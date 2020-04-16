@echo off

echo * Building bootload *
nasm source\bootload.asm -f bin -o bin\bootload.bin
if %errorlevel% neq 0 goto fail

del bin\felipos.flp

echo * Adding bootload to disk image *
copy bin\bootload.bin bin\felipos.flp

echo * Mounting image *
imdisk -a -f bin\felipos.flp -s 1440K -m B: 

echo * Adding dummy kernel.bin *
rem echo KERNEL > b:\kernel.bin
copy C:\projetos\felipo\mikeos-4.6.1\source\kernel.bin b:\kernel.bin

dir b:

echo * Dismounting image *
imdisk -D -m B:

echo * Booting *
@"C:\Program Files\qemu\qemu-system-i386w.exe" -fda bin\felipos.flp -boot order=a
goto end

:fail
echo Failed to build

:end
