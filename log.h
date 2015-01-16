#ifndef _log_h_
#define _log_h_

#include <iostream>

#ifndef __GNUC__
#define __attribute__(X)
#endif

static int _file_log_level __attribute__((unused)) = -1;

extern int get_file_log_level(const char *file, int *level);

#ifdef __BASE_FILE__
#define LOGGING(L)      ((L) <= (_file_log_level < 0 ? get_file_log_level(__BASE_FILE__, &_file_log_level) : _file_log_level))
#else
#define LOGGING(L)      ((L) <= (_file_log_level < 0 ? get_file_log_level(__FILE__, &_file_log_level) : _file_log_level))
#endif

#define LOG(N, X) (LOGGING(N) ? (std::clog << X << std::endl) : std::clog)
#define LOG1(X) LOG(1, X)
#define LOG2(X) LOG(1, X)
#define LOG3(X) LOG(1, X)

#define ERROR(X) (std::cerr << X << std::endl)

#endif /* _log_h_ */
