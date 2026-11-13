; Program utama Phase 00 kembali ke pemanggil untuk menguji CALL dan RET.
firmware_main:
    ret

; HLT menunggu interrupt; CLI mencegah IRQ biasa membangunkan CPU.
halt_loop:
    hlt
    jmp halt_loop
