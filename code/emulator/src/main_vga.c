/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@cc.hut.fi, duge at IRCnet>
 */

#include <stdint.h>
#include "z80cpu.h"
#include "main_vga.h"


/* CONSTANTS */
const char opts[] = "hK:R:I:V:f:";
struct option longopts[] =
{
    { "help", no_argument, NULL, 'h' },
    { "sysrom-file", required_argument, NULL, 'K' },
    { "sysram-file", required_argument, NULL, 'R' },
    { "iram-file", required_argument, NULL, 'I' },
    { "vram-file", required_argument, NULL, 'V' },
    { "frequency", required_argument, NULL, 'f' },
    { 0, 0, 0, 0 },
};

SDL_Window *window = NULL;
SDL_TimerID timer_id;
uint32_t cpu_frequency_mhz = 8;


/**
 * Print commandline help.
 */
void p_help(void)
{
    printf(
    "Options:\n"
    " -K, --sysrom-file <file>      load system rom from given file\n"
    " -R, --sysram-file <file>      load system ram from given file\n"
    " -I, --iram-file <file>        load interface ram from given file\n"
    " -V, --vram-file <file>        load video ram from given file\n"
    " -f, --frequency <fMHz>        set CPU clock to given frequency (default 8 MHz)"
    " -h, --help                    print this help\n"
    "\n");
}


/**
 * Set default values.
 */
void p_defaults(int argc, char *argv[])
{
//    var_set_str("command", argv[0]);
    var_set_str("config-home", "%s/." PACKAGE_NAME "/config", getenv("HOME"));
    var_set_str("config-etc", "/etc/" PACKAGE_NAME "/config");
}


/**
 * Print commandline help.
 */
int p_options(int argc, char *argv[])
{
    int err = 0;
    int longindex = 0, c;

    while((c = getopt_long(argc, argv, opts, longopts, &longindex)) > -1) {
        switch (c) {
        case 'K':
            var_set_str("sysrom-file", "%s", optarg);
            break;

        case 'R':
            var_set_str("sysram-file", "%s", optarg);
            break;

        case 'I':
            var_set_str("iram-file", "%s", optarg);
            break;

        case 'V':
            var_set_str("vram-file", "%s", optarg);
            break;

        case 'f':
            cpu_frequency_mhz = atoi(optarg);
            if (cpu_frequency_mhz < 1) {
                p_help();
                p_exit(1);
            }
            break;

        default:
        case '?':
        case 'h':
            p_help();
            p_exit(1);
        }
    }

out_err:
    return err;
}


/**
 * Initialize resources needed by this process.
 *
 * @param argc Argument count.
 * @param argv Argument array.
 * @return 0 on success, -1 on errors.
 */
int p_init(int argc, char *argv[])
{
    int err = 0;
    SDL_Surface *screen = NULL;

    var_init();

    /* set default values */
    p_defaults(argc, argv);

    /* load config */
    if (!var_file(var_get_str("config-etc"))) { /* load from etc first */
        INFO_MSG("loaded settings from %s", var_get_str("config-etc"));
    }
    if (!var_file(var_get_str("config-home"))) { /* then override with personal ones */
        INFO_MSG("loaded settings from %s", var_get_str("config-home"));
    }

    /* parse commandline options */
    IF_ER(p_options(argc, argv), -1);

    /* init system */
    IF_ERR(vga_init(), -1, "vga_init() failed");

    /* init display */
    IF_ERR(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0, -1, "SDL_Init() failed");
    window = SDL_CreateWindow("ZC160 VGA emulator", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 640, 480, SDL_WINDOW_SHOWN);
    IF_ERR(window == NULL, -1, "SDL_CreateWindow() failed");
    screen = SDL_GetWindowSurface(window);
    SDL_FillRect(screen, NULL, 0x00000000);

    /* setup timer that is called 60 times per second (60 Hz) */
    timer_id = SDL_AddTimer(17, p_run_cpu, NULL);

out_err:
    return err;
}


/**
 * Free resources allocated by process, quit using libraries, terminate
 * connections and so on. This function will use exit() to quit the process.
 *
 * @param return_code Value to be returned to parent process.
 */
void p_exit(int return_code)
{
    vga_quit();

    SDL_RemoveTimer(timer_id);
    SDL_DestroyWindow(window);
    SDL_Quit();

    /* terminate program instantly */
    exit(return_code);
}


/**
 * Run CPU at specified interval (60 Hz).
 */
uint32_t p_run_cpu(uint32_t interval, void *data)
{
    SDL_Surface *screen = NULL;
    int i = FRAME_FREE_TIME_NS / 1000 * cpu_frequency_mhz;

    /* run CPU as many clocks as can fit into free time per frame */
    while (i >= 0) {
        i -= z80cpu_step();
    }

    screen = SDL_GetWindowSurface(window);
    vga_screen_update(screen);
    SDL_UpdateWindowSurface(window);

    return interval;
}


/**
 * Function.
 *
 * @param x x
 * @return value
 */
int main(int argc, char *argv[])
{
    int err = 0, exec = 1;

    IF_ERR(p_init(argc, argv), -1, "failed to initialize");

    while (exec) {
        SDL_Event event;
        unsigned char *vga_vram = NULL;

        while (SDL_WaitEvent(&event)) {
            if (event.type == SDL_QUIT) {
                exec = 0;
                break;
            } else if (event.type == SDL_KEYUP) {
                SDL_KeyboardEvent *event_key = &event;
                if (event_key->keysym.sym == SDLK_r) {
                    z80cpu_dump_registers();
                }
            }
        }
    }

out_err:
    p_exit(err);
    return err;
}

