lb64encode: b64encode.o
	ld -o b64encode b64encode.o
b64encode.o: b64encode.asm
	nasm -f elf64 -g -F stabs b64encode.asm
