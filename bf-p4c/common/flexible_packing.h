#ifndef EXTENSIONS_BF_P4C_COMMON_FLEXIBLE_PACKING_H_
#define EXTENSIONS_BF_P4C_COMMON_FLEXIBLE_PACKING_H_

#include "ir/ir.h"
#include "lib/symbitmatrix.h"
#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/common/map_tables_to_actions.h"
#include "bf-p4c/mau/action_mutex.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/constraints/constraints.h"
#include "bf-p4c/common/bridged_packing.h"

bool findFlexibleAnnotation(const IR::Type_StructLike*);

/// This class gathers all the bridged metadata fields also used as deparser parameters. The
/// CollectPhvInfo pass sets the deparsed_bottom_bits() property for all deparser parameters to
/// true. Therefore, this alignment constraint needs to be recognized and respected during bridged
/// metadata packing.
class GatherDeparserParameters : public Inspector {
 private:
    const PhvInfo& phv;
    /// Set of detected deparser parameters.
    ordered_set<const PHV::Field*>& params;

    profile_t init_apply(const IR::Node* root) override {
        params.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::DeparserParameter* p) override;

 public:
    explicit GatherDeparserParameters(const PhvInfo& p, ordered_set<const PHV::Field*>& f)
            : phv(p), params(f) { }
};

/// This class identifies all fields initialized in the parser during Phase 0. The output of this
/// pass is used later by RepackFlexHeaders as follows: If a bridged field is also initialized in
/// Phase 0, then that field is not packed with any other field.
class GatherPhase0Fields : public Inspector {
 private:
    const PhvInfo& phv;
    /// Set of all fields initialized in phase 0.
    ordered_set<const PHV::Field*>& noPackFields;
    static constexpr char const *PHASE0_PARSER_STATE_NAME = "ingress::$phase0";

    profile_t init_apply(const IR::Node* root) override {
        noPackFields.clear();
        return Inspector::init_apply(root);
    }

    bool preorder(const IR::BFN::ParserState* p) override;

    bool preorder(const IR::BFN::DigestFieldList* d) override;

 public:
    explicit GatherPhase0Fields(
            const PhvInfo& p,
            ordered_set<const PHV::Field*>& f)
            : phv(p), noPackFields(f) { }
};

using RepackedHeaders = std::vector<std::pair<const IR::HeaderOrMetadata*, std::string>>;

// set of variables for bridged fields (pretty print)
// set of constraints for bridged fields
// helper function to convert between PHV::Field to z3::expr
// constraints are objects on PHV fields
// constraints can be pretty_printed, encoded to z3
class LogRepackedHeaders : public Inspector {
 private:
    // Need this for field names
    const PhvInfo& phv;
    // Contains all of the (potentially) repacked headers
    RepackedHeaders repacked;
    // All headers we have seen before, but with "egress" or "ingress" removed (avoid duplication)
    std::unordered_set<std::string> hdrs;

    // Collects all headers/metadatas that may have been repacked (i.e. have a field that is
    // flexible)
    bool preorder(const IR::HeaderOrMetadata* h) override;

    // Pretty print all of the flexible headers
    void end_apply() override;

    // Returns the full field name
    std::string getFieldName(std::string hdr, const IR::StructField* field) const;

    // Pretty prints a single header/metadata
    std::string pretty_print(const IR::HeaderOrMetadata* h, std::string hdr);

    // Strips the given prefix from the front of the cstring, returns as string
    std::string strip_prefix(cstring str, std::string pre);

 public:
    explicit LogRepackedHeaders(const PhvInfo& p) : phv(p) { }

    std::string asm_output() const;
};

class LogFlexiblePacking : public Logging::PassManager {
    LogRepackedHeaders* flexibleLogging;

 public:
    explicit LogFlexiblePacking(const PhvInfo& phv) :
    Logging::PassManager("flexible_packing", Logging::Mode::AUTO) {
        flexibleLogging = new LogRepackedHeaders(phv);
        addPasses({
            flexibleLogging,
        });
    }

    const LogRepackedHeaders *get_flexible_logging() const { return flexibleLogging; }
};

class FlexiblePacking : public PassManager {
 private:
    const BFN_Options&                                  options;
    CollectIngressBridgedFields                         ingressBridgedFields;
    CollectEgressBridgedFields                          egressBridgedFields;
    MauBacktracker                                      table_alloc;
    PackConflicts                                       packConflicts;
    MapTablesToActions                                  tableActionsMap;
    ActionPhvConstraints                                actionConstraints;
    SymBitMatrix                                        doNotPack;
    TablesMutuallyExclusive                             tMutex;
    ActionMutuallyExclusive                             aMutex;
    ordered_set<const PHV::Field*>                      noPackFields;
    ordered_set<const PHV::Field*>                      deparserParams;
    /* constraint that multiple field must be packed to the same container */
    ordered_set<Constraints::CopackConstraint>          copackConstraints;

    // used by solver-based packing
    ordered_set<const PHV::Field*>                      fieldsToPack;
    PackWithConstraintSolver&                           packWithConstraintSolver;

    RepackedHeaderTypes& repackedTypes;

 public:
    explicit FlexiblePacking(
            PhvInfo& p,
            const PhvUse& u,
            DependencyGraph& dg,
            const BFN_Options &o,
            PackWithConstraintSolver& sol,
            RepackedHeaderTypes& map);

    // Return a Json representation of flexible headers to be saved in .bfa/context.json
    // must be called after the pass is applied
    std::string asm_output() const;

    void solve() { packWithConstraintSolver.solve(); }
};

using ExtractedTogether = ordered_map<cstring, ordered_set<cstring>>;

// PackFlexibleHeader manages the global context for packing bridge metadata
// The global context includes:
// - instance of z3 solver and its context
//
// We need to manage the global context at this level is because bridge
// metadata can be used across multiple pipelines in folded pipeline. To
// support folded pipeline, we first collect bridge metadata constraints across
// each pair of ingress/egress, and run z3 solver over the global set of
// constraints over all pairs of ingress&egress pipelines. Therefore, it
// is necessary to maintain z3 context as this level.
class PackFlexibleHeaders : public PassManager {
    std::vector<const IR::BFN::Pipe*> pipe;
    SymBitMatrix mutually_exclusive_field_ids;
    PhvInfo phv;
    PhvUse uses;
    FieldDefUse defuse;
    DependencyGraph deps;

    z3::context context;
    z3::optimize solver;
    ConstraintSolver constraint_solver;
    PackWithConstraintSolver packWithConstraintSolver;

    FlexiblePacking *flexiblePacking;

 public:
    explicit PackFlexibleHeaders(const BFN_Options& options, ordered_set<cstring>&,
            RepackedHeaderTypes& repackedTypes);

    void solve() { flexiblePacking->solve(); }
};


#endif  /* EXTENSIONS_BF_P4C_COMMON_FLEXIBLE_PACKING_H_ */
