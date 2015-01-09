#ifndef _range_h_
#define _range_h_

template<class T> class RangeIter {
    T cur, fin;
    RangeIter(T end) : cur(end), fin(end) {}
public:
    RangeIter(T start, T end) : cur(start), fin((T)(end+1)) {}
    RangeIter begin() const { return *this; }
    RangeIter end() const { return RangeIter(fin); }
    T operator*() const { return cur; }
    bool operator==(const RangeIter &a) const { return cur == a.cur; }
    RangeIter &operator++() { cur = (T)(cur + 1); return *this; }
};

template<class T>
static inline RangeIter<T> Range(T a, T b) { return RangeIter<T>(a, b); }

#endif /* _range_h_ */
