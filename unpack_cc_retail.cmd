@echo off

set ccdir=f:\lalala\Carier Command

set files=data00.cc data01.cc data02.cc patch00.pak
for %%i in (%files%) do (
    echo %%i
    lua64\lua unpack_cc.lua "%ccdir%\%%i" output_retail\%%~ni
)
:eof
pause
