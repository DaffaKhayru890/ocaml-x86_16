; Menjalankan validasi IR lalu self-test emitter yang tidak terhubung ke IR.
; Input: stack telah disiapkan oleh firmware; CS menunjuk ROM firmware.
; Output: WORK_STATUS=SUCCESS jika kedua jalur pengujian selesai.
; Register berubah: AX, CX, SI, DI, DS, ES, flag; BX/DX dipertahankan.
; Error: kegagalan reader, dispatcher, atau emitter berakhir pada error loop.
compiler_main:
    mov ax, WORK_SEGMENT
    mov ds, ax
    mov ax, OUTPUT_SEGMENT
    mov es, ax
    call compiler_initialize

    call ir_init
    call ir_validate_header
    jnc .header_valid
    jmp compiler_error_loop
.header_valid:
    call ir_validate_program
    jnc .program_valid
    jmp compiler_error_loop
.program_valid:

    call emitter_self_test
    jnc .emitter_valid
    jmp compiler_error_loop
.emitter_valid:

    mov word [ds:WORK_STATUS], STATUS_SUCCESS
    mov word [ds:WORK_ERROR_CODE], ERR_SUCCESS
    ret
