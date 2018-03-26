/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#ifndef __VGA_H__
#define __VGA_H__


/******************************************************************************/
#include <stdio.h>
#include <SDL.h>
#include <unistd.h>
#include <sys/types.h>
#include <strvar.h>
#include <strjson.h>
#include <z80ex/z80ex.h>
#include <ddebug/debuglib.h>

#include "mem.h"


/******************************************************************************/

/**
 * Initialize ZC160 VGA emulator.
 */
int vga_init();

/**
 * Deinitialize ZC160 VGA emulator.
 */
void vga_quit();

/**
 * Run emulation.
 */
void vga_run();

/**
 * Find ZC160 VGA memory block which contains this address.
 */
struct mem *vga_find_memory(Z80EX_WORD addr);

/**
 * Get video ram.
 */
void vga_screen_update(SDL_Surface *screen);

/*
 * Z80 emulator library requires following functions to be written.
 */
/*read byte from memory <addr> -- called when RD & MREQ goes active. m1_state will be 1 if M1 signal is active*/
Z80EX_BYTE vga_cpu_rd(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, int m1_state, void *user_data);
/*write <value> to memory <addr> -- called when WR & MREQ goes active*/
void vga_cpu_wr(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, Z80EX_BYTE value, void *user_data);
/*read byte from <port> -- called when RD & IORQ goes active*/
Z80EX_BYTE vga_cpu_in(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, void *user_data);
/*write <value> to <port> -- called when WR & IORQ goes active*/
void vga_cpu_out(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, Z80EX_BYTE value, void *user_data);
/*read byte of interrupt vector -- called when M1 and IORQ goes active*/
Z80EX_BYTE vga_cpu_intr(Z80EX_CONTEXT *cpu, void *user_data);
/*called when the RETI instruction is executed (useful for emulating Z80 PIO/CTC and such)*/
void vga_cpu_reti(Z80EX_CONTEXT *cpu, void *user_data);
/*to be called on each T-State*/
void vga_cpu_tstate(Z80EX_CONTEXT *cpu, void *user_data);


#endif /* __VGA_H__ */

