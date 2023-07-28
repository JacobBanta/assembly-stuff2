section .data
    height equ 26
    width equ 32

    x dq 4
    y dq 0

    draw dq 0
    undraw dq 0

    char db " "

    ; ANSI escape sequence for clearing the screen
    CLEAR_SCREEN db "[2J"

    ; Length of the clear screen sequence
    CLEAR_SCREEN_LENGTH equ $ - CLEAR_SCREEN

    unknown_text db "unknown address"
    unknown_len equ $ - unknown_text

section .bss
    board: resb 240

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

    lea rax, [print_o]
    lea rdx, [unprint_o]
    mov [draw], rax
    mov [undraw], rdx

    call main_loop

  exit:
    mov rdi, 0
    mov rsi, height+1
    call cursor
    ; Terminate the program
    call Recanonize
    mov eax, 60		; System call number for program exit
    xor edi, edi	; Exit status code (0)
    syscall

  unknown:
    mov rax, 1
    mov rdi, 1
    mov rsi, unknown_text
    mov rdx, unknown_len
    syscall
    jmp exit

main_loop:
    call delay
    call input
    call flush_inputs
    call player_move
    add rsp, 8
    jmp main_loop
    ret

player_move:
    mov rdi, [x]
    mov rsi, [y]
    call [undraw]
    call attempt_move
    mov rdi, [x]
    mov rsi, [y]
    call [draw]
    ret

land:
    mov rdi, [x]
    mov rsi, [y]
    call [draw]
    mov qword[y], 0
    mov qword[x], 4
    ret

attempt_move:
    mov rax, [draw]
    cmp rax, print_o
    je am_o
    jmp unknown
  am_o:
    mov rax, [y]
    mov rdx, 10
    mul rdx
    add rax, [x]
    lea rdx, [board+rax]
    cmp qword[rsp+16], 4
    jne skip_o
    cmp qword[x], 0
    je skip_o
    cmp byte[rdx-1], 0
    jne skip_o
    cmp byte[rdx+9], 0
    jne skip_o
    dec qword[x]
  skip_o:
    cmp qword[rsp+16], 3
    jne skip_o2
    cmp qword[x], 8
    je skip_o2
    cmp byte[rdx+2], 0
    jne skip_o2
    cmp byte[rdx+12], 0
    jne skip_o2
    inc qword[x]
  skip_o2:
    mov rax, [y]
    mov rdx, 10
    mul rdx
    add rax, [x]
    lea rdx, [board+rax]
    cmp byte[rdx+20], 0
    jne place
    cmp byte[rdx+21], 0
    jne place
    inc qword[y]
    cmp qword[y], 22
    je place
    ret

place:
    mov rax, [y]
    mov rdx, 10
    mul rdx
    add rax, [x]
    lea rdx, [board+rax]
    mov rax, [draw]
    cmp rax, print_o
    je place_o
    jmp unknown
  place_o:
    mov byte[rdx], 1
    mov byte[rdx+1], 1
    mov byte[rdx+10], 1
    mov byte[rdx+11], 1
    jmp land
    

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

print_o:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 103
    call color
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_i_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 106
    call color
    call print_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call print_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

print_i_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    call cursor
    push 106
    call color
    call print_piece
    call print_piece
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_s_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    add rdi, 3
    call cursor
    push 102
    call color
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_s_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 102
    call color
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    push rdi
    push rsi
    call cursor
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    add rdi, 3
    call cursor
    call print_piece
    push 0
    call color
    ret

print_z_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 101
    call color
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    add rdi, 3
    inc rsi
    call cursor
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_z_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    add rdi, 3
    call cursor
    push 101
    call color
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    push rdi
    push rsi
    call cursor
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

print_j_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 5
    push rdi
    push rsi
    call cursor
    push 104
    call color
    call print_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call print_piece
    pop rsi
    pop rdi
    sub rdi, 3
    inc rsi
    call cursor
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_j_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 104
    call color
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_j_3:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 104
    call color
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

print_j_4:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 104
    call color
    call print_piece
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    add rdi, 6
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

print_l_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 208
    call background_256
    call print_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_l_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 208
    call background_256
    call print_piece
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

print_l_3:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 208
    call background_256
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    add rdi, 3
    push rdi
    inc rsi
    push rsi
    call cursor
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

