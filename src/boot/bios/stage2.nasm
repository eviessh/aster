org 0x7E00
bits 16

cli
hlt

times 0x400 - ($ - $$) db 0
