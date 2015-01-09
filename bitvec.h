#ifndef _bitvec_h_
#define _bitvec_h_

#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <utility>

class bitvec {
    size_t		size;
    union {
	uintptr_t	data;
	uintptr_t	*ptr;
    };
public:
    static constexpr size_t bits_per_unit = CHAR_BIT * sizeof(uintptr_t);
    class bitref {
	friend class bitvec;
	bitvec		&set;
	int		idx;
	bitref(bitvec &s, int i) : set(s), idx(i) {}
    public:
	bitref(const bitref &a) = default;
	bitref(bitref &&a) = default;
	bool operator=(bool b) const {
	    assert(idx >= 0);
	    return b ? set.setbit(idx) : set.clrbit(idx); }
	bool operator=(int b) const {
	    assert(idx >= 0);
	    return b ? set.setbit(idx) : set.clrbit(idx); }
	operator bool() const { return set.getbit(idx); }
	operator int() const { return set.getbit(idx) ? 1 : 0; }
	int index() { return idx; }
	bitref &operator++() {
	    while ((size_t)++idx < set.size * bitvec::bits_per_unit)
		if (set.getbit(idx)) return *this;
	    idx = -1;
	    return *this; }
	bitref &operator--() {
	    while (--idx >= 0)
		if (set.getbit(idx)) return *this;
	    return *this; }
    };
    bitvec() : size(1), data(0) {}
    bitvec(unsigned long v) : size(1), data(v) {}
    bitvec(size_t lo, size_t hi) : size(1), data(0) { setrange(lo, hi); }
    bitvec(const bitvec &a) : size(a.size) {
	if (size > 1) {
	    ptr = new uintptr_t[size];
	    memcpy(ptr, a.ptr, size * sizeof(*ptr));
	} else
	    data = a.data; }
    bitvec(bitvec &&a) : size(a.size), data(a.data) { a.size = 1; }
    bitvec &operator=(const bitvec &a) {
	if (this == &a) return *this;
	if (size > 1) delete [] ptr;
	if ((size = a.size) > 1) {
	    ptr = new uintptr_t[size];
	    memcpy(ptr, a.ptr, size * sizeof(*ptr));
	} else
	    data = a.data;
	return *this; }
    bitvec &operator=(bitvec &&a) {
	std::swap(*this, a);
	return *this; }
    ~bitvec() { if (size > 1) delete [] ptr; }

