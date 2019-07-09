#ifndef BF_P4C_BACKEND_H_
#define BF_P4C_BACKEND_H_

#include "ir/ir.h"
#include "bf-p4c-options.h"

#include "bf-p4c/common/bridged_metadata_replacement.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/parde/decaf.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/mau/jbay_next_table.h"

class FieldDefUse;
struct CollectPhvLoggingInfo;

namespace BFN {

class Backend : public PassManager {
    SymBitMatrix mutually_exclusive_field_ids;
    ClotInfo clot;
    PhvInfo phv;
    PhvUse uses;
    DependencyGraph deps;
    FieldDefUse defuse;
    TablesMutuallyExclusive mutex;
    DeparserCopyOpt decaf;
    CollectBridgedFields bridged_fields;
    /// Bridged fields that must be extracted together (result of bridged metadata packing).
    ordered_map<cstring, ordered_set<cstring>> extracted_together;
    /// Class that represents the backtracking point from table placement to PHV allocation.
    MauBacktracker table_alloc;
    TableSummary table_summary;
    /// List of field names which should not be privatized. Detected by ValidateAllocation pass and
    /// used by Privatization (when invoked due to backtracking) or UndoPrivatization to prevent
    /// privatization.
    ordered_set<cstring> doNotPrivatize;
    // Primitives Json Node, is populated before instruction adjustment and
    // passed to AsmOutput to output primitive json file
    Util::JsonObject primNode;
    // Dynamic Hash Calculations Node, is populated at the end of backend passes
    Util::JsonObject dynHashNode;

    CollectPhvLoggingInfo *phvLoggingInfo;
    NextTableProp *nextTblProp;

 public:
    explicit Backend(const BFN_Options& options, int pipe_id);

    const PhvInfo       &get_phv()     const { return phv; }
    const ClotInfo      &get_clot()    const { return clot; }
    const FieldDefUse   &get_defuse()  const { return defuse; }
    const NextTableProp *get_nxt_tbl() const { return nextTblProp; }
    const Util::JsonObject &get_prim_json() const { return primNode; }
    const Util::JsonObject &get_dynhash_json() const { return dynHashNode; }
    const CollectPhvLoggingInfo *get_phv_logging() const { return phvLoggingInfo; }
    const ordered_map<cstring, ordered_set<int>>& get_table_alloc() const {
        return table_summary.getTableAlloc();
    }
};

}  // namespace BFN

#endif /* BF_P4C_BACKEND_H_ */
