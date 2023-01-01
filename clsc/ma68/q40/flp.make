If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/FLP_asm -iQZ: -ot:CORE_FLP_rom.o
a68k CLASSIC:SRC/Q40/FLP_asm -iQZ: -ot:Q40_FLP_rom.o
blink from t:CORE_FLP_rom.o t:Q40_FLP_rom.o to t:Q40_FLP_rom.ahf

stripcode t:Q40_FLP_rom.ahf

copy t:Q40_FLP_rom CLASSIC:ROM/Q40/FLP_rom

delete t:#? all
