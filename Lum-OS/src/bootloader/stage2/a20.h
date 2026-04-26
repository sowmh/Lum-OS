// src/bootloader/stage2/a20.h
#pragma once
#include "stdint.h"

// Enable A20 line (required for accessing >1MB memory)
// Returns: 1 if successful, 0 if failed
uint8_t _cdecl enable_a20(void);

// Test if A20 line is enabled
// Returns: 1 if enabled, 0 if disabled
uint8_t _cdecl test_a20(void);
