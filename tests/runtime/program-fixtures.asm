; Program dan payload rusak yang dipilih oleh IR_TEST_CASE pada pengujian.
%if IR_TEST_CASE = 1
    db IR_ICONST
    dw 42
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 2
    db IR_ICONST
    dw 10
    db IR_ICONST
    dw 20
    db IR_ADD
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 3
    db IR_ICONST
    dw 30
    db IR_ICONST
    dw 10
    db IR_SUB
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 4
    db IR_ICONST
    dw 7
    db IR_ICONST
    dw 6
    db IR_MUL
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 5
    db IR_ICONST
    dw 25
    db IR_NEG
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 6
    db IR_ICONST
    dw 0xFFF6
    db IR_ICONST
    dw 3
    db IR_ADD
    db IR_ICONST
    dw 2
    db IR_MUL
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 7
    db IR_ICONST
    dw 32767
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 8
    db IR_ICONST
    dw 0x8000
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 9
    db IR_ICONST
    dw 32767
    db IR_ICONST
    dw 1
    db IR_ADD
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 10
    db IR_ICONST
    dw 0x8000
    db IR_NEG
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 11
    db IR_ADD
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 12
    db IR_ICONST
    dw 1
    db IR_ICONST
    dw 2
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 13
    db IR_LOAD_LOCAL
    db 0
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 14
    db IR_ICONST
    dw 1
    db IR_HALT
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 15
    db IR_ICONST
    dw 1
    db IR_HALT
    db IR_ICONST
    dw 2
    db IR_END
%elif IR_TEST_CASE = 16
    db IR_END
%elif IR_TEST_CASE = 17
    times VIRTUAL_STACK_MAX_DEPTH + 1 db IR_ICONST, 0, 0
%elif IR_TEST_CASE = 18
    db IR_ICONST
    dw 5
    db IR_END
%elif IR_TEST_CASE = 19
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 20
    db IR_ICONST
    dw 1
    times 1024 db IR_NEG
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 104
    db IR_ICONST
    db 0x34
%elif IR_TEST_CASE = 105
    db 0x7F
    db IR_END
%elif IR_TEST_CASE = 106
    db IR_ICONST
    dw 1
%elif IR_TEST_CASE = 107
    db IR_END
    db IR_ADD
%elif IR_TEST_CASE = 108
    db IR_LOAD_LOCAL
    db 64
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 109
    db IR_ICONST
    dw 1
    db IR_STORE_LOCAL
    db 64
    db IR_ICONST
    dw 1
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 110
    db IR_STORE_LOCAL
    db 0
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 111
    db IR_ICONST
    dw 1
    db IR_EQ
    db IR_HALT
    db IR_END
%elif IR_TEST_CASE = 101 || IR_TEST_CASE = 102 || IR_TEST_CASE = 103
    db IR_END
%else
    %error "Nomor program uji tidak dikenal"
%endif
