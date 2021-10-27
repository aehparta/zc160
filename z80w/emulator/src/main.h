/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@cc.hut.fi, duge at IRCnet>
 */

#ifndef MAIN_H
#define MAIN_H


/******************************************************************************/
/* INCLUDES */
#include <stdio.h>
#include <net3/net.h>
#include <stdlib.h>
#include <strvar.h>
#include <getopt.h>
#include <ddebug/debuglib.h>

#include "emuz80w.h"


/******************************************************************************/
/* FUNCTION DEFINITIONS */
void p_help(void);
void p_defaults(int argc, char *argv[]);
int p_options(int argc, char *argv[]);
int p_init(int argc, char *argv[]);
void p_exit(int return_code);


#endif /* MAIN_H - END OF HEADER FILE */
/******************************************************************************/

