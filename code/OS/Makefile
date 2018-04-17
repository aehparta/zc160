
TARGET  = zc160
SRC     = main.asm

OBJ     = $(TARGET).obj
BIN     = $(TARGET).bin
DASM    = $(TARGET).dis.asm

all: bin

program: bin
	minipro -p 28C64B -w $(BIN)

build:
	z80-unknown-coff-as -z80 -ignore-unportable-instructions --warn -o $(OBJ) $(SRC)

bin: build
	z80-unknown-coff-objcopy --pad-to 0x2000 -O binary $(OBJ) $(BIN)

dasm:
	z80dasm --origin=0x0000 -a -t -l $(BIN) > $(DASM)

clean:
	rm -f $(OBJ) $(BIN) $(DASM)

.PHONY: all build
