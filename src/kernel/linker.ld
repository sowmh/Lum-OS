ENTRY(_start)

SECTIONS
{
    . = 0x10000;  /* Kernel loads at 64KB */
    
    .text : ALIGN(4096)
    {
        *(.text)
        *(.text*)
    }
    
    .rodata : ALIGN(4096)
    {
        *(.rodata)
        *(.rodata*)
        *(.rdata)
        *(.rdata*)
    }
    
    .data : ALIGN(4096)
    {
        *(.data)
        *(.data*)
    }
    
    __bss_start = .;
    .bss : ALIGN(4096)
    {
        *(COMMON)
        *(.bss)
        *(.bss*)
    }
    __bss_end = .;
}
