os_command_line:
    call os_clear_screen

    mov si, version_msg
    call os_print_string

    mov si, help_msg
    call os_print_string

    jmp get_command

get_command:
    mov si, prompt
    call os_print_string

    mov word [param_list], 0

    mov ax, input
    mov bx, 78
    call os_input_string
    call os_print_newline

    mov ax, input
    call os_string_chomp

    cmp byte [input], 0 ; empty command?
    je get_command

    mov si, input
    mov al, ' '
    call os_string_tokenize

    or di, di
    jz .no_params
    mov [param_list], di
    dec di
    mov byte [di], 0
.no_params:

    mov ax, input
    call os_string_uppercase

    mov si, input
    mov di, cls
    call os_string_compare
    jc cmd_cls

    mov si, input
    mov di, ver
    call os_string_compare
    jc cmd_ver

    mov si, input
    mov di, dir
    call os_string_compare
    jc cmd_dir

    mov si, input
    mov di, ls
    call os_string_compare
    jc cmd_ls

    mov si, input
    mov di, help
    call os_string_compare
    jc cmd_help

    mov si, input
    mov di, time
    call os_string_compare
    jc cmd_time

    mov si, input
    mov di, date
    call os_string_compare
    jc cmd_date

    mov si, input
    mov di, exit
    call os_string_compare
    jc cmd_exit

    mov si, input
    mov di, echo
    call os_string_compare
    jc cmd_echo

    mov si, input
    mov di, size
    call os_string_compare
    jc cmd_size

    mov si, input
    mov di, cat
    call os_string_compare
    jc cmd_cat

    mov si, input
    mov di, ren
    call os_string_compare
    jc cmd_ren

    mov si, input
    mov di, del
    call os_string_compare
    jc cmd_del

    mov si, input
    mov di, copy
    call os_string_compare
    jc cmd_copy

    ; external

    ; has extension?
    mov si, input
    mov al, '.'
    call os_find_char_in_string
    or ax, ax
    jnz .check_bin

    ; add .bin extension
    mov ax, input
    mov bx, bin_ext
    mov cx, temp
    call os_string_join
    mov si, temp
    jmp .check_kernel

.check_bin:
    mov si, input - 1
    add si, ax
    mov di, bin_ext
    call os_string_compare
    jnc .not_bin
    mov si, input

.check_kernel:
    mov di, kernel_name
    call os_string_compare
    jnc .load_bin

    mov si, kernel_msg
    call os_print_string
    jmp get_command

.load_bin:
    mov ax, si
    mov cx, user_space
    call os_load_file
    jc .not_bin
    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov si, [param_list]
    mov di, 0
    call user_space
    jmp get_command

.not_bin:
    mov si, unknown_msg
    call os_print_string

    jmp get_command

cmd_exit:
    ret

cmd_cls:
    call os_clear_screen
    jmp get_command

cmd_help:
    mov si, help_msg
    call os_print_string
    jmp get_command

cmd_ver:
    mov si, version_msg
    call os_print_string
    jmp get_command

cmd_echo:
    mov si, [param_list]
    or si, si
    jz .no_params
    call os_print_string
.no_params:
    call os_print_newline
    jmp get_command

cmd_date:
    mov bx, output
    call os_get_date_string
    mov si, output
    call os_print_string
    call os_print_newline
    jmp get_command

cmd_time:
    mov bx, output
    call os_get_time_string
    mov si, output
    call os_print_string
    call os_print_newline
    jmp get_command

cmd_dir:
    mov ax, user_space
    call os_get_file_list

    mov si, user_space
.next_file:
    mov al, ','
    call os_string_tokenize
    or di, di
    jz .last

    mov byte [di-1], 0
    call os_print_string

    ; fill column with spaces according to filename size
    mov cx, 21
    add cx, si
    sub cx, di

.print_space:
    mov al, ' '
    mov ah, 0eh
    int 10h
    loop .print_space

    mov si, di
    jmp .next_file

.last:
    call os_print_string
    call os_print_newline
    jmp get_command

cmd_ls:
    call disk_read_root_dir

    cld
    mov si, disk_buffer
    mov cx, [RootDirEntries]

.display_header:
    mov dx, 20              ; max lines
    push si
    mov si, ls_header
    call os_print_string
    pop si

.next_entry:
    mov al, [si]

    cmp al, 0         ; first empty entry, skip the rest
    je .end_list
    cmp al, 0e5h      ; erased file
    je .skip

    mov al, [si+0bh]

    test al, 08       ; volume label
    jnz .skip
    test al, 10h      ; subdirectory
    jnz .skip
    test al, 0fh      ; vfat long file name marker
    jnz .skip

    push cx
    push dx
    call display_dir_entry
    pop dx
    pop cx

