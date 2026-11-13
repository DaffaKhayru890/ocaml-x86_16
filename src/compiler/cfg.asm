; CFG direpresentasikan oleh target branch dalam tabel instruksi dan fallthrough.
; Prosedur ini menyiapkan state entry lalu meminta analisis fixed-point.

; Menginisialisasi state setiap node dan memulai propagasi dari instruksi pertama.
cfg_analyze_program:
    mov word [ds:WORK_TEMP_INDEX], 0
.clear_states:
    mov ax, [ds:WORK_TEMP_INDEX]
    cmp ax, [ds:WORK_INSTRUCTION_COUNT]
    jae .states_cleared
    call control_flow_instruction_offset
    mov word [ds:bx + CF_INST_STACK_IN], 0xFFFF
    mov word [ds:bx + CF_INST_INIT_IN], 0
    mov word [ds:bx + CF_INST_INIT_IN + 2], 0
    mov word [ds:bx + CF_INST_INIT_IN + 4], 0
    mov word [ds:bx + CF_INST_INIT_IN + 6], 0
    inc word [ds:WORK_TEMP_INDEX]
    jmp .clear_states
.states_cleared:
    mov ax, 0
    call control_flow_instruction_offset
    mov word [ds:bx + CF_INST_STACK_IN], 0
    mov word [ds:WORK_CFG_ITERATIONS], 0
    call dataflow_fixed_point
    ret
