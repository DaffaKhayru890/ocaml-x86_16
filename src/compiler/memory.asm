; Menginisialisasi status compiler pada DS:WORK_* dan output pada ES:DI.
; Input: DS menunjuk work memory, ES menunjuk output buffer.
; Output: status running, error success, DI nol.
; Register berubah: DI, flag.
; Error: tidak ada.
compiler_initialize:
    mov word [ds:WORK_STATUS], STATUS_RUNNING
    mov word [ds:WORK_ERROR_CODE], ERR_SUCCESS
    mov word [ds:WORK_IR_REMAINING], 0
    mov byte [ds:WORK_CURRENT_OPCODE], 0
    mov byte [ds:WORK_RESERVED_07], 0
    mov word [ds:WORK_DECODED_COUNT], 0
    mov word [ds:WORK_EMIT_LENGTH], 0
    mov byte [ds:WORK_IR_VERSION], 0
    mov byte [ds:WORK_RESERVED_0D], 0
    mov word [ds:WORK_IR_PAYLOAD_LENGTH], 0
    mov byte [ds:WORK_IR_END_SEEN], 0
    mov byte [ds:WORK_OPERAND_SIZE], 0
    mov word [ds:WORK_DECODED_OPERAND], 0
    mov word [ds:WORK_IR_TOTAL_LENGTH], 0
    xor di, di
    ret

; Mencatat error pada work memory dan mengembalikan CF=1.
; Input: AX berisi kode error.
; Output: WORK_STATUS=ERROR, WORK_ERROR_CODE=AX, CF=1.
; Register berubah: flag; AX dipertahankan.
; Error: prosedur ini merupakan pencatatan error.
compiler_record_error:
    mov word [ds:WORK_STATUS], STATUS_ERROR
    mov word [ds:WORK_ERROR_CODE], ax
    stc
    ret

; Menghentikan CPU pada error loop yang dapat diperiksa melalui GDB.
; Input: status dan kode error sudah disimpan pada work memory.
; Output: tidak kembali.
; Register berubah: IF dibersihkan oleh CLI sebelum HLT.
; Error: loop ini hanya digunakan setelah kegagalan compiler.
compiler_error_loop:
    cli
.halt:
    hlt
    jmp .halt
