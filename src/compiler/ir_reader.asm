; Mengatur pointer IR dan batas awal yang mencakup header serta payload.
; Masukan: DS menunjuk work memory.
; Keluaran: SI=program_ir, remaining=ukuran tabel IR.
; Register berubah: SI.
; Kesalahan: tidak ada.
ir_init:
    mov si, program_ir
    mov word [ds:WORK_IR_REMAINING], program_ir_end - program_ir
    mov word [ds:WORK_IR_TOTAL_LENGTH], program_ir_end - program_ir
    mov word [ds:WORK_DECODED_COUNT], 0
    mov byte [ds:WORK_IR_END_SEEN], 0
    ret

; Memastikan jumlah byte yang diminta masih tersedia.
; Masukan: CX adalah jumlah byte minimum.
; Keluaran: CF=0 jika cukup, CF=1 dan status error jika tidak cukup.
; Register berubah: AX pada error dan flag; CX dipertahankan.
; Kesalahan: kekurangan data mencatat ERR_UNEXPECTED_EOF.
ir_check_remaining:
    cmp word [ds:WORK_IR_REMAINING], cx
    jae .available
    mov ax, ERR_UNEXPECTED_EOF
    call compiler_record_error
    ret
.available:
    clc
    ret

; Membaca satu byte dari CS:SI dan mengurangi sisa payload.
; Masukan: SI menunjuk byte berikutnya.
; Keluaran: AL=byte, CF=0; saat gagal CF=1.
; Register berubah: SI, AX, CX, flag.
; Kesalahan: remaining nol mencatat ERR_UNEXPECTED_EOF tanpa mengubah SI.
ir_read_u8:
    mov cx, 1
    call ir_check_remaining
    jc .failed
    mov al, [cs:si]
    inc si
    dec word [ds:WORK_IR_REMAINING]
    clc
    ret
.failed:
    stc
    ret

; Membaca word little-endian dari CS:SI secara atomik.
; Masukan: SI menunjuk byte terendah, remaining minimal dua.
; Keluaran: AX=word, CF=0; saat gagal CF=1.
; Register berubah: SI, AX, CX, flag.
; Kesalahan: remaining kurang dari dua mencatat ERR_UNEXPECTED_EOF tanpa membaca.
ir_read_u16:
    mov cx, 2
    call ir_check_remaining
    jc .failed
    mov ax, [cs:si]
    add si, 2
    sub word [ds:WORK_IR_REMAINING], 2
    clc
    ret
.failed:
    stc
    ret

; Memeriksa magic, versi, dan panjang header sebelum dispatch payload.
; Masukan: SI dan remaining disiapkan oleh ir_init.
; Keluaran: SI menunjuk payload, remaining sama dengan panjang payload.
; Register berubah: AX, CX, SI, flag.
; Kesalahan: magic, versi, panjang, atau header terpotong mencatat kode terkait.
ir_validate_header:
    call ir_read_u8
    jc .failed
    cmp al, 'I'
    jne .invalid_magic
    call ir_read_u8
    jc .failed
    cmp al, 'R'
    jne .invalid_magic
    call ir_read_u8
    jc .failed
    cmp al, '1'
    jne .invalid_magic
    call ir_read_u8
    jc .failed
    cmp al, '6'
    jne .invalid_magic

    call ir_read_u8
    jc .failed
    cmp al, IR_VERSION
    jne .invalid_version
    mov byte [ds:WORK_IR_VERSION], al

    call ir_read_u16
    jc .failed
    mov word [ds:WORK_IR_PAYLOAD_LENGTH], ax
    cmp ax, word [ds:WORK_IR_REMAINING]
    jne .invalid_length
    clc
    ret
.invalid_magic:
    mov ax, ERR_INVALID_MAGIC
    call compiler_record_error
    ret
.invalid_version:
    mov ax, ERR_INVALID_VERSION
    call compiler_record_error
    ret
.invalid_length:
    mov ax, ERR_INVALID_LENGTH
    call compiler_record_error
    ret
.failed:
    stc
    ret
