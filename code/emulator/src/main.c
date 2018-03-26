/*
 * #SOFTWARE_NAME#
 *
 * License: GNU/GPL, see COPYING
 * Authors: Antti Partanen <aehparta@cc.hut.fi, duge at IRCnet>
 */

#include "main.h"


/******************************************************************************/
/* CONSTANTS */
const char opts[] = "h:K:R:";
struct option longopts[] =
{
    { "help", no_argument, NULL, 'h' },
    { "kernel-file", required_argument, NULL, 'K' },
    { "ram32-file", required_argument, NULL, 'R' },
    { 0, 0, 0, 0 },
};


/******************************************************************************/
/**
 * Print commandline help.
 */
void p_help(void)
{
    printf(
    "No help available.\n"
    "\n");
}


/******************************************************************************/
/**
 * Set default values.
 */
void p_defaults(int argc, char *argv[])
{
//    var_set_str("command", argv[0]);
    var_set_str("config-home", "%s/." PACKAGE_NAME "/config", getenv("HOME"));
    var_set_str("config-etc", "/etc/" PACKAGE_NAME "/config");
}


/******************************************************************************/
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
            var_set_str("kernel-file", "%s", optarg);
            break;

        case 'R':
            var_set_str("ram32-file", "%s", optarg);
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


/******************************************************************************/
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

    /* init zc160 */
    IF_ERR(zc160_init(), -1, "z80w_init() failed");

out_err:
    return err;
}


/******************************************************************************/
/**
 * Free resources allocated by process, quit using libraries, terminate
 * connections and so on. This function will use exit() to quit the process.
 *
 * @param return_code Value to be returned to parent process.
 */
void p_exit(int return_code)
{
    zc160_quit();

    /* terminate program instantly */
    exit(return_code);
}


/******************************************************************************/
/**
 * Function.
 *
 * @param x x
 * @return value
 */
int main(int argc, char *argv[])
{
    int err = 0;

    IF_ERR(p_init(argc, argv), -1, "failed to initialize");

    zc160_run();

out_err:
    p_exit(err);
    return err;
}

