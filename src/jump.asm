	.area _CODE
	.globl _jump

	; void jump(unsigned short)
_jump:
	pop de
	jp (hl)
