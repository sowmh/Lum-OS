System Architecture - Lum OS
1. Overview

Lum OS is designed as a lightweight, modular, and highly efficient operating system, built to run on x86_64 architectures with minimal hardware requirements. Its architecture separates user-space applications from the kernel to ensure stability, security, and performance.

2. Architecture Layers
┌─────────────────────────────┐
│      User Applications      │
├─────────────────────────────┤
│       System Libraries      │
├─────────────────────────────┤
│         User Space          │
├─────────────────────────────┤
│         Kernel Space        │
├────────────┬────────────────┤
│  Drivers   │   File System   │
├────────────┼────────────────┤
│ Memory Mgmt│ Process Mgmt    │
├────────────┴────────────────┤
│        Hardware Abstraction │
└─────────────────────────────┘
2.1 User Space

Applications: End-user programs running isolated from the kernel.

System Libraries: Provide API for applications to interact safely with the kernel.

2.2 Kernel Space

Core Kernel: Handles process management, memory management, and system calls.

Drivers: Interface directly with hardware devices.

File System: Manages storage, read/write operations, and file organization.

Hardware Abstraction Layer (HAL): Provides standardized interfaces for hardware access.

3. Memory Management

Paging: Virtual memory management to isolate processes.

Heap and Stack: Kernel and application memory allocations.

Memory Protection: Prevents user-space processes from accessing kernel memory.

4. Process Management

Scheduler: Manages CPU allocation among processes.

Inter-Process Communication (IPC): Allows processes to exchange information.

System Calls: Interface for user-space to request kernel services.

5. Drivers and Hardware

Keyboard, Mouse, Display: Basic input/output drivers.

Storage Devices: SATA, NVMe, and virtual disk support.

Networking: TCP/IP stack for future network support.

6. File System

Supported File Systems: Initial support for FAT32; ext2 planned.

File Operations: Open, read, write, close, and directory management.

7. Boot Process

BIOS/UEFI Initialization: Hardware initialized.

GRUB Bootloader: Loads the kernel from ISO or disk.

Kernel Initialization: Memory, drivers, and system structures initialized.

Transition to User Space: Starts initial processes and system services.

8. Development Notes

Kernel and bootloader are compiled with nasm and gcc.

ISO image created via grub-mkrescue and tested in QEMU.

Future improvements include graphical environment and advanced device support.

9. References

OSDev Wiki: https://wiki.osdev.org

GRUB Manual: https://www.gnu.org/software/grub/manual/

QEMU Documentation: https://www.qemu.org/documentation/
