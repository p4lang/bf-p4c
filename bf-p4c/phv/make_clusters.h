#ifndef BF_P4C_PHV_MAKE_CLUSTERS_H_
#define BF_P4C_PHV_MAKE_CLUSTERS_H_

#include "phv.h"
#include "phv_parde_mau_use.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/lib/union_find.hpp"
#include "bf-p4c/phv/utils.h"

namespace PHV {
class Field;
}  // namespace PHV

class PhvInfo;

/** @brief Builds "clusters" of field slices that must be placed in the same
 * group.
 *
 * Fields that are operands in the same MAU instruction must be placed at the
 * same alignment in PHV containers in the same MAU group.  An AlignedCluster
 * is formed using UnionFind to union slices in the same instruction.
 *
 * Additionally, some slices are required to be placed in the same container
 * (at different offsets).  Hence, their clusters must be placed in the same
 * MAU group.  A SuperCluster holds clusters that must be placed together,
 * along with a set of SliceLists, which are slices that must be placed (in
 * order) in the same container.
 *
 * @pre An up-to-date PhvInfo object.
 * @post A list of cluster groups, accessible via Clustering::cluster_groups().
 */
class Clustering : public PassManager {
    PhvInfo& phv_i;
    PhvUse& uses_i;

    /// Holds all aligned clusters.  Every slice is in exactly one cluster.
    std::list<PHV::AlignedCluster *> aligned_clusters_i;

    /// Holds all rotational clusters.  Every aligned cluster is in exactly
    /// one rotational cluster.
    std::list<PHV::RotationalCluster *> rotational_clusters_i;

    /// Groups of rotational clusters that must be placed in the same MAU
    /// group.  Every rotational cluster is in exactly one super cluster.
    std::list<PHV::SuperCluster *> super_clusters_i;

    class MakeAlignedClusters : public Inspector {
        Clustering& self;
        PhvInfo& phv_i;
        const PhvUse&  uses_i;

        /// The Union-Find data structure, which is used to build clusters.
        UnionFind<PHV::FieldSlice> union_find_i;

        /// Initialize the UnionFind data structure with all fields in phv_i.
        profile_t init_apply(const IR::Node *root) override;

        /// Union all operands of each primitive instruction.
        bool preorder(const IR::Primitive* primitive) override;

        /// Build AlignedClusters from the UnionFind sets.
        void end_apply() override;

     public:
        explicit MakeAlignedClusters(Clustering &self)
        : self(self), phv_i(self.phv_i), uses_i(self.uses_i) { }
    };

    class MakeRotationalClusters : public Inspector {
        Clustering& self;
        PhvInfo& phv_i;

        /// The Union-Find data structure, which is used to build rotational
        /// clusters.
        UnionFind<PHV::AlignedCluster*> union_find_i;

        /// Map slices (i.e. set operands) to the aligned clusters that
        /// contain them.
        ordered_map<const PHV::FieldSlice, PHV::AlignedCluster*> slices_to_clusters_i;

        /// Populate union_find_i with all aligned clusters created in
        /// MakeAlignedClusters.
        Visitor::profile_t init_apply(const IR::Node *) override;

        /// Union AlignedClusters with slices that are operands of `set`
        /// instructions.
        bool preorder(const IR::Primitive*) override;

        /// Create rotational clusters from sets of aligned clusters in
        /// union_find_i.
        void end_apply() override;

     public:
        explicit MakeRotationalClusters(Clustering &self)
        : self(self), phv_i(self.phv_i) { }
    };

    class MakeSuperClusters : public Inspector {
        Clustering& self;
        PhvInfo& phv_i;

        /// Collection of slice lists, each of which contains slices that must
        /// be placed, in order, in the same container.
        ordered_set<PHV::SuperCluster::SliceList*> slice_lists_i;

        /// Create lists of slices that need to be allocated in the same container.
        bool preorder(const IR::HeaderRef*) override;

        /// Create cluster groups by taking the union of clusters of slices
        /// that appear in the same list.
        void end_apply() override;

     public:
        explicit MakeSuperClusters(Clustering &self)
        : self(self), phv_i(self.phv_i) { }
    };

 public:
    Clustering(PhvInfo &p, PhvUse &u)
    : phv_i(p), uses_i(u) {
        addPasses({
            new MakeAlignedClusters(*this),     // populates aligned_clusters_i
            new MakeRotationalClusters(*this),  // populates rotational_clusters_i
            new MakeSuperClusters(*this)        // populates super_clusters_i
        });
    }

    /// @returns all clusters, where every slice is in exactly one cluster.
    const std::list<PHV::SuperCluster*>& cluster_groups() const { return super_clusters_i; }
};

#endif /* BF_P4C_PHV_MAKE_CLUSTERS_H_ */
