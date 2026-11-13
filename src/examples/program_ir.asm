; Header dan IR statis yang dibaca melalui CS:SI oleh compiler.
%ifndef IR_TEST_CASE
    %define IR_TEST_CASE 0
%endif

program_ir:
%if IR_TEST_CASE = 101
    db 'X', 'R', '1', '6'
%else
    db 'I', 'R', '1', '6'
%endif
%if IR_TEST_CASE = 102
    db IR_VERSION + 1
%else
    db IR_VERSION
%endif
%if IR_TEST_CASE = 103
    dw program_ir_end - program_ir_payload - 1
%else
    dw program_ir_end - program_ir_payload
%endif

program_ir_payload:
%if IR_TEST_CASE = 0
    db IR_ICONST
    dw 7
    db IR_ICONST
    dw 5
    db IR_ADD
    db IR_ICONST
    dw 3
    db IR_MUL
    db IR_HALT
    db IR_END
%else
    %include "tests/runtime/program-fixtures.asm"
%endif
program_ir_end:
