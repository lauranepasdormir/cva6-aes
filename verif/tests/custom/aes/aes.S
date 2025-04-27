.section .text
.global _start

_start:
    # Load AES Key (High 64-bit)
    li t1, 0x0011223344556677
    li t2, 0x8899aabbccddeeff
    aes_load_keyh x0, t1, t2

    # Load AES Key (Low 64-bit)
    li t1, 0x0001020304050607
    li t2, 0x08090a0b0c0d0e0f
    aes_load_keyl x0, t1, t2

    # Load Plaintext (High 64-bit)
    li t1, 0x6bc1bee22e409f96
    li t2, 0xe93d7e117393172a
    aes_load_datah x0, t1, t2

    # Load Plaintext (Low 64-bit)
    li t1, 0xae2d8a571e03ac9c
    li t2, 0x9eb76fac45af8e51
    aes_load_datal x0, t1, t2

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
