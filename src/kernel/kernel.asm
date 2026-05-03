org 0x10000
bits 32
%define VGA_TEXT                0xB8000
%define VGA_COLS                80
%define VGA_ROWS                25
%define VGA_ROW_BYTES           (VGA_COLS * 2)
%define COM1                    0x3F8
%define BOOT_INFO_ADDR          0x00009000
%define BOOTINFO_MAGIC          0x304D554C
%define BOOTINFO_CONV_KB        6
%define BOOTINFO_EXT_KB         8
%define BOOTINFO_TOTAL_KB       10
%define BOOTINFO_ROOTDIR_ENTRIES 14
%define BOOTINFO_ROOTDIR_ADDR    16
%define BOOTINFO_FILE_TABLE_ADDR 20
%define BOOTINFO_FILE_COUNT      24
%define LINE_BUFFER_SIZE        128
%define KBD_QUEUE_SIZE           64
%define TIMER_HZ                100
%define KBD_DEBOUNCE_TICKS        2
%define HEAP_START          0x00120000
%define HEAP_SIZE           0x00100000
%define HEAP_MAGIC          0x4B484541
%define HEAP_HDR_SIZE       16
%define MAX_PHYS_MEM        0x01000000
%define FRAME_SIZE          4096
%define FRAME_COUNT         (MAX_PHYS_MEM / FRAME_SIZE)
%define KERNEL_STACK_TOP    0x00110000
%define KERNEL_STACK_GUARD  0x0010C000
%define BOOTSTRAP_RESERVED_END (HEAP_START + HEAP_SIZE)
%define FILE_CACHE_ENTRY_SIZE     24
%macro INSTALL_ISR 2
    mov eax, %2
    mov ebx, %1
    call set_idt_gate
%endmacro
start:
    cli
    mov esp, KERNEL_STACK_TOP
    mov byte [text_color], 0x0F
    call init_idt
    call serial_init
    call init_irq
    call init_paging
    call init_memory
    call clear_screen
    call show_banner
shell_loop:
    mov esi, prompt
    call console_write
    call read_line
    call dispatch_command
    jmp shell_loop
show_banner:
    mov byte [text_color], 0x1E
    mov esi, banner_top
    call console_write
    mov esi, banner_mid
    call console_write
    mov esi, banner_bottom
    call console_write
    mov byte [text_color], 0x0A
    mov esi, boot_ok_message
    call console_write
    mov byte [text_color], 0x07
    mov esi, shell_hint
    call console_write
    ret
init_idt:
    INSTALL_ISR 0, isr0
    INSTALL_ISR 1, isr1
    INSTALL_ISR 2, isr2
    INSTALL_ISR 3, isr3
    INSTALL_ISR 4, isr4
    INSTALL_ISR 5, isr5
    INSTALL_ISR 6, isr6
    INSTALL_ISR 7, isr7
    INSTALL_ISR 8, isr8
    INSTALL_ISR 9, isr9
    INSTALL_ISR 10, isr10
    INSTALL_ISR 11, isr11
    INSTALL_ISR 12, isr12
    INSTALL_ISR 13, isr13
    INSTALL_ISR 14, isr14
    INSTALL_ISR 15, isr15
    INSTALL_ISR 16, isr16
    INSTALL_ISR 17, isr17
    INSTALL_ISR 18, isr18
    INSTALL_ISR 19, isr19
    INSTALL_ISR 20, isr20
    INSTALL_ISR 21, isr21
    INSTALL_ISR 22, isr22
    INSTALL_ISR 23, isr23
    INSTALL_ISR 24, isr24
    INSTALL_ISR 25, isr25
    INSTALL_ISR 26, isr26
    INSTALL_ISR 27, isr27
    INSTALL_ISR 28, isr28
    INSTALL_ISR 29, isr29
    INSTALL_ISR 30, isr30
    INSTALL_ISR 31, isr31
    INSTALL_ISR 32, irq32
    INSTALL_ISR 33, irq33
    INSTALL_ISR 34, irq34
    INSTALL_ISR 35, irq35
    INSTALL_ISR 36, irq36
    INSTALL_ISR 37, irq37
    INSTALL_ISR 38, irq38
    INSTALL_ISR 39, irq39
    INSTALL_ISR 40, irq40
    INSTALL_ISR 41, irq41
    INSTALL_ISR 42, irq42
    INSTALL_ISR 43, irq43
    INSTALL_ISR 44, irq44
    INSTALL_ISR 45, irq45
    INSTALL_ISR 46, irq46
    INSTALL_ISR 47, irq47
    lidt [idtr]
    ret
init_irq:
    call pic_remap
    call pit_init
    sti
    ret
pic_remap:
    mov al, 0x11
    out 0x20, al
    out 0xA0, al
    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al
    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xA1, al
    mov al, 0x01
    out 0x21, al
    out 0xA1, al
    mov al, 0xFC
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al
    ret
pit_init:
    mov al, 0x36
    out 0x43, al
    mov ax, 11932
    out 0x40, al
    mov al, ah
    out 0x40, al
    ret
init_paging:
    call init_frame_bitmap
    call setup_identity_paging
    ret
init_frame_bitmap:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    mov edi, frame_bitmap
    mov ecx, FRAME_COUNT / 8
    xor eax, eax
    rep stosb
    mov dword [frame_reserved_count], 0
    mov dword [frame_dynamic_count], 0
    xor ecx, ecx
.reserve_loop:
    cmp ecx, BOOTSTRAP_RESERVED_END / FRAME_SIZE
    jae .done
    mov eax, ecx
    shr eax, 3
    movzx edx, byte [frame_bitmap + eax]
    mov ebx, ecx
    and ebx, 7
    bts edx, ebx
    mov [frame_bitmap + eax], dl
    inc ecx
    jmp .reserve_loop
.done:
    mov dword [frame_reserved_count], BOOTSTRAP_RESERVED_END / FRAME_SIZE
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
setup_identity_paging:
    push eax
    push ecx
    push edi
    mov edi, page_directory
    mov ecx, 1024
    xor eax, eax
    rep stosd
    mov edi, first_page_table
    mov ecx, 1024
    xor eax, eax
    rep stosd
    xor ecx, ecx
.map_loop:
    mov eax, ecx
    shl eax, 12
    or eax, 0x003
    mov [first_page_table + ecx * 4], eax
    inc ecx
    cmp ecx, 1024
    jb .map_loop
    mov dword [first_page_table + 0], 0
    mov dword [first_page_table + ((KERNEL_STACK_GUARD >> 12) * 4)], 0
    mov eax, [first_page_table + ((0x1000 >> 12) * 4)]
    and eax, 0xFFFFFFFD
    mov [first_page_table + ((0x1000 >> 12) * 4)], eax
    mov eax, first_page_table
    or eax, 0x003
    mov [page_directory + 0], eax
    mov eax, page_directory
    mov cr3, eax
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    jmp short $+2
    pop edi
    pop ecx
    pop eax
    ret
