# Lum-OS

Lum-OS is a small x86 operating system project that now boots end-to-end from a FAT12 floppy image into a 32-bit protected-mode kernel with a usable shell.

## What works today

- Stage 1 boot sector that loads `STAGE2.BIN` from the FAT12 root directory.
- Stage 2 loader that initializes serial output, gathers basic memory info, loads `KERNEL.BIN`, enables A20, and switches to protected mode.
- 32-bit kernel that writes to both VGA text mode and COM1.
- Interactive shell with these commands:
  - `help`
  - `about`
  - `clear`
  - `mem`
  - `ls`
  - `heap`
  - `ticks`
  - `uptime`
  - `alloc <bytes>`
  - `free <addr>`
  - `memtest`
  - `echo <text>`
  - `reboot`
  - `halt`
- IDT initialized with exception handlers (0-31) and IRQ stubs (32-47).
- PIC remap + PIT timer initialization + IRQ-driven keyboard input queue.
- Paging enabled (`CR0.PG`) with an identity-mapped bootstrap virtual memory layout.
- Basic memory protection hardening:
  - null page unmapped
  - stack guard page
  - page-fault diagnostics include `CR2`
- Heap manager upgraded from bump allocation to free-list allocation with:
  - first-fit search
  - block split
  - coalescing on free
  - high-water/statistics counters
- Portable image creation without `mkfs.fat`, `mcopy`, or Open Watcom.
- Automated smoke test that boots QEMU, talks to the shell over COM1, and checks core commands.

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
`smoke-test` is the fastest fully automated check because it boots Lum-OS, waits for the prompt, and validates shell commands end-to-end.

## Project layout

```text
src/
  bootloader/
    stage1/boot.asm      # FAT12 boot sector
    stage2/stage2.asm    # real-mode loader and protected-mode bridge
  kernel/
    kernel.asm           # 32-bit kernel and shell
tools/
  build.py               # portable build and run entry point
  build_image.py         # FAT12 floppy image generator
  smoke_test.py          # automated QEMU serial smoke test
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
4. The kernel starts at physical `0x10000` and opens the Lum-OS shell.

## Next ideas

This repository now has a clean, working vertical slice with protected mode, interrupts, paging, and a reusable kernel heap.

Good next steps would be:

- multi-page virtual memory manager (page tables beyond first 4 MiB)
- robust page-permission policy by region (code RO/RX, data RW, stricter guards)
- physical memory map ingestion (E820) and frame allocator based on real RAM layout
- kernel heap hardening (`kfree` validation, corruption checks, reusable bins/size classes)
- syscall surface + user-space loader foundation

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