.skip:
    add si, 32        ; advance to next entry
    dec cx
    jz .end_list
    dec dx
    jnz .next_entry

.next_page:
    push si
    mov si, ls_nextpage
    call os_print_string
    pop si
    call os_wait_for_key
    cmp al, 27
    je .escape
    call os_clear_screen
    jmp .display_header

.escape:
    call os_print_newline
.end_list:
    jmp get_command

display_dir_entry:
    push cx
    push si

    ; fill output buffer with spaces and add NUL terminator
    mov cx, 80
    mov di, output
    mov al, ' '
    rep stosb
    xor al, al
    stosb

    mov di, output

    mov cx, 8
.copy_name:
    cmp byte [si], ' '       ; TODO: handle spaces inside filename
    je .skipspace_name
    movsb
    loop .copy_name
    jmp .end_name
.skipspace_name:
    inc si
    loop .skipspace_name
.end_name:

    cmp byte [si], ' '
    je .end_ext
    mov al, '.'
    stosb

    mov cx, 3
.copy_ext:
    cmp byte [si], ' '
    je .skipspace_ext
    movsb
    loop .copy_ext
    jmp .end_ext
.skipspace_ext:
    inc si
    loop .skipspace_ext
.end_ext:

    pop si
    push si

    ; display file attributes

    mov di, output + 15
    mov bl, [si + 0bh]  ; file attributes

    mov al, '.'
    test bl, 1<<7
    jz .flag_reserved
    mov al, '*'
.flag_reserved:
    stosb

    mov al, '.'
    test bl, 1<<6
    jz .flag_internal
    mov al, '*'
.flag_internal:
    stosb

    mov al, '.'
    test bl, 1<<5
    jz .flag_archive
    mov al, 'A'
.flag_archive:
    stosb

    mov al, '.'
    test bl, 1<<4
    jz .flag_directory
    mov al, 'S'
.flag_directory:
    stosb

    mov al, '.'
    test bl, 1<<3
    jz .flag_volume
    mov al, 'V'
.flag_volume:
    stosb

    mov al, '.'
    test bl, 1<<2
    jz .flag_system
    mov al, 'S'
.flag_system:
    stosb

    mov al, '.'
    test bl, 1<<1
    jz .flag_hidden
    mov al, 'H'
.flag_hidden:
    stosb

    mov al, '.'
    test bl, 1
    jz .flag_readonly
    mov al, 'R'
.flag_readonly:
    stosb

    ; creation date&time
    mov di, output + 25
    mov cx, [si + 0eh]  ; time
    mov dx, [si + 10h]  ; date
    call .append_datetime

    ; modified date&time
    mov di, output + 44
    mov cx, [si + 16h]  ; time
    mov dx, [si + 18h]  ; date
    call .append_datetime

    ; TODO: align numbers to right

    ; first file cluster
    mov di, output + 63
    mov ax, [si + 1ah]
    call os_int_to_string

    push si
    mov si, ax
.copy_first:
    cmp byte [si], 0
    je .end_first
    movsb
    jmp .copy_first
.end_first:
    pop si

    ; file size in bytes
    mov ax, [si + 1ch]
    mov dx, [si + 1eh]
    mov bx, 10
    mov di, temp
    call os_long_int_to_string
    mov si, di

    mov di, output + 70
.copy_size:
    cmp byte [si], 0
    je .end_size
    movsb
    jmp .copy_size
.end_size:

    mov si, output
    call os_print_string

    pop si
    pop cx
    ret

.append_datetime:       ; CX = time, DX = date
    ; month - bits 15-9
    mov ax, dx
    shr ax, 5
    and ax, 7
    call .append_2digit
    mov al, '/'
    stosb

    ; day - bits 4-0
    mov ax, dx
    and ax, 31
    call .append_2digit
    mov al, '/'
    stosb

    ; day - bits 8-5
    mov ax, dx
    shr ax, 9
    and ax, 127
    add ax, 1980
    mov bl, 100
    div bl
    mov al, ah
    call .append_2digit
    mov al, ' '
    stosb

    ; hour - bits 15-11
    mov ax, cx
    shr ax, 11
    and ax, 15
    call .append_2digit
    mov al, ':'
    stosb

    ; minutes - bits 10-5
    mov ax, cx
    shr ax, 5
    and ax, 63
    call .append_2digit
    mov al, ':'
    stosb
    
    ; seconds (2 seconds resolution) - bits 4-0
    mov ax, cx
    and ax, 15
    shl ax, 1
    call .append_2digit

    ret

