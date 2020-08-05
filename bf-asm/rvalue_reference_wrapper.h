#ifndef BF_ASM_RVALUE_REFERENCE_WRAPPER_H_
#define BF_ASM_RVALUE_REFERENCE_WRAPPER_H_

template<class T>
class rvalue_reference_wrapper {
    T   *ref;
 public:
    typedef T type;
    rvalue_reference_wrapper(T &&r) : ref(&r) {}  // NOLINT(runtime/explicit)
    template<class U>
    rvalue_reference_wrapper(U &&r) : ref(&r) {}  // NOLINT(runtime/explicit)
    T &&get() { return std::move(*ref); }
};

#endif /* BF_ASM_RVALUE_REFERENCE_WRAPPER_H_ */
