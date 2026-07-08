org 0x7E00
bits 16

%include "inc/boot/bios/segments.inc"

;-------------------------------------------------------------------------------
; Enable the A20 line, allowing us to access the even MiBs of memory and
; therefore address the entire x86_64 address space.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviess/tinyboot>
;-------------------------------------------------------------------------------
boot_enableA20:
    in al, 0x92
    or al, 0x02
    out 0x92, al

;-------------------------------------------------------------------------------
; Notify the BIOS that we will be in Long Mode exclusively. This allows certain
; firmwares to optimize their internals for Long Mode operations, although from
; testing it seems to be hit-or-miss with support.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviess/tinyboot>
;-------------------------------------------------------------------------------
boot_notifyBIOS:
    mov ax, 0xEC00
    mov bl, 0x02
    ; If this interrupt fails, we literally do not care. Move on.

;-------------------------------------------------------------------------------
; Setup the page table so we can make the transition into Long Mode. This just
; identity maps the first 2MiB of memory.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviess/tinyboot>
;-------------------------------------------------------------------------------
boot_setupPaging:
    ; This is going to be the beginning of the page table, starting with the
    ; PML4T.
    mov edi, 0x1000
    mov cr3, edi

    ; Clear the page tables to zero.
    xor eax, eax
    mov ecx, 0x1000
    rep stosd
    mov edi, cr3

    ; Set up the cascading table references.
    mov dword [edi], 0x2000 & 0xFFFFFFFFFF000 | 0x01 | 0x02
    mov edi, 0x2000
    mov dword [edi], 0x3000 & 0xFFFFFFFFFF000 | 0x01 | 0x02
    mov edi, 0x3000
    mov dword [edi], 0x4000 & 0xFFFFFFFFFF000 | 0x01 | 0x02
    mov edi, 0x4000

    ; Fill the actual page table.
    mov ebx, 0x01 | 0x02
    mov ecx, 0x200
    .setEntry:
        mov dword [edi], ebx
        add ebx, 0x1000
        add edi, 0x08
        loop .setEntry

    ; Actually enable 64-bit paging.
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

;-------------------------------------------------------------------------------
; Elevate the bootloader first to Compatibility Mode, and then immediately into
; Long Mode, bypassing Protected Mode and all its mechanisms entirely.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviess/tinyboot>
;-------------------------------------------------------------------------------
boot_elevate:
    cli

    ; Enter compatibility mode.
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, cr0
    or eax, 1 << 31 | 0x01
    mov cr0, eax

    ; Time to jump into Long Mode! We need to do this to refresh all the
    ; instruction pointers and such.
    lgdt [boot_gdt.pointer]
    jmp boot_gdt.code:boot_longMode

bits 64

boot_longMode:
    hlt

bits 16

;-------------------------------------------------------------------------------
; The Global Descriptor Table for the operating system. This is just here as a
; skeleton, as Long Mode does not really ever need this table besides for some
; flag checking for paging.
;
; Copyright (c) 2026 Evelyn (eviessh), Tinyboot
; <https://codeberg.org/eviess/tinyboot>
;-------------------------------------------------------------------------------
boot_gdt:
    .null: dq 0
    .code: equ $ - boot_gdt
        .code.limitLow:       dw 0xFFFF
        .code.baseLow:        dw 0
        .code.baseMiddle:     db 0
        .code.access:         db SEGMENT_PRESENT | SEGMENT_NOTSYST | SEGMENT_EXECUTE | SEGMENT_READWRT
        .code.flagsLimitHigh: db SEGMENT_4KGRAN | SEGMENT_LONGMD | 0xF
        .code.baseHigh:       db 0
    .data: equ $ - boot_gdt 
        .data.limitLow:       dw 0xFFFF
        .data.baseLow:        dw 0
        .data.baseMiddle:     db 0
        .data.access:         db SEGMENT_PRESENT | SEGMENT_NOTSYST | SEGMENT_READWRT
        .data.flagsLimitHigh: db SEGMENT_4KGRAN | SEGMENT_32BTSZ | 0xF
        .data.baseHigh:       db 0
    .pointer:
        dw $ - boot_gdt - 1
        dq boot_gdt

times 0x400 - ($ - $$) db 0
