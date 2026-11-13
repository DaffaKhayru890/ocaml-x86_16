; Status compiler dan kode error yang disimpan pada work memory.
STATUS_IDLE                 equ 0x0000
STATUS_RUNNING              equ 0x0001
STATUS_SUCCESS              equ 0x0002
STATUS_ERROR                equ 0xFFFF

ERR_SUCCESS                 equ 0x0000
ERR_INVALID_MAGIC           equ 0x0001
ERR_INVALID_VERSION         equ 0x0002
ERR_INVALID_LENGTH          equ 0x0003
ERR_UNEXPECTED_EOF          equ 0x0004
ERR_UNKNOWN_OPCODE          equ 0x0005
ERR_MISSING_END             equ 0x0006
ERR_TRAILING_DATA           equ 0x0007
ERR_OUTPUT_OVERFLOW         equ 0x0008
ERR_EMITTER_TEST_FAILED     equ 0x0009
