%include "../macros/macros.mac"
%include "../macros/files.mac"
%include "../macros/socket.mac"
section .text
global _start
_start:
    socket SOCK_FD, 2, 1, 0
    buffer server_address, 16
    mov word[server_address], 2
    mov word[server_address+2], 36895
    mov dword[server_address+4], 16777343
    bind SOCK_FD, server_address
    cmp rax, 0
    jl exit
    listen SOCK_FD, 5
    buffer size, 8
    mov dword[size], 16
    buffer client_addr, 16
    buffer request_buffer, 1024
    buffer response, 4096
  loop:
    accept SOCK_FD, client_addr, size
    socket_fd CLIENT_FD, rax
    read CLIENT_FD, request_buffer
    call process_request
    write CLIENT_FD, response
    close CLIENT_FD
    jmp loop
  exit:
    mov rax, 60
    mov rdi, 0
    syscall

%macro pr 2
    mov rax, request_buffer
    add rax, 4
    str %%tmp, %1
    mov rdi, %%tmp
    mov rsi, %%tmplen
    call strcmp
    cmp rax, 0
    je %2

%endmacro

process_request:
;    print request_buffer
    pr "/ ", requested_root
    pr "/menu ", requested_menu
    pr "/stop ", shutdown_server
    ret

requested_root:
    open INDEX, "index.html", O_RDONLY
    read INDEX, response
    sub rax, 8

loop_clear:
    cmp rax, responselen-8
    jg return
    add rax, 8
    mov qword[response+rax], 0
    jmp loop_clear
    ret

requested_menu:
    open MENU, "menu.html", O_RDONLY
    read MENU, response
    sub rax, 8
    jmp loop_clear
    
shutdown_server:
    close CLIENT_FD
    shutdown SOCK_FD, 2
    jmp exit

return:
    mov rax, 0
    ret

strcmp:
    mov r8, rax
    add r8, rsi
    mov r8b, [r8-1]
    mov r9, rdi
    add r9, rsi
    mov r9b, [r9-1]
    cmp rsi, 0
    je return
    dec rsi
    cmp r8b, r9b
    je strcmp
    mov rax, 1
    ret


