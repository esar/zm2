CA=../tools/cc65/bin/ca65
LD=../tools/cc65/bin/ld65
ROMGEN=../tools/romgen/romgen

OBJS = monitor.o    \
       vectors.o    \
       breakout.o   \
       centipede.o  \
       basic.o

all: zm2_rom.vhd

zm2_rom.vhd: zm2.rom
	$(ROMGEN) zm2.rom zm2_rom 14 a r e > zm2_rom.vhd	

zm2.rom: $(OBJS)
	$(LD) -o zm2.rom -C zm2.cfg -m zm2.map $^

%.o: %.asm
	$(CA) --listing $*.lst -o $@ $^

clean:
	rm -f *.o *.rom *.map *.lst *.vhd

