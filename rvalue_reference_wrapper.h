#ifndef _rvalue_reference_wrapper_h_
#define _rvalue_reference_wrapper_h_

template<class T>
class rvalue_reference_wrapper {
    T   *ref;
public:
    typedef T type;
    rvalue_reference_wrapper(T &&r) : ref(&r) {}
    template<class U>
    rvalue_reference_wrapper(U &&r) : ref(&r) {}
    T &&get() { return std::move(*ref); }
};

#endif /* _rvalue_reference_wrapper_h_ */