set_idt_gate:
    push ebx
    push edi
    shl ebx, 3
    mov edi, idt_start
    add edi, ebx
    mov word [edi], ax
    mov word [edi + 2], 0x08
    mov byte [edi + 4], 0
    mov byte [edi + 5], 0x8E
    shr eax, 16
    mov word [edi + 6], ax
    pop edi
    pop ebx
    ret
isr_common:
    cli
    pushad
    mov esi, exception_prefix
    call console_write
    mov eax, [esp + 32]
    call print_uint32
    mov esi, exception_error_prefix
    call console_write
    mov eax, [esp + 36]
    call print_uint32
    mov eax, [esp + 32]
    cmp eax, 14
    jne .no_pf
    mov esi, pf_addr_prefix
    call console_write
    mov eax, cr2
    call print_uint32
    mov esi, pf_addr_suffix
    call console_write
.no_pf:
    mov esi, exception_halt_suffix
    call console_write
.halt:
    hlt
    jmp .halt
irq_common:
    pushad
    mov eax, [esp + 32]
    cmp eax, 32
    jne .check_keyboard
    inc dword [timer_ticks]
    jmp .send_eoi
.check_keyboard:
    cmp eax, 33
    jne .send_eoi
    call irq_keyboard
.send_eoi:
    mov al, 0x20
    cmp eax, 40
    jb .master_only
    out 0xA0, al
.master_only:
    out 0x20, al
    popad
    add esp, 8
    iretd
irq_keyboard:
    push eax
    push ebx
    push ecx
    push edx
    in al, 0x64
    test al, 0x01
    jz .done
    in al, 0x60
    cmp al, 0xE0
    je .done
    cmp al, 0x2A
    je .shift_pressed
    cmp al, 0x36
    je .shift_pressed
    cmp al, 0xAA
    je .shift_released
    cmp al, 0xB6
    je .shift_released
    cmp al, 0x3A
    je .caps_toggle
    cmp al, 0x1D
    je .ctrl_pressed
    cmp al, 0x9D
    je .ctrl_released
    cmp al, 0x38
    je .alt_pressed
    cmp al, 0xB8
    je .alt_released
    test al, 0x80
    jnz .done
    movzx ecx, byte [last_make_scancode]
    cmp al, cl
    jne .new_make
    mov ecx, [timer_ticks]
    sub ecx, [last_make_tick]
    cmp ecx, KBD_DEBOUNCE_TICKS
    jb .done
.new_make:
    mov [last_make_scancode], al
    mov ecx, [timer_ticks]
    mov [last_make_tick], ecx
    movzx ebx, al
    movzx ecx, byte [kbd_shift]
    test ecx, ecx
    jz .map_normal
    mov al, [kbd_scancode_shift_table + ebx]
    jmp .mapped
.map_normal:
    mov al, [kbd_scancode_table + ebx]
.mapped:
    test al, al
    jz .done
    cmp al, 'a'
    jb .check_upper
    cmp al, 'z'
    ja .check_upper
    movzx ecx, byte [kbd_caps]
    test ecx, ecx
    jz .queue
    sub al, 32
    jmp .queue
.check_upper:
    cmp al, 'A'
    jb .queue
    cmp al, 'Z'
    ja .queue
    movzx ecx, byte [kbd_caps]
    test ecx, ecx
    jz .queue
    add al, 32
    jmp .queue
.shift_pressed:
    mov byte [kbd_shift], 1
    jmp .done
.shift_released:
    mov byte [kbd_shift], 0
    jmp .done
.caps_toggle:
    xor byte [kbd_caps], 1
    jmp .done
.ctrl_pressed:
    mov byte [kbd_ctrl], 1
    jmp .done
.ctrl_released:
    mov byte [kbd_ctrl], 0
    jmp .done
.alt_pressed:
    mov byte [kbd_alt], 1
    jmp .done
.alt_released:
    mov byte [kbd_alt], 0
    jmp .done
.queue:
    movzx ebx, byte [kbd_head]
    movzx ecx, byte [kbd_tail]
    mov edx, ebx
    inc edx
    and edx, KBD_QUEUE_SIZE - 1
    cmp edx, ecx
    je .done
    mov [kbd_queue + ebx], al
    mov [kbd_head], dl
.done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
dispatch_command:
    cmp byte [line_buffer], 0
    je .done
    mov esi, line_buffer
    mov edi, cmd_help
    call command_equals
    test eax, eax
    jnz .help
    mov esi, line_buffer
    mov edi, cmd_about
    call command_equals
    test eax, eax
    jnz .about
    mov esi, line_buffer
    mov edi, cmd_clear
    call command_equals
    test eax, eax
    jnz .clear
    mov esi, line_buffer
    mov edi, cmd_mem
    call command_equals
    test eax, eax
    jnz .mem
    mov esi, line_buffer
    mov edi, cmd_ls
    call command_equals
    test eax, eax
    jnz .ls
    mov esi, line_buffer
    mov edi, cmd_files
    call command_equals
    test eax, eax
    jnz .files
    mov esi, line_buffer
    mov edi, cmd_heap
    call command_equals
    test eax, eax
    jnz .heap
    mov esi, line_buffer
    mov edi, cmd_ticks
    call command_equals
    test eax, eax
    jnz .ticks
    mov esi, line_buffer
    mov edi, cmd_uptime
    call command_equals
    test eax, eax
    jnz .uptime
    mov esi, line_buffer
    mov edi, cmd_vmem
    call command_equals
    test eax, eax
    jnz .vmem
    mov esi, line_buffer
    mov edi, cmd_memtest
    call command_equals
    test eax, eax
    jnz .memtest
    mov esi, line_buffer
    mov edi, cmd_halt
    call command_equals
    test eax, eax
    jnz .halt
    mov esi, line_buffer
    mov edi, cmd_reboot
    call command_equals
    test eax, eax
    jnz .reboot
    mov esi, line_buffer
    mov edi, cmd_echo
    call command_equals
    test eax, eax
    jnz .echo_empty
    mov esi, line_buffer
    mov edi, cmd_cat
    call command_equals
    test eax, eax
    jnz .cat_usage
    mov esi, line_buffer
    mov edi, cmd_echo_prefix
    call starts_with
    test eax, eax
    jnz .echo_with_text
    mov esi, line_buffer
    mov edi, cmd_cat_prefix
    call starts_with
    test eax, eax
    jnz .cat
    mov esi, line_buffer
    mov edi, cmd_alloc_prefix
    call starts_with
    test eax, eax
    jnz .alloc
    mov esi, line_buffer
    mov edi, cmd_free_prefix
    call starts_with
    test eax, eax
    jnz .free
    mov esi, unknown_prefix
    call console_write
    mov esi, line_buffer
    call console_write
    mov al, 10
    call console_putc
    jmp .done
