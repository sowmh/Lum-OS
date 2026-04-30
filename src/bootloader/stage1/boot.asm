org 0x7C00
bits 16
%define ENDL 0x0D, 0x0A
jmp short start
nop
bdb_oem:                    db 'MSWIN4.1'
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880
bdb_media_descriptor_type:  db 0F0h
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0
ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h
ebr_volume_label:           db 'LUM OS     '
ebr_system_id:              db 'FAT12   '
start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    push es
    push word .after
    retf
.after:
    mov [ebr_drive_number], dl
    mov si, msg_loading
    call puts
    push es
    mov ah, 08h
    int 13h
    jc floppy_error
    pop es
    and cl, 0x3F
    xor ch, ch
    mov [bdb_sectors_per_track], cx
    inc dh
    mov [bdb_heads], dh
    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx
    add ax, [bdb_reserved_sectors]
    push ax
    mov ax, [bdb_dir_entries_count]
    shl ax, 5
    xor dx, dx
    div word [bdb_bytes_per_sector]
    test dx, dx
    jz .a
    inc ax
.a:
    mov cl, al
    pop ax
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read
    xor bx, bx
    mov di, buffer
.b:
    mov si, file_kernel_bin
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je .c
    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl .b
    jmp kernel_not_found_error
.c:
    mov ax, [di + 26]
    mov [kernel_cluster], ax
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read
    mov bx, KERNEL_LOAD_SEGMENT
    mov es, bx
    mov bx, KERNEL_LOAD_OFFSET
.d:
    mov ax, [kernel_cluster]
    add ax, 31
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read
    add bx, [bdb_bytes_per_sector]
    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx
    mov si, buffer
    add si, ax
    mov ax, [ds:si]
    or dx, dx
    jz .e
.f:
    shr ax, 4
    jmp .g
.e:
    and ax, 0x0FFF
.g:
    cmp ax, 0x0FF8
    jae .h
    mov [kernel_cluster], ax
    jmp .d
.h:
    mov dl, [ebr_drive_number]
    mov ax, KERNEL_LOAD_SEGMENT
    mov ds, ax
    mov es, ax
    jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET
    cli
    hlt
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot
kernel_not_found_error:
    mov si, msg_kernel_not_found
    call puts
    jmp wait_key_and_reboot
wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0
puts:
    push si
    push ax
    push bx
.a:
    lodsb
    or al, al
    jz .b
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .a
.b:
    pop bx
    pop ax
    pop si
    ret
lba_to_chs:
    push ax
    push dx
    xor dx, dx
    div word [bdb_sectors_per_track]
    inc dx
    mov cx, dx
    xor dx, dx
    div word [bdb_heads]
    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah
    pop ax
    mov dl, al
    pop ax
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
    mov ah, 02h
    mov di, 3
.c:
    pusha
    stc
    int 13h
    jnc .d
    popa
    call disk_reset
    dec di
    test di, di
    jnz .c
    jmp floppy_error
.d:
    popa
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret
msg_loading:          db 'Loading stage2...', ENDL, 0
msg_read_failed:      db 'Read from disk failed!', ENDL, 0
msg_kernel_not_found: db 'STAGE2.BIN not found!', ENDL, 0
file_kernel_bin:      db 'STAGE2  BIN'
kernel_cluster:       dw 0
KERNEL_LOAD_SEGMENT   equ 0x2000
KERNEL_LOAD_OFFSET    equ 0
times 510-($-$$) db 0
dw 0AA55h
buffer:
