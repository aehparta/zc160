/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#ifndef __PROFILER_H__
#define __PROFILER_H__

#include <z80ex/z80ex.h>

void profiler_start(Z80EX_CONTEXT *cpu);
void profiler_end(Z80EX_CONTEXT *cpu);

#endif /* __PROFILER_H__ */