.help:
    mov esi, help_text
    call console_write
    jmp .done
.about:
    mov esi, about_text
    call console_write
    jmp .done
.clear:
    call clear_screen
    call show_banner
    jmp .done
.mem:
    call print_memory_report
    jmp .done
.ls:
    call print_root_directory
    jmp .done
.files:
    call print_cached_files_report
    jmp .done
.heap:
    call print_heap_report
    jmp .done
.ticks:
    call print_timer_report
    jmp .done
.uptime:
    call print_uptime_report
    jmp .done
.vmem:
    call print_vmem_report
    jmp .done
.memtest:
    call run_memory_stress_test
    jmp .done
.echo_empty:
    mov al, 10
    call console_putc
    jmp .done
.cat_usage:
    mov esi, cat_usage_text
    call console_write
    jmp .done
.echo_with_text:
    mov esi, line_buffer + 5
    call console_write
    mov al, 10
    call console_putc
    jmp .done
.cat:
    mov esi, line_buffer + 4
    call print_cached_file_contents
    jmp .done
.alloc:
    mov esi, line_buffer + 6
    call parse_uint32
    test edx, edx
    jz .alloc_usage
    test eax, eax
    jz .alloc_usage
    call kmalloc_align16
    test eax, eax
    jz .alloc_failed
    mov esi, alloc_ok_prefix
    call console_write
    call print_uint32
    mov esi, alloc_ok_mid
    call console_write
    mov eax, [last_alloc_size]
    call print_uint32
    mov esi, bytes_suffix
    call console_write
    jmp .done
.alloc_usage:
    mov esi, alloc_usage_text
    call console_write
    jmp .done
.alloc_failed:
    mov esi, alloc_failed_text
    call console_write
    jmp .done
.free:
    mov esi, line_buffer + 5
    call parse_uint32
    test edx, edx
    jz .free_usage
    call kfree
    test edx, edx
    jz .free_failed
    mov esi, free_ok_text
    call console_write
    jmp .done
.free_usage:
    mov esi, free_usage_text
    call console_write
    jmp .done
.free_failed:
    mov esi, free_failed_text
    call console_write
    jmp .done
.halt:
    mov esi, halt_message
    call console_write
.halt_loop:
    cli
    hlt
    jmp .halt_loop
.reboot:
    mov esi, reboot_message
    call console_write
    call reboot_system
    jmp .done
.done:
    ret
print_memory_report:
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .missing
    mov esi, mem_conv_prefix
    call console_write
    movzx eax, word [BOOT_INFO_ADDR + BOOTINFO_CONV_KB]
    call print_uint32
    mov esi, kb_suffix
    call console_write
    mov esi, mem_ext_prefix
    call console_write
    movzx eax, word [BOOT_INFO_ADDR + BOOTINFO_EXT_KB]
    call print_uint32
    mov esi, kb_suffix
    call console_write
    mov esi, mem_total_prefix
    call console_write
    mov eax, [BOOT_INFO_ADDR + BOOTINFO_TOTAL_KB]
    call print_uint32
    mov esi, kb_suffix
    call console_write
    call print_heap_report
    ret
.missing:
    mov esi, mem_missing
    call console_write
    ret
print_root_directory:
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .missing
    mov ebx, [BOOT_INFO_ADDR + BOOTINFO_ROOTDIR_ADDR]
    movzx ecx, word [BOOT_INFO_ADDR + BOOTINFO_ROOTDIR_ENTRIES]
    test ebx, ebx
    jz .missing
    test ecx, ecx
    jz .empty
    mov esi, ls_header
    call console_write
    xor edx, edx
.next_entry:
    test ecx, ecx
    jz .done_listing
    cmp byte [ebx], 0x00
    je .done_listing
    cmp byte [ebx], 0xE5
    je .skip_entry
    mov al, [ebx + 11]
    cmp al, 0x0F
    je .skip_entry
    test al, 0x08
    jnz .skip_entry
    push ecx
    push edx
    push ebx
    mov esi, ebx
    call print_fat_name
    mov esi, ls_spacing
    call console_write
    mov eax, [ebx + 28]
    call print_uint32
    mov esi, bytes_suffix
    call console_write
    pop ebx
    pop edx
    pop ecx
    inc edx
.skip_entry:
    add ebx, 32
    dec ecx
    jmp .next_entry
.done_listing:
    test edx, edx
    jnz .done
.empty:
    mov esi, ls_empty
    call console_write
    ret
.missing:
    mov esi, ls_missing
    call console_write
.done:
    ret
print_cached_files_report:
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .missing
    mov ecx, [BOOT_INFO_ADDR + BOOTINFO_FILE_COUNT]
    test ecx, ecx
    jz .empty
    mov ebx, [BOOT_INFO_ADDR + BOOTINFO_FILE_TABLE_ADDR]
    mov esi, files_header
    call console_write
.next:
    push ecx
    push ebx
    mov esi, ebx
    call console_write
    mov esi, ls_spacing
    call console_write
    mov eax, [ebx + 20]
    call print_uint32
    mov esi, bytes_suffix
    call console_write
    pop ebx
    pop ecx
    add ebx, FILE_CACHE_ENTRY_SIZE
    dec ecx
    jnz .next
    ret
.empty:
    mov esi, files_empty
    call console_write
    ret
.missing:
    mov esi, files_missing
    call console_write
    ret
print_cached_file_contents:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov edi, esi
    call find_cached_file
    test eax, eax
    jz .missing
    mov ebx, eax
    mov ecx, edx
    test ecx, ecx
    jz .done
    mov esi, eax
    call console_write_bytes
    cmp byte [ebx + edx - 1], 10
    je .done
    mov al, 10
    call console_putc
    jmp .done
.missing:
    mov esi, cat_missing_prefix
    call console_write
    mov esi, edi
    call console_write
    mov al, 10
    call console_putc
.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
find_cached_file:
    push ebx
    push ecx
    push esi
    push edi
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .fail
    mov ecx, [BOOT_INFO_ADDR + BOOTINFO_FILE_COUNT]
    test ecx, ecx
    jz .fail
    mov ebx, [BOOT_INFO_ADDR + BOOTINFO_FILE_TABLE_ADDR]
.search:
    push esi
    mov edi, ebx
    call string_equals_ci
    pop esi
    test eax, eax
    jnz .found
    add ebx, FILE_CACHE_ENTRY_SIZE
    dec ecx
    jnz .search
