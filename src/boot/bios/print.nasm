bits 16

boot_logInfo:
    push si
    mov si, boot_log_strings.info
    jmp boot__logFinish

boot_logWarning:
    push si
    mov si, boot_log_strings.warning
    jmp boot__logFinish

boot_logError:
    push si
    mov si, boot_log_strings.error

boot__logFinish:
    call boot_printString
    pop si
    call boot_printString
    ret

boot_printString:
    mov ah, 0x0E
    .loop:
        lodsb
        test al, al
        jz .done
        int 0x10
        jmp .loop
    .done:
        ret

 boot_log_strings:
    .info:    db "[INFO] ", 0
    .warning: db "[WARN] ", 0
    .error:   db "[FAIL] ", 0

