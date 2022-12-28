If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/AMG/JAN_asm -iQZ: -ot:JAN_rom.o

stripcode t:JAN_rom.o

copy t:JAN_rom CLASSIC:ROM/AMG

delete t:#? all

