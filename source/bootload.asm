bits 16

jmp short start
nop

OEMLabel            db 'FELIBOOT'
BytesPerSector      dw 512
SectorsPerCluster   db 1
ReservedForBoot     dw 1
NumberOfFats        db 2
RootDirEntries      dw 224
LogicalSectors      dw 2880
MediumByte          db 0xf0
SectorsPerFat       dw 9
SectorsPerTrack     dw 18
Sides               dw 2
HiddenSectors       dd 0
LargeSectors        dd 0
DriveNo             dw 0
Signature           db 41
VolumeID            dd 0x00000000
VolumeLabel         db 'FelipOS    '
FileSystem          db 'FAT12   '

start:
    cli
    mov ax, 0x07c0
    mov ds, ax       ; data segment 07c0:xxxx
    add ax, 544      ; (8192 for buffer + 512 for boot sector) / 16 bytes per paragraph
    mov ss, ax       ; set stack segment
    mov sp, 4096     ; stack pointer start at end of 4k stack
    sti

    mov [bootdev], dl

read_root_dir:
    mov ax, 19      ; root directory
    call logical_to_hts

    mov bx, ds
    mov es, bx
    mov bx, buffer  ; load data into buffer pointed by es:bx

    mov ah, 2       ; read sectors function
    mov al, 14      ; # of sectors (14 = size of root directory)

    stc
    int 0x13        ; bios disk services

    jnc search_kernel

    call reset_floppy
    jnc read_root_dir

floppy_fail:
    mov si, err_floppy
    call print_string
    jmp reset

search_kernel:
    cld
    mov di, buffer
    mov cx, [RootDirEntries]

.next:
    push cx
    push di
    mov si, kernel_file
    mov cx, 11
    rep cmpsb           ; compare entry to filename
    je kernel_found
    pop di
    add di, 32          ; advance to next entry
    pop cx
    loop .next

no_kernel:
    mov si, err_kernel
    call print_string
    jmp reset

kernel_found:
    mov bx, [es:di+15] ; point to first cluster (pos 26 = 11 for filename + 15)
    mov [cluster], bx

read_fat:
    mov ax, 1       ; 1st fat entry
    call logical_to_hts

    mov bx, ds
    mov es, bx
    mov bx, buffer  ; load data into buffer pointed by es:bx

    mov ah, 2       ; read sectors function
    mov al, [SectorsPerFat]

    stc
    int 0x13        ; bios disk services
    jnc kernel_load

    call reset_floppy
    jnc read_fat

    jmp floppy_fail

kernel_load:

.load_cluster:
    mov ax, [cluster]
    call print_word

    ; TODO: code to load current cluster

    mov ax, [cluster]  ; is last cluster?
    cmp ax, 0x0fff
    je .end

.calc_next:
    ; clusters are stored as 12-bit in FAT12
    ; calculate cluster offset in table
    ; offset = cluster * 3 / 2
    mov ax, [cluster]
    shl ax, 1
    add ax, [cluster]
    shr ax, 1
    mov bx, ax
    mov dx, [buffer+bx] ; loaded 16-bits

    ; check alignment
    mov ax, [cluster]
    test ax, 1
    jz .even

.odd:
    shr dx, 4           ; aligned to left, shift it right 4 bits
    mov [cluster], dx
    jmp .load_cluster

.even:                  ; aligned to right, discard 4 high bits
    and dx, 0x0fff
    mov [cluster], dx
    jmp .load_cluster

.end:
    mov si, msg_ok
    call print_string
    jmp reset

; print nul terminated string pointed by SI
print_string:
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp .loop
.done:
    ret

; print hexadecimal value of byte on AL
print_byte:
    push ax
    shr al, 4
    and ax, 0x000f
    mov bx, ax
    mov al, [hex_dig + bx]
    mov ah, 0x0e
    int 0x10
    pop ax
    and ax, 0x000f
    mov bx, ax
    mov al, [hex_dig + bx]
    mov ah, 0x0e
    int 0x10
    ret

print_word:
    push ax
    mov al, ah
    call print_byte
    pop ax
    call print_byte
    mov al, ' '
    mov ah, 0x0e
    int 0x10
    ret


; wait keypress and reboot
reset:
    mov ax, 0
    int 0x16
    mov ax, 0
    int 0x19
    jmp $

; reset floppy drive to retry operation
reset_floppy:
    mov dl, [bootdev]
    mov ax, 0
    int 0x13
    ret

; convert logical sector (AX) to head (DH), track (DL), sector (CL) geometry
logical_to_hts:
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

; temporary debug routine to display values for logical_to_hts
; debug_hts:
;     push ax
;     mov al, ah
;     call print_byte
;     pop ax
;     push ax
;     call print_byte
;     mov si, debug_msg_logical
;     call print_string

;     pop ax
;     call logical_to_hts
;     mov [debug_head], dh
;     mov [debug_track], ch
;     mov [debug_sector], cl
;     mov [debug_dev], dl

;     mov al, [debug_head]
;     call print_byte
;     mov si, debug_msg_head
;     call print_string

;     mov al, [debug_track]
;     call print_byte
;     mov si, debug_msg_track
;     call print_string

;     mov al, [debug_sector]
;     call print_byte
;     mov si, debug_msg_sector
;     call print_string

;     mov al, [debug_dev]
;     call print_byte
;     mov si, debug_msg_device
;     call print_string

;     mov dh, [debug_head]
;     mov ch, [debug_track]
;     mov cl, [debug_sector]
;     mov dl, [debug_dev]

;     ret

; debug_msg_logical db ' < logical sector', 13, 10, 0
; debug_msg_head    db ' < head', 13, 10, 0
; debug_msg_track   db ' < track', 13, 10, 0
; debug_msg_sector  db ' < sector', 13, 10, 0
; debug_msg_device  db ' < device', 13, 10, 0
; debug_head        db 0
; debug_track       db 0
; debug_sector      db 0
; debug_dev         db 0

msg_ok            db 'ok', 13, 10, 0
err_floppy        db 'floppy error', 13, 10, 0
err_kernel        db 'kernel not found', 13, 10, 0
kernel_file       db 'KERNEL  BIN'
hex_dig           db '0123456789ABCDEF'
bootdev           db 0
cluster           dw 0

times 510-($-$$) db 0 ; fill sector with zeros
dw 0xaa55             ; boot signature

buffer: