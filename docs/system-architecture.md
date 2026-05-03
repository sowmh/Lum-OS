# Lum-OS System Architecture

## Boot Chain

### Stage 1

- lives in the first 512-byte boot sector
- contains the FAT12 BPB
- scans the root directory for `STAGE2.BIN`
- loads stage 2 at `0x2000:0x0000`

### Stage 2

- starts in 16-bit real mode
- initializes COM1 for debug output
- records boot information at physical `0x00009000`
- caches the FAT12 root directory in memory
- preloads extra root files into a RAM cache table
- reads `KERNEL.BIN` through FAT12 cluster traversal
- enables A20
- loads a flat GDT
- jumps into 32-bit protected mode

### Kernel

- starts at physical `0x00010000`
- uses VGA text memory at `0xB8000`
- mirrors output to COM1
- installs exception stubs and hardware IRQ handlers
- remaps the PIC and programs the PIT
- queues keyboard input from IRQ1
- enables bootstrap paging for the first 4 MiB
- initializes a free-list heap allocator
- exposes a simple command shell

## Boot Info Handoff

The kernel reads boot information from `0x00009000`.

Current fields:

- magic signature
- structure version
- BIOS boot drive
- conventional memory in KB
- extended memory in KB
- approximate total memory in KB
- FAT12 root directory entry count
- FAT12 root directory physical address
- cached file table physical address
- cached file count

## Paging Layout

Bootstrap paging currently creates a single identity-mapped page table for the first 4 MiB.

Special cases:

- virtual page `0x00000000` is unmapped
- virtual page at `0x00001000` is present but read-only
- the kernel stack guard page is unmapped

The frame bitmap tracks physical frames up to 16 MiB and reserves the bootstrap-used region before runtime frame allocation begins.

## Heap Layout

- heap start: `0x00120000`
- heap size:  `0x00100000`
- allocator type: free-list
- allocator behaviors:
  - 16-byte alignment
  - first-fit search
  - block split on allocation
  - coalescing on free
  - allocation / free counters
  - high-water tracking

## Disk Format

The generated image is a 1.44 MB FAT12 floppy.

The Python image builder writes:

- stage 1 to sector 0
- `STAGE2.BIN` to the data area
- `KERNEL.BIN` to the data area
- extra text files such as `README.TXT` and `STATUS.TXT`
- FAT entries and root directory records to match all files

## Design Goal

Lum-OS aims for a reliable educational vertical slice:

- understandable boot flow
- no dependency on external FAT tooling
- clear serial diagnostics
- reproducible end-to-end tests
