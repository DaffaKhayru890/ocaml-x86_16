; Menghasilkan immediate Boolean yang disetujui ke AX pada kode sasaran.
; Masukan: AX harus berisi BOOLEAN_FALSE_VALUE atau BOOLEAN_TRUE_VALUE.
; Keluaran: instruksi MOV AX,imm16 ditambahkan; CF=0 jika berhasil.
; Register berubah: BX, DI, flag; AX dapat berubah oleh emitter.
; Kesalahan: nilai selain nol atau satu mencatat ERR_BOOLEAN_GENERATION_FAILED.
; Alur: validasi nilai, simpan sementara, lalu kirim opcode dan immediate.
codegen_emit_boolean_value:
    cmp ax, BOOLEAN_FALSE_VALUE
    je .valid
    cmp ax, BOOLEAN_TRUE_VALUE
    je .valid
    mov ax, ERR_BOOLEAN_GENERATION_FAILED
    call compiler_record_error
    ret
.valid:
    mov bx, ax
    CODEGEN_EMIT8 MC_MOV_AX_IMM16
    CODEGEN_EMIT16 bx
    clc
    ret
