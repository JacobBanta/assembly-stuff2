section .data

    char db " "

    ; ANSI escape sequence for clearing the screen
    CLEAR_SCREEN db "[2J"

    ; Length of the clear screen sequence
    CLEAR_SCREEN_LENGTH equ $ - CLEAR_SCREEN

    length dq 3
    apple dq 11021
    dir dq 3

section .bss
    snake: resb 2208
section .text
    global _start
    extern GetKey
    extern Recanonize
    extern Decanonize
    extern delay

_start:
    call Decanonize

    call clear_screen
    call make_box
    call starting_position    

    mov rdi, 0
    mov rsi, 26
    call cursor

    ;call main_loop

    call input
    add rsp, 8

  exit:
    ; Terminate the program
    call Recanonize
    mov eax, 60		; System call number for program exit
    xor edi, edi	; Exit status code (0)
    syscall

main_loop:
    call delay
    call input
    call flush_inputs
    call player_move
    add rsp, 8
    jmp main_loop
    ret

player_move:
    ;call undraw_right_paddle
    mov rax, [rsp + 8]
    cmp rax, 0
    je zero
    mov rdx, 2
    mul rdx		; rax * rdx -> rax
    sub rax, 3
    ;add rax, [right]
    cmp rax, 24
    je zero
    cmp rax, 2
    je zero
    ;mov [right], rax
  zero:
    ;call draw_right_paddle
    ret

starting_position:
    mov byte[snake], 7
    mov byte[snake+1], 13
    mov byte[snake+2], 6
    mov byte[snake+3], 13
    mov byte[snake+4], 5
    mov byte[snake+5], 13
    mov rdi, 5
    mov rsi, 13
    call cursor
    push '-'
    call print_char
    mov rdi, 6
    mov rsi, 13
    call cursor
    call print_char
    mov rdi, 7
    mov rsi, 13
    call cursor
    push '*'
    call print_char
    add rsp, 16
    mov rdi, 43
    mov rsi, 13
    call cursor
    call print_apple
    ret

print_apple:
    call ANSI
    push "["
    call print_char
    push 31
    call print_num
    push "m"
    call print_char
    push "0"
    call print_char
    call ANSI
    push "["
    call print_char
    add rsp, 8
    call print_char
    add rsp, 8
    call print_char
    add rsp, 24
    ret

clear_screen:
    ; Write the ANSI escape sequence to clear the screen
    call ANSI
    mov eax, 1			; System call number for writing to stdout
    mov edi, 1			; File descriptor for stdout
    mov esi, CLEAR_SCREEN   	; Address of the clear screen sequence
    mov edx, CLEAR_SCREEN_LENGTH ; Length of the sequence
    syscall

ANSI:		; Just prints the escap character to start an ANSI character sequence
    sub rsp, 8
    mov qword[rsp], 27
    call print_char
    add rsp, 8
    ret

cursor:			; Sets the cursor position using ANSI. The x is in the rdi register and the y is in the rsi
    sub rsp, 8
    mov qword[rsp], rdi	; x
    sub rsp, 8
    mov qword[rsp], rsi	; y
    call ANSI
    sub rsp, 8
    mov qword[rsp], "["
    call print_char
    add rsp, 8
    call print_num
    mov qword[rsp], ";"
    call print_char
    add rsp, 8
    call print_num
    mov qword[rsp], 'H'
    call print_char
    add rsp, 8
    ret


print_num:			; This function loads individual digits onto the stack in reverse order, the prints them off individually.
; NOTE: this could be improved if it printed directly from the stack, but that seems too dangerous for me
    xor eax, eax
    xor ebx, ebx
    xor r9, r9
    mov eax, [rsp + 8]
    mov ebx, 10
    loop1:
    inc r9
    xor rdx, rdx                ; rdx register MUST to be cleared befor division
    div ebx                     ; divides eax(printed number) / ebx(10) with remainder going to dx
    add edx, 48                 ; converts raw value to ascii digit
    mov [rsp - 8], rdx
    sub rsp, 8
    cmp eax, 0
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
    mov rax, 1      	; Print
    mov rdi, 1
    mov rsi, char
    mov rdx, 1 		; Length of the string
    syscall
    ret

make_box:
    mov rsi, 0
    mov rdi, 0
    call cursor
    sub rsp, 8
    mov qword[rsp], '-'
    mov r8, 50
    loop3:
    call print_char
    dec r8
    cmp r8, 0
    jne loop3
    mov rsi, 25
    mov rdi, 0
    call cursor
    mov r8, 50
    loop4:
    call print_char
    dec r8
    cmp r8, 0
    jne loop4
    mov r8, 25
    mov qword[rsp], '|'
    loop5:
    ;rdi rsi
    mov rdi, 0
    mov rsi, r8
    call cursor
    call print_char
    dec r8
    cmp r8, 0
    jne loop5
    mov r8, 25
    loop6:
    mov rdi, 50
    mov rsi, r8
    call cursor
    call print_char
    dec r8
    cmp r8, 0
    jne loop6
    mov rdi, 1
    mov rsi, 1
    mov qword[rsp], '/'
    call cursor
    call print_char
    mov rdi, 50
    mov rsi, 25
    call cursor
    call print_char
    mov rdi, 50
    mov rsi, 0
    mov qword[rsp], '\'
    call cursor
    call print_char
    mov rdi, 0
    mov rsi, 25
    call cursor
    call print_char
    add rsp, 8
    ret

input:
    call GetKey
    pop rax
    push QWORD[rsp]

    cmp rax, 0x415B1B
    je up
    cmp rax, 0x425B1B
    je down
    cmp rax, 0x435B1B
    je right
    cmp rax, 0x445B1B
    je left

    mov rax, [dir]
    mov qword[rsp+8], rax
    ret

    up:
    mov qword[rsp+8], 1
    ret

    down:
    mov qword[rsp+8], 2
    ret

    right:
    mov qword[rsp+8], 3
    ret

    left:
    mov qword[rsp+8], 4
    ret

flush_inputs:
    call GetKey
    pop rax
    cmp rax, 0
    jne flush_inputs
    ret

