bits 16

;-------------------------------------------------------------------------------
; Abort the boot process because of a fatal error. This is meant to not be
; jumped to explicitly, but rather one of its sublabels for the purpose of
; adding useful error context.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviessh/tinyboot>
;-------------------------------------------------------------------------------
boot_abort:
    .getVBEInfoFail:
        mov si, boot_strings.getVBEInfoFail
        mov cl, ah
        jmp boot__printErrorCode
    .getVBEModeFail:
        mov si, boot_strings.getVBEModeFail
        mov cl, ah
        jmp boot__printErrorCode
    .setVBEModeFail:
        mov si, boot_strings.setVBEModeFail
        mov cl, ah
        jmp boot__printErrorCode
    .getEDIDFail:
        mov si, boot_strings.getEDIDFail
        mov cl, ah
        jmp boot__printErrorCode
    .diskReadFail:
        mov si, boot_strings.diskReadFail
        mov cl, ah
        jmp boot__printErrorCode
    .memoryMapReadFail:
        mov si, boot_strings.memoryMapReadFail
        mov cl, ah
        jmp boot__printErrorCode
    .vbeUnsupported:
        mov si, boot_strings.noVBE
        jmp boot__printErrorCode
    .noVBEModeFound:
        mov si, boot_strings.noVBEModeFound
        jmp boot__printErrorCode
    .edidUnsupported:
        mov si, boot_strings.noEDID

;-------------------------------------------------------------------------------
; Print the error code associated with an abort event, including the contents of
; the CL register as an error code. CL is printed regardless of if it's garbage
; or not.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviessh/tinyboot>
;-------------------------------------------------------------------------------
boot__printErrorCode:
    push si
    mov si, boot_strings.failMessage

    xor bx, bx
    mov ah, 0x0E
    .loop:
        lodsb
        test al, al
        jz .doneInitial
        int 0x10
        jmp .loop
    .doneInitial:
        pop si
    .string:
        lodsb
        test al, al
        jz .done
        int 0x10
        jmp .string
    .done:

    mov al, 'c'
    int 0x10

    ; Split the nibbles for our indexing use.
    mov ch, cl
    shr ch, 0x04
    and cl, 0x0F

    ; Look up the characters in the bin-to-hex mapping.
    mov ax, cx
    mov bx, boot_strings.characterTable
    xlat
    ; Swap around the nibbles so we can look up the next one.
    xchg ah, al
    xlat
    ; Move AH back to CL so we can use it for interrupt stuff.
    mov cl, ah

    xor bx, bx
    mov ah, 0x0E
    int 0x10
    mov al, cl
    int 0x10
    
    cli
    hlt

