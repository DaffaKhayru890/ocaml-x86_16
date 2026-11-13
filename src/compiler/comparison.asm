; Memilih conditional jump untuk operator comparison IR aktif.
; Masukan: WORK_CURRENT_OPCODE berisi IR_EQ, IR_NE, IR_LT, atau IR_GT.
; Keluaran: AL berisi opcode Jcc 8086; CF=0 jika opcode dikenali.
; Register berubah: AX dan flag.
; Kesalahan: opcode lain mencatat ERR_COMPARISON_FAILED.
; Alur: petakan setiap operator ke kondisi yang membuat Boolean salah.
comparison_select_jump:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_EQ
    jne .not_eq
    mov al, MC_JNE_SHORT
    clc
    ret
.not_eq:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_NE
    jne .not_ne
    mov al, MC_JE_SHORT
    clc
    ret
.not_ne:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LT
    jne .not_lt
    mov al, MC_JGE_SHORT
    clc
    ret
.not_lt:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_GT
    jne .invalid
    mov al, MC_JLE_SHORT
    clc
    ret
.invalid:
    mov ax, ERR_COMPARISON_FAILED
    call compiler_record_error
    ret

; Menghasilkan Boolean dari dua operand bertanda pada stack virtual.
; Masukan: WORK_CURRENT_OPCODE memilih EQ, NE, LT, atau GT; stack berisi dua nilai.
; Keluaran: hasil 0/1 didorong kembali; DI dan panjang code diperbarui emitter.
; Register berubah: AX, BX, DI, flag; register lain dipertahankan.
; Kesalahan: opcode comparison invalid, Boolean invalid, atau emitter overflow.
; Alur: POP kanan/kiri, CMP kiri-kanan, pilih Jcc untuk melewati nilai true.
codegen_compare:
    CODEGEN_EMIT8 MC_POP_BX
    CODEGEN_EMIT8 MC_POP_AX
    CODEGEN_EMIT8 MC_CMP_AX_BX
    CODEGEN_EMIT8 MC_MODRM_CMP_AX_BX

    mov ax, BOOLEAN_FALSE_VALUE
    call codegen_emit_boolean_value
    jc .failed
    call comparison_select_jump
    jc .failed
    CODEGEN_EMIT8 al
    CODEGEN_EMIT8 MC_COMPARE_SKIP_TRUE
    mov ax, BOOLEAN_TRUE_VALUE
    call codegen_emit_boolean_value
    jc .failed
    CODEGEN_EMIT8 MC_PUSH_AX
    clc
    ret
.failed:
    stc
    ret
