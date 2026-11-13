@echo off
setlocal
cd /d "%~dp0.."
where gdb >nul 2>nul
if errorlevel 1 (
    echo Galat: GDB tidak ditemukan pada PATH.
    exit /b 1
)
where qemu-system-i386 >nul 2>nul
if errorlevel 1 (
    echo Galat: QEMU tidak ditemukan pada PATH.
    exit /b 1
)
where python >nul 2>nul
if errorlevel 1 (
    echo Galat: Python tidak ditemukan pada PATH.
    exit /b 1
)
python -c "import sys; raise SystemExit(sys.version_info.major < 3)"
if errorlevel 1 (
    echo Galat: Python 3 diperlukan.
    exit /b 1
)
call scripts\build.bat
if errorlevel 1 exit /b 1
python tests\run_gdb_test.py
if errorlevel 1 exit /b 1
endlocal
