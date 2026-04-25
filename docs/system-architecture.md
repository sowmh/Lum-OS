# Lum-OS System Architecture

## Boot chain

### Stage 1

- lives in the first 512-byte boot sector
- contains a FAT12 BPB
- scans the root directory for `STAGE2.BIN`
- loads stage 2 at `0x2000:0x0000`

### Stage 2

- starts in 16-bit real mode
- initializes COM1 for debug output
- reads basic memory information from BIOS
- stores boot info at physical `0x00009000`
- scans FAT12 for `KERNEL.BIN`
- loads the kernel at physical `0x00010000`
- enables A20
- loads a flat GDT
- jumps into 32-bit protected mode

### Kernel

- runs as flat 32-bit code
- uses VGA text memory at `0xB8000`
- mirrors output to COM1
- polls keyboard controller and serial input
- exposes a minimal command shell

## Memory handoff

The kernel reads boot information from `0x9000`.

Current fields:

- signature
- boot drive
- conventional memory in KB
- extended memory in KB
- approximate total memory in KB

## Disk format

The generated image is a 1.44 MB FAT12 floppy.

The Python image builder writes:

- stage 1 to sector 0
- `STAGE2.BIN` into the data area
- `KERNEL.BIN` into the data area
- matching FAT entries and root directory records

## Design goal

The repository now aims for a reliable educational vertical slice:

- understandable boot flow
- zero external filesystem tools
- easy debugging through serial logs
