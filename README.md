# Lum-OS

<p align="center">
  <img src="docs/logo.png" alt="Lum-OS Logo" width="200">
</p>

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Language](https://img.shields.io/badge/language-C%2FAssembly-orange.svg)]()
[![Status](https://img.shields.io/badge/status-In%20Development-yellow.svg)]()

**Lum-OS** is a lightweight, from-scratch operating system built in C and Assembly, designed for low-resource PCs.  
It includes a custom bootloader, kernel, drivers, and will support its own file system.

## Features

### Implemented
- Custom bootloader
- Disk I/O operations (basic disk reading)

### In Development
- FAT file system

### Planned
- Memory management
- Preemptive multitasking
- Command-line shell
- Lightweight GUI

## Build & Run

### Prerequisites
- GCC cross-compiler toolchain
- NASM assembler
- QEMU emulator
- Make

### Build
```bash
git clone https://github.com/sowmh/Lum-OS.git
cd Lum-OS
make all
make run
```

## Roadmap
- Complete FAT file system
- Implement memory management
- Add multitasking and shell
- Develop basic GUI

## License
This project is licensed under the MIT License.
