#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_BYTE_PACK_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_BYTE_PACK_H_

#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"
#include "ir/ir.h"
#include "lib/safe_vector.h"

/// PragmaBytePack allows users and also other compiler passes to specify byte layouts
/// of metadata for PHV allocation. The concept `byte layout` can be illustrated in the
/// following example:
/// Assume we have @pa_byte_pack(2, f1<4>, 1, f2<6>, f3<3>), (MSB to LSB)
/// PHV allocation must allocate following 2 bytes to byte-aligned position of containers
/// byte1: [f3, f2<6>[0:4]], byte2: [f2<6>[5:5], pad1<1>, f1<4>, pad0<2>] (LSB to MSB)
/// Internally, we implement this feature by packing fields into a PHV::SuperCluster::SliceList
/// and also updating their alignment constraint. Because alignments of PHV::FieldSlices are
/// computed based on alignments of corresponding PHV::Field, this pass must run *before* creating
/// PHV::FieldSlice (as of v9.8, it is the Clustering pass).
class PragmaBytePack : public Inspector {
 public:
    /// PackConstraint represents a packing constraints. If the constraint is added in the program
    /// @a compiler_added will be false and will have a non-null @a src_info.
    struct PackConstraint {
        bool compiler_added;
        boost::optional<Util::SourceInfo> src_info;
        PHV::PackingLayout packing;
    };

    struct AddConstraintResult {
        /// the set of fields which new alignment constraints were added on.
        ordered_set<const PHV::Field*> alignment_added;
        boost::optional<cstring> error;
        bool ok() const { return !error; }
    };

 private:
    PhvInfo& phv_i;
    safe_vector<PackConstraint> packing_layouts_i;

    /// update alignment Fields in @p packing based on the layout.
    /// if alignment conflict was found, @returns boost::none,
    /// otherwise, @returns a set of fields with updated additional alignment constraint.
    AddConstraintResult add_packing_constraint(const PackConstraint& packing);

    /// clear states.
    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        packing_layouts_i.clear();
        return rv;
    }

    /// read user-defined pa_byte_pack pragmas.
    bool preorder(const IR::BFN::Pipe* pipe) override;

 public:
    explicit PragmaBytePack(PhvInfo& phv) : phv_i(phv) {}

    /// @returns all packing constraints saved.
    const safe_vector<PackConstraint>& packings() const { return packing_layouts_i; }

    /// add additional pack constraints. NOTE: this function must be called before
    /// creating any PHV::FieldSlices because it might change alignment of PHV::Field.
    /// If alignment conflict was found, @returns boost::none,
    /// otherwise, @returns a set of fields with updated additional alignment constraint.
    /// NOTE: the order of @p packing (also for all PHV::PackingLayout instances) needs to be
    /// MSB to LSB.
    AddConstraintResult add_compiler_added_packing(const PHV::PackingLayout& packing);

    /// BFN::Pragma interface
    static const char* name;
    static const char* description;
    static const char* help;
};

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_BYTE_PACK_H_ */
