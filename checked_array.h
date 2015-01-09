#ifndef _checked_array_
#define _checked_array_

#include <assert.h>
#include <stdlib.h>

template<size_t S, typename T>
class checked_array {
    T data[S];
public:
    checked_array() {};
    T& operator[](size_t idx) {
        assert(idx < S);
        return data[idx]; }
};

#endif /* _checked_array_ */
