local eeprom = component.list("eeprom")()
local fs = component.proxy(component.invoke(eeprom, "getData"))
local content
local data = ""
local handle = fs.open("/etc/bios.lua")
repeat
	content = fs.read(handle, math.huge)
	data = data .. (content or "")
until not content
fs.close(handle)
component.invoke(eeprom, "set", data)
component.invoke(eeprom, "setLabel", "LiteKernelBios")
computer.shutdown(true)