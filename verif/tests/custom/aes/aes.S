.section .text
.global main

main:
    # Load AES Key
    li t1, 0x0011223344556677
    li t2, 0x8899aabbccddeeff
    aes_load_key x0, t1, t2


    # Load Plaintext
    li t1, 0x6bc1bee22e409f96
    li t2, 0xe93d7e117393172a
    aes_load_data x0, t1, t2

    # Start AES Encryption
    aes_enc x0, x0, x0

    # Wait for encryption
    nop
    nop
    nop

    # Read ciphertext result
    aes_read_high a0, x0, x0  # High
    aes_read_low a1, x0, x0  # Low

    jal exit           # Provided by syscalls.c
