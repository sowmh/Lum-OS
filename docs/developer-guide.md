# Lum OS Developer Guide

## Overview

Lum OS is a lightweight, open-source operating system for multimedia, development, and gaming on limited hardware. This guide helps developers contribute to the project and understand the OS internals.

## Prerequisites

### Required Knowledge

* C, C++, and Assembly language
* Makefiles and build systems
* Basic understanding of OS concepts:

  * Memory management
  * Process scheduling
  * File systems
  * Hardware abstraction

### Required Tools

* GCC - Compiler
* NASM - Assembler
* QEMU - Emulator
* GRUB - Bootloader
* xorriso - ISO creation
* Git - Version control

## Build System

### Make Targets

| Command      | Description                     |
| ------------ | ------------------------------- |
| `make build` | Compile kernel and bootloader   |
| `make iso`   | Generate bootable ISO           |
| `make run`   | Boot ISO in QEMU                |
| `make clean` | Remove compiled objects and ISO |

### Compilation Flags

```makefile
# C Compiler
CFLAGS = -m32 -c -ffreestanding -O2 -fno-stack-protector -fno-pic

# Assembly
ASFLAGS = -f elf32

# Linker
LDFLAGS = -m elf_i386 -T targets/x86_64/linker.ld
```

**Notes:**

* `-m32`: Generate 32-bit code
* `-ffreestanding`: Freestanding environment (no standard library)
* `-O2`: Optimization level 2
* `-fno-stack-protector`: Disable stack protection
* `-fno-pic`: Disable position-independent code

## Project Structure

```
lum-os/
├── src/impl/x86_64/boot/
│   ├── entry.asm
│   ├── header.o
│   ├── main.o
│   └── kernel.c
├── docs/
│   ├── user-guide.md
│   ├── developer-guide.md
│   └── system-architecture.md
├── iso/boot/grub/
├── targets/x86_64/linker.ld
└── Makefile
```

## Development Workflow

1. **Fork & Clone**

```bash
git clone https://github.com/yourusername/lum-os.git
cd lum-os
```

2. **Create Feature Branch**

```bash
git checkout -b feature/your-feature
```

3. **Develop**

* Kernel: `src/impl/x86_64/`
* Bootloader: `src/impl/x86_64/boot/`
* Documentation: `docs/`

4. **Build & Test**

```bash
make build
make iso
make run
```

5. **Commit & Push**

```bash
git add .
git commit -m "feat: add feature"
git push origin feature/your-feature
```

6. **Pull Request**
   Open PR with a clear description of changes.

## Testing

```bash
make clean
make build
make iso
make run
```

## Contributing Guidelines

* Follow the existing code style
* Comment complex logic
* Keep functions modular and focused
* Update documentation when necessary
* Test all changes locally

**Commit Message Format:**

```
type(scope): short description
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`

## References

* [OSDev Wiki](https://wiki.osdev.org/)
* [GRUB Manual](https://www.gnu.org/software/grub/manual/)
* [QEMU Documentation](https://www.qemu.org/docs/)
* [GCC Documentation](https://gcc.gnu.org/onlinedocs/)
