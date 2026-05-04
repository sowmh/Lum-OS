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
%define COLOR_BODY               0x07
%define COLOR_PANEL              0x1F
%define COLOR_PROMPT             0x0B
%define COLOR_SECTION            0x0E
%define COLOR_SUCCESS            0x0A
%define COLOR_INFO               0x0B
%define COLOR_FILE               0x0F
%define COLOR_VALUE              0x0E
%define COLOR_ERROR              0x0C
%define COLOR_SUBTLE             0x08
%macro INSTALL_ISR 2
    mov eax, %2
    mov ebx, %1
    call set_idt_gate
%endmacro
start:
    cli
    mov esp, KERNEL_STACK_TOP
    mov byte [text_color], COLOR_BODY
    call init_idt
    call serial_init
    call init_irq
    call init_paging
    call init_memory
    call set_body_color
    call clear_screen
    call show_banner
shell_loop:
    call print_prompt
    call read_line
    call dispatch_command
    jmp shell_loop
show_banner:
    mov byte [text_color], COLOR_PANEL
    mov esi, banner_top
    call console_write
    mov esi, banner_title
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, banner_meta
    call console_write
    mov byte [text_color], COLOR_SECTION
    mov esi, banner_hint
    call console_write
    mov byte [text_color], COLOR_PANEL
    mov esi, banner_bottom
    call console_write
    mov byte [text_color], COLOR_SUCCESS
    mov esi, boot_ok_message
    call console_write
    mov byte [text_color], COLOR_SUBTLE
    mov esi, shell_ready_hint
    call console_write
    call set_body_color
    ret
print_prompt:
    mov byte [text_color], COLOR_PROMPT
    mov esi, prompt
    call console_write
    call set_body_color
    ret
set_body_color:
    mov byte [text_color], COLOR_BODY
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
    mov edi, cmd_games
    call command_equals
    test eax, eax
    jnz .games
    mov esi, line_buffer
    mov edi, cmd_guess
    call command_equals
    test eax, eax
    jnz .guess
    mov esi, line_buffer
    mov edi, cmd_slots
    call command_equals
    test eax, eax
    jnz .slots
    mov esi, line_buffer
    mov edi, cmd_paint
    call command_equals
    test eax, eax
    jnz .paint
    mov esi, line_buffer
    mov edi, cmd_editor
    call command_equals
    test eax, eax
    jnz .editor
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
    mov edi, cmd_search
    call command_equals
    test eax, eax
    jnz .search_usage
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
    mov edi, cmd_search_prefix
    call starts_with
    test eax, eax
    jnz .search
    mov esi, line_buffer
    mov edi, cmd_free_prefix
    call starts_with
    test eax, eax
    jnz .free
    mov byte [text_color], COLOR_ERROR
    mov esi, unknown_prefix
    call console_write
    mov byte [text_color], COLOR_SECTION
    mov esi, line_buffer
    call console_write
    mov al, 10
    call console_putc
    jmp .done
.help:
    call print_help_screen
    jmp .done
.about:
    call print_about_screen
    jmp .done
.clear:
    call set_body_color
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
.games:
    call print_games_screen
    jmp .done
.guess:
    call run_guess_game
    jmp .done
.slots:
    call run_slots_game
    jmp .done
.paint:
    call run_paint_app
    jmp .done
.editor:
    call run_editor_app
    jmp .done
.memtest:
    call run_memory_stress_test
    jmp .done
.echo_empty:
    mov al, 10
    call console_putc
    jmp .done
.cat_usage:
    mov byte [text_color], COLOR_SECTION
    mov esi, cat_usage_text
    call console_write
    jmp .done
.echo_with_text:
    mov byte [text_color], COLOR_INFO
    mov esi, line_buffer + 5
    call console_write
    mov al, 10
    call console_putc
    jmp .done
.cat:
    mov esi, line_buffer + 4
    call print_cached_file_contents
    jmp .done
.search_usage:
    mov byte [text_color], COLOR_SECTION
    mov esi, search_usage_text
    call console_write
    jmp .done
.search:
    mov esi, line_buffer + 7
    call run_search
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
    mov byte [text_color], COLOR_SUCCESS
    mov esi, alloc_ok_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    call print_uint32
    mov byte [text_color], COLOR_SUCCESS
    mov esi, alloc_ok_mid
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [last_alloc_size]
    call print_uint32
    mov byte [text_color], COLOR_SUCCESS
    mov esi, bytes_suffix
    call console_write
    jmp .done
.alloc_usage:
    mov byte [text_color], COLOR_SECTION
    mov esi, alloc_usage_text
    call console_write
    jmp .done
.alloc_failed:
    mov byte [text_color], COLOR_ERROR
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
    mov byte [text_color], COLOR_SUCCESS
    mov esi, free_ok_text
    call console_write
    jmp .done
.free_usage:
    mov byte [text_color], COLOR_SECTION
    mov esi, free_usage_text
    call console_write
    jmp .done
