If EXISTS CLASSIC:RUN/AMG/c
 path CLASSIC:RUN/AMG/c add
Else
 If EXISTS CLASSIC:c
  path CLASSIC:c add
 EndIf
EndIf

a68k CLASSIC:SRC/CORE/BOOT_asm -iQZ: -ot:CORE_BOOT_rom.o
a68k CLASSIC:SRC/AMG/BOOT_asm -iQZ: -ot:AMG_BOOT_rom.o
blink from t:CORE_BOOT_rom.o t:AMG_BOOT_rom.o to t:AMG_BOOT_rom.ahf

stripcode t:AMG_BOOT_rom.ahf

copy t:AMG_BOOT_rom CLASSIC:ROM/AMG/BOOT_rom

delete t:#? all
