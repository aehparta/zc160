/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#ifndef __MEM_H__
#define __MEM_H__


/******************************************************************************/
#include <stdio.h>
#include <ddebug/debuglib.h>


/******************************************************************************/
/**
 * Memory block.
 */
struct mem {
    /* 1 if read and write, 0 if readonly */
    int rw;
    /* data itself */
    unsigned char *data;
    /* memory block size */
    ssize_t size;
    /* offset */
    ssize_t offset;
    /* possible page */
    ssize_t page;
};


/******************************************************************************/

/**
 * Initialize memory block.
 */
struct mem *mem_init(ssize_t size, ssize_t offset, int rw);

/**
 * Load memory contents from file.
 */
int mem_load(struct mem *m, const char *filename);

/**
 * Save memory contents to file.
 */
int mem_save(struct mem *m, const char *filename);

/**
 * Check is specified address belongs to given block.
 */
int mem_is_in(struct mem *m, ssize_t addr);

/**
 * Read one byte from memory block.
 */
unsigned char mem_read8(struct mem *m, ssize_t addr);

/**
 * Write on byte to memory block.
 */
void mem_write8(struct mem *m, ssize_t addr, unsigned char value);


#endif /* __MEM_H__ */
/******************************************************************************/

