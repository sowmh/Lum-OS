# Lum-OS Developer Guide

## Active Build Path

The supported build path is the top-level NASM-based one driven by `tools/build.py`.

Main targets:

```bash
python tools/build.py stage1
python tools/build.py stage2
python tools/build.py kernel
python tools/build.py image
python tools/build.py run
python tools/build.py run-headless
python tools/build.py smoke-test
python tools/build.py clean
```

The top-level `Makefile` is only a wrapper around those commands.

## Build Inputs

- `src/bootloader/stage1/boot.asm`
  - BIOS boot sector
  - FAT12 root scan for `STAGE2.BIN`
- `src/bootloader/stage2/stage2.asm`
  - serial bring-up
  - boot info handoff
  - FAT12 kernel loading
  - boot-time cache for extra root files
  - protected-mode jump
- `src/kernel/kernel.asm`
  - VGA and serial console
  - IDT, PIC, PIT, keyboard IRQ queue
  - paging bootstrap
  - heap allocator
  - shell commands
- `tools/build_image.py`
  - pure-Python FAT12 floppy generator
- `tools/smoke_test.py`
  - QEMU serial integration test

## Testing Strategy

Fast manual check:

```bash
python tools/build.py run-headless
```

Automated verification:

```bash
python tools/build.py smoke-test
```

The smoke test currently covers:

- boot banner
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

## Memory and Paging Notes

- Boot info lives at physical `0x00009000`
- The kernel binary is loaded at physical `0x00010000`
- The first 4 MiB are identity-mapped during bootstrap
- The null page is intentionally unmapped
- The stack guard page is intentionally unmapped
- The page at `0x1000` is intentionally read-only
- The heap starts at `0x00120000` and spans 1 MiB
- The frame bitmap now reserves bootstrap-used memory before any runtime allocation

## Shell Extension Points

Most shell behavior lives in `src/kernel/kernel.asm`.

Typical places to extend:

- `dispatch_command` for new commands
- `print_*_report` helpers for diagnostics
- memory helpers such as `kmalloc_align16`, `kfree`, `alloc_frame`, and `free_frame`

## Reference Material

The repository still contains older or duplicated material that is not part of the active smoke-tested path:

- `src/kernel/kernel.c`
- legacy C/Open Watcom stage 2 files
- the nested `Lum-OS/` directory

Treat them as reference or archival context unless you intentionally choose to revive them.
