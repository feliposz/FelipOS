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
; os_get_file_size --  Get file size information for specified file
; IN: AX = filename
; OUT: BX = file size in bytes (up to 64K) or carry set if file not found
os_get_file_size:
    call int_filename_convert
    call disk_read_root_dir
    call disk_get_root_entry
    mov bx, [di + 1ch]  ; lower word of file size in dir entry
    ret

; ==========================================================
; os_load_file -- Load file into RAM
; IN: AX = location of filename, CX = location in RAM to load file
; OUT: BX = file size (in bytes), carry set if file not found
os_load_file:
    push ax
    push cx
    push dx
    push di
    mov [file_pointer], cx
    call int_filename_convert
    call disk_read_root_dir
    call disk_get_root_entry
    jc .done

    mov bx, [di + 1ch]
    mov [file_size], bx
    mov bx, [di + 1ah]
    mov [disk_cluster], bx

.read_fat:
    mov ax, 1            ; 1st fat entry
    call disk_convert_l2hts

    mov bx, disk_buffer  ; load data into buffer pointed by es:bx
    mov ah, 2            ; read sectors function
    mov al, [SectorsPerFat]
    stc
    int 0x13             ; bios disk services
    jnc .load_cluster

    call disk_reset_drive
    jnc .read_fat

    jmp .done

.load_cluster:
    mov ax, [disk_cluster]   ; is last cluster?
    cmp ax, 0x0ff0      ; last cluster indicator can be 0xff0, 0xff8 or 0xfff
    jge .file_complete

    ; User Data Offset = ReservedForBoot + SectorsPerFat*NumberOfFats + RootDirEntries*32/BytesPerSector - 2 <= reserved clusters on FAT
    mov ax, [disk_cluster]
    add ax, 31
    call disk_convert_l2hts

    mov bx, [file_pointer]
    mov ah, 2         ; read sectors function
    mov al, 1         ; read 1 sector
    stc
    int 0x13          ; bios disk services
    jnc .cluster_ok

    ; retry on error
    call disk_reset_drive
    jnc .load_cluster
    jmp .done

.cluster_ok:
    mov ax, 512        ; advance pointer
    add [file_pointer], ax

    ; clusters are stored as 12-bit in FAT12
    ; calculate cluster offset in table
    ; offset = cluster * 3 / 2
    mov ax, [disk_cluster]
    shl ax, 1
    add ax, [disk_cluster]
    shr ax, 1
    mov bx, ax
    mov dx, [disk_buffer+bx] ; loaded 16-bits

    ; check alignment
    mov ax, [disk_cluster]
    test ax, 1
    jz .even_cluster

.odd_cluster:
    shr dx, 4           ; aligned to left, shift it right 4 bits
    mov [disk_cluster], dx
    jmp .load_cluster

.even_cluster:          ; aligned to right, discard 4 high bits
    and dx, 0x0fff
    mov [disk_cluster], dx
    jmp .load_cluster

.file_complete:
    clc
    mov bx, [file_size]
.done:
    pop di
    pop dx
    pop cx
    pop ax
    ret

; ==========================================================
; INTERNAL OS ROUTINES
; Not accessible to user programs

; ==========================================================
; int_filename_convert --  Change 'TEST.BIN' into 'TEST    BIN' as per FAT12
; IN: AX = filename string
; OUT: AX = location of converted string (carry set if invalid)
int_filename_convert:
    pusha
    mov si, ax

    mov cx, 11
    mov di, filename_converted
    mov al, ' '
    rep stosb

    mov di, filename_converted
.copy_name:
    cmp byte [si], '.'
    je .end_name
    cmp byte [si], 0
    je .done
    movsb
    jmp .copy_name
.end_name:

    inc si
    mov di, filename_converted + 8

.copy_ext:
    cmp byte [si], 0
    je .done
    movsb
    jmp .copy_ext
.end_ext:

.done:
    popa
    mov ax, filename_converted
    ret

; ==========================================================
; disk_get_root_entry --  Search RAM copy of root dir for file entry
; IN: AX = filename
; OUT: DI = location in disk_buffer of root dir entry, or carry set if file not found
disk_get_root_entry:
    push ax
    push cx
    push si

    cld
    mov si, ax
    mov di, disk_buffer
    mov cx, [RootDirEntries]

.next_entry:
    mov al, [si]

    cmp al, 0         ; first empty entry, skip the rest
    je .not_found
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
    push di
    push cx

    mov cx, 11
    rep cmpsb
    je .found

    pop cx
    pop di
    pop si

.skip:
    add di, 32        ; advance to next entry
    loop .next_entry
    jmp .not_found

.found:
    pop cx
    pop di
    pop si
    clc
    jmp .done

.not_found:
    stc

.done:
    pop si
    pop cx
    pop ax
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
SectorsPerFat       dw 9
bootdev             db 0
filename_converted  times 12 db 0
disk_cluster        dw 0
file_size           dw 0
file_pointer        dw 0