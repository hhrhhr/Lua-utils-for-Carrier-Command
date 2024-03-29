require("util_binary_reader")
local zlib = require("zlib")

local in_file = assert(arg[1], "set game path")
local out_path = arg[2] or "."
local BIG = true
local files = {}

local reader = BinaryReader
reader:open(in_file)
print("[LOG] open " .. in_file)

-- magic
reader:idstring("FORM")
print("[LOG] filesize: " .. reader:size())
local arc_size = reader:uint32(BIG)
assert(arc_size + 8 == reader:size(), "!!! FORM size error")
print("[LOG] arc_size: " .. arc_size .. ", OK")

reader:idstring("PAC1")

-- header
reader:idstring("HEAD")
local header = {}
header.size = reader:uint32(BIG)
header.unk1 = reader:uint32(BIG)     -- equal 256
header.zero = reader:str(6 * 4)
header.year = reader:uint16()
header.month = reader:uint8()
header.day = reader:uint8()
header.hour = reader:uint8()
header.min = reader:uint8()
header.sec = reader:uint8()

local txt = string.format("(%d) %d-%d-%d %d:%d:%d",
    header.unk1, header.year, header.month, header.day,
    header.hour, header.min, header.sec)
print(txt)

-- data
reader:idstring("DATA")
local data_sz = reader:uint32(BIG)
reader:seek(reader:pos() + data_sz)

-- file table
reader:idstring("FILE")

local file_sz = reader:uint32(BIG)

local zero = reader:uint16(BIG)
assert(zero == 0, "!!! zero != 0")
local dir_count = reader:uint32()

---------------------------------------------------------------------
-- make 1-mip dds
local function restore_dds(dds)
    local mip_type = dds:sub(129, 132)
    if mip_type == "COPY" or mip_type == "ZLIB" then
        local mips = dds:byte(29)

        local data = {}
        data[1] = dds:sub(1, 28) .. "\001" .. dds:sub(30, 128)

        local pos = 128 + 1 + (mips - 1) * 8
        mip_type = dds:sub(pos, pos + 4 - 1)

        pos = pos + 4
        local i32 = 0
        i32 = i32 + dds:byte(pos+0) * 2^0
        i32 = i32 + dds:byte(pos+1) * 2^8
        i32 = i32 + dds:byte(pos+2) * 2^16
        i32 = i32 + dds:byte(pos+3) * 2^24

        local buf = dds:sub(-(i32), dds:len())

        if mip_type == "ZLIB" then
            local unpak = zlib.inflate()
            data[2] = unpak(buf)
        else
            data[2] = buf
        end
        dds = table.concat(data)
    end
    return dds
end
---------------------------------------------------------------------
local function copy_file(file)
    reader:seek(file.offset)
    local buf = reader:str(file.zsize)
    local unz = ""

    if file.flag == 262 then
        local stream = zlib.inflate()
        unz = stream(buf)
    else
        unz = buf
    end

    if file.name:sub(-3) == "dds" then
        unz = restore_dds(unz)
    end

    file.path = out_path .. file.path
--    cmd = string.format("if not exist \"%s\" mkdir \"%s\"", file.path, file.path)
    cmd = string.format("mkdir \"%s\"  >NUL 2>&1", file.path)
    os.execute(cmd)

    local w = assert(io.open(file.path .. file.name, "w+b"))
    w:write(unz)
    w:close()
end
---------------------------------------------------------------------
local function get_file(fullpath)
    local f_type = reader:uint8()
    assert(f_type <= 1, "!!! unknown file type")
    local name_sz = reader:uint8()
    local name = reader:str(name_sz)
    if f_type < 1 then
        fullpath = fullpath .. name .. "\\"
        local file_count = reader:uint32()
        for f = 1, file_count do
            get_file(fullpath)
        end
    else
        local t = {}
        t.path = fullpath
        t.name = name
        t.offset = reader:uint32()
        t.zsize = reader:uint32()
        t.size = reader:uint32()
        t.zero = reader:uint32()
        assert(t.zero == 0, "!!! zero != 0")
        t.flag = reader:uint32(BIG)  -- 256 or 262 in big endian
        table.insert(files, t)
--print(t.offset, t.zsize, t.size, t.flag, t.path .. t.name)
    end
end
---------------------------------------------------------------------

for dir = 1, dir_count do
    get_file("\\")
end

for _, file in pairs(files) do
    print(file.offset, file.zsize, file.size, file.flag, file.path .. file.name)
    copy_file(file)
end

reader:close()
print("[LOG] close " .. in_file)
