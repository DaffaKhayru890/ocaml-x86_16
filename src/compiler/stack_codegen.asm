; Memvalidasi efek stack virtual tanpa mengeluarkan kode mesin.
; Masukan: WORK_CURRENT_OPCODE adalah instruksi valid hasil IR dispatcher.
; Keluaran: depth dan maksimum diperbarui; CF=0 jika aturan stack terpenuhi.
; Register berubah: AX, flag; register lain dipertahankan.
; Kesalahan: underflow, overflow, depth HALT salah, opcode tak didukung, atau alur invalid.
codegen_validate_stack:
    cmp byte [ds:WORK_IR_HALT_SEEN], 0
    je .not_after_halt
    mov ax, ERR_INVALID_IR_FLOW
    call codegen_record_stack_error
    ret
.not_after_halt:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_ICONST
    jne .not_iconst
    jmp .push_value
.not_iconst:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_ADD
    je .binary
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_SUB
    je .binary
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_MUL
    je .binary
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_NEG
    je .unary
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_HALT
    jne .unsupported
    jmp .halt

.binary:
    cmp word [ds:WORK_STACK_DEPTH], 2
    jae .binary_ready
    mov ax, ERR_STACK_UNDERFLOW
    call codegen_record_stack_error
    ret
.binary_ready:
    dec word [ds:WORK_STACK_DEPTH]
    clc
    ret

.unary:
    cmp word [ds:WORK_STACK_DEPTH], 1
    jae .valid
    mov ax, ERR_STACK_UNDERFLOW
    call codegen_record_stack_error
    ret

.push_value:
    cmp word [ds:WORK_STACK_DEPTH], VIRTUAL_STACK_MAX_DEPTH
    jb .push_ready
    mov ax, ERR_STACK_OVERFLOW
    call codegen_record_stack_error
    ret
.push_ready:
    inc word [ds:WORK_STACK_DEPTH]
    mov ax, [ds:WORK_STACK_DEPTH]
    cmp ax, [ds:WORK_MAX_STACK_DEPTH]
    jbe .valid
    mov word [ds:WORK_MAX_STACK_DEPTH], ax
    jmp .valid

.halt:
    cmp word [ds:WORK_STACK_DEPTH], 0
    jne .halt_has_value
    mov ax, ERR_EMPTY_PROGRAM
    call codegen_record_stack_error
    ret
.halt_has_value:
    cmp word [ds:WORK_STACK_DEPTH], 1
    je .halt_valid
    mov ax, ERR_INVALID_STACK_DEPTH
    call codegen_record_stack_error
    ret
.halt_valid:
    dec word [ds:WORK_STACK_DEPTH]
    mov byte [ds:WORK_IR_HALT_SEEN], 1
.valid:
    clc
    ret

.unsupported:
    mov ax, ERR_UNSUPPORTED_OPCODE
    call compiler_record_error
    ret

; Memastikan tabel berakhir sesudah satu HALT yang mengonsumsi satu hasil.
; Masukan: dispatcher telah membaca IR_END dan menandai WORK_IR_END_SEEN.
; Keluaran: CF=0 jika program mempunyai isi, HALT final, dan depth akhir nol.
; Register berubah: AX, flag; register lain dipertahankan.
; Kesalahan: program kosong, tanpa HALT, atau depth akhir tidak valid.
codegen_validate_end:
    cmp word [ds:WORK_DECODED_COUNT], 0
    jne .has_instruction
    mov ax, ERR_EMPTY_PROGRAM
    call codegen_record_stack_error
    ret
.has_instruction:
    cmp byte [ds:WORK_IR_HALT_SEEN], 1
    je .halt_present
    mov ax, ERR_INVALID_IR_FLOW
    call codegen_record_stack_error
    ret
.halt_present:
    cmp word [ds:WORK_STACK_DEPTH], 0
    je .valid
    mov ax, ERR_INVALID_STACK_DEPTH
    call codegen_record_stack_error
    ret
.valid:
    clc
    ret

; Menyimpan kode error stack pada field khusus dan status compiler.
; Masukan: AX adalah kode error stack atau alur IR.
; Keluaran: WORK_STACK_ERROR dan WORK_ERROR_CODE berisi kode; CF=1.
; Register berubah: flag; AX dipertahankan.
; Kesalahan: prosedur ini merupakan pencatatan error.
codegen_record_stack_error:
    mov word [ds:WORK_STACK_ERROR], ax
    call compiler_record_error
    ret
