If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/SSS_asm -iQZ: -ot:CORE_SSS_rom.o -n -p32767 -t
a68k CLASSIC:SRC/AMG/SSS_asm -iQZ: -ot:AMG_SSS_rom.o -n -p32767 -t
blink from t:CORE_SSS_rom.o t:AMG_SSS_rom.o to t:AMG_SSS_rom.ahf

stripcode t:AMG_SSS_rom.ahf

copy t:AMG_SSS_rom CLASSIC:ROM/AMG/SSS_rom

delete t:#? all
