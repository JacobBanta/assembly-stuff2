all: files
	./files
files: files.asm
	nasm -felf64 files.asm -o files.o
	ld files.o -o files
