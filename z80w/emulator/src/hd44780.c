/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#include "hd44780.h"


/******************************************************************************/
struct hd44780 *hd44780_create(int width_chars, int height_chars)
{
    int err = 0;
    struct hd44780 *hd = NULL;

    DD_SALLOC(hd);
    hd->w = width_chars;
    hd->h = height_chars;
    DD_ALLOC(hd->display, hd->w * hd->h);
    memset(hd->display, 0x20, hd->w * hd->h);

out_err:
    return hd;
}


/******************************************************************************/
void hd44780_set_rs(struct hd44780 *hd, int value)
{
    hd->rs = value ? 1 : 0;
}


/******************************************************************************/
void hd44780_set_rw(struct hd44780 *hd, int value)
{
    hd->rw = value ? 1 : 0;
}


/******************************************************************************/
void hd44780_en(struct hd44780 *hd)
{
    /* write command */
    if (hd->rs == 0 && hd->rw == 0) {
        hd44780_write_command(hd);
    /* write ddram */
    } else if (hd->rs == 1 && hd->rw == 0 && hd->useddorcg == 1) {
        /* dont allow write to unallocated memory */
        if (hd->ddaddr < (hd->w * hd->h)) {
            hd->display[hd->ddaddr] = (unsigned char)hd->data;
            hd->ddaddr++;
            usleep(100000);
        }
    }
}


/******************************************************************************/
void hd44780_set_data(struct hd44780 *hd, int value)
{
    hd->data = (value & 0xff);
}


/******************************************************************************/
void hd44780_write_command(struct hd44780 *hd)
{
    /* clear display */
    if (hd->data == 0x01) {
        memset(hd->display, 0x20, hd->w * hd->h);
        hd->ddaddr = 0;
    /* return cursor to home */
    } else if ((hd->data & 0xfe) == 0x02) {
        hd->ddaddr = 0;
    /* set cgram address */
    } else if ((hd->data & 0x40) == 0x40) {
        hd->cgaddr = hd->data & 0x3f;
        hd->useddorcg = 0;
    /* set ddram address */
    } else if ((hd->data & 0x80) == 0x80) {
        hd->ddaddr = hd->data & 0x7f;
        hd->useddorcg = 1;
    }
}


/******************************************************************************/
unsigned char *hd44780_get_display(struct hd44780 *hd)
{
    return hd->display;
}



