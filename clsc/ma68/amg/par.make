If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/PAR_asm -iQZ: -ot:CORE_PAR_rom.o
a68k CLASSIC:SRC/AMG/PAR_asm -iQZ: -ot:AMG_PAR_rom.o
blink from t:CORE_PAR_rom.o t:AMG_PAR_rom.o to t:AMG_PAR_rom.ahf

stripcode t:AMG_PAR_rom.ahf

copy t:AMG_PAR_rom CLASSIC:ROM/AMG/PAR_rom

delete t:#? all
