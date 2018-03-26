#!/bin/bash

NAME="zc160_vga"

SRC="${NAME}.asm"

DIR="bin"
OBJ="$DIR/${NAME}.obj"
BIN="$DIR/${NAME}.bin"
DASM="$DIR/${NAME}.dasm"

mkdir -p $DIR

echo "Compile $SRC to object $OBJ..."
z80-unknown-coff-as -z80 -forbid-unportable-instructions --warn -o $OBJ $SRC
if [ "$?" -ne "0" ]; then
    echo "Failed to compile!"
    exit 1
fi

echo "Create binary $BIN from $OBJ..."
z80-unknown-coff-objcopy --pad-to 0x1800 -O binary $OBJ $BIN
if [ "$?" -ne "0" ]; then
    echo "Failed to create binary!"
    exit 1
fi

echo "Disassemble $BIN to $DASM..."
z80dasm --origin=0x0000 -a -t -l $BIN > $DASM
if [ "$?" -ne "0" ]; then
    echo "Failed to disassemble!"
    exit 1
fi

echo "Append font data..."
cat system-font.zfont >> $BIN
