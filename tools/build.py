from __future__ import annotations
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path
REPO_ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = REPO_ROOT / "build"
STAGE1_SRC = REPO_ROOT / "src" / "bootloader" / "stage1" / "boot.asm"
STAGE2_SRC = REPO_ROOT / "src" / "bootloader" / "stage2" / "stage2.asm"
KERNEL_SRC = REPO_ROOT / "src" / "kernel" / "kernel.asm"
IMAGE_SCRIPT = REPO_ROOT / "tools" / "build_image.py"
SMOKE_TEST_SCRIPT = REPO_ROOT / "tools" / "smoke_test.py"
def find_executable(env_var: str, names: list[str], fallbacks: list[Path]) -> str:
    override = os.environ.get(env_var)
    if override:
        return override
    for name in names:
        found = shutil.which(name)
        if found:
            return found
    for path in fallbacks:
        if path.exists():
            return str(path)
    searched = ", ".join(names + [str(path) for path in fallbacks])
    raise FileNotFoundError(f"Unable to find {env_var}. Tried: {searched}")
def run_command(args: list[str]) -> None:
    printable = " ".join(f'"{arg}"' if " " in arg else arg for arg in args)
    print(f"[build] {printable}")
    subprocess.run(args, cwd=REPO_ROOT, check=True)
def ensure_build_dir() -> None:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
def nasm() -> str:
    return find_executable(
        "NASM",
        ["nasm"],
        [Path(r"C:\Program Files\NASM\nasm.exe")],
    )
def qemu() -> str:
    return find_executable(
        "QEMU",
        ["qemu-system-i386"],
        [Path(r"C:\Program Files\qemu\qemu-system-i386.exe")],
    )
def build_stage1() -> Path:
    ensure_build_dir()
    output = BUILD_DIR / "stage1.bin"
    run_command([nasm(), "-f", "bin", str(STAGE1_SRC), "-o", str(output)])
    return output
def build_stage2() -> Path:
    ensure_build_dir()
    output = BUILD_DIR / "stage2.bin"
    run_command([nasm(), "-f", "bin", str(STAGE2_SRC), "-o", str(output)])
    return output
def build_kernel() -> Path:
    ensure_build_dir()
    output = BUILD_DIR / "kernel.bin"
    run_command([nasm(), "-f", "bin", str(KERNEL_SRC), "-o", str(output)])
    return output
def build_image() -> Path:
    ensure_build_dir()
    stage1 = build_stage1()
    stage2 = build_stage2()
    kernel = build_kernel()
    output = BUILD_DIR / "main_floppy.img"
    run_command(
        [
            sys.executable,
            str(IMAGE_SCRIPT),
            "--boot",
            str(stage1),
            "--stage2",
            str(stage2),
            "--kernel",
            str(kernel),
            "--output",
            str(output),
        ]
    )
    return output
def run_qemu(headless: bool) -> None:
    image = build_image()
    command = [qemu(), "-drive", f"file={image},format=raw,if=floppy"]
    if headless:
        command.extend(["-serial", "stdio", "-display", "none", "-no-reboot", "-no-shutdown"])
    run_command(command)
def smoke_test() -> None:
    image = build_image()
    run_command([sys.executable, str(SMOKE_TEST_SCRIPT), "--image", str(image), "--qemu", qemu()])
def clean() -> None:
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
        print(f"[build] removed {BUILD_DIR}")
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build Lum-OS with local tools.")
    parser.add_argument(
        "target",
        choices=["all", "image", "stage1", "stage2", "kernel", "run", "run-headless", "smoke-test", "test", "clean"],
        nargs="?",
        default="all",
    )
    return parser.parse_args()
def main() -> int:
    args = parse_args()
    try:
        if args.target in {"all", "image"}:
            build_image()
        elif args.target == "stage1":
            build_stage1()
        elif args.target == "stage2":
            build_stage2()
        elif args.target == "kernel":
            build_kernel()
        elif args.target == "run":
            run_qemu(headless=False)
        elif args.target == "run-headless":
            run_qemu(headless=True)
        elif args.target in {"smoke-test", "test"}:
            smoke_test()
        elif args.target == "clean":
            clean()
    except FileNotFoundError as exc:
        print(f"[build] {exc}", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        print(f"[build] command failed with exit code {exc.returncode}", file=sys.stderr)
        return exc.returncode
    return 0
if __name__ == "__main__":
    raise SystemExit(main())