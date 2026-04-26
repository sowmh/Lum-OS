// src/bootloader/stage2/disk.h
#pragma once
#include "stdint.h"

// Load kernel from disk to memory
// Returns: 1 on success, 0 on failure
uint8_t _cdecl load_kernel(uint8_t drive, uint32_t load_address);
