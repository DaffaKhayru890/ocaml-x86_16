; Memvalidasi encoding, batas instruksi, dan target branch hasil codegen.

%macro MC_CHECK_BYTE 2
    mov bx, [ds:WORK_VALIDATION_OFFSET]
    add bx, %1
    mov al, %2
    call machine_code_expect_byte
    jnc %%valid
    jmp .invalid
%%valid:
%endmacro

%macro MC_CHECK_WORD 2
    mov bx, [ds:WORK_VALIDATION_OFFSET]
    add bx, %1
    mov ax, %2
    call machine_code_expect_word
    jnc %%valid
    jmp .invalid
%%valid:
%endmacro

; Membandingkan satu byte ES:BX dengan AL tanpa mengubah register umum.
machine_code_expect_byte:
    cmp byte [es:bx], al
    jne .mismatch
    clc
    ret
.mismatch:
    stc
    ret

; Membandingkan satu word little-endian ES:BX dengan AX.
machine_code_expect_word:
    cmp word [es:bx], ax
    jne .mismatch
    clc
    ret
.mismatch:
    stc
    ret

; Mengembalikan ukuran encoding untuk satu opcode IR yang dikenal.
; Masukan: AL adalah opcode; keluaran: AX adalah panjang atau CF=1.
machine_code_instruction_size:
    cmp al, IR_ICONST
    jne .not_iconst
    mov ax, 4
    clc
    ret
.not_iconst:
    cmp al, IR_LOAD_LOCAL
    jne .not_load
    mov ax, 4
    clc
    ret
.not_load:
    cmp al, IR_STORE_LOCAL
    jne .not_store
    mov ax, 4
    clc
    ret
.not_store:
    cmp al, IR_ADD
    jne .not_add
    mov ax, 5
    clc
    ret
.not_add:
    cmp al, IR_SUB
    jne .not_sub
    mov ax, 5
    clc
    ret
.not_sub:
    cmp al, IR_MUL
    jne .not_mul
    mov ax, 5
    clc
    ret
.not_mul:
    cmp al, IR_NEG
    jne .not_neg
    mov ax, 4
    clc
    ret
.not_neg:
    cmp al, IR_EQ
    jne .not_eq
    jmp .comparison
.not_eq:
    cmp al, IR_NE
    jne .not_ne
    jmp .comparison
.not_ne:
    cmp al, IR_LT
    jne .not_lt
    jmp .comparison
.not_lt:
    cmp al, IR_GT
    jne .not_gt
    jmp .comparison
.not_gt:
    cmp al, IR_JMP
    jne .not_jump
    mov ax, 3
    clc
    ret
.not_jump:
    cmp al, IR_JZ
    je .conditional
    cmp al, IR_JNZ
    jne .not_conditional
.conditional:
    mov ax, 8
    clc
    ret
.not_conditional:
    cmp al, IR_HALT
    jne .unknown
    mov ax, 7
    clc
    ret
.comparison:
    mov ax, 13
    clc
    ret
.unknown:
    stc
    ret

; Memastikan setiap record cocok dengan template machine code yang ditentukan.
; Masukan: WORK_CURRENT_OPCODE dan WORK_DECODED_OPERAND telah disiapkan.
machine_code_validate_instruction_bytes:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_ICONST
    jne .not_iconst
    jmp .iconst
.not_iconst:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LOAD_LOCAL
    jne .not_load
    jmp .load_local
.not_load:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_STORE_LOCAL
    jne .not_store
    jmp .store_local
.not_store:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_ADD
    jne .not_add
    jmp .add
.not_add:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_SUB
    jne .not_sub
    jmp .sub
.not_sub:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_MUL
    jne .not_mul
    jmp .mul
.not_mul:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_NEG
    jne .not_neg
    jmp .neg
.not_neg:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_EQ
    jne .not_eq
    jmp .comparison
.not_eq:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_NE
    jne .not_ne
    jmp .comparison
.not_ne:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LT
    jne .not_lt
    jmp .comparison
.not_lt:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_GT
    jne .not_gt
    jmp .comparison
.not_gt:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JMP
    jne .not_jump
    jmp .jump
.not_jump:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JZ
    je .conditional
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_JNZ
    jne .not_conditional
.conditional:
    jmp .conditional_jump
.not_conditional:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_HALT
    je .is_halt
    jmp .invalid
.is_halt:
    jmp .halt

