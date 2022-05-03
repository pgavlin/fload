.PHONY: all fload example clean

all: fload example

fload: tools/ihex2bin
	$(MAKE) -C ./src

example: tools/ihex2bin
	$(MAKE) -C ./example

tools/ihex2bin: tools/go.mod tools/cmd/ihex2bin/main.go
	cd tools && go build ./cmd/ihex2bin
