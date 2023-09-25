section .data
    height equ 26
    width equ 32

    x dq 4
    y dq 0

    piece_history db 0

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

    %assign counter 0
    %rep 10
    mov byte[board+240+counter], 1
    %assign counter counter + 1
    %endrep

    lea rax, [print_j_1]
    lea rdx, [unprint_j_1]
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
    cmp qword[rsp+8], 1
    jne skip1
    call rotate
  skip1:
    call attempt_move
    mov rdi, [x]
    mov rsi, [y]
    call [draw]
    ret

return:
    ret

switch_piece:
    cmp byte[piece_history], 127
    jne skip
    mov byte[piece_history], 0
  skip:
    mov rax, 318
    mov rsi, 1
    mov rdx, 0
    push 0
    mov rdi, rsp
    syscall
    pop rax
    xor rdx, rdx
    mov rdi, 7
    div rdi
    mov rcx, rdx
    mov al, [piece_history]
    shr al, cl
    and rax, 1
    cmp rax, 1
    je switch_piece
    mov rdx, 1
    shl rdx, cl
    mov al, [piece_history]
    or al, dl
    mov [piece_history], al
    mov rax, rcx
    call set_piece
    ret

%macro set 1
    lea rax, [print_%1_1]
    lea rdx, [unprint_%{1}_1]
    mov [draw], rax
    mov [undraw], rdx
    ret
%endmacro
set_piece:
    cmp rax, 1
    je set_o
    cmp rax, 2
    je set_i
    cmp rax, 3
    je set_s
    cmp rax, 4
    je set_z
    cmp rax, 5
    je set_j
    cmp rax, 6
    je set_l
    cmp rax, 7
    je set_t
    ;jmp unknown
    ret

  set_o:
    set o
  set_i:
    set i
  set_s:
    set s
  set_z:
    set z
  set_j:
    set j
  set_l:
    set l
  set_t:
    set t

%macro rotat_helper 2
    cmp rax, print_%1_%2
    je rot_%1_%2
%endmacro

%macro rotat 2
    %assign w 1
  %rep %2
    rotat_helper %1, w
    %assign w w+1
  %endrep
%endmacro

%macro rot_helper 3
    rot_%{1}_%{2}:
    lea rax, [print_%1_%{3}]
    lea rdx, [unprint_%{1}_%{3}]
    mov [draw], rax
    mov [undraw], rdx
    ret
%endmacro

%macro rot 2
    %assign w 1
  %rep %2
    %if w==%2
      rot_helper %1, w, 1
    %else
      %assign e w+1
      rot_helper %1, w, e
    %endif
    %assign w w+1
  %endrep
%endmacro

rotate:
    mov rax, [draw]
    cmp rax, print_o
    je return
    rotat i, 2
    rotat s, 2
    rotat z, 2
    rotat j, 4
    rotat l, 4
    rotat t, 4
    ;push rax
    ;call print_num
    ;pop rax
    ;jmp unknown
    ret

    rot i, 2
    rot s, 2
    rot z, 2
    rot j, 4
    rot l, 4
    rot t, 4



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
    cmp al, 3
    je s
    cmp al, 4
    je z
    cmp al, 5
    je j
    cmp al, 6
    je l
    cmp al, 7
    je t
    push rax
    call print_num
    ;jmp unknown
    ret
  blank:
    call unprint_piece
    ret
%macro print_piece_c 1
    push %1
    call color
    call print_piece
    push 0
    call color
    ret
%endmacro
  o:
    print_piece_c 103
  i:
    print_piece_c 106
  s:
    print_piece_c 102
  z:
    print_piece_c 101
  j:
    print_piece_c 104
  l:
    push 208
    call background_256
    call print_piece
    push 0
    call color
    ret
  t:
    print_piece_c 105

drop_lines:
    mov rax, [y]
    mov rdx, 10
    mul rdx
   loop10:
    %assign counter 0
    %rep 10
    mov dl, [board-10+rax+counter]
    mov [board+rax+counter], dl
    %assign counter counter + 1
    %endrep
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


%macro am 5
    mov rax, [y]
    mov rdx, 10
    mul rdx
    add rax, [x]
    lea rdx, [board+rax]
    cmp qword[rsp+16], 4
    jne %%skip_1
    cmp qword[x], 0
    jle %%skip_1
    cmp byte[rdx+%1-1], 0
    jne %%skip_1
    cmp byte[rdx+%2-1], 0
    jne %%skip_1
    cmp byte[rdx+%3-1], 0
    jne %%skip_1
    cmp byte[rdx+%4-1], 0
    jne %%skip_1
    dec qword[x]
  %%skip_1:
    cmp qword[rsp+16], 3
    jne %%skip_2
    cmp qword[x], %5
    jge %%skip_2
    cmp byte[rdx+%1+1], 0
    jne %%skip_2
    cmp byte[rdx+%2+1], 0
    jne %%skip_2
    cmp byte[rdx+%3+1], 0
    jne %%skip_2
    cmp byte[rdx+%4+1], 0
    jne %%skip_2
    inc qword[x]
  %%skip_2:
    mov rax, [y]
    mov rdx, 10
    mul rdx
    add rax, [x]
    lea rdx, [board+rax]
    cmp byte[rdx+%1+10], 0
    jne place
    cmp byte[rdx+%2+10], 0
    jne place
    cmp byte[rdx+%3+10], 0
    jne place
    cmp byte[rdx+%4+10], 0
    jne place
    inc qword[y]
    ret
