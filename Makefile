PROG:=coremark
ARCH:=$(shell uname -m)

ifeq ($(ARCH),x86_64)
WAMR_ARG=--disable-simd
endif
ifeq ($(ARCH), riscv64)
WAMR_ARG=--cpu=generic-rv64 --cpu-features=+a,+m,+f,+d,+c
endif

WAMR=/home/han/Project/wasm-micro-runtime
WAMRC=$(WAMR)/wamr-compiler/build/wamrc
LLC=llc -march=riscv64 -mcpu=generic-rv64 -mattr=+a,+m,+f,+d,+c
OBJDUMP=llvm-objdump
CC=/opt/wasi-sdk/bin/clang
CFLAGS=--target=wasm32-wasi -Os -g -flto
CFLAGS+=-Wl,--initial-memory=65536 -Wl,--max-memory=65536 -Wl,-zstack-size=1024 -Wl,--global-base=4096
CFLAGS+=-Iposix -I. -DFLAGS_STR="\"-Os -g -ftlo\""

all: $(PROG).wasm $(PROG).wat $(PROG).$(ARCH).aot $(PROG).$(ARCH).o $(PROG).$(ARCH).ll $(PROG).$(ARCH).opt.ll $(PROG).$(ARCH).opt.s $(PROG).$(ARCH).s

$(PROG).wasm: core_list_join.c core_main.c core_matrix.c core_state.c core_util.c posix/core_portme.c
	$(CC) $(CFLAGS) -o $@ $^

$(PROG).wat: $(PROG).wasm
	wasm-dis $^ > $@

$(PROG).$(ARCH).aot: $(PROG).wasm
	$(WAMRC) --target=$(ARCH) $(WAMR_ARG) --format=aot -o $@ $^

$(PROG).$(ARCH).o: $(PROG).wasm
	$(WAMRC) --target=$(ARCH) $(WAMR_ARG) --format=object -o $@ $^

$(PROG).$(ARCH).ll: $(PROG).wasm
	$(WAMRC) --target=$(ARCH) $(WAMR_ARG) --format=llvmir-unopt -o $@ $^

$(PROG).$(ARCH).opt.ll: $(PROG).wasm
	$(WAMRC) --target=$(ARCH) $(WAMR_ARG) --format=llvmir-opt -o $@ $^

$(PROG).$(ARCH).opt.s: $(PROG).$(ARCH).opt.ll
	$(LLC) $^

$(PROG).$(ARCH).s: $(PROG).$(ARCH).o
	$(OBJDUMP) -d --print-imm-hex $^ > $@

clean:
	rm -f *.o *.wasm *.wat *.aot *.s *.ll
