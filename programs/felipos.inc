bits 16
org 32768

    %define API_VERSION 17

    %define KEY_UP      72
    %define KEY_DOWN    80
    %define KEY_LEFT    75
    %define KEY_RIGHT   77
    %define KEY_ENTER   13
    %define KEY_ESC     27

    %define BLACK_ON_WHITE 0f0h

    kernel_start              equ 0000h
    os_print_string           equ 0003h
    os_move_cursor            equ 0006h
    os_clear_screen           equ 0009h
    os_print_horiz_line       equ 000Ch
    os_print_newline          equ 000Fh
    os_wait_for_key           equ 0012h
    os_check_for_key          equ 0015h
    os_int_to_string          equ 0018h
    os_speaker_tone           equ 001Bh
    os_speaker_off            equ 001Eh
    os_load_file              equ 0021h
    os_pause                  equ 0024h
    os_fatal_error            equ 0027h
    os_draw_background        equ 002Ah
    os_string_length          equ 002Dh
    os_string_uppercase       equ 0030h
    os_string_lowercase       equ 0033h
    os_input_string           equ 0036h
    os_string_copy            equ 0039h
    os_dialog_box             equ 003Ch
    os_string_join            equ 003Fh
    os_get_file_list          equ 0042h
    os_string_compare         equ 0045h
    os_string_chomp           equ 0048h
    os_string_strip           equ 004Bh
    os_string_truncate        equ 004Eh
    os_bcd_to_int             equ 0051h
    os_get_time_string        equ 0054h
    os_get_api_version        equ 0057h
    os_file_selector          equ 005Ah
    os_get_date_string        equ 005Dh
    os_send_via_serial        equ 0060h
    os_get_via_serial         equ 0063h
    os_find_char_in_string    equ 0066h
    os_get_cursor_pos         equ 0069h
    os_print_space            equ 006Ch
    os_dump_string            equ 006Fh
    os_print_digit            equ 0072h
    os_print_1hex             equ 0075h
    os_print_2hex             equ 0078h
    os_print_4hex             equ 007Bh
    os_long_int_to_string     equ 007Eh
    os_long_int_negate        equ 0081h
    os_set_time_fmt           equ 0084h
    os_set_date_fmt           equ 0087h
    os_show_cursor            equ 008Ah
    os_hide_cursor            equ 008Dh
    os_dump_registers         equ 0090h
    os_string_strincmp        equ 0093h
    os_write_file             equ 0096h
    os_file_exists            equ 0099h
    os_create_file            equ 009Ch
    os_remove_file            equ 009Fh
    os_rename_file            equ 00A2h
    os_get_file_size          equ 00A5h
    os_input_dialog           equ 00A8h
    os_list_dialog            equ 00ABh
    os_string_reverse         equ 00AEh
    os_string_to_int          equ 00B1h
    os_draw_block             equ 00B4h
    os_get_random             equ 00B7h
    os_string_charchange      equ 00BAh
    os_serial_port_enable     equ 00BDh
    os_sint_to_string         equ 00C0h
    os_string_parse           equ 00C3h
    os_run_basic              equ 00C6h
    os_port_byte_out          equ 00C9h
    os_port_byte_in           equ 00CCh
    os_string_tokenize        equ 00CFh

    call os_get_api_version
    cmp al, API_VERSION
    je __api_version_ok
    mov ax, __api_version_error
    call os_fatal_error

__api_version_error db 'Invalid API Version!', 0

__api_version_ok: