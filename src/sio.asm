	.globl _sio_initialize,_sio_putc

	.area _CODE

SIOA_C .equ 0x80
SIOA_D .equ 0x81
SIO_TX_RDY .equ 2

_sio_initialize:
	push bc
	push hl
	ld c, #SIOA_C
	ld hl, #sio_init_data
	ld b, #sio_init_data_end - #sio_init_data
	otir
	pop hl
	pop bc
	ret

	; character to write is in a
_sio_putc:
	push af
1$:
	in a, (#SIOA_C)
	bit #SIO_TX_RDY, a
	jr z, 1$
	pop af
	out (#SIOA_D), a
	ret

sio_init_data:
	.db 0b00011000 ; Wr0 Channel Reset
	.db 0b00010100 ; Wr0 Pointer R4 + reset ex st int
	.db 0b11000100 ; Wr4 /64, async mode, no parity
	.db 0b00000011 ; Wr0 Pointer R3
	.db 0b11000001 ; Wr3 Receive enable, 8 bit 
	.db 0b00000101 ; Wr0 Pointer R5
	.db 0b11101010 ; Wr5 Transmit enable, 8 bit, flow ctrl
	.db 0b00010001 ; Wr0 Pointer R1 + reset ex st int
	.db 0b00000000 ; Wr1 No Tx interrupts
sio_init_data_end:
