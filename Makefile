.PHONY: all build run clean

all: build

build:
	./scripts/build.sh

run: build
	./scripts/run-qemu.sh

clean:
	rm -f build/custom_rom.bin
