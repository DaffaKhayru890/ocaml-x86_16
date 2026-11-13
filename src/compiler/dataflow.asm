; Menganalisis stack depth dan definite assignment pada node CFG yang reachable.

; Menyalin delapan byte bitmap lokal dari sumber DS:SI ke tujuan DS:BX.
; CX digunakan sebagai penghitung dan dipulihkan oleh pemanggil bila diperlukan.
dataflow_copy_bitmap:
    mov cx, WORK_LOCAL_INIT_SIZE
.copy:
    mov al, [ds:si]
    mov [ds:bx], al
    inc si
    inc bx
    loop .copy
    ret

; Menerapkan efek stack dan local pada satu instruksi reachable.
; Keluaran: WORK_TEMP_DEPTH dan WORK_TEMP_BITMAP berisi state setelah instruksi.
dataflow_transfer:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_STACK_IN]
    mov [ds:WORK_TEMP_DEPTH], ax
    mov si, bx
    add si, CF_INST_INIT_IN
    mov bx, WORK_LOCAL_INIT_BITMAP
    call dataflow_copy_bitmap
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov dl, [ds:bx + CF_INST_OPCODE]
    mov ax, [ds:bx + CF_INST_OPERAND]
    xor ah, ah
    mov [ds:WORK_DECODED_OPERAND], ax

    cmp dl, IR_ICONST
    jne .not_iconst
    jmp .push
.not_iconst:
    cmp dl, IR_LOAD_LOCAL
    jne .not_load_local
    jmp .load
.not_load_local:
    cmp dl, IR_STORE_LOCAL
    jne .not_store_local
    jmp .store
.not_store_local:
    cmp dl, IR_ADD
    jne .not_add
    jmp .binary
.not_add:
    cmp dl, IR_SUB
    jne .not_sub
    jmp .binary
.not_sub:
    cmp dl, IR_MUL
    jne .not_mul
    jmp .binary
.not_mul:
    cmp dl, IR_EQ
    jne .not_eq
    jmp .binary
.not_eq:
    cmp dl, IR_NE
    jne .not_ne
    jmp .binary
.not_ne:
    cmp dl, IR_LT
    jne .not_lt
    jmp .binary
.not_lt:
    cmp dl, IR_GT
    jne .not_gt
    jmp .binary
.not_gt:
    cmp dl, IR_NEG
    jne .not_neg
    jmp .unary
.not_neg:
    cmp dl, IR_JZ
    jne .not_jz
    jmp .conditional
.not_jz:
    cmp dl, IR_JNZ
    jne .not_jnz
    jmp .conditional
.not_jnz:
    cmp dl, IR_JMP
    jne .not_jmp
    jmp .finish
.not_jmp:
    cmp dl, IR_HALT
    jne .unsupported
    jmp .halt
.unsupported:
    mov ax, ERR_UNSUPPORTED_OPCODE
    call codegen_record_stack_error
    ret

.push:
    mov ax, [ds:WORK_TEMP_DEPTH]
    cmp ax, VIRTUAL_STACK_MAX_DEPTH
    jb .push_valid
    mov ax, ERR_STACK_OVERFLOW
    call codegen_record_stack_error
    ret
.push_valid:
    inc word [ds:WORK_TEMP_DEPTH]
    jmp .finish

.load:
    mov al, [ds:WORK_DECODED_OPERAND]
    call check_local_initialized
    jnc .load_valid
    jmp .failed
.load_valid:
    jmp .push

.store:
    cmp word [ds:WORK_TEMP_DEPTH], 1
    jae .store_stack_valid
    mov ax, ERR_STACK_UNDERFLOW
    call codegen_record_stack_error
    ret
.store_stack_valid:
    mov al, [ds:WORK_DECODED_OPERAND]
    call set_local_initialized
    jnc .store_valid
    jmp .failed
.store_valid:
    dec word [ds:WORK_TEMP_DEPTH]
    jmp .finish

.binary:
    cmp word [ds:WORK_TEMP_DEPTH], 2
    jae .binary_valid
    mov ax, ERR_STACK_UNDERFLOW
    call codegen_record_stack_error
    ret
.binary_valid:
    dec word [ds:WORK_TEMP_DEPTH]
    jmp .finish

.unary:
    cmp word [ds:WORK_TEMP_DEPTH], 1
    jae .finish
    mov ax, ERR_STACK_UNDERFLOW
    call codegen_record_stack_error
    ret

.conditional:
    cmp word [ds:WORK_TEMP_DEPTH], 1
    jae .conditional_valid
    mov ax, ERR_STACK_UNDERFLOW
    call codegen_record_stack_error
    ret
.conditional_valid:
    dec word [ds:WORK_TEMP_DEPTH]
    jmp .finish

