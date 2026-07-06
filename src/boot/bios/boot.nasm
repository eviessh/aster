org 0x7C00
bits 16

%include "src/boot/bios/types/vbeInfo.nasm"
%include "src/boot/bios/types/vbeMode.nasm"
%include "src/boot/bios/types/edid.nasm"

boot_launch:
    ; Some BIOSes spit us out at 0x7C00:0x0, and others spit us out at
    ; 0x0:0x7C00. Make sure it's the second one, because it's way easier to
    ; handle.
    .ensureCorrectSegment:
        xor ax, ax
        mov ds, ax
        ; Save the boot disk.
        mov [ds:0x7BFF], dl
        jmp 0x0000:boot_launch.clearEnvironment
    .clearEnvironment:
        clc
        cld

        xor bx, bx
        xor cx, cx

        mov es, ax
        mov fs, ax
        mov gs, ax
    ; Stack grows downward, and there are about 500KiB that we can use as free
    ; stack. We should NOT get anywhere close to that, however.
    .setupStack:
        mov dx, 0x0007
        mov ss, dx
        xor dx, dx
        mov sp, 0xFFFF

;-------------------------------------------------------------------------------
; Very simply get the SuperVGA information block from the BIOS and store it in
; RAM where we can access it. Note that we ask for VBE2.0+ data.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviessh/tinyboot>
;-------------------------------------------------------------------------------
boot_getGraphicsInfo:
    ; Request VBE2 information from the BIOS.
    mov [ds:0x0500], 'V'
    mov [ds:0x0501], 'B'
    mov [ds:0x0502], 'E'
    mov [ds:0x0503], '2'

    mov ah, 0x4F
    ; Load the SuperVGA information block into RAM right at the beginning of
    ; what we can access.
    mov di, 0x0500
    int 0x10

    cmp al, 0x4F
    jne boot_abort.vgaUnsupported
    ; If we pass this test, there is little to no chance that the
    ; information block we were passed was bad, so we don't have to check
    ; the signature. However, it would still probably be good practice to.
    ; Meh.
    test ah, ah
    jne boot_abort.getVGAInfoFail

;-------------------------------------------------------------------------------
; Read the monitor's EDID information. Just about every monitor since the early
; 2000s supports this protocol, so we should be good. This just details the
; preferred video mode and its parameters.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviessh/tinyboot>
;-------------------------------------------------------------------------------
boot_readEDID:
    mov ax, 0x4F15
    inc bl
    ; Load EDID right after the VGA info. This structure is 128 bytes long.
    mov di, 0x0700
    int 0x10

    cmp al, 0x4F
    jne boot_abort.edidUnsupported
    test ah, ah
    jne boot_abort.getEDIDFail

boot_loadSecondStage:
    ; Use SI to count the attempts to read.
    xor si, si

    mov dl, [ds:0x7BFF]
    xor ch, ch
    xor dh, dh
    ; Load the rest of the bootloader directly after this sector.
    mov bx, 0x7E00

    .resetDisks:
        xor ah, ah
        int 0x13
        ; If we fail to reset, just keep trying.
        jc .resetDisks
    .readDisks:
        mov ah, 0x02
        mov al, 0x01
        mov cl, 0x02

        int 0x13
        jnc boot_getPreferredVideoMode

        cmp si, 0x03
        je boot_abort.diskReadFail
        inc si
        jmp .resetDisks

;-------------------------------------------------------------------------------
; Get the preferred video mode's width and height from the monitor's EDID. We
; look for a 32bpp version of this resolution that supports the flags we want,
; and if we can't find it, we give up.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviessh/tinyboot>
;-------------------------------------------------------------------------------
boot_getPreferredVideoMode:
    ; X resolution (in pixels)
    mov bl, byte[0x0700 + vbe_edid_t.preferredHorizontalActivePixels]
    mov bh, byte[0x0700 + vbe_edid_t.preferredHorizontalPixels2]
    shr bh, 0x04

    ; Y resolution (in pixels)
    mov dl, byte[0x0700 + vbe_edid_t.preferredVerticalActiveLines]
    mov dh, byte[0x0700 + vbe_edid_t.preferredVerticalLines2]
    shr dh, 0x04

; Data setup to enable the preferred video mode.
mov si, word [0x0500 + vbe_info_t.supportedModes]
mov di, 0x0780

;-------------------------------------------------------------------------------
; Enable the preferred video mode by looping through all the BIOS-provided ones
; and picking the one that fits our liking the best. If we can't find that, we
; will throw an abort. We need the mode attributes hardware-supported, optional
; information available, color, graphics mode, and linear framebuffer available.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviessh/tinyboot>
;-------------------------------------------------------------------------------
boot_enablePreferredVideoMode:
    mov ax, 0x4F01
    mov cx, word [ds:si]
    ; Very, very unlikely for the first mode to be the terminator, but in case
    ; this is a stub implementation, we need to check it.
    cmp cx, 0xFFFF
    je boot_abort.noVGAModeFound

    int 0x10

    ; Only test for success because this function is 100% supported.
    test ah, ah
    jnz boot_abort.getVGAModeFail

    ; We only need the first half of the attributes.
    mov al, byte [0x0780 + vbe_mode_t.attributes]
    and al, 0b10011011
    cmp al, 0b10011011
    jne .nextMode

    cmp bx, word [0x0780 + vbe_mode_t.width]
    jne .nextMode
    cmp dx, word [0x0780 + vbe_mode_t.height]
    jne .nextMode

    cmp byte [0x0780 + vbe_mode_t.bitsPerPixel], 0x20
    je .setMode
    .nextMode:
        add si, 0x02
        jmp boot_enablePreferredVideoMode
    .setMode:
        mov ax, 0x4F02
        mov bx, cx
        int 0x10

; Jump into stage 2.
jmp 0x7E00

%include "src/boot/bios/print.nasm"
%include "src/boot/bios/abort.nasm"

boot_strings:
    ; Early-boot abort strings.
    .characterTable: db "0123456789ABCDEF"
    .getVGAInfoFail: db "10/4F00", 0
    .getVGAModeFail: db "10/4F01", 0
    .diskReadFail:   db "13/0002", 0
    .getEDIDFail:    db "10/4F15", 0
    .noVGAModeFound: db "NO MODE", 0
    ; Middle-boot strings.
    .setupFinished: db "Initial setup finished.", 0
    
times 510 - ($ - $$) db 0
dw 0xAA55

