.PHONY: all build run test test-gdb test-runtime test-codegen test-arithmetic test-variables test-control-flow test-errors test-ir-errors test-emitter clean

all: build

build:
	./scripts/build.sh

run: build
	./scripts/run-qemu.sh

test:
	./scripts/test.sh --suite all

test-gdb:
	./scripts/test-gdb.sh

test-runtime:
	./scripts/test.sh --suite runtime

test-codegen:
	./scripts/test.sh --suite codegen

test-arithmetic:
	./scripts/test.sh --suite arithmetic

test-variables:
	./scripts/test.sh --suite variables

test-control-flow:
	./scripts/test.sh --suite control-flow

test-errors:
	./scripts/test.sh --suite errors

test-ir-errors:
	./scripts/test.sh --suite ir-errors

test-emitter:
	./scripts/test.sh --suite emitter

clean:
	rm -f build/custom_rom.bin build/custom_rom.lst
