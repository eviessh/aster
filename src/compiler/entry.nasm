bits 64
default rel

global _start

section .text

%include "src/compiler/process.nasm"
%include "src/compiler/files.nasm"

_start:
    lea rdi, [compiler_kernelEntry]
    xor rsi, rsi
    call compiler_openFile

    xor rax, rax
    jmp compiler_exit

section .data

compiler_kernelEntry: db "src/kernel/entry", 0

compiler_perror:
    .open:
        dq 0x15
        db "Failed to open file.", 10
