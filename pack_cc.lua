require("util_binary_writer")
local zlib = require("zlib")
local lfs = require("lfs")

local in_dir = assert(arg[1], "set path")
local out_file = arg[2] or "patch99.pak"
local BE = true
local files = {}

local w = BinaryWriter
w:open(out_file)
print("[LOG] open " .. out_file)

-- magic
w:str("FORM")
w:uint32(0)         -- size, filled after
w:str("PAC1")

-- header
w:str("HEAD")
w:uint32(35, BE)    -- size of header
w:uint32(256, BE)   -- unk1, always 256
for i = 1, 6 do
    w:uint32(0)     -- zero
end

local d = os.date("!*t")
w:uint16(d.year)
w:uint8(d.month)
w:uint8(d.day)
w:uint8(d.hour)
w:uint8(d.min)
w:uint8(d.sec)

-- data
w:str("DATA")
w:uint32(0)         -- size of data, filled after

local data_start = w:pos()
local offset = data_start
-------------------------------------------------------------------------------
function pack(file)
    local compression = 6
    local stream = zlib.deflate(compression)    -- function

    local content, deflated, eof, bytes_in, bytes_out = "", "", false, 0, 0
    local f = io.open(file, "rb")
    content = f:read("*a")
    f:close()
    deflated, eof, bytes_in, bytes_out = stream(content, "finish")

    if bytes_in * 0.95 <= bytes_out then
        compression = 0
        bytes_out = bytes_in
        deflated = content
    end

    return compression, bytes_in, bytes_out, deflated
end
-------------------------------------------------------------------------------
function parse_dir(path)
    for file in lfs.dir(path) do
        if file == "." or file == ".." then
            goto next_file
        end
        local fullpath = path .. "\\" .. file
        local attr = lfs.attributes(fullpath)
        if attr.mode == "directory" then
            local elements = 0
            for file in lfs.dir(fullpath) do
                if file ~= "." and file ~= ".." then
                    elements = elements + 1
                end
            end
            table.insert(files, {8, 0})             -- directory type
            table.insert(files, {8, file:len()})    -- name_sz
            table.insert(files, {0, file})          -- name
            table.insert(files, {32, elements})     -- file_count

            parse_dir(fullpath)
        else
            local comp, size, zsize, data = pack(fullpath)
            w:str(data)

            print(string.format("%d\t   ->\t%d\t%s", size, zsize, file))

            table.insert(files, {8, 1})             -- file type
            table.insert(files, {8, file:len()})    -- name_sz
            table.insert(files, {0, file})          -- name
            table.insert(files, {32, offset})
            table.insert(files, {32, zsize})
            table.insert(files, {32, size})
            table.insert(files, {32, 0})
            table.insert(files, {16, 0})
            table.insert(files, {8, 1})
            table.insert(files, {8, comp})

            offset = offset + zsize
        end
        ::next_file::
    end
end
-------------------------------------------------------------------------------
local elements = 0
for file in lfs.dir(in_dir) do
    if file ~= "." and file ~= ".." then
        elements = elements + 1
    end
end
table.insert(files, {16, 0})
table.insert(files, {32, elements})     -- root file count
parse_dir(in_dir)

local data_sz = offset - data_start

-- file
w:str("FILE")
w:uint32(0)         -- size of files, filled after

print(w:pos())
local file_start = w:pos()
print(file_start)

for k, v in pairs(files) do
    if v[1] == 0 then
        w:str(v[2])
    elseif v[1] == 8 then
        w:uint8(v[2])
    elseif v[1] == 16 then
        w:uint16(v[2])
    elseif v[1] == 32 then
        w:uint32(v[2])
    else
        assert()
    end
end

print(w:pos(), file_start)
local file_sz = w:pos() - file_start
print(file_sz)

w:close()

-- update sizes
w:update(out_file)

w:seek(4)
w:uint32(w:size() - 8, BE)

w:seek(data_start - 4)
w:uint32(data_sz, BE)

w:seek(file_start - 4)
w:uint32(file_sz, BE)

w:close()
