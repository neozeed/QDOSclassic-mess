If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/BEEP_asm -iQZ: -ot:CORE_BEEP_rom.o -n -p32767 -t
a68k CLASSIC:SRC/SSS/BEEP_asm -iQZ: -ot:SSS_BEEP_rom.o -n -p32767 -t
blink from t:CORE_BEEP_rom.o t:SSS_BEEP_rom.o to t:SSS_BEEP_rom.ahf

stripcode t:SSS_BEEP_rom.ahf

copy t:SSS_BEEP_rom CLASSIC:ROM/SSS/BEEP_rom

delete t:#? all
