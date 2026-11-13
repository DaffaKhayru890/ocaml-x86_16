; Payload alternatif untuk pengujian error reader dan dispatcher.
%if IR_TEST_CASE = 1 || IR_TEST_CASE = 2 || IR_TEST_CASE = 3
    db IR_END
%elif IR_TEST_CASE = 4
    db IR_ICONST
    db 0x34
%elif IR_TEST_CASE = 5
    db 0x7F
    db IR_END
%elif IR_TEST_CASE = 6
    db IR_ADD
%elif IR_TEST_CASE = 7
    db IR_END
    db IR_ADD
%else
    %error "Nomor fixture IR tidak dikenal"
%endif
