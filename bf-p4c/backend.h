#ifndef BF_P4C_BACKEND_H_
#define BF_P4C_BACKEND_H_

#include "ir/ir.h"
#include "bf-p4c-options.h"

#include "bf-p4c/common/bridged_metadata_replacement.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/mau/table_mutex.h"

class FieldDefUse;

namespace BFN {

class Backend : public PassManager {
    SymBitMatrix mutually_exclusive_field_ids;
    ClotInfo clot;
    PhvInfo phv;
    PhvUse uses;
    DependencyGraph deps;
    FieldDefUse defuse;
    TablesMutuallyExclusive mutex;
    CollectBridgedFields bridged_fields;
    /// List of field names which should not be privatized. Detected by ValidateAllocation pass and
    /// used by Privatization (when invoked due to backtracking) or UndoPrivatization to prevent
    /// privatization.
    ordered_set<cstring> doNotPrivatize;

 public:
    explicit Backend(const BFN_Options& options);

    const PhvInfo       &get_phv()    const { return phv; }
    const ClotInfo      &get_clot()   const { return clot; }
    const FieldDefUse   &get_defuse() const { return defuse; }
};

}  // namespace BFN

#endif /* BF_P4C_BACKEND_H_ */
