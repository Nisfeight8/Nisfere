"""
process_manager.py — process listing for the System Monitor tool.

Everything else the System Monitor UI needs (overall CPU%, RAM%, uptime,
username, distro name) already exists via SystemInfo/SystemStatsService.
This module's only job is the per-process breakdown.
"""

import logging
import os
import psutil

logger = logging.getLogger(__name__)

_current_uid = os.getuid()

# Per-process cache: keeps the psutil.Process object alive (needed for
# cpu_percent() deltas) AND caches values that essentially never change
# for a process's lifetime (name, uid/is_system) — querying those fresh
# every 2s for 200+ processes was pure wasted syscall overhead.
_tracked: dict[int, dict] = {}


def _is_system_process(proc: psutil.Process) -> bool:
    try:
        return proc.uids().real != _current_uid
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        return True


def list_processes(limit: int = 150) -> list[dict]:
    results = []
    seen_pids = set()

    for pinfo in psutil.process_iter(["pid"]):
        pid = pinfo.info["pid"]
        seen_pids.add(pid)

        entry = _tracked.get(pid)
        if entry is None:
            try:
                proc = psutil.Process(pid)
                proc.cpu_percent(interval=None)  # prime baseline
                entry = {
                    "proc": proc,
                    "name": proc.name(),
                    "isSystem": _is_system_process(proc),
                }
                _tracked[pid] = entry
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue

        try:
            cpu_percent = entry["proc"].cpu_percent(interval=None)
            mem_mb = entry["proc"].memory_info().rss / (1024 * 1024)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

        results.append(
            {
                "pid": pid,
                "name": entry["name"],
                "cpuPercent": round(cpu_percent, 1),
                "memMb": round(mem_mb, 1),
                "isSystem": entry["isSystem"],
            }
        )

    # Drop cache entries for processes that no longer exist.
    dead_pids = set(_tracked.keys()) - seen_pids
    for pid in dead_pids:
        del _tracked[pid]

    # Cap the payload — a human glancing at this table only cares about
    # the heaviest processes anyway, and this directly cuts network +
    # QML-side JSON/array handling cost every poll.
    results.sort(key=lambda p: p["memMb"], reverse=True)
    return results[:limit]


async def handle_command(action: str, payload: dict, sock) -> None:
    match action:
        case "get_processes":
            processes = list_processes()
            await sock.send(
                {
                    "type": "process_list",
                    "payload": {
                        "processes": processes,
                        "count": len(processes),
                    },
                }
            )

        case _:
            logger.warning("Unknown process action: '%s'", action)
