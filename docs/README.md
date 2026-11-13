# Indeks dokumentasi

Dokumentasi ini mencakup firmware Phase 00, compiler IR Assembly Phase 01–04,
serta integrasi, validasi, dan regresi Phase 05. Proyek tetap merupakan
compiler IR bare-metal kecil, bukan compiler OCaml lengkap. Mulai dari
[README proyek](../README.md).

## Firmware dan alamat

- [Arsitektur sistem](architecture.md)
- [Urutan boot](boot-process.md)
- [Reset vector dan pemetaan QEMU](reset-vector.md)
- [Segment register](segment-registers.md)
- [Peta memori](memory-map.md)
- [Debugging QEMU dan GDB](qemu-debugging.md)

## Compiler dan generated code

- [Arsitektur compiler](compiler-architecture.md)
- [Spesifikasi IR](ir-specification.md)
- [Referensi machine code](machine-code-reference.md)
- [Validasi machine code](../src/compiler/machine-code-validation-readme.md)
- [Code generation](code-generation.md)
- [Emitter dan output buffer](machine-code-emitter.md), [output buffer](output-buffer.md)
- [Stack machine](stack-machine.md), [arithmetic](arithmetic.md),
  [comparison](comparison.md), dan [local variables](local-variables.md)
- [Runtime](runtime.md) dan [boolean](boolean-representation.md)
- [Reader](ir-reader.md) dan [dispatcher](ir-dispatch.md)

## CFG, relocation, dan analisis

- [Control-flow table](../src/compiler/control-flow-readme.md)
- [CFG](../src/compiler/cfg-readme.md)
- [Dataflow dan definite assignment](../src/compiler/dataflow-readme.md)
- [Relocation](../src/compiler/relocation-readme.md)
- [Branch codegen](../src/compiler/jump-codegen-readme.md)

## Build, tes, error, dan limitasi

- [Pengujian](testing.md)
- [Manifest regresi](regression-testing.md)
- [Referensi kode error](error-reference.md)
- [Batasan](limitations.md)
- [README pengujian](../tests/README.md)
- [Debugging compiler/runtime](debugging.md)
