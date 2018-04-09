
#include <stdint.h>
#include <string.h>

// void delay(uint32_t j)
// {
// 	uint32_t i;
// 	memset(0, 0, 1024);
// 	memcpy(0, 0x1000, 1024);
// 	for (i = 0; i < j; i++) {
// 	}
// }
// void print(char *str);

// void main(void)
// {
// 	__asm
// 	ld a, #0x4c
// 	out (0x01), a
// 	__endasm;

// 	print("Hello!");
// }

void putpixel(uint16_t x, uint16_t y)
{

}

void drawcircle(void)
{
	uint16_t x0 = 100;
	uint16_t y0 = 100;
	uint16_t radius = 100;

	uint16_t x = radius - 1;
	uint16_t y = 0;
	uint16_t dx = 1;
	uint16_t dy = 1;
	uint16_t err = dx - (radius << 1);

	while (x >= y) {
		putpixel(x0 + x, y0 + y);
		putpixel(x0 + y, y0 + x);
		putpixel(x0 - y, y0 + x);
		putpixel(x0 - x, y0 + y);
		putpixel(x0 - x, y0 - y);
		putpixel(x0 - y, y0 - x);
		putpixel(x0 + y, y0 - x);
		putpixel(x0 + x, y0 - y);

		if (err <= 0) {
			y++;
			err += dy;
			dy += 2;
		}

		if (err > 0) {
			x--;
			dx += 2;
			err += dx - (radius << 1);
		}
	}
}