.append_2digit:      ; append 2 digits in AL to output at DI
    xor ah, ah
    mov bl, 10
    div bl
    add al, '0'
    stosb
    mov al, ah
    add al, '0'
    stosb
    ret

cmd_size:
    mov si, [param_list]
    or si, si
    jz .error
    mov ax, si
    call os_get_file_size
    jc .error
    push bx
    mov si, size_msg
    call os_print_string
    pop ax
    call os_int_to_string
    mov si, ax
    call os_print_string
    call os_print_newline
    jmp get_command

.error:
    mov si, nofile_msg
    call os_print_string
    jmp get_command

cmd_cat:
    mov si, [param_list]
    or si, si
    jz .error

    mov ax, si
    mov cx, user_space
    call os_load_file
    jc .error

    mov cx, bx
    mov si, user_space
    mov ah, 0eh
.loop_cat:
    lodsb
    cmp al, 10
    je .newline
    int 10h
    jmp .next
.newline:
    call os_print_newline
.next:
    loop .loop_cat

    call os_print_newline
    jmp get_command

.error:
    mov si, nofile_msg
    call os_print_string
    jmp get_command

cmd_ren:
    mov si, [param_list]
    or si, si
    jz .error

    mov ax, [param_list]
    call os_string_chomp

    mov al, ' '
    call os_string_tokenize
    or di, di
    jz .error_target
    mov byte [di-1], 0
    mov [param_other], di

    mov ax, [param_list]    ; check source file
    call os_file_exists
    jc .error

    mov ax, [param_other]   ; check target file
    call os_string_chomp
    call os_file_exists
    jnc .error_target

    mov ax, [param_list]
    mov bx, [param_other]
    call os_rename_file

    jmp get_command

.error:
    mov si, nofile_msg
    call os_print_string
    jmp get_command

.error_target:
    mov si, target_msg
    call os_print_string
    jmp get_command

cmd_del:
    mov si, [param_list]
    or si, si
    jz .error
    mov ax, si
    call os_remove_file
    jc .error
    jmp get_command

.error:
    mov si, nofile_msg
    call os_print_string
    jmp get_command


cmd_copy:
    mov si, [param_list]
    or si, si
    jz .error

    mov ax, [param_list]
    call os_string_chomp

    mov al, ' '
    call os_string_tokenize
    or di, di
    jz .error_target
    mov byte [di-1], 0
    mov [param_other], di

    mov ax, [param_list]    ; check source file
    call os_file_exists
    jc .error

    mov ax, [param_other]   ; check target file
    call os_string_chomp
    call os_file_exists
    jnc .error_target

    mov ax, [param_list]
    mov cx, user_space
    call os_load_file
    jc .error

    mov cx, bx
    mov ax, [param_other]
    mov bx, user_space
    call os_write_file
    jc .error_target

    jmp get_command

.error:
    mov si, nofile_msg
    call os_print_string
    jmp get_command

.error_target:
    mov si, target_msg
    call os_print_string
    jmp get_command

echo        db 'ECHO', 0
exit        db 'EXIT', 0
cls         db 'CLS', 0
ver         db 'VER', 0
dir         db 'DIR', 0
ls          db 'LS', 0
help        db 'HELP', 0
date        db 'DATE', 0
time        db 'TIME', 0
size        db 'SIZE', 0
cat         db 'CAT', 0
ren         db 'REN', 0
del         db 'DEL', 0
copy        db 'COPY', 0
help_msg    db 'Commands: HELP CLS ECHO TIME DATE VER DIR LS SIZE CAT REN DEL COPY EXIT', 13, 10, 0
unknown_msg db 'Invalid command or program not found', 13, 10, 0
size_msg    db 'File size (bytes): ', 0
nofile_msg  db 'File not found or invalid filename', 13, 10, 0
target_msg  db 'Invalid target filename', 13, 10, 0
kernel_msg  db 'Cannot run KERNEL.BIN', 13, 10, 0
version_msg db 'FelipOS ', OS_VERSION, 13, 10, 0
bin_ext     db '.BIN', 0
kernel_name db 'KERNEL.BIN', 0
ls_header   db '    Name         attr         created          last write      first  bytes     ', 0
ls_nextpage db 'Press key for next page', 0
prompt      db '>', 0
param_list  dw 0
param_other dw 0
input       times 80 db 0
output      times 81 db 0 ; 1 extra for nul terminator
temp        times 80 db 0