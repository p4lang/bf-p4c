#ifndef _checked_array_
#define _checked_array_

#include <assert.h>
#include <stdlib.h>
#include "log.h"

void print_regname(std::ostream &out, const void *addr, const void *end);

template<size_t S, typename T> class checked_array;
template<size_t S, typename T>
std::ostream &operator<<(std::ostream &out, checked_array<S, T> *arr);

template<typename T>
class checked_array_base {
public:
    virtual T& operator[](size_t) = 0;
    virtual const T& operator[](size_t) const = 0;
    virtual size_t size() const = 0;
    virtual T *begin() = 0;
    virtual T *end() = 0;
    virtual bool modified() const = 0;
    virtual bool disabled() const = 0;
    virtual void disable() = 0;
    virtual bool disable_if_zero() = 0;
};

template<size_t S, typename T>
class checked_array : public checked_array_base<T> {
    bool disabled_;
    T data[S];
public:
    checked_array() : disabled_(false) {};
    checked_array(const T &v) : disabled_(false) { for (auto &e : data) e = v; }
    checked_array(const std::initializer_list<T> &v) : disabled_(false) {
        auto it = v.begin();
        for (auto &e : data) {
            if (it == v.end()) break;
            e = *v++; } }
    T& operator[](size_t idx) {
        assert(idx < S);
        if (disabled_) ERROR("Accessing disabled record " << this);
        return data[idx]; }
    const T& operator[](size_t idx) const {
        assert(idx < S);
        return data[idx]; }
    size_t size() const { return S; }
    T *begin() { return data; }
    T *end() { return data + S; }
    bool modified() const {
        for (size_t i = 0; i < S; i++)
            if (data[i].modified()) return true;
        return false; }
    bool disabled() const { return disabled_; }
    void disable() {
        if (modified()) ERROR("Disabling modified record " << this);
        disabled_ = true; }
    bool disable_if_zero() {
        bool rv = true;
        for (size_t i = 0; i < S; i++)
            if (!data[i].disable_if_zero()) rv = false;
        /* Can't actually disable arrays, as walle doesn't like it, but allow
         * containing object to be disabled */
        return rv; }
};

template<size_t S, typename T>
inline std::ostream &operator<<(std::ostream &out, checked_array<S, T> *arr) {
    print_regname(out, arr, arr+1);
    return out; }

#endif /* _checked_array_ */
