/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#ifndef __ZC160_H__
#define __ZC160_H__


/******************************************************************************/
#include <stdio.h>
#include <unistd.h>
#include <net3/net.h>
#include <strvar.h>
#include <strjson.h>
#include <z80ex/z80ex.h>
#include <ddebug/debuglib.h>

#include "mem.h"
#include "hd44780.h"


/******************************************************************************/

/**
 * Initialize ZC160 emulator.
 */
int zc160_init();

/**
 * Deinitialize ZC160 emulator.
 */
void zc160_quit();

/**
 * Run emulation.
 */
void zc160_run();

/**
 * Find ZC160 memory block which contains this address.
 */
struct mem *zc160_find_memory(Z80EX_WORD addr);

/*
 * Z80 emulator library requires following functions to be written.
 */
/*read byte from memory <addr> -- called when RD & MREQ goes active. m1_state will be 1 if M1 signal is active*/
Z80EX_BYTE zc160_cpu_rd(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, int m1_state, void *user_data);
/*write <value> to memory <addr> -- called when WR & MREQ goes active*/
void zc160_cpu_wr(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, Z80EX_BYTE value, void *user_data);
/*read byte from <port> -- called when RD & IORQ goes active*/
Z80EX_BYTE zc160_cpu_in(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, void *user_data);
/*write <value> to <port> -- called when WR & IORQ goes active*/
void zc160_cpu_out(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, Z80EX_BYTE value, void *user_data);
/*read byte of interrupt vector -- called when M1 and IORQ goes active*/
Z80EX_BYTE zc160_cpu_intr(Z80EX_CONTEXT *cpu, void *user_data);
/*called when the RETI instruction is executed (useful for emulating Z80 PIO/CTC and such)*/
void zc160_cpu_reti(Z80EX_CONTEXT *cpu, void *user_data);
/*to be called on each T-State*/
void zc160_cpu_tstate(Z80EX_CONTEXT *cpu, void *user_data);


#endif /* __EMUZ80W_H__ */
/******************************************************************************/

