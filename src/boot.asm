	.globl _boot_base,_boot_cluster_lbas,_boot_cluster_size,_boot_cluster_count,_boot_load_address,_boot_start_address,_boot_file_sectors,_boot_last_sector_used,_boot

	.area _BOOT (ABS)
	.org 0xfc00

_boot_base:
	.ds 0

	; static unsigned long boot_cluster_lbas[16];
_boot_cluster_lbas:
	.ds 4 * 128
	; static unsigned char boot_cluster_size
_boot_cluster_size:
	.ds 1
	; static unsigned char boot_cluster_count
_boot_cluster_count:
	.ds 1
	; static unsigned short boot_load_address
_boot_load_address:
	.ds 2
	; static unsigned short boot_start_address
_boot_start_address:
	.ds 2
	; static unsigned char boot_file_sectors
_boot_file_sectors:
	.ds 1
	; static unsigned short boot_last_sector_used
_boot_last_sector_used:
	.ds 2

; CF registers
CF_DATA     .equ 0x10
CF_SECCOUNT .equ 0x12
CF_STATUS   .equ 0x17
CF_COMMAND  .equ 0x17
CF_LBA0     .equ 0x13
CF_LBA1     .equ 0x14
CF_LBA2     .equ 0x15
CF_LBA3     .equ 0x16

;CF Commands
CF_RD_SEC   .equ 0x20

_boot:
	ld sp, #4
	ld ix, #_boot_cluster_lbas
	ld hl, (_boot_load_address)
	ld a, (_boot_file_sectors)
	ld d, a
	ld c, #CF_DATA

1$:
	ld a, 0 (ix) ; load the next LBA into the card
	out (#CF_LBA0), a
	ld a, 1 (ix)
	out (#CF_LBA1), a
	ld a, 2 (ix)
	out (#CF_LBA2), a
	ld a, 3 (ix)
	and a, #0x04
	or a, #0xe0
	out (#CF_LBA3), a
	add ix, sp
	ld a, (_boot_cluster_size) ; load the cluster size into the card
	out (#CF_SECCOUNT), a
	ld a, #CF_RD_SEC
	out (#CF_COMMAND), a

6$:
	in a, (#CF_STATUS)    ; wait for the busy flag to drop
	bit 7, a
	jr nz, 6$
	in a, (#CF_STATUS)    ; wait for the ready flag to set
	bit 6, a
	jr z, 6$

2$:
	in a, (#CF_STATUS)    ; wait for data to become available
	bit 3, a
	jr z, 2$

	ld a, (_boot_cluster_size)
	ld e, a
3$:
	dec d                 ; are we loading the last sector?
	jr z, 4$

	ld b, #0              ; read the sector into the destination
	inir
	inir

	dec e
	jr nz, 3$
	jr 1$

4$:
	ld a, (_boot_last_sector_used + 1) ; if more than 256 bytes of the last sector are used, read the first 256 bytes.
	cp a, #0
	jr z, 5$
	inir
5$:
	ld a, (_boot_last_sector_used)
	ld b, a                            ; read the remaining data from the sector.
	inir

	ld sp, #0                          ; reset the stack to the top of RAM
	ld hl, (_boot_start_address)       ; load the start address and boot.
	jp (hl)
