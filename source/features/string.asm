; ==========================================================
; os_string_strincmp -- See if two strings match up to set number of chars
; IN: SI = string one, DI = string two, CL = chars to check
; OUT: carry set if same, clear if different
os_string_strincmp:
    pusha
    cld
.loop:
    jz .equal
    mov al, [si]
    cmpsb
    jne .not_equal
    or al, al
    jz .equal
    loop .loop
.equal:
    popa
    stc
    ret
.not_equal:
    popa
    clc
    ret

; ==========================================================
; os_string_compare -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different
os_string_compare:
    pusha
    cld
.loop:
    mov al, [si]
    cmpsb
    jne .not_equal
    or al, al
    jnz .loop
.equal:
    popa
    stc
    ret
.not_equal:
    popa
    clc
    ret

; ==========================================================
; os_string_uppercase -- Convert zero-terminated string to upper case
; IN/OUT: AX = string location
os_string_uppercase:
    pusha
    mov si, ax
.loop:
    mov al, [si]
    or al, al
    jz .done
    cmp al, 'a'
    jl .skip
    cmp al, 'z'
    jg .skip
    sub ax, 'a' - 'A'
    mov [si], al
.skip:
    inc si
    jmp .loop
.done:
    popa
    ret

; ==========================================================
; os_string_lowercase -- Convert zero-terminated string to lower case
; IN/OUT: AX = string location
os_string_lowercase:
    pusha
    mov si, ax
.loop:
    mov al, [si]
    or al, al
    jz .done
    cmp al, 'A'
    jl .skip
    cmp al, 'Z'
    jg .skip
    add al, 'a' - 'A'
    mov [si], al
.skip:
    inc si
    jmp .loop
.done:
    popa
    ret

; ==========================================================
; os_string_chomp -- Strip leading and trailing spaces from a string
; IN: AX = string location
os_string_chomp:
    pusha
    cld
    mov bx, ax
    mov si, ax
    mov di, ax
.scan_lead:                ; skip all leading spaces
    mov al, [si]
    or al, al
    jz .cut_trail
    cmp al, ' '
    jne .shift_left
    inc si
    jmp .scan_lead
.shift_left:               ; move string to the left
    mov al, [si]
    or al, al
    jz .done_shift
    movsb
    jmp .shift_left
.done_shift:
    mov byte [di], 0       ; restore terminator
    mov si, ax
    mov di, ax
.scan_trail:               ; scan for first space after non-space character
    mov al, [si]
    or al, al
    jz .cut_trail
    cmp al, ' '
    je .is_space
    mov di, si
    inc di
.is_space:
    inc si
    jmp .scan_trail
.cut_trail:
    mov byte [di], 0       ; place terminator after last non-space
.done:
    popa
    ret

; ==========================================================
; os_string_tokenize -- Reads tokens separated by specified char from a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning
; OUT: DI = next token or 0 if none
os_string_tokenize:
    push ax
    push bx
    push si
    mov di, 0
.next:
    mov bl, [si]
    or bl, bl
    jz .done
    inc si
    cmp bl, al
    jne .next
.found:
    mov di, si
.done:
    pop si
    pop bx
    pop ax
    ret

; ==========================================================
; os_set_time_fmt -- Set time reporting format (eg '10:25 AM' or '2300 hours')
; IN: AL = format flag, 0 = 12-hr format
os_set_time_fmt:
    mov [time_fmt], al
    ret

; ==========================================================
; os_set_date_fmt -- Set date reporting format (M/D/Y, D/M/Y or Y/M/D - 0, 1, 2)
; IN: AX = format flag, 0-2
; If AX bit 7 = 1 = use name for months
; If AX bit 7 = 0, high byte = separator character
os_set_date_fmt:
    test ax, 1<<7
    jnz .no_sep
    mov byte [date_mon], 0
    mov [date_sep], ah
    jmp .sep
.no_sep:
    mov byte [date_mon], 1
    mov byte [date_sep], ' '
.sep:
    and al, 3
    mov [date_fmt], al
    ret

; ==========================================================
; os_get_time_string -- Get current time in a string (eg '10:25')
; IN/OUT: BX = string location
os_get_time_string:
    pusha

.retry:
    mov ah, 2
    int 1ah
    jc .retry

    ; CH = hours in BCD
    ; CL = minutes in BCD
    ; DH = seconds in BCD
    ; DL = 1 if daylight savings time option

    mov al, [time_fmt]
    or al, al
    jz .12hour_fmt
    jmp .24hour_fmt

.12hour_fmt:
    mov ah, 0
    cmp ch, 0
    je .midnight
    cmp ch, 24
    je .midnight
    cmp ch, 12h
    je .noon
    jg .pm
    jmp .12hour_out
.noon:
    mov ah, 1
.midnight:
    mov ch, 12h
    jmp .12hour_out
.pm:
    mov ah, 1
    sub ch, 12h
    das
.12hour_out:
    mov al, ch
    shr al, 4
    add al, '0'
    mov [bx], al
    mov al, ch
    and al, 0fh
    add al, '0'
    mov [bx+1], al

    mov byte [bx+2], ':'

    mov al, cl
    shr al, 4
    add al, '0'
    mov [bx+3], al
    mov al, cl
    and al, 0fh
    add al, '0'
    mov [bx+4], al

    mov byte [bx+5], ' '
    mov byte [bx+6], 'a'
    mov byte [bx+7], 'm'

    or ah, ah
    jz .am
    mov byte [bx+6], 'p'
.am:
    mov byte [bx+8], 0
    popa
    ret

