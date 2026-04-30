from __future__ import annotations

import argparse
import socket
import subprocess
import sys
import time
from pathlib import Path


BOOT_FRAGMENTS = [
    b"Lum-OS stage2: serial online",
    b"Loading kernel.bin from FAT12...",
    b"Kernel loaded successfully.",
    b"Switching to 32-bit protected mode...",
    b"Lum-OS kernel online",
    b"lum> ",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a serial smoke test against Lum-OS in QEMU.")
    parser.add_argument("--image", required=True, type=Path, help="path to the floppy image to boot")
    parser.add_argument("--qemu", required=True, type=Path, help="path to qemu-system-i386")
    parser.add_argument("--timeout", type=float, default=10.0, help="timeout in seconds for each phase")
    return parser.parse_args()


def find_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.bind(("127.0.0.1", 0))
        return int(probe.getsockname()[1])


def connect_serial(port: int, timeout: float) -> socket.socket:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            sock = socket.create_connection(("127.0.0.1", port), timeout=1.0)
            sock.settimeout(0.25)
            return sock
        except OSError:
            time.sleep(0.1)
    raise TimeoutError("timed out waiting for the QEMU serial TCP listener")


def read_until(sock: socket.socket, fragments: list[bytes], timeout: float) -> bytes:
    deadline = time.time() + timeout
    data = bytearray()

    while time.time() < deadline:
        if all(fragment in data for fragment in fragments):
            return bytes(data)

        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            continue

        if not chunk:
            break

        data.extend(chunk)

    missing = [fragment.decode("latin1", errors="replace") for fragment in fragments if fragment not in data]
    rendered = bytes(data).decode("latin1", errors="replace")
    raise TimeoutError(f"timed out waiting for serial output: {missing}\nCaptured output:\n{rendered}")


def expect_command_output(
    sock: socket.socket,
    command: bytes,
    expected_fragments: list[bytes],
    timeout: float,
) -> bytes:
    sock.sendall(command)
    return read_until(sock, expected_fragments, timeout)


def main() -> int:
    args = parse_args()

    if not args.image.exists():
        raise FileNotFoundError(f"image not found: {args.image}")
    if not args.qemu.exists():
        raise FileNotFoundError(f"qemu binary not found: {args.qemu}")

    port = find_free_port()
    command = [
        str(args.qemu),
        "-drive",
        f"file={args.image},format=raw,if=floppy",
        "-serial",
        f"tcp:127.0.0.1:{port},server=on,wait=on",
        "-display",
        "none",
        "-monitor",
        "none",
        "-no-reboot",
    ]

    proc = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    sock: socket.socket | None = None

    try:
        sock = connect_serial(port, args.timeout)

        boot_output = read_until(sock, BOOT_FRAGMENTS, args.timeout)
        print("[smoke] boot banner received")
        print(boot_output.decode("latin1", errors="replace"))

        help_output = expect_command_output(
            sock,
            b"help\n",
            [b"Commands: help, about, clear, mem, ls, heap, ticks, uptime, alloc <bytes>, free <addr>, memtest, echo <text>, reboot, halt", b"lum> "],
            args.timeout,
        )
        print("[smoke] help command passed")
        print(help_output.decode("latin1", errors="replace"))

        heap_output = expect_command_output(
            sock,
            b"heap\n",
            [b"Heap start:", b"Heap used:", b"lum> "],
            args.timeout,
        )
        print("[smoke] heap command passed")
        print(heap_output.decode("latin1", errors="replace"))

        alloc_output = expect_command_output(
            sock,
            b"alloc 256\n",
            [b"Allocated at", b"size=256 bytes", b"lum> "],
            args.timeout,
        )
        print("[smoke] alloc command passed")
        print(alloc_output.decode("latin1", errors="replace"))

        ticks_output = expect_command_output(
            sock,
            b"ticks\n",
            [b"Timer ticks:", b"Approx uptime:", b"lum> "],
            args.timeout,
        )
        print("[smoke] ticks command passed")
        print(ticks_output.decode("latin1", errors="replace"))

        uptime_output = expect_command_output(
            sock,
            b"uptime\n",
            [b"Uptime exact:", b" s", b"lum> "],
            args.timeout,
        )
        print("[smoke] uptime command passed")
        print(uptime_output.decode("latin1", errors="replace"))

        mem_output = expect_command_output(
            sock,
            b"mem\n",
            [b"Approx total memory:", b"lum> "],
            args.timeout,
        )
        print("[smoke] mem command passed")
        print(mem_output.decode("latin1", errors="replace"))

        ls_output = expect_command_output(
            sock,
            b"ls\n",
            [b"Root directory:", b"STAGE2.BIN", b"KERNEL.BIN", b"lum> "],
            args.timeout,
        )
        print("[smoke] ls command passed")
        print(ls_output.decode("latin1", errors="replace"))

        echo_output = expect_command_output(
            sock,
            b"echo smoke test\n",
            [b"smoke test", b"lum> "],
            args.timeout,
        )
        print("[smoke] echo command passed")
        print(echo_output.decode("latin1", errors="replace"))

        halt_output = expect_command_output(
            sock,
            b"halt\n",
            [b"CPU halted."],
            args.timeout,
        )
        print("[smoke] halt command passed")
        print(halt_output.decode("latin1", errors="replace"))
    except Exception as exc:
        print(f"[smoke] failed: {exc}", file=sys.stderr)
        return 1
    finally:
        if sock is not None:
            sock.close()

        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)

    print("[smoke] Lum-OS serial smoke test passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
