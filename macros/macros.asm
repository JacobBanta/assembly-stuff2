%include "macros.mac"

section .data

section .text
    global _start
    extern break

_start:
    printstr 27, "[2J"
    mov rax, 0xc0ffee
    mov rdx, 0xFFFFFFFFFFFFFFFF
    call break
  exit:
    ; Terminate the program
    mov eax, 60		; System call number for program exit
    xor edi, edi	; Exit status code (0)
    syscall



