@echo off

mkdir bin\

cd source

echo * Building bootload *
nasm bootload.asm -f bin -o ..\bin\bootload.bin
if %errorlevel% neq 0 goto fail

echo * Building kernel *
nasm kernel.asm -f bin -o ..\bin\kernel.bin
if %errorlevel% neq 0 goto fail

cd ..

del bin\felipos.flp

echo * Adding bootload to disk image *
copy bin\bootload.bin bin\felipos.flp

echo * Mounting image *
imdisk -a -f bin\felipos.flp -s 1440K -m B: 

echo * Adding dummy kernel.bin *
copy bin\kernel.bin b:\

echo * Add some test cases for DIR *
echo hello, world! > b:\hello.txt
copy bin\kernel.bin b:\delete.me
copy ..\..\mikeos-4.6.1\programs\*.* b:\
dir b:

echo * Dismounting image *
imdisk -D -m B:

echo * Booting *
@"C:\Program Files\qemu\qemu-system-i386w.exe" -fda bin\felipos.flp -boot order=a
goto end

:fail
echo Failed to build

:end
