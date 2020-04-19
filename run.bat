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
copy nul b:\deleted.txt
del b:\deleted.txt
mkdir b:\dir
copy nul b:\file.a
copy nul b:\file.bb
copy nul b:\file.ccc
copy nul b:\a.001
copy nul b:\bbbb.004
copy nul b:\ccccccc.007
copy nul b:\dddddddd.008
dir b:

echo * Dismounting image *
imdisk -D -m B:

echo * Booting *
@"C:\Program Files\qemu\qemu-system-i386w.exe" -fda bin\felipos.flp -boot order=a
goto end

:fail
echo Failed to build

:end
