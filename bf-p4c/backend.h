#ifndef BF_P4C_BACKEND_H_
#define BF_P4C_BACKEND_H_

#include "ir/ir.h"
#include "bf-p4c-options.h"

#include "bf-p4c/common/bridged_metadata_replacement.h"
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/parde/decaf.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"

class FieldDefUse;
class FlexiblePacking;
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
    // Dependency Flow Graph Json, is a collection of graphs populated when
    // passed as a parameter to FindDependencyGraph pass. By default graphs are
    // generated once before and once after table placement.
    Util::JsonObject jsonGraph;

    FlexiblePacking *flexiblePacking;
    LogRepackedHeaders *flexibleLogging;
    CollectPhvLoggingInfo *phvLoggingInfo;
    NextTable *nextTblProp;

 public:
    explicit Backend(const BFN_Options& options, int pipe_id, ExtractedTogether&);

    const PhvInfo       &get_phv()     const { return phv; }
    const ClotInfo      &get_clot()    const { return clot; }
    const FieldDefUse   &get_defuse()  const { return defuse; }
    const NextTable *get_nxt_tbl() const { return nextTblProp; }
    const Util::JsonObject &get_prim_json() const { return primNode; }
    const Util::JsonObject &get_json_graph() const { return jsonGraph; }
    const FlexiblePacking  *get_flexible_packing() const { return flexiblePacking; }
    const LogRepackedHeaders *get_flexible_logging() const { return flexibleLogging; }
    const CollectPhvLoggingInfo *get_phv_logging() const { return phvLoggingInfo; }
    const ordered_map<cstring, ordered_set<int>>& get_table_alloc() const {
        return table_summary.getTableAlloc();
    }
};

}  // namespace BFN

#endif /* BF_P4C_BACKEND_H_ */
