; Menyiapkan emission dari tabel IR dan state hasil analisis CFG.
; Masukan: tabel instruksi sudah tervalidasi dan prologue siap ditulis.
; Keluaran: emitter siap; CF=0.
; Register berubah: AX, BX, CX, DX, SI, DI, flag; DS/ES tetap.
; Kesalahan: tidak ada pada inisialisasi; emitter disiapkan untuk emission.
; Alur: atur state codegen dan buffer tanpa menghapus tabel analisis.
codegen_init:
    mov word [ds:WORK_STACK_DEPTH], 0
    mov word [ds:WORK_STACK_ERROR], 0
    call clear_local_init_bitmap
    mov byte [ds:WORK_CODEGEN_HALT_EMITTED], 0
    mov byte [ds:WORK_CODEGEN_PROLOGUE_EMITTED], 0
    mov word [ds:WORK_STATUS], STATUS_RUNNING
    mov word [ds:WORK_ERROR_CODE], ERR_SUCCESS
    mov word [ds:WORK_RELOCATION_COUNT], 0
    mov word [ds:WORK_RELOCATION_APPLIED_COUNT], 0
    call emitter_init
    clc
    ret

; Memilih generator berdasarkan opcode dari record instruksi aktif.
; Masukan: WORK_CURRENT_OPCODE dan operand telah disalin dari tabel.
; Keluaran: encoding instruksi ditambahkan; CF menunjukkan keberhasilan.
; Register berubah: AX, BX, CX, DX, DI, flag; DS/ES tetap.
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
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JMP
    je .branch
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JZ
    je .branch
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JNZ
    je .branch
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_HALT
    jne .unsupported
    jmp codegen_halt
.comparison:
    jmp codegen_compare
.branch:
    jmp codegen_jump
.unsupported:
    mov ax, ERR_UNSUPPORTED_OPCODE
    call compiler_record_error
    ret

; Menghasilkan seluruh record instruksi melalui generator kontrol alur.
; Masukan: tabel instruksi telah tervalidasi dan prologue telah ditulis.
; Keluaran: seluruh kode di-emits, relocation ditambal, dan hasil diverifikasi.
; Register berubah: AX, BX, CX, SI, DI, flag.
; Kesalahan: kegagalan dispatch, stack, buffer, atau hasil mencatat kode kesalahan.
; Alur: gunakan tabel instruksi, set alamat label, emit, lalu patch displacement.
codegen_generate_program:
    jmp control_flow_generate_code

; Memastikan status prologue/HALT, batas buffer, panjang, dan byte prologue sesuai.
; Masukan: ES menunjuk kode hasil; DI dan WORK_EMIT_LENGTH adalah panjang.
; Keluaran: CF=0 jika buffer berisi bentuk kode yang diharapkan.
; Register berubah: AX, BX, flag; register lain dipertahankan.
; Kesalahan: bentuk kode tidak valid mencatat ERR_RUNTIME_INVALID.
; Alur: cek state, panjang, kapasitas, dan encoding prologue 14 byte.
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
    call machine_code_validate_generated_program
    ret
.invalid:
    mov ax, ERR_RUNTIME_INVALID
    call compiler_record_error
    ret
