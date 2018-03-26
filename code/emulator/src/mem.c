/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#include "mem.h"


/******************************************************************************/
struct mem *mem_init(ssize_t size, ssize_t offset, int rw)
{
    int err = 0;
    struct mem *m = NULL;
    ssize_t c;

    DD_SALLOC(m);
    DD_ALLOC(m->data, size);
    m->size = size;
    m->offset = offset;
    m->rw = rw ? 1 : 0;
    m->page = 0;

    /* randomize memory content as default if it is writable (usually ram) */
    if (rw) {
        for (c = 0; c < size; c++) {
            m->data[c] = (unsigned char)(rand() & 0xff);
        }
    }

out_err:
    return m;
}


/******************************************************************************/
int mem_load(struct mem *m, const char *filename)
{
    int err = 0;
    FILE *f;

    f = fopen(filename, "rb");
    IF_ERR(!f, -1, "mem_load() failed to open file: %s", filename);
    fread(m->data, m->size, 1, f);
    fclose(f);

out_err:
    return err;
}


/******************************************************************************/
int mem_save(struct mem *m, const char *filename)
{
    int err = 0;
    FILE *f;

    f = fopen(filename, "wb");
    IF_ERR(!f, -1, "mem_save() failed to open file: %s", filename);
    fwrite(m->data, m->size, 1, f);
    fclose(f);

out_err:
    return err;
}


/******************************************************************************/
int mem_is_in(struct mem *m, ssize_t addr)
{
    if (m->offset > addr) {
        return 0;
    } else if ((m->offset + m->size) <= addr) {
        return 0;
    }
    return 1;
}


/******************************************************************************/
unsigned char mem_read8(struct mem *m, ssize_t addr)
{
    unsigned char err = 0;

    /* check that given address is within this block */
    IF_ERR(m->offset > addr, 0, "tried to read from memory block that does not contain given address");
    IF_ERR((m->offset + m->size) <= addr, 0, "tried to read from memory block that does not contain given address");

    err = m->data[addr - m->offset];

out_err:
    return err;
}

/******************************************************************************/
void mem_write8(struct mem *m, ssize_t addr, unsigned char value)
{
    int err = 0;

    /* check that given address is within this block */
    IF_ERR(m->offset > addr, 0, "tried to write to memory block that does not contain given address");
    IF_ERR((m->offset + m->size) <= addr, 0, "tried to write to memory block that does not contain given address");
    IF_ERR(!m->rw, 0, "tried to write memory at address %0.4X that is readonly", addr);

    m->data[addr - m->offset] = value;

out_err:
    return;
}



