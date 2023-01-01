If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/AMG/VDU_asm -iQZ: -ot:VDU_rom.o

stripcode t:VDU_rom.o

copy t:VDU_rom CLASSIC:ROM/AMG

delete t:#? all

