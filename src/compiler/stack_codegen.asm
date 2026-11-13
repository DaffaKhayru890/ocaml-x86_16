; Mencatat error stack/control-flow dari analisis dataflow.
; Masukan: AX berisi kode error stack atau CFG.
; Keluaran: WORK_STACK_ERROR dan WORK_ERROR_CODE berisi kode; CF=1.
; Register berubah: flag; AX dipertahankan.
; Kesalahan: prosedur ini merupakan pencatatan error.
codegen_record_stack_error:
    mov word [ds:WORK_STACK_ERROR], ax
    call compiler_record_error
    ret
