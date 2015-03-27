#ifndef _map_h_
#define _map_h_

#include <map>

template<class K, class T, class V, class Comp, class Alloc>
inline V get(const std::map<K,V,Comp,Alloc> &m, T key, V def = V()) {
    auto it = m.find(key);
    if (it != m.end()) return it->second;
    return def; }

template<class K, class T, class V, class Comp, class Alloc>
inline V *getref(std::map<K,V,Comp,Alloc> &m, T key) {
    auto it = m.find(key);
    if (it != m.end()) return &it->second;
    return 0; }

template<class K, class T, class V, class Comp, class Alloc>
inline const V *getref(const std::map<K,V,Comp,Alloc> &m, T key) {
    auto it = m.find(key);
    if (it != m.end()) return &it->second;
    return 0; }

template<class K, class T, class V, class Comp, class Alloc>
inline V get(const std::map<K,V,Comp,Alloc> *m, T key, V def = V()) {
    return m ? get(*m, key, def) : def; }

template<class K, class T, class V, class Comp, class Alloc>
inline V *getref(std::map<K,V,Comp,Alloc> *m, T key) {
    return m ? getref(*m, key) : 0; }

template<class K, class T, class V, class Comp, class Alloc>
inline const V *getref(const std::map<K,V,Comp,Alloc> *m, T key) {
    return m ? getref(*m, key) : 0; }

/* iterate over the values in a map */
template<class K, class V, class Comp, class Alloc>
class MapValues {
    std::map<K,V,Comp,Alloc>    &m;
    class iterator {
        typename std::map<K,V,Comp,Alloc>::iterator      it;
    public:
        iterator(typename std::map<K,V,Comp,Alloc>::iterator i) : it(i) {}
        iterator &operator++() { ++it; return *this; }
        iterator &operator--() { --it; return *this; }
        bool operator==(const iterator &i) const { return it == i.it; }
        V &operator*() const { return it->second; }
        V *operator->() const { return &it->second; }
    };
    public:
        MapValues(std::map<K,V,Comp,Alloc> &map) : m(map) {}
        iterator begin() { return m.begin(); }
        iterator end() { return m.end(); }
};
template<class K, class V, class Comp, class Alloc>
MapValues<K, V, Comp, Alloc>
Values(std::map<K,V,Comp,Alloc> &m) { return MapValues<K,V,Comp,Alloc>(m); }

#endif /* _map_h_ */
