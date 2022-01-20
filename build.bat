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

echo * Building programs *

for %%i in (*.asm) do nasm -O0 -f bin %%i
for %%i in (*.bin) do del %%i
for %%i in (*.) do ren %%i %%i.bin

cd ..

del bin\felipos.flp

echo * Adding bootload to disk image *
copy bin\bootload.bin bin\felipos.flp

echo * Mounting image *
imdisk -a -f bin\felipos.flp -s 1440K -m B: 

echo * Copying kernel.bin *
copy bin\kernel.bin b:\

echo * Copying programs *
copy programs\*.bin b:\
echo test > b:\test.txt
copy ..\mikeos\edit.bin b:\
copy ..\mikeos\fileman.bin b:\
copy ..\mikeos\fisher.bin b:\
copy ..\mikeos\forth.bin b:\
copy ..\mikeos\hangman.bin b:\
copy ..\mikeos\keyboard.bin b:\
copy ..\mikeos\monitor.bin b:\
copy ..\mikeos\serial.bin b:\
copy ..\mikeos\viewer.bin b:\
dir b:

echo * Dismounting image *
imdisk -D -m B:

goto end

:fail
echo Failed to build

:end
