; Menghasilkan encoding MOV AX,imm16 dan PUSH AX untuk IR_ICONST.
; Masukan: WORK_DECODED_OPERAND berisi nilai 16-bit.
; Keluaran: empat byte masuk ke buffer keluaran; CF=0 jika berhasil.
; Register berubah: AX, DI, flag; register lain dipertahankan.
; Kesalahan: overflow emitter diteruskan tanpa melanjutkan instruksi.
; Alur: tulis opcode MOV, immediate little-endian, lalu opcode PUSH.
codegen_iconst:
    CODEGEN_EMIT8 MC_MOV_AX_IMM16
    CODEGEN_EMIT16 [ds:WORK_DECODED_OPERAND]
    CODEGEN_EMIT8 MC_PUSH_AX
    clc
    ret

; Menghasilkan POP BX, POP AX, ADD AX,BX, dan PUSH AX.
; Masukan: stack virtual memiliki minimal dua nilai.
; Keluaran: lima byte operasi penjumlahan masuk ke buffer keluaran.
; Register berubah: AX, DI, flag; register lain dipertahankan.
; Kesalahan: overflow emitter dikembalikan melalui CF.
; Alur: ambil operand kanan ke BX, kiri ke AX, jumlahkan, lalu simpan hasil.
codegen_add:
    CODEGEN_EMIT8 MC_POP_BX
    CODEGEN_EMIT8 MC_POP_AX
    CODEGEN_EMIT8 MC_ADD_AX_BX
    CODEGEN_EMIT8 MC_MODRM_ADD_AX_BX
    CODEGEN_EMIT8 MC_PUSH_AX
    clc
    ret

; Menghasilkan POP BX, POP AX, SUB AX,BX, dan PUSH AX.
; Masukan: stack virtual memiliki minimal dua nilai.
; Keluaran: lima byte operasi pengurangan kiri dikurangi kanan masuk ke buffer.
; Register berubah: AX, DI, flag; register lain dipertahankan.
; Kesalahan: overflow emitter dikembalikan melalui CF.
; Alur: BX menerima operand kanan, AX menerima kiri, lalu hitung kiri dikurangi kanan.
codegen_sub:
    CODEGEN_EMIT8 MC_POP_BX
    CODEGEN_EMIT8 MC_POP_AX
    CODEGEN_EMIT8 MC_SUB_AX_BX
    CODEGEN_EMIT8 MC_MODRM_SUB_AX_BX
    CODEGEN_EMIT8 MC_PUSH_AX
    clc
    ret

; Menghasilkan POP BX, POP AX, IMUL BX, dan PUSH AX.
; Masukan: stack virtual memiliki minimal dua nilai bertanda 16-bit.
; Keluaran: lima byte perkalian masuk ke buffer keluaran.
; Register berubah: AX, DI, flag; register lain dipertahankan.
; Kesalahan: overflow emitter dikembalikan melalui CF.
; Alur: IMUL menaruh hasil 32-bit di DX:AX; hanya bagian rendah AX disimpan.
codegen_mul:
    CODEGEN_EMIT8 MC_POP_BX
    CODEGEN_EMIT8 MC_POP_AX
    CODEGEN_EMIT8 MC_IMUL_BX
    CODEGEN_EMIT8 MC_MODRM_IMUL_BX
    CODEGEN_EMIT8 MC_PUSH_AX
    clc
    ret

; Menghasilkan POP AX, NEG AX, dan PUSH AX.
; Masukan: stack virtual memiliki minimal satu nilai.
; Keluaran: empat byte negasi komplemen-dua masuk ke buffer keluaran.
; Register berubah: AX, DI, flag.
; Kesalahan: overflow emitter dikembalikan melalui CF.
; Alur: negasikan word teratas; nilai 8000h tetap 8000h secara modulo 16-bit.
codegen_neg:
    CODEGEN_EMIT8 MC_POP_AX
    CODEGEN_EMIT8 MC_NEG_AX
    CODEGEN_EMIT8 MC_MODRM_NEG_AX
    CODEGEN_EMIT8 MC_PUSH_AX
    clc
    ret

; Mengalihkan IR_HALT ke pembuat sequence penyimpan hasil.
; Masukan: validasi stack memastikan tepat satu nilai berada di stack virtual.
; Keluaran: urutan instruksi halt program ditambahkan; CF=0 jika berhasil.
; Register berubah: AX, DI, flag.
; Kesalahan: kegagalan emitter diteruskan melalui CF.
; Alur: kode saat jalan mengambil hasil, menyimpan ke DS:0000, lalu berhenti.
codegen_halt:
    call runtime_emit_halt
    ret
