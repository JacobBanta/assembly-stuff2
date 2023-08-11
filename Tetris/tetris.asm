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
    board: resb 250

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

    mov byte[board+240], 1
    mov byte[board+241], 1
    mov byte[board+242], 1
    mov byte[board+243], 1
    mov byte[board+244], 1
    mov byte[board+245], 1
    mov byte[board+246], 1
    mov byte[board+247], 1
    mov byte[board+248], 1
    mov byte[board+249], 1

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

attempt_line_clear:
    mov rdi, [y]
    inc rdi
    mov rax, 10
    mul rdi
    mov rdi, rax
    sub rax, 11
    xor rdx, rdx
   loop7:
    inc rax
    mov dl, [board+rax]
    cmp rax, rdi
    je next
    cmp dl, 0
    jne loop7
    jmp next2
  next:
    call unprint_line
    call unplace_line
    call drop_lines
    call redraw_lines
  next2:
    inc qword[y]
    cmp qword[y], 24
    jne attempt_line_clear
    ret

redraw_lines:
    push qword[y]
   loop11:
    call unprint_line
    call print_line
    dec qword[y]
    cmp qword[y], 0
    jne loop11
    pop qword[y]
    ret
    
print_line:
    mov rax, 0
    mov rsi, [y]
    add rsi, 2
    mov rdi, 2
    push rax
    call cursor
    pop rax
   print_line_loop:
    push rax
    call print_piece_color
    pop rax
    inc rax
    cmp rax, 10
    jne print_line_loop
    ret

print_piece_color:
    mov rdi, rax
    mov rax, [y]
    mov rdx, 10
    mul rdx
    add rax, rdi
    mov al, [board+rax]
    cmp al, 0
    je blank
    cmp al, 1
    je o
    cmp al, 2
    je i
    push rax
    call print_num
    jmp unknown
  blank:
    call unprint_piece
    ret
  o:
    push 103
    call color
    call print_piece
    push 0
    call color
    ret
  i:
    push 106
    call color
    call print_piece
    push 0
    call color
    ret

drop_lines:
    mov rax, [y]
    mov rdx, 10
    mul rdx
   loop10:
    mov dl, [board-10+rax]
    mov [board+rax], dl
    mov dl, [board-9+rax]
    mov [board+rax+1], dl
    mov dl, [board-8+rax]
    mov [board+rax+2], dl
    mov dl, [board-7+rax]
    mov [board+rax+3], dl
    mov dl, [board-6+rax]
    mov [board+rax+4], dl
    mov dl, [board-5+rax]
    mov [board+rax+5], dl
    mov dl, [board-4+rax]
    mov [board+rax+6], dl
    mov dl, [board-3+rax]
    mov [board+rax+7], dl
    mov dl, [board-2+rax]
    mov [board+rax+8], dl
    mov dl, [board-1+rax]
    mov [board+rax+9], dl
    sub rax, 10
    cmp rax, 0
    jne loop10
    ret

unplace_line:
    mov rax, [y]
    mov rdx, 10
    mul rdx
    mov rdx, rax
    add rdx, 10
   loop9:
    mov byte[board+rax], 0
    inc rax
    cmp rax, rdx
    jne loop9
    ret

unprint_line:
    mov rax, 10
    mov rsi, [y]
    add rsi, 2
    mov rdi, 2
    push rax
    call cursor
    pop rax
   unprint_line_loop:
    dec rax
    push rax
    call unprint_piece
    pop rax
    cmp rax, 0
    jne unprint_line_loop
    ret

land:
    mov rdi, [x]
    mov rsi, [y]
    call [draw]
    call attempt_line_clear
    mov qword[y], 0
    mov qword[x], 4
    ret

attempt_move:
    mov rax, [draw]
    cmp rax, print_o
    je am_o
    cmp rax, print_i_1
    je am_i_1
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
    ret
  am_i_1:
    mov rax, [y]
    mov rdx, 10
    mul rdx
    add rax, [x]
    lea rdx, [board+rax]
    cmp qword[rsp+16], 4
    jne skip_i_1
    cmp qword[x], 0
    je skip_i_1
    cmp byte[rdx-1], 0
    jne skip_i_1
    cmp byte[rdx+9], 0
    jne skip_i_1
    cmp byte[rdx+19], 0
    jne skip_i_1
    cmp byte[rdx+29], 0
    jne skip_i_1
    dec qword[x]
  skip_i_1:
    cmp qword[rsp+16], 3
    jne skip_i_12
    cmp qword[x], 9
    je skip_i_12
    cmp byte[rdx+1], 0
    jne skip_i_12
    cmp byte[rdx+11], 0
    jne skip_i_12
    cmp byte[rdx+21], 0
    jne skip_i_12
    cmp byte[rdx+31], 0
    jne skip_i_12
    inc qword[x]
  skip_i_12:
    mov rax, [y]
    mov rdx, 10
    mul rdx
    add rax, [x]
    lea rdx, [board+rax]
    cmp byte[rdx+40], 0
    jne place
    inc qword[y]
    cmp qword[y], 22
    je place
    ret

place:
    mov rax, [y]
    cmp rax, 0
    je exit
    mov rdx, 10
    mul rdx
    add rax, [x]
    lea rdx, [board+rax]
    mov rax, [draw]
    cmp rax, print_o
    je place_o
    cmp rax, print_i_1
    je place_i_1
    jmp unknown
  place_o:
    mov byte[rdx], 1
    mov byte[rdx+1], 1
    mov byte[rdx+10], 1
    mov byte[rdx+11], 1
    jmp land
  place_i_1:
    mov byte[rdx], 2
    mov byte[rdx+10], 2
    mov byte[rdx+20], 2
    mov byte[rdx+30], 2
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
