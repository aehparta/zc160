/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#ifndef __HD44780_H__
#define __HD44780_H__


/******************************************************************************/
#include <stdio.h>
#include <ddebug/debuglib.h>


/******************************************************************************/
struct hd44780
{
    unsigned char *display;
    int w;
    int h;

    int rs;
    int rw;
    int en;
    int data;

    int onoff;
    int cursoron;
    int blink;

    int moveshift;
    int shiftdir;

    int interfacelen;
    int displayline;
    int charfont;

    int useddorcg;
    int cgaddr;
    int ddaddr;
};


/******************************************************************************/
struct hd44780 *hd44780_create(int width_chars, int height_chars);
void hd44780_set_rs(struct hd44780 *hd, int value);
void hd44780_set_rw(struct hd44780 *hd, int value);
void hd44780_en(struct hd44780 *hd);
void hd44780_set_data(struct hd44780 *hd, int value);
void hd44780_write_command(struct hd44780 *hd);
unsigned char *hd44780_get_display(struct hd44780 *hd);

#endif /* __HD44780_H__ */
/******************************************************************************/

