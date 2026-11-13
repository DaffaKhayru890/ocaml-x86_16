; Program statis untuk menguji comparison dan hasil Boolean.
%if IR_TEST_CASE = 24
    db IR_ICONST
    dw 10
    db IR_ICONST
    dw 10
    db IR_EQ
%elif IR_TEST_CASE = 25
    db IR_ICONST
    dw 10
    db IR_ICONST
    dw 20
    db IR_EQ
%elif IR_TEST_CASE = 26
    db IR_ICONST
    dw 10
    db IR_ICONST
    dw 20
    db IR_NE
%elif IR_TEST_CASE = 27
    db IR_ICONST
    dw 10
    db IR_ICONST
    dw 10
    db IR_NE
%elif IR_TEST_CASE = 28
    db IR_ICONST
    dw 10
    db IR_ICONST
    dw 20
    db IR_LT
%elif IR_TEST_CASE = 29
    db IR_ICONST
    dw 20
    db IR_ICONST
    dw 10
    db IR_LT
%elif IR_TEST_CASE = 30
    db IR_ICONST
    dw -5
    db IR_ICONST
    dw 3
    db IR_LT
%elif IR_TEST_CASE = 31
    db IR_ICONST
    dw 3
    db IR_ICONST
    dw -5
    db IR_LT
%elif IR_TEST_CASE = 32
    db IR_ICONST
    dw 20
    db IR_ICONST
    dw 10
    db IR_GT
%elif IR_TEST_CASE = 33
    db IR_ICONST
    dw 10
    db IR_ICONST
    dw 20
    db IR_GT
%elif IR_TEST_CASE = 34
    db IR_ICONST
    dw 5
    db IR_ICONST
    dw -5
    db IR_GT
%elif IR_TEST_CASE = 35
    db IR_ICONST
    dw -5
    db IR_ICONST
    dw 5
    db IR_GT
%endif
    db IR_HALT
    db IR_END
