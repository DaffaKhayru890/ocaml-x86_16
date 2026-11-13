; Mengubah IR menjadi tabel instruksi, mendaftarkan label, dan menghubungkan target.
; Tabel ini menjadi sumber validasi CFG serta code generation tahap berikutnya.

; Menghitung offset record instruksi dari indeks AX.
; Keluaran: BX menunjuk record; AX, CX, DX berubah.
control_flow_instruction_offset:
    mov bx, ax
    mov dx, ax
    shl bx, 1
    mov cx, ax
    shl cx, 1
    shl cx, 1
    shl cx, 1
    shl cx, 1
    add bx, cx
    add bx, dx
    add bx, CF_INSTRUCTION_TABLE
    ret

; Menghitung offset record label dari indeks AX.
; Keluaran: BX menunjuk record; AX, DX berubah.
control_flow_label_offset:
    mov bx, ax
    mov dx, ax
    shl bx, 1
    shl bx, 1
    shl bx, 1
    sub bx, dx
    add bx, CF_LABEL_TABLE
    ret

; Mencari ID label pada tabel.
; Masukan: AX=ID; keluaran AX=indeks dan CF=0, atau CF=1 jika tidak ditemukan.
control_flow_find_label:
    mov word [ds:WORK_TEMP_LABEL_ID], ax
    xor cx, cx
.search:
    cmp cx, word [ds:WORK_LABEL_COUNT]
    jae .not_found
    mov ax, cx
    call control_flow_label_offset
    mov ax, [ds:bx + CF_LABEL_ID]
    cmp ax, word [ds:WORK_TEMP_LABEL_ID]
    je .found
    inc cx
    jmp .search
.found:
    mov ax, cx
    clc
    ret
.not_found:
    stc
    ret

; Menambahkan deklarasi label dengan indeks instruksi executable saat ini.
; Kesalahan: ID duplikat atau kapasitas tabel habis.
control_flow_add_label:
    mov ax, [ds:WORK_DECODED_OPERAND]
    call control_flow_find_label
    jnc .duplicate
    mov ax, [ds:WORK_LABEL_COUNT]
    cmp ax, MAX_IR_LABELS
    jb .capacity_ok
    mov ax, ERR_LABEL_TABLE_OVERFLOW
    call compiler_record_error
    ret
.capacity_ok:
    mov [ds:WORK_TEMP_INDEX], ax
    call control_flow_label_offset
    mov ax, [ds:WORK_DECODED_OPERAND]
    mov [ds:bx + CF_LABEL_ID], ax
    mov ax, [ds:WORK_INSTRUCTION_COUNT]
    mov [ds:bx + CF_LABEL_TARGET_INDEX], ax
    mov word [ds:bx + CF_LABEL_CODE_OFFSET], 0xFFFF
    mov byte [ds:bx + CF_LABEL_FLAGS], CF_LABEL_DEFINED
    inc word [ds:WORK_LABEL_COUNT]
    clc
    ret
.duplicate:
    mov ax, ERR_DUPLICATE_LABEL
    call compiler_record_error
    ret

; Menyimpan instruksi executable hasil dispatcher ke tabel tetap.
; Label tidak dimasukkan ke dalam tabel instruksi.
control_flow_add_instruction:
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LOAD_LOCAL
    je .validate_local_operand
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_STORE_LOCAL
    jne .capacity_check
.validate_local_operand:
    mov al, [ds:WORK_DECODED_OPERAND]
    call validate_local_slot
    jc .failed
.capacity_check:
    mov ax, [ds:WORK_INSTRUCTION_COUNT]
    cmp ax, MAX_IR_INSTRUCTIONS
    jb .capacity_ok
    mov ax, ERR_INSTRUCTION_TABLE_OVERFLOW
    call compiler_record_error
    ret
.capacity_ok:
    call control_flow_instruction_offset
    mov al, [ds:WORK_CURRENT_OPCODE]
    mov [ds:bx + CF_INST_OPCODE], al
    mov ax, [ds:WORK_DECODED_OPERAND]
    mov [ds:bx + CF_INST_OPERAND], ax
    mov ax, [ds:WORK_CURRENT_IR_OFFSET]
    mov [ds:bx + CF_INST_SOURCE_OFFSET], ax
    mov word [ds:bx + CF_INST_TARGET_INDEX], 0xFFFF
    mov word [ds:bx + CF_INST_CODE_OFFSET], 0xFFFF
    mov word [ds:bx + CF_INST_STACK_IN], 0xFFFF
    mov word [ds:bx + CF_INST_INIT_IN], 0
    mov word [ds:bx + CF_INST_INIT_IN + 2], 0
    mov word [ds:bx + CF_INST_INIT_IN + 4], 0
    mov word [ds:bx + CF_INST_INIT_IN + 6], 0
    inc word [ds:WORK_INSTRUCTION_COUNT]
    clc
    ret
.failed:
    stc
    ret

; Resolves seluruh operand label dan menolak target yang tidak menunjuk instruksi.
control_flow_resolve_labels:
    mov word [ds:WORK_TEMP_INDEX], 0
.validate_label_targets:
    mov ax, [ds:WORK_TEMP_INDEX]
    cmp ax, [ds:WORK_LABEL_COUNT]
    jae .labels_valid
    call control_flow_label_offset
    mov ax, [ds:bx + CF_LABEL_TARGET_INDEX]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jb .next_label
    mov ax, ERR_INVALID_BRANCH_TARGET
    call compiler_record_error
    ret
.next_label:
    inc word [ds:WORK_TEMP_INDEX]
    jmp .validate_label_targets
