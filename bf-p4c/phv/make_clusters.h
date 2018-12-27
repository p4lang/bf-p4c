#ifndef BF_P4C_PHV_MAKE_CLUSTERS_H_
#define BF_P4C_PHV_MAKE_CLUSTERS_H_

#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/lib/union_find.hpp"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/analysis/pack_conflicts.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/mau/gateway.h"

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
    const PackConflicts& conflicts_i;
    const ActionPhvConstraints& actions_i;

    /// Holds all aligned clusters.  Every slice is in exactly one cluster.
    std::list<PHV::AlignedCluster *> aligned_clusters_i;

    /// Holds all rotational clusters.  Every aligned cluster is in exactly
    /// one rotational cluster.
    std::list<PHV::RotationalCluster *> rotational_clusters_i;

    /// Groups of rotational clusters that must be placed in the same MAU
    /// group.  Every rotational cluster is in exactly one super cluster.
    std::list<PHV::SuperCluster *> super_clusters_i;

    /// Maps fields to their slices.  Slice lists are ordered from LSB to MSB.
    ordered_map<const PHV::Field*, std::list<PHV::FieldSlice>> fields_to_slices_i;

    /// Collects validity bits involved in complex instructions, i.e.
    /// instructions that do anything other than assign a constant to the
    /// validity bit. Fields that are involved in the same assignment statement
    /// are part of the same UnionFind set.
    UnionFind<const PHV::Field*> complex_validity_bits_i;

    /// Utility method for querying fields_to_slices_i.
    /// @returns the slices of @field in `fields_to_slices_i` overlapping with @range.
    std::vector<PHV::FieldSlice> slices(const PHV::Field* field, le_bitrange range) const;

    /** For backtracking, clear all the pre-existing structs in the Clustering object.
      */
    class ClearClusteringStructs : public Inspector {
        Clustering& self;
        Visitor::profile_t init_apply(const IR::Node* node) override;

     public:
        explicit ClearClusteringStructs(Clustering& self) : self(self) { }
    };

    /** Find validity bits involved in any MAU instruction other than
     *
     *   `*.$valid = n`,
     *
     * where `n` is a constant.
     */
    class FindComplexValidityBits : public Inspector {
        Clustering& self;
        PhvInfo& phv_i;

        bool preorder(const IR::MAU::Instruction*) override;
        void end_apply() override;

     public:
        explicit FindComplexValidityBits(Clustering& self) : self(self), phv_i(self.phv_i) { }
    };

    /** Break each field into slices based on the operations that use it.  For
     * example if a field f is used in two operations:
     *
     *    f1[7:4] = 0xFF;
     *    f1[5:2] = f2[4:0];
     *
     * then the field is split into four slices:
     *
     *    f1[7:6], f1[5:4], f1[3:2], f[1:0]
     *
     * However, if the field has the `no_split` constraint, then it is always
     * placed in a single slice the size of the whole field:
     *
     *    f1[7:0]
     *
     * This makes cluster formation more precise, by only placing field slices
     * in the same cluster for the bits of the fields actually used in the
     * operations.
     */
    class MakeSlices : public Inspector {
        Clustering& self;
        PhvInfo& phv_i;

        /// Sets of sets of slices, where each set of slices must share a
        /// fine-grained slicing.  (We use a vector because duplicates don't
        /// affect correctness.)
        std::vector<ordered_set<PHV::FieldSlice>> equivalences_i;

        /// Start by mapping each field to a single slice the size of the
        /// field.
        profile_t init_apply(const IR::Node *root) override;

        bool preorder(const IR::MAU::Table* tbl) override;

        /// For each occurrence of a field in a slicing operation, split its
        /// slices in fields_to_slice_i along the boundary of the new slice.
        bool preorder(const IR::Expression*) override;

        /// After each operand has been sliced, ensure for each instruction that
        /// the slice granularity of each operand matches.
        void postorder(const IR::MAU::Instruction*) override;

        // TODO: Add a check for shrinking casts that fails if any are
        // detected.

        /// Ensure fields in each UF group share the same fine-grained slicing.
        void end_apply() override;

     public:
        explicit MakeSlices(Clustering &self) : self(self), phv_i(self.phv_i) { }

        /// Utility method for updating fields_to_slices_i.
        /// Splits slices for @field at @range.lo and @range.hi + 1.
        /// @returns true if any new slices were created.
        bool updateSlices(const PHV::Field* field, le_bitrange range);
    };

    MakeSlices          slice_i;

    class MakeAlignedClusters : public Inspector {
        Clustering& self;
        PhvInfo& phv_i;
        const PhvUse&  uses_i;

        /// The Union-Find data structure, which is used to build clusters.
        UnionFind<PHV::FieldSlice> union_find_i;

        /// Initialize the UnionFind data structure with all fields in phv_i.
        profile_t init_apply(const IR::Node *root) override;

        /// Union all operands of each primitive instruction.
        bool preorder(const IR::MAU::Instruction* inst) override;

        /** Union all operands in the gateway.
         * TODO(yumin): gateway operands can be in a same container,
         * and they are only required to be byte-aligned, not necessary in same MAU group.
         */
        bool preorder(const IR::MAU::Table *tbl) override;

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
        bool preorder(const IR::MAU::Instruction*) override;

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
        const PackConflicts& conflicts_i;

        /// Track headers already visited, by tracking the IDs of the first
        /// fields.
        ordered_set<int> headers_i;

        /// Collection of slice lists, each of which contains slices that must
        /// be placed, in order, in the same container.
        ordered_set<PHV::SuperCluster::SliceList*> slice_lists_i;

        /// Helper function for visiting HeaderRefs.
        void visitHeaderRef(const IR::HeaderRef* hr);

        /// Clear state to enable backtracking
        Visitor::profile_t init_apply(const IR::Node *) override;

        /// Create lists of slices that need to be allocated in the same container.
        bool preorder(const IR::ConcreteHeaderRef*) override;

        /// Create lists of slices that need to be allocated in the same container.
        bool preorder(const IR::HeaderStackItemRef*) override;

        /// Create cluster groups by taking the union of clusters of slices
        /// that appear in the same list.
        void end_apply() override;

        /// Pack pov bits into slice lists.
        void pack_pov_bits();

        /// Pack complex pov bits.
        /// XXX(Deep): Add this back in, if needed. No need for this right now.
        /// void pack_complex_pov_bits();

        /// Add padding into slice list for fields that will be marshaled, because they
        /// have exact_container requirement but might be non-byte-aligned.
        /// Singleton padding cluster will be inserted into @p cluster_set, if it is added
        /// into @p slice_lists.
        void addPaddingForMarshaledFields(
                ordered_set<const PHV::RotationalCluster*>& cluster_set,
                ordered_set<PHV::SuperCluster::SliceList*>& slice_lists);

     public:
        explicit MakeSuperClusters(Clustering &self)
        : self(self), phv_i(self.phv_i), conflicts_i(self.conflicts_i) { }
    };

    /** For the deparser zero optimization, we need to make sure that every deparser zero
      * optimizable field is never in a supercluster that also contains non deparser zero fields.
      * This class performs that validation after superclusters are generated.
      */
    class ValidateDeparserZeroClusters : public Inspector {
     private:
        Clustering& self;

        profile_t init_apply(const IR::Node* root) override;

     public:
        explicit ValidateDeparserZeroClusters(Clustering& c) : self(c) { }
    };

 public:
    Clustering(PhvInfo &p, PhvUse &u, const PackConflicts& c, const ActionPhvConstraints& a)
    : phv_i(p), uses_i(u), conflicts_i(c), actions_i(a),  slice_i(*this) {
        addPasses({
            new ClearClusteringStructs(*this),          // clears pre-existing maps
            new FindComplexValidityBits(*this),         // populates complex_validity_bits_i
            &slice_i,
            new MakeAlignedClusters(*this),             // populates aligned_clusters_i
            new MakeRotationalClusters(*this),          // populates rotational_clusters_i
            new MakeSuperClusters(*this),               // populates super_clusters_i
            new ValidateDeparserZeroClusters(*this)     // validate clustering is correct for
                                                        // deparser zero optimization
        });
    }

    /// @returns all clusters, where every slice is in exactly one cluster.
    const std::list<PHV::SuperCluster*>& cluster_groups() const { return super_clusters_i; }
};

#endif /* BF_P4C_PHV_MAKE_CLUSTERS_H_ */
