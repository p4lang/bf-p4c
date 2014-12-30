#ifndef _map_h_
#define _map_h_

#include <map>

template<class K, class T, class V, class Comp, class Alloc>
inline V get(const std::map<K,V,Comp,Alloc> &m, T key, V def = V()) {
    auto it = m.find(key);
    if (it != m.end()) return it->second;
    return def; }

template<class K, class T, class V, class Comp, class Alloc>
inline V get(const std::map<K,V,Comp,Alloc> *m, T key, V def = V()) {
    if (m) {
        auto it = m->find(key);
        if (it != m->end()) return it->second; }
    return def; }

#endif /* _map_h_ */