.free_failed:
    mov byte [text_color], COLOR_ERROR
    mov esi, free_failed_text
    call console_write
    jmp .done
.halt:
    mov byte [text_color], COLOR_SECTION
    mov esi, halt_message
    call console_write
.halt_loop:
    cli
    hlt
    jmp .halt_loop
.reboot:
    mov byte [text_color], COLOR_INFO
    mov esi, reboot_message
    call console_write
    call reboot_system
    jmp .done
.done:
    call set_body_color
    ret
print_help_screen:
    mov byte [text_color], COLOR_PANEL
    mov esi, help_top
    call console_write
    mov esi, help_title
    call console_write
    mov esi, help_bottom
    call console_write
    mov byte [text_color], COLOR_SUCCESS
    mov esi, help_core_line
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, help_inspect_line
    call console_write
    mov byte [text_color], COLOR_SECTION
    mov esi, help_files_line
    call console_write
    mov byte [text_color], COLOR_SUCCESS
    mov esi, help_memory_line
    call console_write
    mov byte [text_color], COLOR_SUBTLE
    mov esi, help_hint_line
    call console_write
    call set_body_color
    ret
print_about_screen:
    mov byte [text_color], COLOR_PANEL
    mov esi, about_top
    call console_write
    mov esi, about_title
    call console_write
    mov esi, about_bottom
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, about_boot_line
    call console_write
    mov esi, about_input_line
    call console_write
    mov esi, about_video_line
    call console_write
    mov byte [text_color], COLOR_SUCCESS
    mov esi, about_memory_line
    call console_write
    mov byte [text_color], COLOR_SECTION
    mov esi, about_files_line
    call console_write
    call set_body_color
    ret
print_games_screen:
    mov byte [text_color], COLOR_PANEL
    mov esi, games_top
    call console_write
    mov esi, games_title
    call console_write
    mov esi, games_bottom
    call console_write
    mov byte [text_color], COLOR_SUCCESS
    mov esi, games_guess_line
    call console_write
    mov esi, games_slots_line
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, games_search_line
    call console_write
    mov byte [text_color], COLOR_SUBTLE
    mov esi, games_hint_line
    call console_write
    call set_body_color
    ret
run_guess_game:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov byte [text_color], COLOR_PANEL
    mov esi, guess_top
    call console_write
    mov esi, guess_title
    call console_write
    mov esi, guess_bottom
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, guess_intro_line
    call console_write
    mov ebx, 9
    call random_mod
    inc eax
    mov [guess_secret], eax
    mov dword [guess_attempts], 3
.loop:
    mov byte [text_color], COLOR_SECTION
    mov esi, guess_attempt_prefix
    call console_write
    mov eax, 4
    sub eax, [guess_attempts]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, guess_attempt_suffix
    call console_write
    mov byte [text_color], COLOR_PROMPT
    mov esi, guess_prompt
    call console_write
    call set_body_color
    call read_line
    mov esi, line_buffer
    call parse_uint32
    test edx, edx
    jz .invalid
    cmp eax, 0
    je .cancel
    cmp eax, 9
    ja .range
    cmp eax, [guess_secret]
    je .win
    cmp eax, [guess_secret]
    jb .higher
    mov byte [text_color], COLOR_SECTION
    mov esi, guess_lower_text
    call console_write
    dec dword [guess_attempts]
    jnz .loop
    jmp .lose
.higher:
    mov byte [text_color], COLOR_SECTION
    mov esi, guess_higher_text
    call console_write
    dec dword [guess_attempts]
    jnz .loop
    jmp .lose
.invalid:
    mov byte [text_color], COLOR_ERROR
    mov esi, guess_invalid_text
    call console_write
    jmp .loop
.range:
    mov byte [text_color], COLOR_ERROR
    mov esi, guess_range_text
    call console_write
    jmp .loop
.win:
    mov byte [text_color], COLOR_SUCCESS
    mov esi, guess_win_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [guess_secret]
    call print_uint32
    mov byte [text_color], COLOR_SUCCESS
    mov esi, guess_win_suffix
    call console_write
    jmp .out
.lose:
    mov byte [text_color], COLOR_ERROR
    mov esi, guess_lose_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [guess_secret]
    call print_uint32
    mov byte [text_color], COLOR_ERROR
    mov esi, guess_lose_suffix
    call console_write
    jmp .out
.cancel:
    mov byte [text_color], COLOR_SUBTLE
    mov esi, guess_cancel_text
    call console_write
