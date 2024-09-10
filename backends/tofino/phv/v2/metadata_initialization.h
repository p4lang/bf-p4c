#ifndef BF_P4C_PHV_V2_METADATA_INITIALIZATION_H_
#define BF_P4C_PHV_V2_METADATA_INITIALIZATION_H_

#include <algorithm>
#include "backends/tofino/phv/mau_backtracker.h"
#include "backends/tofino/common/field_defuse.h"
#include "backends/tofino/common/utils.h"
#include "backends/tofino/phv/pragma/pa_no_init.h"

namespace PHV {

namespace v2 {
class MetadataInitialization : public PassManager {
    MauBacktracker& backtracker;

 public:
    MetadataInitialization(MauBacktracker& backtracker, const PhvInfo &phv, FieldDefUse& defuse);
};


}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_METADATA_INITIALIZATION_H_ */
