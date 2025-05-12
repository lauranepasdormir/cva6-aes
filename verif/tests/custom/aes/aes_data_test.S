  .global main
main:
    li t1, 0xdeadbeefcafebabe;
    li t2, 0xfacefeed12345678;
    aes_load_key x0, t1, t2;

    li t1, 0x0123456789abcdef;
    li t2, 0xfedcba9876543210;
    aes_load_data x0, t1, t2;

    aes_enc x0, x0, x0;

    nop;
    nop;
    nop;
    nop;
    

    aes_read_high s0, x0, x0;

    aes_read_low s1, x0, x0; 

    li t1, 0x1111111122222222
    li t2, 0x3333333344444444
    aes_load_data x0, t1, t2
    aes_enc x0, x0, x0

    nop;
    nop;
    nop;
    nop;
    
    aes_read_high a1, x0, x0
    aes_read_low  a2, x0, x0

    li a0, 0x0;

    jal exit;     