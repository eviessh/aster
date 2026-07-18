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
;   RAX is clobbered.
;
; This function returns the open file descriptor in RAX. If it fails, the
; function will not return and just exit with an error code.
;-------------------------------------------------------------------------------
compiler_openFile:
    mov rax, OPEN_SYSCALL
    syscall
    cmp rax, 0
    js .fail
    ret
    .fail:
        push rax
        mov rdi, STDERR_FILE
        mov rsi, [compiler_perror.open + 8]
        mov rdx, qword [compiler_perror.open]
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
;   RAX is clobbered.
;
; This function returns nothing, and if it fails, it will just exit with an
; error code.
;-------------------------------------------------------------------------------
compiler_writeFile:
    mov rax, WRITE_SYSCALL
    syscall
    test rax, rax
    jnz .fail
    ret
    .fail: jmp compiler_exit

