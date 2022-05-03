AS=sdasz80
ASFLAGS=-plosgffw
CC=sdcc
CFLAGS=-mz80 --no-std-crt0 --max-allocs-per-node 200000

.PHONY: clean hello
hello: hello.bin

clean:
	rm -f hello.bin
	rm build/*

hello.bin: build/hello.hex
	../tools/ihex2bin <build/hello.hex >hello.bin

build/hello.hex: build/crt0.rel build/hello.rel
	$(CC) $(CFLAGS) --code-loc 0x9000 --data-loc 0xa000 -o build/hello.hex $^

build/%.rel: %.c
	$(CC) $(CFLAGS) -o build/ -c $<

build/%.rel: %.asm
	cp $< build/
	cd build && $(AS) $(ASFLAGS) $<
