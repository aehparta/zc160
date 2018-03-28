/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#include "profiler.h"
#include "vga.h"


/* cpu itself */
extern Z80EX_CONTEXT *z80cpu;

/* memories */
struct mem *vga_sysrom;
struct mem *vga_sysram;
struct mem *vga_iram;
struct mem *vga_vram;

/* io flags */
int vga_mode = 0;
int vga_blank = 0;
uint32_t vga_custom_color = 0x00000000;

int vga_init()
{
	int err = 0;

	z80cpu = z80ex_create(vga_cpu_rd, NULL,
	                      vga_cpu_wr, NULL,
	                      vga_cpu_in, NULL,
	                      vga_cpu_out, NULL,
	                      vga_cpu_intr, NULL);
	z80ex_reset(z80cpu);

	/* system rom (8kB at 0x0000) */
	vga_sysrom = mem_init(8192, 0x0000, 0);
	if (!var_is_empty("sysrom-file")) {
		DEBUG_MSG("load system rom from: %s", var_get_str("sysrom-file"));
		mem_load(vga_sysrom, var_get_str("sysrom-file"));
	}

	/* system ram (22kB at 0x2000) */
	vga_sysram = mem_init(22528, 0x2000, 1);
	if (!var_is_empty("sysram-file")) {
		DEBUG_MSG("load system ram from: %s", var_get_str("sysram-file"));
		mem_load(vga_sysram, var_get_str("sysram-file"));
	}

	/* interface ram (2kB at 0x7800) */
	vga_iram = mem_init(2048, 0x7800, 1);
	if (!var_is_empty("iram-file")) {
		DEBUG_MSG("load interface ram from: %s", var_get_str("iram-file"));
		mem_load(vga_iram, var_get_str("iram-file"));
	}

	/* vram (32kB at 0x8000) */
	vga_vram = mem_init(32768, 0x8000, 1);
	if (!var_is_empty("vram-file")) {
		DEBUG_MSG("load video ram from: %s", var_get_str("vram-file"));
		mem_load(vga_vram, var_get_str("vram-file"));
	} else {
		// memset(vga_vram->data, 0x00, 32768);
	}

out_err:
	return err;
}


void vga_quit()
{
	z80ex_destroy(z80cpu);
}


void vga_run()
{
	struct timeval tv_start, tv_cur;
	double ss, uss;

	z80ex_reset(z80cpu);

	gettimeofday(&tv_start, NULL);
	ss = (double)tv_start.tv_sec;
	uss = (double)tv_start.tv_usec;

	while (1) {
		double sc, usc;
		gettimeofday(&tv_cur, NULL);
		sc = (double)tv_cur.tv_sec;
		usc = (double)tv_cur.tv_usec;

		sc -= ss;
		usc -= uss;
		sc += (usc / 1000.0f / 1000.0f);
		if (sc >= 0.0001f) {
			int i;
			ss = (double)tv_cur.tv_sec;
			uss = (double)tv_cur.tv_usec;

			for (i = 0; i < 10; i++) {
				z80ex_step(z80cpu);
			}
		} else {
			usleep(1);
		}
	}
}


struct mem *vga_find_memory(Z80EX_WORD addr)
{
	if (mem_is_in(vga_sysrom, (ssize_t)addr)) {
		return vga_sysrom;
	} else if (mem_is_in(vga_sysram, (ssize_t)addr)) {
		return vga_sysram;
	} else if (mem_is_in(vga_iram, (ssize_t)addr)) {
		return vga_iram;
	} else if (mem_is_in(vga_vram, (ssize_t)addr)) {
		return vga_vram;
	}

	return NULL;
}


void vga_screen_update(SDL_Surface *screen)
{
	int x, y;
	SDL_Rect rect;

	rect.w = 1;
	rect.h = 1;

	SDL_FillRect(screen, NULL, 0x00000000);
	for (y = 0; y < 384; y++) {
		int row_addr = (y * 512) >> 3;
		for (x = 0; x < 512; x++) {
			unsigned char mask = 1 << (x & 0x07);
			unsigned char b = mem_read8(vga_vram, 0x8000 + row_addr + (x >> 3));
			if (b & mask) {
				rect.x = x + 64;
				rect.y = y + 48;
				SDL_FillRect(screen, &rect, vga_custom_color);
			}
		}
	}
}


Z80EX_BYTE vga_cpu_rd(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, int m1_state, void *user_data)
{
	Z80EX_BYTE err = 0;
	struct mem *m = vga_find_memory(addr);

	IF_ERR(!m, -1, "tried to access memory at %0.4X which does not exist", addr);
	err = mem_read8(m, addr);
//     DEBUG_MSG("rd @%0.4X: %0.2X", (int)addr, (int)err);

out_err:
	return err;
}


void vga_cpu_wr(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, Z80EX_BYTE value, void *user_data)
{
	int err = 0;
	struct mem *m = vga_find_memory(addr);

	if (addr == 0x0000 || addr == 0x0001) {
		INFO_MSG("debug value: %0.4X:%0.2X", addr, value);
		return;
	}
	if (addr == 0x0002) {
		z80cpu_dump_registers();
		return;
	}
	if (addr == 0x0003) {
		z80cpu_dump_flags();
		return;
	}

	IF_ERR(!m, -1, "tried to access memory at %0.4X which does not exist", addr);
//     DEBUG_MSG("wr @%0.4X: %0.2X", (int)addr, (int)value);
	mem_write8(m, addr, value);

out_err:
	return;
}


Z80EX_BYTE vga_cpu_in(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, void *user_data)
{
	Z80EX_BYTE err = 0;

//     DEBUG_MSG("in @%0.4X: %0.2X", (int)addr, (int)err);

out_err:
	return err;
}


void vga_cpu_out(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, Z80EX_BYTE value, void *user_data)
{
	addr &= 0xff;
	if (addr == 1) {
		vga_mode = (value & 0x80) ? 1 : 0;
		vga_blank = (value & 0x40) ? 0 : 1;
		vga_custom_color = ((value & 0x30) << 18) | ((value & 0x0c) << 12) | ((value & 0x03) << 6);
		DEBUG_MSG("set vga mode %d, blank %d, custom color %0.6X", vga_mode, vga_blank, vga_custom_color);
	} else if (addr == 255) {
		profiler_start(cpu);
	} else if (addr == 254) {
		profiler_end(cpu);
	} else {
		ERROR_MSG("IO write to unknown address %0.2X", (addr & 0xff));
	}
}


Z80EX_BYTE vga_cpu_intr(Z80EX_CONTEXT *cpu, void *user_data)
{
	Z80EX_BYTE err = 0;

	DEBUG_MSG("zc160_cpu_intr()");

out_err:
	return err;
}


void vga_cpu_reti(Z80EX_CONTEXT *cpu, void *user_data)
{
	DEBUG_MSG("zc160_cpu_reti()");
}


void vga_cpu_tstate(Z80EX_CONTEXT *cpu, void *user_data)
{
	DEBUG_MSG("zc160_cpu_tstate()");
}

