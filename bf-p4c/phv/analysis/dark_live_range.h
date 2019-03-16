#ifndef BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_
#define BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_

#include "ir/ir.h"
#include "lib/log.h"
#include "lib/symbitmatrix.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/phv/utils/live_range_report.h"

class ClotInfo;

/** This class calculates the live range of fields to determine potential for overlay due to
  * spilling into dark containers. The calculated live ranges use the min_stage value for tables
  * determined using the table dependency graph. If overlay(f1->id, f2->id) is true, it means that
  * f1 and f2 could potentially be allocated to the same container by moving one of those fields
  * into a dark container.
  */
class DarkLiveRange : public Inspector {
 public:
    // XXX(Deep): Should we expose a way of changing the DEP_DIST using a command line flag, as
    // glass does?
    static constexpr int DEP_DIST = 1;
    /// Name of the ingress parser state, where the compiler adds all the implicit initializations
    /// for fields with uninitialized reads.
    static constexpr char const *INGRESS_PARSER_ENTRY =
        "$entry_point.$ingress_tna_entry_point";
    /// Name of the egress parser state, where the compiler adds all the implicit initializations
    /// for fields with uninitialized reads.
    static constexpr char const *EGRESS_PARSER_ENTRY =
        "$entry_point.$egress_tna_entry_point";

    /// Given maximum number of MAU stages @max_num_min_stages and two fields with read/write
    /// accesses defined by @range1 and @range2, this method @returns true if the accesses for the
    /// field overlap.
    static bool overlaps(
            const int max_num_min_stages,
            const ordered_map<unsigned, unsigned>& range1,
            const ordered_map<unsigned, unsigned>& range2);

 private:
    PhvInfo                                 &phv;
    const ClotInfo                          &clot;
    const DependencyGraph                   &dg;
    FieldDefUse                             &defuse;
    const PragmaNoOverlay                   &noOverlay;
    const PhvUse                            &uses;

    /// List of fields that are marked as pa_no_init, which means that we assume the live range of
    /// these fields is from the first use of it to the last use.
    const ordered_set<const PHV::Field*>    &noInitFields;
    /// List of fields that are marked as not parsed.
    const ordered_set<const PHV::Field*>    &notParsedFields;
    /// List of fields that are marked as not deparsed.
    const ordered_set<const PHV::Field*>    &notDeparsedFields;

    /// overlay(f1->id, f2->id) true if the live ranges of fields f1 and f2 allow overlay. Overlay
    /// is considered possible if the live ranges according to the table dependency graph's
    /// `min_stage` calculation have a stage separation of DEP_DIST or more.
    SymBitMatrix&                           overlay;

    /// Map of field ID to the live range for each field.
    ordered_map<const PHV::Field*, ordered_map<unsigned, unsigned>> livemap;

    profile_t init_apply(const IR::Node* root) override;
    void end_apply() override;

    /// Pretty print the live ranges of all metadata fields.
    cstring printLiveRanges() const;

    /// Calculate and set the live range for field @f.
    void setFieldLiveMap(const PHV::Field* f);

    /// Padding fields have special requirements for live ranges: they are only alive at the ingress
    /// deparser and the egress parser. This function sets the live range for a padding field @f.
    void setPaddingFieldLiveMap(const PHV::Field* f);

 public:
    /// @returns the live ranges of all metadata fields: key is field ID and the value is the live
    /// range pair [minStage, maxStage], where parser = -1 and deparser = Device::numStages().
    const ordered_map<const PHV::Field*, ordered_map<unsigned, unsigned>>&
    getMetadataLiveMap() const {
        return livemap;
    }

    /// @returns true if fields @f1 and @f2 are found to be potentially overlayable because of their
    /// live ranges.
    bool hasPotentialLiveRangeOverlay(const PHV::Field* f1, const PHV::Field* f2) const {
        return overlay(f1->id, f2->id);
    }

    explicit DarkLiveRange(
            PhvInfo& p,
            const ClotInfo& c,
            const DependencyGraph& g,
            FieldDefUse& f,
            const PHV::Pragmas& pragmas,
            const PhvUse& u,
            const MauBacktracker&)
        : phv(p),
          clot(c),
          dg(g),
          defuse(f),
          noOverlay(pragmas.pa_no_overlay()),
          uses(u),
          noInitFields(pragmas.pa_no_init().getFields()),
          notParsedFields(pragmas.pa_deparser_zero().getNotParsedFields()),
          notDeparsedFields(pragmas.pa_deparser_zero().getNotDeparsedFields()),
          overlay(phv.dark_mutex())
    { }
};

#endif  /* BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_ */
