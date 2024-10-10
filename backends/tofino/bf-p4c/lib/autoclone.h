#ifndef _BF_P4C_LIB_AUTOCLONE_H_
#define _BF_P4C_LIB_AUTOCLONE_H_

#include <memory>

/** Adaptor/wrapper class for std::unique_ptr that allows copying by cloning the
 *  pointed at object.  An autoclone_ptr can be used when you want to make a pointer
 *  field act like a value field -- any copy of the containing object will deep-copy
 *  all the autoclone_ptr-referenced objects avoid any accidental shallow copy aliasing
 *  or slicing (particularly useful for dynamic classes).
 */
template<class T, class D = std::default_delete<T>>
class autoclone_ptr : public std::unique_ptr<T, D> {
 public:
    autoclone_ptr() = default;
    autoclone_ptr(autoclone_ptr &&) = default;
    autoclone_ptr &operator=(autoclone_ptr &&) = default;
    autoclone_ptr(const autoclone_ptr &a) : std::unique_ptr<T,D>(a ? a->clone() : nullptr) {}
    autoclone_ptr &operator=(const autoclone_ptr &a) {
        auto *t = a.get();
        this->reset(t ? t->clone() : nullptr);
        return *this; }
};

#endif  /* _BF_P4C_LIB_AUTOCLONE_H_ */
