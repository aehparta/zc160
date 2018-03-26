#!/bin/bash

NAME="zc160"
SRC="${NAME}.asm"
OBJ="${NAME}.obj"
BIN="${NAME}.bin"
DASM="${NAME}.dasm"

echo "Compile $SRC to object $OBJ..."
z80-unknown-coff-as -z80 -forbid-unportable-instructions --warn -o $OBJ $SRC
if [ "$?" -ne "0" ]; then
    echo "Failed to compile!"
    exit 1
fi

echo "Create binary $BIN from $OBJ..."
z80-unknown-coff-objcopy -O binary $OBJ $BIN
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

