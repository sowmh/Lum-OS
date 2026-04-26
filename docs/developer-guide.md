# Lum-OS Developer Guide

## Active build path

The supported build path is the NASM-based one driven by `tools/build.py`.

Requirements:

- Python 3
- NASM
- QEMU

Build targets:

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

The top-level `Makefile` is only a wrapper around these commands.

## Source map

- `src/bootloader/stage1/boot.asm`
  - FAT12-aware boot sector
  - loads `STAGE2.BIN`
- `src/bootloader/stage2/stage2.asm`
  - serial console setup
  - kernel loading from FAT12
  - boot info handoff at `0x9000`
  - A20 enable and protected-mode jump
- `src/kernel/kernel.asm`
  - VGA + serial console
  - line input from serial and keyboard polling
  - command shell
- `tools/build_image.py`
  - assembles a FAT12 floppy image in pure Python

## Notes on legacy files

There are older C and Open Watcom experiments still present under `src/bootloader/stage2/` and `src/kernel/`.

They are not part of the current verified boot path.

## Testing

Use headless mode for the quickest verification:

```bash
python tools/build.py run-headless
```

You should see:

- stage 2 serial messages
- the kernel banner
- the `lum>` prompt

Use the automated smoke test when you want a repeatable boot-to-shell check:

```bash
python tools/build.py smoke-test
```

The smoke test boots QEMU with a TCP-backed serial port, waits for the prompt, and verifies `help`, `mem`, `ls`, `echo`, and `halt`.

You can also pipe commands into QEMU for smoke tests:

```bash
printf "help\nmem\nhalt\n" | qemu-system-i386 -drive file=build/main_floppy.img,format=raw,if=floppy -serial stdio -display none -no-reboot -no-shutdown
```

## Extension points

- Add new shell commands in `src/kernel/kernel.asm`
- Extend the boot info structure at `0x9000`
- Replace polling with proper interrupt-driven input once an IDT exists