.fail:
    xor eax, eax
    xor edx, edx
    jmp .out
.found:
    mov eax, [ebx + 16]
    mov edx, [ebx + 20]
.out:
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
print_timer_report:
    mov esi, ticks_prefix
    call console_write
    mov eax, [timer_ticks]
    call print_uint32
    mov esi, ticks_suffix
    call console_write
    mov esi, uptime_prefix
    call console_write
    mov eax, [timer_ticks]
    xor edx, edx
    mov ebx, TIMER_HZ
    div ebx
    call print_uint32
    mov esi, seconds_suffix
    call console_write
    ret
print_vmem_report:
    push eax
    push ebx
    push ecx
    push edx
    mov esi, vmem_present_prefix
    call console_write
    xor ebx, ebx
    xor edx, edx
    xor ecx, ecx
.count_loop:
    mov eax, [first_page_table + ecx * 4]
    test eax, 1
    jz .next
    inc ebx
    test eax, 2
    jz .next
    inc edx
.next:
    inc ecx
    cmp ecx, 1024
    jb .count_loop
    mov eax, ebx
    call print_uint32
    mov esi, vmem_total_suffix
    call console_write
    mov esi, vmem_writable_prefix
    call console_write
    mov eax, edx
    call print_uint32
    mov esi, vmem_total_suffix
    call console_write
    mov esi, frames_reserved_prefix
    call console_write
    mov eax, [frame_reserved_count]
    call print_uint32
    mov esi, newline_suffix
    call console_write
    mov esi, frames_runtime_prefix
    call console_write
    mov eax, [frame_dynamic_count]
    call print_uint32
    mov esi, newline_suffix
    call console_write
    mov esi, frames_free_prefix
    call console_write
    mov eax, FRAME_COUNT
    sub eax, [frame_reserved_count]
    sub eax, [frame_dynamic_count]
    call print_uint32
    mov esi, newline_suffix
    call console_write
    mov esi, null_page_prefix
    call console_write
    mov eax, [first_page_table + 0]
    call print_page_state
    mov esi, stack_guard_prefix
    call console_write
    mov eax, [first_page_table + ((KERNEL_STACK_GUARD >> 12) * 4)]
    call print_page_state
    mov esi, readonly_guard_prefix
    call console_write
    mov eax, [first_page_table + ((0x1000 >> 12) * 4)]
    call print_page_state
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
print_page_state:
    test eax, 1
    jz .unmapped
    test eax, 2
    jz .readonly
    mov esi, page_rw_text
    call console_write
    ret
.readonly:
    mov esi, page_ro_text
    call console_write
    ret
.unmapped:
    mov esi, page_unmapped_text
    call console_write
    ret
init_memory:
    mov dword [heap_end], HEAP_START + HEAP_SIZE
    mov dword [last_alloc_size], 0
    mov dword [heap_used_bytes], 0
    mov dword [heap_alloc_count], 0
    mov dword [heap_free_count], 0
    mov dword [heap_high_water], 0
    mov dword [heap_free_head], HEAP_START
    mov dword [HEAP_START + 0], HEAP_SIZE - HEAP_HDR_SIZE
    mov dword [HEAP_START + 4], 0
    mov dword [HEAP_START + 8], 1
    mov dword [HEAP_START + 12], HEAP_MAGIC
    ret
kmalloc_align16:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov [last_alloc_size], eax
    add eax, 15
    and eax, 0xFFFFFFF0
    mov esi, eax                    
    xor edi, edi                    
    mov ebx, [heap_free_head]       
.scan:
    test ebx, ebx
    jz .oom
    mov eax, [ebx + 0]
    cmp eax, esi
    jae .fit
    mov edi, ebx
    mov ebx, [ebx + 4]
    jmp .scan
.fit:
    mov edx, [ebx + 0]              
    mov ecx, edx
    sub ecx, esi
    cmp ecx, HEAP_HDR_SIZE + 16
    jb .use_whole
    mov [ebx + 0], esi
    lea eax, [ebx + HEAP_HDR_SIZE + esi]    
    mov [eax + 0], ecx
    sub dword [eax + 0], HEAP_HDR_SIZE
    mov edx, [ebx + 4]
    mov [eax + 4], edx
    mov dword [eax + 8], 1
    mov dword [eax + 12], HEAP_MAGIC
    test edi, edi
    jz .set_head_split
    mov [edi + 4], eax
    jmp .mark_alloc
.set_head_split:
    mov [heap_free_head], eax
    jmp .mark_alloc
.use_whole:
    mov eax, [ebx + 4]
    test edi, edi
    jz .set_head_whole
    mov [edi + 4], eax
    jmp .mark_alloc
.set_head_whole:
    mov [heap_free_head], eax
.mark_alloc:
    mov dword [ebx + 8], 0
    mov dword [ebx + 12], HEAP_MAGIC
    add dword [heap_used_bytes], esi
    inc dword [heap_alloc_count]
    lea eax, [ebx + HEAP_HDR_SIZE]
    call update_heap_high_water
    jmp .out
.oom:
    xor eax, eax
.out:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
update_heap_high_water:
    push ebx
    push ecx
    mov ebx, eax
    sub ebx, HEAP_START
    mov ecx, [last_alloc_size]
    add ebx, ecx
    cmp ebx, [heap_high_water]
    jbe .done
    mov [heap_high_water], ebx
.done:
    pop ecx
    pop ebx
    ret
print_heap_report:
    mov esi, heap_start_prefix
    call console_write
    mov eax, HEAP_START
    call print_uint32
    mov esi, heap_end_prefix
    call console_write
    mov eax, [heap_end]
    call print_uint32
    mov esi, heap_used_prefix
    call console_write
    mov eax, [heap_used_bytes]
    call print_uint32
    mov esi, bytes_suffix
    call console_write
    mov esi, heap_free_prefix
    call console_write
    mov eax, [heap_end]
    sub eax, HEAP_START
    sub eax, [heap_used_bytes]
    call print_uint32
    mov esi, bytes_suffix
    call console_write
    mov esi, heap_hw_prefix
    call console_write
    mov eax, [heap_high_water]
    call print_uint32
    mov esi, bytes_suffix
    call console_write
    mov esi, heap_ops_prefix
    call console_write
    mov eax, [heap_alloc_count]
    call print_uint32
    mov esi, slash_sep
    call console_write
    mov eax, [heap_free_count]
    call print_uint32
    mov esi, newline_suffix
    call console_write
    ret
