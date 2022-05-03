#include <string.h>
#include "diskio.h"

extern char cf_sector[512];
extern void cf_initialize();
extern char cf_read_sector(unsigned long lba);

DSTATUS disk_initialize() {
	cf_initialize();
	return 0;
}

static unsigned long lastSector = 0xffff; // out-of-bounds LBA

DRESULT disk_readp(
	BYTE* buf,		/* Pointer to the destination object */
	DWORD sector,	/* Sector number (LBA) */
	UINT offset,	/* Offset in the sector */
	UINT count		/* Byte count (bit15:destination) */
) {
	if (lastSector != sector) {
		cf_read_sector(sector);
		lastSector = sector;
	}

	memcpy(buf, &cf_sector[offset], count);
	return RES_OK;
}
