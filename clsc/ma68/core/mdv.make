If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/MDV_asm -iQZ: -ot:CORE_MDV_rom.o

stripcode t:CORE_MDV_rom.o

copy t:CORE_MDV_rom CLASSIC:ROM/CORE/MDV_ROM

delete t:#? all

