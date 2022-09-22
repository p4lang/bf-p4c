#ifndef EXTENSIONS_BF_P4C_COMMON_ALLOC_H_
#define EXTENSIONS_BF_P4C_COMMON_ALLOC_H_

#include <stdlib.h>
#include <stdexcept>
#include <utility>

namespace BFN {

template<class T> class Alloc1Dbase {
    int         size;
    T           *data;
    Alloc1Dbase() = delete;
    Alloc1Dbase(const Alloc1Dbase &) = delete;

 protected:
    explicit Alloc1Dbase(int sz) : size(sz) {
        data = new T[sz];
        for (int i = 0; i < sz; i++) data[i] = T(); }
    Alloc1Dbase(Alloc1Dbase &&a) : size(a.size), data(a.data) { a.data = 0; }
    virtual ~Alloc1Dbase() { delete [] data; }

 public:
    typedef T *iterator;
    typedef T *const_iterator;
    T &operator[](int i) {
        if (i < 0 || i >= size) throw std::out_of_range("Alloc1D");
        return data[i]; }
    const T &operator[](int i) const {
        if (i < 0 || i >= size) throw std::out_of_range("Alloc1D");
        return data[i]; }
    bool operator==(const Alloc1Dbase<T> &t) const {
        for (int i = 0; i < size; i++)
            if (data[i] != t.data[i]) return false;
        return true; }
    bool operator!=(const Alloc1Dbase<T> &t) const { return !(*this==t); }

    void clear() { for (int i = 0; i < size; i++) data[i] = T(); }
    T *begin() { return data; }
    T *end() { return data + size; }
};

template<class T, int S> class Alloc1D : public Alloc1Dbase<T> {
 public:
    Alloc1D() : Alloc1Dbase<T>(S) {}
    Alloc1Dbase<T> &base() { return *this; }
    bool operator!=(const Alloc1D<T,S> &t) const {
        return Alloc1Dbase<T>::operator!=(t); }
};

template<class T> class Alloc2Dbase {
    int         nrows, ncols;
    T           *data;
    template<class U>
    class rowref {
        U       *row;
        int     ncols;
        friend class Alloc2Dbase;
        rowref(U *r, int c) : row(r), ncols(c) {}
     public:
        typedef U *iterator;
        typedef const U *const_iterator;
        U &operator[](int i) const {
            if (i < 0 || i >= ncols) throw std::out_of_range("Alloc2D");
            return row[i]; }
        U *begin() const { return row; }
        U *end() const { return row + ncols; }
    };
    Alloc2Dbase() = delete;
    Alloc2Dbase(const Alloc2Dbase &) = delete;

 protected:
    Alloc2Dbase(int r, int c) : nrows(r), ncols(c) {
        size_t sz = r*c;
        data = new T[sz];
        for (size_t i = 0; i < sz; i++) data[i] = T(); }
    Alloc2Dbase(Alloc2Dbase &&a) : nrows(a.nrows), ncols(a.ncols), data(a.data) { a.data = 0; }
    virtual ~Alloc2Dbase() { delete [] data; }

 public:
    rowref<T> operator[](int i) {
        if (i < 0 || i >= nrows) throw std::out_of_range("Alloc2D");
        return rowref<T>(data+i*ncols, ncols); }
    rowref<const T> operator[](int i) const {
        if (i < 0 || i >= nrows) throw std::out_of_range("Alloc2D");
        return rowref<const T>(data+i*ncols, ncols); }
    T &at(int i, int j) {
        if (i < 0 || i >= nrows || j < 0 || j >= ncols)
            throw std::out_of_range("Alloc2D");
        return data[i*ncols + j]; }
    const T &at(int i, int j) const {
        if (i < 0 || i >= nrows || j < 0 || j >= ncols)
            throw std::out_of_range("Alloc2D");
        return data[i*ncols + j]; }
    T &operator[](std::pair<int, int> i) {
        if (i.first < 0 || i.first >= nrows ||
            i.second < 0 || i.second >= ncols)
            throw std::out_of_range("Alloc2D");
        return data[i.first*ncols + i.second]; }
    bool operator==(const Alloc2Dbase<T> &t) const {
        int sz = nrows*ncols;
        int tsz = t.nrows*t.ncols;
        if (sz != tsz) return false;
        for (int i = 0; i < sz; i++)
            if (data[i] != t.data[i]) return false;
        return true; }
    bool operator!=(const Alloc2Dbase<T> &t) const { return !(*this==t); }

    int rows() const { return nrows; }
    int cols() const { return ncols; }
    void clear() { for (int i = 0; i < nrows*ncols; i++) data[i] = T(); }
};

template<class T, int R, int C> class Alloc2D : public Alloc2Dbase<T> {
 public:
    Alloc2D() : Alloc2Dbase<T>(R, C) {}
    Alloc2Dbase<T> &base() { return *this; }
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_COMMON_ALLOC_H_ */
