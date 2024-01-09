SRC := $(wildcard xdp/*.c)

OBJ := $(patsubst %.c,%.o,$(SRC))

all: $(OBJ)

xdp/%.o: xdp/%.c
	clang -mcpu=v3 -g -O2 -Wall -Werror -D__TARGET_ARCH_x86 -idirafter /usr/lib/llvm-14/lib/clang/14.0.0/include -idirafter /usr/local/include -idirafter /usr/include/x86_64-linux-gnu -idirafter /usr/include -Ixdp/include -c -target bpf $< -o $@
