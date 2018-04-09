/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#include "z80cpu.h"


Z80EX_CONTEXT *z80cpu = NULL;
uint64_t z80cpu_ticks = 0;


void z80cpu_dump_registers()
{
	/* get register values */
	int bit;
	int af1, bc1, de1, hl1;
	int af2, bc2, de2, hl2;
	int ix, iy, pc, sp, i, r, r7, im, iff1, iff2;
	char flags[] = "CNP?H?ZS";

	af1 = z80ex_get_reg(z80cpu, regAF);
	bc1 = z80ex_get_reg(z80cpu, regBC);
	de1 = z80ex_get_reg(z80cpu, regDE);
	hl1 = z80ex_get_reg(z80cpu, regHL);

	af2 = z80ex_get_reg(z80cpu, regAF_);
	bc2 = z80ex_get_reg(z80cpu, regBC_);
	de2 = z80ex_get_reg(z80cpu, regDE_);
	hl2 = z80ex_get_reg(z80cpu, regHL_);

	ix = z80ex_get_reg(z80cpu, regIX);
	iy = z80ex_get_reg(z80cpu, regIY);
	pc = z80ex_get_reg(z80cpu, regPC);
	sp = z80ex_get_reg(z80cpu, regSP);
	i = z80ex_get_reg(z80cpu, regI);
	r = z80ex_get_reg(z80cpu, regR);
	r7 = z80ex_get_reg(z80cpu, regR7);
	im = z80ex_get_reg(z80cpu, regIM);
	iff1 = z80ex_get_reg(z80cpu, regIFF1);
	iff2 = z80ex_get_reg(z80cpu, regIFF2);

	printf(" af1: %04X, a: %3d (", af1, af1 >> 8);
	for (bit = 7; bit >= 0; bit--) {
		printf("%c:", (int)flags[bit]);
		if (af1 & (1 << bit)) {
			printf("1");
		} else {
			printf("0");
		}
		if (bit != 0) {
			printf(", ");
		}
	}
	printf(")\n");

	printf(" bc1: %04X, b: %3d, c: %3d\n", bc1, bc1 >> 8, bc1 & 0xff);
	printf(" de1: %04X, d: %3d, e: %3d\n", de1, de1 >> 8, de1 & 0xff);
	printf(" hl1: %04X, h: %3d, l: %3d\n", hl1, hl1 >> 8, hl1 & 0xff);

	printf("%s: %04X (", " af2", af2);
	for (bit = 7; bit >= 0; bit--) {
		printf("%c:", (int)flags[bit]);
		if (af2 & (1 << bit)) {
			printf("1");
		} else {
			printf("0");
		}
		if (bit != 0) {
			printf(", ");
		}
	}
	printf(")\n");

	printf("%s: %04X\n", " bc2", bc2);
	printf("%s: %04X\n", " de2", de2);
	printf("%s: %04X\n", " hl2", hl2);

	printf("%s: %04X\n", "  ix", ix);
	printf("%s: %04X\n", "  iy", iy);
	printf("%s: %04X\n", "  pc", pc);
	printf("%s: %04X\n", "  sp", sp);
	printf("%s: %04X\n", "   i", i);
	printf("%s: %04X\n", "   r", r);
	printf("%s: %04X\n", "  r7", r7);
	printf("%s: %04X\n", "  im", im);
	printf("%s: %04X\n", "iff1", iff1);
	printf("%s: %04X\n", "iff2", iff2);
}


void z80cpu_dump_flags()
{
	/* get register values */
	int bit;
	int af;
	char flags[] = "CNP?H?ZS";

	af = z80ex_get_reg(z80cpu, regAF);

	printf("flags: %02X (", af & 0xff);
	for (bit = 7; bit >= 0; bit--) {
		printf("%c:", (int)flags[bit]);
		if (af & (1 << bit)) {
			printf("1");
		} else {
			printf("0");
		}
		if (bit != 0) {
			printf(", ");
		}
	}
	printf(")\n");
}


int z80cpu_step()
{
	int clocks = 0;
	clocks = z80ex_step(z80cpu);
	z80cpu_ticks  += clocks;
	return clocks;
}

