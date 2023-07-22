all: snake 
	./snake
snake: snake.o GetKey.o delay.o
	ld snake.o GetKey.o delay.o -o snake
snake.o: snake.asm
	nasm -f elf64 snake.asm -o snake.o
GetKey.o: GetKey.asm
	nasm -f elf64 GetKey.asm -o GetKey.o
delay.o: delay.asm
	nasm -f elf64 delay.asm -o delay.o
run:
	./snake
test: demo
	./demo
demo: demo.asm
	nasm -f elf64 demo.asm -o delay.o
	ld demo.o -o demo
