	.globl _decode_hex_byte,_decode_hex_word,_encode_hex_nibble

	.area _CODE

	; character in a
	; returns nibble in a; C is set for successful decode
decode_hex_nibble:
	sub #48
	jr c, 1$
	cp #10
	ret c
	sub #7
	cp #10
	jr c, 1$
	cp #16
	ret c
	sub #32
	cp #10
	jr c, 1$
	cp #16
	ret c
1$: ccf
	ret

	; hi character in a
	; lo character in l
	; clobbers h
	; returns byte in a, C is set for successful decode
decode_hex_byte:
	call decode_hex_nibble
	ret nc
	add a, a
	add a, a
	add a, a
	add a, a
	ld h, a
	ld a, l
	call decode_hex_nibble
	ret nc
	or a, h
	scf
	ret

	; uint8_t decode_hex_byte(uint8_t hi, uint8_t lo, uint8_t* byte)
_decode_hex_byte:
	push bc
	call decode_hex_byte
	jr nc, 1$
	push ix
	ld ix, #6
	add ix, sp
	ld h, 1 (ix)
	ld l, 0 (ix)
	ld (hl), a
	pop hl
	xor a, a
	pop bc
	ret
1$:
	ld a, #1
	pop bc
	ret

	; uint8_t decode_hex_word(uint8_t* digits, uint16_t* word)
_decode_hex_word:
	push ix
	ex de, hl
	ld ix, #0
	add ix, de
	ex de, hl
	ld a, 2 (ix)
	ld l, 3 (ix)
	call decode_hex_byte
	jr nc, 1$
	ld (de), a
	ld a, 0 (ix)
	ld l, 1 (ix)
	call decode_hex_byte
	jr nc, 1$
	inc de
	ld (de), a
	xor a, a
	pop ix
	ret
1$:
	ld a, #1
	pop ix
	ret

	; uint8_t encode_hex_nibble(uint8_t nibble)
_encode_hex_nibble:
	and #0x0f
	cp #10
	jr c, 1$
    add #7
1$:	add #48
	ret