.halt:
    cmp word [ds:WORK_TEMP_DEPTH], 1
    je .halt_valid
    cmp word [ds:WORK_TEMP_DEPTH], 0
    jne .invalid_halt_depth
    mov ax, ERR_EMPTY_PROGRAM
    call codegen_record_stack_error
    ret
.invalid_halt_depth:
    mov ax, ERR_INVALID_STACK_DEPTH
    call codegen_record_stack_error
    ret
.halt_valid:
    dec word [ds:WORK_TEMP_DEPTH]

.finish:
    mov ax, [ds:WORK_TEMP_DEPTH]
    cmp ax, [ds:WORK_MAX_STACK_DEPTH]
    jbe .save_bitmap
    mov [ds:WORK_MAX_STACK_DEPTH], ax
.save_bitmap:
    mov bx, WORK_TEMP_BITMAP
    mov si, WORK_LOCAL_INIT_BITMAP
    call dataflow_copy_bitmap
    clc
    ret
.failed:
    stc
    ret

; Menggabungkan state predecessor ke sebuah node.
; Masukan: AX=indeks tujuan; output depth/bitmap berada pada temporary state.
dataflow_propagate:
    mov [ds:WORK_TEMP_INDEX], ax
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jb .destination_valid
    mov ax, ERR_CFG_INVALID_FALLTHROUGH
    call codegen_record_stack_error
    ret
.destination_valid:
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_STACK_IN]
    cmp ax, 0xFFFF
    je .first_predecessor
    cmp ax, [ds:WORK_TEMP_DEPTH]
    je .merge_bitmap
    mov ax, ERR_CFG_STACK_MISMATCH
    call codegen_record_stack_error
    ret
.first_predecessor:
    mov ax, [ds:WORK_TEMP_DEPTH]
    mov [ds:bx + CF_INST_STACK_IN], ax
    mov si, WORK_TEMP_BITMAP
    lea bx, [bx + CF_INST_INIT_IN]
    call dataflow_copy_bitmap
    mov byte [ds:WORK_CFG_CHANGED], 1
    clc
    ret
.merge_bitmap:
    lea si, [bx + CF_INST_INIT_IN]
    mov bx, WORK_TEMP_BITMAP
    mov cx, WORK_LOCAL_INIT_SIZE
.intersect:
    mov al, [ds:si]
    and al, [ds:bx]
    cmp al, [ds:si]
    je .unchanged
    mov [ds:si], al
    mov byte [ds:WORK_CFG_CHANGED], 1
.unchanged:
    inc si
    inc bx
    loop .intersect
    clc
    ret

; Menjalankan sweep berulang sampai seluruh stack dan bitmap mencapai fixed-point.
dataflow_fixed_point:
    mov byte [ds:WORK_CFG_CHANGED], 1
.iteration:
    cmp word [ds:WORK_CFG_ITERATIONS], MAX_CFG_ITERATIONS
    jb .iteration_allowed
    mov ax, ERR_DATAFLOW_FAILURE
    call codegen_record_stack_error
    ret
.iteration_allowed:
    inc word [ds:WORK_CFG_ITERATIONS]
    mov byte [ds:WORK_CFG_CHANGED], 0
    mov word [ds:WORK_REACHABLE_HALTS], 0
    mov word [ds:WORK_CURRENT_INSTRUCTION], 0
.node:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jae .sweep_done
    call control_flow_instruction_offset
    cmp word [ds:bx + CF_INST_STACK_IN], 0xFFFF
    je .next_node
    call dataflow_transfer
    jc .failed
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov al, [ds:bx + CF_INST_OPCODE]
    cmp al, IR_HALT
    je .halt
    cmp al, IR_JMP
    je .unconditional
    cmp al, IR_JZ
    je .conditional
    cmp al, IR_JNZ
    je .conditional
    jmp .fallthrough
.unconditional:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_TARGET_INDEX]
    call dataflow_propagate
    jc .failed
    jmp .next_node
.conditional:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov ax, [ds:bx + CF_INST_TARGET_INDEX]
    call dataflow_propagate
    jc .failed
.fallthrough:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    inc ax
    call dataflow_propagate
    jc .failed
    jmp .next_node
.halt:
    inc word [ds:WORK_REACHABLE_HALTS]
.next_node:
    inc word [ds:WORK_CURRENT_INSTRUCTION]
    jmp .node
.sweep_done:
    cmp byte [ds:WORK_CFG_CHANGED], 0
    je .converged
    jmp .iteration
.converged:
    cmp word [ds:WORK_REACHABLE_HALTS], 0
    jne .valid
    mov ax, ERR_INVALID_CONTROL_FLOW
    call codegen_record_stack_error
    ret
.valid:
    mov byte [ds:WORK_IR_HALT_SEEN], 1
    mov word [ds:WORK_STACK_DEPTH], 0
    clc
    ret
.failed:
    stc
    ret
