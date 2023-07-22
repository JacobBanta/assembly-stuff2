section .bss
    timeout: resq 16
section .text
    global delay

delay:
    push rcx
    mov qword[timeout+8], 200000000 ; nanoseconds
    ; Initialize file descriptor sets
    mov eax, 35; nanosleep syscall https://man7.org/linux/man-pages/man2/nanosleep.2.html
    mov rdi, timeout
    lea rsi, 0
    syscall
    pop rcx
    ret

