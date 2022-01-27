#ifndef BF_P4C_PHV_ALLOCATE_TEMPS_AND_FINALIZE_LIVERANGE_H_
#define BF_P4C_PHV_ALLOCATE_TEMPS_AND_FINALIZE_LIVERANGE_H_

#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "ir/ir.h"

namespace PHV {

class AllocateTempsAndFinalizeLiverange : public PassManager {
    PhvInfo& phv_i;
    const ClotInfo& clot_i;

 public:
    AllocateTempsAndFinalizeLiverange(PhvInfo& phv,  const ClotInfo& clot);
};

}  // namespace PHV

#endif /* BF_P4C_PHV_ALLOCATE_TEMPS_AND_FINALIZE_LIVERANGE_H_ */
