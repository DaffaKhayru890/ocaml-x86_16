# Generator jump 8086

## Pengantar dan tujuan

8086 mendukung JMP near rel16, tetapi conditional jump hanya memiliki
displacement pendek. Karena itu JZ/JNZ tidak boleh diterjemahkan sebagai
encoding `0F 84/85` yang baru tersedia pada prosesor lebih baru. Modul ini
membuat conditional trampoline yang seluruhnya kompatibel dengan 8086.

## Hubungan, register, dan memori

`jump_codegen.asm` dipanggil oleh `codegen_dispatch`, menggunakan emitter
`ES:DI` pada output segment `2000h`, serta mendaftarkan displacement ke
`relocation.asm`. `WORK_DECODED_OPERAND` berisi ID label dan
`WORK_CURRENT_PATCH_OFFSET` menyimpan offset word rel16.

## Encoding dan alur prosedur

- JMP: emit `E9 00 00`, simpan offset dua byte kosong, lalu panggil
  `relocation_add`.
- JZ: emit `58 85 C0 75 03 E9 00 00`. `POP AX; TEST AX,AX` mengambil kondisi;
  `JNZ +3` melewati JMP ketika nilai bukan nol.
- JNZ: emit `58 85 C0 74 03 E9 00 00`. `JZ +3` melewati JMP ketika nilai nol.

Setiap conditional branch mengonsumsi satu word dari virtual stack. Pass
dataflow telah memvalidasi kondisi sebelum codegen. `CODEGEN_EMIT8/16`
menangani overflow; setelah E9 dan word placeholder ditulis, relocation
mengisi displacement akhir. Semua register kerja dapat berubah kecuali
segment DS/ES.

## Build dan debugging

Jalankan `make test`. Case 42 memeriksa JZ, case 43 memeriksa JNZ, dan case 49
memiliki dua HALT reachable. Inspeksi bytes menggunakan
`xp /64bx 0x20000`; displacement dihitung dari IP sesudah word placeholder.
