; src/bootloader/stage2/pmode.asm
bits 16

section .text class=CODE

global _enter_protected_mode

; void _cdecl enter_protected_mode(uint32_t kernel_address)
_enter_protected_mode:
    push bp
    mov bp, sp
    
    ; Get kernel address from stack (4 bytes on 16-bit: high:low)
    mov eax, [bp + 4]       ; Load 32-bit kernel address
    
    ; Disable interrupts
    cli
    
    ; Enable A20 line (should already be enabled, but make sure)
    in al, 0x92
    or al, 2
    out 0x92, al
    
    ; Load GDT (should already be loaded, but reload to be safe)
    ; The GDT descriptor is already set up by setup_gdt()
    
    ; Enable Protected Mode by setting bit 0 of CR0
    mov ebx, cr0
    or ebx, 1
    mov cr0, ebx
    
    ; Far jump to flush pipeline and load CS with code selector (0x08)
    ; Jump to 32-bit code segment
    jmp 0x08:protected_mode_entry

bits 32
protected_mode_entry:
    ; Now in 32-bit protected mode
    
    ; Set up data segment registers
    mov bx, 0x10            ; Data segment selector
    mov ds, bx
    mov es, bx
    mov fs, bx
    mov gs, bx
    mov ss, bx
    
    ; Set up stack pointer (4MB stack)
    mov esp, 0x00400000
    
    ; Jump to kernel
    ; EAX still contains kernel address from earlier
    jmp eax
    
    ; Should never return
hang:
    hlt
    jmp hang
