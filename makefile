encode: encode.o
	ld -o encode encode.o
encode.o: encode.asm
	nasm -f elf64 -g -F stabs encode.asm
