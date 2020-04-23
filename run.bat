@echo off

call build.bat
if %errorlevel% neq 0 goto end

"C:\Program Files\qemu\qemu-system-i386w.exe" -rtc base=localtime -fda bin\felipos.flp -boot order=a

:end
