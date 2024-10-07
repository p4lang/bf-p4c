#ifndef BF_P4C_ARCH_COLLECT_HARDWARE_CONSTRAINED_FIELDS_H_
#define BF_P4C_ARCH_COLLECT_HARDWARE_CONSTRAINED_FIELDS_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/pragma/all_pragmas.h"

namespace BFN {

// This class add hardware constrained fields to pipe->thread[gress].hw_constrained_fields. This is
// a honeypot for Alias pass, so that Alias pass can replace hardware constrained fields' Member
// with AliasMember or AliasSlice. And this part of information can be used in CollectPhvInfo and
// DisableAutoInitMetadata to set Field's properties properly for alias fields for hardware
// constrained fields.

class AddHardwareConstrainedFields : public Modifier {
 public:
    void postorder(IR::BFN::Pipe *) override;
};

class CollectHardwareConstrainedFields : public PassManager {
 public:
    CollectHardwareConstrainedFields() {
        addPasses({
            new AddHardwareConstrainedFields()
        });
    }
};

}  // namespace BFN



#endif  /* BF_P4C_ARCH_COLLECT_HARDWARE_CONSTRAINED_FIELDS_H_ */
