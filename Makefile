AS=asl
P2BIN=p2bin
SRC=patch.s
BSPLIT=bsplit
MAME=mame

ASFLAGS=-i . -n -U

.PHONY: prg.bin

all: prg.bin

prg.o: prg.orig
	$(AS) $(SRC) $(ASFLAGS) -o prg.o

prg.bin: prg.o
	$(P2BIN) $< prg.bin -r \$$-0x3FFFF
	rm prg.o
	$(BSPLIT) s prg.bin prg1.bin prg2.bin

test:
	$(MAME) -debug outzone

clean:
	@-rm -f prg.bin
	@-rm -f prg.o
