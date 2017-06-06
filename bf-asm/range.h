#ifndef _range_h_
#define _range_h_

template<class T> class RangeIter {
    int incr;
    T cur, fin;
    RangeIter(T end) : incr(0), cur(end), fin(end) {}
public:
    RangeIter(T start, T end) : incr(start <= end ? 1 : -1), cur(start), fin((T)(end+incr)) {}
    RangeIter begin() const { return *this; }
    RangeIter end() const { return RangeIter(fin); }
    T operator*() const { return cur; }
    bool operator==(const RangeIter &a) const { return cur == a.cur; }
    RangeIter &operator++() { cur = (T)(cur + incr); return *this; }
};

template<class T>
static inline RangeIter<T> Range(T a, T b) { return RangeIter<T>(a, b); }

#endif /* _range_h_ */
