@echo off

set ccdir=f:\lalala\Carier Command Demo

set files=demo00.pak demo01.pak
for %%i in (%files%) do (
    echo %%i
    lua64\lua unpack_cc.lua "%ccdir%\%%i" output_demo
)
:eof
pause
