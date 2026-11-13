; Menghasilkan prologue yang menyiapkan DS dan stack program hasil.
; Masukan: ES menunjuk buffer keluaran; DS masih menunjuk memori kerja compiler.
; Keluaran: prologue 14 byte berada di ES:0000; flag prologue bernilai satu.
; Register berubah: AX, DI, flag; register lain dipertahankan.
; Kesalahan: overflow emitter menghentikan prosedur dengan CF=1.
; Alur: CLI, set DS=3000h, set SS=4000h, lalu set SP=FFFEh.
runtime_emit_prologue:
    CODEGEN_EMIT8 MC_CLI
    CODEGEN_EMIT8 MC_MOV_AX_IMM16
    CODEGEN_EMIT16 RUNTIME_DATA_SEGMENT
    CODEGEN_EMIT8 MC_MOV_DS_AX
    CODEGEN_EMIT8 MC_MODRM_MOV_DS_AX
    CODEGEN_EMIT8 MC_MOV_AX_IMM16
    CODEGEN_EMIT16 RUNTIME_STACK_SEGMENT
    CODEGEN_EMIT8 MC_MOV_SS_AX
    CODEGEN_EMIT8 MC_MODRM_MOV_SS_AX
    CODEGEN_EMIT8 MC_MOV_SP_IMM16
    CODEGEN_EMIT16 RUNTIME_STACK_TOP
    mov byte [ds:WORK_CODEGEN_PROLOGUE_EMITTED], 1
    clc
    ret

; Menghasilkan pengambilan hasil, penyimpanan DS:0000, dan loop HLT.
; Masukan: ES:DI menunjuk akhir kode; stack program berisi satu word hasil.
; Keluaran: tujuh byte halt ditambahkan dan penanda halt diatur.
; Register berubah: AX, DI, flag; register lain dipertahankan.
; Kesalahan: overflow emitter menghentikan prosedur dengan CF=1.
; Alur: POP AX, MOV [0000h],AX, HLT, lalu JMP pendek kembali tiga byte.
runtime_emit_halt:
    CODEGEN_EMIT8 MC_POP_AX
    CODEGEN_EMIT8 MC_MOV_MOFFS_AX
    CODEGEN_EMIT16 0
    CODEGEN_EMIT8 MC_HLT
    CODEGEN_EMIT8 MC_JMP_SHORT
    CODEGEN_EMIT8 MC_JMP_SHORT_BACK_3
    mov byte [ds:WORK_CODEGEN_HALT_EMITTED], 1
    clc
    ret
