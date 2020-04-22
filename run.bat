@echo off

mkdir bin\

cd source

echo * Building bootload *
nasm bootload.asm -f bin -o ..\bin\bootload.bin
if %errorlevel% neq 0 goto fail

echo * Building kernel *
nasm kernel.asm -f bin -o ..\bin\kernel.bin
if %errorlevel% neq 0 goto fail

cd ..\programs

nasm hello.asm -f bin -o hello.bin

cd ..

del bin\felipos.flp

echo * Adding bootload to disk image *
copy bin\bootload.bin bin\felipos.flp

echo * Mounting image *
imdisk -a -f bin\felipos.flp -s 1440K -m B: 

echo * Copying kernel.bin *
copy bin\kernel.bin b:\

echo * Add some test files *
echo hello, world! > b:\hello.txt
copy programs\hello.bin b:\
rem copy ..\..\mikeos-4.6.1\programs\*.* b:\
dir b:

echo * Dismounting image *
imdisk -D -m B:

echo * Booting *
@"C:\Program Files\qemu\qemu-system-i386w.exe" -rtc base=localtime -fda bin\felipos.flp -boot order=a
goto end

:fail
echo Failed to build

:end
