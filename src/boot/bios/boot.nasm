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

        xor bx, bx
        xor cx, cx

        mov es, ax
        mov fs, ax
        mov gs, ax
    ; Stack grows downward, and there are about 500KiB that we can use as free
    ; stack. We should NOT get anywhere close to that, however.
    .setupStack:
        mov dx, 0x7FFF
        mov ss, dx
        xor dx, dx
        mov sp, 0x000F

cli
hlt
    
times 0x1FE - ($ - $$) db 0
dw 0xAA55
