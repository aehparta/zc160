/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@iki.fi, duge at IRCnet>
 */

#include "zc160.h"


/******************************************************************************/
/* cpu itself */
Z80EX_CONTEXT *z80cpu;

/* memories */
struct mem *kernel;
struct mem *flash;
struct mem *ram32;

/* outputs */
int leds;
int segments[4];
struct hd44780 *hd44780;

/* http daemon for serving out info */
net_httpd_vhost *httpd_vhost = NULL;


/******************************************************************************/
int zc160_registers_request(net_session *ns, net_httpd_request *request, net_httpd_response *response, void *userdata)
{
    int err = 0;
    char *data = NULL;
    size_t size = 0;
    var_json_t *registers;

    /* get register values */
    int af1, bc1, de1, hl1;
    int af2, bc2, de2, hl2;
    int ix, iy, pc, sp, i, r, r7, im, iff1, iff2;

    af1 = z80ex_get_reg(z80cpu, regAF);
    bc1 = z80ex_get_reg(z80cpu, regBC);
    de1 = z80ex_get_reg(z80cpu, regDE);
    hl1 = z80ex_get_reg(z80cpu, regHL);

    af2 = z80ex_get_reg(z80cpu, regAF_);
    bc2 = z80ex_get_reg(z80cpu, regBC_);
    de2 = z80ex_get_reg(z80cpu, regDE_);
    hl2 = z80ex_get_reg(z80cpu, regHL_);

    ix = z80ex_get_reg(z80cpu, regIX);
    iy = z80ex_get_reg(z80cpu, regIY);
    pc = z80ex_get_reg(z80cpu, regPC);
    sp = z80ex_get_reg(z80cpu, regSP);
    i = z80ex_get_reg(z80cpu, regI);
    r = z80ex_get_reg(z80cpu, regR);
    r7 = z80ex_get_reg(z80cpu, regR7);
    im = z80ex_get_reg(z80cpu, regIM);
    iff1 = z80ex_get_reg(z80cpu, regIFF1);
    iff2 = z80ex_get_reg(z80cpu, regIFF2);

    registers = var_json_object(NULL, NULL);

    var_json_int(registers, "af1", af1);
    var_json_int(registers, "bc1", bc1);
    var_json_int(registers, "de1", de1);
    var_json_int(registers, "hl1", hl1);

    var_json_int(registers, "af2", af2);
    var_json_int(registers, "bc2", bc2);
    var_json_int(registers, "de2", de2);
    var_json_int(registers, "hl2", hl2);

    var_json_int(registers, "ix", ix);
    var_json_int(registers, "iy", iy);
    var_json_int(registers, "pc", pc);
    var_json_int(registers, "sp", sp);
    var_json_int(registers, "i", i);
    var_json_int(registers, "r", r);
    var_json_int(registers, "r7", r7);
    var_json_int(registers, "im", im);
    var_json_int(registers, "iff1", iff1);
    var_json_int(registers, "iff2", iff2);

    data = var_json_to_str(registers, &size);
    net_httpd_response_simple(ns, request, NET_HTTPD_STATUS_CODE_200, data, size);

out_err:
    return err;
}


/******************************************************************************/
int zc160_outputs_request(net_session *ns, net_httpd_request *request, net_httpd_response *response, void *userdata)
{
    int err = 0, i;
    char *data = NULL;
    size_t size = 0;
    var_json_t *json, *arr;

    json = var_json_object(NULL, NULL);
    var_json_int(json, "leds", leds ^ 0xff);
    var_json_int(json, "seg1", segments[0] ^ 0xff);
    var_json_int(json, "seg2", segments[1] ^ 0xff);
    var_json_int(json, "seg3", segments[2] ^ 0xff);
    var_json_int(json, "seg4", segments[3] ^ 0xff);
    arr = var_json_array(json, "hd44780");
    unsigned char *display = hd44780_get_display(hd44780);
    for (i = 0; i < 40; i++) {
        var_json_int(arr, NULL, (int)display[i]);
    }

    data = var_json_to_str(json, &size);
    net_httpd_response_simple(ns, request, NET_HTTPD_STATUS_CODE_200, data, size);

out_err:
    return err;
}


