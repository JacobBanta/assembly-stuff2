all: pong 
	./pong
pong: pong.o GetKey.o delay.o
	ld pong.o GetKey.o delay.o -o pong
pong.o: pong.asm
	nasm -f elf64 pong.asm -o pong.o
GetKey.o: GetKey.asm
	nasm -f elf64 GetKey.asm -o GetKey.o
delay.o: delay.asm
	nasm -f elf64 delay.asm -o delay.o
run:
	./pong
