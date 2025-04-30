  .global main
main:
    li t1, 0x0011223344556677;
    li t2, 0x8899aabbccddeeff;
    aes_load_key x0, t1, t2;

    li t1, 0x6bc1bee22e409f96;
    li t2, 0xe93d7e117393172a;
    aes_load_data x0, t1, t2;

    aes_enc x0, x0, x0;

    aes_read_high a0, x0, x0;

    aes_read_low a1, x0, x0; 

     li a0, 0x0;

    jal exit;         