.24hour_fmt:
    mov al, ch
    shr al, 4
    add al, '0'
    mov [bx], al
    mov al, ch
    and al, 0fh
    add al, '0'
    mov [bx+1], al

    mov al, cl
    shr al, 4
    add al, '0'
    mov [bx+2], al
    mov al, cl
    and al, 0fh
    add al, '0'
    mov [bx+3], al

    mov byte [bx+4], ' '
    mov byte [bx+5], 'h'
    mov byte [bx+6], 'o'
    mov byte [bx+7], 'u'
    mov byte [bx+8], 'r'
    mov byte [bx+9], 's'
    mov byte [bx+10], 0

    popa
    ret

; ==========================================================
; os_get_date_string -- Get current date in a string (eg '12/31/2007')
; IN/OUT: BX = string location
os_get_date_string:
    pusha
    mov di, bx
.retry:
    mov ah, 4
    int 1ah
    jc .retry

    ; CH    century, in BCD  (19H ... 20H)
    ; CL    year, in BCD     (00H ... 99H)
    ; DH    month, in BCD    (i.e., 01H=Jan ... 12H=Dec)
    ; DL    day, in BCD      (00H ... 31H)

    cmp byte [date_fmt], 0
    jne .not0
    call .month
    call .sep
    call .day
    call .sep
    call .year
    jmp .done
.not0:

    cmp byte [date_fmt], 1
    jne .not1
    call .day
    call .sep
    call .month
    call .sep
    call .year
    jmp .done
.not1:

    call .year
    call .sep
    call .month
    call .sep
    call .day

.done:
    mov byte [di], 0
    popa
    ret

.sep:
    mov al, [date_sep]
    stosb
    ret

.year:
    mov al, ch
    shr al, 4
    add al, '0'
    stosb
    mov al, ch
    and al, 0fh
    add al, '0'
    stosb
    mov al, cl
    shr al, 4
    add al, '0'
    stosb
    mov al, cl
    and al, 0fh
    add al, '0'
    stosb
    ret

.month:
    mov al, [date_mon]
    or al, al
    jnz .month_name
    mov al, dh
    shr al, 4
    or al, al
    add al, '0'
    stosb
    mov al, dh
    and al, 0fh
    add al, '0'
    stosb
    ret
.month_name:
    push cx
    push dx
    mov al, dh
    call os_bcd_to_int
    dec ax
    mov cx, 3
    mul cx
    mov si, month_name
    add si, ax
    rep movsb
    pop dx
    pop cx
    ret

.day:
    mov al, dl
    shr al, 4
    add al, '0'
    stosb
    mov al, dl
    and al, 0fh
    add al, '0'
    stosb
    ret

; ==========================================================
; os_int_to_string -- Convert unsigned integer to string
; IN: AX = signed int
; OUT: AX = string location
os_int_to_string:
    pusha
    mov di, int_string
    or ax, ax
    jnz .not_zero
    mov dx, '0'
    mov cx, 1
    push dx
    jmp .pop_digits
.not_zero:
    mov bx, 10
    mov cx, 0
.push_digits:
    xor dx, dx
    or ax, ax
    jz .pop_digits
    div bx
    add dl, '0'
    push dx
    inc cx
    jmp .push_digits
.pop_digits:
    pop dx
    mov [di], dl
    inc di
    dec cx
    or cx, cx
    jnz .pop_digits
.done:
    mov byte [di], 0
    popa
    mov ax, int_string
    ret

; ==========================================================
; os_sint_to_string -- Convert signed integer to string
; IN: AX = signed int
; OUT: AX = string location
os_sint_to_string:
    cmp ax, 0
    jl .negative
    call os_int_to_string
    ret
.negative:
    neg ax
    call os_int_to_string
    mov ax, neg_string
    ret

; ==========================================================
; os_long_int_to_string -- Convert value in DX:AX to string
; IN: DX:AX = long unsigned integer, BX = number base, DI = string location
; OUT: DI = location of converted string
os_long_int_to_string:
    pusha

    mov di, long_string
    mov byte [di], 0

    cmp bx, 37
    ja .done

    cmp bx, 0
    je .done

.conversion:            ; divide dx:ax (32-bit) by bx (base)
    mov cx, 0
    xchg ax, cx
    xchg ax, dx
    div bx
    xchg ax, cx
    div bx
    xchg cx, dx         ; cx = remainder, dx:ax = quotient

    ; digits will be added in reverse order
    cmp cx, 9
    jle .is_digit
    add cx, 'A'-10
    jmp .not_digit
.is_digit:
    add cx, '0'
.not_digit:
    mov [di], cl
    inc di
    mov cx, dx
    or cx, ax
    jnz .conversion

    mov al, 0 ; add nul terminator
    stosb

    mov si, long_string
    call os_string_reverse

.done:
    popa
    mov di, long_string
    ret

; os_string_reverse -- Reverse the characters in a string
; IN: SI = string location
os_string_reverse:
    pusha

    ; point DI to last char
    mov di, si
.advance:
    cmp byte [di], 0
    jz .end_reached
    inc di
    jmp .advance

.end_reached:
    dec di

    ; swap SI and DI, move SI left and DI right
.reverse_loop:
    cmp si, di
    jae .done
    mov al, [si]
    mov bl, [di]
    mov [si], bl
    mov [di], al
    inc si
    dec di
    jmp .reverse_loop

.done:
    popa
    ret

time_fmt     db 0
date_fmt     db 0
date_mon     db 0
date_sep     db '/'
month_name   db 'JanFebMarAprMayJunJulAugSepOctNovDec'
neg_string   db '-'
int_string   times 7 db 0
long_string  times 11 db 0
