#ifndef _log_h_
#define _log_h_

#include <iostream>
#include <vector>

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

#define ERROR(X) (std::clog << "ERROR: " << X << std::endl)
#define WARNING(X) (std::clog << "WARNING: " << X << std::endl)
#define ERRWARN(C, X) ((C) ? ERROR(X) : WARNING(X))

#if 0

template<class T, class = decltype(void(std::declval<T>().dbprint(std::declval<std::ostream&>())), std::true_type{})> inline std::ostream &operator<<(std::ostream &out, const T &obj) { obj.dbprint(out); return out; }

template<class T, class = decltype(void(std::declval<T*>()->dbprint(std::declval<std::ostream&>())), std::true_type{})> inline std::ostream &operator<<(std::ostream &out, const T *obj) { obj->dbprint(out); return out; }

#else

template<class T> inline auto operator<<(std::ostream &out, const T &obj) -> decltype((void)obj.dbprint(out), out)
{ obj.dbprint(out); return out; }

template<class T> inline auto operator<<(std::ostream &out, const T *obj) -> decltype((void)obj->dbprint(out), out)
{ obj->dbprint(out); return out; }

#endif

template<class T> std::ostream &operator<<(std::ostream &out, const std::vector<T> &vec) {
    bool first = true;
    out << '[';
    for (auto &el : vec) {
        if (first) first = false;
        else out << ',';
        out << ' ' << el; }
    if (!first) out << ' ';
    out << ']';
    return out; }

#endif /* _log_h_ */
