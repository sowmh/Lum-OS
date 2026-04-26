org 0x0000
bits 16

%define STAGE2_PHYSICAL_BASE  0x00020000
%define BOOT_INFO_SEGMENT     0x0900
%define ROOT_DIR_BUFFER       0x3000
%define FAT_BUFFER            0x5000
%define ROOT_DIR_LBA          19
%define ROOT_DIR_SECTORS      14
%define FAT_LBA               1
%define FAT_SECTORS           9
%define DATA_START_LBA        33
%define KERNEL_LOAD_SEGMENT   0x1000
%define KERNEL_ENTRY          0x00010000
%define STACK_TOP             0xFFFE
%define SERIAL_PORT           0x3F8
%define GDT_CODE_SELECTOR     0x08
%define GDT_DATA_SELECTOR     0x10
%define BOOTINFO_MAGIC        0x304D554C

%define BOOTINFO_VERSION      4
%define BOOTINFO_BOOT_DRIVE   5
%define BOOTINFO_CONV_KB      6
%define BOOTINFO_EXT_KB       8
%define BOOTINFO_TOTAL_KB     10
%define BOOTINFO_ROOTDIR_ENTRIES 14
%define BOOTINFO_ROOTDIR_ADDR    16

start:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, STACK_TOP
    sti

    mov [boot_drive], dl

    call serial_init
    mov si, msg_stage2_banner
    call puts

    call write_boot_info

    mov si, msg_loading_kernel
    call puts
    call load_kernel
    jc load_failure

    mov si, msg_kernel_loaded
    call puts

    call enable_a20

    mov si, msg_entering_pm
    call puts

    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax
    jmp dword GDT_CODE_SELECTOR:(STAGE2_PHYSICAL_BASE + protected_mode_entry)

load_failure:
    mov si, msg_kernel_failed
    call puts
.hang:
    cli
    hlt
    jmp .hang

write_boot_info:
    push ax
    push di
    push es

    mov ax, BOOT_INFO_SEGMENT
    mov es, ax
    xor di, di

    mov dword [es:di + 0], BOOTINFO_MAGIC
    mov byte [es:di + BOOTINFO_VERSION], 2

    mov al, [boot_drive]
    mov [es:di + BOOTINFO_BOOT_DRIVE], al

    int 0x12
    mov [es:di + BOOTINFO_CONV_KB], ax

    xor ax, ax
    mov [es:di + BOOTINFO_EXT_KB], ax

    mov ah, 0x88
    int 0x15
    jc .store_total
    mov [es:di + BOOTINFO_EXT_KB], ax

.store_total:
    xor eax, eax
    mov ax, [es:di + BOOTINFO_EXT_KB]
    add eax, 1024
    mov [es:di + BOOTINFO_TOTAL_KB], eax

    mov word [es:di + BOOTINFO_ROOTDIR_ENTRIES], 224
    mov dword [es:di + BOOTINFO_ROOTDIR_ADDR], STAGE2_PHYSICAL_BASE + ROOT_DIR_BUFFER

    pop es
    pop di
    pop ax
    ret

load_kernel:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, cs
    mov es, ax
    mov bx, ROOT_DIR_BUFFER
    mov ax, ROOT_DIR_LBA
    mov cl, ROOT_DIR_SECTORS
    mov dl, [boot_drive]
    call disk_read
    jc .fail

    mov di, ROOT_DIR_BUFFER
    mov cx, 224

.find_entry:
    cmp byte [es:di], 0x00
    je .fail
    cmp byte [es:di], 0xE5
    je .next_entry

    push di
    mov si, kernel_file_name
    mov cx, 11
    repe cmpsb
    pop di
    je .entry_found

.next_entry:
    add di, 32
    loop .find_entry
    jmp .fail

.entry_found:
    mov ax, [es:di + 26]
    mov [kernel_cluster], ax

    mov ax, cs
    mov es, ax
    mov bx, FAT_BUFFER
    mov ax, FAT_LBA
    mov cl, FAT_SECTORS
    mov dl, [boot_drive]
    call disk_read
    jc .fail

    mov ax, KERNEL_LOAD_SEGMENT
    mov es, ax
    xor bx, bx

.load_cluster:
    mov ax, [kernel_cluster]
    cmp ax, 2
    jb .fail

    sub ax, 2
    add ax, DATA_START_LBA
    mov cl, 1
    mov dl, [boot_drive]
    call disk_read
    jc .fail

    call advance_kernel_buffer

    mov ax, [kernel_cluster]
    call fat12_next_cluster
    cmp ax, 0x0FF8
    jae .done
    mov [kernel_cluster], ax
    jmp .load_cluster

.done:
    clc
    jmp .out

.fail:
    stc

.out:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

advance_kernel_buffer:
    add bx, 512
    jnc .done
    mov ax, es
    add ax, 0x20
    mov es, ax
.done:
    ret

fat12_next_cluster:
    push bx
    push dx
    push si

    mov bx, 3
    mul bx
    mov bx, 2
    div bx

    mov si, FAT_BUFFER
    add si, ax
    mov ax, [si]

    test dx, dx
    jz .even_cluster
    shr ax, 4
    jmp .done

.even_cluster:
    and ax, 0x0FFF

.done:
    pop si
    pop dx
    pop bx
    ret

disk_read:
    push ax
    push bx
    push cx
    push dx
    push di
    push cx

    call lba_to_chs

    pop ax
    mov ah, 0x02
    mov di, 3

.retry:
    pusha
    stc
    int 0x13
    jnc .success
    popa
    call disk_reset
    dec di
    test di, di
    jnz .retry
    stc
    jmp .done

.success:
    popa
    clc

.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [sectors_per_track]
    inc dx
    mov cx, dx

    xor dx, dx
    div word [heads]
    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret

disk_reset:
    pusha
    mov ah, 0x00
    stc
    int 0x13
    popa
    ret

enable_a20:
    in al, 0x92
    or al, 0x02
    out 0x92, al
    ret

serial_init:
    mov dx, SERIAL_PORT + 1
    xor al, al
    out dx, al

    mov dx, SERIAL_PORT + 3
    mov al, 0x80
    out dx, al

    mov dx, SERIAL_PORT + 0
    mov al, 0x01
    out dx, al

    mov dx, SERIAL_PORT + 1
    xor al, al
    out dx, al

    mov dx, SERIAL_PORT + 3
    mov al, 0x03
    out dx, al

    mov dx, SERIAL_PORT + 2
    mov al, 0xC7
    out dx, al

    mov dx, SERIAL_PORT + 4
    mov al, 0x0B
    out dx, al
    ret

serial_putc_raw:
    push dx

.wait:
    mov dx, SERIAL_PORT + 5
    in al, dx
    test al, 0x20
    jz .wait

    mov dx, SERIAL_PORT
    mov al, [serial_char]
    out dx, al

    pop dx
    ret

bios_putc_raw:
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    ret

putc:
    cmp al, 10
    jne .raw

    push ax
    mov al, 13
    mov [serial_char], al
    call bios_putc_raw
    call serial_putc_raw
    pop ax

.raw:
    mov [serial_char], al
    call bios_putc_raw
    call serial_putc_raw
    ret

puts:
    push ax

.loop:
    lodsb
    test al, al
    jz .done
    call putc
    jmp .loop

.done:
    pop ax
    ret

bits 32
protected_mode_entry:
    mov eax, GDT_DATA_SELECTOR
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x0009FC00
    jmp GDT_CODE_SELECTOR:KERNEL_ENTRY

bits 16
align 8
gdt_start:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd STAGE2_PHYSICAL_BASE + gdt_start

boot_drive:          db 0
kernel_cluster:      dw 0
serial_char:         db 0
sectors_per_track:   dw 18
heads:               dw 2

kernel_file_name:    db 'KERNEL  BIN'

msg_stage2_banner:   db 'Lum-OS stage2: serial online', 10, 0
msg_loading_kernel:  db 'Loading kernel.bin from FAT12...', 10, 0
msg_kernel_loaded:   db 'Kernel loaded successfully.', 10, 0
msg_entering_pm:     db 'Switching to 32-bit protected mode...', 10, 0
msg_kernel_failed:   db 'Kernel load failed. System halted.', 10, 0