/******************************************************************************/
int zc160_init()
{
    int err = 0;

    z80cpu = z80ex_create(zc160_cpu_rd, NULL,
        zc160_cpu_wr, NULL,
        zc160_cpu_in, NULL,
        zc160_cpu_out, NULL,
        zc160_cpu_intr, NULL);

    /* kernel is 16kB of ROM at 0x0000 */
    kernel = mem_init(16384, 0x0000, 0);
    if (!var_is_empty("kernel-file")) {
        DEBUG_MSG("load kernel from: %s", var_get_str("kernel-file"));
        mem_load(kernel, var_get_str("kernel-file"));
    }

    /* basic ram is 32kB of static RAM at 0x8000 */
    ram32 = mem_init(32768, 0x8000, 1);
    if (!var_is_empty("ram32-file")) {
        DEBUG_MSG("load ram32 from: %s", var_get_str("kernel-file"));
        mem_load(kernel, var_get_str("ram32-file"));
    }

    /* setup outputs */
    leds = 0;
    segments[0] = 0;
    segments[1] = 0;
    segments[2] = 0;
    segments[3] = 0;
    //memset(hd44780, 0x20, sizeof(hd44780));
    hd44780 = hd44780_create(20, 2);

    /* initialize network */
    net_log_set_level(NET_LOG_INFO);
    net_init();
    net_httpd_init();
    httpd_vhost = net_httpd_vhost_create("0.0.0.0", 8080);
    net_httpd_vhost_set_int(httpd_vhost, NET_HTTPD_VAR_KEEPALIVE, 1);
    net_httpd_vhost_set_int(httpd_vhost, NET_HTTPD_VAR_KEEPALIVE_MAX_REQUESTS, 5);
    net_httpd_vhost_add_route(httpd_vhost, "/registers\\.json$", zc160_registers_request, NULL);
    net_httpd_vhost_add_route(httpd_vhost, "/outputs\\.json$", zc160_outputs_request, NULL);
    net_httpd_vhost_set_str(httpd_vhost, NET_HTTPD_VAR_WWWROOT, "public_html");
    IF_ERR(net_httpd_listen(httpd_vhost), -1, "failed starting http server");

//     net_httpd_vhost_add_hostname(vhost, "aehparta.iki.fi");
//     net_httpd_vhost_set_str(vhost, NET_HTTPD_VAR_WWWROOT, "/tmp");
//     net_httpd_vhost_set_str(vhost, NET_HTTPD_VAR_TMPDIR, "/tmp");
//     net_httpd_vhost_set_int(vhost, NET_HTTPD_VAR_SSL_ENCRYPTION, NET_ENCRYPTION_NONE);
//     net_httpd_vhost_set_str(vhost, NET_HTTPD_VAR_SRC_ROOT, "");
//     net_httpd_vhost_set_str(vhost, NET_HTTPD_VAR_CACHE, "");

out_err:
    return err;
}


/******************************************************************************/
void zc160_quit()
{
    z80ex_destroy(z80cpu);
}


/******************************************************************************/
void zc160_run()
{
    struct timeval tv_start, tv_cur;
    double ss, uss;

    z80ex_reset(z80cpu);

    gettimeofday(&tv_start, NULL);
    ss = (double)tv_start.tv_sec;
    uss = (double)tv_start.tv_usec;

    while (1) {
        double sc, usc;
        gettimeofday(&tv_cur, NULL);
        sc = (double)tv_cur.tv_sec;
        usc = (double)tv_cur.tv_usec;

        sc -= ss;
        usc -= uss;
        sc += (usc / 1000.0f / 1000.0f);
        if (sc >= 0.0001f) {
            int i;
            ss = (double)tv_cur.tv_sec;
            uss = (double)tv_cur.tv_usec;

            for (i = 0; i < 10; i++) {
                z80ex_step(z80cpu);
            }
            net_poll();
        } else {
            usleep(1);
        }
    }
}


/******************************************************************************/
struct mem *zc160_find_memory(Z80EX_WORD addr)
{
    if (mem_is_in(kernel, (ssize_t)addr)) {
        return kernel;
    } else if (mem_is_in(ram32, (ssize_t)addr)) {
        return ram32;
    }

    return NULL;
}


