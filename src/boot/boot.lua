do
    local MENU_AUTOSELECT_TIME = 3
    function _G.dump(o)
        if type(o) == 'table' then
            local s = '{ '
            for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
            end
            return s .. '} '
        else
            if type(o) == "string" then return string.format("'%s'", tostring(o)) end
            return tostring(o)
        end
    end
    _G.lib = {}

    local gpu, screen
    for addr in component.list("gpu") do
        screen = component.invoke(addr, "getScreen")

        if screen then
            gpu = component.proxy(addr)
        break
        end
    end
    if not gpu then
        gpu = component.list("gpu")()
        screen = component.list("screen")()
      end
    
    if gpu then
        if type(gpu) == "string" then gpu = component.proxy(gpu) end
        gpu.bind(screen)
    
        local w, h = gpu.getResolution()
        gpu.fill(1, 1, w, h, " ")
        local current_line = 0
    
        function _G.lib.log_to_screen(lines)
            lines = lines:gsub("\t", "  ")
    
            for message in lines:gmatch("[^\n]+") do
                while #message > 0 do
                    local line = message:sub(1, w)
    
                    message = message:sub(#line + 1)
                    current_line = current_line + 1
    
                    if current_line > h then
                        gpu.copy(1, 1, w, h, 0, -1)
                        gpu.fill(1, h, w, 1, " ")
                    end
    
                    gpu.set(1, current_line, line)
                end
            end
        end
    else
        _G.lib.log_to_screen = function() end
    end

    local bootdev, invoke = computer.getBootAddress(), component.invoke

    _G.lib.readFile = function(file)
    
        local handle = assert(invoke(bootdev, "open", file))
        local buffer = ""
        repeat
            local data = invoke(bootdev, "read", handle, math.huge)
            buffer = buffer .. (data or "")
        until not data
        invoke(bootdev, "close", handle)
        return buffer
    end

    local function menu(entries)
        local w, h = gpu.getResolution()
        local str = "LiteOS Loader"
        local x = (w - str:len()) / 2
        gpu.set(x, 2, str)
        local str = "Select an option"
        local x = (w - str:len()) / 2
        gpu.set(x, 13, str)
        local y = 16
        local selected = nil
        for _, e in ipairs(entries) do
            if e.default then
                gpu.setBackground(0xffffff)
                gpu.setForeground(0x000000)
                local x = (w - e.name:len()-1) / 2
                gpu.fill(1, y, w, 1, " ")
                gpu.set(x, y, e.name:sub(1, e.name:len()-1))
                selected = _
            else
                gpu.setBackground(0x000000)
                gpu.setForeground(0xffffff)
                local x = (w - e.name:len()-1) / 2
                gpu.fill(0, y, w, 1, " ")
                gpu.set(x, y, e.name:sub(1, e.name:len()-1))
            end
            y = y + 1
        end
        local t = computer.uptime()
        while true do
            e = table.pack(computer.pullSignal(0.1))
            if t + MENU_AUTOSELECT_TIME <= computer.uptime() then return entries[selected] end 
            if e.n > 0 then
                if e[1] == "key_down" then
                   
                    if e[3] == 0.0 and e[4] == 200.0 then
                        if selected - 1 >= 1 then
                            local e = entries[selected]
                            gpu.setBackground(0x000000)
                            gpu.setForeground(0xffffff)
                            local x = (w - e.name:len()-1) / 2
                            gpu.fill(0, 15+selected, w, 1, " ")
                            gpu.set(x, 15+selected, e.name:sub(1, e.name:len()-1))

                            selected = selected - 1

                            e = entries[selected]
                            gpu.setBackground(0xffffff)
                            gpu.setForeground(0x000000)
                            local x = (w - e.name:len()-1) / 2
                            gpu.fill(1, 15+selected, w, 1, " ")
                            gpu.set(x, 15+selected, e.name:sub(1, e.name:len()-1))
                        end
                    elseif e[3] == 0.0 and e[4] == 208.0 then
                        if selected + 1 <= #entries then
                            local e = entries[selected]
                            gpu.setBackground(0x000000)
                            gpu.setForeground(0xffffff)
                            local x = (w - e.name:len()-1) / 2
                            gpu.fill(0, 15+selected, w, 1, " ")
                            gpu.set(x, 15+selected, e.name:sub(1, e.name:len()-1))

                            selected = selected + 1

                            e = entries[selected]
                            gpu.setBackground(0xffffff)
                            gpu.setForeground(0x000000)
                            local x = (w - e.name:len()-1) / 2
                            gpu.fill(1, 15+selected, w, 1, " ")
                            gpu.set(x, 15+selected, e.name:sub(1, e.name:len()-1))
                        end
                    elseif e[3] == 13 and e[4] == 28 then
                        return entries[selected]
                    end
                end
            end
        end
    end
    local function loadConfig()
        local config = _G.lib.readFile("/boot/config")
        local entries = {}
        local selected
        local lines = {}
        for v in string.gmatch(config, "([^\n]+)") do
            lines[#lines+1] = v
        end
        -- error(dump(lines))
        local cur = {}
        for _, line in ipairs(lines) do
            if line:sub(1,6) == "entry " then
                if cur.name then
                    entries[#entries + 1] = cur
                    cur = {}
                end
                cur.name = line:sub(7)
            elseif line:sub(1, 11) == "    kernel " then
                cur.kernel = line:sub(12)
            elseif line:sub(1,9) == "    opts " then
                cur.opts = line:sub(10)
            elseif line:sub(1, 12) == "    default " then
                local skip = false
                for _, e in ipairs(entries) do
                    if e.default then skip = true end
                end
                cur.default = not skip and line:sub(13,16) == "true"
            end
        end
        entries[#entries + 1] = cur
        return entries
    end
    local entries = loadConfig()
    local entry = menu(entries)
    entry.kernel = entry.kernel:sub(1, -2)
    local kernel, err = load(_G.lib.readFile(entry.kernel), "=" .. entry.kernel, "bt", _G)
    if kernel == nil then
        error("Cannot load kernel: " .. err)
    end
    kernel(entry.opts)
end