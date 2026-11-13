; Batas compile-time dan macro pengiriman nilai ke primitive emitter.
VIRTUAL_STACK_MAX_DEPTH      equ 0x3FFF

%macro CODEGEN_EMIT8 1
    mov al, %1
    call emit8
    jnc %%emitted
    ret
%%emitted:
%endmacro

%macro CODEGEN_EMIT16 1
    mov ax, %1
    call emit16
    jnc %%emitted
    ret
%%emitted:
%endmacro
