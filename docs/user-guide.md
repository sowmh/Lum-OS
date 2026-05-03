# Lum-OS User Guide

## Booting Lum-OS

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

Headless mode is the fastest way to interact with the shell because COM1 is connected directly to your terminal.

## Input Methods

You can type into Lum-OS through:

- the QEMU keyboard
- the serial console in headless mode

Keyboard input is queued through IRQ1, while serial input is polled from COM1.

## Available Commands

- `help` prints the command list
- `about` prints a compact project summary
- `clear` clears the screen and redraws the banner
- `mem` prints memory values gathered during boot plus heap stats
- `ls` lists cached FAT12 root directory entries
- `files` lists the boot-time cached readable files
- `heap` prints heap usage and allocation counters
- `ticks` prints timer tick counters
- `uptime` prints approximate uptime in seconds
- `vmem` prints bootstrap paging and frame allocator status
- `alloc <bytes>` allocates heap memory
- `free <addr>` frees a previously allocated block
- `memtest` runs a heap stress test
- `echo <text>` writes text back to the console
- `cat <file>` prints a boot-time cached file such as `README.TXT`
- `reboot` asks the keyboard controller to reset the machine
- `halt` stops the CPU

`alloc` and `free` accept decimal and hexadecimal values.

Examples:

```text
lum> alloc 256
lum> alloc 0x100
lum> free 1179664
lum> free 0x120010
```

## Example Session

```text
lum> help
lum> vmem
lum> files
lum> cat README.TXT
lum> heap
lum> alloc 0x100
lum> free 0x120010
lum> halt
```

## Scope

Lum-OS is currently a working educational boot-to-shell kernel, not a full general-purpose operating system.

Its present focus is:

- BIOS boot
- FAT12 loading
- protected-mode entry
- basic interrupt handling
- paging and heap diagnostics
- simple shell interaction
