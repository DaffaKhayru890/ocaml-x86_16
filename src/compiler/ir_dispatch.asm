; Membaca opcode berikutnya lalu meneruskan validasi operand.
; Masukan: SI menunjuk opcode dan remaining memuat sisa byte IR.
; Keluaran: opcode tersimpan; CF=0 jika instruksi valid, CF=1 jika gagal.
; Register berubah: AX, SI, CX, flag.
; Kesalahan: pembaca atau validator mencatat kode kesalahan pada memori kerja.
ir_dispatch_opcode:
    call ir_read_u8
    jc .failed
    mov byte [ds:WORK_CURRENT_OPCODE], al
    mov byte [ds:WORK_OPERAND_SIZE], 0
    mov word [ds:WORK_DECODED_OPERAND], 0
    call ir_validate_instruction
    ret
.failed:
    stc
    ret

; Mengenali opcode, membaca operand yang diwajibkan, dan menghitung instruksi.
; Masukan: WORK_CURRENT_OPCODE berisi opcode yang baru dibaca.
; Keluaran: field operand/ukuran diperbarui; CF=0 jika valid.
; Register berubah: AX, CX, SI, flag.
; Kesalahan: opcode asing, operand terpotong, atau byte sesudah IR_END.
ir_validate_instruction:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_END
    jne .not_end
    jmp .end
.not_end:

    cmp byte [ds:WORK_CURRENT_OPCODE], IR_ICONST
    je .operand_u16
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LABEL
    je .operand_u16
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JMP
    je .operand_u16
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JZ
    je .operand_u16
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JNZ
    je .operand_u16

    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LOAD_LOCAL
    je .operand_u8
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_STORE_LOCAL
    je .operand_u8

    cmp byte [ds:WORK_CURRENT_OPCODE], IR_ADD
    je .no_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_SUB
    je .no_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_MUL
    je .no_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_NEG
    je .no_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_EQ
    je .no_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_NE
    je .no_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LT
    je .no_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_GT
    je .no_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_HALT
    je .no_operand

    mov ax, ERR_UNKNOWN_OPCODE
    call compiler_record_error
    ret

.operand_u16:
    call ir_read_u16
    jc .failed
    mov word [ds:WORK_DECODED_OPERAND], ax
    mov byte [ds:WORK_OPERAND_SIZE], 2
    jmp .count
.operand_u8:
    call ir_read_u8
    jc .failed
    xor ah, ah
    mov word [ds:WORK_DECODED_OPERAND], ax
    mov byte [ds:WORK_OPERAND_SIZE], 1
.count:
    inc word [ds:WORK_DECODED_COUNT]
    clc
    ret
.no_operand:
    inc word [ds:WORK_DECODED_COUNT]
    clc
    ret
.end:
    cmp word [ds:WORK_IR_REMAINING], 0
    jne .trailing_data
    mov byte [ds:WORK_IR_END_SEEN], 1
    clc
    ret
.trailing_data:
    mov ax, ERR_TRAILING_DATA
    call compiler_record_error
    ret
.failed:
    stc
    ret

; Memvalidasi payload sampai IR_END atau mencatat kondisi terminasi yang gagal.
; Masukan: SI berada di awal payload dan WORK_IR_REMAINING berisi panjangnya.
; Keluaran: WORK_IR_END_SEEN=1 jika valid; CF=0.
; Register berubah: AX, CX, SI, flag.
; Kesalahan: payload habis tanpa IR_END atau salah satu instruksi tidak valid.
ir_validate_program:
.next_instruction:
    cmp word [ds:WORK_IR_REMAINING], 0
    je .missing_end
    call ir_dispatch_opcode
    jc .failed
    cmp byte [ds:WORK_IR_END_SEEN], 1
    je .end
    call codegen_validate_stack
    jc .failed
    jmp .next_instruction
.end:
    call codegen_validate_end
    ret
.missing_end:
    mov ax, ERR_MISSING_END
    call compiler_record_error
    ret
.failed:
    stc
    ret
