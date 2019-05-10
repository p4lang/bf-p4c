#ifndef BF_P4C_LIB_CMP_H_
#define BF_P4C_LIB_CMP_H_

/// Provides templates for lifting comparison operators from objects to pointers, and deriving
/// related comparison operators on objects.

#define OPERATOR(op, Op)                                       \
    struct Op {                                                \
        bool operator()(const T* left, const T* right) const { \
            return op(left, right);                            \
        }                                                      \
    };                                                         \
    static bool op(const T* left, const T* right)

/// Lifts == on objects to functions and functors for == and != on pointers, and also derives !=
/// on objects. The virtual operator== is assumed to implement an equivalence relation.
template <class T>
class LiftEqual {
 public:
    virtual bool operator==(const T&) const = 0;

    bool operator!=(const T& other) const { return !(operator==(other)); }

    OPERATOR(equal, Equal) {
        if (left != right && left && right) return *left == *right;
        return left == right;
    }

    OPERATOR(not_equal, NotEqual) { return !equal(left, right); }
};

/// Lifts < on objects to functions and functors for ==, !=, <, >, <=, and >= on pointers, and also
/// derives ==, !=, >, <=, and >= on objects. The lifted virtual operator< is assumed to implement
/// a strict weak ordering relation.
template <class T>
class LiftLess {
 public:
    virtual bool operator<(const T&) const = 0;

    bool operator==(const T& other) const { return !operator!=(other); }

    bool operator!=(const T& other) const {
        return operator<(other) || operator>(other);
    }

    bool operator> (const T& other) const {
        return other.operator<(*dynamic_cast<const T*>(this));
    }

    bool operator<=(const T& other) const { return !operator>(other); }
    bool operator>=(const T& other) const { return !(operator<(other)); }

    OPERATOR(not_equal, NotEqual) {
        return less(left, right) || greater(left, right);
    }

    OPERATOR(less, Less) {
        if (left != right && left && right) return *left < *right;
        return left < right;
    }

    OPERATOR(equal, Equal)                { return !not_equal(left, right); }
    OPERATOR(greater, Greater)            { return less(right, left); }
    OPERATOR(less_equal, LessEqual)       { return !greater(left, right); }
    OPERATOR(greater_equal, GreaterEqual) { return !less(left, right); }
};

/// Similar to LiftLess, except allows subclasses to provide a more efficient ==. The virtual
/// operator== is assumed to be the equivalence relation induced by operator<.
template <class T>
class LiftCompare : public LiftEqual<T>, public LiftLess<T> {
 public:
    bool operator!=(const T& other) const {
        return LiftEqual<T>::operator!=(other);
    }

    OPERATOR(equal, Equal) {
        return LiftEqual<T>::equal(left, right);
    }

    OPERATOR(not_equal, NotEqual) {
        return LiftEqual<T>::not_equal(left, right);
    }
};

#endif /* BF_P4C_LIB_CMP_H_ */
