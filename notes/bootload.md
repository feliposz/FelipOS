# bootload.asm

## Disk description table for a valid floppy

FAT12 table starting at byte 4 after a short jump (2 bytes) and NOP (1 byte for alignment)

Total size = 58 bytes

Field            | Type | Size | Data          | Description
-----------------|------|------|---------------|-------------------
OEMLabel         |  db  |   8  |"MIKEBOOT"     |Disk label
BytesPerSector   |  dw  |   2  |512            |Bytes per sector
SectorsPerCluster|  db  |   1  |1              |Sectors per cluster
ReservedForBoot  |  dw  |   2  |1              |Reserved sectors for boot record
NumberOfFats     |  db  |   1  |2              |Number of copies of the FAT
RootDirEntries   |  dw  |   2  |224            |Number of entries in root dir (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors   |  dw  |   2  |2880           |Number of logical sectors
MediumByte       |  db  |   1  |0F0h           |Medium descriptor byte
SectorsPerFat    |  dw  |   2  |9              |Sectors per FAT
SectorsPerTrack  |  dw  |   2  |18             |Sectors per track (36/cylinder)
Sides            |  dw  |   2  |2              |Number of sides/heads
HiddenSectors    |  dd  |   4  |0              |Number of hidden sectors
LargeSectors     |  dd  |   4  |0              |Number of LBA sectors
DriveNo          |  dw  |   2  |0              |Drive No: 0
Signature        |  db  |   1  |41             |Drive signature: 41 for floppy
VolumeID         |  dd  |   4  |00000000h      |Volume ID: any number
VolumeLabel      |  db  |  10  |"MIKEOS     "  | Volume Label: any 11 chars
FileSystem       |  db  |   8  |"FAT12   "     |File system type: don't change!

Stack:
- Set stack segment to 8k above loader address (07c0) considering loader size(512 bytes) and stack pointer to 4k.
- Stop interrupts while setting stack.
- Set data segment to same as loader.

Check device number:
- Check DL and save boot device
- Get drive parameters (AH=8, int 0x13)
    - SectorsPerTrack
    - Sides

Routine to calculate Head/Track/Sector from Logical sector:
- Input:
    - AX = logical sector
- Output
    - Sector (CL) = Logical Sector % SectorsPerTrack + 1
    - Head (DH) = (Logical Sector / SectorsPerTrack) / Sides
    - Track (DH) = (Logical Sector / SectorsPerTrack) % Sides
    - Set correct device (saved above)

Read root directory
- Logical sector 19
- Point ES:BX to buffer
- Load 14 sectors (AH=function 2, AL=14 sectors)
- On carry (success) go to search dir, otherwise reset floppy and try again

Search dir
- Point ES:DI to buffer
- Note 14 sectors * 512 bytes / 32 bytes per entry = 224
- Repeat "RootDirEntries" (224) times
    - Compare to kernel filename name
    - If found, proceed to load kernel
    - Else, skip 32 bytes (size of each entry)
    - Decrement counter
- Not found? Error + reboot

Load kernel file
- Directory entry at offset 26 (11 for filename + 15 bytes) contains a word pointing to first cluster (sector)
- Set cluster
- Read 9 sectors of 1st cluster (FAT)
- On error
    - Reset floppy and try again
    - Reboot if can't reset
- Point ES:BX to 2000:0000 where kernel will be loaded
- Read floppy (AH=2 read sector, AL=1 sector)
- Loop:
    - Load file cluster (cluster + 31???)
    - Point to ES:BX to next block after already loaded 2000:pointer
    - If error, reset and retry
    - Else, calculate next cluster considering 12 bits per cluster entry (need to do some math and masking to get proper values)
    - If end of file marker 0xff8, exit loop
    - Else, advance pointer 512 bytes and read one more sector
- Pass boot device to kernel (on DL)
- Jump to loaded kernel on 2000:0000

Reset floppy
- Set DL to bootdevice
- Do reset (AX=0, int 0x13) 

Reboot
- Wait keystroke (AX=0, int 0x16)
- Reboot (AX=0, int 0x19)

Print string
- Pointed by SI
- Use (AH=0x0e, int 0x10) while character <> 0

Disk buffer
- Placed right after MBR code
- 8k size (stack starts after)