kfree:
    push eax
    push ebx
    push ecx
    push esi
    push edi
    xor edx, edx
    test eax, eax
    jz .out
    cmp eax, HEAP_START + HEAP_HDR_SIZE
    jb .out
    cmp eax, [heap_end]
    jae .out
    lea ebx, [eax - HEAP_HDR_SIZE]
    cmp dword [ebx + 12], HEAP_MAGIC
    jne .out
    cmp dword [ebx + 8], 0
    jne .out
    mov dword [ebx + 8], 1
    inc dword [heap_free_count]
    mov ecx, [ebx + 0]
    sub dword [heap_used_bytes], ecx
    xor edi, edi
    mov esi, [heap_free_head]
.find_pos:
    test esi, esi
    jz .insert_here
    cmp esi, ebx
    ja .insert_here
    mov edi, esi
    mov esi, [esi + 4]
    jmp .find_pos
.insert_here:
    mov [ebx + 4], esi
    test edi, edi
    jz .set_head
    mov [edi + 4], ebx
    jmp .coalesce
.set_head:
    mov [heap_free_head], ebx
.coalesce:
    mov esi, [ebx + 4]
    test esi, esi
    jz .coalesce_prev
    lea ecx, [ebx + HEAP_HDR_SIZE]
    add ecx, [ebx + 0]
    cmp ecx, esi
    jne .coalesce_prev
    mov ecx, [esi + 0]
    add [ebx + 0], ecx
    add dword [ebx + 0], HEAP_HDR_SIZE
    mov ecx, [esi + 4]
    mov [ebx + 4], ecx
.coalesce_prev:
    test edi, edi
    jz .ok
    lea ecx, [edi + HEAP_HDR_SIZE]
    add ecx, [edi + 0]
    cmp ecx, ebx
    jne .ok
    mov ecx, [ebx + 0]
    add [edi + 0], ecx
    add dword [edi + 0], HEAP_HDR_SIZE
    mov ecx, [ebx + 4]
    mov [edi + 4], ecx
.ok:
    mov edx, 1
.out:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret
alloc_frame:
    push ebx
    push ecx
    push edx
    xor ecx, ecx
.next:
    cmp ecx, FRAME_COUNT
    jae .fail
    mov ebx, ecx
    shr ebx, 3
    movzx edx, byte [frame_bitmap + ebx]
    mov ebx, ecx
    and ebx, 7
    bt edx, ebx
    jc .used
    bts edx, ebx
    mov ebx, ecx
    shr ebx, 3
    mov [frame_bitmap + ebx], dl
    inc dword [frame_dynamic_count]
    mov eax, ecx
    shl eax, 12
    jmp .out
.used:
    inc ecx
    jmp .next
.fail:
    xor eax, eax
.out:
    pop edx
    pop ecx
    pop ebx
    ret
free_frame:
    push ebx
    push ecx
    cmp eax, BOOTSTRAP_RESERVED_END
    jb .out
    mov ecx, eax
    shr ecx, 12
    cmp ecx, FRAME_COUNT
    jae .out
    mov ebx, ecx
    shr ebx, 3
    movzx eax, byte [frame_bitmap + ebx]
    mov ebx, ecx
    and ebx, 7
    bt eax, ebx
    jnc .out
    btr eax, ebx
    mov ebx, ecx
    shr ebx, 3
    mov [frame_bitmap + ebx], al
    cmp dword [frame_dynamic_count], 0
    je .out
    dec dword [frame_dynamic_count]
.out:
    pop ecx
    pop ebx
    ret
map_page:
    push esi
    push edi
    mov edi, eax
    cmp edi, 0x1000
    jb .fail
    cmp eax, 0x00400000
    jae .fail
    test ecx, 0xFFFFFFF9
    jnz .fail
    test ecx, 0x4
    jz .perm_ok
    cmp edi, HEAP_START
    jb .fail
.perm_ok:
    test ebx, ebx
    jnz .have_phys
    test edx, edx
    jz .fail
    call alloc_frame
    test eax, eax
    jz .fail
    mov ebx, eax
.have_phys:
    mov esi, edi
    shr esi, 12
    mov eax, ebx
    and eax, 0xFFFFF000
    and ecx, 0x6
    or eax, ecx
    or eax, 0x1
    mov [first_page_table + esi * 4], eax
    mov eax, edi
    invlpg [eax]
    mov eax, 1
    pop edi
    pop esi
    ret
.fail:
    xor eax, eax
    pop edi
    pop esi
    ret
unmap_page:
    push ebx
    push ecx
    cmp eax, 0x00400000
    jae .fail
    mov ecx, eax
    shr ecx, 12
    mov ebx, [first_page_table + ecx * 4]
    test ebx, 1
    jz .fail
    and ebx, 0xFFFFF000
    mov eax, ebx
    call free_frame
    mov dword [first_page_table + ecx * 4], 0
    mov eax, ecx
    shl eax, 12
    invlpg [eax]
    mov eax, 1
    jmp .out
.fail:
    xor eax, eax
.out:
    pop ecx
    pop ebx
    ret
is_range_mapped:
    push ecx
    push esi
    xor edx, edx
    test ebx, ebx
    jz .ok
    mov ecx, eax
    add ecx, ebx
    dec ecx
    cmp ecx, 0x003FFFFF
    ja .out
    mov esi, eax
    shr esi, 12
.check:
    mov eax, [first_page_table + esi * 4]
    test eax, 1
    jz .out
    mov eax, ecx
    shr eax, 12
    cmp esi, eax
    jae .ok
    inc esi
    jmp .check
.ok:
    mov edx, 1
.out:
    pop esi
    pop ecx
    ret
safe_memzero:
    push eax
    push ebx
    mov eax, edi
    mov ebx, ecx
    call is_range_mapped
    test edx, edx
    jz .done
    xor eax, eax
    rep stosb
.done:
    pop ebx
    pop eax
    ret
safe_memcpy:
    push eax
    push ebx
    mov eax, edi
    mov ebx, ecx
    call is_range_mapped
    test edx, edx
    jz .done
    mov eax, esi
    mov ebx, ecx
    call is_range_mapped
    test edx, edx
    jz .done
    rep movsb
.done:
    pop ebx
    pop eax
    ret
run_memory_stress_test:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    mov esi, memtest_start_text
    call console_write
    mov ebx, 500
.loop:
    mov eax, 64
    call kmalloc_align16
    test eax, eax
    jz .fail
    push eax
    mov edi, eax
    mov ecx, 64
    call safe_memzero
    pop eax
    call kfree
    test edx, edx
    jz .fail
    dec ebx
    jnz .loop
    mov eax, HEAP_SIZE + 4096
    call kmalloc_align16
    test eax, eax
    jnz .fail
    mov esi, memtest_ok_text
    call console_write
    jmp .out
.fail:
    mov esi, memtest_fail_text
    call console_write
.out:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
parse_uint32:
    xor eax, eax
    xor edx, edx
 .skip_space:
    mov bl, [esi]
    cmp bl, ' '
    je .advance_space
    cmp bl, 9
    je .advance_space
    jmp .prefix_check
.advance_space:
    inc esi
    jmp .skip_space
.prefix_check:
    mov bl, [esi]
    cmp bl, '0'
    jne .decimal
    mov bl, [esi + 1]
    cmp bl, 'x'
    je .hex_start
    cmp bl, 'X'
    je .hex_start
.decimal:
    xor ecx, ecx
.decimal_loop:
    mov bl, [esi]
    test bl, bl
    jz .done
    cmp bl, '0'
    jb .fail
    cmp bl, '9'
    ja .fail
    imul eax, eax, 10
    movzx ebx, bl
    sub ebx, '0'
    add eax, ebx
    inc esi
    inc ecx
    jmp .decimal_loop
.hex_start:
    add esi, 2
    xor ecx, ecx
.hex_loop:
    mov bl, [esi]
    test bl, bl
    jz .done
    cmp bl, '0'
    jb .fail
    cmp bl, '9'
    jbe .hex_digit
    cmp bl, 'A'
    jb .hex_lower
    cmp bl, 'F'
    jbe .hex_upper
.hex_lower:
    cmp bl, 'a'
    jb .fail
    cmp bl, 'f'
    ja .fail
    movzx ebx, bl
    sub ebx, 'a' - 10
    jmp .hex_apply
.hex_upper:
    movzx ebx, bl
    sub ebx, 'A' - 10
    jmp .hex_apply
.hex_digit:
    movzx ebx, bl
    sub ebx, '0'
.hex_apply:
    shl eax, 4
    add eax, ebx
    inc esi
    inc ecx
    jmp .hex_loop
.done:
    test ecx, ecx
    jz .fail
    mov edx, 1
    ret
.fail:
    xor eax, eax
    xor edx, edx
    ret
string_equals_ci:
    push ebx
    push esi
    push edi
.compare:
    mov al, [esi]
    mov bl, [edi]
    cmp al, 'a'
    jb .query_folded
    cmp al, 'z'
    ja .query_folded
    sub al, 32
.query_folded:
    cmp bl, 'a'
    jb .entry_folded
    cmp bl, 'z'
    ja .entry_folded
    sub bl, 32
.entry_folded:
    cmp al, bl
    jne .no_match
    test al, al
    je .match
    inc esi
    inc edi
    jmp .compare
.match:
    mov eax, 1
    jmp .done
.no_match:
    xor eax, eax
.done:
    pop edi
    pop esi
    pop ebx
    ret
console_write_bytes:
    push eax
    push ecx
.loop:
    test ecx, ecx
    jz .done
    lodsb
    call console_putc
    dec ecx
    jmp .loop
.done:
    pop ecx
    pop eax
    ret
print_uptime_report:
    mov eax, [timer_ticks]
    xor edx, edx
    mov ebx, TIMER_HZ
    div ebx
    mov [uptime_seconds], eax
    mov [uptime_tick_remainder], edx
    mov eax, [uptime_tick_remainder]
    imul eax, eax, 1000
    xor edx, edx
    mov ebx, TIMER_HZ
    div ebx
    mov [uptime_millis], eax
    mov esi, uptime_detail_prefix
    call console_write
    mov eax, [uptime_seconds]
    call print_uint32
    mov al, '.'
    call console_putc
    mov eax, [uptime_millis]
    call print_uint32_3pad
    mov esi, seconds_suffix
    call console_write
    ret
print_fat_name:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    mov edx, esi
    mov ecx, 8
.name_loop:
    test ecx, ecx
    jz .check_ext
    mov al, [edx]
    cmp al, ' '
    je .check_ext
    call console_putc
    inc edx
    dec ecx
    jmp .name_loop
.check_ext:
    mov edx, esi
    add edx, 8
    mov ecx, 3
.scan_ext:
    test ecx, ecx
    jz .done
    cmp byte [edx], ' '
    jne .print_ext
    inc edx
    dec ecx
    jmp .scan_ext
.print_ext:
    mov al, '.'
    call console_putc
    mov edx, esi
    add edx, 8
    mov ecx, 3
.ext_loop:
    test ecx, ecx
    jz .done
    mov al, [edx]
    cmp al, ' '
    je .done
    call console_putc
    inc edx
    dec ecx
    jmp .ext_loop
.done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
read_line:
    mov edi, line_buffer
    xor ecx, ecx
.read_char:
    push ecx
    call read_input_char
    pop ecx
    cmp al, 13
    je .finish
    cmp al, 10
    je .finish
    cmp al, 8
    je .backspace
    cmp al, 127
    je .backspace
    cmp ecx, LINE_BUFFER_SIZE - 1
    jae .read_char
    mov [edi + ecx], al
    inc ecx
    push ecx
    call console_putc
    pop ecx
    jmp .read_char
.backspace:
    test ecx, ecx
    jz .read_char
    dec ecx
    push ecx
    call console_backspace
    pop ecx
    jmp .read_char
.finish:
    mov byte [edi + ecx], 0
    mov al, 10
    call console_putc
    ret
read_input_char:
.poll:
    mov dx, COM1 + 5
    in al, dx
    test al, 0x01
    jz .keyboard
    mov dx, COM1
    in al, dx
    ret
.keyboard:
    movzx ebx, byte [kbd_tail]
    movzx ecx, byte [kbd_head]
    cmp ebx, ecx
    je .poll
    mov al, [kbd_queue + ebx]
    inc ebx
    and ebx, KBD_QUEUE_SIZE - 1
    mov [kbd_tail], bl
    ret
command_equals:
    push esi
    push edi
.compare:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .not_equal
    test al, al
    je .equal
    inc esi
    inc edi
    jmp .compare
.equal:
    mov eax, 1
    jmp .done
.not_equal:
    xor eax, eax
.done:
    pop edi
    pop esi
    ret
starts_with:
    push esi
    push edi
.compare:
    mov bl, [edi]
    test bl, bl
    je .match
    mov al, [esi]
    cmp al, bl
    jne .no_match
    inc esi
    inc edi
    jmp .compare
.match:
    mov eax, 1
    jmp .done
.no_match:
    xor eax, eax
.done:
    pop edi
    pop esi
    ret
console_write:
    push eax
.loop:
    lodsb
    test al, al
    jz .done
    call console_putc
    jmp .loop
.done:
    pop eax
    ret
console_putc:
    cmp al, 13
    je .carriage_return
    cmp al, 10
    je .newline
    push eax
    call serial_write_raw
    pop eax
    call vga_write_char
    ret
