; Header dan static IR yang dibaca melalui CS:SI pada Phase 01.
%ifndef IR_TEST_CASE
    %define IR_TEST_CASE 0
%endif

program_ir:
%if IR_TEST_CASE = 1
    db 'X', 'R', '1', '6'
%else
    db 'I', 'R', '1', '6'
%endif
%if IR_TEST_CASE = 2
    db IR_VERSION + 1
%else
    db IR_VERSION
%endif
%if IR_TEST_CASE = 3
    dw program_ir_end - program_ir_payload - 1
%else
    dw program_ir_end - program_ir_payload
%endif

program_ir_payload:
%if IR_TEST_CASE = 0
    db IR_ICONST
    dw 42
    db IR_STORE_LOCAL
    db 0
    db IR_LOAD_LOCAL
    db 0
    db IR_ICONST
    dw 10
    db IR_ADD
    db IR_SUB
    db IR_MUL
    db IR_NEG
    db IR_EQ
    db IR_NE
    db IR_LT
    db IR_GT
    db IR_LABEL
    dw 1
    db IR_JMP
    dw 1
    db IR_JZ
    dw 1
    db IR_JNZ
    dw 1
    db IR_HALT
    db IR_END
%else
    %include "tests/ir/ir_fixtures.asm"
%endif
program_ir_end:
