@echo off

set fntdir=output_retail\data01\gui\fonts

set files=etelkatextpro12.fnt etelkatextpro16.fnt etelkatextpro22.fnt etelkatextpro28.fnt etelkatextpro48n.fnt system.fnt
for %%i in (%files%) do (
    echo %%i
    lua64\lua unpack_fnt.lua "%fntdir%\%%i" output_retail_fnt > %%i.txt
)
:eof
pause