    void clear() {
	if (size > 1) memset(ptr, 0, size * sizeof(*ptr));
	else data = 0; }
    bool setbit(size_t idx) {
	if (idx >= size * bits_per_unit) expand(1 + idx/bits_per_unit);
	if (size > 1)
	    ptr[idx/bits_per_unit] |= (uintptr_t)1 << (idx%bits_per_unit);
	else
	    data |= (uintptr_t)1 << idx;
	return true; }
    void setrange(size_t idx, size_t sz) {
	if (idx+sz > size * bits_per_unit) expand(1 + (idx+sz-1)/bits_per_unit);
        if (size == 1) {
            data |= ~(~(uintptr_t)1 << (sz-1)) << idx;
        } else if (idx/bits_per_unit == (idx+sz-1)/bits_per_unit) {
            ptr[idx/bits_per_unit] |=
                ~(~(uintptr_t)1 << (sz-1)) << (idx%bits_per_unit);
        } else {
            size_t i = idx/bits_per_unit;
            ptr[i] |= ~(uintptr_t)0 << (idx%bits_per_unit);
            idx += sz;
            while (++i < idx/bits_per_unit) {
                ptr[i] = ~0; }
            ptr[i] |= (((uintptr_t)1 << (idx%bits_per_unit)) - 1); } }
    bool clrbit(size_t idx) {
	if (idx >= size * bits_per_unit) return false;
	if (size > 1)
	    ptr[idx/bits_per_unit] &= ~((uintptr_t)1 << (idx%bits_per_unit));
	else
	    data &= ~((uintptr_t)1 << idx);
	return false; }
    bool getbit(size_t idx) const {
	if (idx >= size * bits_per_unit) return false;
	if (size > 1)
	    return (ptr[idx/bits_per_unit] >> (idx%bits_per_unit)) & 1;
	else
	    return (data >> idx) & 1;
	return false; }
    uintptr_t getrange(size_t idx, size_t sz) const {
        assert(sz > 0 && sz <= bits_per_unit);
	if (idx >= size * bits_per_unit) return 0;
        if (size > 1) {
            unsigned shift = idx % bits_per_unit;
            idx /= bits_per_unit;
            uintptr_t rv = ptr[idx] >> shift;
            if (shift != 0 && idx + 1 < size)
                rv |= ptr[idx + 1] << (bits_per_unit - shift);
	    return rv & ~(~(uintptr_t)1 << (sz-1)); 
        } else
	    return (data >> idx) & ~(~(uintptr_t)1 << (sz-1)); }
    bitref operator[](int idx) { return bitref(*this, idx); }
    bool operator[](int idx) const { return getbit(idx); }
    bitref min() { return ++bitref(*this, -1); }
    bitref max() { return --bitref(*this, size * bits_per_unit); }
    bool empty() const {
	if (size > 1) {
	    for (size_t i = 0; i < size; i++)
		if (ptr[i] != 0) return false;
	    return true;
	} else return data == 0; }
    bool operator&=(const bitvec &a) {
	bool rv = false;
	if (size > 1) {
	    if (a.size > 1) {
		for (size_t i = 0; i < size && i < a.size; i++) {
		    rv |= ((ptr[i] & a.ptr[i]) != ptr[i]);
		    ptr[i] &= a.ptr[i]; }
	    } else {
		rv |= ((*ptr & a.data) != *ptr);
		*ptr &= a.data; }
	    if (size > a.size) {
		if (!rv)
		    for (size_t i = a.size; i < size; i++)
			if (ptr[i]) { rv = true; break; }
		memset(ptr + a.size, 0, (size-a.size) * sizeof(*ptr)); }
	} else if (a.size > 1) {
	    rv |= ((data & a.ptr[0]) != data);
	    data &= a.ptr[0];
	} else {
	    rv |= ((data & a.data) != data);
	    data &= a.data; }
	return rv; }
    bitvec operator&(const bitvec &a) const {
	bitvec rv(*this); rv &= a; return rv; }
    bool operator|=(const bitvec &a) {
	bool rv = false;
	if (size < a.size) expand(a.size);
	if (size > 1) {
	    if (a.size > 1) {
		for (size_t i = 0; i < a.size; i++) {
		    rv |= ((ptr[i] | a.ptr[i]) != ptr[i]);
		    ptr[i] |= a.ptr[i]; }
	    } else {
		rv |= ((*ptr | a.data) != *ptr);
		*ptr |= a.data; }
	} else {
	    rv |= ((data | a.data) != data);
	    data |= a.data; }
	return rv; }
    bitvec operator|(const bitvec &a) const {
	bitvec rv(*this); rv |= a; return rv; }
    bitvec &operator^=(const bitvec &a) {
	if (size < a.size) expand(a.size);
	if (size > 1) {
	    if (a.size > 1)
		for (size_t i = 0; i < a.size; i++) ptr[i] ^= a.ptr[i];
	    else
		*ptr ^= a.data;
	} else
	    data ^= a.data;
	return *this; }
    bitvec operator^(const bitvec &a) const {
	bitvec rv(*this); rv ^= a; return rv; }
    bool operator-=(const bitvec &a) {
	bool rv = false;
	if (size > 1) {
	    if (a.size > 1) {
		for (size_t i = 0; i < size && i < a.size; i++) {
		    rv |= ((ptr[i] & ~a.ptr[i]) != ptr[i]);
		    ptr[i] &= ~a.ptr[i]; }
	    } else {
		rv |= ((*ptr & ~a.data) != *ptr);
		*ptr &= ~a.data; }
	} else if (a.size > 1) {
	    rv |= ((data & ~a.ptr[0]) != data);
	    data &= ~a.ptr[0];
	} else {
	    rv |= ((data & ~a.data) != data);
	    data &= ~a.data; }
	return rv; }
    bitvec operator-(const bitvec &a) const {
	bitvec rv(*this); rv -= a; return rv; }
    bool intersects(const bitvec &a) const {
        if (size > 1) {
            if (a.size > 1) {
                for (size_t i = 0; i < size && i < a.size; i++)
                    if (ptr[i] & a.ptr[i]) return true;
                return false;
            } else
                return (ptr[0] & a.data) != 0;
        } else if (a.size > 1)
            return (data & a.ptr[0]) != 0;
        else
            return (data & a.data) != 0; }

private:
    void expand(size_t newsize) {
	assert(newsize > size);
	if (size > 1) {
            uintptr_t *old = ptr;
	    ptr = new uintptr_t[newsize];
            memcpy(ptr, old, size * sizeof(*ptr));
	    memset(ptr + size, 0, (newsize - size) * sizeof(*ptr));
            delete [] old;
	} else {
	    uintptr_t d = data;
	    ptr = new uintptr_t[newsize];
	    *ptr = d;
	    memset(ptr + size, 0, (newsize - size) * sizeof(*ptr));
	}
	size = newsize;
    }
};

#endif // _bitvec_h_
