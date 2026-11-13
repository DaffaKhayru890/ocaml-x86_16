; Program statis untuk menguji penyimpanan dan pemuatan slot lokal.
%if IR_TEST_CASE = 21
    db IR_ICONST
    dw 10
    db IR_STORE_LOCAL
    db 0
    db IR_LOAD_LOCAL
    db 0
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 22
    db IR_ICONST
    dw 10
    db IR_STORE_LOCAL
    db 0
    db IR_ICONST
    dw 20
    db IR_STORE_LOCAL
    db 1
    db IR_LOAD_LOCAL
    db 0
    db IR_LOAD_LOCAL
    db 1
    db IR_ADD
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 23
    db IR_ICONST
    dw 10
    db IR_STORE_LOCAL
    db 0
    db IR_ICONST
    dw 25
    db IR_STORE_LOCAL
    db 0
    db IR_LOAD_LOCAL
    db 0
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 36
    db IR_ICONST
    dw 10
    db IR_STORE_LOCAL
    db 0
    db IR_ICONST
    dw 20
    db IR_STORE_LOCAL
    db 1
    db IR_LOAD_LOCAL
    db 0
    db IR_LOAD_LOCAL
    db 1
    db IR_LT
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 37
    db IR_ICONST
    dw 7
    db IR_STORE_LOCAL
    db 0
    db IR_ICONST
    dw 5
    db IR_STORE_LOCAL
    db 1
    db IR_ICONST
    dw 3
    db IR_STORE_LOCAL
    db 2
    db IR_LOAD_LOCAL
    db 0
    db IR_LOAD_LOCAL
    db 1
    db IR_ADD
    db IR_LOAD_LOCAL
    db 2
    db IR_MUL
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 38
    db IR_ICONST
    dw 77
    db IR_STORE_LOCAL
    db 63
    db IR_LOAD_LOCAL
    db 63
    db IR_HALT
    db IR_END
%endif
