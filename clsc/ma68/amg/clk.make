If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/CLK_asm -iQZ: -ot:CORE_CLK_rom.o
a68k CLASSIC:SRC/AMG/CLK_asm -iQZ: -ot:AMG_CLK_rom.o
blink from t:CORE_CLK_rom.o t:AMG_CLK_rom.o to t:AMG_CLK_rom.ahf

stripcode t:AMG_CLK_rom.ahf

copy t:AMG_CLK_rom CLASSIC:ROM/AMG/CLK_rom

delete t:#? all