.iconst:
    MC_CHECK_BYTE 0, MC_MOV_AX_IMM16
    MC_CHECK_WORD 1, [ds:WORK_DECODED_OPERAND]
    MC_CHECK_BYTE 3, MC_PUSH_AX
    clc
    ret
.load_local:
    MC_CHECK_BYTE 0, MC_MOV_AX_MOFFS
    mov ax, [ds:WORK_DECODED_OPERAND]
    shl ax, 1
    add ax, LOCAL_SLOT_BASE
    MC_CHECK_WORD 1, ax
    MC_CHECK_BYTE 3, MC_PUSH_AX
    clc
    ret
.store_local:
    MC_CHECK_BYTE 0, MC_POP_AX
    MC_CHECK_BYTE 1, MC_MOV_MOFFS_AX
    mov ax, [ds:WORK_DECODED_OPERAND]
    shl ax, 1
    add ax, LOCAL_SLOT_BASE
    MC_CHECK_WORD 2, ax
    clc
    ret
.add:
    MC_CHECK_BYTE 0, MC_POP_BX
    MC_CHECK_BYTE 1, MC_POP_AX
    MC_CHECK_BYTE 2, MC_ADD_AX_BX
    MC_CHECK_BYTE 3, MC_MODRM_ADD_AX_BX
    MC_CHECK_BYTE 4, MC_PUSH_AX
    clc
    ret
.sub:
    MC_CHECK_BYTE 0, MC_POP_BX
    MC_CHECK_BYTE 1, MC_POP_AX
    MC_CHECK_BYTE 2, MC_SUB_AX_BX
    MC_CHECK_BYTE 3, MC_MODRM_SUB_AX_BX
    MC_CHECK_BYTE 4, MC_PUSH_AX
    clc
    ret
.mul:
    MC_CHECK_BYTE 0, MC_POP_BX
    MC_CHECK_BYTE 1, MC_POP_AX
    MC_CHECK_BYTE 2, MC_IMUL_BX
    MC_CHECK_BYTE 3, MC_MODRM_IMUL_BX
    MC_CHECK_BYTE 4, MC_PUSH_AX
    clc
    ret
.neg:
    MC_CHECK_BYTE 0, MC_POP_AX
    MC_CHECK_BYTE 1, MC_NEG_AX
    MC_CHECK_BYTE 2, MC_MODRM_NEG_AX
    MC_CHECK_BYTE 3, MC_PUSH_AX
    clc
    ret
.comparison:
    MC_CHECK_BYTE 0, MC_POP_BX
    MC_CHECK_BYTE 1, MC_POP_AX
    MC_CHECK_BYTE 2, MC_CMP_AX_BX
    MC_CHECK_BYTE 3, MC_MODRM_CMP_AX_BX
    MC_CHECK_BYTE 4, MC_MOV_AX_IMM16
    MC_CHECK_WORD 5, 0
    call comparison_select_jump
    jnc .comparison_jump_valid
    jmp .invalid
.comparison_jump_valid:
    MC_CHECK_BYTE 7, al
    MC_CHECK_BYTE 8, MC_COMPARE_SKIP_TRUE
    MC_CHECK_BYTE 9, MC_MOV_AX_IMM16
    MC_CHECK_WORD 10, 1
    MC_CHECK_BYTE 12, MC_PUSH_AX
    clc
    ret
.jump:
    MC_CHECK_BYTE 0, MC_JMP_NEAR
    call machine_code_check_rel16
    ret
.conditional_jump:
    MC_CHECK_BYTE 0, MC_POP_AX
    MC_CHECK_BYTE 1, MC_TEST_AX_AX
    MC_CHECK_BYTE 2, MC_MODRM_TEST_AX_AX
    mov al, [ds:WORK_CURRENT_OPCODE]
    cmp al, IR_JZ
    jne .conditional_jnz
    MC_CHECK_BYTE 3, MC_JNZ_SHORT
    jmp .conditional_skip_valid
.conditional_jnz:
    MC_CHECK_BYTE 3, MC_JZ_SHORT
.conditional_skip_valid:
    MC_CHECK_BYTE 4, MC_COMPARE_SKIP_TRUE
    MC_CHECK_BYTE 5, MC_JMP_NEAR
    call machine_code_check_rel16_conditional
    ret
.halt:
    MC_CHECK_BYTE 0, MC_POP_AX
    MC_CHECK_BYTE 1, MC_MOV_MOFFS_AX
    MC_CHECK_WORD 2, 0
    MC_CHECK_BYTE 4, MC_HLT
    MC_CHECK_BYTE 5, MC_JMP_SHORT
    MC_CHECK_BYTE 6, MC_JMP_SHORT_BACK_3
    clc
    ret
