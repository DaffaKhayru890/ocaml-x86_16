@echo off
setlocal
cd /d "%~dp0.."

where nasm >nul 2>nul
if errorlevel 1 (
    echo Galat: NASM tidak ditemukan pada PATH.
    exit /b 1
)

if not exist build mkdir build
nasm -f bin -I . -l build\custom_rom.lst src\firmware.asm -o build\custom_rom.bin
if errorlevel 1 exit /b 1

powershell -NoProfile -Command "$l=Get-Content 'build/custom_rom.lst' -Raw; if($l -match '(?m)^\s*\d+\s+[0-9A-F]{8}\s+0F8[0-9A-F]'){Write-Error 'Conditional jump tidak kompatibel dengan 8086'; exit 1}; $b=[IO.File]::ReadAllBytes('build/custom_rom.bin'); if($b.Length -ne 65536){Write-Error ('Ukuran ROM salah: '+$b.Length); exit 1}; $v=($b[65520..65524] -join ','); if($v -ne '234,0,0,0,240'){Write-Error ('Reset vector salah: '+$v); exit 1}; Write-Output 'ROM berhasil dibangun: build/custom_rom.bin (65536 byte)'; Write-Output ('Reset vector: '+(($b[65520..65524] | ForEach-Object {$_.ToString('X2')}) -join ' '))"
if errorlevel 1 exit /b 1

endlocal
