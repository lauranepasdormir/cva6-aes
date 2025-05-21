  .global main
main:
    li t1, 0x0001020304050607;
    li t2, 0x08090a0b0c0d0e0f;
    aes_load_key a1, t1, t2;

    li t1, 0x0011223344556677;
    li t2, 0x8899aabbccddeeff;
    aes_load_data a2, t1, t2;

    aes_enc x0, x0, x0;

    nop;
    nop;
    nop;
    nop;

    aes_round a5, x0, x0;
    

    aes_read_high s0, x0, x0;

    aes_read_low s1, x0, x0; 

    li a0, 0x0;

    jal exit;     