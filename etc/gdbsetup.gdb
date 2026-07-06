set disassembly-flavor intel
target remote :1234
set architecture i8086
break *0x7C00
layout asm
