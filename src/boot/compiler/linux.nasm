bits 64

%include "inc/compiler/syscalls/linux.nasm"

global _start

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
    

_start:
    mov rdi, build_script_path
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
