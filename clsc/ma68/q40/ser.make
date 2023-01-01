If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/SER_asm -iQZ: -ot:CORE_SER_rom.o
a68k CLASSIC:SRC/Q40/SER_asm -iQZ: -ot:Q40_SER_rom.o
blink from t:CORE_SER_rom.o t:Q40_SER_rom.o to t:Q40_SER_rom.ahf

stripcode t:Q40_SER_rom.ahf

copy t:Q40_SER_rom CLASSIC:ROM/Q40/SER_rom

delete t:#? all
