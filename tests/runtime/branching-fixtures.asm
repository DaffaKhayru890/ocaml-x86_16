; Program kontrol alur untuk menguji label, jump, merge, dan analisis dataflow.
%if IR_TEST_CASE = 40
    db IR_JMP
    dw 2
    db IR_ICONST
    dw 99
    db IR_LABEL
    dw 2
    db IR_ICONST
    dw 42
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 41
    db IR_ICONST
    dw 3
    db IR_STORE_LOCAL
    db 0
    db IR_LABEL
    dw 1
    db IR_LOAD_LOCAL
    db 0
    db IR_ICONST
    dw 1
    db IR_SUB
    db IR_STORE_LOCAL
    db 0
    db IR_LOAD_LOCAL
    db 0
    db IR_JNZ
    dw 1
    db IR_ICONST
    dw 42
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 42
    db IR_ICONST
    dw 0
    db IR_JZ
    dw 1
    db IR_ICONST
    dw 111
    db IR_JMP
    dw 2
    db IR_LABEL
    dw 1
    db IR_ICONST
    dw 42
    db IR_LABEL
    dw 2
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 43
    db IR_ICONST
    dw 1
    db IR_JNZ
    dw 1
    db IR_ICONST
    dw 100
    db IR_JMP
    dw 2
    db IR_LABEL
    dw 1
    db IR_ICONST
    dw 55
    db IR_LABEL
    dw 2
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 44
    db IR_ICONST
    dw 1
    db IR_JZ
    dw 1
    db IR_ICONST
    dw 2
    db IR_LABEL
    dw 1
    db IR_ICONST
    dw 3
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 45
    db IR_JMP
    dw 99
    db IR_ICONST
    dw 1
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 46
    db IR_LABEL
    dw 1
    db IR_ICONST
    dw 1
    db IR_LABEL
    dw 1
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 47
    db IR_JMP
    dw 1
    db IR_HALT
    db IR_LABEL
    dw 1
    db IR_END
%elif IR_TEST_CASE = 48
    db IR_ICONST
    dw 1
    db IR_JZ
    dw 1
    db IR_ICONST
    dw 5
    db IR_STORE_LOCAL
    db 0
    db IR_JMP
    dw 2
    db IR_LABEL
    dw 1
    db IR_LABEL
    dw 2
    db IR_LOAD_LOCAL
    db 0
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 49
    db IR_ICONST
    dw 0
    db IR_JZ
    dw 1
    db IR_ICONST
    dw 10
    db IR_HALT
    db IR_LABEL
    dw 1
    db IR_ICONST
    dw 20
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 50
    db IR_ICONST
    dw 1
    db IR_HALT
    db IR_LOAD_LOCAL
    db 0
    db IR_END
%elif IR_TEST_CASE = 51
    %rep 129
        db IR_JMP
        dw 1
    %endrep
    db IR_LABEL
    dw 1
    db IR_ICONST
    dw 1
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 52
    %assign test_label 0
    %rep 65
        db IR_LABEL
        dw test_label
        %assign test_label test_label + 1
    %endrep
    db IR_ICONST
    dw 1
    db IR_HALT
    db IR_END
%endif
