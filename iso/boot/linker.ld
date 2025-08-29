OUTPUT_FORMAT(elf32-i386)
ENTRY(_start)

SECTIONS
{
    . = 0x00100000;

    .multiboot : {
        *(.multiboot)
    }

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .stack : {
        stack_start = .;
        stack_space = . + 4096;
        . = stack_space;
    }

    .bss : {
        *(.bss COMMON)
    }
}
