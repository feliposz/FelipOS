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

    mov si, msg_ok
    call print_string

    mov ax, 0
    call debug_hts

    mov ax, 0x13
    call debug_hts

    mov ax, 0x24e
    call debug_hts

    mov ax, 2879
    call debug_hts

    call reset

    jmp $

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

; wait keypress and reboot
reset:
    mov ax, 0
    int 0x16
    mov ax, 0
    int 0x19
    ret

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
debug_hts:
    push ax
    mov al, ah
    call print_byte
    pop ax
    push ax
    call print_byte
    mov si, debug_msg_logical
    call print_string

    pop ax
    call logical_to_hts
    mov [debug_head], dh
    mov [debug_track], ch
    mov [debug_sector], cl
    mov [debug_dev], dl

    mov al, [debug_head]
    call print_byte
    mov si, debug_msg_head
    call print_string

    mov al, [debug_track]
    call print_byte
    mov si, debug_msg_track
    call print_string

    mov al, [debug_sector]
    call print_byte
    mov si, debug_msg_sector
    call print_string

    mov al, [debug_dev]
    call print_byte
    mov si, debug_msg_device
    call print_string

    ret

debug_msg_logical db ' < logical sector', 13, 10, 0
debug_msg_head    db ' < head', 13, 10, 0
debug_msg_track   db ' < track', 13, 10, 0
debug_msg_sector  db ' < sector', 13, 10, 0
debug_msg_device  db ' < device', 13, 10, 0

debug_head        db 0
debug_track       db 0
debug_sector      db 0
debug_dev         db 0

msg_ok  db 'boot ok', 13, 10, 0
hex_dig db '0123456789ABCDEF'
bootdev db 0

times 510-($-$$) db 0 ; fill sector with zeros
dw 0xaa55             ; boot signature