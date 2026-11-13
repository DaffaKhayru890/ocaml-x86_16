.PHONY: all build run test clean

all: build

build:
	./scripts/build.sh

run: build
	./scripts/run-qemu.sh

test: build
	python3 tests/run_qemu_tests.py

clean:
	rm -f build/custom_rom.bin build/custom_rom.lst
