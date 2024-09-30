#ifndef BF_P4C_COMMON_ELIM_UNUSED_H_
#define BF_P4C_COMMON_ELIM_UNUSED_H_

#include "field_defuse.h"

class ReplaceMember : public Transform {
    const P4::IR::BFN::AliasMember *preorder(P4::IR::BFN::AliasMember *m) {
        return m; }
    const P4::IR::BFN::AliasMember *preorder(P4::IR::Member *m) {
        return new P4::IR::BFN::AliasMember(m, m); }
};

class ElimUnused : public PassManager {
    const PhvInfo       &phv;
    FieldDefUse         &defuse;
    std::set<cstring> &zeroInitFields;

    class Instructions;
    class CollectEmptyTables;
    class Tables;
    class Headers;

 public:
    ElimUnused(const PhvInfo &phv, FieldDefUse &defuse,
                std::set<cstring> &zeroInitFields);
};

class AbstractElimUnusedInstructions : public Transform {
 protected:
    const FieldDefUse& defuse;

    /// Names of fields whose extracts have been eliminated.
    std::set<cstring> eliminated;

    const P4::IR::MAU::StatefulAlu* preorder(P4::IR::MAU::StatefulAlu* salu) override {
        // Don't go through these.
        prune();
        return salu;
    }

    const P4::IR::GlobalRef *preorder(P4::IR::GlobalRef *gr) override {
        // Don't go through these.
        prune();
        return gr;
    }

    /// Determines whether the given extract, occurring in the given unit, should be eliminated.
    virtual bool elim_extract(const P4::IR::BFN::Unit* unit, const P4::IR::BFN::Extract* extract) = 0;

    const P4::IR::BFN::Extract* preorder(P4::IR::BFN::Extract* extract) override;
    const P4::IR::BFN::FieldLVal* preorder(P4::IR::BFN::FieldLVal* lval) override;

    explicit AbstractElimUnusedInstructions(const FieldDefUse& defuse)
      : defuse(defuse) { }
};

#endif /* BF_P4C_COMMON_ELIM_UNUSED_H_ */
