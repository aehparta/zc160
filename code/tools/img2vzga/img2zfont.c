#include <stdio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>


uint8_t rgb2indexed16(uint32_t rgb)
{
    uint8_t color = 0x00;
    
    switch (rgb) {
    /* black */
    case 0x000000:
        color = 0x00;
        break;
    /* red */
    case 0x0000ff:
        color = 0x01;
        break;
    /* green */
    case 0x00ff00:
        color = 0x02;
        break;
    /* yellow */
    case 0x00ffff:
        color = 0x03;
        break;
    /* blue */
    case 0xff0000:
        color = 0x04;
        break;
    /* ? */
    case 0xff00ff:
        color = 0x05;
        break;
    /* teal */
    case 0xffff00:
        color = 0x06;
        break;
    /* white */
    case 0xffffff:
        color = 0x07;
        break;
    /* dark red */
    case 0x000055:
        color = 0x08;
        break;
    /* dark green */
    case 0x005500:
        color = 0x09;
        break;
    /* dark blue */
    case 0x550000:
        color = 0x0a;
        break;

    case 0x555500:
        color = 0x0b;
        break;

    case 0x550055:
        color = 0x0c;
        break;

    case 0x005555:
        color = 0x0d;
        break;
    /* light grey */
    case 0xaaaaaa:
        color = 0x0e;
        break;
    /* dark grey */
    case 0x555555:
        color = 0x0f;
        break;
    }
    
    return color;
}


int main(int argc, char *argv[])
{
    SDL_Surface *img;
    char outfile[1024];
    int x, y, z, i, j;
    FILE *f;
    uint8_t ch = 0;
    unsigned char *pixels;
    
    if (argc != 2) {
        printf("invalid arguments: <image>\n");
        exit(1);
    }
    sprintf(outfile, "%s.zfont", argv[1]);
    img = IMG_Load(argv[1]);
    if (!img) {
        printf("image loading failed\n");
        exit(1);
    }

    if (img->w != 128 || img->h != 128) {
        printf("image must be 128*128 pixels (8*8 pixels per character, 256 characters)\n");
        exit(1);
    }

    f = fopen(outfile, "wb");
    if (!f) {
        printf("could not open output file\n");
        exit(1);
    }
    
    pixels = img->pixels;
    
    for (y = 0; y < img->h; y += 8) {
        for (x = 0; x < img->w; x += 8) {
            for (z = 0; z < 8; z++) {
                ch = 0;
                for (i = 0; i < 8; i++) {
                    if (pixels[3 * (img->w * (y + z) + x + i)] > 128) {
                        ch |= (0x01 << i);
                    }
                }
                fwrite(&ch, 1, 1, f);
            }
        }
    }
    
    fclose(f);
        
    return 0;
}

