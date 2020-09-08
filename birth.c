#define _GNU_SOURCE
#define _ATFILE_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include "statx.h"
#include <time.h>
#include <getopt.h>
#include <string.h>

// does not (yet) provide a wrapper for the statx() system call
#include <sys/syscall.h>

/* this code works ony with x86 and x86_64 */
#if __x86_64__
#define __NR_statx 332
#else
#define __NR_statx 383
#endif

#define statx(a,b,c,d,e) syscall(__NR_statx,(a),(b),(c),(d),(e))

int main(int argc, char *argv[])
{
    int dirfd = AT_FDCWD;
    int flags = AT_SYMLINK_NOFOLLOW;
    unsigned int mask = STATX_ALL;
    struct statx stxbuf;
    long ret = 0;

    int opt = 0;

    while(( opt = getopt(argc, argv, "alfd")) != -1)
    {
        switch(opt) {
            case 'a':
                flags |= AT_NO_AUTOMOUNT;
                break;
            case 'l':
                flags &= ~AT_SYMLINK_NOFOLLOW;
                break;
            case 'f':
                flags &= ~AT_STATX_SYNC_TYPE;
                flags |= AT_STATX_FORCE_SYNC;
                break;
            case 'd':
                flags &= ~AT_STATX_SYNC_TYPE;
                flags |= AT_STATX_DONT_SYNC;
                break;
            default:
                exit(EXIT_SUCCESS);
                break;
        }
    }

    if (optind >= argc) {
        exit(EXIT_FAILURE);
    }

    for (; optind < argc; optind++) {
        memset(&stxbuf, 0xbf, sizeof(stxbuf));
        ret = statx(dirfd, argv[optind], flags, mask, &stxbuf);
        if( ret < 0)
        {
            perror("statx");
            return EXIT_FAILURE;
        }
        printf("%lld.%u\n", *&stxbuf.stx_btime.tv_sec, *&stxbuf.stx_btime.tv_nsec);
    }
    return EXIT_SUCCESS;
}
