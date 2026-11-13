; Tata letak writable state pada segment WORK_SEGMENT.
WORK_STATUS                 equ 0x0000
WORK_ERROR_CODE             equ 0x0002
WORK_IR_REMAINING            equ 0x0004
WORK_CURRENT_OPCODE          equ 0x0006
WORK_RESERVED_07             equ 0x0007
WORK_DECODED_COUNT           equ 0x0008
WORK_EMIT_LENGTH             equ 0x000A
WORK_IR_VERSION              equ 0x000C
WORK_RESERVED_0D             equ 0x000D
WORK_IR_PAYLOAD_LENGTH       equ 0x000E
WORK_IR_END_SEEN             equ 0x0010
WORK_OPERAND_SIZE            equ 0x0011
WORK_DECODED_OPERAND         equ 0x0012
WORK_IR_TOTAL_LENGTH         equ 0x0014
WORK_LAYOUT_END              equ 0x0016
