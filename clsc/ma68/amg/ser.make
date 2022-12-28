If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/SER_asm -iQZ: -ot:CORE_SER_rom.o
a68k CLASSIC:SRC/AMG/SER_asm -iQZ: -ot:AMG_SER_rom.o
blink from t:CORE_SER_rom.o t:AMG_SER_rom.o to t:AMG_SER_rom.ahf

stripcode t:AMG_SER_rom.ahf

copy t:AMG_SER_rom CLASSIC:ROM/AMG/SER_rom

delete t:#? all
