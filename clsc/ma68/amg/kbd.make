If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/KBD_asm -iQZ: -ot:CORE_KBD_rom.o
a68k CLASSIC:SRC/AMG/KBD_asm -iQZ: -ot:AMG_KBD_rom.o
blink from t:CORE_KBD_rom.o t:AMG_KBD_rom.o to t:AMG_KBD_rom.ahf

stripcode t:AMG_KBD_rom.ahf

copy t:AMG_KBD_rom CLASSIC:ROM/AMG/KBD_rom

delete t:#? all
