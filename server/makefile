all: server

server: server.asm
	nasm -g -felf64 server.asm -o server.o
	ld server.o -o server
