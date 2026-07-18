bits 64
default rel

%ifdef LINUX
    %include "inc/compiler/syscalls/linux.nasm"
%elifdef MACOS
    %include "inc/compiler/syscalls/macos.nasm"
%else
    %error "Unknown operating environment."
%endif

compiler_exit:
    mov rdi, rax
    mov rax, EXIT_SYSCALL
    syscall

