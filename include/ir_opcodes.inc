; Opcode IR yang dikenali dispatcher compiler.
IR_END          equ 0x00
IR_ICONST       equ 0x01
IR_LOAD_LOCAL   equ 0x02
IR_STORE_LOCAL  equ 0x03
IR_ADD          equ 0x10
IR_SUB          equ 0x11
IR_MUL          equ 0x12
IR_NEG          equ 0x13
IR_EQ           equ 0x20
IR_NE           equ 0x21
IR_LT           equ 0x22
IR_GT           equ 0x23
IR_LABEL        equ 0x30
IR_JMP          equ 0x31
IR_JZ           equ 0x32
IR_JNZ          equ 0x33
IR_HALT         equ 0x40
