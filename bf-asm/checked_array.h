#ifndef BF_ASM_CHECKED_ARRAY_H_
#define BF_ASM_CHECKED_ARRAY_H_

#include <stdlib.h>
#include "log.h"
#include "bfas.h"  // to get at the options

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
    virtual void set_modified(bool v = true) = 0;
    virtual bool disabled() const = 0;
    virtual bool disable() = 0;
    virtual bool disable_if_zero() = 0;
    virtual void enable() = 0;
};

template<size_t S, typename T>
class checked_array : public checked_array_base<T> {
    bool disabled_;
    T data[S];

 public:
    checked_array() : disabled_(false) {}
    template<class U> explicit checked_array(U v) : disabled_(false) {
        for (auto &e : data) new(&e) T(v); }
    template<class U> checked_array(const std::initializer_list<U> &v) : disabled_(false) {
        auto it = v.begin();
        for (auto &e : data) {
            if (it == v.end()) break;
            new(&e) T(*it++); } }
    T& operator[](size_t idx) {
        if (idx >= S) {
            LOG1("ERROR: array index " << idx << " out of bounds " << this);
            BUG(); }
        return data[idx]; }
    const T& operator[](size_t idx) const {
        if (idx >= S) {
            LOG1("ERROR: array index " << idx << " out of bounds " << this);
            BUG(); }
        return data[idx]; }
    size_t size() const { return S; }
    T *begin() { return data; }
    T *end() { return data + S; }
    bool modified() const {
        for (size_t i = 0; i < S; i++)
            if (data[i].modified()) return true;
        return false; }
    void set_modified(bool v = true) {
        for (size_t i = 0; i < S; i++)
            data[i].set_modified(v); }
    bool disabled() const { return disabled_; }
    bool disable() {
        bool rv = true;
        for (size_t i = 0; i < S; i++)
            if (!data[i].disable()) rv = false;
        if (rv) disabled_ = true;
        return rv; }
    void enable() {
        disabled_ = false;
        for (size_t i = 0; i < S; i++)
            data[i].enable(); }
    bool disable_if_unmodified() {
        bool rv = true;
        for (size_t i = 0; i < S; i++)
            if (!data[i].disable_if_unmodified()) rv = false;
        if (rv && !options.gen_json) {
            /* Can't actually disable arrays when generating json, as walle doesn't like it,
             * but allow containing object to be disabled */
            disabled_ = true; }
        return rv; }
    bool disable_if_zero() {
        bool rv = true;
        for (size_t i = 0; i < S; i++)
            if (!data[i].disable_if_zero()) rv = false;
        if (rv && !options.gen_json) {
            /* Can't actually disable arrays when generating json, as walle doesn't like it,
             * but allow containing object to be disabled */
            disabled_ = true; }
        return rv; }
    bool disable_if_reset_value() {
        bool rv = true;
        for (size_t i = 0; i < S; i++)
            if (!data[i].disable_if_reset_value()) rv = false;
        if (rv && !options.gen_json) {
            /* Can't actually disable arrays when generating json, as walle doesn't like it,
             * but allow containing object to be disabled */
            disabled_ = true; }
        return rv; }
};

template<size_t S, typename T>
inline std::ostream &operator<<(std::ostream &out, checked_array<S, T> *arr) {
    print_regname(out, arr, arr+1);
    return out; }

#endif /* BF_ASM_CHECKED_ARRAY_H_ */