%endmacro

attempt_move:
    mov rax, [draw]
    cmp rax, print_o
    je am_o
    cmp rax, print_i_1
    je am_i_1
    cmp rax, print_i_2
    je am_i_2
    cmp rax, print_s_1
    je am_s_1
    cmp rax, print_s_2
    je am_s_2
    cmp rax, print_z_1
    je am_z_1
    cmp rax, print_z_2
    je am_z_2
    cmp rax, print_j_1
    je am_j_1
    cmp rax, print_j_2
    je am_j_2
    cmp rax, print_j_3
    je am_j_3
    cmp rax, print_j_4
    je am_j_4
    cmp rax, print_l_1
    je am_l_1
    cmp rax, print_l_2
    je am_l_2
    cmp rax, print_l_3
    je am_l_3
    cmp rax, print_l_4
    je am_l_4
    cmp rax, print_t_1
    je am_t_1
    cmp rax, print_t_2
    je am_t_2
    cmp rax, print_t_3
    je am_t_3
    cmp rax, print_t_4
    je am_t_4
    push rax
    call print_num
    pop rax
    jmp unknown

    ret
  am_o:
    am 0, 1, 10, 11, 8
  am_i_1:
    am 0, 10, 20, 30, 9
  am_i_2:
    am 0, 1, 2, 3, 6
  am_s_1:
    am 1, 2, 10, 11, 7
  am_s_2:
    am 0, 10, 11, 21, 8
  am_z_1:
    am 1, 0, 11, 12, 7
  am_z_2:
    am 1, 10, 11, 20, 8
  am_j_1:
    am 1, 11, 20, 21, 8
  am_j_2:
    am 0, 1, 2, 12, 7
  am_j_3:
    am 0, 1, 10, 20, 8
  am_j_4:
    am 0, 10, 11, 12, 7
  am_l_1:
    am 0, 10, 20, 21, 8
  am_l_2:
    am 2, 10, 11, 12, 7
  am_l_3:
    am 0, 1, 11, 21, 8
  am_l_4:
    am 0, 1, 2, 10, 7
  am_t_1:
    am 0, 1, 2, 11, 7
  am_t_2:
    am 0, 10, 11, 20, 8
  am_t_3:
    am 1, 10, 11, 12, 7
  am_t_4:
    am 1, 10, 11, 21, 8

%macro place_macro 5
    mov byte[rdx+%1], %5
    mov byte[rdx+%2], %5
    mov byte[rdx+%3], %5
    mov byte[rdx+%4], %5
    jmp land
%endmacro

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
    cmp rax, print_i_2
    je place_i_2
    cmp rax, print_s_1
    je place_s_1
    cmp rax, print_s_2
    je place_s_2
    cmp rax, print_z_1
    je place_z_1
    cmp rax, print_z_2
    je place_z_2
    cmp rax, print_j_1
    je place_j_1
    cmp rax, print_j_2
    je place_j_2
    cmp rax, print_j_3
    je place_j_3
    cmp rax, print_j_4
    je place_j_4
    cmp rax, print_l_1
    je place_l_1
    cmp rax, print_l_2
    je place_l_2
    cmp rax, print_l_3
    je place_l_3
    cmp rax, print_l_4
    je place_l_4
    cmp rax, print_t_1
    je place_t_1
    cmp rax, print_t_2
    je place_t_2
    cmp rax, print_t_3
    je place_t_3
    cmp rax, print_t_4
    je place_t_4
    jmp unknown
  place_o:
    %assign c 1
    place_macro 0, 1, 10, 11, c
  place_i_1:
    %assign c c + 1
    place_macro 0, 10, 20, 30, c
  place_i_2:
    place_macro 0, 1, 2, 3, c
  place_s_1:
    %assign c c + 1
    place_macro 1, 2, 10, 11, c
  place_s_2:
    place_macro 0, 10, 11, 21, c
  place_z_1:
    %assign c c + 1
    place_macro 1, 0, 11, 12, c
  place_z_2:
    place_macro 1, 10, 11, 20, c
  place_j_1:
    %assign c c + 1
    place_macro 1, 11, 20, 21, c
  place_j_2:
    place_macro 0, 1, 2, 12, c
  place_j_3:
    place_macro 0, 1, 10, 20, c
  place_j_4:
    place_macro 0, 10, 11, 12, c
  place_l_1:
    %assign c c + 1
    place_macro 0, 10, 20, 21, c
  place_l_2:
    place_macro 2, 10, 11, 12, c
  place_l_3:
    place_macro 0, 1, 11, 21, c
  place_l_4:
    place_macro 0, 1, 2, 10, c
  place_t_1:
    %assign c c + 1
    place_macro 0, 1, 2, 11, c
  place_t_2:
    place_macro 0, 10, 11, 20, c
  place_t_3:
    place_macro 1, 10, 11, 12, c
  place_t_4:
    place_macro 1, 10, 11, 21, c

land:
    mov rdi, [x]
    mov rsi, [y]
    call [draw]
    call attempt_line_clear
    ;call redraw_lines
    call switch_piece
    mov qword[y], 0
    mov qword[x], 4
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

print_o_1:
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

print_l_4:
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

print_l_2:
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

unprint_o_1:
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

unprint_l_4:
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

unprint_l_2:
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
    call ANSI
    mov rsi, 1
    mov rdi, 1
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
