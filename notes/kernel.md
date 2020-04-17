# Kernel

Notes on the kernel and features of MikeOS.

Lines of code on version 4.6.1 (excluding blank lines and comments).

File                  | Lines
----------------------|-------:
kernel.asm            |  248
bootload\bootload.asm |  209
features\sound.asm    |   21
features\keyboard.asm |   27
features\ports.asm    |   48
features\misc.asm     |   59
features\math.asm     |   62
features\string.asm   |  676
features\cli.asm      |  707
features\screen.asm   |  785
features\disk.asm     |  830
features\basic.asm    | 2915
**SUM:**              | **6587**

## KERNEL.ASM

Description of basic kernel.

- Loaded by `bootload.asm`.
- Begins with a jump table of 69 system calls and a jump on the beginning to skip to main kernel code.
- Set stack segment to 0 and pointer to FFFFh.
- Set all segments to the same 2000:xxxx.
- Save boot device and if not zero, get drive parameters with AH=8, int 13h
- Set text attributes to use bright colors instead of blinking
- Seed random.
- If exists autorun.bin, load into ram and execute it.
- If exists autorun.bas, load into ram and call basic interpreter.
- Option screen
    - Draw background
    - Display dialog box
    - Go to App Selector or command line depending on selection
- App selector
    - If filename is KERNEL.BIN, display error dialog
    - Else if extension is BIN, load file into 32k and call 32k as a routine (program must end with RET)
    - Else if extension is BAS, load file into 32k and run kernel basic intepreter
    - Else display error on invalid extension
    - Go back to selector
- Declaration of kernel internal variables
- Include all feature source

## System calls

System call               | Position    | Source file
--------------------------|:-----------:|--------------
os_print_string           | 0003h       | screen.asm
os_move_cursor            | 0006h       | screen.asm
os_clear_screen           | 0009h       | screen.asm
os_print_horiz_line       | 000Ch       | screen.asm
os_print_newline          | 000Fh       | screen.asm
os_wait_for_key           | 0012h       | keyboard.asm
os_check_for_key          | 0015h       | keyboard.asm
os_int_to_string          | 0018h       | string.asm
os_speaker_tone           | 001Bh       | sound.asm
os_speaker_off            | 001Eh       | sound.asm
os_load_file              | 0021h       | disk.asm
os_pause                  | 0024h       | misc.asm
os_fatal_error            | 0027h       | misc.asm
os_draw_background        | 002Ah       | screen.asm
os_string_length          | 002Dh       | string.asm
os_string_uppercase       | 0030h       | string.asm
os_string_lowercase       | 0033h       | string.asm
os_input_string           | 0036h       | screen.asm
os_string_copy            | 0039h       | string.asm
os_dialog_box             | 003Ch       | screen.asm
os_string_join            | 003Fh       | string.asm
os_get_file_list          | 0042h       | disk.asm
os_string_compare         | 0045h       | string.asm
os_string_chomp           | 0048h       | string.asm
os_string_strip           | 004Bh       | string.asm
os_string_truncate        | 004Eh       | string.asm
os_bcd_to_int             | 0051h       | math.asm
os_get_time_string        | 0054h       | string.asm
os_get_api_version        | 0057h       | misc.asm
os_file_selector          | 005Ah       | screen.asm
os_get_date_string        | 005Dh       | string.asm
os_send_via_serial        | 0060h       | ports.asm
os_get_via_serial         | 0063h       | ports.asm
os_find_char_in_string    | 0066h       | string.asm
os_get_cursor_pos         | 0069h       | screen.asm
os_print_space            | 006Ch       | screen.asm
os_dump_string            | 006Fh       | screen.asm
os_print_digit            | 0072h       | screen.asm
os_print_1hex             | 0075h       | screen.asm
os_print_2hex             | 0078h       | screen.asm
os_print_4hex             | 007Bh       | screen.asm
os_long_int_to_string     | 007Eh       | string.asm
os_long_int_negate        | 0081h       | math.asm
os_set_time_fmt           | 0084h       | string.asm
os_set_date_fmt           | 0087h       | string.asm
os_show_cursor            | 008Ah       | screen.asm
os_hide_cursor            | 008Dh       | screen.asm
os_dump_registers         | 0090h       | screen.asm
os_string_strincmp        | 0093h       | string.asm
os_write_file             | 0096h       | disk.asm
os_file_exists            | 0099h       | disk.asm
os_create_file            | 009Ch       | disk.asm
os_remove_file            | 009Fh       | disk.asm
os_rename_file            | 00A2h       | disk.asm
os_get_file_size          | 00A5h       | disk.asm
os_input_dialog           | 00A8h       | screen.asm
os_list_dialog            | 00ABh       | screen.asm
os_string_reverse         | 00AEh       | string.asm
os_string_to_int          | 00B1h       | string.asm
os_draw_block             | 00B4h       | screen.asm
os_get_random             | 00B7h       | math.asm
os_string_charchange      | 00BAh       | string.asm
os_serial_port_enable     | 00BDh       | ports.asm
os_sint_to_string         | 00C0h       | string.asm
os_string_parse           | 00C3h       | string.asm
os_run_basic              | 00C6h       | basic.asm
os_port_byte_out          | 00C9h       | ports.asm
os_port_byte_in           | 00CCh       | ports.asm
os_string_tokenize        | 00CFh       | string.asm


## FEATURES/CLI.ASM

Description of command line interface (shell).

- Clear screen, display version and help
- Command loop:
    - Clear command buffer
    - Display prompt
    - Read input
    - Print newline
    - Remove trailing spaces
    - Empty command? Ignore
    - Split command line
    - Save original command
    - Convert to uppercase
    - Compare to internal commands (EXIT, HELP, CLS, DIR, VER, TIME, DATE, CAT, DEL, COPY, REN, SIZE, LS) and call appropriate sub
    - If external
        - Extension provided?
        - If not, check .BIN or .BAS
        - Load according to extension (.BIN or .BAS)
            - If KERNEL.BIN display warning and ignore
            - Load BIN file, clear registers, pass param_list in SI and execute loaded BIN (call 32k)
            - Load BAS file, call basic interpreter
    - Else, print error and repeat

### Internal commands

All commands jump back to command loop at end.

HELP
- Just print help message (list of commands)

TIME
- Get system time and print

DATE
- Get system date and print

VER
- Print version string

DIR
- Get file list on a comma separated string
- Parse string to list files on columns

CAT
- Check parameter list for file name
- Show error if no file provided
- If file not found print error
- Load file into memory at 32k
- Loop printing each byte in memory according to size
    - If character is LF (0x0A) go to new line

DEL
- Check parameter list for file name
- Show error if no file provided
- If file not found print error
- Call sub to remove file

SIZE
- Check parameter list for file name
- Show error if no file provided
- If file not found print error
- Call sub to get file size and print it

COPY
- Check parameter list for two file names
- Show error if no file provided
- If source file not found print error
- If dest file already exists print error
- Load entire file into memory
- Write entire file to disk from memory

REN
- Check parameter list for old name and new name
- Show error if no file provided
- If old file name not found print error
- If new file name exists print error

LS
- Read root directory
- Loop through entries, paging every 20 entries
    - Skip non-files (., .., non-ASCII names, space, etc.)
    - Print entry:
        - Attributes (A, D, V, S, H, R)
        - Created Date&Time
        - Modified Date&Time
        - Starting cluster
        - File size
        - File name
    - Wait for key, if ESCAPE, exit loop

EXIT
- Return from CLI to option screen