.out:
    call set_body_color
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
run_slots_game:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    mov byte [text_color], COLOR_PANEL
    mov esi, slots_top
    call console_write
    mov esi, slots_title
    call console_write
    mov esi, slots_bottom
    call console_write
    mov ebx, 6
    call random_mod
    mov [slots_reel_a], eax
    mov ebx, 6
    call random_mod
    mov [slots_reel_b], eax
    mov ebx, 6
    call random_mod
    mov [slots_reel_c], eax
    mov byte [text_color], COLOR_INFO
    mov esi, slots_result_prefix
    call console_write
    mov byte [text_color], COLOR_FILE
    mov esi, slots_left_bracket
    call console_write
    mov eax, [slots_reel_a]
    call print_slot_symbol
    mov esi, slots_mid_bracket
    call console_write
    mov eax, [slots_reel_b]
    call print_slot_symbol
    mov esi, slots_mid_bracket
    call console_write
    mov eax, [slots_reel_c]
    call print_slot_symbol
    mov esi, slots_right_bracket
    call console_write
    mov eax, [slots_reel_a]
    cmp eax, [slots_reel_b]
    jne .check_pairs
    cmp eax, [slots_reel_c]
    je .jackpot
.check_pairs:
    mov eax, [slots_reel_a]
    cmp eax, [slots_reel_b]
    je .pair
    cmp eax, [slots_reel_c]
    je .pair
    mov eax, [slots_reel_b]
    cmp eax, [slots_reel_c]
    je .pair
    mov eax, [slots_reel_a]
    cmp eax, 2
    je .lucky
    mov eax, [slots_reel_b]
    cmp eax, 2
    je .lucky
    mov eax, [slots_reel_c]
    cmp eax, 2
    je .lucky
    mov byte [text_color], COLOR_SUBTLE
    mov esi, slots_miss_text
    call console_write
    jmp .out
.jackpot:
    mov byte [text_color], COLOR_SUCCESS
    mov esi, slots_jackpot_text
    call console_write
    jmp .out
.pair:
    mov byte [text_color], COLOR_SECTION
    mov esi, slots_pair_text
    call console_write
    jmp .out
.lucky:
    mov byte [text_color], COLOR_INFO
    mov esi, slots_lucky_text
    call console_write
.out:
    call set_body_color
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
run_paint_app:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov byte [text_color], COLOR_PANEL
    mov esi, paint_top
    call console_write
    mov esi, paint_title
    call console_write
    mov esi, paint_bottom
    call console_write
    call paint_clear_buffer
    call paint_show_buffer
.paint_loop:
    mov byte [text_color], COLOR_PROMPT
    mov esi, paint_prompt
    call console_write
    call set_body_color
    call read_line
    mov esi, line_buffer
    mov edi, cmd_paint_exit
    call command_equals
    test eax, eax
    jnz .paint_done
    mov esi, line_buffer
    mov edi, cmd_paint_show
    call command_equals
    test eax, eax
    jnz .paint_show
    mov esi, line_buffer
    mov edi, cmd_paint_clear
    call command_equals
    test eax, eax
    jnz .paint_clear
    mov esi, line_buffer
    mov edi, cmd_paint_draw_prefix
    call starts_with
    test eax, eax
    jnz .paint_draw
    mov byte [text_color], COLOR_ERROR
    mov esi, paint_usage_text
    call console_write
    jmp .paint_loop
.paint_draw:
    mov esi, line_buffer + 5
    call parse_uint32
    test edx, edx
    jz .paint_invalid
    mov ebx, eax
    mov esi, line_buffer + 5
    ; skip first number and whitespace
.paint_skip_x:
    mov al, [esi]
    cmp al, ' '
    je .paint_skip_space1
    cmp al, 0
    je .paint_invalid
    inc esi
    jmp .paint_skip_x
.paint_skip_space1:
    inc esi
    mov al, [esi]
    cmp al, ' '
    je .paint_skip_space1
    call parse_uint32
    test edx, edx
    jz .paint_invalid
    mov ecx, eax
    cmp ebx, 39
    ja .paint_invalid
    cmp ecx, 15
    ja .paint_invalid
    mov edx, ecx
    imul edx, 40
    add edx, ebx
    mov al, '*'
    mov [paint_buffer + edx], al
    mov byte [text_color], COLOR_SUCCESS
    mov esi, paint_drawn_text
    call console_write
    jmp .paint_loop
.paint_invalid:
    mov byte [text_color], COLOR_ERROR
    mov esi, paint_invalid_text
    call console_write
    jmp .paint_loop
.paint_show:
    call paint_show_buffer
    jmp .paint_loop
.paint_clear:
    call paint_clear_buffer
    mov byte [text_color], COLOR_SUCCESS
    mov esi, paint_cleared_text
    call console_write
    jmp .paint_loop
.paint_done:
    mov byte [text_color], COLOR_SUBTLE
    mov esi, paint_exit_text
    call console_write
    call set_body_color
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
paint_clear_buffer:
    push eax
    push ecx
    push edi
    mov edi, paint_buffer
    mov al, ' '
    mov ecx, 640
    rep stosb
    pop edi
    pop ecx
    pop eax
    ret
paint_show_buffer:
    push eax
    push ecx
    push edx
    push esi
    mov esi, paint_buffer
    mov ecx, 16
.paint_row:
    mov edx, 40
