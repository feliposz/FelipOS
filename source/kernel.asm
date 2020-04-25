bits 16

    %define OS_VERSION '0.0.1'
    %define API_VERSION 17

    disk_buffer equ 24576   ; 8k disk buffer located after OS code and before 32k (user space)
    user_space  equ 32768

    jmp kernel_start              ; 0000h
    jmp os_print_string           ; 0003h
    jmp os_move_cursor            ; 0006h
    jmp os_clear_screen           ; 0009h
    jmp os_print_horiz_line       ; 000Ch
    jmp os_print_newline          ; 000Fh
    jmp os_wait_for_key           ; 0012h
    jmp os_check_for_key          ; 0015h
    jmp os_int_to_string          ; 0018h
    jmp os_speaker_tone           ; 001Bh
    jmp os_speaker_off            ; 001Eh
    jmp os_load_file              ; 0021h
    jmp os_pause                  ; 0024h
    jmp os_fatal_error            ; 0027h
    jmp os_draw_background        ; 002Ah
    jmp os_string_length          ; 002Dh
    jmp os_string_uppercase       ; 0030h
    jmp os_string_lowercase       ; 0033h
    jmp os_input_string           ; 0036h
    jmp os_string_copy            ; 0039h
    jmp os_dialog_box             ; 003Ch
    jmp os_string_join            ; 003Fh
    jmp os_get_file_list          ; 0042h
    jmp os_string_compare         ; 0045h
    jmp os_string_chomp           ; 0048h
    jmp os_string_strip           ; 004Bh
    jmp os_string_truncate        ; 004Eh
    jmp os_bcd_to_int             ; 0051h
    jmp os_get_time_string        ; 0054h
    jmp os_get_api_version        ; 0057h
    jmp os_file_selector          ; 005Ah
    jmp os_get_date_string        ; 005Dh
    jmp os_send_via_serial        ; 0060h
    jmp os_get_via_serial         ; 0063h
    jmp os_find_char_in_string    ; 0066h
    jmp os_get_cursor_pos         ; 0069h
    jmp os_print_space            ; 006Ch
    jmp os_dump_string            ; 006Fh
    jmp os_print_digit            ; 0072h
    jmp os_print_1hex             ; 0075h
    jmp os_print_2hex             ; 0078h
    jmp os_print_4hex             ; 007Bh
    jmp os_long_int_to_string     ; 007Eh
    jmp os_long_int_negate        ; 0081h
    jmp os_set_time_fmt           ; 0084h
    jmp os_set_date_fmt           ; 0087h
    jmp os_show_cursor            ; 008Ah
    jmp os_hide_cursor            ; 008Dh
    jmp os_dump_registers         ; 0090h
    jmp os_string_strincmp        ; 0093h
    jmp os_write_file             ; 0096h
    jmp os_file_exists            ; 0099h
    jmp os_create_file            ; 009Ch
    jmp os_remove_file            ; 009Fh
    jmp os_rename_file            ; 00A2h
    jmp os_get_file_size          ; 00A5h
    jmp os_input_dialog           ; 00A8h
    jmp os_list_dialog            ; 00ABh
    jmp os_string_reverse         ; 00AEh
    jmp os_string_to_int          ; 00B1h
    jmp os_draw_block             ; 00B4h
    jmp os_get_random             ; 00B7h
    jmp os_string_charchange      ; 00BAh
    jmp os_serial_port_enable     ; 00BDh
    jmp os_sint_to_string         ; 00C0h
    jmp os_string_parse           ; 00C3h
    jmp near __NOT_IMPLEMENTED__  ; os_run_basic              ; 00C6h
    jmp os_port_byte_out          ; 00C9h
    jmp os_port_byte_in           ; 00CCh
    jmp os_string_tokenize        ; 00CFh

kernel_start:

    ; setup segments and stack pointer
    cli
    mov ax, cs
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0ffffh
    sti

    call disk_init
    call os_seed_random

.option_screen:

    call os_hide_cursor

    mov ax, header_msg
    mov bx, footer_msg
    mov cx, 1Fh
    call os_draw_background

    mov ax, welcome1_msg
    mov bx, welcome2_msg
    mov cx, welcome3_msg
    mov dx, 1
    call os_dialog_box

    or ax, ax
    jz .app_selector

    ; start CLI
    call os_show_cursor
    call os_command_line

    jmp .option_screen

.app_selector:

    call os_hide_cursor

    mov ax, header_msg
    mov bx, footer_msg
    mov cx, 1Fh
    call os_draw_background

    call os_file_selector
    jc .option_screen

    mov dx, ax

    ; has extension?
    mov si, dx
    mov al, '.'
    call os_find_char_in_string
    or ax, ax
    jz .bin_error

    call os_print_2hex

    ; is .BIN?
    mov si, dx
    add si, ax
    dec si
    mov di, bin_ext
    call os_string_compare
    jnc .bin_error

    ; is kernel?
    mov si, dx
    mov di, kernel_name
    call os_string_compare
    jc .kernel_error

    ; load program
    mov ax, dx
    mov si, 0
    mov cx, user_space
    call os_load_file
    jc .bin_error

    ; execute program
    call os_show_cursor
    call os_clear_screen
    call user_space

    ; wait key press
    mov si, pause_msg
    call os_print_string
    call os_wait_for_key

    jmp .app_selector

.bin_error:
    mov ax, bin_msg
    mov bx, 0
    mov cx, 0
    mov dx, 0
    call os_dialog_box
    jmp .app_selector

.kernel_error:
    mov ax, kernel_msg
    mov bx, 0
    mov cx, 0
    mov dx, 0
    call os_dialog_box
    jmp .app_selector

__NOT_IMPLEMENTED__:
    mov ax, not_imp_msg
    call os_fatal_error
.halt:
    hlt
    jmp .halt

    %include 'features/cli.asm'
    %include 'features/screen.asm'
    %include 'features/string.asm'
    %include 'features/math.asm'
    %include 'features/disk.asm'
    %include 'features/keyboard.asm'
    %include 'features/misc.asm'
    %include 'features/sound.asm'
    %include 'features/ports.asm'

header_msg      db 'Welcome to FelipOS', 0
footer_msg      db 'Version ', OS_VERSION, 0
welcome1_msg    db 'Welcome! Thanks for using FelipOS!', 0
welcome2_msg    db 'Please, select OK for program menu or', 0
welcome3_msg    db 'Cancel for command line.', 0
not_imp_msg     db 'SYSTEM CALL NOT IMPLEMENTED', 13, 10, 0
bin_msg         db 'Not a valid BIN program.', 0
pause_msg       db '>>> Program ended. Press any key to continue.', 0