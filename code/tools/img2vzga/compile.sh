#!/bin/bash

echo "Compile img2zvga..."
gcc img2zvga.c -o img2zvga -lSDL2 -lSDL2_image

echo "Compile img2zfont..."
gcc img2zfont.c -o img2zfont -lSDL2 -lSDL2_image
