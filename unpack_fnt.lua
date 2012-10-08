require("util_binary_reader")

local in_file = assert(arg[1], "set font path")
local out_path = arg[2] or "."
local BIG = true

local r = BinaryReader
r:open(in_file)
print("[LOG] open " .. in_file)

-- magic
r:idstring("FORM")
print("[LOG] filesize: " .. r:size())
local arc_size = r:int32(BIG)
assert(arc_size + 8 == r:size(), "!!! FORM size error")
print("[LOG] arc_size: " .. arc_size .. ", OK")

--r:idstring("FNT3")
local font_type = r:str(4)

-- GLPS
r:idstring("GLPS")
local glps = {}
local glps_size = r:int32(BIG)
glps.type1 = r:int32()
glps.type2 = r:int32()
glps.charz = r:int32()
glps.count = r:int32()

print("\nconfig:")
print(glps.type1, glps.type2, glps.charz)

local tmp = {}
for i = 1, glps.count do
    local start = r:int16()
    local count = r:int16()
    local ch = ""
    if count > 1 then
        ch = start .. "-" .. start + count - 1
    else
        ch = start
    end
    table.insert(tmp, ch)
end

print("\nchars for BMFont:")
print(table.concat(tmp, ","))

-- TCRD
r:idstring("TCRD")
local tcrd = {}
local tcrd_size = r:int32(BIG)
for i = 1, glps.charz do
    local t = {}
    if font_type == "FNT3" then
        t.x = r:int16()
        t.y = r:int16()
        t.w = r:int16()
        t.h = r:int16()
        t.xa = r:uint16()
        t.ya = r:uint16()
    else
        t.x = r:int32(BIG)
        t.y = r:int32(BIG)
        t.w = r:int32(BIG)
        t.h = r:int32(BIG)

    end
    table.insert(tcrd, t)
end

print("\nchars:")
print("#\tx\ty\twidth\theight\tdx\tdy")
for k, v in pairs(tcrd) do
    print(k, v.x, v.y, v.w, v.h, v.xa or "", v.ya or "")
end

-- KERN
print("\nkerning:")
print("#\tx\ty\tamount")
if font_type == "FNT3" then
    r:idstring("KERN")
    local kern = {}
    local kern_size = r:int32(BIG)
    for i = 1, kern_size / 8 do
        local k = {}
        k.first = r:int16()
        k.second = r:int16()
        k.amount = r:uint32()
        table.insert(kern, k)
    end

    for k, v in pairs(kern) do
        print(k, v.first, v.second, v.amount)
    end
else
    print("no kerning")
end
