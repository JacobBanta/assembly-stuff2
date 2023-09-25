projectName := macros
all: ${projectName} 
	./${projectName}
${projectName}: ${projectName}.o
	ld ${projectName}.o -o ${projectName}
${projectName}.o: ${projectName}.asm
	nasm -f elf64 ${projectName}.asm -o ${projectName}.o
run:
	./${projectName}
