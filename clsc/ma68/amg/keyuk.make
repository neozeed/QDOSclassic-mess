If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/KEYUK_asm -iQZ: -ot:CORE_KEYUK_rom.o
a68k CLASSIC:SRC/AMG/KEYUK_asm -iQZ: -ot:AMG_KEYUK_rom.o
blink from t:CORE_KEYUK_rom.o t:AMG_KEYUK_rom.o to t:AMG_KEYUK_rom.ahf

stripcode t:AMG_KEYUK_rom.ahf

copy t:AMG_KEYUK_rom CLASSIC:ROM/AMG/KEYUK_rom

delete t:#? all
