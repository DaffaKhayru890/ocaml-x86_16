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
    mov ax, [ds:bx + CF_RELOC_LABEL_INDEX]
    call control_flow_label_offset
    mov ax, [ds:bx + CF_LABEL_CODE_OFFSET]
    cmp ax, 0xFFFF
    jne .target_available
    mov ax, ERR_INVALID_RELOCATION
    call compiler_record_error
    ret
.target_available:
    mov [ds:WORK_TEMP_DEPTH], ax
    mov ax, [ds:WORK_TEMP_INDEX]
    mov dx, ax
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov cx, dx
    shl cx, 1
    sub ax, cx
    mov bx, ax
    add bx, CF_RELOCATION_TABLE
    mov dx, [ds:bx + CF_RELOC_PATCH_OFFSET]
    cmp dx, 0
    je .invalid_patch
    mov ax, dx
    add ax, 2
    cmp ax, di
    jbe .patch_in_range
.invalid_patch:
    mov ax, ERR_INVALID_RELOCATION
    call compiler_record_error
    ret
.patch_in_range:
    mov bx, dx
    dec bx
    cmp byte [es:bx], MC_JMP_NEAR
    je .opcode_valid
    mov ax, ERR_INVALID_RELOCATION
    call compiler_record_error
    ret
.opcode_valid:
    mov ax, [ds:WORK_TEMP_DEPTH]
    sub ax, dx
    sub ax, 2
    cmp ax, 0x0FFF
    jbe .positive_range
    cmp ax, 0xF000
    jae .negative_range
    mov ax, ERR_JUMP_DISPLACEMENT_RANGE
    call compiler_record_error
    ret
.positive_range:
.negative_range:
    push di
    mov di, dx
    mov [es:di], ax
    pop di
    inc word [ds:WORK_TEMP_INDEX]
    jmp .next_relocation
.done:
    clc
    ret
