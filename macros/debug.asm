%include "macros.mac"
section .data
    char: db 0
section .text
global break
extern Decanonize
extern GetKey_b
extern Restore
break:
    push rbp
    mov rbp, rsp
    pusha
    printstr 27, "[0;0H|---|-----------------------|--------------------|", 10, "|rax|"
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|rbx|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|rcx|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|rdx|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|rsi|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|rdi|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|r8 |"
    pop rax
    sub rbp, 16
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|r9 |"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|r10|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|r11|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|r12|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|r13|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|r14|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|r15|"
    pop rax
    sub rbp, 8
    push qword[rbp]
    call print_hex
    printstr 27,"[1D|"
    call print_num
    printstr 27, "[50G|", 10, "|---|-----------------------|--------------------|"
    pop rax
    call Decanonize
    back:
    call GetKey_b
    pop rax
    cmp rax, 10
    jne back
    call Restore
    popa
    pop rbp
    ret


print_hex:
    xor rax, rax
    xor rbx, rbx
    xor r9, r9
    mov rax, [rsp + 8]
    mov rbx, 16
    loop1h:
    inc r9
    xor rdx, rdx
    div rbx
    cmp rdx, 10
    jge skip1
    add rdx, 48
    jmp skip2
    skip1:
    add rdx, 87
    skip2:
    push rdx
    cmp rax, 0
    jg loop1h
    cmp r9, 16
    je loop2h
    loop3h:
    inc r9
    push '0'
    cmp r9, 16
    jl loop3h
    loop2h:
    call print_char
    add rsp, 8
    call print_char
    push ' '
    call print_char
    add rsp, 16
    sub r9, 2
    cmp r9, 0
    jg loop2h
    ret

print_num:                      ; This function loads individual digits onto the stack in reverse order, the prints them off individually.
    xor rax, rax
    xor rbx, rbx
    xor r9, r9
    mov rax, [rsp + 8]
    mov rbx, 10
    loop1:
    inc r9
    xor rdx, rdx                ; rdx register MUST to be cleared befor division
    div rbx                     ; divides eax(printed number) / ebx(10) with remainder going to dx
    add rdx, 48                 ; converts raw value to ascii digit
    mov [rsp - 8], rdx
    sub rsp, 8
    cmp rax, 0
    jg loop1
    loop2:
    call print_char
    add rsp, 8
    dec r9
    cmp r9, 0
    jg loop2
    ret

print_char:
    mov al, [rsp + 8]
    mov [char], al
    mov rax, 1          ; Print
    mov rdi, 1
    mov rsi, char
    mov rdx, 1          ; Length of the string
    syscall
    ret
