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

/** @brief Builds "clusters" of PHV fields that must be placed in the same
 * group.
 *
 * Fields that are operands in the same MAU instruction must be placed at the
 * same alignment in PHV containers in the same MAU group.  An AlignedCluster
 * is formed using UnionFind to union fields in the same instruction.
 *
 * Additionally, some fields are required to be placed in the same container
 * (at different offsets).  Hence, their clusters must be placed in the same
 * MAU group.  A SuperCluster holds clusters that must be placed together,
 * along with a set of FieldLists, which are fields that must be placed (in
 * order) in the same container.
 *
 * @pre An up-to-date PhvInfo object.
 * @post A list of cluster groups, accessible via Clustering::cluster_groups().
 */
class Clustering : public PassManager {
    PhvInfo& phv_i;
    PhvUse& uses_i;

    /// Holds all clusters.  Every field is in exactly one cluster.
    // XXX(cole): Does this have to hold pointers?
    std::list<PHV::AlignedCluster *> clusters_i;

    /// Groups of clusters that must be placed in the same MAU group.  Every
    /// cluster is in exactly one cluster group.
    std::list<PHV::SuperCluster *> cluster_groups_i;

    class MakeSuperClusters : public Inspector {
        Clustering& self;
        PhvInfo& phv_i;
        PhvUse&  uses_i;

        /// Collection of field lists, each of which contains fields that must
        /// be placed, in order, in the same container.
        ordered_set<PHV::SuperCluster::FieldList*> field_lists_i;

        /// Operands of `set` instructions, which induce SuperCluster unions
        /// but don't need to be placed in the same container, like field lists.
        ordered_set<std::pair<PHV::Field*, PHV::Field*>> set_operands_i;

        /// Create lists of fields that need to be allocated in the same container.
        bool preorder(const IR::HeaderRef*) override;

        /// Operands of `set` instructions need to be in the same SuperCluster.
        bool preorder(const IR::Primitive*) override;

        /// Create cluster groups by taking the union of clusters of fields
        /// that appear in the same list.
        void end_apply();

     public:
        explicit MakeSuperClusters(Clustering &self)
        : self(self), phv_i(self.phv_i), uses_i(self.uses_i) { }
    };

    class MakeClusters : public Inspector {
        Clustering& self;
        PhvInfo& phv_i;
        const PhvUse&  uses_i;

        /// The Union-Find data structure, which is used to build clusters.
        UnionFind<PHV::Field*> union_find_i;

        /// Initialize the UnionFind data structure with all fields in phv_i.
        profile_t init_apply(const IR::Node *root);

        /// Union all operands of each primitive instruction.
        bool preorder(const IR::Primitive* primitive) override;

        /// Build AlignedClusters from the UnionFind sets.
        void end_apply() override;

     public:
        explicit MakeClusters(Clustering &self)
        : self(self), phv_i(self.phv_i), uses_i(self.uses_i) { }
    };

 public:
    Clustering(PhvInfo &p, PhvUse &u)
    : phv_i(p), uses_i(u) {
        addPasses({
            new MakeClusters(*this),    // populates clusters_i
            new MakeSuperClusters(*this)        // populates cluster_groups_i
        });
    }

    /// @returns all clusters, where every field is in exactly one clusters.
    const std::list<PHV::SuperCluster*>& cluster_groups() const { return cluster_groups_i; }
};

#endif /* BF_P4C_PHV_MAKE_CLUSTERS_H_ */
