SET ROM_DIR=C:\Repos\mame0206\roms

del build\sf2_hack.bin
copy build\sf2.bin build\sf2_hack.bin

Asm68k.exe /p sf2_dma_tests.asm, build\sf2_hack.bin

java -jar RomMangler.jar split sf2eb_out_split.cfg build\sf2_hack.bin

del %ROM_DIR%\sf2eb.zip

java -jar RomMangler.jar zipdir build\out %ROM_DIR%\sf2eb.zip

pause