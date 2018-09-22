/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@cc.hut.fi, duge at IRCnet>
 */

#ifndef MAIN_VGA_H
#define MAIN_VGA_H


/******************************************************************************/
#include <stdio.h>
#include <SDL.h>
#include <stdlib.h>
#include <strvar.h>
#include <getopt.h>
#include <ddebug/debuglib.h>

#include "vga.h"


/******************************************************************************/
/**
 * Define free time per frame that cpu has time to do stuff.
 * This is around 4480635 ns.
 *
 * One line: 31777.557100298 ns
 * One frame: 525 lines
 * Used by drawing: 384 lines
 * Free lines in frame: 141
 * Busrq activated one line earlier
 */
#define FRAME_FREE_TIME_NS (31777.557100298 * (525 - 384 - 1))


/******************************************************************************/
void p_help(void);
void p_defaults(int argc, char *argv[]);
int p_options(int argc, char *argv[]);
int p_init(int argc, char *argv[]);
void p_exit(int return_code);
uint32_t p_timer_60hz(uint32_t interval, void *data);
void p_run_cpu(void);


#endif /* MAIN_VGA_H */

