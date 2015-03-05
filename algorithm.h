#ifndef _algorithm_h_
#define _algorithm_h_

#include <algorithm>

template<class C, class T>
inline bool contains(C &c, const T &val) {
    return std::find(c.begin(), c.end(), val) != c.end(); }

template<class C, class Pred>
inline bool contains_if(C &c, Pred pred) {
    return std::find_if(c.begin(), c.end(), pred) != c.end(); }

#endif /* _algorithm_h_ */
