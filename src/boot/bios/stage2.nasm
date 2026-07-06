org 0x7E00
bits 16

cli
hlt

times 512 - ($ - $$) db 0
