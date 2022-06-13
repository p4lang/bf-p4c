#ifndef BF_P4C_PHV_ALLOCATE_TEMPS_AND_FINALIZE_LIVERANGE_H_
#define BF_P4C_PHV_ALLOCATE_TEMPS_AND_FINALIZE_LIVERANGE_H_

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "ir/ir.h"

namespace PHV {

// TODO (Yumin): Enhance logs during PHV::AllocateTempsAndFinalizeLiverange to indentify
// and log these conditions in phv logs where a field mutex is not consistent with a table mutex
//
// Two non-mutex fields, f_a and f_b, are overlaid in B0.
// f_a's live range: [-1w, 4r]
// f_b's live range: [3w, 7r]
// It's not a BUG, because when the table t_a that writes f_a are mutex
// with table t_b that reads f_b, hence they will not cause read / write violations
//
//             stage 3         stage 4
//    |---- t_a writes B0
// ---|
//    |--------------------- t_b reads B0
//

class AllocateTempsAndFinalizeLiverange : public PassManager {
    PhvInfo& phv_i;
    const ClotInfo& clot_i;
    const FieldDefUse &defuse_i;

 public:
    AllocateTempsAndFinalizeLiverange(PhvInfo& phv, const ClotInfo& clot,
                                      const FieldDefUse& defuse);
};

}  // namespace PHV

#endif /* BF_P4C_PHV_ALLOCATE_TEMPS_AND_FINALIZE_LIVERANGE_H_ */
