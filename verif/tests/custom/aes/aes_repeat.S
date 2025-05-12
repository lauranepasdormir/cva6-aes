.global main
main:
    li t1, 0xabcdefabcdefabcd
    li t2, 0x1234567812345678
    aes_load_key x0, t1, t2

    li t1, 0x1122334455667788
    li t2, 0x99aabbccddeeff00
    aes_load_data x0, t1, t2
    aes_enc x0, x0, x0
    nop
    nop
    nop
    aes_read_high s0, x0, x0
    aes_read_low  s1, x0, x0


    li t1, 0x1122334455667788
    li t2, 0x99aabbccddeeff00
    aes_load_data x0, t1, t2
    aes_enc x0, x0, x0

    nop
    nop
    nop

    aes_read_high a1, x0, x0
    aes_read_low  a2, x0, x0

    li a0, 0
    jal exit
