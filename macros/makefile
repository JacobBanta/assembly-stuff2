projectName := macros
all: ${projectName} 
	./${projectName}
${projectName}: ${projectName}.o GetKey.o debug.o
	ld ${projectName}.o GetKey.o debug.o -o ${projectName}
${projectName}.o: ${projectName}.asm
	nasm -f elf64 ${projectName}.asm -o ${projectName}.o
GetKey.o: GetKey.asm
	nasm -f elf64 GetKey.asm -o GetKey.o
debug.o: debug.asm
	nasm -f elf64 debug.asm -o debug.o
run:
	./${projectName}
