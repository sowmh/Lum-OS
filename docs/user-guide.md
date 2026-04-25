# Lum-OS User Guide

## Booting Lum-OS

Build the floppy image:

```bash
python tools/build.py image
```

Run it with a QEMU window:

```bash
python tools/build.py run
```

Run it headless through the serial console:

```bash
python tools/build.py run-headless
```

Headless mode is useful for debugging because stage 2 and the kernel both print to COM1.

## Input methods

The shell accepts input from:

- the QEMU keyboard
- the serial console in headless mode

## Available commands

- `help` shows the command list
- `about` prints a short project summary
- `clear` redraws the screen and banner
- `mem` shows the memory values collected by stage 2
- `echo <text>` prints text back
- `reboot` requests a keyboard-controller reset
- `halt` stops the CPU

## Example session

```text
lum> help
lum> mem
lum> echo hello
lum> halt
```

## Current scope

Lum-OS is a working boot-to-shell demo, not yet a full general-purpose operating system.

Today it focuses on:

- BIOS boot
- FAT12 loading
- protected-mode entry
- simple console interaction
