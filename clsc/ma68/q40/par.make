If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/PAR_asm -iQZ: -ot:CORE_PAR_rom.o
a68k CLASSIC:SRC/Q40/PAR_asm -iQZ: -ot:Q40_PAR_rom.o
blink from t:CORE_PAR_rom.o t:Q40_PAR_rom.o to t:Q40_PAR_rom.ahf

stripcode t:Q40_PAR_rom.ahf

copy t:Q40_PAR_rom CLASSIC:ROM/Q40/PAR_rom

delete t:#? all
