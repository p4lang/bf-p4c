#ifndef BF_P4C_COMMON_ELIM_UNUSED_H_
#define BF_P4C_COMMON_ELIM_UNUSED_H_

#include "field_defuse.h"

class ReplaceMember : public Transform {
    const IR::BFN::AliasMember *preorder(IR::BFN::AliasMember *m) {
        return m; }
    const IR::BFN::AliasMember *preorder(IR::Member *m) {
        return new IR::BFN::AliasMember(m, m); }
};

class ElimUnused : public PassManager {
    const PhvInfo       &phv;
    FieldDefUse         &defuse;

    class Instructions;
    class CollectEmptyTables;
    class Tables;
    class Headers;

 public:
    ElimUnused(const PhvInfo &phv, FieldDefUse &defuse);
};

#endif /* BF_P4C_COMMON_ELIM_UNUSED_H_ */
