If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/KBD_asm -iQZ: -ot:CORE_KBD_rom.o
a68k CLASSIC:SRC/Q40/KBD_asm -iQZ: -ot:Q40_KBD_rom.o
blink from t:CORE_KBD_rom.o t:Q40_KBD_rom.o to t:Q40_KBD_rom.ahf

stripcode t:Q40_KBD_rom.ahf

copy t:Q40_KBD_rom CLASSIC:ROM/Q40/KBD_rom

delete t:#? all
