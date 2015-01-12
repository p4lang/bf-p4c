#ifndef _checked_array_
#define _checked_array_

#include <assert.h>
#include <stdlib.h>
#include "log.h"

void print_regname(std::ostream &out, const void *addr, const void *end);

template<size_t S, typename T> class checked_array;
template<size_t S, typename T>
std::ostream &operator<<(std::ostream &out, checked_array<S, T> *arr);

template<size_t S, typename T>
class checked_array {
    bool disabled_;
    T data[S];
public:
    checked_array() : disabled_(false) {};
    T& operator[](size_t idx) {
        assert(idx < S);
        if (disabled_) ERROR("Accessing disabled record " << this);
        return data[idx]; }
    const T& operator[](size_t idx) const {
        assert(idx < S);
        return data[idx]; }
    bool modified() const {
        for (int i = 0; i < S; i++)
            if (data[i].modified()) return true;
        return false; }
    bool disabled() const { return disabled_; }
    void disable() {
        if (modified()) ERROR("Disabling modified record " << this);
        disabled_ = true; }
};

template<size_t S, typename T>
inline std::ostream &operator<<(std::ostream &out, checked_array<S, T> *arr) {
    print_regname(out, arr, arr+1);
    return out; }

#endif /* _checked_array_ */
