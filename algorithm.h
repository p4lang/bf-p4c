#ifndef _algorithm_h_
#define _algorithm_h_

#include <algorithm>

template<class C, class Pred>
inline bool contains_if(C &c, Pred pred) {
    return std::find_if(c.begin(), c.end(), pred) != c.end(); }

#endif /* _algorithm_h_ */
