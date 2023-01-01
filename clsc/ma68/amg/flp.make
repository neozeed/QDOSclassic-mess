If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/FLP_asm -iQZ: -ot:CORE_FLP_rom.o
a68k CLASSIC:SRC/AMG/FLP_asm -iQZ: -ot:AMG_FLP_rom.o
blink from t:CORE_FLP_rom.o t:AMG_FLP_rom.o to t:AMG_FLP_rom.ahf

stripcode t:AMG_FLP_rom.ahf

copy t:AMG_FLP_rom CLASSIC:ROM/AMG/FLP_rom

delete t:#? all
