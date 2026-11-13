; Firmware memanggil compiler Phase 01 setelah stack siap.
firmware_main:
    call compiler_main
    ret

; Menghentikan CPU setelah compiler selesai.
halt_loop:
    hlt
    jmp halt_loop
