bits 64
default rel

global _start

section .text

%include "src/boot/compiler/process.nasm"
%include "src/boot/compiler/files.nasm"

_start:
    mov rdi, [compiler_kernelEntry]
    xor rsi, rsi
    call compiler_openFile

    xor rax, rax
    jmp compiler_exit

section .data

compiler_kernelEntry: db "src/kernel/entr", 0

compiler_perror:
    .open:
        dq 0x14
        db "Failed to open file."
