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

    call disk_read_fat
    jc .done

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
; os_file_exists -- Check for presence of file on the floppy
; IN: AX = filename location
; OUT: carry clear if found, set if not
os_file_exists:
    call int_filename_convert
    call disk_read_root_dir
    call disk_get_root_entry
    ret

; ==========================================================
; os_rename_file -- Change the name of a file on the disk
; IN: AX = filename to change, BX = new filename (zero-terminated strings)
; OUT: carry set on error
os_rename_file:
    call disk_read_root_dir
    jc .done
    call int_filename_convert
    jc .done
    call disk_get_root_entry ; DI = file entry
    jc .done

    mov ax, bx
    call int_filename_convert
    mov si, ax
    mov cx, 11
    rep movsb

    call disk_write_root_dir
.done:
    ret

; ==========================================================
; os_remove_file -- Deletes the specified file from the filesystem
; IN: AX = location of filename to remove
os_remove_file:
    pusha
    call int_filename_convert
    call disk_read_root_dir
    jc .error
    call disk_get_root_entry
    jc .error

    mov bx, [di + 1ah]
    mov [disk_cluster], bx

    mov byte [di], 0e5h ; erased file marker
    call disk_write_root_dir
    jc .error

    or bx, bx ; no first cluster (empty file)
    jz .done

    call disk_read_fat
    jc .error

.next_cluster:
    mov ax, [disk_cluster]
    cmp ax, 0x0ff0                  ; last cluster indicator can be 0xff0, 0xff8 or 0xfff
    jge .last_cluster

    ; clusters are stored as 12-bit in FAT12
    ; calculate cluster offset in table
    ; offset = cluster * 3 / 2
    mov ax, [disk_cluster]
    shl ax, 1
    add ax, [disk_cluster]
    shr ax, 1
    mov bx, ax
    mov dx, [disk_buffer+bx]

    ; check alignment
    mov ax, [disk_cluster]
    test ax, 1
    jz .even_cluster

.odd_cluster:
    shr dx, 4                       ; aligned to left, shift it right 4 bits
    mov [disk_cluster], dx
    and word [disk_buffer+bx], 000fh     ; erase 12 bits to left, keep 4 bits on the right
    jmp .next_cluster

.even_cluster:
    and dx, 0x0fff                  ; aligned to right, discard 4 high bits
    mov [disk_cluster], dx
    and word [disk_buffer+bx], 0f000h    ; erase 12 bits to right, keep 4 bits on the left
    jmp .next_cluster

.last_cluster:
    call disk_write_fat

.done:
    popa
    clc
    ret

.error:
    popa
    stc
    ret

; ==========================================================
; os_create_file -- Creates a new 0-byte file on the floppy disk
; IN: AX = location of filename
; OUT: Nothing
os_create_file:
    pusha
    call int_filename_convert
    call disk_read_root_dir
    jc .error
    call disk_get_free_entry
    jc .error

    mov si, ax
    mov cx, 11
    rep movsb

    call int_get_timestamp

    mov al, 20h         ; file attribute (20h = Archive)
    stosb
    mov al, 18h         ; Windows lowercase name + extension
    stosb
    mov al, 0           ; fine resolution creation time (10ms)
    stosb
    mov ax, [file_time] ; creation time
    stosw
    mov ax, [file_date] ; creation date
    stosw
    mov ax, [file_date] ; access date
    stosw
    mov ax, 0           ; unused
    stosw
    mov ax, [file_time] ; modified time
    stosw
    mov ax, [file_date] ; modified date
    stosw
    mov ax, 0           ; first cluster
    stosw
    mov ax, 0           ; size (4 bytes)
    stosw
    stosw

    call disk_write_root_dir
    jc .error

    popa
    clc
    ret

.error:
    popa
    stc
    ret

; ==========================================================
; os_write_file -- Save (max 64K) file to disk
; IN: AX = filename, BX = data location, CX = bytes to write
; OUT: Carry clear if OK, set if failure
os_write_file:
    pusha
    mov [file_name], ax
    mov [file_pointer], bx
    mov [file_size], cx

    ; if file exists, return failure
    call os_file_exists
    jnc .error

    call disk_read_fat

    ; build a free cluster list (128 clusters since max size is 64k)

    mov cx, 128             ; max filesize = 64k = 512 bytes * 128 clusters
    xor ax, ax
    rep stosw               ; clear free list

    mov cx, 0
    mov dx, 1536            ; 9 sectors * 512 bytes / 3 bytes for every pair

    mov word [disk_cluster], 2  ; first 2 pairs are reserved
    mov si, disk_buffer + 3     ; 2 * 12-bits entry = 3 bytes (24-bits)
    mov di, free_list

