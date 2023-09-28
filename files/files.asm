%include "../macros/macros.mac"
%include "../macros/files.mac"
section .text
global _start
_start:
    open FILE, "file.txt", O_RDONLY
    cmp qword[FILE], 0
    jl error
    open FILE2, "file2.txt", O_RDWR | O_CREAT, 384
    buffer BUFFER, 100
    read FILE, BUFFER
    write FILE2, BUFFER
    close FILE
    close FILE2
    printstr "data copied from file.txt to file2.txt", 10
  exit:
    mov rax, 60
    mov rdi, 0
    syscall

error:
    printstr "file.txt not found", 10
    jmp exit