.labels_valid:
    mov word [ds:WORK_TEMP_INDEX], 0
.next_instruction:
    mov ax, [ds:WORK_TEMP_INDEX]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jae .resolved
    call control_flow_instruction_offset
    mov al, [ds:bx + CF_INST_OPCODE]
    cmp al, IR_JMP
    je .branch
    cmp al, IR_JZ
    je .branch
    cmp al, IR_JNZ
    jne .next
.branch:
    mov ax, [ds:bx + CF_INST_OPERAND]
    call control_flow_find_label
    jnc .label_found
    mov ax, ERR_UNRESOLVED_LABEL
    call compiler_record_error
    ret
.label_found:
    mov [ds:WORK_TEMP_LABEL_ID], ax
    call control_flow_label_offset
    mov ax, [ds:bx + CF_LABEL_TARGET_INDEX]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jb .target_valid
    mov ax, ERR_INVALID_BRANCH_TARGET
    call compiler_record_error
    ret
.target_valid:
    mov [ds:WORK_TEMP_DEPTH], ax
    mov ax, [ds:WORK_TEMP_INDEX]
    call control_flow_instruction_offset
    mov dx, [ds:WORK_TEMP_DEPTH]
    mov [ds:bx + CF_INST_TARGET_INDEX], dx
.next:
    inc word [ds:WORK_TEMP_INDEX]
    jmp .next_instruction
.resolved:
    clc
    ret

; Menjalankan decode, resolusi label, dan analisis dataflow sebelum emission.
; Masukan: SI/remaining menunjuk payload setelah header tervalidasi.
; Keluaran: tabel instruksi/label terisi dan CFG tervalidasi.
control_flow_validate_program:
    mov word [ds:WORK_INSTRUCTION_COUNT], 0
    mov word [ds:WORK_LABEL_COUNT], 0
    mov word [ds:WORK_RELOCATION_COUNT], 0
    mov word [ds:WORK_STACK_DEPTH], 0
    mov word [ds:WORK_MAX_STACK_DEPTH], 0
    mov word [ds:WORK_STACK_ERROR], 0
    mov word [ds:WORK_REACHABLE_HALTS], 0
    mov byte [ds:WORK_IR_HALT_SEEN], 0
    call clear_local_init_bitmap
.decode:
    cmp word [ds:WORK_IR_REMAINING], 0
    je .missing_end
    mov ax, si
    mov [ds:WORK_CURRENT_IR_OFFSET], ax
    call ir_dispatch_opcode
    jc .failed
    cmp byte [ds:WORK_IR_END_SEEN], 1
    je .decode_end
    cmp byte [ds:WORK_CURRENT_OPCODE], IR_LABEL
    jne .add_instruction
    call control_flow_add_label
    jc .failed
    jmp .decode
.add_instruction:
    call control_flow_add_instruction
    jc .failed
    jmp .decode
.decode_end:
    cmp word [ds:WORK_INSTRUCTION_COUNT], 0
    jne .resolve
    mov ax, ERR_EMPTY_PROGRAM
    call compiler_record_error
    ret
.resolve:
    call control_flow_resolve_labels
    jc .failed
    call cfg_analyze_program
    ret
.missing_end:
    mov ax, ERR_MISSING_END
    call compiler_record_error
    ret
.failed:
    stc
    ret

; Mengatur alamat machine code untuk seluruh label yang menunjuk indeks tertentu.
; Masukan: WORK_CURRENT_INSTRUCTION dan DI menunjukkan indeks serta output saat ini.
control_flow_set_label_offsets:
    mov word [ds:WORK_TEMP_INDEX], 0
.next_label:
    mov ax, [ds:WORK_TEMP_INDEX]
    cmp ax, [ds:WORK_LABEL_COUNT]
    jae .done
    call control_flow_label_offset
    mov ax, [ds:bx + CF_LABEL_TARGET_INDEX]
    cmp ax, [ds:WORK_CURRENT_INSTRUCTION]
    jne .next
    mov [ds:bx + CF_LABEL_CODE_OFFSET], di
.next:
    inc word [ds:WORK_TEMP_INDEX]
    jmp .next_label
.done:
    ret

; Menghasilkan code dari tabel instruksi tervalidasi, bukan membaca ulang IR.
control_flow_generate_code:
    mov word [ds:WORK_CURRENT_INSTRUCTION], 0
.next_instruction:
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jae .end_instructions
    call control_flow_set_label_offsets
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov [ds:bx + CF_INST_CODE_OFFSET], di
    mov al, [ds:bx + CF_INST_OPCODE]
    mov [ds:WORK_CURRENT_OPCODE], al
    mov ax, [ds:bx + CF_INST_OPERAND]
    mov [ds:WORK_DECODED_OPERAND], ax
    mov ax, [ds:WORK_CURRENT_INSTRUCTION]
    call control_flow_instruction_offset
    mov si, bx
    add si, CF_INST_INIT_IN
    xor bx, bx
    mov cx, WORK_LOCAL_INIT_SIZE
.copy_bitmap:
    mov al, [ds:si]
    mov [ds:WORK_LOCAL_INIT_BITMAP + bx], al
    inc si
    inc bx
    loop .copy_bitmap
    call codegen_dispatch
    jc .failed
    inc word [ds:WORK_CURRENT_INSTRUCTION]
    jmp .next_instruction
.end_instructions:
    call control_flow_set_label_offsets
    call relocation_apply_all
    jc .failed
    call codegen_validate_generated_code
    ret
.failed:
    stc
    ret