.paint_col:
    mov al, [esi]
    call console_putc
    inc esi
    dec edx
    jnz .paint_col
    mov al, 10
    call console_putc
    dec ecx
    jnz .paint_row
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
run_editor_app:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov byte [text_color], COLOR_PANEL
    mov esi, editor_top
    call console_write
    mov esi, editor_title
    call console_write
    mov esi, editor_bottom
    call console_write
    mov dword [editor_length], 0
.editor_loop:
    mov byte [text_color], COLOR_PROMPT
    mov esi, editor_prompt
    call console_write
    call set_body_color
    call read_line
    mov esi, line_buffer
    mov edi, cmd_editor_exit
    call command_equals
    test eax, eax
    jnz .editor_done
    mov esi, line_buffer
    mov edi, cmd_editor_show
    call command_equals
    test eax, eax
    jnz .editor_show
    mov esi, line_buffer
    mov edi, cmd_editor_clear
    call command_equals
    test eax, eax
    jnz .editor_clear
    mov esi, line_buffer
    call string_length
    mov ebx, eax
    mov eax, [editor_length]
    add eax, ebx
    cmp eax, 2047
    ja .editor_full
    mov edx, [editor_length]
    lea edi, [editor_buffer + edx]
    mov ecx, ebx
    mov esi, line_buffer
    call safe_memcpy
    add dword [editor_length], ebx
    mov eax, [editor_length]
    lea edi, [editor_buffer + eax]
    mov byte [edi], 10
    inc dword [editor_length]
    mov byte [text_color], COLOR_SUCCESS
    mov esi, editor_append_text
    call console_write
    jmp .editor_loop
.editor_full:
    mov byte [text_color], COLOR_ERROR
    mov esi, editor_full_text
    call console_write
    jmp .editor_loop
.editor_show:
    mov eax, [editor_length]
    test eax, eax
    jz .editor_empty
    mov esi, editor_buffer
    mov ecx, eax
    call console_write_bytes
    mov al, 10
    call console_putc
    jmp .editor_loop
.editor_empty:
    mov byte [text_color], COLOR_SUBTLE
    mov esi, editor_empty_text
    call console_write
    jmp .editor_loop
.editor_clear:
    mov dword [editor_length], 0
    mov byte [text_color], COLOR_SUCCESS
    mov esi, editor_cleared_text
    call console_write
    jmp .editor_loop
.editor_done:
    mov byte [text_color], COLOR_SUBTLE
    mov esi, editor_exit_text
    call console_write
    call set_body_color
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
string_length:
    push ecx
    push esi
    xor ecx, ecx
.strlen_loop:
    mov al, [esi]
    cmp al, 0
    je .strlen_done
    inc ecx
    inc esi
    jmp .strlen_loop
.strlen_done:
    mov eax, ecx
    pop esi
    pop ecx
    ret
run_search:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
.skip_space:
    cmp byte [esi], ' '
    je .advance
    cmp byte [esi], 9
    jne .start
.advance:
    inc esi
    jmp .skip_space
.start:
    cmp byte [esi], 0
    je .usage
    mov [search_query_ptr], esi
    mov dword [search_total_hits], 0
    mov byte [text_color], COLOR_PANEL
    mov esi, search_top
    call console_write
    mov esi, search_title_prefix
    call console_write
    mov byte [text_color], COLOR_SECTION
    mov esi, [search_query_ptr]
    call console_write
    mov byte [text_color], COLOR_PANEL
    mov esi, search_title_suffix
    call console_write
    mov byte [text_color], COLOR_SECTION
    mov esi, search_commands_header
    call console_write
    mov ebx, search_command_table
    xor edx, edx
.command_loop:
    mov edi, [ebx]
    test edi, edi
    jz .command_done
    mov esi, edi
    mov edi, [search_query_ptr]
    call string_contains_ci
    test eax, eax
    jz .command_next
    inc edx
    inc dword [search_total_hits]
    mov byte [text_color], COLOR_FILE
    mov esi, list_bullet
    call console_write
    mov esi, [ebx]
    call console_write
    mov al, 10
    call console_putc
.command_next:
    add ebx, 4
    jmp .command_loop
.command_done:
    test edx, edx
    jnz .files_section
    mov byte [text_color], COLOR_SUBTLE
    mov esi, search_none_text
    call console_write
.files_section:
    mov byte [text_color], COLOR_SECTION
    mov esi, search_files_header
    call console_write
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .files_missing
    mov ecx, [BOOT_INFO_ADDR + BOOTINFO_FILE_COUNT]
    test ecx, ecx
    jz .files_none
    mov ebx, [BOOT_INFO_ADDR + BOOTINFO_FILE_TABLE_ADDR]
    xor edx, edx
