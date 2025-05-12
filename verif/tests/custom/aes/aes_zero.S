  .global main
main:
    li t1, 0x0000000000000000;
    li t2, 0x0000000000000000;
    aes_load_key x0, t1, t2;

    li t1, 0x0000000000000000;
    li t2, 0x0000000000000000;
    aes_load_data x0, t1, t2;

    aes_enc x0, x0, x0;

    nop;
    nop;
    nop;
    nop;
    

    aes_read_high s0, x0, x0;

    aes_read_low s1, x0, x0; 

    li a0, 0x0;

    jal exit;     