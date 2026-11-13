; Menjalankan dua lintasan, memvalidasi stack, menghasilkan kode, lalu transfer kontrol.
; Masukan: stack compiler telah siap; CS menunjuk firmware dan IR statis.
; Keluaran: tidak kembali; status sukses disimpan sebelum far jump ke RAM keluaran.
; Register berubah: AX, CX, SI, DI, DS, ES, flag; BX/DX dipertahankan.
; Kesalahan: kegagalan pada tahap mana pun berhenti di compiler_error_loop.
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

    call codegen_init
    jnc .codegen_initialized
    jmp compiler_error_loop
.codegen_initialized:
    call runtime_emit_prologue
    jnc .prologue_emitted
    jmp compiler_error_loop
.prologue_emitted:
    call codegen_generate_program
    jnc .generated_code_valid
    jmp compiler_error_loop
.generated_code_valid:
    mov word [ds:WORK_STATUS], STATUS_SUCCESS
    mov word [ds:WORK_ERROR_CODE], ERR_SUCCESS
    jmp OUTPUT_SEGMENT:0