.file_loop:
    push ecx
    push ebx
    mov esi, ebx
    mov edi, [search_query_ptr]
    call string_contains_ci
    test eax, eax
    jz .file_next
    inc edx
    inc dword [search_total_hits]
    mov byte [text_color], COLOR_FILE
    mov esi, list_bullet
    call console_write
    mov esi, ebx
    call console_write
    mov byte [text_color], COLOR_SUBTLE
    mov esi, search_size_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [ebx + 20]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, bytes_suffix
    call console_write
.file_next:
    pop ebx
    pop ecx
    add ebx, FILE_CACHE_ENTRY_SIZE
    dec ecx
    jnz .file_loop
    test edx, edx
    jnz .text_section
.files_none:
    mov byte [text_color], COLOR_SUBTLE
    mov esi, search_none_text
    call console_write
    jmp .text_section
.files_missing:
    mov byte [text_color], COLOR_ERROR
    mov esi, files_missing
    call console_write
.text_section:
    mov byte [text_color], COLOR_SECTION
    mov esi, search_text_header
    call console_write
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .text_missing
    mov ecx, [BOOT_INFO_ADDR + BOOTINFO_FILE_COUNT]
    test ecx, ecx
    jz .text_none
    mov ebx, [BOOT_INFO_ADDR + BOOTINFO_FILE_TABLE_ADDR]
    xor edx, edx
.text_loop:
    push ecx
    push ebx
    mov esi, [search_query_ptr]
    mov edi, [ebx + 16]
    mov ecx, [ebx + 20]
    call memory_contains_ci
    test eax, eax
    jz .text_next
    inc edx
    inc dword [search_total_hits]
    mov byte [text_color], COLOR_FILE
    mov esi, list_bullet
    call console_write
    mov esi, ebx
    call console_write
    mov byte [text_color], COLOR_SUBTLE
    mov esi, search_text_hit_suffix
    call console_write
.text_next:
    pop ebx
    pop ecx
    add ebx, FILE_CACHE_ENTRY_SIZE
    dec ecx
    jnz .text_loop
    test edx, edx
    jnz .summary
.text_none:
    mov byte [text_color], COLOR_SUBTLE
    mov esi, search_none_text
    call console_write
    jmp .summary
.text_missing:
    mov byte [text_color], COLOR_ERROR
    mov esi, files_missing
    call console_write
.summary:
    mov byte [text_color], COLOR_INFO
    mov esi, search_total_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [search_total_hits]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, search_total_suffix
    call console_write
    jmp .out
.usage:
    mov byte [text_color], COLOR_SECTION
    mov esi, search_usage_text
    call console_write
.out:
    call set_body_color
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
print_memory_report:
    mov byte [text_color], COLOR_SECTION
    mov esi, mem_header
    call console_write
    call set_body_color
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .missing
    mov byte [text_color], COLOR_INFO
    mov esi, mem_conv_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    movzx eax, word [BOOT_INFO_ADDR + BOOTINFO_CONV_KB]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, kb_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, mem_ext_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    movzx eax, word [BOOT_INFO_ADDR + BOOTINFO_EXT_KB]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, kb_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, mem_total_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [BOOT_INFO_ADDR + BOOTINFO_TOTAL_KB]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, kb_suffix
    call console_write
    call set_body_color
    call print_heap_report
    ret
.missing:
    mov byte [text_color], COLOR_ERROR
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
    mov byte [text_color], COLOR_SECTION
    mov esi, ls_header
    call console_write
    call set_body_color
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
    mov byte [text_color], COLOR_FILE
    mov esi, ebx
    call print_fat_name
    mov byte [text_color], COLOR_SUBTLE
    mov esi, ls_spacing
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [ebx + 28]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, bytes_suffix
    call console_write
    call set_body_color
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
    mov byte [text_color], COLOR_SUBTLE
    mov esi, ls_empty
    call console_write
    ret
.missing:
    mov byte [text_color], COLOR_ERROR
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
    mov byte [text_color], COLOR_SECTION
    mov esi, files_header
    call console_write
    call set_body_color
.next:
    push ecx
    push ebx
    mov byte [text_color], COLOR_FILE
    mov esi, ebx
    call console_write
    mov byte [text_color], COLOR_SUBTLE
    mov esi, ls_spacing
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [ebx + 20]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, bytes_suffix
    call console_write
    call set_body_color
    pop ebx
    pop ecx
    add ebx, FILE_CACHE_ENTRY_SIZE
    dec ecx
    jnz .next
    ret
.empty:
    mov byte [text_color], COLOR_SUBTLE
    mov esi, files_empty
    call console_write
    ret
.missing:
    mov byte [text_color], COLOR_ERROR
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
    mov byte [text_color], COLOR_PANEL
    mov esi, cat_header_prefix
    call console_write
    mov byte [text_color], COLOR_SECTION
    mov esi, edi
    call console_write
    mov byte [text_color], COLOR_PANEL
    mov esi, cat_header_suffix
    call console_write
    mov byte [text_color], COLOR_BODY
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
    mov byte [text_color], COLOR_ERROR
    mov esi, cat_missing_prefix
    call console_write
    mov byte [text_color], COLOR_SECTION
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
    mov byte [text_color], COLOR_SECTION
    mov esi, ticks_header
    call console_write
    call set_body_color
    mov byte [text_color], COLOR_INFO
    mov esi, ticks_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [timer_ticks]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, ticks_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, uptime_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [timer_ticks]
    xor edx, edx
    mov ebx, TIMER_HZ
    div ebx
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, seconds_suffix
    call console_write
    ret
