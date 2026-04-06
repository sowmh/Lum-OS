```markdown
# Lum-OS

Ultra-lightweight Operating System: powerful, fast, and minimal.

[Features](#features) | [Getting Started](#getting-started) | [Building](#building) | [Architecture](#architecture) | [Roadmap](#roadmap) | [Contributing](#contributing)

---

## Overview
Lum-OS is a custom operating system built from scratch, designed to be lightweight and educational. This project demonstrates fundamental OS concepts including:

* Custom Bootloader (two-stage boot process)
* Real Mode to Protected Mode transition
* FAT12 File System support
* Kernel development in C and Assembly
* Hardware abstraction layer

---

## Features

### Current Implementation
* **Two-Stage Bootloader**
    * Stage 1: MBR boot sector (512 bytes)
    * Stage 2: Extended bootloader with C support
* **FAT12 File System**
    * Read files from disk, directory traversal, and file loading into memory
* **Real Mode Operations**
    * BIOS interrupts, Disk I/O (INT 13h), and Screen output (INT 10h)

### In Progress
* Protected Mode kernel
* Memory management (paging, virtual memory)
* Process scheduling
* Device drivers (keyboard, VGA, timer)
* Shell/CLI interface

---

## Getting Started

### Prerequisites
Install the following tools:

**Debian/Ubuntu**
```bash
sudo apt-get install nasm gcc make mtools qemu-system-x86 bochs bochs-sdl
```

**Arch Linux**
```bash
sudo pacman -S nasm gcc make mtools qemu bochs
```

**Fedora**
```bash
sudo dnf install nasm gcc make mtools qemu bochs
```

**Additional Requirements:**
* **Open Watcom C Compiler** (for 16-bit code): [Download](https://github.com/open-watcom/open-watcom-v2/releases)
* Install to `/opt/open-watcom/`

### Quick Start
```bash
git clone [https://github.com/sowmh/Lum-OS.git](https://github.com/sowmh/Lum-OS.git)
cd Lum-OS
make all
./run.sh
```

---

## Building

### Build Process
```bash
# Full build
make all

# Build individual components
make bootloader
make kernel
make tools_fat

# Clean build artifacts
make clean
```

### Build Output
* `build/main_floppy.img`: Bootable floppy image (1.44MB)
* `build/stage1.bin`: First stage bootloader
* `build/stage2.bin`: Second stage bootloader
* `build/kernel.bin`: Kernel binary

---

## Architecture

### Boot Process
1. **BIOS POST**
2. **Stage 1 Boot (MBR)**: Initializes hardware, loads FAT12, finds STAGE2.BIN.
3. **Stage 2 Boot**: Sets up GDT, enables A20 line, enters Protected Mode.
4. **Kernel**: Initializes drivers, starts scheduler, loads shell.

### Memory Layout
* `0x00000000 - 0x000003FF`: Real Mode IVT
* `0x00007C00 - 0x00007DFF`: Stage 1 Bootloader
* `0x00020000 - 0x0002FFFF`: Stage 2 Bootloader
* `0x00100000 - ...`: Kernel (1MB+)

---

## Project Structure
```
Lum-OS/
├── src/
│   ├── bootloader/
│   │   ├── stage1/       # MBR bootloader (ASM)
│   │   └── stage2/       # C entry point & utilities
│   └── kernel/           # Kernel source
├── build/                # Build output
├── tools/                # FAT12 utility
├── docs/                 # Documentation
└── Makefile              # Main build system
```

---

## Roadmap
* **Phase 1**: Bootloader & Basic I/O (Done)
* **Phase 2**: Protected Mode (In Progress)
* **Phase 3**: Memory Management (Planned)
* **Phase 4**: Drivers (Planned)
* **Phase 5**: Multitasking (Planned)
* **Phase 6**: User Interface (Planned)

---

## Contributing
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/name`).
3. Commit changes (`git commit -m 'feat: description'`).
4. Push to the branch (`git push origin feature/name`).
5. Open a Pull Request.

---

## License
Licensed under the MIT License.

---

## Contact
* **Author**: sowmh
* **Project Link**: [https://github.com/sowmh/Lum-OS](https://github.com/sowmh/Lum-OS)
```

