wsl ./a68k CLSC/SRC/AMG/BOOT_asm -i. -oobj/amg_boot_rom.o
wsl ./a68k CLSC/SRC/CORE/BOOT_asm -i. -oobj/boot.obj
vlink.exe -sd -sc -s obj\amg_boot_rom.o obj\boot.obj -baoutnull -obin\BOOT_rom
