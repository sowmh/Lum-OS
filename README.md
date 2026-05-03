# Lum-OS

Lum-OS is a small from-scratch x86 operating system that boots from a FAT12 floppy image into a 32-bit protected-mode kernel with a serial and VGA shell.

The project is intentionally educational: the goal is a clean, understandable boot-to-shell path that is easy to build, inspect, and extend.

## Current Capabilities

- Stage 1 FAT12 boot sector that locates and loads `STAGE2.BIN`
- Stage 2 loader that:
  - initializes COM1 serial output
  - captures basic BIOS memory information
  - caches the FAT12 root directory in memory
  - preloads extra root files into RAM for the kernel shell
  - loads `KERNEL.BIN`
  - enables A20
  - switches into 32-bit protected mode
- 32-bit kernel with:
  - VGA text output
  - serial console mirroring
  - exception stubs for vectors `0-31`
  - PIC remap and PIT timer setup
  - IRQ-backed keyboard input queue
  - bootstrap paging with guard pages
  - free-list heap allocator with split and coalescing
  - frame bitmap bootstrap reservations
  - interactive shell commands
- Portable Python image builder for FAT12 floppy images
- Automated QEMU smoke test

## Shell Commands

- `help`
- `about`
- `clear`
- `mem`
- `ls`
- `files`
- `heap`
- `ticks`
- `uptime`
- `vmem`
- `alloc <bytes>`
- `free <addr>`
- `memtest`
- `echo <text>`
- `cat <file>`
- `reboot`
- `halt`

`alloc` and `free` accept decimal and hexadecimal values such as `256` or `0x100`.

## Requirements

- Python 3
- NASM
- QEMU

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y python3 nasm qemu-system-x86
```

### macOS

```bash
brew install nasm qemu
```

### Windows

Use WSL2, or install NASM and QEMU natively and keep Python available in `PATH`.

## Quick Start

Build the floppy image:

```bash
python tools/build.py image
```

Run with a QEMU window:

```bash
python tools/build.py run
```

Run headless through the serial console:

```bash
python tools/build.py run-headless
```

Run the automated smoke test:

```bash
python tools/build.py smoke-test
```

The top-level `Makefile` is a thin wrapper around the same commands:

```bash
make image
make run
make run-headless
make smoke-test
make clean
```

## Verified Boot Flow

1. BIOS loads the first sector at `0x7C00`.
2. Stage 1 parses the FAT12 root directory and finds `STAGE2.BIN`.
3. Stage 2 starts in real mode, initializes serial, records boot info at `0x9000`, loads `KERNEL.BIN`, enables A20, and enters protected mode.
4. The kernel starts at `0x10000`, initializes interrupts, paging, memory services, console output, and the shell.

## Memory Notes

- Boot info handoff address: `0x00009000`
- Kernel entry address: `0x00010000`
- Bootstrap heap range: `0x00120000` to `0x00220000`
- Bootstrap paging maps the first 4 MiB
- Guard layout:
  - null page unmapped
  - stack guard page unmapped
  - page at `0x1000` present but read-only

## Testing

`python tools/build.py smoke-test` boots QEMU in headless mode and verifies:

- boot banner arrival
- `help`
- `about`
- `vmem`
- `files`
- `cat`
- `heap`
- `alloc`
- `free`
- `memtest`
- `ticks`
- `uptime`
- `mem`
- `ls`
- `echo`
- `halt`

This gives a repeatable end-to-end check from boot sector to shell behavior.

## Source Layout

```text
src/
  bootloader/
    stage1/   FAT12-aware boot sector
    stage2/   real-mode loader and protected-mode jump
  kernel/     32-bit kernel shell and core services
tools/
  build.py        build entry point
  build_image.py  FAT12 image builder
  smoke_test.py   automated QEMU verification
docs/
  user-guide.md
  developer-guide.md
  system-architecture.md
```

## Active Build Path vs Reference Material

The smoke-tested build path is the top-level `src/` plus `tools/build.py`.

Some files remain in the repository as reference material:

- `src/kernel/kernel.c`
- the older C/Open Watcom stage 2 files under `src/bootloader/stage2/`
- the nested `Lum-OS/` tree

They are useful for history and experimentation, but they are not part of the active verified build path.

## Project Status

Lum-OS now has a stable boot-to-shell vertical slice:

- protected-mode boot works
- interrupts are installed
- keyboard and timer IRQs are live
- paging is enabled
- heap allocation and freeing are exercised automatically
- memory diagnostics are exposed through the shell

The biggest remaining milestones are:

- richer FAT12 access from the kernel beyond the boot-time file cache
- RAM map ingestion and frame management based on real hardware layout
- syscall and user-space foundations
- tasking / scheduling
- broader device and filesystem support

## Documentation

- [User guide](docs/user-guide.md)
- [Developer guide](docs/developer-guide.md)
- [System architecture](docs/system-architecture.md)

## License

Released under the MIT License. See [LICENSE](LICENSE).