print_l_4:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    add rdi, 6
    call cursor
    push 208
    call background_256
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_t_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 105
    call color
    call print_piece
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    add rdi, 3
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

print_t_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 5
    push rdi
    push rsi
    call cursor
    push 105
    call color
    call print_piece
    pop rsi
    pop rdi
    push rdi
    push rsi
    sub rdi, 3
    inc rsi
    call cursor
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

print_t_3:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    add rdi, 3
    push 105
    call color
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    call print_piece
    call print_piece
    push 0
    call color
    ret

print_t_4:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    push 105
    call color
    call print_piece
    pop rsi
    pop rdi
    push rdi
    push rsi
    inc rsi
    call cursor
    call print_piece
    call print_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call print_piece
    push 0
    call color
    ret

unprint_o:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    ret

unprint_i_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    ret

unprint_i_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    call cursor
    call unprint_piece
    call unprint_piece
    call unprint_piece
    call unprint_piece
    ret

unprint_s_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    add rdi, 3
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    ret

unprint_s_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    add rdi, 3
    call cursor
    call unprint_piece
    ret

unprint_z_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    add rdi, 3
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    ret

unprint_z_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    add rdi, 3
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    ret

unprint_j_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 5
    push rdi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    sub rdi, 3
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    ret

unprint_j_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    call unprint_piece
    ret

unprint_j_3:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    ret

unprint_j_4:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    add rdi, 6
    inc rsi
    call cursor
    call unprint_piece
    ret

unprint_l_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    push rdi
    inc rsi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    ret

unprint_l_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    ret

unprint_l_3:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    add rdi, 3
    push rdi
    inc rsi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    ret

unprint_l_4:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    add rdi, 6
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    call unprint_piece
    ret

unprint_t_1:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    add rdi, 3
    inc rsi
    call cursor
    call unprint_piece
    ret

unprint_t_2:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 5
    push rdi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    push rdi
    push rsi
    sub rdi, 3
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    ret

unprint_t_3:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    add rdi, 3
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    call unprint_piece
    ret

unprint_t_4:
    add rsi, 2
    mov rax, 3
    mul rdi
    mov rdi, rax
    add rdi, 2
    push rdi
    push rsi
    call cursor
    call unprint_piece
    pop rsi
    pop rdi
    push rdi
    push rsi
    inc rsi
    call cursor
    call unprint_piece
    call unprint_piece
    pop rsi
    pop rdi
    inc rsi
    call cursor
    call unprint_piece
    ret

print_piece:
    push "["
    call print_char
    push " "
    call print_char
    push "]"
    call print_char
    add rsp, 24
    ret

unprint_piece:
    push " "
    call print_char
    call print_char
    call print_char
    add rsp, 8
    ret

color:
    push qword[rsp+8]
    call ANSI
    push "["
    call print_char
    add rsp, 8
    call print_num
    push "m"
    call print_char
    add rsp, 16
    mov rax, [rsp]
    mov [rsp+8], rax
    add rsp, 8
    ret

background_256:
    push qword[rsp+8]
    call ANSI
    push "["
    call print_char
    push 48
    call print_num
    push ";"
    call print_char
    push "5"
    call print_char
    add rsp, 8
    call print_char
    add rsp, 24
    call print_num
    push "m"
    call print_char
    add rsp, 16
    mov rax, [rsp]
    mov [rsp+8], rax
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
    push 47
    call color
    sub rsp, 8
    mov qword[rsp], ' '
    mov r8, width
    loop3:
    call print_char
    dec r8
    cmp r8, 0
    jne loop3
    mov rsi, height
    mov rdi, 0
    call cursor
    mov r8, width
    loop4:
    call print_char
    dec r8
    cmp r8, 0
    jne loop4
    mov r8, height
    loop5:
    ;rdi rsi
    mov rdi, 0
    mov rsi, r8
    call cursor
    call print_char
    dec r8
    cmp r8, 0
    jne loop5
    mov r8, height
    loop6:
    mov rdi, width
    mov rsi, r8
    call cursor
    call print_char
    dec r8
    cmp r8, 0
    jne loop6
    add rsp, 8
    push 0
    call color
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

    mov qword[rsp+8], 0
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
