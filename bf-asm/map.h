#ifndef _map_h_
#define _map_h_

#include <map>

template<class K, class T, class V, class Comp, class Alloc>
inline V get(const std::map<K, V, Comp, Alloc> &m, T key, V def = V()) {
    auto it = m.find(key);
    if (it != m.end()) return it->second;
    return def; }

template<class K, class T, class V, class Comp, class Alloc>
inline V *getref(std::map<K, V, Comp, Alloc> &m, T key) {
    auto it = m.find(key);
    if (it != m.end()) return &it->second;
    return 0; }

template<class K, class T, class V, class Comp, class Alloc>
inline const V *getref(const std::map<K, V, Comp, Alloc> &m, T key) {
    auto it = m.find(key);
    if (it != m.end()) return &it->second;
    return 0; }

template<class K, class T, class V, class Comp, class Alloc>
inline V get(const std::map<K, V, Comp, Alloc> *m, T key, V def = V()) {
    return m ? get(*m, key, def) : def; }

template<class K, class T, class V, class Comp, class Alloc>
inline V *getref(std::map<K, V, Comp, Alloc> *m, T key) {
    return m ? getref(*m, key) : 0; }

template<class K, class T, class V, class Comp, class Alloc>
inline const V *getref(const std::map<K, V, Comp, Alloc> *m, T key) {
    return m ? getref(*m, key) : 0; }

/* iterate over the values in a map */
template<class PairIter>
struct IterKeys {
    class iterator : public std::iterator<
        typename std::iterator_traits<PairIter>::iterator_category,
        typename std::iterator_traits<PairIter>::value_type,
        typename std::iterator_traits<PairIter>::difference_type,
        typename std::iterator_traits<PairIter>::pointer,
        typename std::iterator_traits<PairIter>::reference> {
        PairIter                it;
     public:
        explicit iterator(PairIter i) : it(i) {}
        iterator &operator++() { ++it; return *this; }
        iterator &operator--() { --it; return *this; }
        iterator operator++(int) { auto copy = *this; ++it; return copy; }
        iterator operator--(int) { auto copy = *this; --it; return copy; }
        bool operator==(const iterator &i) const { return it == i.it; }
        bool operator!=(const iterator &i) const { return it != i.it; }
        decltype(*&it->first) operator*() const { return it->first; }
        decltype(&it->first) operator->() const { return &it->first; }
    } b, e;

    template<class U> IterKeys(U &map) : b(map.begin()), e(map.end()) {}
    IterKeys(PairIter b, PairIter e) : b(b), e(e) {}
    iterator begin() const { return b; }
    iterator end() const { return e; }
};

template<class Map> IterKeys<typename Map::iterator>
Keys(Map &m) { return IterKeys<typename Map::iterator>(m); }

template<class Map> IterKeys<typename Map::const_iterator>
Keys(const Map &m) { return IterKeys<typename Map::const_iterator>(m); }

template<class PairIter> IterKeys<PairIter>
Keys(std::pair<PairIter, PairIter> range) {
    return IterKeys<PairIter>(range.first, range.second); }

/* iterate over the values in a map */
template<class PairIter>
struct IterValues {
    class iterator : public std::iterator<
        typename std::iterator_traits<PairIter>::iterator_category,
        typename std::iterator_traits<PairIter>::value_type,
        typename std::iterator_traits<PairIter>::difference_type,
        typename std::iterator_traits<PairIter>::pointer,
        typename std::iterator_traits<PairIter>::reference> {
        PairIter                it;
     public:
        explicit iterator(PairIter i) : it(i) {}
        iterator &operator++() { ++it; return *this; }
        iterator &operator--() { --it; return *this; }
        iterator operator++(int) { auto copy = *this; ++it; return copy; }
        iterator operator--(int) { auto copy = *this; --it; return copy; }
        bool operator==(const iterator &i) const { return it == i.it; }
        bool operator!=(const iterator &i) const { return it != i.it; }
        decltype(*&it->second) operator*() const { return it->second; }
        decltype(&it->second) operator->() const { return &it->second; }
    } b, e;

    template<class U> IterValues(U &map) : b(map.begin()), e(map.end()) {}
    IterValues(PairIter b, PairIter e) : b(b), e(e) {}
    iterator begin() const { return b; }
    iterator end() const { return e; }
};

template<class Map> IterValues<typename Map::iterator>
Values(Map &m) { return IterValues<typename Map::iterator>(m); }

template<class Map> IterValues<typename Map::const_iterator>
Values(const Map &m) { return IterValues<typename Map::const_iterator>(m); }

template<class PairIter> IterValues<PairIter>
Values(std::pair<PairIter, PairIter> range) {
    return IterValues<PairIter>(range.first, range.second); }

/* iterate over the values for a single key in a multimap */
template<class M> class MapForKey {
    M                           &map;
    typename M::key_type        key;
    class iterator {
        const MapForKey         &self;
        decltype(map.begin())   it;
     public:
        iterator(const MapForKey &s, decltype(map.begin()) i) : self(s), it(i) {}
        iterator &operator++() {
            if (++it != self.map.end() && it->first != self.key)
                it = self.map.end();
            return *this; }
        bool operator==(const iterator &i) const { return it == i.it; }
        bool operator!=(const iterator &i) const { return it != i.it; }
        decltype(*&it->second) operator*() const { return it->second; }
        decltype(&it->second) operator->() const { return &it->second; }
    };
 public:
    MapForKey(M &m, typename M::key_type k) : map(m), key(k) {}
    iterator begin() const { return iterator(*this, map.find(key)); }
    iterator end() const { return iterator(*this, map.end()); }
};

template<class M> MapForKey<M> ValuesForKey(M &m, typename M::key_type k) {
    return MapForKey<M>(m, k); }

#endif /* _map_h_ */