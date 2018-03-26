/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#ifndef __Z80_CPU_H__
#define __Z80_CPU_H__


/******************************************************************************/
#include <stdio.h>
#include <z80ex/z80ex.h>


/******************************************************************************/
struct callee {
    uint32_t addr;
    void *prev;
    void *next;
};

/******************************************************************************/

/** Dump all registers. */
void z80cpu_dump_registers();

/** Dump flags only. */
void z80cpu_dump_flags();

/** Single step the cpu. */
int z80cpu_step();


#endif /* __Z80_CPU_H__ */

