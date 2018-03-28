/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#include <stdlib.h>
#include <ddebug/linkedlist.h>
#include <ddebug/debuglib.h>
#include "profiler.h"

struct profiler_stack {
	uint16_t address;
	uint64_t ticks;
	struct profiler_stack *prev;
	struct profiler_stack *next;
};

static struct profiler_stack *first = NULL;
static struct profiler_stack *last = NULL;

/* clock cycles */
extern uint64_t z80cpu_ticks;

void profiler_start(Z80EX_CONTEXT *cpu)
{
	struct profiler_stack *item;
	item = (struct profiler_stack *)malloc(sizeof(*item));
	memset(item, 0, sizeof(*item));
	item->address = z80ex_get_reg(cpu, regPC);
	item->ticks = z80cpu_ticks;
	LL_APP(first, last, item);
	DEBUG_MSG("profiler start called at $%04x", z80ex_get_reg(cpu, regPC));
}

void profiler_end(Z80EX_CONTEXT *cpu)
{
	struct profiler_stack *item;
	LL_POP(first, last, item);
	if (!item) {
		ERROR_MSG("profiler end called when no start has been called at $%04x", z80ex_get_reg(cpu, regPC));
		return;
	}
	INFO_MSG("profiler: $%04x -> $%04x, clock cycles: %d", item->address, z80ex_get_reg(cpu, regPC), z80cpu_ticks - item->ticks - 11);
	free(item);
}