.next_pair:

    ; even cluster
    mov ax, [si]
    and ax, 0fffh
    or ax, ax
    jnz .even_skip
    mov ax, [disk_cluster] ; add even cluster to free list
    stosw
    inc cx
.even_skip:

    cmp cx, 128
    jge .end_free

    ; odd cluster
    mov ax, [si+1]
    shr ax, 4
    or ax, ax
    jnz .odd_skip
    mov ax, [disk_cluster] ; add odd cluster to free list
    inc ax
    stosw
    inc cx
.odd_skip:

    cmp cx, 128
    jge .end_free

    dec dx
    or dx, dx
    jz .end_free

    add word [disk_cluster], 2
    add si, 3
    jmp .next_pair
.end_free:

    mov [free_clusters], cx

    ; check how many clusters needed for file (file_size / 512)

    xor dx, dx
    mov ax, [file_size]
    mov bx, 512
    div bx
    or dx, dx
    jz .exact
    inc ax      ; + 1 if remainder is not zero
.exact:
    cmp ax, cx
    jg .error        ; if not enough free clusters, return failure

    mov [file_clusters], ax

    ; write blocks using free cluster list

    mov si, free_list
    mov cx, [file_clusters]

.write_file:
    or cx, cx ; is last cluster?
    jz .write_complete

    push cx

    ; User Data Offset = ReservedForBoot + SectorsPerFat*NumberOfFats + RootDirEntries*32/BytesPerSector - 2 <= reserved clusters on FAT
    mov ax, [si]   ; AX = current cluster
    add ax, 31
    call disk_convert_l2hts

    mov bx, [file_pointer]
    mov ah, 3         ; write sectors function
    mov al, 1         ; write 1 sector
    stc
    int 0x13          ; bios disk services
    jc .write_error

    pop cx

    add word [file_pointer], 512
    add si, 2
    dec cx
    jmp .write_file

.write_error:
    pop cx
    jmp .error

.write_complete:

    ; update fat with used clusters
    mov si, free_list
    mov cx, [file_clusters]

.update_fat:
    or cx, cx
    jz .done_fat

    ; offset = cluster * 3 / 2
    mov ax, [si]
    shl ax, 1
    add ax, [si]
    shr ax, 1
    mov di, disk_buffer
    add di, ax

    ; BX = next cluster in linked list
    mov bx, [si+2]
    cmp cx, 1
    jnz .not_last
    mov bx, 0xfff   ; EOF marker
.not_last:

    ; check alignment
    mov ax, [si]
    test ax, 1
    jz .even_cluster
    shl bx, 4           ; if odd, align 12 bits before writing
.even_cluster:
    or [di], bx

    add si, 2
    dec cx
    jmp .update_fat

.done_fat:
    call disk_write_fat
    jc .error

    ; create new file entry with size and pointing to first cluster

    call disk_read_root_dir
    jc .error
    call disk_get_free_entry
    jc .error

    mov ax, [file_name]
    call int_filename_convert
    mov si, ax
    mov cx, 11
    rep movsb

    call int_get_timestamp

    mov al, 20h         ; file attribute (20h = Archive)
    stosb
    mov al, 18h         ; Windows lowercase name + extension
    stosb
    mov al, 0           ; fine resolution creation time (10ms)
    stosb
    mov ax, [file_time] ; creation time
    stosw
    mov ax, [file_date] ; creation date
    stosw
    mov ax, [file_date] ; access date
    stosw
    mov ax, 0           ; unused
    stosw
    mov ax, [file_time] ; modified time
    stosw
    mov ax, [file_date] ; modified date
    stosw
    mov ax, [free_list] ; first cluster
    stosw
    mov ax, [file_size] ; size low word
    stosw
    xor ax, ax          ; size high word
    stosw

    call disk_write_root_dir
    jc .error

    popa
    clc
    ret

.error:
    popa
    stc
    ret

; ==========================================================
; INTERNAL OS ROUTINES
; Not accessible to user programs

; ==========================================================
; int_hexdump --  Dump memory segment
; IN: SI = memory address, CX = bytes
int_hexdump:
    pusha
.next_row:
    or cx, cx
    jz .done
    mov ax, si
    call os_print_4hex
    mov al, ':'
    mov ah, 0eh
    int 10h
    call os_print_space
    mov dx, 16
.next_byte:
    lodsb
    call os_print_2hex
    call os_print_space
    dec cx
    jz .done
    dec dx
    jnz .next_byte
    call os_print_newline
    jmp .next_row
.done:
    call os_print_newline
    popa
    ret

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
; int_get_timestamp -- Set current timestamp for file operations
; OUT: Update file_date and file_time
int_get_timestamp:
    pusha