.carriage_return:
    push eax
    call serial_write_raw
    pop eax
    mov dword [cursor_col], 0
    ret
.newline:
    push eax
    mov al, 13
    call serial_write_raw
    mov al, 10
    call serial_write_raw
    pop eax
    call vga_newline
    ret
console_backspace:
    push eax
    mov al, 8
    call serial_write_raw
    mov al, ' '
    call serial_write_raw
    mov al, 8
    call serial_write_raw
    cmp dword [cursor_col], 0
    jne .same_row
    cmp dword [cursor_row], 0
    je .done
    dec dword [cursor_row]
    mov dword [cursor_col], VGA_COLS - 1
    jmp .erase
.same_row:
    dec dword [cursor_col]
.erase:
    mov eax, [cursor_row]
    imul eax, VGA_COLS
    add eax, [cursor_col]
    shl eax, 1
    mov edi, VGA_TEXT
    add edi, eax
    mov al, ' '
    mov ah, [text_color]
    mov [edi], ax
.done:
    pop eax
    ret
vga_write_char:
    push eax
    push edx
    push edi
    cmp dword [cursor_col], VGA_COLS
    jb .write
    call vga_newline
.write:
    mov dl, al
    mov eax, [cursor_row]
    imul eax, VGA_COLS
    add eax, [cursor_col]
    shl eax, 1
    mov edi, VGA_TEXT
    add edi, eax
    mov al, dl
    mov ah, [text_color]
    mov [edi], ax
    inc dword [cursor_col]
    cmp dword [cursor_col], VGA_COLS
    jb .done
    call vga_newline
.done:
    pop edi
    pop edx
    pop eax
    ret
vga_newline:
    mov dword [cursor_col], 0
    inc dword [cursor_row]
    call vga_scroll_if_needed
    ret
vga_scroll_if_needed:
    cmp dword [cursor_row], VGA_ROWS
    jb .done
    push eax
    push ecx
    push esi
    push edi
    mov esi, VGA_TEXT + VGA_ROW_BYTES
    mov edi, VGA_TEXT
    mov ecx, (VGA_COLS * (VGA_ROWS - 1) * 2) / 4
    rep movsd
    mov edi, VGA_TEXT + (VGA_ROW_BYTES * (VGA_ROWS - 1))
    mov ah, [text_color]
    mov al, ' '
    mov ecx, VGA_COLS
    rep stosw
    mov dword [cursor_row], VGA_ROWS - 1
    pop edi
    pop esi
    pop ecx
    pop eax
.done:
    ret
clear_screen:
    push eax
    push ecx
    push edi
    mov edi, VGA_TEXT
    mov ah, [text_color]
    mov al, ' '
    mov ecx, VGA_COLS * VGA_ROWS
    rep stosw
    mov dword [cursor_row], 0
    mov dword [cursor_col], 0
    pop edi
    pop ecx
    pop eax
    ret
serial_init:
    mov dx, COM1 + 1
    xor al, al
    out dx, al
    mov dx, COM1 + 3
    mov al, 0x80
    out dx, al
    mov dx, COM1 + 0
    mov al, 0x01
    out dx, al
    mov dx, COM1 + 1
    xor al, al
    out dx, al
    mov dx, COM1 + 3
    mov al, 0x03
    out dx, al
    mov dx, COM1 + 2
    mov al, 0xC7
    out dx, al
    mov dx, COM1 + 4
    mov al, 0x0B
    out dx, al
    ret
serial_write_raw:
    push edx
    mov [serial_shadow], al
.wait:
    mov dx, COM1 + 5
    in al, dx
    test al, 0x20
    jz .wait
    mov dx, COM1
    mov al, [serial_shadow]
    out dx, al
    pop edx
    ret
print_uint32:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    mov edi, number_buffer + 15
    mov byte [edi], 0
    dec edi
    mov ebx, 10
    cmp eax, 0
    jne .convert
    mov al, '0'
    call console_putc
    jmp .done
.convert:
    xor edx, edx
    div ebx
    add dl, '0'
    mov [edi], dl
    dec edi
    test eax, eax
    jnz .convert
    lea esi, [edi + 1]
    call console_write
.done:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
print_uint32_3pad:
    push eax
    cmp eax, 100
    jae .print
    mov al, '0'
    call console_putc
    mov eax, [esp]
    cmp eax, 10
    jae .print
    mov al, '0'
    call console_putc
.print:
    mov eax, [esp]
    call print_uint32
    pop eax
    ret
reboot_system:
.wait_ready:
    in al, 0x64
    test al, 0x02
    jnz .wait_ready
    mov al, 0xFE
    out 0x64, al
.hang:
    cli
    hlt
    jmp .hang
%macro ISR_NOERR 1
isr%1:
    push dword 0
    push dword %1
    jmp isr_common
%endmacro
%macro ISR_ERR 1
isr%1:
    push dword %1
    jmp isr_common
%endmacro
ISR_NOERR 0
ISR_NOERR 1
ISR_NOERR 2
ISR_NOERR 3
ISR_NOERR 4
ISR_NOERR 5
ISR_NOERR 6
ISR_NOERR 7
ISR_ERR   8
ISR_NOERR 9
ISR_ERR   10
ISR_ERR   11
ISR_ERR   12
ISR_ERR   13
ISR_ERR   14
ISR_NOERR 15
ISR_NOERR 16
ISR_ERR   17
ISR_NOERR 18
ISR_NOERR 19
ISR_NOERR 20
ISR_NOERR 21
ISR_NOERR 22
ISR_NOERR 23
ISR_NOERR 24
ISR_NOERR 25
ISR_NOERR 26
ISR_NOERR 27
ISR_NOERR 28
ISR_NOERR 29
ISR_ERR   30
ISR_NOERR 31
%macro IRQ_STUB 1
irq%1:
    push dword 0
    push dword %1
    jmp irq_common
%endmacro
IRQ_STUB 32
IRQ_STUB 33
IRQ_STUB 34
IRQ_STUB 35
IRQ_STUB 36
IRQ_STUB 37
IRQ_STUB 38
IRQ_STUB 39
IRQ_STUB 40
IRQ_STUB 41
IRQ_STUB 42
IRQ_STUB 43
IRQ_STUB 44
IRQ_STUB 45
IRQ_STUB 46
IRQ_STUB 47
align 8
idt_start:
    times 256 dq 0
idt_end:
idtr:
    dw idt_end - idt_start - 1
    dd idt_start
text_color:        db 0x0F
serial_shadow:     db 0
cursor_row:        dd 0
cursor_col:        dd 0
timer_ticks:       dd 0
heap_free_head:    dd HEAP_START
heap_end:          dd HEAP_START + HEAP_SIZE
heap_used_bytes:   dd 0
last_alloc_size:   dd 0
heap_alloc_count:  dd 0
heap_free_count:   dd 0
heap_high_water:   dd 0
frame_reserved_count: dd 0
frame_dynamic_count: dd 0
kbd_head:          db 0
kbd_tail:          db 0
kbd_shift:         db 0
kbd_caps:          db 0
kbd_ctrl:          db 0
kbd_alt:           db 0
last_make_scancode: db 0
last_make_tick:    dd 0
kbd_queue:         times KBD_QUEUE_SIZE db 0
banner_top:        db '==============================================================', 10, 0
banner_mid:        db ' Lum-OS kernel online (32-bit protected mode)', 10, 0
banner_bottom:     db '==============================================================', 10, 0
boot_ok_message:   db '[ok] Boot path complete: FAT12 -> stage2 -> protected mode -> kernel', 10, 0
shell_hint:        db 'Type help. Input works from the QEMU keyboard or the serial console.', 10, 10, 0
exception_prefix:  db '[EXCEPTION] vector=', 0
exception_error_prefix: db ' error=', 0
pf_addr_prefix:    db ' cr2=', 0
pf_addr_suffix:    db 10, 0
exception_halt_suffix: db ' System halted.', 10, 0
readonly_page:     db 'Lum-OS read-only guard page', 0
prompt:            db 'lum> ', 0
unknown_prefix:    db 'Unknown command: ', 0
help_text:         db 'Commands: help, about, clear, mem, ls, files, heap, ticks, uptime, vmem, alloc <bytes>, free <addr>, memtest, echo <text>, cat <file>, reboot, halt', 10, 0
alloc_usage_text:  db 'Usage: alloc <bytes>', 10, 0
alloc_failed_text: db 'Allocation failed: out of heap memory.', 10, 0
alloc_ok_prefix:   db 'Allocated at ', 0
alloc_ok_mid:      db ' size=', 0
cat_usage_text:    db 'Usage: cat <file>', 10, 0
cat_missing_prefix: db 'Cached file not found: ', 0
free_usage_text:   db 'Usage: free <addr>', 10, 0
free_failed_text:  db 'Free failed: invalid or already freed block.', 10, 0
free_ok_text:      db 'Block released.', 10, 0
memtest_start_text: db 'Running memory stress test...', 10, 0
memtest_ok_text:   db 'Memory stress test passed.', 10, 0
memtest_fail_text: db 'Memory stress test FAILED.', 10, 0
ticks_prefix:      db 'Timer ticks: ', 0
ticks_suffix:      db ' ticks', 10, 0
uptime_prefix:     db 'Approx uptime: ', 0
uptime_detail_prefix: db 'Uptime exact: ', 0
seconds_suffix:    db ' s', 10, 0
about_text:        db 'Lum-OS is a tiny x86 OS demo with a FAT12 stage1/stage2 loader, PIC/PIT/keyboard interrupts,', 10, 'paging with guard pages, a heap allocator, and cached floppy files readable from the shell.', 10, 0
halt_message:      db 'CPU halted.', 10, 0
reboot_message:    db 'Rebooting system...', 10, 0
mem_conv_prefix:   db 'Conventional memory: ', 0
mem_ext_prefix:    db 'Extended memory:     ', 0
mem_total_prefix:  db 'Approx total memory: ', 0
mem_missing:       db 'Memory info unavailable.', 10, 0
kb_suffix:         db ' KB', 10, 0
ls_header:         db 'Root directory:', 10, 0
files_header:      db 'Cached files:', 10, 0
files_empty:       db 'No cached files available.', 10, 0
files_missing:     db 'Cached file table unavailable.', 10, 0
ls_spacing:        db '  ', 0
bytes_suffix:      db ' bytes', 10, 0
heap_start_prefix: db 'Heap start: ', 0
heap_end_prefix:   db ' end: ', 0
heap_used_prefix:  db 10, 'Heap used: ', 0
heap_free_prefix:  db ' free: ', 0
heap_hw_prefix:    db ' high-water: ', 0
heap_ops_prefix:   db 10, 'Heap ops alloc/free: ', 0
slash_sep:         db '/', 0
newline_suffix:    db 10, 0
ls_empty:          db '<empty>', 10, 0
ls_missing:        db 'Root directory metadata unavailable.', 10, 0
cmd_help:          db 'help', 0
cmd_about:         db 'about', 0
cmd_clear:         db 'clear', 0
cmd_mem:           db 'mem', 0
cmd_ls:            db 'ls', 0
cmd_files:         db 'files', 0
cmd_heap:          db 'heap', 0
cmd_ticks:         db 'ticks', 0
cmd_uptime:        db 'uptime', 0
cmd_vmem:          db 'vmem', 0
cmd_cat:           db 'cat', 0
cmd_echo:          db 'echo', 0
cmd_cat_prefix:    db 'cat ', 0
cmd_echo_prefix:   db 'echo ', 0
cmd_alloc_prefix:  db 'alloc ', 0
cmd_free_prefix:   db 'free ', 0
cmd_memtest:       db 'memtest', 0
cmd_reboot:        db 'reboot', 0
cmd_halt:          db 'halt', 0
kbd_scancode_table:
    db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 0, 0, 10, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 0, 0, 0, 0, 0
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '
    times (128 - ($ - kbd_scancode_table)) db 0
kbd_scancode_shift_table:
    db 0, 27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 8, 9
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 0, 0, 10, 0
    db 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0, '|'
    db 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, '*', 0, ' '
    times (128 - ($ - kbd_scancode_shift_table)) db 0
number_buffer:     times 16 db 0
uptime_seconds:    dd 0
uptime_tick_remainder: dd 0
uptime_millis:     dd 0
vmem_present_prefix: db 'VM pages present: ', 0
vmem_writable_prefix: db 'VM pages writable: ', 0
vmem_total_suffix: db '/1024', 10, 0
frames_reserved_prefix: db 'Frames reserved: ', 0
frames_runtime_prefix: db 'Frames runtime: ', 0
frames_free_prefix: db 'Frames free: ', 0
null_page_prefix:  db 'Null page: ', 0
stack_guard_prefix: db 'Stack guard: ', 0
readonly_guard_prefix: db 'Readonly guard 0x1000: ', 0
page_unmapped_text: db 'unmapped', 10, 0
page_ro_text:      db 'read-only', 10, 0
page_rw_text:      db 'read/write', 10, 0
line_buffer:       times LINE_BUFFER_SIZE db 0
align 4096
page_directory:    times 1024 dd 0
align 4096
first_page_table:  times 1024 dd 0
frame_bitmap:      times (FRAME_COUNT / 8) db 0
