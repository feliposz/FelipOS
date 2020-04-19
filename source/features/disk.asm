; ==========================================================
; os_get_file_list -- Generate comma-separated string of files on floppy
; IN/OUT: AX = location to store zero-terminated filename string
os_get_file_list:
    call disk_read_root_dir

    pusha
    cld
    mov si, disk_buffer
    mov di, ax
    mov cx, [RootDirEntries]

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

    push si
    push cx

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

    mov al, ','       ; separator
    stosb

    pop cx
    pop si

.skip:
    add si, 32        ; advance to next entry
    loop .next_entry

.end_list:
    dec di            ; overwrite last ',' whit nul terminator
    xor al, al
    stosb
    popa
    ret

; ==========================================================
; disk_read_root_dir -- > Get the root directory contents
; IN: Nothing
; OUT: root directory contents in disk_buffer, carry set if error
disk_read_root_dir:
    pusha
    mov ax, 19      ; root directory
    call disk_convert_l2hts

    mov bx, ds
    mov es, bx
    mov bx, disk_buffer  ; load data into buffer pointed by es:bx

    mov ah, 2            ; read sectors function
    mov al, 14           ; # of sectors (14 = size of root directory)

    stc
    int 13h              ; bios disk services
    jnc .done

    call disk_reset_drive
    jnc disk_read_root_dir

.done:
    popa
    ret

; ==========================================================
; disk_convert_l2hts -- > Calculate head, track and sector for int 13h
; IN: logical sector in AX
; OUT: correct registers for int 13h -> head (DH), track (DL), sector (CL)
disk_convert_l2hts:
    xor dx, dx
    div word [SectorsPerTrack] ; quot=ax, rem=dx
    mov cl, dl
    inc cl          ; Sector = (Logical Sector % SectorsPerTrack) + 1
    xor dx, dx
    div word [Sides]
    mov dh, dl      ; Head  = (Logical Sector / SectorsPerTrack) % Sides
    mov ch, al      ; Track = (Logical Sector / SectorsPerTrack) / Sides
    mov dl, [bootdev]
    ret

; ==========================================================
; disk_reset_drive -- reset floppy drive to retry operation
disk_reset_drive:
    mov dl, [bootdev]
    mov ax, 0
    int 13h
    ret

; ==========================================================
; disk_init -- initialize drive parameters
disk_init:
    mov [bootdev], dl
    jz .done
    ; TODO: get actual drive parameters
.done:
    ret

; ==========================================================

RootDirEntries      dw 224
SectorsPerTrack     dw 18
Sides               dw 2
bootdev             db 0
