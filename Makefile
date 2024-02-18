
all: rgb

run: rgb
	./rgb

bench: rgb-bench
	perf stat -e instructions,cycles \
		-e uops_dispatched_port.port_0 \
		-e uops_dispatched_port.port_1 \
		-e uops_dispatched_port.port_5 \
		./rgb-bench

rgb: rgb.c rgb.asm
	nasm -felf64 rgb.asm && gcc -o rgb -no-pie rgb.c rgb.o

rgb-bench: rgb.c rgb.asm
	nasm -felf64 rgb.asm && gcc -DBENCH -o rgb-bench -no-pie rgb.c rgb.o
