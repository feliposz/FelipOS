# FelipOS

A simple OS programmed in x86 Assembly real mode (16-bit) inspired by [MikeOS](http://mikeos.sourceforge.net/).

## Requirements

- Netwide Assembler (NASM)
- ImDisk tools
- QEMU

## Features

- A simple bootloader
- A basic kernel with a command line (shell) and a few commands
- Code is a complete rewrite and tries to keep compatibility with MikeOS system calls/interface
- (Probably) Lots of bugs!

## Notes

- Some random notes written while studying the source for MikeOS.

## Testing

Install requirements and execute:

```
run.bat
```

> *Note:* Edit executable paths if needed.

For use on real PC hardware, a floppy image can be written to a physical 1.44 MB floppy disk or directly to an USB drive (some BIOSes can emulate a floppy disk on boot).

