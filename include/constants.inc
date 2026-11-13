; Konstanta dasar firmware Phase 00.
FIRMWARE_SEGMENT        equ 0xF000
STACK_SEGMENT           equ 0x5000
STACK_TOP               equ 0xFFFE
WORK_SEGMENT            equ 0x6000
OUTPUT_SEGMENT          equ 0x2000
OUTPUT_CAPACITY          equ 0x1000
RUNTIME_DATA_SEGMENT     equ 0x3000
RUNTIME_STACK_SEGMENT    equ 0x4000
RUNTIME_STACK_TOP        equ 0xFFFE
ROM_SIZE                equ 0x10000
RESET_VECTOR_OFFSET     equ 0xFFF0
IR_VERSION              equ 0x01
