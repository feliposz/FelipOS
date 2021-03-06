# MikeOS Syscalls

Description of system calls on MikeOS.

Extracted from source files, listed here for easy reference.


# BASIC.ASM

## os_run_basic
> Start the BASIC interpreter to run previously loaded program.


# DISK.ASM

## os_get_file_list
> Generate comma-separated string of files on floppy
> - IN/OUT: AX = location to store zero-terminated filename string

## os_load_file
> Load file into RAM
> - IN: AX = location of filename, CX = location in RAM to load file
> - OUT: BX = file size (in bytes), carry set if file not found

## os_write_file
> Save (max 64K) file to disk
> - IN: AX = filename, BX = data location, CX = bytes to write
> - OUT: Carry clear if OK, set if failure

## os_file_exists
> Check for presence of file on the floppy
> - IN: AX = filename location
> - OUT: carry clear if found, set if not

## os_create_file
> Creates a new 0-byte file on the floppy disk
> - IN: AX = location of filename
> - OUT: Nothing

## os_remove_file
> Deletes the specified file from the filesystem
> - IN: AX = location of filename to remove

## os_rename_file
> Change the name of a file on the disk
> - IN: AX = filename to change, BX = new filename (zero-terminated strings)
> - OUT: carry set on error

## os_get_file_size
> Get file size information for specified file
> - IN: AX = filename
> - OUT: BX = file size in bytes (up to 64K) or carry set if file not found

## INTERNAL OS ROUTINES

Not accessible to user programs

## int_filename_convert
> Change 'TEST.BIN' into 'TEST    BIN' as per FAT12
> - IN: AX = filename string
> - OUT: AX = location of converted string (carry set if invalid)

## disk_get_root_entry
> Search RAM copy of root dir for file entry
> - IN: AX = filename
> - OUT: DI = location in disk_buffer of root dir entry, or carry set if file not found

## disk_read_fat
> Read FAT entry from floppy into disk_buffer
> - IN: Nothing
> - OUT: carry set if failure

## disk_write_fat
> Save FAT contents from disk_buffer in RAM to disk
> - IN: FAT in disk_buffer
> - OUT: carry set if failure

## disk_read_root_dir
> Get the root directory contents
> - IN: Nothing
> - OUT: root directory contents in disk_buffer, carry set if error

## disk_write_root_dir
> Write root directory contents from disk_buffer to disk
> - IN: root dir copy in disk_buffer
> - OUT: carry set if error

## disk_convert_l2hts
> Calculate head, track and sector for int 13h
> - IN: logical sector in AX
> - OUT: correct registers for int 13h


# KEYBOARD.ASM

## os_wait_for_key
> Waits for keypress and returns key
> - IN: Nothing
> - OUT: AX = key pressed, other regs preserved

## os_check_for_key
> Scans keyboard for input, but doesn't wait
> - IN: Nothing
> - OUT: AX = 0 if no key pressed, otherwise scan code


# MATH.ASM

## os_seed_random
> Seed the random number generator based on clock
> - IN: Nothing
> - OUT: Nothing (registers preserved)

## os_get_random
> Return a random integer between low and high (inclusive)
> - IN: AX = low integer, BX = high integer
> - OUT: CX = random integer

## os_bcd_to_int
> Converts binary coded decimal number to an integer
> - IN: AL = BCD number
> - OUT: AX = integer value

## os_long_int_negate
> Multiply value in DX:AX by -1
> - IN: DX:AX = long integer
> - OUT: DX:AX = -(initial DX:AX)


# MISC.ASM

## os_get_api_version
> Return current version of MikeOS API
> - IN: Nothing
> - OUT: AL = API version number

## os_pause
> Delay execution for specified 110ms chunks
> - IN: AX = 100 millisecond chunks to wait (max delay is 32767, which multiplied by 55ms = 1802 seconds = 30 minutes)

## os_fatal_error
> Display error message and halt execution
> - IN: AX = error message string location


# PORTS.ASM

## os_port_byte_out
> Send byte to a port
> - IN: DX = port address, AL = byte to send

## os_port_byte_in
> Receive byte from a port
> - IN: DX = port address
> - OUT: AL = byte from port

## os_serial_port_enable
> Set up the serial port for transmitting data
> - IN: AX = 0 for normal mode (9600 baud), or 1 for slow mode (1200 baud)

## os_send_via_serial
> Send a byte via the serial port
> - IN: AL = byte to send via serial
> - OUT: AH = Bit 7 clear on success

## os_get_via_serial
> Get a byte from the serial port
> - OUT: AL = byte that was received
> - OUT: AH = Bit 7 clear on success


# SCREEN.ASM

## os_print_string
> Displays text
> - IN: SI = message location (zero-terminated string)
> - OUT: Nothing (registers preserved)

## os_clear_screen
> Clears the screen to background
> - IN/OUT: Nothing (registers preserved)

## os_move_cursor
> Moves cursor in text mode
> - IN: DH, DL = row, column
> - OUT: Nothing (registers preserved)

## os_get_cursor_pos
> Return position of text cursor
> - OUT: DH, DL = row, column

## os_print_horiz_line
> Draw a horizontal line on the screen
> - IN: AX = line type (1 for double (-), otherwise single (=))
> - OUT: Nothing (registers preserved)

## os_show_cursor
> Turns on cursor in text mode
> - IN/OUT: Nothing

## os_hide_cursor
> Turns off cursor in text mode
> - IN/OUT: Nothing

