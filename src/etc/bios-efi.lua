local i
efi = {e=false}
do
    local bp,ci,pack,upack,clist = "/boot/boot.lua",component.invoke,table.pack,table.unpack,component.list
    local function invoke(address, method, ...)
        local r = pack(pcall(ci, address, method, ...))
        if not r[1] then
            return nil, r[2]
        else
            return upack(r, 2, r.n)
        end
    end

    local e = clist("eeprom")()
    if computer.getArchitecture() ~= "Lua 5.3" then
        computer.setArchitecture("Lua 5.3")
    end
    computer.getBootAddress = function()
        return invoke(e, "getData")
    end
    computer.setBootAddress = function(a)
        return invoke(e, "setData", a)
    end
    local ba = computer.getBootAddress()

    do
        local s = clist("screen")()
        local g = clist("gpu")()
        if g and s then invoke(gpu, "bind", screen) end
    end
    local function try(a, f)
        local h, r = invoke(address, "open", f)
        if not h then return nil, r end
        local b = ""
        repeat
            local d, r = invoke(a, "read", h, math.huge)
            if not d and r then return nil, r end
            b = b .. (d or "")
        until not d
        invoke(a, "close", h)
        return load(b, "=init")
    end
    local r
    if ba then
        i, r = try(ba, bp)
    end
    if not i then
        computer.setBootAddress()
        for a in clist("filesystem") do
            i, r = try(a, bp)
            if i then
                computer.setBootAddress(a)
                break
            end
        end
    end
    if not i then
        error("no bootable medium found " .. tostring(r))
    end
    computer.beep(1000, 0.2)
end

function efi.enable()
    efi.e = true
    efi.systab = {}
end

function efi.loadfile(f)
    if not efi.e then return end
    local a = computer.getBootAddress()
    return unpack(pack(try(a,f)))
end

function efi.invoke(addr, )

return i()
