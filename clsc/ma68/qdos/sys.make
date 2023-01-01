If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/QDOS/SYS_asm -iQZ: -ot:SYS_rom.o -n -p32767 -t

stripcode t:SYS_rom.o

copy t:SYS_rom CLASSIC:ROM/QDOS

delete t:#? all