## os_draw_block
> Render block of specified colour
> - IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos

## os_file_selector
> Show a file selection dialog
> - IN: Nothing
> - OUT: AX = location of filename string (or carry set if Esc pressed)

## os_list_dialog
> Show a dialog with a list of options
> - IN: AX = comma-separated list of strings to show (zero-terminated), BX = first help string, CX = second help string
> - OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

## os_draw_background
> Clear screen with white top and bottom bars containing text, and a coloured middle section.
> - IN: AX/BX = top/bottom string locations, CX = colour

## os_print_newline
> Reset cursor to start of next line
> - IN/OUT: Nothing (registers preserved)

## os_dump_registers
> Displays register contents in hex on the screen
> - IN/OUT: AX/BX/CX/DX = registers to show

## os_input_dialog
> Get text string from user via a dialog box
> - IN: AX = string location, BX = message to show
> - OUT: AX = string location

## os_dialog_box
> Print dialog box in middle of screen, with button(s)
> - IN: AX, BX, CX = string locations (set registers to 0 for no display)
> - IN: DX = 0 for single 'OK' dialog, 1 for two-button 'OK' and 'Cancel'
> - OUT: If two-button mode, AX = 0 for OK and 1 for cancel
> - NOTE: Each string is limited to 40 characters

## os_print_space
> Print a space to the screen
> - IN/OUT: Nothing

## os_dump_string
> Dump string as hex bytes and printable characters
> - IN: SI = points to string to dump

## os_print_digit
> Displays contents of AX as a single digit; Works up to base 37, ie digits 0-Z
> - IN: AX = "digit" to format and print

## os_print_1hex
> Displays low nibble of AL in hex format
> - IN: AL = number to format and print

## os_print_2hex
> Displays AL in hex format
> - IN: AL = number to format and print

## os_print_4hex
> Displays AX in hex format
> - IN: AX = number to format and print

## os_input_string
> Get a string from keyboard input
> - IN: AX = output address, BX = maximum bytes of output string
> - OUT: nothing


# SOUND.ASM

## os_speaker_tone
> Generate PC speaker tone (call os_speaker_off to turn off)
> - IN: AX = note frequency
> - OUT: Nothing (registers preserved)

## os_speaker_off
> Turn off PC speaker
> - IN/OUT: Nothing (registers preserved)


# STRING.ASM

## os_string_length
> Return length of a string
> - IN: AX = string location
> - OUT AX = length (other regs preserved)

## os_string_reverse
> Reverse the characters in a string
> - IN: SI = string location

## os_find_char_in_string
> Find location of character in a string
> - IN: SI = string location, AL = character to find
> - OUT: AX = location in string, or 0 if char not present

## os_string_charchange
> Change instances of character in a string
> - IN: SI = string, AL = char to find, BL = char to replace with

## os_string_uppercase
> Convert zero-terminated string to upper case
> - IN/OUT: AX = string location

## os_string_lowercase
> Convert zero-terminated string to lower case
> - IN/OUT: AX = string location

## os_string_copy
> Copy one string into another
> - IN/OUT: SI = source, DI = destination (programmer ensure sufficient room)

## os_string_truncate
> Chop string down to specified number of characters
> - IN: SI = string location, AX = number of characters
> - OUT: String modified, registers preserved

## os_string_join
> Join two strings into a third string
> - IN/OUT: AX = string one, BX = string two, CX = destination string

## os_string_chomp
> Strip leading and trailing spaces from a string
> - IN: AX = string location

## os_string_strip
> Removes specified character from a string (max 255 chars)
> - IN: SI = string location, AL = character to remove

## os_string_compare
> See if two strings match
> - IN: SI = string one, DI = string two
> - OUT: carry set if same, clear if different

## os_string_strincmp
> See if two strings match up to set number of chars
> - IN: SI = string one, DI = string two, CL = chars to check
> - OUT: carry set if same, clear if different

## os_string_parse
> Take string (eg "run foo bar baz") and return pointers to zero-terminated strings (eg AX = "run", BX = "foo" etc.)
> - IN: SI = string
> - OUT: AX, BX, CX, DX = individual strings

## os_string_to_int
> Convert decimal string to integer value
> - IN: SI = string location (max 5 chars, up to '65536')
> - OUT: AX = number

## os_int_to_string
> Convert unsigned integer to string
> - IN: AX = signed int
> - OUT: AX = string location

## os_sint_to_string
> Convert signed integer to string
> - IN: AX = signed int
> - OUT: AX = string location

## os_long_int_to_string
> Convert value in DX:AX to string
> - IN: DX:AX = long unsigned integer, BX = number base, DI = string location
> - OUT: DI = location of converted string

## os_set_time_fmt
> Set time reporting format (eg '10:25 AM' or '2300 hours')
> - IN: AL = format flag, 0 = 12-hr format

## os_get_time_string
> Get current time in a string (eg '10:25')
> - IN/OUT: BX = string location

## os_set_date_fmt
> Set date reporting format (M/D/Y, D/M/Y or Y/M/D - 0, 1, 2)
> - IN: AX = format flag, 0-2
> - If AX bit 7 = 1 = use name for months
> - If AX bit 7 = 0, high byte = separator character

## os_get_date_string
> Get current date in a string (eg '12/31/2007')
> - IN/OUT: BX = string location

## os_string_tokenize
> Reads tokens separated by specified char from a string. Returns pointer to next token, or 0 if none left
> - IN: AL = separator char, SI = beginning
> - OUT: DI = next token or 0 if none
