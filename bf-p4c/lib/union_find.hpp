#ifndef BF_P4C_LIB_UNION_FIND_H
#define BF_P4C_LIB_UNION_FIND_H

#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"

/** Implements the Union-Find data structure and algorithm.
 *
 * Construction: O(n), where n is the number of elements.
 * Union(a, b):  O(m * log(n)), where m is the size of the smaller set, n the
 *               larger.
 * Find(x):      O(1)
 *
 * XXX(cole): there are more sophisticated implementations that are more
 *            efficient.
 *
 * @param T the type of elements to form into sets.  Must be eligible for
 *          placement in Set-typed containers.
 * @param T optional type of sets to form.  Must be able to hold elements of
 *          type T.
 */
template <typename T, typename Set = ordered_set<T>>
class UnionFind {
    // Map elements to the set that contains them.  Each element is in exactly
    // one set, and set pointers are never null.
    ordered_map<T, Set*> element_map_i;

    // All the sets.
    ordered_set<Set*> sets_i;

    // Used internally for finding and mutating sets; clients cannot mutate
    // sets.
    Set* internalFind(const T x) {
        BUG_CHECK(element_map_i.find(x) != element_map_i.end(),
                  "UnionFind: looking for element not in data structure: %1%\n"
                  "UnionFind: data structure is\n%2%",
                  cstring::to_cstring(x), cstring::to_cstring(this));
        return element_map_i.at(x);
    }

    // Used internally for finding and mutating sets; clients cannot mutate
    // sets.
    Set* internalFind(const T x) const {
        BUG_CHECK(element_map_i.find(x) != element_map_i.end(),
                  "UnionFind: looking for element not in data structure: %1%\n"
                  "UnionFind: data structure is\n%2%",
                  cstring::to_cstring(x), cstring::to_cstring(this));
        return element_map_i.at(x);
    }

 public:
    /// Creates an empty UnionFind.  Elements can be added with UnionFind::insert.
    UnionFind() { }

    /// Iterates through the sets in this data structure.
    using const_iterator = typename ordered_set<Set*>::const_iterator;
    const_iterator begin() const { return sets_i.begin(); }
    const_iterator end()   const { return sets_i.end(); }

    /// Creates a UnionFind initialized with @all_elements.
    template <typename ContainerOfT>
    explicit UnionFind(ContainerOfT all_elements) {
        for (T& elt : all_elements)
            insert(elt);
    }

    /// Clears the union find data structure
    void clear() {
        element_map_i.clear();
        sets_i.clear();
    }

    /// Adds a new element.  Has no effect if @elt is already present.
    void insert(const T& elt) {
        if (element_map_i.find(elt) != element_map_i.end())
            return;

        auto* set = new Set();
        set->insert(elt);
        sets_i.insert(set);
        element_map_i[elt] = set;
    }

    /// Unions the sets containing @x and @y.
    void makeUnion(const T x, const T y) {
        Set* xs = internalFind(x);
        Set* ys = internalFind(y);

        if (xs == ys)
            return;

        Set* smaller = xs->size() < ys->size() ? xs : ys;
        Set* larger = xs->size() >= ys->size() ? xs : ys;

        // Union the smaller set with the larger and update the element map.
        for (auto elt : *smaller) {
            larger->insert(elt);
            element_map_i[elt] = larger; }

        // Remove the smaller set.
        sets_i.erase(sets_i.find(smaller));
    }

    /// @returns a canonical element of the set containing @x.
    /// @exception if @x is not present.
    const T find(const T x) {
        Set* internal = internalFind(x);
        return *internal->begin();
    }

    /// @returns a copy of the set containing @x.
    /// @exception if @x is not present.
    Set* setOf(const T x) {
        const Set* internal = internalFind(x);
        auto* rv = new Set();
        rv->insert(internal->begin(), internal->end());
        return rv;
    }

    /// @returns a copy of the set containing @x.
    /// @exception if @x is not present.
    Set* setOf(const T x) const {
        const Set* internal = internalFind(x);
        auto* rv = new Set();
        rv->insert(internal->begin(), internal->end());
        return rv;
    }

    /// @returns true if element@e is present in the UnionFind struct.
    /// @returns false otherwise.
    bool contains(const T x) const {
        return element_map_i.count(x);
    }

    /// @returns the size of the largest set in the UnionFind struct.
    size_t maxSize() const {
        size_t rv = 0;
        for (const auto* s : sets_i)
            if (s->size() > rv)
                rv = s->size();
        return rv;
    }
};


template<typename T>
std::ostream &operator<<(std::ostream &out, const UnionFind<T>& uf) {
    for (auto* set : uf) {
        for (auto& x : *set)
            out << x << " ";
        out << std::endl; }
    return out;
}

template<typename T>
std::ostream &operator<<(std::ostream &out, const UnionFind<T>* uf) {
    if (uf)
        out << *uf;
    else
        out << "-null-union-find-";
    return out;
}


#endif  /* BF_P4C_LIB_UNION_FIND_H */
