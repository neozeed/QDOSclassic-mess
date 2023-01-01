If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/NOP_asm -iQZ: -ot:CORE_NOP_rom.o

stripcode t:CORE_NOP_rom.o

copy t:CORE_NOP_rom CLASSIC:ROM/CORE/NOP_ROM

delete t:#? all

