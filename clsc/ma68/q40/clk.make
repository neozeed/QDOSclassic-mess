If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/CLK_asm -iQZ: -ot:CORE_CLK_rom.o
a68k CLASSIC:SRC/Q40/CLK_asm -iQZ: -ot:Q40_CLK_rom.o
blink from t:CORE_CLK_rom.o t:Q40_CLK_rom.o to t:Q40_CLK_rom.ahf

stripcode t:Q40_CLK_rom.ahf

copy t:Q40_CLK_rom CLASSIC:ROM/Q40/CLK_rom

delete t:#? all