print_vmem_report:
    push eax
    push ebx
    push ecx
    push edx
    mov byte [text_color], COLOR_SECTION
    mov esi, vmem_header
    call console_write
    call set_body_color
    mov byte [text_color], COLOR_INFO
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
    mov byte [text_color], COLOR_VALUE
    mov eax, ebx
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, vmem_total_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, vmem_writable_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, edx
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, vmem_total_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, frames_reserved_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [frame_reserved_count]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, newline_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, frames_runtime_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [frame_dynamic_count]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, newline_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, frames_free_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, FRAME_COUNT
    sub eax, [frame_reserved_count]
    sub eax, [frame_dynamic_count]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, newline_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
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
    mov byte [text_color], COLOR_SUCCESS
    mov esi, page_rw_text
    call console_write
    call set_body_color
    ret
.readonly:
    mov byte [text_color], COLOR_SECTION
    mov esi, page_ro_text
    call console_write
    call set_body_color
    ret
.unmapped:
    mov byte [text_color], COLOR_ERROR
    mov esi, page_unmapped_text
    call console_write
    call set_body_color
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
    mov byte [text_color], COLOR_SECTION
    mov esi, heap_header
    call console_write
    call set_body_color
    mov byte [text_color], COLOR_INFO
    mov esi, heap_start_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, HEAP_START
    call print_uint32
    mov byte [text_color], COLOR_INFO
    mov esi, heap_end_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [heap_end]
    call print_uint32
    mov byte [text_color], COLOR_INFO
    mov esi, heap_used_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [heap_used_bytes]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, bytes_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, heap_free_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [heap_end]
    sub eax, HEAP_START
    sub eax, [heap_used_bytes]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, bytes_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, heap_hw_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [heap_high_water]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, bytes_suffix
    call console_write
    mov byte [text_color], COLOR_INFO
    mov esi, heap_ops_prefix
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [heap_alloc_count]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
    mov esi, slash_sep
    call console_write
    mov byte [text_color], COLOR_VALUE
    mov eax, [heap_free_count]
    call print_uint32
    mov byte [text_color], COLOR_SUBTLE
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
    mov byte [text_color], COLOR_INFO
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
    mov byte [text_color], COLOR_SUCCESS
    mov esi, memtest_ok_text
    call console_write
    jmp .out
.fail:
    mov byte [text_color], COLOR_ERROR
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
string_contains_ci:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    cmp byte [edi], 0
    je .no_match
.outer:
    mov al, [esi]
    test al, al
    jz .no_match
    mov ebx, esi
    mov edx, edi
.inner:
    mov al, [edx]
    test al, al
    jz .match
    mov cl, [ebx]
    test cl, cl
    jz .advance
    cmp al, 'a'
    jb .needle_folded
    cmp al, 'z'
    ja .needle_folded
    sub al, 32
.needle_folded:
    cmp cl, 'a'
    jb .hay_folded
    cmp cl, 'z'
    ja .hay_folded
    sub cl, 32
.hay_folded:
    cmp al, cl
    jne .advance
    inc ebx
    inc edx
    jmp .inner
.advance:
    inc esi
    jmp .outer
.match:
    mov eax, 1
    jmp .done
.no_match:
    xor eax, eax
.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
compare_memory_ci:
    push ebx
.loop:
    mov al, [esi]
    test al, al
    jz .match
    test ecx, ecx
    jz .no_match
    mov bl, [edi]
    cmp al, 'a'
    jb .needle_folded
    cmp al, 'z'
    ja .needle_folded
    sub al, 32
.needle_folded:
    cmp bl, 'a'
    jb .data_folded
    cmp bl, 'z'
    ja .data_folded
    sub bl, 32
.data_folded:
    cmp al, bl
    jne .no_match
    inc esi
    inc edi
    dec ecx
    jmp .loop
.match:
    mov eax, 1
    jmp .done
.no_match:
    xor eax, eax
.done:
    pop ebx
    ret
memory_contains_ci:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    cmp byte [esi], 0
    je .no_match
.outer:
    test ecx, ecx
    jz .no_match
    push ecx
    push esi
    push edi
    call compare_memory_ci
    pop edi
    pop esi
    pop ecx
    test eax, eax
    jnz .done
    inc edi
    dec ecx
    jmp .outer
.no_match:
    xor eax, eax
.done:
    pop edi
    pop esi
    pop edx
    pop ecx
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
random_next:
    push edx
    mov eax, [rng_state]
    test eax, eax
    jnz .seeded
    mov eax, [timer_ticks]
    xor eax, 0xA341316C
    add eax, [heap_alloc_count]
