If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/KEYUK_asm -iQZ: -ot:CORE_KEYUK_rom.o
a68k CLASSIC:SRC/Q40/KEYUK_asm -iQZ: -ot:Q40_KEYUK_rom.o
blink from t:CORE_KEYUK_rom.o t:Q40_KEYUK_rom.o to t:Q40_KEYUK_rom.ahf

stripcode t:Q40_KEYUK_rom.ahf

copy t:Q40_KEYUK_rom CLASSIC:ROM/Q40/KEYUK_rom

delete t:#? all
