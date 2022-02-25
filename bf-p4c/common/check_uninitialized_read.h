#ifndef BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_
#define BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "ir/ir.h"

class CheckUninitializedRead : public Inspector {
 private:
    const FieldDefUse &defuse;
    const PhvInfo &phv;
    const PHV::Pragmas &pragmas;
    static bool printed;
    ordered_set<const PHV::Field*> pov_protected_fields;
    Phv_Parde_Mau_Use uses;

 protected:
    /// Check if any other fields that share a container with the field in @p use are are extracted
    /// from packet data and are not mutually exclusive.
    ///
    /// @param use Use to check if there are other parser extractions
    ///
    /// @return Boolean value indicating whether one or more other fields share a container with
    ///         @p f that are extracted from packet data and not mutually exclusive.
    bool copackedFieldExtracted(const FieldDefUse::locpair& use);

 public:
    CheckUninitializedRead(
        const FieldDefUse &defuse,
        const PhvInfo &phv,
        const PHV::Pragmas &pragmas) :
        defuse(defuse), phv(phv), pragmas(pragmas), uses(phv) {}
    static void set_printed() {printed = true;}

    // unset_printed is intended to be only used in gtest unit test, the reason to unset printed is
    // because gtest may call CheckUninitializedRead multiple times, but warning message will only
    // presented once. Therefore, gtest may not capture the warning message.
    static void unset_printed() {printed = false;}

    void end_apply() override;
    bool preorder(const IR::BFN::Pipe *) override;
    bool preorder(const IR::BFN::DeparserParameter *) override;
    bool preorder(const IR::BFN::Digest *) override;
};


#endif /* BF_P4C_COMMON_CHECK_UNINITIALIZED_READ_H_ */
