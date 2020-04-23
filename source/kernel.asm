bits 16

    %define OS_VERSION '0.0.1'
    %define API_VERSION 17

    disk_buffer equ 24576   ; 8k disk buffer located after OS code and before 32k (user space)
    user_space  equ 32768

    jmp kernel_start              ; 0000h
    jmp os_print_string           ; 0003h
    jmp near __NOT_IMPLEMENTED__  ; os_move_cursor            ; 0006h
    jmp os_clear_screen           ; 0009h
    jmp near __NOT_IMPLEMENTED__  ; os_print_horiz_line       ; 000Ch
    jmp os_print_newline          ; 000Fh
    jmp os_wait_for_key           ; 0012h
    jmp os_check_for_key          ; 0015h
    jmp os_int_to_string          ; 0018h
    jmp os_speaker_tone           ; 001Bh
    jmp os_speaker_off            ; 001Eh
    jmp os_load_file              ; 0021h
    jmp os_pause                  ; 0024h
    jmp os_fatal_error            ; 0027h
    jmp near __NOT_IMPLEMENTED__  ; os_draw_background        ; 002Ah
    jmp os_string_length          ; 002Dh
    jmp os_string_uppercase       ; 0030h
    jmp os_string_lowercase       ; 0033h
    jmp os_input_string           ; 0036h
    jmp os_string_copy            ; 0039h
    jmp near __NOT_IMPLEMENTED__  ; os_dialog_box             ; 003Ch
    jmp os_string_join            ; 003Fh
    jmp os_get_file_list          ; 0042h
    jmp os_string_compare         ; 0045h
    jmp os_string_chomp           ; 0048h
    jmp os_string_strip           ; 004Bh
    jmp os_string_truncate        ; 004Eh
    jmp os_bcd_to_int             ; 0051h
    jmp os_get_time_string        ; 0054h
    jmp os_get_api_version        ; 0057h
    jmp near __NOT_IMPLEMENTED__  ; os_file_selector          ; 005Ah
    jmp os_get_date_string        ; 005Dh
    jmp near __NOT_IMPLEMENTED__  ; os_send_via_serial        ; 0060h
    jmp near __NOT_IMPLEMENTED__  ; os_get_via_serial         ; 0063h
    jmp os_find_char_in_string    ; 0066h
    jmp near __NOT_IMPLEMENTED__  ; os_get_cursor_pos         ; 0069h
    jmp os_print_space            ; 006Ch
    jmp near __NOT_IMPLEMENTED__  ; os_dump_string            ; 006Fh
    jmp os_print_digit            ; 0072h
    jmp os_print_1hex             ; 0075h
    jmp os_print_2hex             ; 0078h
    jmp os_print_4hex             ; 007Bh
    jmp os_long_int_to_string     ; 007Eh
    jmp near __NOT_IMPLEMENTED__  ; os_long_int_negate        ; 0081h
    jmp os_set_time_fmt           ; 0084h
    jmp os_set_date_fmt           ; 0087h
    jmp near __NOT_IMPLEMENTED__  ; os_show_cursor            ; 008Ah
    jmp near __NOT_IMPLEMENTED__  ; os_hide_cursor            ; 008Dh
    jmp os_dump_registers         ; 0090h
    jmp os_string_strincmp        ; 0093h
    jmp os_write_file             ; 0096h
    jmp os_file_exists            ; 0099h
    jmp os_create_file            ; 009Ch
    jmp os_remove_file            ; 009Fh
    jmp os_rename_file            ; 00A2h
    jmp os_get_file_size          ; 00A5h
    jmp near __NOT_IMPLEMENTED__  ; os_input_dialog           ; 00A8h
    jmp near __NOT_IMPLEMENTED__  ; os_list_dialog            ; 00ABh
    jmp os_string_reverse         ; 00AEh
    jmp os_string_to_int          ; 00B1h
    jmp near __NOT_IMPLEMENTED__  ; os_draw_block             ; 00B4h
    jmp near __NOT_IMPLEMENTED__  ; os_get_random             ; 00B7h
    jmp os_string_charchange      ; 00BAh
    jmp near __NOT_IMPLEMENTED__  ; os_serial_port_enable     ; 00BDh
    jmp os_sint_to_string         ; 00C0h
    jmp os_string_parse           ; 00C3h
    jmp near __NOT_IMPLEMENTED__  ; os_run_basic              ; 00C6h
    jmp near __NOT_IMPLEMENTED__  ; os_port_byte_out          ; 00C9h
    jmp near __NOT_IMPLEMENTED__  ; os_port_byte_in           ; 00CCh
    jmp os_string_tokenize        ; 00CFh

__NOT_IMPLEMENTED__:
    mov ax, not_implemented_msg
    call os_fatal_error

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

kernel_main:

    ; start CLI
    call os_command_line

    mov si, end_msg
    call os_print_string

    ; halt
    jmp $

    %include 'features/cli.asm'
    %include 'features/screen.asm'
    %include 'features/string.asm'
    %include 'features/math.asm'
    %include 'features/disk.asm'
    %include 'features/keyboard.asm'
    %include 'features/misc.asm'
    %include 'features/sound.asm'

end_msg db 'Exited', 13, 10, 0
not_implemented_msg db 'SYSTEM CALL NOT IMPLEMENTED', 13, 10, 0
