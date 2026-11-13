# Dispatcher dan validasi instruksi IR

## Konsep dan fungsi

Dispatcher mengenali satu opcode, menentukan ukuran operand, membaca
operand, dan memperbarui penghitung decode. Ia tidak membuat machine code.
`control_flow_validate_program` menggunakan dispatcher untuk membangun
instruction table dan label table, kemudian me-resolve target.

## Prosedur

- `ir_dispatch_opcode` mengambil opcode melalui reader, menyimpannya di
  `WORK_CURRENT_OPCODE`, lalu memanggil validator.
- `ir_validate_instruction` memeriksa daftar opcode yang diizinkan. ICONST
  dan opcode kontrol alur/label membaca word; LOAD_LOCAL dan STORE_LOCAL
  membaca byte; opcode aritmetika, perbandingan, serta HALT tidak memiliki
  operand.
- `ir_validate_program` meneruskan ke decode/tabel/CFG validation. Label
  dihitung sebagai IR record dispatcher tetapi tidak menempati instruction
  table executable.

Operand hasil parse disimpan di `WORK_DECODED_OPERAND` dan panjangnya di
`WORK_OPERAND_SIZE`. Jumlah instruksi tidak menghitung IR_END.

## Register dan error

SI/remaining dikelola reader. AX menampung operand word atau kode error; CX
dipakai reader untuk pemeriksaan panjang. Semua status/error berada di DS
(`6000h`). CF=1 mengembalikan error ke `compiler_main`, yang menghentikan CPU
pada `compiler_error_loop`. Opcode asing, EOF, payload tanpa END, dan byte
setelah END memiliki kode error berbeda.

## Build dan debugging

`make test` menjalankan opcode valid, branch dan label, serta fixture opcode
asing, operand terpotong, END hilang, data setelah END, dan target invalid. Periksa
`WORK_CURRENT_OPCODE`, `WORK_DECODED_COUNT`, `WORK_IR_END_SEEN`, dan kode
error di work memory.
