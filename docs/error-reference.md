# Referensi kode error

Kode disimpan sebagai word pada `WORK_ERROR_CODE` di segment work `6000h`.
Sukses memakai `0000h`; status error adalah `FFFFh`. Semua nilai aktif unik.

| Kode | Konstanta | Arti |
|---:|---|---|
| `0000h` | `ERR_SUCCESS` | Tidak ada error |
| `0001h` | `ERR_INVALID_MAGIC` | Magic header IR tidak cocok |
| `0002h` | `ERR_INVALID_VERSION` | Versi IR tidak didukung |
| `0003h` | `ERR_INVALID_LENGTH` | Panjang header/payload tidak valid |
| `0004h` | `ERR_UNEXPECTED_EOF` | Operand terpotong atau input berakhir terlalu awal |
| `0005h` | `ERR_UNKNOWN_OPCODE` | Byte opcode tidak dikenal |
| `0006h` | `ERR_MISSING_END` | Terminator IR_END tidak ditemukan |
| `0007h` | `ERR_TRAILING_DATA` | Ada data setelah IR_END |
| `0008h` | `ERR_OUTPUT_OVERFLOW` | Primitive emitter melewati kapasitas |
| `0009h` | `ERR_EMITTER_TEST_FAILED` | Self-test emitter gagal |
| `000Ah` | `ERR_STACK_UNDERFLOW` | Operasi membutuhkan operand stack yang tidak tersedia |
| `000Bh` | `ERR_STACK_OVERFLOW` | Kedalaman virtual stack melebihi batas |
| `000Ch` | `ERR_INVALID_STACK_DEPTH` | Kedalaman pada akhir/HALT tidak valid |
| `000Dh` | `ERR_UNSUPPORTED_OPCODE` | Opcode valid tidak mempunyai generator |
| `000Eh` | `ERR_CODEGEN_FAILED` | Kode error lama; belum dihasilkan jalur aktif |
| `000Fh` | `ERR_RUNTIME_INVALID` | Validasi generated code/prologue gagal |
| `0010h` | `ERR_EMPTY_PROGRAM` | IR kosong atau tidak menghasilkan nilai terminal |
| `0011h` | `ERR_INVALID_IR_FLOW` | Kode error legacy; analisis CFG memakai kode khusus |
| `0012h` | `ERR_INVALID_LOCAL_SLOT` | Indeks local di luar rentang |
| `0013h` | `ERR_UNINITIALIZED_LOCAL` | Local dibaca sebelum definite assignment |
| `0014h` | `ERR_LOCAL_MEMORY_OVERFLOW` | Perhitungan akses melampaui area local |
| `0015h` | `ERR_BOOLEAN_GENERATION_FAILED` | Generator Boolean gagal |
| `0016h` | `ERR_COMPARISON_FAILED` | Opcode comparison tidak dapat dipetakan |
| `0017h` | `ERR_UNRESOLVED_LABEL` | ID label branch tidak didefinisikan |
| `0018h` | `ERR_DUPLICATE_LABEL` | ID label didefinisikan lebih dari sekali |
| `0019h` | `ERR_LABEL_TABLE_OVERFLOW` | Kapasitas label habis |
| `001Ah` | `ERR_RELOCATION_TABLE_OVERFLOW` | Kapasitas relocation habis |
| `001Bh` | `ERR_INVALID_BRANCH_TARGET` | Label tidak menunjuk instruksi executable |
| `001Ch` | `ERR_JUMP_DISPLACEMENT_RANGE` | rel16 tidak dapat direpresentasikan |
| `001Dh` | `ERR_CFG_STACK_MISMATCH` | Kedalaman stack predecessor berbeda di merge |
| `001Eh` | `ERR_CFG_INVALID_FALLTHROUGH` | Jalur reachable jatuh melewati akhir IR |
| `001Fh` | `ERR_INSTRUCTION_TABLE_OVERFLOW` | Kapasitas instruction table habis |
| `0020h` | `ERR_DATAFLOW_FAILURE` | Fixed-point dataflow tidak konvergen |
| `0021h` | `ERR_INVALID_CONTROL_FLOW` | Tidak ada terminal HALT reachable |
| `0022h` | `ERR_INVALID_RELOCATION` | Record relocation, target, atau patch tidak valid |

`000Eh` dan `0011h` dipertahankan untuk konsistensi kode sebelumnya; tidak
ada jalur aktif yang boleh mengklaimnya sebagai hasil tes. Batas kondisi yang
belum dapat dicapai oleh IR normal dijelaskan pada
[limitations.md](limitations.md).
