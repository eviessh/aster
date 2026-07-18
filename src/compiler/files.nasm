bits 64
default rel

%ifdef LINUX
    %include "inc/compiler/params/linux.nasm"
    %include "inc/compiler/syscalls/linux.nasm"
%elifdef MACOS
    %include "inc/compiler/params/macos.nasm"
    %include "inc/compiler/syscalls/macos.nasm"
%else
    %error "Unknown operating environment."
%endif

;-------------------------------------------------------------------------------
; This function will open a file descriptor in a user-supplied write mode.
; 
; Parameters:
;   RDI: The file path to open.
;   RSI: The open flags.
;       0: Read only.
;       1: Write only.
;   RCX, R11, RAX, and maybe RDX are clobbered.
;
; This function returns the open file descriptor in RAX. If it fails, the
; function will not return and just exit with an error code.
;-------------------------------------------------------------------------------
compiler_openFile:
    mov rax, OPEN_SYSCALL
    syscall
    %ifdef LINUX
        cmp rax, 0
        jl .fail
    %elifdef MACOS
        ; BSD variants use the carry flag to represent the failure of a system
        ; call.
        jc .fail
    %endif
    ret
    .fail:
        push rax
        mov rdi, STDERR_FILE
        ; Get the length of the string.
        mov rdx, [compiler_perror.open]
        lea rsi, [compiler_perror.open + 8]
        call compiler_writeFile
        pop rax
        jmp compiler_exit

;-------------------------------------------------------------------------------
; This function will write a user-supplied buffer of bytes to a file descriptor.
;
; Parameters:
;   RDI: The file descriptor to write to.
;   RSI: The buffer to write.
;   RDX: The amount of data to write.
;   RCX, R11, and RAX are clobbered.
;
; This function returns nothing, and if it fails, it will just exit with an
; error code.
;-------------------------------------------------------------------------------
compiler_writeFile:
    mov rax, WRITE_SYSCALL
    syscall
    %ifdef LINUX
        test rax, rax
        jnz .fail
    %elifdef MACOS
        ; BSD variants use the carry flag to represent the failure of a system
        ; call.
        jc .fail
    %endif
    ret
    .fail: jmp compiler_exit

