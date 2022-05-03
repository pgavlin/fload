	.globl _putc,_puts,_putln

	.area _CODE

	; void putc(char c)
	;
	; Writes c to SIOA. Translates LF to CR LF.
_putc:
	cp #0x0a
	jp nz, _sio_putc
putnl:
	ld a, #0x0d
	call _sio_putc
	ld a, #0x0a
	jp _sio_putc

	; void puts(char* s)
	;
	; Writes the string pointed to by s to SIOA.
_puts:
	push af
	call puts
	pop af

	; Writes the string in hl to SIOA. Clobbers a.
puts:
	ld a, (hl)
	cp #0
	ret z
	call _putc
	inc hl
	jr puts

	; void putln(char *s)
	;
	; Writes the string pointed to by s to SIOA followed by a newline.
_putln:
	push af
	call puts
	call putnl
	pop af
	ret
