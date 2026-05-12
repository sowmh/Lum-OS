org 0x0000
bits 16

%define BYTES_PER_SECTOR      512
%define ROOT_DIR_ENTRY_COUNT  224
%define ROOT_DIR_ENTRY_SIZE   32

%define STAGE2_PHYSICAL_BASE   0x00020000
%define BOOT_INFO_SEGMENT      0x0900
%define FILE_CACHE_TABLE_OFFSET 0x0100
%define FILE_CACHE_TABLE_PHYS  0x00009100

%define ROOT_DIR_BUFFER        0x3000
%define FAT_BUFFER             0x5000

%define ROOT_DIR_LBA           19
%define ROOT_DIR_SECTORS       14
%define FAT_LBA                1
%define FAT_SECTORS            9
%define DATA_START_LBA         33

%define FILE_CACHE_BASE        0x00030000
%define FILE_CACHE_LIMIT       0x00090000
%define FILE_CACHE_MAX         8
%define FILE_CACHE_ENTRY_SIZE  24

%define KERNEL_LOAD_SEGMENT    0x1000
%define KERNEL_ENTRY           0x00010000
%define STACK_TOP              0xFFFE

%define SERIAL_PORT            0x3F8
%define GDT_CODE_SELECTOR      0x08
%define GDT_DATA_SELECTOR      0x10

%define BOOTINFO_MAGIC         0x304D554C
%define BOOTINFO_VERSION_VALUE 4
%define BOOTINFO_VERSION       4
%define BOOTINFO_BOOT_DRIVE    5
%define BOOTINFO_CONV_KB       6
%define BOOTINFO_EXT_KB        8
%define BOOTINFO_TOTAL_KB      10
%define BOOTINFO_ROOTDIR_ENTRIES 14
%define BOOTINFO_ROOTDIR_ADDR  16
%define BOOTINFO_FILE_TABLE_ADDR 20
%define BOOTINFO_FILE_COUNT    24
%define BOOTINFO_FB_ADDR       26
%define BOOTINFO_FB_WIDTH      30
%define BOOTINFO_FB_HEIGHT     34
%define BOOTINFO_FB_PITCH      38
%define BOOTINFO_FB_BPP        42
%define BOOTINFO_FB_RED_POS    43
%define BOOTINFO_FB_GREEN_POS  44
%define BOOTINFO_FB_BLUE_POS   45

%define VBE_INFO_BLOCK_OFFSET  0x0800
%define MODE_INFO_BLOCK_OFFSET 0x0A00

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

    call cache_extra_files

    mov si, msg_kernel_loaded
    call puts

    call vesa_init

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
    mov byte [es:di + BOOTINFO_VERSION], BOOTINFO_VERSION_VALUE

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

    mov word [es:di + BOOTINFO_ROOTDIR_ENTRIES], ROOT_DIR_ENTRY_COUNT
    mov dword [es:di + BOOTINFO_ROOTDIR_ADDR], STAGE2_PHYSICAL_BASE + ROOT_DIR_BUFFER
    mov dword [es:di + BOOTINFO_FILE_TABLE_ADDR], FILE_CACHE_TABLE_PHYS
    mov dword [es:di + BOOTINFO_FILE_COUNT], 0

    mov dword [es:di + BOOTINFO_FB_ADDR], 0
    mov dword [es:di + BOOTINFO_FB_WIDTH], 0
    mov dword [es:di + BOOTINFO_FB_HEIGHT], 0
    mov dword [es:di + BOOTINFO_FB_PITCH], 0
    mov byte [es:di + BOOTINFO_FB_BPP], 0
    mov byte [es:di + BOOTINFO_FB_RED_POS], 0
    mov byte [es:di + BOOTINFO_FB_GREEN_POS], 0
    mov byte [es:di + BOOTINFO_FB_BLUE_POS], 0

    pop es
    pop di
    pop ax
    ret

load_kernel:
    push ax
    push bx
    push di
    push es

    call load_root_directory
    jc .fail
    call load_fat
    jc .fail

    mov si, kernel_file_name
    call find_root_entry
    jc .fail

    mov ax, KERNEL_LOAD_SEGMENT
    mov es, ax
    xor bx, bx
    call load_root_entry_to_buffer
    jc .fail

    clc
    jmp .out

.fail:
    stc

.out:
    pop es
    pop di
    pop bx
    pop ax
    ret

load_root_directory:
    push ax
    push bx
    push cx
    push dx
    push es

    mov ax, cs
    mov es, ax
    mov bx, ROOT_DIR_BUFFER
    mov ax, ROOT_DIR_LBA
    mov cl, ROOT_DIR_SECTORS
    mov dl, [boot_drive]
    call disk_read

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

load_fat:
    push ax
    push bx
    push cx
    push dx
    push es

    mov ax, cs
    mov es, ax
    mov bx, FAT_BUFFER
    mov ax, FAT_LBA
    mov cl, FAT_SECTORS
    mov dl, [boot_drive]
    call disk_read

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

