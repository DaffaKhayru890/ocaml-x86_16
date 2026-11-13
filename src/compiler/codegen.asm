; Menyiapkan lintasan kedua, mengulang IR, dan menghasilkan kode yang dapat dijalankan.
; Masukan: lintasan pertama dan uji mandiri emitter telah berhasil.
; Keluaran: buffer keluaran berisi kode valid; CF=0 jika lintasan kedua berhasil.
; Register berubah: AX, BX, CX, DX, SI, DI, flag; DS/ES tetap.
; Kesalahan: pembaca, stack, dispatcher, atau emitter gagal dan menghentikan lintasan.
; Alur: atur ulang IR/stack/buffer, dispatch ulang, tulis kode, lalu validasi hasil.
codegen_init:
    mov word [ds:WORK_STACK_DEPTH], 0
    mov word [ds:WORK_MAX_STACK_DEPTH], 0
    mov word [ds:WORK_STACK_ERROR], 0
    call clear_local_init_bitmap
    mov byte [ds:WORK_IR_HALT_SEEN], 0
    mov byte [ds:WORK_CODEGEN_HALT_EMITTED], 0
    mov byte [ds:WORK_CODEGEN_PROLOGUE_EMITTED], 0
    mov word [ds:WORK_STATUS], STATUS_RUNNING
    mov word [ds:WORK_ERROR_CODE], ERR_SUCCESS
    call ir_init
    call ir_validate_header
    jc .failed
    call emitter_init
    clc
    ret
.failed:
    stc
    ret

; Memilih generator berdasarkan opcode tervalidasi dari dispatcher.
; Masukan: WORK_CURRENT_OPCODE dan operand telah diisi pembaca IR.
; Keluaran: encoding instruksi ditambahkan; CF menunjukkan keberhasilan.
; Register berubah: AX, DI, flag; register lain dipertahankan.
; Kesalahan: opcode tanpa generator mencatat ERR_UNSUPPORTED_OPCODE.
; Alur: cocokkan opcode yang didukung lalu panggil generator khusus.
codegen_dispatch:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_ICONST
    jne .not_iconst
    jmp codegen_iconst
.not_iconst:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LOAD_LOCAL
    jne .not_load_local
    jmp codegen_load_local
.not_load_local:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_STORE_LOCAL
    jne .not_store_local
    jmp codegen_store_local
.not_store_local:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_ADD
    jne .not_add
    jmp codegen_add
.not_add:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_SUB
    jne .not_sub
    jmp codegen_sub
.not_sub:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_MUL
    jne .not_mul
    jmp codegen_mul
.not_mul:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_NEG
    jne .not_neg
    jmp codegen_neg
.not_neg:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_EQ
    je .comparison
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_NE
    je .comparison
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LT
    je .comparison
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_GT
    je .comparison
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_HALT
    jne .unsupported
    jmp codegen_halt
.comparison:
    jmp codegen_compare
.unsupported:
    mov ax, ERR_UNSUPPORTED_OPCODE
    call compiler_record_error
    ret

; Menjalankan lintasan kedua dari payload sampai IR_END.
; Masukan: IR telah diinisialisasi, header tervalidasi, prologue telah ditulis.
; Keluaran: seluruh instruksi didorong ke keluaran dan hasil diverifikasi.
; Register berubah: AX, BX, CX, SI, DI, flag.
; Kesalahan: kegagalan dispatch, stack, buffer, atau hasil mencatat kode kesalahan.
; Alur: baca satu instruksi, validasi efek stack, tulis kode, lalu ulangi.
codegen_generate_program:
.next_instruction:
    call ir_dispatch_opcode
    jc .failed
    cmp byte [ds:WORK_IR_END_SEEN], 1
    je .end
    call codegen_validate_stack
    jc .failed
    call codegen_dispatch
    jc .failed
    jmp .next_instruction
.end:
    call codegen_validate_end
    jc .failed
    call codegen_validate_generated_code
    ret
.failed:
    stc
    ret

; Memastikan batas program, terminator, dan byte prologue/halt sesuai.
; Masukan: ES menunjuk kode hasil; DI dan WORK_EMIT_LENGTH adalah panjang.
; Keluaran: CF=0 jika buffer berisi bentuk kode yang diharapkan.
; Register berubah: AX, BX, flag; register lain dipertahankan.
; Kesalahan: bentuk kode tidak valid mencatat ERR_RUNTIME_INVALID.
; Alur: cek state, panjang, prologue 14 byte, dan suffix halt tujuh byte.
codegen_validate_generated_code:
    cmp byte [ds:WORK_CODEGEN_PROLOGUE_EMITTED], 1
    je .prologue_flag_valid
    jmp .invalid
.prologue_flag_valid:
    cmp byte [ds:WORK_CODEGEN_HALT_EMITTED], 1
    je .halt_flag_valid
    jmp .invalid
.halt_flag_valid:
    cmp byte [ds:WORK_IR_END_SEEN], 1
    je .end_flag_valid
    jmp .invalid
.end_flag_valid:
    cmp word [ds:WORK_STACK_DEPTH], 0
    je .stack_valid
    jmp .invalid
.stack_valid:
    cmp di, OUTPUT_CAPACITY
    jbe .capacity_valid
    jmp .invalid
.capacity_valid:
    cmp di, 21
    jae .minimum_valid
    jmp .invalid
.minimum_valid:
    cmp di, word [ds:WORK_EMIT_LENGTH]
    je .length_valid
    jmp .invalid
.length_valid:
    cmp word [es:0], 0xB8FA
    je .prologue_0_valid
    jmp .invalid
.prologue_0_valid:
    cmp word [es:2], 0x3000
    je .prologue_1_valid
    jmp .invalid
.prologue_1_valid:
    cmp word [es:4], 0xD88E
    je .prologue_2_valid
    jmp .invalid
.prologue_2_valid:
    cmp word [es:6], 0x00B8
    je .prologue_3_valid
    jmp .invalid
.prologue_3_valid:
    cmp word [es:8], 0x8E40
    je .prologue_4_valid
    jmp .invalid
.prologue_4_valid:
    cmp word [es:10], 0xBCD0
    je .prologue_5_valid
    jmp .invalid
.prologue_5_valid:
    cmp word [es:12], 0xFFFE
    je .prologue_valid
    jmp .invalid
.prologue_valid:
    mov bx, di
    sub bx, 7
    cmp word [es:bx], 0xA358
    je .halt_0_valid
    jmp .invalid
.halt_0_valid:
    add bx, 2
    cmp word [es:bx], 0x0000
    je .halt_1_valid
    jmp .invalid
.halt_1_valid:
    add bx, 2
    cmp word [es:bx], 0xEBF4
    je .halt_2_valid
    jmp .invalid
.halt_2_valid:
    add bx, 2
    cmp byte [es:bx], MC_JMP_SHORT_BACK_3
    je .valid
    jmp .invalid
.valid:
    clc
    ret
.invalid:
    mov ax, ERR_RUNTIME_INVALID
    call compiler_record_error
    ret
