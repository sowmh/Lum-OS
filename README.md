# Lum-OS

<p align="center">
  <img src="docs/logo.png" alt="Lum-OS Logo" width="200">
</p>

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Language](https://img.shields.io/badge/language-C%2FAssembly-orange.svg)]()
[![Status](https://img.shields.io/badge/status-In%20Development-yellow.svg)]()

**Lum-OS** is a lightweight, from-scratch operating system built in C and Assembly, designed for low-resource PCs.  
It features a custom bootloader, kernel, drivers, and **a basic FAT12 file system implemented**.

## Features

### Implemented

* Custom bootloader (stage1 & stage2)
* Kernel (basic initialization and booting)
* Disk I/O operations (read/write support)
* Basic FAT12 file system support

### In Development

* Full FAT file system with extended features
* Tools for disk management

### Planned

* Memory management
* Preemptive multitasking
* Command-line shell
* Lightweight GUI

## Build & Run

### Prerequisites

* GCC cross-compiler toolchain
* NASM assembler
* Open Watcom for 16-bit C compilation
* QEMU emulator (or Bochs)
* Make

### Build

```bash
git clone https://github.com/sowmh/Lum-OS.git
cd Lum-OS
make all

