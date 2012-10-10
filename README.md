Lua-util-for-Carier-Command
===========================

used tools:
-----------

- Lua 5.2 (http://www.lua.org)
- zlib 1.2.7 (http://www.zlib.net)
- lua-zlib (https://github.com/brimworks/lua-zlib 145a96aad4)
- luafilesystem (https://github.com/keplerproject/luafilesystem 9c2679f9d7)

compiled from sources only for Win x64

usage:
------

Edit 'unpack_cc_demo.cmd' or 'unpack_cc_retail.cmd', set your path to game, run.

all textures is autoconverted from game format to 1-mip DDSs.

manual unpack:
--------------

    lua64\lua.exe unpack_cc.lua path_to_archive output_dir

manual pack:
------------

    lua64\lua.exe pack_cc.lua path_to_dir output_archive
