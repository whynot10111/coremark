PROG:=coremark
ARCH:=$(shell uname -m)

CC=/opt/wasi-sdk/bin/clang
CFLAGS=--target=wasm32-wasi -Os -g -flto
CFLAGS+=-Wl,--initial-memory=65536 -Wl,--max-memory=65536 -Wl,-zstack-size=1024 -Wl,--global-base=4096
CFLAGS+=-Iposix -I. -DFLAGS_STR="\"-Os -g -ftlo\""

all: $(PROG).wasm 

$(PROG).wasm: core_list_join.c core_main.c core_matrix.c core_state.c core_util.c posix/core_portme.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f *.o *.wasm *.wat *.aot *.s *.ll
