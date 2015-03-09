#ifndef _algorithm_h_
#define _algorithm_h_

#include <algorithm>

/* these should all be in <algorithm>, but are missing... */

template<class C, class T>
inline bool contains(C &c, const T &val) {
    return std::find(c.begin(), c.end(), val) != c.end(); }

template<class C, class Pred>
inline bool contains_if(C &c, Pred pred) {
    return std::find_if(c.begin(), c.end(), pred) != c.end(); }

using std::min_element;
using std::max_element;

template<class C>
inline typename C::const_iterator min_element(const C &c) {
    return min_element(c.begin(), c.end()); }

template<class C>
inline typename C::const_iterator max_element(const C &c) {
    return min_element(c.begin(), c.end()); }

#endif /* _algorithm_h_ */
