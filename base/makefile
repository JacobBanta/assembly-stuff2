projectName := base
all: ${projectName} 
	./${projectName}
${projectName}: ${projectName}.o GetKey.o delay.o
	ld ${projectName}.o GetKey.o delay.o -o ${projectName}
${projectName}.o: ${projectName}.asm
	nasm -f elf64 ${projectName}.asm -o ${projectName}.o
GetKey.o: GetKey.asm
	nasm -f elf64 GetKey.asm -o GetKey.o
delay.o: delay.asm
	nasm -f elf64 delay.asm -o delay.o
run:
	./${projectName}