.seeded:
    imul eax, eax, 1664525
    add eax, 1013904223
    xor eax, [timer_ticks]
    rol eax, 7
    mov [rng_state], eax
    pop edx
    ret
random_mod:
    push edx
    test ebx, ebx
    jz .zero
    call random_next
    xor edx, edx
    div ebx
    mov eax, edx
    pop edx
    ret
.zero:
    xor eax, eax
    pop edx
    ret
print_slot_symbol:
    push eax
    mov esi, [slots_symbol_table + eax * 4]
    call console_write
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
banner_title:      db 'Lum-OS kernel online (32-bit protected mode)', 10, 0
banner_mid:        db ' Protected mode shell with VGA, serial, IRQ keyboard, paging, heap.', 10, 0
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
help_text:         db 'Commands: help, about, clear, mem, ls, files, heap, ticks, uptime, vmem, alloc <bytes>, free <addr>, memtest, echo <text>, cat <file>, games, search <text>, paint, editor, reboot, halt', 10, 0
help_top:          db '=================== HELP ===================', 10, 0
help_title:        db 'Available shell commands and categories', 10, 0
help_bottom:       db '============================================', 10, 0
help_core_line:    db ' core: help, about, clear, mem, ls, files, heap, ticks, uptime, vmem', 10, 0
help_inspect_line: db ' inspect: alloc <bytes>, free <addr>, cat <file>, search <text>', 10, 0
help_files_line:   db ' files: ls, files, cat <file>', 10, 0
help_memory_line:  db ' memory: mem, alloc, free, memtest', 10, 0
help_hint_line:    db 'Hint: type games for puzzles, paint for drawing, editor for text.', 10, 0
about_top:         db '=================== ABOUT ===================', 10, 0
about_title:       db 'Lum-OS capabilities', 10, 0
about_bottom:      db '============================================', 10, 0
about_boot_line:   db ' boot: FAT12 -> stage2 -> protected mode', 10, 0
about_input_line:  db ' input: IRQ keyboard + serial console', 10, 0
about_video_line:  db ' video: VGA text + serial output', 10, 0
about_memory_line: db ' memory: paging, heap, guard pages', 10, 0
about_files_line:  db ' files: floppy cache access, low-level shell I/O', 10, 0
games_top:         db '=================== GAMES ===================', 10, 0
games_title:       db 'Shell mini-games', 10, 0
games_bottom:      db '============================================', 10, 0
games_guess_line:  db ' guess      : play the number guess game', 10, 0
games_slots_line:  db ' slots      : spin three random symbols', 10, 0
games_search_line: db ' search <q> : search command names by substring', 10, 0
games_hint_line:   db 'Try paint or editor for simple apps too.', 10, 0

guess_top:         db '=================== GUESS ===================', 10, 0
guess_title:       db 'Guess the number from 1 to 9', 10, 0
guess_bottom:      db '============================================', 10, 0
guess_intro_line:  db 'You have 3 tries. Enter 0 to cancel.', 10, 0
guess_secret:      dd 0
guess_attempts:    dd 0
guess_attempt_prefix: db 'Tries left: ', 0
guess_attempt_suffix: db 10, 0
guess_prompt:      db 'guess> ', 0
guess_lower_text:  db 'Too low.', 10, 0
guess_higher_text: db 'Too high.', 10, 0
guess_invalid_text: db 'Invalid input. Enter a number 1-9.', 10, 0
guess_range_text:  db 'Out of range. Use 1-9 or 0 to cancel.', 10, 0
guess_win_prefix:  db 'Correct! Secret number was ', 0
guess_win_suffix:  db '.', 10, 0
guess_lose_prefix: db 'You lost. The number was ', 0
guess_lose_suffix: db '.', 10, 0
guess_cancel_text: db 'Guess cancelled.', 10, 0

slots_top:         db '=================== SLOTS ===================', 10, 0
slots_title:       db 'Spin the reels and match symbols', 10, 0
slots_bottom:      db '============================================', 10, 0
slots_result_prefix: db 'Result: ', 0
slots_left_bracket: db '[', 0
slots_mid_bracket:  db ' ', 0
slots_right_bracket: db ']', 10, 0
slots_miss_text:   db 'No match. Better luck next time.', 10, 0
slots_jackpot_text: db 'Jackpot! All three symbols match!', 10, 0
slots_pair_text:   db 'Nice! A pair matched.', 10, 0
slots_lucky_text:  db 'Lucky hit! One reel landed a special symbol.', 10, 0
slots_reel_a:      dd 0
slots_reel_b:      dd 0
slots_reel_c:      dd 0

