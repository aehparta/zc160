
TARGET  = zc160_vga
SRC     = main.asm math.asm

OBJ     = $(TARGET).obj
BIN     = $(TARGET).bin
DASM    = $(TARGET).dis.asm

all: bin

program: bin
	minipro -p 28C64B -w $(BIN)

build:
	z80-unknown-coff-as -z80 -ignore-unportable-instructions --warn -o $(OBJ) $(SRC)

bin: build
	z80-unknown-coff-objcopy --pad-to 0x1800 -O binary $(OBJ) $(BIN)
	cat system-font.zfont >> $(BIN)

dasm:
	z80dasm --origin=0x0000 -a -t -l $(BIN) > $(DASM)

emulate: bin
	../emulator/src/zc160vgaemu -K $(BIN) -I iram.bin

.PHONY: all build
