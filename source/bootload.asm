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
VolumeLabel         db 'FeliPOS    '
FileSystem          db 'FAT12   '

start:
    cli
    mov ax, 0x07c0
    mov ds, ax       ; data segment 07c0:xxxx
    add ax, 544      ; (8192 for buffer + 512 for boot sector) / 16 bytes per paragraph
    mov ss, ax       ; set stack segment
    mov sp, 4096     ; stack pointer start at end of 4k stack
    sti

    mov si, msg_ok
    call print_string
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

; wait keypress and reboot
reset:
    mov ax, 0
    int 0x16
    mov ax, 0
    int 0x19
    ret

msg_ok db 'boot ok', 13, 10, 0

times 510-($-$$) db 0 ; fill sector with zeros
dw 0xaa55             ; boot signature