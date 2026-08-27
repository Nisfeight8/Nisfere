import asyncio
import logging

logger = logging.getLogger(__name__)

try:
    import docker
    from docker import DockerClient

    _DOCKER_AVAILABLE = True
except ImportError:
    docker = None
    DockerClient = None
    _DOCKER_AVAILABLE = False
    logger.warning(
        "python-docker not installed — Docker features disabled (Docker tab "
        "will report unavailable instead of working, nothing else is affected)"
    )


class DockerService:

    def _client(self):
        """Creates a fresh client per call — handles daemon restarts gracefully."""
        if not _DOCKER_AVAILABLE:
            raise RuntimeError(
                "Docker is not installed (python-docker package missing)"
            )
        return docker.from_env()

    # ── Streaming ────────────────────────────────────────────────

    async def get_stats_process(self, container_id: str):
        return await asyncio.create_subprocess_exec(
            "docker",
            "stats",
            "--format",
            "{{json .}}",
            container_id,
            stdout=asyncio.subprocess.PIPE,
        )

    async def get_logs_process(self, container_id: str):
        return await asyncio.create_subprocess_exec(
            "docker",
            "logs",
            "-f",
            "--tail",
            "50",
            container_id,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )

    # ── Data fetchers ─────────────────────────────────────────────

    def _fetch_containers(self, client) -> tuple:
        compose_projects: dict = {}
        standalone_containers: list = []
        running_count = 0
        containers = client.containers.list(all=True)

        for c in containers:
            if c.status == "running":
                running_count += 1

            labels = c.labels
            project_name = labels.get("com.docker.compose.project")

            container_info = {
                "id": c.short_id,
                "name": c.name,
                "status": c.status,
                "service": labels.get("com.docker.compose.service", "N/A"),
            }

            if project_name:
                if project_name not in compose_projects:
                    compose_projects[project_name] = {
                        "working_dir": labels.get(
                            "com.docker.compose.project.working_dir", ""
                        ),
                        "config_files": [],
                        "containers": [],
                    }

                config_files_str = labels.get(
                    "com.docker.compose.project.config_files", ""
                )
                known = compose_projects[project_name]["config_files"]
                for f in config_files_str.split(","):
                    f = f.strip()
                    if f and f not in known:
                        known.append(f)

                compose_projects[project_name]["containers"].append(container_info)
            else:
                standalone_containers.append(container_info)

        return compose_projects, standalone_containers, running_count, len(containers)

    def _fetch_images(self, client) -> list[dict]:
        result = []
        for img in client.images.list():
            tags = img.tags or ["<none>:<none>"]
            # Was img.attrs.get("VirtualSize", 0) — VirtualSize is
            # deprecated in newer Docker Engine API versions and often
            # comes back unset (0) there, which is exactly why every
            # image was showing "0.0 MB" regardless of its real size.
            # "Size" is the current, consistently-populated field;
            # falling back to VirtualSize keeps this working against
            # older daemons that only report that one.
            size_bytes = img.attrs.get("Size", img.attrs.get("VirtualSize", 0))
            size_mb = round(size_bytes / (1024 * 1024), 1)
            for tag in tags:
                name, t = tag.split(":", 1) if ":" in tag else (tag, "latest")
                result.append(
                    {
                        "id": img.short_id.replace("sha256:", ""),
                        "name": name,
                        "tag": t,
                        "size": f"{size_mb} MB",
                    }
                )
        # client.images.list() doesn't guarantee stable ordering
        # between calls — without this, the list visibly reordered on
        # every 3s poll refresh while the tab was open, even though
        # nothing had actually changed.
        result.sort(key=lambda r: (r["name"].lower(), r["tag"].lower()))
        return result

    def _fetch_volumes(self, client) -> list[dict]:
        # Same non-deterministic-ordering issue as images — sorted for
        # a stable list across refreshes.
        volumes = [
            {
                "name": vol.name,
                "driver": vol.attrs.get("Driver", "local"),
                "mountpoint": vol.attrs.get("Mountpoint", ""),
            }
            for vol in client.volumes.list()
        ]
        volumes.sort(key=lambda v: v["name"].lower())
        return volumes

    # ── Public API ────────────────────────────────────────────────

    def get_docker_status(self) -> dict:
        try:
            client = self._client()
            compose_projects, standalone, running, total = self._fetch_containers(
                client
            )
            return {
                "type": "docker_stats",
                "payload": {
                    "runningCount": running,
                    "totalCount": total,
                    "composeProjects": compose_projects,
                    "standaloneContainers": standalone,
                    "images": self._fetch_images(client),
                    "volumes": self._fetch_volumes(client),
                    "error": "",
                },
            }
        except Exception as e:
            logger.error("get_docker_status failed: %s", e)
            return {
                "type": "docker_stats",
                "payload": {"runningCount": -1, "error": str(e)},
            }

    def get_container_details(self, container_id: str) -> dict:
        try:
            client = self._client()
            c = client.containers.get(container_id)
            attrs = c.attrs
            logs = c.logs(tail=50, stdout=True, stderr=True).decode(
                "utf-8", errors="ignore"
            )
            return {
                "type": "container_details",
                "payload": {
                    "id": c.short_id,
                    "name": c.name,
                    "status": c.status,
                    "image": attrs["Config"]["Image"],
                    "created": attrs["Created"],
                    "env": attrs["Config"].get("Env", []),
                    "ports": attrs["NetworkSettings"]["Ports"],
                    "logs": logs,
                },
            }
        except Exception as e:
            logger.error("get_container_details failed for %s: %s", container_id, e)
            return {"type": "error", "payload": f"Could not fetch details: {e}"}

    def docker_action(self, action: str, target: str, action_type: str) -> bool:
        try:
            client = self._client()
            match action_type:
                case "container":
                    c = client.containers.get(target)
                    match action:
                        case "start":
                            c.start()
                        case "stop":
                            c.stop()
                        case "restart":
                            c.restart()
                        case "delete":
                            if c.status == "running":
                                c.stop()
                            c.remove(v=True, force=True)
                        case _:
                            logger.warning("Unknown container action: %s", action)
                            return False
                case "image":
                    if action == "delete":
                        client.images.remove(target, force=True)
                    elif action == "prune":
                        # Dangling only (untagged <none>:<none> images)
                        # — same scope as plain `docker image prune` on
                        # the CLI, deliberately NOT the more aggressive
                        # `-a` (which also removes any image not
                        # currently used by a container, even ones you
                        # might want to reuse without re-pulling).
                        # `target` is unused/irrelevant for a bulk
                        # prune.
                        client.images.prune()
                    else:
                        logger.warning("Unknown image action: %s", action)
                        return False
                case "volume":
                    if action == "delete":
                        client.volumes.get(target).remove(force=True)
                    elif action == "prune":
                        # Removes volumes not attached to any
                        # container — same scope as plain `docker
                        # volume prune`, no extra flags.
                        client.volumes.prune()
                    else:
                        logger.warning("Unknown volume action: %s", action)
                        return False
            return True
        except Exception as e:
            logger.error(
                "docker_action [%s %s %s] failed: %s", action, action_type, target, e
            )
            return False

    async def docker_action_async(
        self, action: str, target_obj: dict, action_type: str
    ) -> bool:
        """Runs a docker compose command."""
        try:
            working_dir = target_obj.get("working_dir")
            config_files: list[str] = target_obj.get("config_files", [])

            cmd = ["docker", "compose"]
            for f in config_files:
                cmd.extend(["-f", f])
            cmd.append(action)
            if action == "up":
                cmd.append("-d")

            proc = await asyncio.create_subprocess_exec(
                *cmd,
                cwd=working_dir,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            _, stderr = await proc.communicate()

            if proc.returncode != 0:
                logger.error("compose %s failed: %s", action, stderr.decode())
                return False
            return True
        except Exception as e:
            logger.error("docker_action_async [%s] failed: %s", action, e)
            return False
