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
    jmp $

times 510-($-$$) db 0 ; fill sector with zeros
dw 0xaa55             ; boot signature