paint_top:         db '=================== PAINT ===================', 10, 0
paint_title:       db 'Simple text canvas: draw x y', 10, 0
paint_bottom:      db '============================================', 10, 0
paint_prompt:      db 'paint> ', 0
paint_usage_text:  db 'Commands: draw x y, .show, .clear, .exit', 10, 0
paint_invalid_text: db 'Invalid coordinates. Use x 0-39 y 0-15.', 10, 0
paint_drawn_text:  db 'Point drawn.', 10, 0
paint_cleared_text: db 'Canvas cleared.', 10, 0
paint_exit_text:   db 'Exiting paint.', 10, 0
paint_buffer:      times 640 db ' '

editor_top:        db '=================== EDITOR ==================', 10, 0
editor_title:      db 'Line editor: add lines, .show, .clear, .exit', 10, 0
editor_bottom:     db '============================================', 10, 0
editor_prompt:     db 'edit> ', 0
editor_append_text: db 'Line appended.', 10, 0
editor_full_text:  db 'Editor full. Maximum 2047 chars.', 10, 0
editor_empty_text: db 'No text saved yet.', 10, 0
editor_cleared_text: db 'Editor cleared.', 10, 0
editor_exit_text:  db 'Exiting editor.', 10, 0
editor_buffer:     times 2048 db 0
editor_length:     dd 0
banner_meta:       db 'Protected mode kernel, VGA + serial console, IRQ keyboard, paging, heap.', 10, 0
banner_hint:       db 'Use help to list commands. QEMU keyboard and serial input are active.', 10, 10, 0
shell_ready_hint:  db 'Shell ready. Type help for commands.', 10, 0

search_top:              db '=================== SEARCH ==================', 10, 0
search_title_prefix:     db 'Search query: ', 0
search_title_suffix:     db 10, 0
search_commands_header:  db 'Matching commands:', 10, 0
search_files_header:     db 'Matching cached files:', 10, 0
search_text_header:      db 'Matching text lines:', 10, 0
search_none_text:        db 'No matches found.', 10, 0
search_size_prefix:      db ' Size: ', 0
search_text_hit_suffix:  db ' <-- match', 10, 0
search_total_prefix:     db 'Total hits: ', 0
search_total_suffix:     db 10, 0
search_usage_text:       db 'Usage: search <query>', 10, 0
list_bullet:             db ' - ', 0

mem_header:              db 'Memory report:', 10, 0
heap_header:             db 'Heap allocator report:', 10, 0
ticks_header:            db 'Timer tick report:', 10, 0
vmem_header:             db 'Virtual memory report:', 10, 0

alloc_usage_text:  db 'Usage: alloc <bytes>', 10, 0
alloc_failed_text: db 'Allocation failed: out of heap memory.', 10, 0
alloc_ok_prefix:   db 'Allocated at ', 0
alloc_ok_mid:      db ' size=', 0
cat_usage_text:    db 'Usage: cat <file>', 10, 0
cat_header_prefix: db '--- ', 0
cat_header_suffix: db ' ---', 10, 0
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
cmd_games:         db 'games', 0
cmd_guess:         db 'guess', 0
cmd_slots:         db 'slots', 0
cmd_search:        db 'search', 0
cmd_search_prefix: db 'search ', 0
cmd_paint:         db 'paint', 0
cmd_paint_show:    db '.show', 0
cmd_paint_clear:   db '.clear', 0
cmd_paint_draw_prefix: db 'draw ', 0
cmd_paint_exit:    db '.exit', 0
cmd_editor:        db 'editor', 0
cmd_editor_show:   db '.show', 0
cmd_editor_clear:  db '.clear', 0
cmd_editor_exit:   db '.exit', 0
search_query_ptr:  dd 0
search_total_hits: dd 0
search_command_table:
    dd cmd_help
    dd cmd_about
    dd cmd_clear
    dd cmd_mem
    dd cmd_ls
    dd cmd_files
    dd cmd_heap
    dd cmd_ticks
    dd cmd_uptime
    dd cmd_vmem
    dd cmd_cat
    dd cmd_echo
    dd cmd_alloc_prefix
    dd cmd_free_prefix
    dd cmd_memtest
    dd cmd_reboot
    dd cmd_halt
    dd cmd_games
    dd cmd_guess
    dd cmd_slots
    dd cmd_search
    dd cmd_paint
    dd cmd_editor
rng_state:        dd 0
slots_symbol_table:
    dd slot_symbol_0
    dd slot_symbol_1
    dd slot_symbol_2
    dd slot_symbol_3
    dd slot_symbol_4
    dd slot_symbol_5
kbd_scancode_table:
slot_symbol_0:     db '7', 0
slot_symbol_1:     db '$', 0
slot_symbol_2:     db '%', 0
slot_symbol_3:     db '&', 0
slot_symbol_4:     db '*', 0
slot_symbol_5:     db '+', 0
    db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 0, 0, 10, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 0xA4, 0, 0, 0, 0
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '
    times (128 - ($ - kbd_scancode_table)) db 0
kbd_scancode_shift_table:
    db 0, 27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 8, 9
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 0, 0, 10, 0
    db 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 0xA5, '"', '~', 0, '|'
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
