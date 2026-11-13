; Menyiapkan segmen data dan stack sebelum instruksi CALL pertama.
initialize_segments:
    mov ax, FIRMWARE_SEGMENT
    mov ds, ax
    mov es, ax

    mov ax, STACK_SEGMENT
    mov ss, ax
    mov sp, STACK_TOP

    call firmware_main
    jmp halt_loop
