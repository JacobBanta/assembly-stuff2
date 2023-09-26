; credit goes to AFÖÉK, specifically https://github.com/AFOEK/KeyPressASM
; the code was modified for this use case, but I could not have done it without them

global GetKey
global GetKey_b
global Recanonize
global Decanonize
global Restore
section .bss
    file_descriptors: resq 32
    file_descriptors2: resq 32
    file_descriptors3: resq 32 
    timeout: resq 16

Nada: Resb 4    ;Reserve 4 bytes
termios: 
    c_iflag Resd 1    ; input mode flags
    c_oflag Resd 1    ; output mode flags
    c_cflag Resd 1    ; control mode flags
    c_lflag Resd 1    ; local mode flags
    c_line Resb 1     ; line discipline
    c_cc Resb 64      ; control characters
    c_lflag_old resd 1; stores old lflag value
section .text
GetKey:
    mov qword[timeout], 0
    mov dword[file_descriptors], 1
    ; Initialize file descriptor sets
    mov rax, 23      
    mov rdi, 1        ; nfds - highest file descriptor number + 1 (stdin file descriptor)
    lea rsi, file_descriptors
    mov rdx, file_descriptors2      ; timeout - maximum time to wait, 0 means no waiting
    lea r10, file_descriptors3
    mov r8, timeout         ; sigsetsize - size of signal mask in bytes
    syscall
    test rax, rax     ; check the return value of the syscall
    jz skip ; jump if no input is available
    
    Mov EAX,3   ;sys_read kernel call
    Mov EBX,0   ;stdin trap (standart input)
    Mov ECX,Nada    ;buffer pointer
    Mov EDX,3   ;Number of bytes read
    int 80h     ;Call Kernel
    
  skip:
    xor rax, rax
    mov eax, [Nada]
    mov dword[Nada], 0
    push qword[rsp]
    mov [rsp+8], rax
    ret

GetKey_b:; blocking
    Mov EAX,3   ;sys_read kernel call
    Mov EBX,0   ;stdin trap (standart input)
    Mov ECX,Nada    ;buffer pointer
    Mov EDX,3   ;Number of bytes read
    int 80h     ;Call Kernel

    xor rax, rax
    mov eax, [Nada]
    mov dword[Nada], 0
    push qword[rsp]
    mov [rsp+8], rax
    ret
    
Recanonize:
    push rax
    push rbx
    push rcx
    push rdx
    ;Get current settings
    Mov EAX,54             ; SYS_ioctl
    Mov EBX,0              ; STDIN_FILENO
    Mov ECX,0x5401         ; TCGETS
    Mov EDX,termios
    Int 80h

    or dword [c_lflag], 0x0000000A

    ; Write termios structure back
    Mov EAX,54             ; SYS_ioctl
    Mov EBX,0              ; STDIN_FILENO
    Mov ECX,0x5402         ; TCSETS
    Mov EDX,termios
    Int 80h
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
    
Decanonize:
    push rax
    push rbx
    push rcx
    push rdx
    ;Get current settings
    Mov EAX,54             ; SYS_ioctl
    Mov EBX,0              ; STDIN_FILENO
    Mov ECX,0x5401         ; TCGETS
    Mov EDX,termios
    Int 80h

    mov eax, [c_lflag]
    mov [c_lflag_old], eax
    And dword [c_lflag], 0xFFFFFFF5

    ; Write termios structure back
    Mov EAX,54             ; SYS_ioctl
    Mov EBX,0              ; STDIN_FILENO
    Mov ECX,0x5402         ; TCSETS
    Mov EDX,termios
    Int 80h
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

Restore:
    push rax
    push rbx
    push rcx
    push rdx
    ;Get current settings
    Mov EAX,54             ; SYS_ioctl
    Mov EBX,0              ; STDIN_FILENO
    Mov ECX,0x5401         ; TCGETS
    Mov EDX,termios
    Int 80h

    mov eax, [c_lflag_old]
    mov [c_lflag], eax

    ; Write termios structure back
    Mov EAX,54             ; SYS_ioctl
    Mov EBX,0              ; STDIN_FILENO
    Mov ECX,0x5402         ; TCSETS
    Mov EDX,termios
    Int 80h
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
