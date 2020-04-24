# FelipOS

A simple OS programmed in x86 Assembly real mode (16-bit) inspired by [MikeOS](http://mikeos.sourceforge.net/).

## Requirements

- Netwide Assembler (NASM)
- ImDisk tools
- QEMU, Bochs or similar for emulation
- A 1.44MB floppy disk or USB key for real hardware

## Features

- A bootloader that can search for a kernel file on the root directory, load and execute it.
- A basic kernel with a command line (shell), some builtin commands and a "graphical" menu.
- Can execute external binary programs.
- Code is a complete rewrite and tries to keep compatibility with MikeOS system calls/interface.
    - Runs *most* original binary programs for MikeOS. \o/
- ~~(Probably)~~  Lots of bugs!

## Notes

- Some random notes taken when studying the source for MikeOS.

## Testing

Install requirements and execute:

```
run.bat
```

> *Note:* Edit executable paths if needed.

For use on real PC hardware, a floppy image can be written to a physical 1.44 MB floppy disk or directly to an USB drive (some BIOSes can emulate a floppy disk on boot).

