bits 64
default rel

%include "inc/compiler/syscalls/macos.nasm"

global start

section .text
openFile:
    mov rax, OPEN_SYSCALL
    xor rsi, rsi
    syscall
    cmp rax, 0
    jng standardError
    ret

statFile:
    mov rax, FSTAT_SYSCALL
    mov rsi, rsp
    syscall
    cmp rax, 0
    jng standardError
    ret

readFile:
    
start:
    mov rdi, [rel build_script_path]
    call openFile
    mov rdi, rax
    call statFile

standardError:
    mov rdi, rax
exit:
    mov rax, EXIT_SYSCALL
    syscall
    
section .data
    build_script_path: db "src/build", 0
