section .data
    left dq 13
    right dq 13

    ball_x dq 400	; 25 << 4
    ball_y dq 208	; 13 << 4
    ball_vel dq 16	; 1 << 4
    ball_dir dq 16

    char db " "

    ; ANSI escape sequence for clearing the screen
    CLEAR_SCREEN db "[2J"

    ; Length of the clear screen sequence
    CLEAR_SCREEN_LENGTH equ $ - CLEAR_SCREEN

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
    call draw_left_paddle
    call draw_right_paddle

    mov rdi, 2
    mov rsi, 2
    call cursor

    call main_loop

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
    call bot_move
    call ball_logic
    jmp main_loop
    ret

draw_ball:
    mov rdi, [ball_x]
    mov rcx, 4
    sar rdi, cl
    mov rsi, [ball_y]
    sar rsi, cl
    call cursor
    push '0'
    call print_char
    add rsp, 8
    ret

undraw_ball:
    mov rdi, [ball_x]
    mov rcx, 4
    sar rdi, cl
    mov rsi, [ball_y]
    sar rsi, cl
    call cursor
    push ' '
    call print_char
    add rsp, 8
    ret

move_ball:
    mov rax, [ball_y]
    add rax, [ball_vel]
    cmp rax, 400
    jge skip
    cmp rax, 31
    jle skip
    mov [ball_y], rax
    jmp next
  skip:
    mov rax, [ball_vel]
    neg rax
    mov [ball_vel], rax
  next:
    mov rax, [ball_x]
    add rax, [ball_dir]
    cmp rax, 32
    jle left_test
    cmp rax, 784
    jge right_test
    mov [ball_x], rax
    ret

left_test:
    mov rcx, 4
    mov rax, [ball_y]
    sar rax, cl
    dec rax
    cmp rax, [left]
    jg die
    add rax, 2
    cmp rax, [left]
    jl die
    je skip3
    dec rax
    cmp rax, [left]
    je skip4
    mov rax, [ball_vel]
    dec rax
    mov [ball_vel], rax
    jmp skip4
  skip3:
    mov rax, [ball_vel]
    inc rax
    mov [ball_vel], rax
  skip4:
    mov rdx, [ball_dir]
    neg rdx
    mov [ball_dir], rdx
    ret

right_test:
    mov rcx, 4
    mov rax, [ball_y]
    sar rax, cl
    dec rax
    cmp rax, [right]
    jg die
    add rax, 2
    cmp rax, [right]
    jl die
    je skip5
    dec rax
    cmp rax, [left]
    je skip6
    mov rax, [ball_vel]
    dec rax
    mov [ball_vel], rax
    jmp skip6
  skip5:
    mov rax, [ball_vel]
    inc rax
    mov [ball_vel], rax
  skip6:
    mov rdx, [ball_dir]
    neg rdx
    mov [ball_dir], rdx
    ret
 die:
    mov qword[ball_vel], 0
    mov qword[ball_dir], 0
    jmp exit

ball_logic:
    call undraw_ball
    call move_ball
    call draw_ball
    ret

player_move:
    mov rax, [rsp + 8]
    cmp rax, 0
    je zero
    push rax 
    call undraw_right_paddle
    pop rax
    mov rdx, 2
    mul rdx		; rax * rdx -> rax
    sub rax, 3
    add rax, [right]
    cmp rax, 24
    je redraw
    cmp rax, 2
    je redraw
    mov [right], rax
  redraw:
    call draw_right_paddle
  zero:
    ret

bot_move:
    call undraw_left_paddle
    mov rax, [ball_y]
    add rax, [ball_vel]
    mov rcx, 4
    sar rax, cl
    sub rax, [left]
    cmp rax, 0
    je zero2
    jl neg
    mov rax, 1
    jmp skip2
  neg:
    mov rax, -1
  skip2:
    add rax, [left]
    cmp rax, 24
    je zero2
    cmp rax, 2
    je zero2
    mov [left], rax
  zero2:
    call draw_left_paddle
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
    mov eax, 1      	; Print
    mov edi, 1
    mov esi, char
    mov edx, 1 		; Length of the string
    syscall
    ret

make_box:
    mov rsi, 0
    mov rdi, 0
    call cursor
    sub rsp, 8
    mov qword[rsp], '#'
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

    mov qword[rsp+8], 0
    ret

    up:
    mov qword[rsp+8], 1
    ret

    down:
    mov qword[rsp+8], 2
    ret

flush_inputs:
    call GetKey
    pop rax
    cmp rax, 0
    jne flush_inputs
    ret

draw_left_paddle:
    mov rax, [left]
    mov r8, rax
    mov r10, rax
    sub r10, 2
    inc r8
    push '|'
    loop7:
    mov rdi, 2
    mov rsi, r8
    call cursor
    call print_char
    dec r8
    cmp r8, r10
    jne loop7
    add rsp, 8
    ret

undraw_left_paddle:
    mov rax, [left]
    mov r8, rax
    mov r10, rax
    sub r10, 2
    inc r8
    push ' '
    loop9:
    mov rdi, 2
    mov rsi, r8
    call cursor
    call print_char
    dec r8
    cmp r8, r10
    jne loop9
    add rsp, 8
    ret

draw_right_paddle:
    mov rax, [right]
    mov r8, rax
    mov r10, rax
    sub r10, 2
    inc r8
    push '|'
    loop8:
    mov rdi, 49
    mov rsi, r8
    call cursor
    call print_char
    dec r8
    cmp r8, r10
    jne loop8
    add rsp, 8
    ret

undraw_right_paddle:
    mov rax, [right]
    mov r8, rax
    mov r10, rax
    sub r10, 2
    inc r8
    push ' '
    loop10:
    mov rdi, 49
    mov rsi, r8
    call cursor
    call print_char
    dec r8
    cmp r8, r10
    jne loop10
    add rsp, 8
    ret


