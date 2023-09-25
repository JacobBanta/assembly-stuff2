%macro str 2+
    %1: db %2
    %1len equ $ - %1
%endmacro
%macro print 1
    mov rax, 1
    mov rdi, 1
    mov rdx, %1len
    mov rsi, %1
    syscall
%endmacro
%macro printstr 1+
    jmp %%over
    str %%string, %1
    %%over:
    print %%string
%endmacro
section .data

section .text
    global _start

_start:
    printstr 27, "[2J"
  exit:
    ; Terminate the program
    mov eax, 60		; System call number for program exit
    xor edi, edi	; Exit status code (0)
    syscall



