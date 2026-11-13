; Mengumpulkan operand rel16 dan menambal semuanya setelah alamat kode diketahui.

; Mendaftarkan lokasi displacement untuk label target branch.
relocation_add:
    mov ax, [ds:WORK_DECODED_OPERAND]
    call control_flow_find_label
    jnc .label_found
    mov ax, ERR_UNRESOLVED_LABEL
    call compiler_record_error
    ret
.label_found:
    mov [ds:WORK_TEMP_INDEX], ax
    mov ax, [ds:WORK_RELOCATION_COUNT]
    cmp ax, MAX_IR_RELOCATIONS
    jb .capacity_ok
    mov ax, ERR_RELOCATION_TABLE_OVERFLOW
    call compiler_record_error
    ret
.capacity_ok:
    mov dx, ax
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov cx, dx
    shl cx, 1
    sub ax, cx
    mov bx, ax
    add bx, CF_RELOCATION_TABLE
    mov ax, [ds:WORK_TEMP_INDEX]
    mov [ds:bx + CF_RELOC_LABEL_INDEX], ax
    mov ax, [ds:WORK_CURRENT_PATCH_OFFSET]
    mov [ds:bx + CF_RELOC_PATCH_OFFSET], ax
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    mov [ds:bx + CF_RELOC_SOURCE_INDEX], ax
    inc word [ds:WORK_RELOCATION_COUNT]
    clc
    ret

; Menerapkan seluruh displacement rel16 terhadap alamat code offset final.
relocation_apply_all:
    mov word [ds:WORK_TEMP_INDEX], 0
    mov word [ds:WORK_RELOCATION_APPLIED_COUNT], 0
.next_relocation:
    mov ax, [ds:WORK_TEMP_INDEX]
    cmp ax, [ds:WORK_RELOCATION_COUNT]
    jb .has_relocation
    jmp .done
.has_relocation:
    mov dx, ax
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov cx, dx
    shl cx, 1
    sub ax, cx
    mov bx, ax
    add bx, CF_RELOCATION_TABLE
    mov [ds:WORK_TEMP_SIZE], bx
    mov ax, [ds:bx + CF_RELOC_SOURCE_INDEX]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jb .source_index_valid
    jmp .invalid
.source_index_valid:
    mov [ds:WORK_TEMP_BITMAP], ax
    call control_flow_instruction_offset
    mov al, [ds:bx + CF_INST_OPCODE]
    cmp al, IR_JMP
    je .source_is_jump
    cmp al, IR_JZ
    je .source_is_conditional
    cmp al, IR_JNZ
    je .source_is_conditional
    jmp .invalid
.source_is_conditional:
    mov dx, [ds:bx + CF_INST_CODE_OFFSET]
    cmp dx, 0xFFFF
    jne .conditional_offset_valid
    jmp .invalid
.conditional_offset_valid:
    add dx, 6
    jmp .source_patch_ready
.source_is_jump:
    mov dx, [ds:bx + CF_INST_CODE_OFFSET]
    cmp dx, 0xFFFF
    jne .jump_offset_valid
    jmp .invalid
.jump_offset_valid:
    inc dx
.source_patch_ready:
    mov ax, [ds:bx + CF_INST_OPERAND]
    mov [ds:WORK_TEMP_BITMAP + 2], ax
    mov bx, [ds:WORK_TEMP_SIZE]
    cmp dx, [ds:bx + CF_RELOC_PATCH_OFFSET]
    je .patch_matches
    jmp .invalid
.patch_matches:
    mov ax, [ds:bx + CF_RELOC_LABEL_INDEX]
    cmp ax, [ds:WORK_LABEL_COUNT]
    jb .label_index_valid
    jmp .invalid
.label_index_valid:
    call control_flow_label_offset
    mov ax, [ds:WORK_TEMP_BITMAP + 2]
    cmp ax, [ds:bx + CF_LABEL_ID]
    jne .invalid
    mov ax, [ds:bx + CF_LABEL_TARGET_INDEX]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jb .label_target_valid
    jmp .invalid
.label_target_valid:
    mov ax, [ds:bx + CF_LABEL_CODE_OFFSET]
    cmp ax, 0xFFFF
    jne .target_valid
    jmp .invalid
.target_valid:
    mov [ds:WORK_TEMP_DEPTH], ax
    mov bx, [ds:WORK_TEMP_SIZE]
    mov dx, [ds:bx + CF_RELOC_PATCH_OFFSET]
    cmp dx, 0
    jne .patch_nonzero
    jmp .invalid_patch
.patch_nonzero:
    mov ax, dx
    add ax, 2
    cmp ax, di
    jbe .patch_in_range
    jmp .invalid_patch
.invalid_patch:
    mov ax, ERR_INVALID_RELOCATION
    call compiler_record_error
    ret
.patch_in_range:
    mov bx, dx
    dec bx
    cmp byte [es:bx], MC_JMP_NEAR
    je .opcode_valid
    jmp .invalid
.opcode_valid:
    mov ax, [ds:WORK_TEMP_DEPTH]
    sub ax, dx
    sub ax, 2
    cmp ax, 0x0FFF
    jbe .displacement_valid
    cmp ax, 0xF000
    jae .displacement_valid
    mov ax, ERR_JUMP_DISPLACEMENT_RANGE
    call compiler_record_error
    ret
.displacement_valid:
    push di
    mov di, dx
    mov [es:di], ax
    pop di
    inc word [ds:WORK_RELOCATION_APPLIED_COUNT]
    inc word [ds:WORK_TEMP_INDEX]
    jmp .next_relocation
.invalid:
    mov ax, ERR_INVALID_RELOCATION
    call compiler_record_error
    ret
.done:
    mov ax, [ds:WORK_RELOCATION_APPLIED_COUNT]
    cmp ax, [ds:WORK_RELOCATION_COUNT]
    je .all_applied
    mov ax, ERR_INVALID_RELOCATION
    call compiler_record_error
    ret
.all_applied:
    clc
    ret
