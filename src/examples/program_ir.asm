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
%elif IR_TEST_CASE = 21 || IR_TEST_CASE = 22 || IR_TEST_CASE = 23 || IR_TEST_CASE = 36 || IR_TEST_CASE = 37 || IR_TEST_CASE = 38
    %include "src/examples/variable_test_ir.asm"
%elif IR_TEST_CASE >= 24 && IR_TEST_CASE <= 35
    %include "src/examples/comparison_test_ir.asm"
%else
    %include "tests/runtime/program-fixtures.asm"
%endif
program_ir_end:
