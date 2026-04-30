# Lum-OS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-x86-blue.svg)]()
[![Build](https://img.shields.io/badge/build-NASM-green.svg)]()

A minimal x86 operating system that boots end-to-end from a FAT12 floppy image into a 32-bit protected-mode kernel with an interactive shell.

## 🚀 Features

### Bootloader (Two-Stage)
- **Stage 1**: Boot sector that loads `STAGE2.BIN` from the FAT12 root directory
- **Stage 2**: Real-mode loader that:
  - Initializes serial output (COM1)
  - Gathers basic memory information
  - Loads `KERNEL.BIN` into memory
  - Enables the A20 line
  - Switches to 32-bit protected mode

### Kernel
- 32-bit protected-mode kernel
- Dual output support: VGA text mode (80x25) and COM1 serial
- Interactive shell with built-in commands:
  - `help` — Display available commands
  - `about` — System information
  - `clear` — Clear the screen
  - `mem` — Display memory information
  - `ls` — List files in root directory
  - `heap` — Display heap information
  - `ticks` — Display timer ticks
  - `uptime` — Display system uptime
  - `alloc <bytes>` — Allocate memory
  - `free <addr>` — Free memory
  - `memtest` — Run memory test
  - `echo <text>` — Echo text to screen
  - `reboot` — Restart the system
  - `halt` — Halt the CPU
- IDT initialized with exception handlers (0-31) and IRQ stubs (32-47)
- PIC remap + PIT timer initialization + IRQ-driven keyboard input queue
- Paging enabled (`CR0.PG`) with an identity-mapped bootstrap virtual memory layout
- Basic memory protection hardening:
  - null page unmapped
  - stack guard page
  - page-fault diagnostics include `CR2`
- Heap manager upgraded from bump allocation to free-list allocation with:
  - first-fit search
  - block split
  - coalescing on free
  - high-water/statistics counters

### Development Tools
- Portable FAT12 image creation (no external dependencies like `mkfs.fat` or `mcopy`)
- Automated smoke tests via QEMU serial interface
- Multiple execution modes (GUI, headless, automated testing)
  - Loads `KERNEL.BIN` into memory
  - Enables the A20 line
  - Switches to 32-bit protected mode

### Kernel
- 32-bit protected-mode kernel
- Dual output support: VGA text mode (80x25) and COM1 serial
- Interactive shell with 8 built-in commands:
  - `help` — Display available commands
  - `about` — System information
  - `clear` — Clear the screen
  - `mem` — Display memory information
  - `ls` — List files in root directory
  - `echo <text>` — Echo text to screen
  - `reboot` — Restart the system
  - `halt` — Halt the CPU

### Development Tools
- Portable FAT12 image creation (no external dependencies like `mkfs.fat` or `mcopy`)
- Automated smoke tests via QEMU serial interface
- Multiple execution modes (GUI, headless, automated testing)

## 📋 Requirements

- **Python 3** (build system)
- **NASM** (assembler)
- **QEMU** (emulator for testing)

### Installation (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install python3 nasm qemu-system-x86
```

### Installation (macOS)

```bash
brew install nasm qemu
```

### Installation (Windows)

Use WSL2 with Ubuntu and follow the Ubuntu instructions above.

## 🏃 Quick Start

### Using Python build tool

```bash
# Build the floppy image
python3 tools/build.py image

# Run in QEMU with GUI
python3 tools/build.py run

# Run headless (serial output to terminal)
python3 tools/build.py run-headless

# Run automated smoke tests
python3 tools/build.py smoke-test
```

### Using Make

```bash
make image        # Build floppy image
make run          # Run in QEMU with GUI
make run-headless # Run headless mode
make smoke-test   # Run automated tests
make clean        # Clean build artifacts
```

**Tip**: `run-headless` is the fastest way to interact with the shell because it exposes COM1 directly to your terminal.

**Tip**: `smoke-test` provides fully automated verification by booting Lum-OS, waiting for the shell prompt, and validating all core commands.

## 📁 Project Structure

```text
Lum-OS/
├── src/
│   ├── bootloader/
│   │   ├── stage1/
│   │   │   └── boot.asm          # FAT12 boot sector (512 bytes)
│   │   └── stage2/
│   │       └── stage2.asm        # Real-mode loader + protected-mode switch
│   └── kernel/
│       └── kernel.asm            # 32-bit kernel and interactive shell
├── tools/
│   ├── build.py                  # Main build orchestrator
│   ├── build_image.py            # FAT12 floppy image generator
│   └── smoke_test.py             # Automated QEMU serial testing
├── docs/
│   ├── user-guide.md
│   ├── developer-guide.md
│   └── system-architecture.md
├── build/                        # Generated build artifacts (created on build)
├── Makefile                      # Make wrapper for build.py
└── README.md
```

## 🔄 Boot Flow

The verified boot sequence is:

1. **BIOS POST** → Loads 512-byte boot sector from floppy to `0x7C00`
2. **Stage 1 Bootloader** → Parses FAT12 filesystem, finds and loads `STAGE2.BIN` to `0x2000:0x0000`
3. **Stage 2 Loader** → Finds `KERNEL.BIN`, stores boot info at `0x9000`, enables A20, switches to protected mode
4. **32-bit Kernel** → Starts at physical address `0x10000`, initializes VGA and serial, launches shell

## 🛠️ Technical Details

<<<<<<< HEAD
This repository now has a clean, working vertical slice with protected mode, interrupts, paging, and a reusable kernel heap.

Good next steps would be:

- multi-page virtual memory manager (page tables beyond first 4 MiB)
- robust page-permission policy by region (code RO/RX, data RW, stricter guards)
- physical memory map ingestion (E820) and frame allocator based on real RAM layout
- kernel heap hardening (`kfree` validation, corruption checks, reusable bins/size classes)
- syscall surface + user-space loader foundation
=======
### Memory Map

| Address Range | Usage |
|--------------|-------|
| `0x0000–0x03FF` | BIOS Interrupt Vector Table |
| `0x0400–0x04FF` | BIOS Data Area |
| `0x0500–0x7BFF` | Free conventional memory |
| `0x7C00–0x7DFF` | Stage 1 bootloader (loaded by BIOS) |
| `0x7E00–0x9FFF` | Available for stack and data |
| `0x9000–0x9FFF` | Boot information structure |
| `0x20000–...` | Stage 2 loader |
| `0x10000–...` | Kernel binary |
| `0xA0000–0xFFFFF` | Video memory and ROM |

### Filesystem

- **Type**: FAT12 (1.44 MB floppy format)
- **Sector size**: 512 bytes
- **Cluster size**: 1 sector
- **Root directory**: Fixed size (224 entries max)
- **Current capabilities**: Read-only access to root directory

## 🎯 Project Status

**Current Development Phase**: ~35-40% Complete

### ✅ Implemented
- [x] Two-stage bootloader (real mode → protected mode)
- [x] FAT12 filesystem driver (read-only)
- [x] 32-bit protected mode kernel
- [x] VGA text mode output (80x25, 16 colors)
- [x] Serial port (COM1) output
- [x] Interactive shell with 8 commands
- [x] Portable build system (no external FS tools)
- [x] Automated testing framework

### 🚧 Planned Features

**Short-term** (Next milestones):
- [ ] Interrupt Descriptor Table (IDT) setup
- [ ] CPU exception handlers (divide by zero, page fault, etc.)
- [ ] Hardware interrupt handlers (timer, keyboard)
- [ ] Keyboard driver (beyond simple polling)
- [ ] Enhanced file operations (read file contents)

**Medium-term**:
- [ ] Memory allocator (heap management)
- [ ] Paging and virtual memory
- [ ] Basic syscall interface
- [ ] User-space program loading (ELF or custom format)
- [ ] Simple task scheduler

**Long-term**:
- [ ] Full FAT12 write support
- [ ] Multi-tasking and process isolation
- [ ] Device driver framework
- [ ] Network stack (basic TCP/IP)
- [ ] Graphical user interface

## 🤝 Contributing

Contributions are welcome! This is an educational project, perfect for learning OS development.

### Areas to Contribute
- Implement missing features from the roadmap
- Add more shell commands
- Improve documentation
- Write unit tests
- Port to other architectures (x86-64, ARM)

### Development Notes
- The older C/Open Watcom files remain in the repository as reference material
- The current bootable path uses **NASM only** and is driven by `tools/build.py`
- All assembly code follows Intel syntax

## 📚 Learning Resources

If you're new to OS development, check out:
- [OSDev Wiki](https://wiki.osdev.org/) — Comprehensive OS development resource
- [Writing a Simple Operating System from Scratch](https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf) — Excellent tutorial by Nick Blundell
- [The little book about OS development](https://littleosbook.github.io/) — Practical guide to x86 OS development
- [xv6: A simple Unix-like teaching OS](https://pdos.csail.mit.edu/6.828/2012/xv6.html) — MIT's teaching OS

## 📄 License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

This project was built as a learning exercise in operating system development. Special thanks to the OSDev community for their excellent documentation and tutorials.

---

**Note**: Lum-OS is an educational project and is not intended for production use.
>>>>>>> a7226617488a95108750e1ff21c2a4a0afd512f2

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
