bits 64
default rel

global _start

section .text

%include "src/compiler/process.nasm"
%include "src/compiler/files.nasm"

_start:
    ; Make a new stack "frame".
    mov rbp, rsp

    lea rdi, [compiler_kernelEntry]
    xor rsi, rsi
    call compiler_openFile
    mov rdi, rax
    call compiler_measureFile

    sub rsp, rax
    mov rsi, rsp
    mov rdx, rax
    ; Store the length of the file right before its contents.
    push rax
    call compiler_readFile

    mov rdi, STDERR_FILE
    call compiler_writeFile

    xor rax, rax
    jmp compiler_exit

section .data

compiler_kernelEntry: db "src/kernel/entry", 0

compiler_perror:
    .open:
        dq 0x15
        db "Failed to open file.", 0xA
    .read:
        dq 0x1A
        db "Failed to read from file.", 0xA
    .lseek:
        dq 0x15
        db "Failed to seek file.", 0xA
