section .data

    char db " "

    ; ANSI escape sequence for clearing the screen
    CLEAR_SCREEN db "[2J"

    ; Length of the clear screen sequence
    CLEAR_SCREEN_LENGTH equ $ - CLEAR_SCREEN

    len dq 3
    apple dw 3371
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

    call main_loop

    ;mov rdi, 0
    ;mov rsi, 26
    ;call cursor

  exit:
    mov rsi, 26
    xor rdi, rdi
    call cursor
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
    call print_score
    jmp main_loop
    ret

player_move:
    call undraw_tail
    call undraw_head
    call shift
    mov rax, [rsp+8]
    mov [dir], rax
    cmp rax, 1
    je up3
    cmp rax, 2
    je down3
    cmp rax, 3
    je right3
    jmp left3
  up3:
    dec byte[snake+1]
    call draw_head
    call check_bounds
    ret
  down3:
    inc byte[snake+1]
    call draw_head
    call check_bounds
    ret
  right3:
    inc byte[snake]
    call draw_head
    call check_bounds
    ret
  left3:
    dec byte[snake]
    call draw_head
    call check_bounds
    ret

shift:
    mov rax, [len]
    add rax, rax
    and al, 248
    add rax, 10
  loop7:
    sub rax, 10
    mov rdx, [snake + rax]
    add rax, 2
    mov [snake+rax], rdx
    cmp rax, 2
    jne loop7
    ret

check_bounds:
    xor rdi, rdi
    xor rsi, rsi
    mov dil, [snake]
    mov sil, [snake+1]
    cmp rdi, 50
    je exit
    cmp rdi, 1
    je exit
    cmp rsi, 25
    je exit
    cmp rsi, 1
    je exit
    cmp dil, [apple]
    jne skip
    cmp sil, [apple+1]
    jne skip
    inc qword[len]
    call generate_apple
  skip:
    call check_tail
    ret

check_tail:
    mov rax, [len]
    inc rax
    add rax, rax
  loop8:
    sub rax, 2
    mov di, [snake]
    mov si, [snake+rax]
    cmp si, di
    je exit
    cmp rax, 2
    jne loop8
    ret

generate_apple:
    lea rdi, apple
    mov rsi, 2
    mov rdx, 0
    mov rax, 318
    syscall
    cmp byte[apple], 1
    jle generate_apple
    cmp byte[apple], 50
    jge generate_apple 
    cmp byte[apple+1], 1
    jle generate_apple
    cmp byte[apple+1], 25
    jge generate_apple
    mov rax, len
    inc rax
    add rax, rax
  tail_loop:
    cmp rax, 0
    jne tail_loop_end
    sub rax,2
    lea rdx, [snake+rax]
    mov sil, [apple]
    mov dil, [apple+1]
    cmp sil, [rdx]
    jne tail_loop
    cmp dil, [rdx+1]
    jne tail_loop
    jmp generate_apple
  tail_loop_end:
    xor rsi, rsi
    xor rdi, rdi 
    mov dil, [apple]
    mov sil, [apple+1]
    call cursor
    call print_apple
    ret

draw_head:
    xor rdi, rdi
    xor rsi, rsi
    mov dil, [snake]
    mov sil, [snake+1]
    call cursor
    push '*'
    call print_char
    add rsp, 8
    ret

undraw_tail:
    mov rax, [len]
    dec rax
    add rax, rax
    xor rdi, rdi
    xor rsi, rsi
    mov dil, byte[snake + rax]
    inc rax
    mov sil, byte[snake + rax]
    call cursor
    push " "
    call print_char
    add rsp, 8
    ret

undraw_head:
    xor rdi, rdi
    xor rsi, rsi
    mov dil, [snake]
    mov sil, [snake+1]
    call cursor
    mov rax, [dir]
    mov rdx, [rsp+16]
    cmp rax, rdx
    je same
    cmp rax, 1
    je up2
    cmp rax, 2
    je down2
    cmp rax, 3
    je right2
    cmp rax, 4
    je left2

  forward:
    push "/"
    call print_char
    add rsp, 8
    ret
  backward:
    push '\'
    call print_char
    add rsp, 8
    ret
  up2:
    cmp rdx, 3
    je forward
    jmp backward

  down2:
    cmp rdx, 3
    je backward
    jmp forward

  right2:
    cmp rdx, 1
    je forward
    jmp backward

  left2:
    cmp rdx, 1
    je backward
    jmp forward

  same:
    cmp rax, 2
    jg greater
    push "|"
    call print_char
    add rsp, 8
    ret
  greater:
    push "-"
    call print_char
    add rsp, 8
    ret

print_score:
    mov rdi, 51
    xor rsi, rsi
    call cursor
    mov rax, [len] 
    sub rax, 3
    push rax
    call print_num
    pop rax
    xor rdi, rdi
    xor rsi, rsi
    call cursor
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
    mov rax, 1			; System call number for writing to stdout
    mov rdi, 1			; File descriptor for stdout
    mov rsi, CLEAR_SCREEN   	; Address of the clear screen sequence
    mov rdx, CLEAR_SCREEN_LENGTH ; Length of the sequence
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

  fail:
    mov rdx, [dir]
    mov qword[rsp+8], rdx
    ret

    up:
    cmp qword[dir], 2
    je fail
    mov qword[rsp+8], 1
    ret

    down:
    cmp qword[dir], 1
    je fail
    mov qword[rsp+8], 2
    ret

    right:
    cmp qword[dir], 4
    je fail
    mov qword[rsp+8], 3
    ret

    left:
    cmp qword[dir], 3
    je fail
    mov qword[rsp+8], 4
    ret

flush_inputs:
    call GetKey
    pop rax
    cmp rax, 0
    jne flush_inputs
    ret

