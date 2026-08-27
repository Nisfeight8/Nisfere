import asyncio
import logging
import os

logger = logging.getLogger(__name__)


class GitService:
    # Local-only operations (status/add/reset/commit) should be near-
    # instant — this is just a generous safety net, not a realistic
    # expected wait.
    DEFAULT_TIMEOUT_SECONDS = 10.0

    # push/pull hit the network AND can need credentials — a real,
    # longer wait is expected, but still bounded. Combined with
    # GIT_TERMINAL_PROMPT=0 below (git fails immediately instead of
    # blocking on an interactive prompt we have no way to answer from a
    # background daemon), this is the second line of defense against
    # an SSH-agent passphrase prompt or similar hang.
    NETWORK_TIMEOUT_SECONDS = 15.0

    async def _run_git(
        self, repo: str, args: list[str], timeout: float | None = None
    ) -> tuple[int, str, str]:
        """Runs `git <args>` in `repo`. Returns (returncode, stdout, stderr).
        -1 as returncode signals our own timeout kill, not git's exit code."""
        if timeout is None:
            timeout = self.DEFAULT_TIMEOUT_SECONDS

        env = os.environ.copy()
        env["GIT_TERMINAL_PROMPT"] = "0"

        logger.debug("git -C %s %s", repo, " ".join(args))

        proc = await asyncio.create_subprocess_exec(
            "git",
            "-C",
            repo,
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )
        try:
            stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        except asyncio.TimeoutError:
            logger.warning(
                "git -C %s %s timed out after %.0fs", repo, " ".join(args), timeout
            )
            proc.kill()
            await proc.wait()
            return (
                -1,
                "",
                f"Timed out after {timeout:.0f}s (likely waiting on credentials/SSH agent)",
            )

        if proc.returncode != 0:
            logger.debug(
                "git -C %s %s exited %s: %s",
                repo,
                " ".join(args),
                proc.returncode,
                stderr.decode(errors="replace").strip(),
            )

        return (
            proc.returncode,
            stdout.decode(errors="replace"),
            stderr.decode(errors="replace"),
        )

    async def get_status(self, repo: str) -> dict:
        """Parses `git status --porcelain=v2 -b` into a structured dict.
        --porcelain=v2 is a stable, script-oriented format — unlike
        plain `git status`, which is meant for human eyes and can
        change wording between git versions, breaking any parsing
        built on top of it. Returns {"error": "..."} on failure."""
        code, out, err = await self._run_git(repo, ["status", "--porcelain=v2", "-b"])
        if code != 0:
            message = err.strip() or "git status failed"
            logger.warning("git status failed for %s: %s", repo, message)
            return {"error": message}

        branch = ""
        ahead = 0
        behind = 0
        staged: list[str] = []
        unstaged: list[str] = []
        untracked: list[str] = []

        for line in out.splitlines():
            if line.startswith("# branch.head "):
                branch = line.split(" ", 2)[2]
            elif line.startswith("# branch.ab "):
                # "# branch.ab +2 -1"  ->  2 ahead, 1 behind
                parts = line.split(" ")
                ahead = int(parts[2].lstrip("+"))
                behind = int(parts[3].lstrip("-"))
            elif line.startswith("1 ") or line.startswith("2 "):
                # Ordinary ("1 ...") or renamed/copied ("2 ...") change
                # line: "1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>".
                # XY are the two status letters — index (staged) and
                # worktree (unstaged) respectively; "." means unchanged
                # in that slot.
                xy = line.split(" ", 2)[1]
                path = (
                    line.rsplit("\t", 1)[-1]
                    if "\t" in line
                    else line.rsplit(" ", 1)[-1]
                )
                if xy[0] != ".":
                    staged.append(path)
                if xy[1] != ".":
                    unstaged.append(path)
            elif line.startswith("? "):
                untracked.append(line[2:])

        logger.debug(
            "git status %s: branch=%s ahead=%d behind=%d staged=%d unstaged=%d untracked=%d",
            repo,
            branch,
            ahead,
            behind,
            len(staged),
            len(unstaged),
            len(untracked),
        )

        return {
            "branch": branch,
            "ahead": ahead,
            "behind": behind,
            "staged": staged,
            "unstaged": unstaged,
            "untracked": untracked,
        }

    async def stage(self, repo: str, files: list[str]) -> tuple[bool, str]:
        args = ["add", "--"] + files if files else ["add", "-A"]
        code, out, err = await self._run_git(repo, args)
        return code == 0, (err.strip() or out.strip())

    async def unstage(self, repo: str, files: list[str]) -> tuple[bool, str]:
        args = ["reset", "--"] + files if files else ["reset"]
        code, out, err = await self._run_git(repo, args)
        return code == 0, (err.strip() or out.strip())

    async def commit(self, repo: str, message: str) -> tuple[bool, str]:
        code, out, err = await self._run_git(repo, ["commit", "-m", message])
        return code == 0, (err.strip() or out.strip())

    async def push(self, repo: str) -> tuple[bool, str]:
        code, out, err = await self._run_git(
            repo, ["push"], timeout=self.NETWORK_TIMEOUT_SECONDS
        )
        return code == 0, (err.strip() or out.strip())

    async def pull(self, repo: str) -> tuple[bool, str]:
        code, out, err = await self._run_git(
            repo, ["pull"], timeout=self.NETWORK_TIMEOUT_SECONDS
        )
        return code == 0, (err.strip() or out.strip())
