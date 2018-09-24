
#include <stdio.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include "font8x8.h"

void main(void)
{
	SDL_Surface *img;

	img = SDL_CreateRGBSurface(0, 128, 128, 32, 0, 0, 0, 0);
	SDL_FillRect(img, NULL, SDL_MapRGB(img->format, 0, 0, 0));

	for (int i = 0; i < 128; i++) {
		for (int x = 0; x < 8; x++) {
			for (int y = 0; y < 8; y++) {
				SDL_Rect rc;
				rc.x = (i & 0xf) * 8 + y;
				rc.y = (i >> 4) * 8 + x;
				rc.w = 1;
				rc.h = 1;
				if (font8x8_basic[i][x] & (1 << y)) {
					SDL_FillRect(img, &rc, SDL_MapRGB(img->format, 255, 255, 255));
				}
			}
		}
	}

	for (int i = 0; i < 32; i++) {
		for (int x = 0; x < 8; x++) {
			for (int y = 0; y < 8; y++) {
				SDL_Rect rc;
				int j = i + 128;
				rc.x = (j & 0xf) * 8 + y;
				rc.y = (j >> 4) * 8 + x;
				rc.w = 1;
				rc.h = 1;
				if (font8x8_block[i][x] & (1 << y)) {
					SDL_FillRect(img, &rc, SDL_MapRGB(img->format, 255, 255, 255));
				}
			}
		}
	}

	for (int i = 0; i < 96; i++) {
		for (int x = 0; x < 8; x++) {
			for (int y = 0; y < 8; y++) {
				SDL_Rect rc;
				int j = i + 128 + 32;
				rc.x = (j & 0xf) * 8 + y;
				rc.y = (j >> 4) * 8 + x;
				rc.w = 1;
				rc.h = 1;
				if (font8x8_ext_latin[i][x] & (1 << y)) {
					SDL_FillRect(img, &rc, SDL_MapRGB(img->format, 255, 255, 255));
				}
			}
		}
	}

	IMG_SavePNG(img, "font.png");
}
