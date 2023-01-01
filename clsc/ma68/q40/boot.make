If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/BOOT_asm -iQZ: -ot:CORE_BOOT_rom.o
a68k CLASSIC:SRC/Q40/BOOT_asm -iQZ: -ot:Q40_BOOT_rom.o
blink from t:CORE_BOOT_rom.o t:Q40_BOOT_rom.o to t:Q40_BOOT_rom.ahf

stripcode t:Q40_BOOT_rom.ahf

copy t:Q40_BOOT_rom CLASSIC:ROM/Q40/BOOT_rom

delete t:#? all
