@echo off

echo Building bootload
nasm source/bootload.asm -f bin -o bin/bootload.bin
if %errorlevel% neq 0 goto fail

echo Booting
@"C:\Program Files\qemu\qemu-system-i386w.exe" -fda bin/bootload.bin -boot order=a
goto end

:fail
echo Failed to build

:end
