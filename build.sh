#! /bin/bash
exit

mkdir -p $TARGET/boot
mkdir -p $TARGET/etc
cp $SRC/src/boot/boot.lua $TARGET/boot/boot.lua
cp $SRC/src/etc/bios.lua $TARGET/etc/bios.lua
cp $SRC/src/init.lua $TARGET/init.lua
cp $SRC/config $TARGET/boot/config

printf "[  \033[1;92mOK\033[0;39m  ] Bootloader\n"