/******************************************************************************/
Z80EX_BYTE zc160_cpu_rd(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, int m1_state, void *user_data)
{
    Z80EX_BYTE err = 0;
    struct mem *m = zc160_find_memory(addr);

    IF_ERR(!m, -1, "tried to access memory at %0.4X which does not exist");
    err = mem_read8(m, addr);
//     DEBUG_MSG("rd @%0.4X: %0.2X", (int)addr, (int)err);

out_err:
    return err;
}


/******************************************************************************/
void zc160_cpu_wr(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, Z80EX_BYTE value, void *user_data)
{
    int err = 0;
    struct mem *m = zc160_find_memory(addr);

    IF_ERR(!m, -1, "tried to access memory at %0.4X which does not exist");
//     DEBUG_MSG("wr @%0.4X: %0.2X", (int)addr, (int)value);
    mem_write8(m, addr, value);

out_err:
    return;
}


/******************************************************************************/
Z80EX_BYTE zc160_cpu_in(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, void *user_data)
{
    Z80EX_BYTE err = 0;

//     DEBUG_MSG("in @%0.4X: %0.2X", (int)addr, (int)err);

out_err:
    return err;
}


/******************************************************************************/
void zc160_cpu_out(Z80EX_CONTEXT *cpu, Z80EX_WORD addr, Z80EX_BYTE value, void *user_data)
{
// SSeg1           equ $01
// SSeg2           equ $02
// SSeg3           equ $03
// SSeg4           equ $04
// KeyS            equ $05
// KeyR            equ $06
// LEDs            equ $07
#define Z80W_7SEG1      0x01
#define Z80W_7SEG2      0x02
#define Z80W_7SEG3      0x03
#define Z80W_7SEG4      0x04
#define Z80W_KEYS       0x05
#define Z80W_KEYR       0x06
#define Z80W_LEDS       0x07
// PortA           equ $20
// PortB           equ $21
// PortC           equ $22
// PIOCtrl         equ $23
// LCDd            equ PortB
// LCDi            equ PortC
#define Z80W_PIOA       0x20
#define Z80W_PIOB       0x21
#define Z80W_PIOC       0x22
#define Z80W_PIOCTRL    0x23

    switch (addr & 0xff) {
    case Z80W_7SEG1:
        DEBUG_MSG("7seg #1: %0.2X", (int)value);
        segments[0] = (int)value;
        break;
    case Z80W_7SEG2:
        DEBUG_MSG("7seg #2: %0.2X", (int)value);
        segments[1] = (int)value;
        break;
    case Z80W_7SEG3:
        DEBUG_MSG("7seg #3: %0.2X", (int)value);
        segments[2] = (int)value;
        break;
    case Z80W_7SEG4:
        DEBUG_MSG("7seg #4: %0.2X", (int)value);
        segments[3] = (int)value;
        break;
    case Z80W_KEYS:
//         DEBUG_MSG("KEYS #4: %0.2X", (int)value);
        break;
    case Z80W_KEYR:
//         DEBUG_MSG("KEYR #4: %0.2X", (int)value);
        break;
    case Z80W_LEDS:
        leds = (int)value;
        break;

    case Z80W_PIOA:
        DEBUG_MSG("PIOA: %0.2X", (int)value);
        break;
    case Z80W_PIOB:
        hd44780_set_data(hd44780, value);
        break;
    case Z80W_PIOC:
        /* set register select and read/write */
        hd44780_set_rs(hd44780, value & 0x04);
        hd44780_set_rw(hd44780, value & 0x02);
        /* apply previous action to hd44780 display */
        if ((value & 0x01) == 0) {
            hd44780_en(hd44780);
        }
        break;
    case Z80W_PIOCTRL:
        DEBUG_MSG("PIOCTRL: %0.2X", (int)value);
        break;
    }
}


/******************************************************************************/
Z80EX_BYTE zc160_cpu_intr(Z80EX_CONTEXT *cpu, void *user_data)
{
    Z80EX_BYTE err = 0;

    DEBUG_MSG("zc160_cpu_intr()");

out_err:
    return err;
}


/******************************************************************************/
void zc160_cpu_reti(Z80EX_CONTEXT *cpu, void *user_data)
{
    DEBUG_MSG("zc160_cpu_reti()");
}


/******************************************************************************/
void zc160_cpu_tstate(Z80EX_CONTEXT *cpu, void *user_data)
{
    DEBUG_MSG("zc160_cpu_tstate()");
}

