; Batas tabel dan posisi field untuk instruksi, label, dan relocation.
MAX_IR_INSTRUCTIONS     equ 256
MAX_IR_LABELS           equ 64
MAX_IR_RELOCATIONS      equ 128
MAX_CFG_ITERATIONS      equ 0x1000

CF_INSTRUCTION_TABLE    equ 0x0100
CF_INSTRUCTION_SIZE     equ 19
CF_INST_OPCODE          equ 0
CF_INST_OPERAND         equ 1
CF_INST_SOURCE_OFFSET   equ 3
CF_INST_TARGET_INDEX    equ 5
CF_INST_CODE_OFFSET     equ 7
CF_INST_STACK_IN        equ 9
CF_INST_INIT_IN         equ 11

CF_LABEL_TABLE          equ 0x1400
CF_LABEL_SIZE           equ 7
CF_LABEL_ID             equ 0
CF_LABEL_TARGET_INDEX   equ 2
CF_LABEL_CODE_OFFSET    equ 4
CF_LABEL_FLAGS          equ 6

CF_RELOCATION_TABLE     equ 0x1600
CF_RELOCATION_SIZE      equ 6
CF_RELOC_LABEL_INDEX    equ 0
CF_RELOC_PATCH_OFFSET   equ 2
CF_RELOC_SOURCE_INDEX   equ 4
CF_LABEL_DEFINED        equ 0x01
