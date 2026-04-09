#include "a20.h"
#include "stdint.h"

// Intenta habilitar A20 usando la BIOS
int _cdecl enable_a20() {
    __asm {
        mov ax, 0x2401
        int 0x15
    }
    return 1; // Simplificado para este paso
}
