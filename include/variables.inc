; Konstanta area slot variabel lokal pada segment data runtime.
LOCAL_SLOT_BASE          equ 0x0002
LOCAL_SLOT_SIZE          equ 2
MAX_LOCAL_SLOTS          equ 64
LOCAL_SLOT_END           equ LOCAL_SLOT_BASE + (MAX_LOCAL_SLOTS * LOCAL_SLOT_SIZE)
