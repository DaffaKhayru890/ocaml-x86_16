; Membuat far jump dengan pasangan segment:offset pada reset vector.
%macro FIRMWARE_FAR_JUMP 2
    jmp %1:%2
%endmacro
