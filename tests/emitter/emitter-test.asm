; Menulis urutan byte tetap untuk menguji emit8 dan emit16 tanpa IR.
; Masukan: DS menunjuk memori kerja dan ES menunjuk buffer keluaran.
; Keluaran: B8 34 12 50 58 di ES:0000; CF=0 jika tes selesai.
; Register berubah: AX, DI, flag.
; Kesalahan: kegagalan penulisan atau verifikasi mencatat ERR_EMITTER_TEST_FAILED.
emitter_self_test:
    call emitter_init
    mov al, 0xB8
    call emit8
    jnc .first_byte_written
    jmp .failed
.first_byte_written:
    mov ax, 0x1234
    call emit16
    jnc .word_written
    jmp .failed
.word_written:
    mov al, 0x50
    call emit8
    jnc .third_byte_written
    jmp .failed
.third_byte_written:
    mov al, 0x58
    call emit8
    jnc .fourth_byte_written
    jmp .failed
.fourth_byte_written:
    call emitter_verify_test
    jnc .bytes_verified
    jmp .failed
.bytes_verified:
    call emitter_overflow_test
    ret
.failed:
    stc
    ret

; Membandingkan hasil emitter dengan lima byte yang diharapkan.
; Masukan: ES:0000 berisi hasil uji mandiri dan WORK_EMIT_LENGTH bernilai lima.
; Keluaran: CF=0 jika seluruh byte sama.
; Register berubah: AX, flag.
; Kesalahan: ketidakcocokan mencatat ERR_EMITTER_TEST_FAILED.
emitter_verify_test:
    cmp word [ds:WORK_EMIT_LENGTH], 5
    je .length_valid
    jmp .failed
.length_valid:
    cmp byte [es:0], 0xB8
    je .byte_0_valid
    jmp .failed
.byte_0_valid:
    cmp byte [es:1], 0x34
    je .byte_1_valid
    jmp .failed
.byte_1_valid:
    cmp byte [es:2], 0x12
    je .byte_2_valid
    jmp .failed
.byte_2_valid:
    cmp byte [es:3], 0x50
    je .byte_3_valid
    jmp .failed
.byte_3_valid:
    cmp byte [es:4], 0x58
    je .byte_4_valid
    jmp .failed
.byte_4_valid:
    clc
    ret
.failed:
    mov ax, ERR_EMITTER_TEST_FAILED
    call compiler_record_error
    ret

; Menguji byte terakhir buffer, satu byte berlebih, dan emit16 yang hanya muat satu byte.
; Masukan: emitter_self_test telah mengisi dan memverifikasi lima byte awal.
; Keluaran: lima byte awal dan panjangnya dipertahankan; CF=0 jika tes lulus.
; Register berubah: AX, DI, flag.
; Kesalahan: kondisi uji yang gagal mencatat ERR_EMITTER_TEST_FAILED.
emitter_overflow_test:
    mov di, OUTPUT_CAPACITY - 1
    mov al, 0xA5
    call emit8
    jnc .last_byte_written
    jmp .failed
.last_byte_written:
    cmp di, OUTPUT_CAPACITY
    je .at_capacity
    jmp .failed
.at_capacity:
    cmp byte [es:OUTPUT_CAPACITY - 1], 0xA5
    je .boundary_byte_valid
    jmp .failed
.boundary_byte_valid:

    mov byte [es:OUTPUT_CAPACITY], 0xC3
    mov al, 0x7E
    call emit8
    jc .byte_overflow
    jmp .failed
.byte_overflow:
    cmp word [ds:WORK_STATUS], STATUS_ERROR
    je .byte_status_valid
    jmp .failed
.byte_status_valid:
    cmp word [ds:WORK_ERROR_CODE], ERR_OUTPUT_OVERFLOW
    je .byte_error_valid
    jmp .failed
.byte_error_valid:
    cmp byte [es:OUTPUT_CAPACITY], 0xC3
    je .byte_guard_valid
    jmp .failed
.byte_guard_valid:
    mov word [ds:WORK_STATUS], STATUS_RUNNING
    mov word [ds:WORK_ERROR_CODE], ERR_SUCCESS

    mov di, OUTPUT_CAPACITY - 1
    mov byte [es:OUTPUT_CAPACITY - 1], 0x5A
    mov byte [es:OUTPUT_CAPACITY], 0xC3
    mov ax, 0x1234
    call emit16
    jc .word_overflow
    jmp .failed
.word_overflow:
    cmp di, OUTPUT_CAPACITY - 1
    je .word_pointer_valid
    jmp .failed
.word_pointer_valid:
    cmp word [ds:WORK_STATUS], STATUS_ERROR
    je .word_status_valid
    jmp .failed
.word_status_valid:
    cmp word [ds:WORK_ERROR_CODE], ERR_OUTPUT_OVERFLOW
    je .word_error_valid
    jmp .failed
.word_error_valid:
    cmp byte [es:OUTPUT_CAPACITY - 1], 0x5A
    je .word_low_untouched
    jmp .failed
.word_low_untouched:
    cmp byte [es:OUTPUT_CAPACITY], 0xC3
    je .word_guard_valid
    jmp .failed
.word_guard_valid:

    mov word [ds:WORK_STATUS], STATUS_RUNNING
    mov word [ds:WORK_ERROR_CODE], ERR_SUCCESS
    mov di, 5
    mov word [ds:WORK_EMIT_LENGTH], 5
    clc
    ret
.failed:
    mov ax, ERR_EMITTER_TEST_FAILED
    call compiler_record_error
    ret
