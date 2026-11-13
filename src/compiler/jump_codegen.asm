; Menghasilkan near jump dan conditional trampoline yang kompatibel dengan 8086.

; Menghasilkan JMP rel16 dengan displacement yang akan ditambal di akhir.
codegen_jump:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JMP
    je .unconditional
    jmp .conditional
.unconditional:
    CODEGEN_EMIT8 MC_JMP_NEAR
    mov [ds:WORK_CURRENT_PATCH_OFFSET], di
    CODEGEN_EMIT16 0
    call relocation_add
    ret

; Mengonsumsi nilai kondisi lalu melompati JMP near ketika kondisi tidak cocok.
; JZ memakai JNZ +3; JNZ memakai JZ +3 untuk membalik kondisi.
.conditional:
    CODEGEN_EMIT8 MC_POP_AX
    CODEGEN_EMIT8 MC_TEST_AX_AX
    CODEGEN_EMIT8 MC_MODRM_TEST_AX_AX
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JZ
    jne .not_zero
    CODEGEN_EMIT8 MC_JNZ_SHORT
    jmp .emit_skip
.not_zero:
    CODEGEN_EMIT8 MC_JZ_SHORT
.emit_skip:
    CODEGEN_EMIT8 3
    CODEGEN_EMIT8 MC_JMP_NEAR
    mov [ds:WORK_CURRENT_PATCH_OFFSET], di
    CODEGEN_EMIT16 0
    call relocation_add
    ret