find_root_entry:
    push ax
    push cx
    push si

    mov di, ROOT_DIR_BUFFER
    mov cx, ROOT_DIR_ENTRY_COUNT

.scan:
    cmp byte [di], 0x00
    je .not_found
    call is_regular_root_entry
    jc .next

    push si
    push di
    call entry_name_equals
    pop di
    pop si
    test ax, ax
    jnz .found

.next:
    add di, ROOT_DIR_ENTRY_SIZE
    loop .scan

.not_found:
    stc
    jmp .out

.found:
    clc

.out:
    pop si
    pop cx
    pop ax
    ret

is_regular_root_entry:
    mov al, [di]
    cmp al, 0x00
    je .skip
    cmp al, 0xE5
    je .skip
    mov al, [di + 11]
    cmp al, 0x0F
    je .skip
    test al, 0x08
    jnz .skip
    clc
    ret

.skip:
    stc
    ret

entry_name_equals:
    push bx
    push cx
    push si
    push di

    mov cx, 11

.compare:
    mov al, [di]
    mov bl, [si]
    cmp al, bl
    jne .no_match
    inc di
    inc si
    loop .compare

    mov ax, 1
    jmp .done

.no_match:
    xor ax, ax

.done:
    pop di
    pop si
    pop cx
    pop bx
    ret

load_root_entry_to_buffer:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, [di + 26]
    mov [file_cluster], ax

.load_cluster:
    mov ax, [file_cluster]
    cmp ax, 2
    jb .fail
    sub ax, 2
    add ax, DATA_START_LBA
    mov cl, 1
    mov dl, [boot_drive]
    call disk_read
    jc .fail
    call advance_buffer
    mov ax, [file_cluster]
    call fat12_next_cluster
    cmp ax, 0x0FF8
    jae .done
    mov [file_cluster], ax
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

advance_buffer:
    add bx, BYTES_PER_SECTOR
    jnc .done
    mov ax, es
    add ax, 0x20
    mov es, ax
.done:
    ret

cache_extra_files:
    push ax
    push cx
    push di

    mov dword [cache_next_phys], FILE_CACHE_BASE
    mov dword [cached_file_count], 0

    mov di, ROOT_DIR_BUFFER
    mov cx, ROOT_DIR_ENTRY_COUNT

.scan:
    cmp byte [di], 0x00
    je .finish

    push cx
    push di
    call cache_root_entry_if_needed
    pop di
    pop cx

    add di, ROOT_DIR_ENTRY_SIZE
    loop .scan

.finish:
    call sync_cached_file_count

    pop di
    pop cx
    pop ax
    ret

cache_root_entry_if_needed:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    call is_regular_root_entry
    jc .skip

    mov eax, [cached_file_count]
    cmp eax, FILE_CACHE_MAX
    jae .skip

    mov eax, [di + 28]
    test eax, eax
    jz .skip
    mov ax, [di + 26]
    cmp ax, 2
    jb .skip

    mov si, kernel_file_name
    call entry_name_equals
    test ax, ax
    jnz .skip

    mov si, stage2_file_name
    call entry_name_equals
    test ax, ax
    jnz .skip

    mov eax, [di + 28]
    mov [cache_temp_size], eax
    add eax, BYTES_PER_SECTOR - 1
    and eax, 0xFFFFFE00
    mov [cache_temp_rounded], eax

    mov edx, [cache_next_phys]
    mov [cache_temp_addr], edx
    add eax, edx
    cmp eax, FILE_CACHE_LIMIT
    ja .skip

    mov eax, [cache_temp_addr]
    shr eax, 4
    mov es, ax
    xor bx, bx
    call load_root_entry_to_buffer
    jc .skip

    mov si, di
    call write_cached_file_entry

    mov eax, [cache_next_phys]
    add eax, [cache_temp_rounded]
    mov [cache_next_phys], eax
    inc dword [cached_file_count]

.skip:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

write_cached_file_entry:
    push ax
    push bx
    push cx
    push di
    push es

    mov ax, BOOT_INFO_SEGMENT
    mov es, ax

    mov ax, [cached_file_count]
    mov bx, FILE_CACHE_TABLE_OFFSET

.offset_loop:
    test ax, ax
    jz .offset_done
    add bx, FILE_CACHE_ENTRY_SIZE
    dec ax
    jmp .offset_loop

.offset_done:
    mov di, bx
    xor ax, ax
    mov cx, 8
    rep stosw

    mov di, bx
    call fat_name_to_string

    mov eax, [cache_temp_addr]
    mov [es:bx + 16], eax
    mov eax, [cache_temp_size]
    mov [es:bx + 20], eax

    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

fat_name_to_string:
    push ax
    push bx
    push cx
    push si
    push di

    mov bx, si
    mov cx, 8

.name_loop:
    test cx, cx
    jz .scan_ext
    mov al, [bx]
    cmp al, ' '
    je .scan_ext
    stosb
    inc bx
    dec cx
    jmp .name_loop

.scan_ext:
    mov bx, si
    add bx, 8
    mov cx, 3