.invalid:
    stc
    ret

; Memverifikasi bahwa rel16 branch cocok dengan code offset label executable.
; Masukan: index instruksi aktif dan posisi displacement pada WORK_VALIDATION_OFFSET.
machine_code_check_rel16:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_TARGET_INDEX]
    cmp ax, 0xFFFF
    je .invalid
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jae .invalid
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_CODE_OFFSET]
    cmp ax, 0xFFFF
    je .invalid
    cmp ax, [ds:WORK_EMIT_LENGTH]
    jae .invalid
    mov [ds:WORK_TEMP_DEPTH], ax
    mov ax, [ds:WORK_VALIDATION_OFFSET]
    add ax, 3
    mov dx, ax
    mov ax, [ds:WORK_TEMP_DEPTH]
    sub ax, dx
    cmp ax, 0x0FFF
    jbe .range_valid
    cmp ax, 0xF000
    jae .range_valid
    jmp .invalid
.range_valid:
    mov bx, [ds:WORK_VALIDATION_OFFSET]
    inc bx
    call machine_code_expect_word
    jc .invalid
    clc
    ret
.invalid:
    stc
    ret

; Memverifikasi rel16 pada trampoline JZ/JNZ yang berakhir delapan byte setelah awal.
machine_code_check_rel16_conditional:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_TARGET_INDEX]
    cmp ax, 0xFFFF
    je .invalid
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jae .invalid
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_CODE_OFFSET]
    cmp ax, 0xFFFF
    je .invalid
    cmp ax, [ds:WORK_EMIT_LENGTH]
    jae .invalid
    mov [ds:WORK_TEMP_DEPTH], ax
    mov ax, [ds:WORK_VALIDATION_OFFSET]
    add ax, 8
    mov dx, ax
    mov ax, [ds:WORK_TEMP_DEPTH]
    sub ax, dx
    cmp ax, 0x0FFF
    jbe .range_valid
    cmp ax, 0xF000
    jae .range_valid
    jmp .invalid
.range_valid:
    mov bx, [ds:WORK_VALIDATION_OFFSET]
    add bx, 6
    call machine_code_expect_word
    jc .invalid
    clc
    ret
.invalid:
    stc
    ret

; Memvalidasi prologue, relocation, offset berurutan, template, dan seluruh target.
machine_code_validate_generated_program:
    mov ax, [ds:WORK_RELOCATION_APPLIED_COUNT]
    cmp ax, [ds:WORK_RELOCATION_COUNT]
    je .relocations_valid
    jmp .invalid
.relocations_valid:
    mov word [ds:WORK_CURRENT_INSTRUCTION], 0
    mov word [ds:WORK_VALIDATION_OFFSET], 14
.next_instruction:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jae .all_instructions_valid
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_CODE_OFFSET]
    cmp ax, [ds:WORK_VALIDATION_OFFSET]
    je .offset_valid
    jmp .invalid
.offset_valid:
    mov al, [ds:bx + CF_INST_OPCODE]
    mov [ds:WORK_CURRENT_OPCODE], al
    mov ax, [ds:bx + CF_INST_OPERAND]
    mov [ds:WORK_DECODED_OPERAND], ax
    mov al, [ds:WORK_CURRENT_OPCODE]
    call machine_code_instruction_size
    jnc .size_valid
    jmp .invalid
.size_valid:
    mov [ds:WORK_TEMP_SIZE], ax
    call machine_code_validate_instruction_bytes
    jnc .bytes_valid
    jmp .invalid
.bytes_valid:
    mov ax, [ds:WORK_VALIDATION_OFFSET]
    add ax, [ds:WORK_TEMP_SIZE]
    cmp ax, [ds:WORK_EMIT_LENGTH]
    jbe .instruction_in_range
    jmp .invalid
.instruction_in_range:
    mov [ds:WORK_VALIDATION_OFFSET], ax
    inc word [ds:WORK_CURRENT_INSTRUCTION]
    jmp .next_instruction
.all_instructions_valid:
    mov ax, [ds:WORK_VALIDATION_OFFSET]
    cmp ax, [ds:WORK_EMIT_LENGTH]
    je .valid
.invalid:
    mov ax, ERR_RUNTIME_INVALID
    call compiler_record_error
    ret
.valid:
    clc
    ret
