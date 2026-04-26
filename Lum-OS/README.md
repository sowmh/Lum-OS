# Lum-OS

Lum-OS is a small x86 operating system project that now boots end-to-end from a FAT12 floppy image into a 32-bit protected-mode kernel with a usable interrupt-driven shell.

## What works today

- Stage 1 boot sector that loads `STAGE2.BIN` from the FAT12 root directory.
- Stage 2 loader that initializes serial output, gathers basic memory info, loads `KERNEL.BIN`, enables A20, and switches to protected mode.
- 32-bit kernel that writes to both VGA text mode and COM1.
- IDT, PIC remap, and PIT timer support inside the kernel.
- IRQ-driven keyboard input buffered for the shell.
- Interactive shell with these commands:
  - `help`
  - `about`
  - `clear`
  - `mem`
  - `boot`
  - `irq`
  - `ticks`
  - `uptime`
  - `echo <text>`
  - `reboot`
  - `halt`
- Portable image creation without `mkfs.fat`, `mcopy`, or Open Watcom.

## Tooling

The active build path uses:

- Python 3
- NASM
- QEMU

The older C / Open Watcom files are still in the repository as experiments and reference material, but the current bootable path is NASM-only and is driven by `tools/build.py`.

## Quick start

```bash
python tools/build.py image
python tools/build.py run
python tools/build.py run-headless
python tools/build.py smoke-test
```

If you prefer `make`, the top-level `Makefile` forwards to the same Python build tool:

```bash
make image
make run
make run-headless
make smoke-test
```

`run-headless` is the fastest way to verify the shell because it exposes COM1 on your terminal.

## Project layout

```text
src/
  bootloader/
    stage1/boot.asm      # FAT12 boot sector
    stage2/stage2.asm    # real-mode loader and protected-mode bridge
  kernel/
    kernel.asm           # 32-bit kernel, interrupts, and shell
tools/
  build.py               # portable build and run entry point
  build_image.py         # FAT12 floppy image generator
docs/
  user-guide.md
  developer-guide.md
  system-architecture.md
```

## Verified flow

The current verified boot path is:

1. BIOS loads the stage 1 boot sector.
2. Stage 1 finds `STAGE2.BIN` in the FAT12 root directory and loads it at `0x2000:0x0000`.
3. Stage 2 finds `KERNEL.BIN`, stores boot info at `0x9000`, and switches to protected mode.
4. The kernel starts at physical `0x10000`, enables interrupts, and opens the Lum-OS shell.

## Next ideas

This repository now has a clean, working vertical slice. Good next steps would be:

- file commands inside the shell
- allocator and paging
- user-space program loading

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
