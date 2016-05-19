#ifndef _alloc_h_
#define _alloc_h_

#include <stdlib.h>
#include <stdexcept>

template<class T> class Alloc1Dbase {
    int         size;
    T           *data;
protected:
    Alloc1Dbase(int sz) : size(sz) {
        data = new T[sz];
        for (int i = 0; i < sz; i++) data[i] = T(); }
    Alloc1Dbase(Alloc1Dbase &&a) : size(a.size), data(a.data) { a.data = 0; }
    virtual ~Alloc1Dbase() { delete [] data; }
public:
    T &operator[](int i) {
        if (i < 0 || i >= size) throw std::out_of_range("Alloc1D");
        return data[i]; }
};

template<class T, int S> class Alloc1D : public Alloc1Dbase<T> {
public:
    Alloc1D() : Alloc1Dbase<T>(S) {}
};

template<class T> class Alloc2Dbase {
    int         nrows, ncols;
    T           *data;
    class rowref {
        T       *row;
        int     ncols;
        friend class Alloc2Dbase;
        rowref(T *r, int c) : row(r), ncols(c) {}
    public:
        T &operator[](int i) {
            if (i < 0 || i >= ncols) throw std::out_of_range("Alloc2D");
            return row[i]; }
    };
protected:
    Alloc2Dbase(int r, int c) : nrows(r), ncols(c) {
        size_t sz = r*c;
        data = new T[sz];
        for (size_t i = 0; i < sz; i++) data[i] = T(); }
    Alloc2Dbase(Alloc2Dbase &&a) : nrows(a.nrows), ncols(a.ncols), data(a.data) { a.data = 0; }
    virtual ~Alloc2Dbase() { delete [] data; }
public:
    rowref operator[](int i) {
        if (i < 0 || i >= nrows) throw std::out_of_range("Alloc2D");
        return rowref(data+i*ncols, ncols); }
};

template<class T, int R, int C> class Alloc2D : public Alloc2Dbase<T> {
public:
    Alloc2D() : Alloc2Dbase<T>(R, C) {}
};

#endif /* _alloc_h_ */
