import time
import psutil

# Module-level state for network delta calculation
_prev_net_bytes: tuple | None = None  # (bytes_recv, bytes_sent)
_prev_net_time: float | None = None


def _format_speed(bps: float) -> str:
    if bps < 1024:
        return f"{bps:.0f} B/s"
    if bps < 1024 * 1024:
        return f"{bps / 1024:.1f} KB/s"
    return f"{bps / (1024 * 1024):.1f} MB/s"


def get_cpu_temp() -> str:
    if not hasattr(psutil, "sensors_temperatures"):
        return "N/A"
    for name in ("coretemp", "k10temp", "zenpower"):
        sensors = psutil.sensors_temperatures().get(name, [])
        if sensors:
            return f"{int(sensors[0].current)}°C"
    return "N/A"


async def get_system_stats() -> dict:
    global _prev_net_bytes, _prev_net_time

    # ── CPU ───────────────────────────────────────────────────────
    cpu_usage = psutil.cpu_percent(interval=None) / 100.0

    # ── RAM ───────────────────────────────────────────────────────
    mem = psutil.virtual_memory()
    ram_used_gib = (mem.total - mem.available) / (1024**3)
    ram_total_gib = mem.total / (1024**3)

    # ── Disk ──────────────────────────────────────────────────────
    disk = psutil.disk_usage("/")
    disk_used_gb = disk.used / (1024**3)
    disk_total_gb = disk.total / (1024**3)

    # ── Network speed (bytes delta / elapsed time) ────────────────
    net = psutil.net_io_counters()
    now = time.monotonic()
    dl_bps = ul_bps = 0.0

    if _prev_net_bytes is not None and _prev_net_time is not None:
        elapsed = now - _prev_net_time
        if elapsed > 0:
            dl_bps = max(0, net.bytes_recv - _prev_net_bytes[0]) / elapsed
            ul_bps = max(0, net.bytes_sent - _prev_net_bytes[1]) / elapsed

    _prev_net_bytes = (net.bytes_recv, net.bytes_sent)
    _prev_net_time = now

    return {
        "type": "sys_stats",
        "payload": {
            # CPU
            "cpuUsage": cpu_usage,
            "cpuTempText": get_cpu_temp(),
            # RAM
            "ramUsage": mem.percent / 100.0,
            "ramUsedText": f"{ram_used_gib:.1f}GiB",
            "ramTotalText": f"{ram_total_gib:.1f}GiB",
            # Disk
            "diskUsage": f"{int(disk.percent)}%",
            "diskUsedText": f"{disk_used_gb:.1f}G",
            "diskTotalText": f"{disk_total_gb:.1f}G",
            # Network
            "netDownText": _format_speed(dl_bps),
            "netUpText": _format_speed(ul_bps),
            "netDownMbps": round(dl_bps / (1024 * 1024), 2),
            "netUpMbps": round(ul_bps / (1024 * 1024), 2),
        },
    }
