If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/AMG/ACE_asm -iQZ: -ot:ACE_rom.o

stripcode t:ACE_rom.o

copy t:ACE_rom CLASSIC:ROM/AMG

delete t:#? all

