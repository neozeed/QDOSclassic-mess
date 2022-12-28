.key opt1
.def opt1 "ram:CLASSICp_ROM"
.bra {
.ket }


copy CLASSIC:ROM/CORE/NOP_ROM {opt1}
fpatch {opt1} CLASSIC:ROM/CORE/NOP_ROM 16384
fpatch {opt1} CLASSIC:ROM/CORE/NOP_ROM 32768
fpatch {opt1} CLASSIC:ROM/CORE/NOP_ROM 49152
fpatch {opt1} CLASSIC:ROM/CORE/NOP_ROM 65536
fpatch {opt1} CLASSIC:ROM/CORE/NOP_ROM 81920

fpatch {opt1} CLASSIC:ROM/QDOS/SYS_ROM 0
fpatch {opt1} QZ:UTIL/ROM/TK2_rom 49152

setenv ttt 0
setenv off 65536
setenv len 0

setenv nam CLASSIC:ROM/Q40/BOOT_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam CLASSIC:ROM/Q40/CLK_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam CLASSIC:ROM/Q40/KBD_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam CLASSIC:ROM/Q40/KEYUK_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam CLASSIC:ROM/Q40/SSS_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam CLASSIC:ROM/SSS/BEEP_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam CLASSIC:ROM/Q40/SER_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam CLASSIC:ROM/CORE/MDV_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam QZ:HW/QUB/QUBQ40_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

setenv nam CLASSIC:ROM/Q40/FLP_ROM
fpatch {opt1} $nam $off
list >ENV:len $nam LFORMAT "%l"
eval ((($len+127)/128)*128+$off) >ENV:ttt
setenv off $ttt

eval (98304-$off) >ENV:ttt
echo "Q40 ROM created as {opt1} , $ttt bytes free"

unsetenv nam
unsetenv len
unsetenv off
unsetenv ttt
