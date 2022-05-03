AS=sdasz80
ASFLAGS=-plosgffw
CC=sdcc
CFLAGS=-mz80 --no-std-crt0 --max-allocs-per-node 200000

.PHONY: fload clean
fload: fload.bin

clean:
	rm -f fload.bin
	rm build/*

fload.bin: build/fload.hex
	../tools/ihex2bin <build/fload.hex >fload.bin

build/fload.hex: build/crt0.rel build/main.rel build/pff.rel build/diskio.rel build/puts.rel build/hex.rel build/sio.rel build/cf.rel build/boot.rel
	$(CC) $(CFLAGS) --code-loc 0xd200 --data-loc 0xf000 -o build/fload.hex $^

build/%.rel: %.c
	$(CC) $(CFLAGS) -o build/ -c $<

build/%.rel: %.asm
	cp $< build/
	cd build && $(AS) $(ASFLAGS) $<
