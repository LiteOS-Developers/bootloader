build:
	@mkdir -p $(TARGET)/boot
	@mkdir -p $(TARGET)/etc
	@cp $(SRC)/src/boot/boot.lua $(TARGET)/boot/boot.lua
	@cp $(SRC)/src/etc/bios.lua $(TARGET)/etc/bios.lua
	@cp $(SRC)/src/init.lua $(TARGET)/init.lua
	@cp $(SRC)/config $(TARGET)/boot/config
