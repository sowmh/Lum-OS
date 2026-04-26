// src/bootloader/stage2/pmode.h
#pragma once
#include "stdint.h"

// Enter 32-bit protected mode and jump to kernel
void _cdecl enter_protected_mode(uint32_t kernel_address);
