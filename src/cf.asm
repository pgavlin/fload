; Based on code by Stephen C Cousins and Grant Searle. 
; http://searle.hostei.com/grant/index.html

	.globl _cf_initialize,_cf_read_sector,_cf_sector

	.area _CODE

; CF registers
CF_DATA     .equ 0x10
CF_FEATURES .equ 0x11
CF_ERROR    .equ 0x11
CF_SECCOUNT .equ 0x12
CF_SECTOR   .equ 0x13
CF_CYL_LOW  .equ 0x14
CF_CYL_HI   .equ 0x15
CF_HEAD     .equ 0x16
CF_STATUS   .equ 0x17
CF_COMMAND  .equ 0x17
CF_LBA0     .equ 0x13
CF_LBA1     .equ 0x14
CF_LBA2     .equ 0x15
CF_LBA3     .equ 0x16

;CF Features
CF_8BIT     .equ 1
CF_NOCACHE  .equ 0x82
;CF Commands
CF_RD_SEC   .equ 0x20
CF_WR_SEC   .equ 0x30
CF_SET_FEAT .equ 0xEF

	; void cf_initialize()
_cf_initialize:
	push af
	call cf_wait
	ld a, #CF_8BIT        ; configure the card for 8-bit IDE
	out (#CF_FEATURES), a
	ld a, #CF_SET_FEAT
	out (#CF_COMMAND), a
	call cf_wait
	ld a, #CF_NOCACHE     ; disable the card's write cache
	out (#CF_FEATURES), a
	ld a, #CF_SET_FEAT
	out (#CF_COMMAND), a
	call cf_wait
	pop af
	ret

	; uint8_t cf_read_sector(uint32_t lba)
	;
	; lba is in hlde
_cf_read_sector:
	push bc

	ld a, e               ; load the LBA into the card
	out (#CF_LBA0), a
	ld a, d
	out (#CF_LBA1), a
	ld a, l
	out (#CF_LBA2), a
	ld a, h
	and a, #0x04
	or a, #0xe0
	out (#CF_LBA3), a
	ld a, #1
	out (#CF_SECCOUNT), a ; read a single sector
	ld a, #CF_RD_SEC
	out (#CF_COMMAND), a
	call cf_wait
	
1$:
	in a, (#CF_STATUS)    ; wait for data to become available
	bit 3, a
	jr z, 1$

	ld hl, #_cf_sector    ; copy data into the sector buffer
	ld c, #CF_DATA
	ld b, #0
	inir
	ld b, #0
	inir

	xor a
	pop bc
	ret

cf_wait:
	in a, (#CF_STATUS)    ; wait for the busy flag to drop
	bit 7, a
	jr nz, cf_wait
	in a, (#CF_STATUS)    ; wait for the ready flag to set
	bit 6, a
	jr z, cf_wait
	ret

	.area _BSS
_cf_sector:
	.blkb 512
