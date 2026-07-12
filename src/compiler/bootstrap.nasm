bits 64

%include "inc/compiler/syscalls/linux.inc"

global _start

section .text
_start:

; error in rdi
exit:
    mov rax, EXIT_SYSCALL
    syscall
    
section .data
message: db "Hello, world!", 10
