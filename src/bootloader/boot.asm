org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

jmp short _start
nop

bpb_oem:                db 'MSWIN4.1'
bpb_bytes_per_sector:   dw 512
bpb_sectors_per_cluster:db 1
bpb_reserved_sectors:   dw 1
bpb_fat_count:          db 2
bpb_root_entries:       dw 0E0h
bpb_total_sectors:      dw 2880
bpb_media:              db 0F0h
bpb_sectors_per_fat:    dw 9
bpb_sectors_per_track:  dw 18
bpb_heads:              dw 2
bpb_hidden_sectors:     dd 0
bpb_large_sector_count: dd 0

ebr_drive_number:       db 0
                        db 0
ebr_signature:          db 29h
ebr_volume_id:          dd 12345678h
ebr_volume_label:       db 'LUM OS     '
ebr_system_id:          db 'FAT12   '

_start:
    jmp main

print_str:
    push ax
    push bx
    push si
.next_char:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .next_char
.done:
    pop si
    pop bx
    pop ax
    ret

main:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [ebr_drive_number], dl

    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00
    call disk_read

    mov si, msg_hello
    call print_str

    cli
    hlt

read_failed:
    mov si, msg_read_failed
    call print_str
    jmp wait_key_reboot

wait_key_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bpb_sectors_per_track]
    inc dx
    mov cl, dl

    xor dx, dx
    div word [bpb_heads]
    mov dh, dl
    mov ch, al

    shl ah, 6
    or cl, ah

    pop dx
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

    mov ah, 0x02
    mov di, 3

.read_retry:
    pusha
    stc
    int 0x13
    jnc .read_ok

    popa
    call disk_reset

    dec di
    jnz .read_retry

    jmp read_failed

.read_ok:
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
    int 0x13
    jc disk_reset_fail
    popa
    ret

disk_reset_fail:
    popa
    jmp read_failed

msg_hello:       db 'Hello world!', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
