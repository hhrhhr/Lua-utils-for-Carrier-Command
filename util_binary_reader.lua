BinaryReader = {
    f_handle = nil,
    f_size = 0
}

function BinaryReader:open(fullpath)
    self.f_handle = assert(io.open(fullpath, "rb"))
    self.f_size = self.f_handle:seek("end")
    self.f_handle:seek("set")
end

function BinaryReader:close()
    if self.f_handle then
        self.f_handle:close()
    end
end

function BinaryReader:pos()
    if self.f_handle then
       return self.f_handle:seek()
    end
end

function BinaryReader:size()
    return self.f_size
end

function BinaryReader:seek(pos)
    if self.f_handle then
       return self.f_handle:seek("set", pos)
    end
end

function BinaryReader:int8()  -- byte
    local i8 = 0
    i8 = i8 + string.byte(self.f_handle:read(1)) * 2^0
    return i8
end

function BinaryReader:int16(endian_big)  -- word
    local i16 = 0
    if endian_big then
        i16 = i16 + string.byte(self.f_handle:read(1)) * 2^8
        i16 = i16 + string.byte(self.f_handle:read(1)) * 2^0
    else
        i16 = i16 + string.byte(self.f_handle:read(1)) * 2^0
        i16 = i16 + string.byte(self.f_handle:read(1)) * 2^8
    end
    return i16
end

function BinaryReader:int32(endian_big)  -- integer
    local i32 = 0
    if endian_big then
        i32 = i32 + string.byte(self.f_handle:read(1)) * 2^24
        i32 = i32 + string.byte(self.f_handle:read(1)) * 2^16
        i32 = i32 + string.byte(self.f_handle:read(1)) * 2^8
        i32 = i32 + string.byte(self.f_handle:read(1)) * 2^0
    else
        i32 = i32 + string.byte(self.f_handle:read(1)) * 2^0
        i32 = i32 + string.byte(self.f_handle:read(1)) * 2^8
        i32 = i32 + string.byte(self.f_handle:read(1)) * 2^16
        i32 = i32 + string.byte(self.f_handle:read(1)) * 2^24
    end
    return i32
end

function BinaryReader:hex32()  -- hex
    local h32 = ""
    h32 = string.format("%08x", self:int32())
    return h32
end

function BinaryReader:float32()  -- float
    local x = self:int32()
    local mantissa = bit32.extract(x, 0, 23)
    local exp = bit32.extract(x, 23, 8) - 127
    local sign = bit32.extract(x, 31, 1)
    if sign == 0 then sign = 1 else sign = -1 end
    local mul, res = 1, 1
    for i=22, 0, -1 do
        mul = mul * 0.5
        res = bit32.extract(mantissa, i) * mul + res
    end
    local f = 0
    if exp ~= -127 and mantissa ~= 0 then
        f = sign * res * math.pow(2, exp)
    end
    return f
end

function BinaryReader:str(len) -- string
    local str = ""
    if len then
        str = self.f_handle:read(len)
    else
        local chars = {}
        local char = ""
        local zero = string.char(0x00)
        while char ~= zero do
            char = self.f_handle:read(1)
            table.insert(chars, char)
        end
        table.remove(chars)
        str = table.concat(chars)
    end
    return str
end
