@echo off
setlocal
cd /d "%~dp0.."
where qemu-system-i386 >nul 2>nul
if errorlevel 1 (
    echo Galat: QEMU tidak ditemukan pada PATH.
    exit /b 1
)
if not exist build\custom_rom.bin (
    echo Galat: build\custom_rom.bin belum ada; jalankan scripts\build.bat.
    exit /b 1
)
qemu-system-i386 -machine pc -m 16M -bios build\custom_rom.bin -display none -serial none -monitor none -no-reboot -no-shutdown -S -s