.ext_probe:
    test cx, cx
    jz .done
    cmp byte [bx], ' '
    jne .emit_ext
    inc bx
    dec cx
    jmp .ext_probe

.emit_ext:
    mov al, '.'
    stosb
    mov bx, si
    add bx, 8
    mov cx, 3

.ext_loop:
    test cx, cx
    jz .done
    mov al, [bx]
    cmp al, ' '
    je .done
    stosb
    inc bx
    dec cx
    jmp .ext_loop

.done:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

sync_cached_file_count:
    push ax
    push es

    mov ax, BOOT_INFO_SEGMENT
    mov es, ax
    mov eax, [cached_file_count]
    mov [es:BOOTINFO_FILE_COUNT], eax

    pop es
    pop ax
    ret

vesa_init:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    push si

    mov ax, cs
    mov es, ax

    mov si, msg_vesa_detect
    call puts

    mov di, VBE_INFO_BLOCK_OFFSET
    mov ax, 0x4F00
    int 0x10
    cmp ax, 0x004F
    jne .vesa_fail

    mov si, msg_vesa_found
    call puts

    call vesa_set_mode

    jmp .vesa_done

.vesa_fail:
    mov si, msg_vesa_fail
    call puts

.vesa_done:
    pop si
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

vesa_set_mode:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    push si

    mov ax, cs
    mov es, ax

    mov di, MODE_INFO_BLOCK_OFFSET
    mov cx, 0x115
    mov ax, 0x4F01
    int 0x10
    cmp ax, 0x004F
    jne .mode_set_fail

    mov si, msg_vesa_800_trying
    call puts

.mode_supported:
    mov ax, cx
    or ax, 0x4000
    mov bx, ax
    mov ax, 0x4F02
    int 0x10
    cmp ax, 0x004F
    jne .mode_set_fail

    mov si, msg_vesa_success
    call puts

    call vesa_store_info

    jmp .vesa_set_done

.mode_set_fail:
    mov si, msg_vesa_mode_fail
    call puts

.vesa_set_done:
    pop si
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

vesa_store_info:
    push ax
    push bx
    push cx
    push edx
    push edi
    push es
    push si
    push ds

    mov ax, cs
    mov es, ax

    mov ax, BOOT_INFO_SEGMENT
    mov ds, ax

    mov di, MODE_INFO_BLOCK_OFFSET

    mov eax, [es:di + 40]
    mov [ds:BOOTINFO_FB_ADDR], eax

    mov eax, [es:di + 12]
    and eax, 0xFFFF
    mov [ds:BOOTINFO_FB_WIDTH], eax

    mov eax, [es:di + 14]
    and eax, 0xFFFF
    mov [ds:BOOTINFO_FB_HEIGHT], eax

    mov eax, [es:di + 16]
    and eax, 0xFFFF
    mov [ds:BOOTINFO_FB_PITCH], eax

    mov al, [es:di + 25]
    mov [ds:BOOTINFO_FB_BPP], al

    mov al, [es:di + 27]
    mov [ds:BOOTINFO_FB_RED_POS], al

    mov al, [es:di + 29]
    mov [ds:BOOTINFO_FB_GREEN_POS], al

    mov al, [es:di + 31]
    mov [ds:BOOTINFO_FB_BLUE_POS], al

    mov ax, cs
    mov ds, ax

    mov si, msg_vesa_info
    call puts

    pop ds
    pop si
    pop es
    pop edi
    pop edx
    pop cx
    pop bx
    pop ax
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

boot_drive:           db 0
file_cluster:         dw 0
serial_char:          db 0
sectors_per_track:    dw 18
heads:                dw 2

cache_next_phys:      dd 0
cached_file_count:    dd 0
cache_temp_addr:      dd 0
cache_temp_size:      dd 0
cache_temp_rounded:   dd 0

kernel_file_name:     db 'KERNEL  BIN'
stage2_file_name:     db 'STAGE2  BIN'

msg_stage2_banner:    db 'Lum-OS stage2: serial online', 10, 0
msg_loading_kernel:   db 'Loading kernel.bin from FAT12...', 10, 0
msg_kernel_loaded:    db 'Kernel loaded successfully.', 10, 0
msg_vesa_detect:      db 'Detecting VESA VBE 2.0...', 10, 0
msg_vesa_found:       db 'VESA VBE found. Querying modes...', 10, 0
msg_vesa_1024_fail:   db 'Mode 1024x768 not available, trying 800x600...', 10, 0
msg_vesa_800_trying:  db 'Setting 800x600 32bpp mode...', 10, 0
msg_vesa_success:     db 'Graphics mode set successfully.', 10, 0
msg_vesa_fail:        db 'VBE not available. Continuing with text mode.', 10, 0
msg_vesa_mode_fail:   db 'Failed to set graphics mode. Continuing with text mode.', 10, 0
msg_vesa_info:        db 'Framebuffer initialized.', 10, 0
msg_entering_pm:      db 'Switching to 32-bit protected mode...', 10, 0
msg_kernel_failed:    db 'Kernel load failed. System halted.', 10, 0
