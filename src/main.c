#include "pff.h"

static FATFS fs;
static char rbuf[32];

extern unsigned char boot_base;
extern unsigned long boot_cluster_lbas[128];
extern unsigned char boot_cluster_size;
extern unsigned char boot_cluster_count;
extern unsigned short boot_load_address;
extern unsigned short boot_start_address;
extern unsigned char boot_file_sectors;
extern unsigned short boot_last_sector_used;

extern void sio_initialize();
extern void putc(char c);
extern void puts(const char* s);
extern void putln(const char* s);
extern char decode_hex_word(char* digits, unsigned short* word);
extern char encode_hex_nibble(char nibble);
extern void boot();

void put_hex_byte(char byte) {
	putc(encode_hex_nibble(byte >> 4));
	putc(encode_hex_nibble(byte));
}

void put_hex_word(unsigned short word) {
	put_hex_byte((char)(word >> 8));
	put_hex_byte((char)word);
}

int read_hex_field(unsigned short *word) {
	FRESULT res;
	unsigned int read;

	res = pf_read(rbuf, 5, &read);
	if (res || read != 5 || rbuf[4] != ':') {
		return 1;
	}
	return decode_hex_word(rbuf, word);
}

int read_boot_cfg(unsigned short *load, unsigned short *start, unsigned char **file) {
	FRESULT res;
	unsigned int read;
	char c;

	if (read_hex_field(load) || read_hex_field(start)) {
		return 1;
	}

	res = pf_read(rbuf, 31, &read);
	if (res || read == 0) {
		return 1;
	}
	rbuf[31] = '\0';

	for (read > 0; ; read--) {
		c = rbuf[read];
		if (c >= 0x21 && c <= 0x7e) {
			break;
		}
	}
	rbuf[read+1] = '\0';
	*file = rbuf;
	return 0;
}

int load_boot_image_clusters() {
	unsigned int count;

	if (pf_read_cluster_lbas(0, boot_cluster_lbas, 128, &count)) {
		return 1;
	}

	boot_cluster_size = fs.csize;
	boot_cluster_count = (unsigned char)count;
	return 0;
}

void main() {
	unsigned char *file;

	sio_initialize();

	putln("fload FAT32 bootloader v0.10");
	if (pf_mount(&fs)) {
		putln("failed to mount filesystem");
		return;
	}

	if (pf_open("boot.cfg") || read_boot_cfg(&boot_load_address, &boot_start_address, &file)) {
		putln("failed to load boot.cfg");
		return;
	}
	if (boot_load_address > (unsigned short)&boot_base) {
		putln("invalid load address");
		return;
	}

	puts("loading ");
	puts(file);
	puts(" at ");
	put_hex_word(boot_load_address);
	puts(" and booting from ");
	put_hex_word(boot_start_address);
	putln("...");
	if (pf_open(file)) {
		putln("failed to open boot image");
		return;
	}
	if (fs.fsize == 0) {
		putln("boot image is empty");
		return;
	}

	if (fs.fsize > (unsigned long)((unsigned short)&boot_base - boot_load_address)) {
		putln("boot image is too large");
		return;
	}
	boot_file_sectors = (char)((unsigned short)fs.fsize / 512);
	boot_last_sector_used = (unsigned short)fs.fsize % 512;
	if (boot_last_sector_used != 0) {
		boot_file_sectors++;
	}

	if (load_boot_image_clusters()) {
		putln("failed to read boot image");
		return;
	}

	__asm__ ("jp _boot");
}
