/* Minimal <unistd.h> shim so avra builds under MSVC (which has no unistd.h).
 * avra/file.c only uses unlink(); MSVC provides it as _unlink() in <io.h>. */
#pragma once
#include <io.h>
#include <process.h>
#ifndef unlink
#define unlink _unlink
#endif
