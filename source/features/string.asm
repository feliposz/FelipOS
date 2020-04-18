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
    or ax, 1<<7
    jnz .no_sep
    mov byte [date_mon], 0
    mov [date_sep], ah
    jmp .sep
.no_sep:
    mov byte [date_mon], 1
    mov byte [date_sep], '/'
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
    add al, 48
    mov [bx], al
    mov al, ch
    and al, 0fh
    add al, 48
    mov [bx+1], al

    mov byte [bx+2], ':'

    mov al, cl
    shr al, 4
    add al, 48
    mov [bx+3], al
    mov al, cl
    and al, 0fh
    add al, 48
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
    add al, 48
    mov [bx], al
    mov al, ch
    and al, 0fh
    add al, 48
    mov [bx+1], al

    mov al, cl
    shr al, 4
    add al, 48
    mov [bx+2], al
    mov al, cl
    and al, 0fh
    add al, 48
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
    mov si, bx
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
    mov byte [si], 0
    popa
    ret

.sep:
    mov al, [date_sep]
    mov byte [si], al
    inc si
    ret

.year:
    mov al, ch
    shr al, 4
    add al, 48
    mov [si], al
    inc si
    mov al, ch
    and al, 0fh
    add al, 48
    mov [si], al
    inc si
    mov al, cl
    shr al, 4
    add al, 48
    mov [si], al
    inc si
    mov al, cl
    and al, 0fh
    add al, 48
    mov [si], al
    inc si
    ret

.month:
    mov al, dh
    shr al, 4
    add al, 48
    mov [si], al
    inc si
    mov al, dh
    and al, 0fh
    add al, 48
    mov [si], al
    inc si
    ret

.day:
    mov al, dl
    shr al, 4
    add al, 48
    mov [si], al
    inc si
    mov al, dl
    and al, 0fh
    add al, 48
    mov [si], al
    inc si
    ret

time_fmt db 1
date_fmt db 1
date_mon db 0
date_sep db '/'
