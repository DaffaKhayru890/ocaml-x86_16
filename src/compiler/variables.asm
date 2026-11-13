; Genera pembacaan slot ke AX lalu mendorong nilainya ke stack runtime.
; Masukan: WORK_DECODED_OPERAND berisi indeks slot tervalidasi.
; Keluaran: empat byte MOV AX,[disp16]/PUSH AX ditambahkan.
; Register berubah: AX, BX, DI, flag; register lain dipertahankan.
; Kesalahan: slot invalid, belum diinisialisasi, atau emitter overflow.
; Alur: hitung offset, emit A1 dengan offset little-endian, lalu PUSH AX.
codegen_load_local:
    mov al, [ds:WORK_DECODED_OPERAND]
    call check_local_initialized
    jc .failed
    mov al, [ds:WORK_DECODED_OPERAND]
    call calculate_local_address
    jc .failed
    mov bx, ax
    CODEGEN_EMIT8 MC_MOV_AX_MOFFS
    CODEGEN_EMIT16 bx
    CODEGEN_EMIT8 MC_PUSH_AX
    clc
    ret
.failed:
    stc
    ret

; Genera pengambilan nilai stack dan penyimpanan ke slot lokal.
; Masukan: WORK_DECODED_OPERAND berisi indeks slot dan stack berisi nilai.
; Keluaran: empat byte POP AX/MOV [disp16],AX ditambahkan.
; Register berubah: AX, BX, DI, flag; register lain dipertahankan.
; Kesalahan: slot invalid, rentang lokal tidak valid, atau emitter overflow.
; Alur: hitung offset, emit POP AX, lalu emit A3 dengan offset little-endian.
codegen_store_local:
    mov al, [ds:WORK_DECODED_OPERAND]
    call calculate_local_address
    jc .failed
    mov bx, ax
    CODEGEN_EMIT8 MC_POP_AX
    CODEGEN_EMIT8 MC_MOV_MOFFS_AX
    CODEGEN_EMIT16 bx
    clc
    ret
.failed:
    stc
    ret
