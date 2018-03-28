
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

void print(char *str)
{
	for ( ; *str != '\0'; str++) {
		int i;
		uint8_t *from = (uint8_t *)((*str) << 3) + 0x1800;
		uint8_t *to = (uint8_t *)0x8000;
		for (i = 0; i < 8; i++) {
			*to = from[i];
			to += 64;
		}
	}
}

