BITS 16
ORG 0

%include "include/constants.inc"
%include "include/memory_map.inc"
%include "include/firmware.inc"

%include "src/boot/reset.asm"
%include "src/boot/initialization.asm"
%include "src/boot/main.asm"
%include "src/boot/reset_vector.asm"
