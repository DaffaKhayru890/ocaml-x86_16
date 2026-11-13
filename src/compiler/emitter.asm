; Menyetel buffer keluaran untuk uji mandiri emitter.
; Masukan: ES menunjuk OUTPUT_SEGMENT.
; Keluaran: DI dan WORK_EMIT_LENGTH bernilai nol.
; Register berubah: DI.
; Kesalahan: tidak ada.
emitter_init:
    xor di, di
    mov word [ds:WORK_EMIT_LENGTH], 0
    ret

; Menulis AL ke ES:DI jika masih ada ruang.
; Masukan: AL adalah byte yang akan ditulis.
; Keluaran: byte tersimpan, DI dan panjang bertambah; CF=0.
; Register berubah: DI, flag; AX/BX/CX/DX dipertahankan.
; Kesalahan: kapasitas penuh mencatat ERR_OUTPUT_OVERFLOW, DI tidak berubah, CF=1.
emit8:
    cmp di, OUTPUT_CAPACITY
    jae .overflow
    mov [es:di], al
    inc di
    mov word [ds:WORK_EMIT_LENGTH], di
    clc
    ret
.overflow:
    push ax
    mov ax, ERR_OUTPUT_OVERFLOW
    call compiler_record_error
    pop ax
    ret

; Menulis AX dalam urutan little-endian hanya jika dua byte tersedia.
; Masukan: AX adalah word yang akan ditulis.
; Keluaran: dua byte tersimpan, DI dan panjang bertambah dua; CF=0.
; Register berubah: DI, flag; AX/BX/CX/DX dipertahankan.
; Kesalahan: ruang kurang dari dua byte mencatat overflow tanpa penulisan parsial.
emit16:
    cmp di, OUTPUT_CAPACITY - 2
    ja .overflow
    mov [es:di], ax
    add di, 2
    mov word [ds:WORK_EMIT_LENGTH], di
    clc
    ret
.overflow:
    push ax
    mov ax, ERR_OUTPUT_OVERFLOW
    call compiler_record_error
    pop ax
    ret

