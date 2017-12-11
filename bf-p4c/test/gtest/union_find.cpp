#include "gtest/gtest.h"
#include "bf-p4c/lib/union_find.hpp"
#include "lib/ordered_set.h"

namespace Test {

namespace {

/** @returns true if @left and @right contain the same elements. */
template <typename T>
static bool equivalent(const ordered_set<T>& left, const ordered_set<T>& right) {
    if (left.size() != right.size())
        return false;
    for (auto x : left)
        if (left.find(x) == right.end())
            return false;
    return true;
}

}   // namespace

TEST(UnionFind, ops) {
    ordered_set<int> universe({ 1, 2, 3 });
    UnionFind<int> uf(universe);

    // After creation, all elements are in singleton sets.
    EXPECT_TRUE(equivalent(ordered_set<int>({1}), *uf.setOf(uf.find(1))));
    EXPECT_TRUE(equivalent(ordered_set<int>({2}), *uf.setOf(uf.find(2))));
    EXPECT_TRUE(equivalent(ordered_set<int>({3}), *uf.setOf(uf.find(3))));

    // Union should merge exactly the sets of 1 and 2.
    uf.makeUnion(1, 2);

    EXPECT_TRUE(equivalent(ordered_set<int>({1, 2}), *uf.setOf(uf.find(1))));
    EXPECT_TRUE(equivalent(ordered_set<int>({1, 2}), *uf.setOf(uf.find(2))));
    EXPECT_TRUE(equivalent(ordered_set<int>({3}), *uf.setOf(uf.find(3))));

    // Union should be idempotent.
    uf.makeUnion(1, 2);

    EXPECT_TRUE(equivalent(ordered_set<int>({1, 2}), *uf.setOf(uf.find(1))));
    EXPECT_TRUE(equivalent(ordered_set<int>({1, 2}), *uf.setOf(uf.find(2))));
    EXPECT_TRUE(equivalent(ordered_set<int>({3}), *uf.setOf(uf.find(3))));

    uf.makeUnion(3, 2);

    EXPECT_TRUE(equivalent(ordered_set<int>({1, 2, 3}), *uf.setOf(uf.find(1))));
    EXPECT_TRUE(equivalent(ordered_set<int>({1, 2, 3}), *uf.setOf(uf.find(2))));
    EXPECT_TRUE(equivalent(ordered_set<int>({1, 2, 3}), *uf.setOf(uf.find(3))));
}

}   /* end namespace Test */
