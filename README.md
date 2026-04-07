# 🌟 Lum-OS

<div align="center">

![Lum-OS Logo](docs/logo.png)

**Ultra-lightweight Operating System: powerful, fast, and minimal.**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![Made with Assembly](https://img.shields.io/badge/made%20with-Assembly-red.svg)]()
[![Made with C](https://img.shields.io/badge/made%20with-C-blue.svg)]()

[Features](#-features) • [Getting Started](#-getting-started) • [Building](#-building) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 📋 Overview

Lum-OS is a custom operating system built from scratch, designed to be lightweight and educational. This project demonstrates fundamental OS concepts including:

- **Custom Bootloader** (two-stage boot process)
- **Real Mode → Protected Mode transition**
- **FAT12 File System** support
- **Kernel development** in C and Assembly
- **Hardware abstraction layer**

## ✨ Features

### Current Implementation

- ✅ **Two-Stage Bootloader**
  - Stage 1: MBR boot sector (512 bytes)
  - Stage 2: Extended bootloader with C support
  
- ✅ **FAT12 File System**
  - Read files from disk
  - Directory traversal
  - File loading into memory

- ✅ **Real Mode Operations**
  - BIOS interrupts
  - Disk I/O (INT 13h)
  - Screen output (INT 10h)

### 🚧 In Progress

- 🔨 Protected Mode kernel
- 🔨 Memory management (paging, virtual memory)
- 🔨 Process scheduling
- 🔨 Device drivers (keyboard, VGA, timer)
- 🔨 Shell/CLI interface

## 🚀 Getting Started

### Prerequisites

Before building Lum-OS, ensure you have the following tools installed:

```bash
# Debian/Ubuntu
sudo apt-get install nasm gcc make mtools qemu-system-x86 bochs bochs-sdl

# Arch Linux
sudo pacman -S nasm gcc make mtools qemu bochs

# Fedora
sudo dnf install nasm gcc make mtools qemu bochs
```

**Additional Requirements:**
- **Open Watcom C Compiler** (for 16-bit code)
  - Download from: https://github.com/open-watcom/open-watcom-v2/releases
  - Install to `/opt/open-watcom/`

### Quick Start

```bash
# Clone the repository
git clone https://github.com/sowmh/Lum-OS.git
cd Lum-OS

# Build the OS
make all

# Run in QEMU
./run.sh

# Or run in Bochs
bochs -f bochs_config

# Debug mode
./debug.sh
```

## 🔧 Building

### Build Process

The build system uses GNU Make to orchestrate compilation:

```bash
# Full build (creates floppy image)
make all

# Build individual components
make bootloader    # Build stage1 and stage2
make kernel        # Build kernel
make tools_fat     # Build FAT filesystem tool

# Clean build artifacts
make clean
```

### Build Output

After building, you'll find:

```
build/
├── main_floppy.img    # Bootable floppy image (1.44MB)
├── stage1.bin         # First stage bootloader (512 bytes)
├── stage2.bin         # Second stage bootloader
├── kernel.bin         # Kernel binary
└── tools/
    └── fat            # FAT filesystem utility
```

## 🏗️ Architecture

### Boot Process

```
┌─────────────────┐
│   BIOS POST     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Stage 1 Boot   │ ← MBR (512 bytes)
│  (boot.asm)     │   - Initialize hardware
└────────┬────────┘   - Load FAT12
         │            - Find STAGE2.BIN
         ▼
┌─────────────────┐
│  Stage 2 Boot   │ ← Extended bootloader
│  (main.c)       │   - Set up GDT
└────────┬────────┘   - Enable A20 line
         │            - Enter Protected Mode
         ▼
┌─────────────────┐
│     Kernel      │ ← 32-bit protected mode
│   (kernel.bin)  │   - Initialize drivers
└─────────────────┘   - Start scheduler
                      - Load shell
```

### Memory Layout

```
0x00000000 - 0x000003FF : Real Mode IVT (Interrupt Vector Table)
0x00000400 - 0x000004FF : BIOS Data Area
0x00000500 - 0x00007BFF : Free memory (stage2 stack)
0x00007C00 - 0x00007DFF : Stage 1 bootloader (512 bytes)
0x00007E00 - 0x0009FFFF : Free memory
0x00020000 - 0x0002FFFF : Stage 2 bootloader (loaded here)
0x00100000 - ...        : Kernel (loaded at 1MB+)
```

### Project Structure

```
Lum-OS/
├── src/
│   ├── bootloader/
│   │   ├── stage1/
│   │   │   ├── boot.asm          # MBR bootloader (FAT12)
│   │   │   └── Makefile
│   │   └── stage2/
│   │       ├── main.c            # C entry point
│   │       ├── crt0.asm          # C runtime startup
│   │       ├── stdio.c/h         # Basic I/O functions
│   │       ├── x86.asm/h         # CPU utilities
│   │       └── Makefile
│   └── kernel/
│       ├── main.asm              # Kernel entry point
│       └── Makefile
├── build/                        # Build output (generated)
├── tools/
│   └── fat/                      # FAT12 filesystem tool
├── docs/                         # Documentation
├── Makefile                      # Main build system
├── bochs_config                  # Bochs emulator config
├── run.sh                        # Quick run script
└── debug.sh                      # Debug script
```

## 📚 Documentation

- [User Guide](docs/user-guide.md) - How to use Lum-OS
- [Developer Guide](docs/developer-guide.md) - Contributing to the project
- [System Architecture](docs/system-architecture.md) - Technical details

## 🛠️ Development

### Testing

```bash
# Run in QEMU (recommended for development)
qemu-system-i386 -fda build/main_floppy.img

# Run in Bochs (better debugging)
bochs -f bochs_config -q

# Debug with GDB (if kernel has debug symbols)
qemu-system-i386 -s -S -fda build/main_floppy.img
gdb build/kernel.bin
(gdb) target remote localhost:1234
```

### Adding Features

1. **Modify the bootloader**: `src/bootloader/stage2/main.c`
2. **Extend the kernel**: `src/kernel/main.asm` (or create `main.c`)
3. **Rebuild**: `make clean && make all`
4. **Test**: `./run.sh`

### Common Tasks

```bash
# Add a new file to the disk image
echo "Hello from Lum-OS" > myfile.txt
mcopy -i build/main_floppy.img myfile.txt ::myfile.txt

# List files on the disk
mdir -i build/main_floppy.img

# Extract a file
mcopy -i build/main_floppy.img ::test.txt output.txt

# View disk structure
./build/tools/fat build/main_floppy.img
```

## 🎯 Roadmap

### Phase 1: Bootloader & Basic I/O ✅
- [x] Stage 1 bootloader (MBR)
- [x] FAT12 filesystem support
- [x] Stage 2 bootloader
- [x] Basic text output

### Phase 2: Protected Mode 🚧
- [ ] GDT (Global Descriptor Table) setup
- [ ] IDT (Interrupt Descriptor Table) setup
- [ ] Switch to 32-bit protected mode
- [ ] Basic exception handlers

### Phase 3: Memory Management 📋
- [ ] Physical memory manager
- [ ] Paging (virtual memory)
- [ ] Heap allocator (malloc/free)
- [ ] Memory protection

### Phase 4: Drivers 📋
- [ ] Keyboard driver
- [ ] VGA text mode driver
- [ ] Timer (PIT) driver
- [ ] ATA/IDE disk driver

### Phase 5: Multitasking 📋
- [ ] Process control blocks
- [ ] Context switching
- [ ] Scheduler (round-robin)
- [ ] System calls

### Phase 6: User Interface 📋
- [ ] Shell/CLI
- [ ] Basic commands (ls, cat, echo)
- [ ] File system operations
- [ ] Simple text editor

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Convention

We follow conventional commits:

```
feat: add new feature
fix: bug fix
docs: documentation changes
refactor: code refactoring
test: adding tests
chore: maintenance tasks
```

## 📖 Learning Resources

- [OSDev Wiki](https://wiki.osdev.org/) - Comprehensive OS development resource
- [x86 Assembly Guide](https://www.cs.virginia.edu/~evans/cs216/guides/x86.html)
- [Intel Software Developer Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [Bran's Kernel Development Tutorial](http://www.osdever.net/bkerndev/Docs/intro.htm)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OSDev community for invaluable resources
- Bran's Kernel Development Tutorial
- The creators of NASM, GCC, and QEMU

## 📞 Contact

- **Author**: [sowmh](https://github.com/sowmh)
- **Project Link**: [https://github.com/sowmh/Lum-OS](https://github.com/sowmh/Lum-OS)

---

<div align="center">

**Made with ❤️ and Assembly**

[⬆ Back to Top](#-lum-os)

</div>
