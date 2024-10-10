#ifndef BF_P4C_LIB_DYN_VECTOR_H_
#define BF_P4C_LIB_DYN_VECTOR_H_

#include <vector>

/// An enhanced version of std::vector that auto-expands for
/// operator[].
template<class T, class _Alloc = std::allocator<T>>
class dyn_vector : public std::vector<T, _Alloc> {
 public:
    using std::vector<T, _Alloc>::vector;
    typedef typename std::vector<T, _Alloc>::reference reference;
    typedef typename std::vector<T, _Alloc>::const_reference const_reference;
    typedef typename std::vector<T, _Alloc>::size_type size_type;
    typedef typename std::vector<T>::const_iterator const_iterator;
    reference operator[](size_type n) {
        if (n >= this->size())
            this->resize(n+1);
        return this->at(n); }
    const_reference operator[](size_type n) const {
        if (n < this->size())
            return this->at(n);
        static const T default_value = T();
        return default_value; }
};

#endif /* BF_P4C_LIB_DYN_VECTOR_H_ */
