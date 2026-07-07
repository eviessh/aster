org 0x7C00
bits 16

;-------------------------------------------------------------------------------
; Exported Data Map
;-------------------------------------------------------------------------------
; [Memory 1]
;   0x00000500 [0x0200]: The VBE information structure.
;       This contains the VBE2.0+ information structure as reported by the BIOS.
;       If the BIOS does not support VBE2.0, an error will be thrown on load.
;   0x00000700 [0x0080]: The monitor's EDID record.
;       This contains the VBE/DDC2 information structure as reported by the
;       BIOS. This is mostly used by the bootloader to get the preferred video
;       mode. 
;   0x00000780 [0x747F]: The list of VBE mode information.
;       This contains the list of VBE2.0+ mode information structures, truncated
;       to 128 bytes to fit more into memory. We can only store about 232 of
;       these, if we go over for some reason an error will be thrown on load.
;   0x00007BFF [0x0001]: The index of the boot disk.
; [Bootloader]
;   0x00007C00 [0x0200]: The first bootsector.
;       This sector handles initial bootup sanitization, loads necessary
;       bootloader data from the disk, gets the RAM memory map, and gets
;       graphics information from the motherboard / BIOS.
;   0x00007E00 [0x0400]: The secondary bootsectors.
;       This section is loaded by the first on startup, and will setup the GDT,
;       IDT, and PML4T Page Table. It will then load the kernel into the
;       higher-half of memory and execute it.
; [Memory 2]
;   0x00008200 [0x14 * ...] The system memory map.
;       This is recieved via the BIOS interrupt 0x15 AX=0xE820. It comes in
;       segments of 20 bytes, and details any reserved or usable sctions. There
;       is no environment I know of that will need more than the available
;       ~480.5 KiB we have free(ish, stack) in the second memory segment.
;   0x0007FF0 [...] The stack.
;       This is just the stack we use during the boot process, and shouldn't be
;       used as any sort of data export.
;-------------------------------------------------------------------------------

%include "src/boot/bios/types/vbeInfo.nasm"
%include "src/boot/bios/types/vbeMode.nasm"
%include "src/boot/bios/types/edid.nasm"

boot_launch:
    ; Some BIOSes spit us out at 0x7C00:0x0000, and others spit us out at
    ; 0x0000:0x7C00. Make sure it's the second one, because it's way easier to
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

        ; We need the other registers, or have already cleared them.
        xor cx, cx
        xor si, si
        xor di, di

        mov es, ax
        mov fs, ax
        mov gs, ax
    ; Stack grows downward, and there are about 500KiB that we can use as free
    ; stack. We should NOT get anywhere close to that, however.
    .setupStack:
        mov bx, 0x7FFF
        mov ss, bx
        xor bx, bx
        mov sp, 0x0000

boot_loadSecondary:
    ; DL is already set to the boot disk!
    .resetDisk:
        ; Clearing AX wastes a cycle on first load, but saves an extra jump on
        ; the success path.
        xor ax, ax
        int 0x13
        jc .resetDisk
    .loadDisk:
        ; Rest of the parameters are already 0.
        mov ah, 0x02
        mov al, 0x02
        ; Load the secondary sectors after this one.
        mov bx, 0x7E00
        mov cl, 0x02
        int 0x13
        jnc boot_getMemoryMap
        cmp di, 0x03
        je boot_abort.diskReadFail
        inc di
        jmp .resetDisk

boot_getMemoryMap:
    ; It feels so wrong to use extended registers in Real Mode...some BIOSes
    ; need the top half of EAX cleared.
    mov eax, 0x0000E820
    xor ebx, ebx
    mov ecx, 0x00000014
    mov edx, 0x534D4150
    mov di, 0x8200
    .readEntry:
        int 0x15
        jc boot_abort.memoryMapReadFail
        test ebx, ebx
        jz boot_getGraphicsInfo
        cmp ecx, 0x14
        jne .tryAgain
        add di, 0x14
    .readNext:
        xchg eax, edx
        mov eax, 0x0000E820
        jmp .readEntry
    .tryAgain:
        sub ebx, ecx
        mov ecx, 0x00000014
        jmp .readNext

boot_getGraphicsInfo:
    ; We need this signature to get VBE 2.0 information.
    mov dword [ds:0x0500], "VBE2"
    .getVBEInfo:
        mov ax, 0x4F00
        mov di, 0x0500
        int 0x10
        cmp al, 0x4F
        jne boot_abort.vbeUnsupported
        test ah, ah
        jnz boot_abort.getVBEInfoFail
    .getEDIDInfo:
        mov ax, 0x4F15
        inc bl
        mov di, 0x0700
        int 0x10
        cmp al, 0x4F
        jne boot_abort.edidUnsupported
        test ah, ah
        jnz boot_abort.getEDIDFail
    .getEDIDModeInfo:
        mov bl, byte [0x0700 + vbe_edid_t.preferredHorizontalActivePixels]
        mov bh, byte [0x0700 + vbe_edid_t.preferredHorizontalPixels2]
        shr bh, 0x04

        ; Y resolution (in pixels)
        mov dl, byte [0x0700 + vbe_edid_t.preferredVerticalActiveLines]
        mov dh, byte [0x0700 + vbe_edid_t.preferredVerticalLines2]
        shr dh, 0x04
    mov si, [0x0500 + vbe_info_t.supportedModes]
    mov di, 0x8200
    .retrieveModeInfos:
        mov ax, 0x4F01
        mov cx, [ds:si]
        cmp cx, 0xFFFF
        je .endSearch
        int 0x10
        
        ; We just assume this function is supported because it's guaranteed by
        ; the VBE standard and we've already confirmed that getInfo exists.
        test ah, ah
        jnz boot_abort.getVBEModeFail

        test bx, bx
        jne .checkMode
        .nextMode:
            add si, 0x02
            jmp .retrieveModeInfos
        .checkMode:
            ; We only need the first half of the attributes.
            mov al, byte [0x8200 + vbe_mode_t.attributes]
            and al, 0b10011011
            cmp al, 0b10011011
            jne .nextMode

            cmp bx, word [0x8200 + vbe_mode_t.width]
            jne .nextMode
            cmp dx, word [0x8200 + vbe_mode_t.height]
            jne .nextMode

            cmp byte [0x8200 + vbe_mode_t.bitsPerPixel], 0x20
            jne .nextMode
        .setMode:
            mov ax, 0x4F02
            mov bx, cx
            int 0x10

            test ah, ah
            jnz boot_abort.setVBEModeFail

            jmp .nextMode
        .endSearch:
            test bx, bx
            jnz boot_abort.noVBEModeFound

boot_nextStage:
    jmp 0x7E00

%include "src/boot/bios/abort.nasm"

boot_strings:
    ; Early-boot abort strings.
    .characterTable:    db "0123456789ABCDEF"
    .failMessage:       db "ERROR WITH ",  0
    .getVBEInfoFail:    db "10/4F00",      0
    .getVBEModeFail:    db "10/4F01",      0
    .setVBEModeFail:    db "10/4F02",      0
    .diskReadFail:      db "13/0002",      0
    .memoryMapReadFail: db "15/E820",      0
    .getEDIDFail:       db "10/4F15",      0
    .noVBE:             db "NO VBE HERE",  0
    .noEDID:            db "NO EDID HERE", 0
    .noVBEModeFound:    db "NO GMODE",     0
    
times 0x1FE - ($ - $$) db 0
dw 0xAA55