.retry_time:
    mov ah, 2
    int 1ah
    jc .retry_time

    ; CH = hours in BCD
    ; CL = minutes in BCD
    ; DH = seconds in BCD
    ; DL = 1 if daylight savings time option

    xor bx, bx

    ; hour - bits 15-11
    mov al, ch
    call os_bcd_to_int
    shl ax, 11
    or bx, ax

    ; minutes - bits 10-5
    mov al, cl
    call os_bcd_to_int
    shl ax, 5
    or bx, ax

    ; seconds (2 seconds resolution) - bits 4-0
    mov al, dh
    call os_bcd_to_int
    shr ax, 1
    or bx, ax

    mov [file_time], bx

.retry_date:
    mov ah, 4
    int 1ah
    jc .retry_date

    ; CH    century, in BCD  (19H ... 20H)
    ; CL    year, in BCD     (00H ... 99H)
    ; DH    month, in BCD    (i.e., 01H=Jan ... 12H=Dec)
    ; DL    day, in BCD      (00H ... 31H)

    ; year - bits 15-9
    mov al, ch
    call os_bcd_to_int
    mov bl, 100
    mul bl
    mov bx, ax
    mov al, cl
    call os_bcd_to_int
    add bx, ax
    sub bx, 1980
    shl bx, 9

    ; month - bits 8-5
    mov al, dh
    call os_bcd_to_int
    shl ax, 5
    or bx, ax

    ; day - bits 4-0
    mov al, dl
    call os_bcd_to_int
    or bx, ax

    mov [file_date], bx

    popa
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
    mov al, [di]

    cmp al, 0         ; first empty entry, skip the rest
    je .not_found
    cmp al, 0e5h      ; erased file
    je .skip

    mov al, [di+0bh]

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

    pop cx
    pop di
    pop si

    je .found

.skip:
    add di, 32        ; advance to next entry
    loop .next_entry

.not_found:
    pop si
    pop cx
    pop ax
    stc
    ret

.found:
    pop si
    pop cx
    pop ax
    clc
    ret


; ==========================================================
; disk_get_free_entry --  Search RAM copy of root dir for a free file entry
; OUT: DI = location in disk_buffer of free root dir entry, or carry set if no free entry found
disk_get_free_entry:
    push ax
    push cx
    push dx
    cld
    xor dx, dx
    mov di, disk_buffer
    mov cx, [RootDirEntries]

.next_entry:
    mov al, [di]
    cmp al, 0         ; first empty entry, skip the rest
    je .empty_found
    cmp al, 0e5h
    jne .advance
    mov dx, di        ; erased file
.advance:
    add di, 32        ; advance to next entry
    loop .next_entry

    or dx, dx
    jz .not_found
    mov di, dx        ; if no empty entry found, use erased entry

.empty_found:
    pop dx
    pop cx
    pop ax
    clc
    ret

.not_found:
    pop dx
    pop cx
    pop ax
    stc
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
    jc .error

    popa
    clc
    ret

.error:
    popa
    stc
    ret

; ==========================================================
; disk_write_root_dir -- Write root directory contents from disk_buffer to disk
; IN: root dir copy in disk_buffer
; OUT: carry set if error
disk_write_root_dir:
    pusha
    mov ax, 19      ; root directory
    call disk_convert_l2hts

    mov bx, ds
    mov es, bx
    mov bx, disk_buffer  ; write data from buffer pointed by es:bx

    mov ah, 3            ; write sectors function
    mov al, 14           ; # of sectors (14 = size of root directory)

    stc
    int 13h              ; bios disk services
    jc .error

    popa
    clc
    ret

.error:
    popa
    stc
    ret

; ==========================================================
; disk_read_fat -- Read FAT entry from floppy into disk_buffer
; IN: Nothing
; OUT: carry set if failure
disk_read_fat:
    pusha
    mov ax, 1            ; 1st fat entry
    call disk_convert_l2hts

    mov bx, disk_buffer  ; load data into buffer pointed by es:bx
    mov ah, 2            ; read sectors function
    mov al, [SectorsPerFat]
    stc
    int 0x13             ; bios disk services
    jc .error

    popa
    clc
    ret

.error:
    popa
    stc
    ret

; ==========================================================
; disk_write_fat -- Save FAT contents from disk_buffer in RAM to disk
; IN: FAT in disk_buffer
; OUT: carry set if failure
disk_write_fat:
    pusha
    mov ax, 1            ; 1st fat entry
    call disk_convert_l2hts

    mov bx, disk_buffer  ; load data into buffer pointed by es:bx
    mov ah, 3            ; read sectors function
    mov al, [SectorsPerFat]
    stc
    int 0x13             ; bios disk services
    jc .error

    popa
    clc
    ret

.error:
    popa
    stc
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
file_date           dw 0
file_time           dw 0
file_clusters       dw 0
file_name           dw 0
free_list           times 128 dw 0
free_clusters       dw 0