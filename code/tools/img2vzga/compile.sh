#!/bin/bash

echo "Compile img2zvga..."
gcc img2zvga.c -o img2zvga -lSDL -lSDL_image

echo "Compile img2zfont..."
gcc img2zfont.c -o img2zfont -lSDL -lSDL_image
