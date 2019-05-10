#ifndef BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_
#define BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_

#include "lib/symbitmatrix.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/phv/utils/live_range_report.h"

/** This class calculates the live range of fields to determine potential for overlay due to
  * spilling into dark containers. The calculated live ranges use the min_stage value for tables
  * determined using the table dependency graph. If overlay(f1->id, f2->id) is true, it means that
  * f1 and f2 could potentially be allocated to the same container by moving one of those fields
  * into a dark container.
  */
class DarkLiveRange : public Inspector {
 private:
    static constexpr unsigned READ = PHV::FieldUse::READ;
    static constexpr unsigned WRITE = PHV::FieldUse::WRITE;
    static constexpr int PARSER = -1;
    using StageAndAccess = PHV::StageAndAccess;

    // Pair of sets of units in which the field has been used, and a bool set to true, if all those
    // units use the field such that it can be sourced/written to a dark container.
    using AccessInfo = std::pair<ordered_set<const IR::BFN::Unit*>, bool>;
    // Single entry in live range map.
    using DarkLiveRangeEntry = ordered_map<StageAndAccess, AccessInfo>;

    // Structure that represents the live range map.
    class DarkLiveRangeMap {
     private:
        ordered_map<const PHV::Field*, DarkLiveRangeEntry> livemap;
        int DEPARSER = -1;

     public:
        /// Pretty print the live ranges of all metadata fields.
        cstring printDarkLiveRanges() const;

        void setDeparserStageValue(int dep) { DEPARSER = dep; }

        int getDeparserStageValue() const { return DEPARSER; }

        boost::optional<DarkLiveRangeEntry> getDarkLiveRange(const PHV::Field* f) const {
            if (livemap.count(f)) return livemap.at(f);
            return boost::none;
        }

        void addAccess(
                const PHV::Field* f,
                int stage,
                unsigned access,
                const IR::BFN::Unit* unit,
                bool dark) {
            StageAndAccess key = std::make_pair(stage, PHV::FieldUse(access));
            bool fieldEntryPresent = livemap.count(f);
            bool accessEntryPresent = fieldEntryPresent && livemap.at(f).count(key);
            if (!fieldEntryPresent || !accessEntryPresent) {
                ordered_set<const IR::BFN::Unit*> units;
                units.insert(unit);
                AccessInfo val = std::make_pair(units, dark);
                livemap[f][key] = val;
                return;
            }
            livemap[f][key].first.insert(unit);
            livemap[f][key].second &= dark;
        }

        void clear() {
            livemap.clear();
        }

        bool count(const PHV::Field* f) const {
            return livemap.count(f);
        }

        const DarkLiveRangeEntry& at(const PHV::Field* f) const {
            return livemap.at(f);
        }

        const AccessInfo& at(const PHV::Field* f, int stage, unsigned access) const {
            StageAndAccess key = std::make_pair(stage, PHV::FieldUse(access));
            return livemap.at(f).at(key);
        }

        bool hasAccess(const PHV::Field* f, int stage, unsigned access) const {
            if (!livemap.count(f)) return false;
            StageAndAccess key = std::make_pair(stage, PHV::FieldUse(access));
            if (!livemap.at(f).count(key)) return false;
            return true;
        }

        bool canBeDark(const PHV::Field* f, int stage, unsigned access) const {
            if (!hasAccess(f, stage, access)) return false;
            StageAndAccess key = std::make_pair(stage, PHV::FieldUse(access));
            return livemap.at(f).at(key).second;
        }
    };

 public:
    /// Given maximum number of MAU stages @max_num_min_stages and two fields with read/write
    /// accesses defined by @range1 and @range2, this method @returns true if the accesses for the
    /// field overlap.
    static bool overlaps(
            const int num_max_min_stages,
            const DarkLiveRangeEntry& range1,
            const DarkLiveRangeEntry& range2);

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

    int DEPARSER;

    /// Map of field ID to the live range for each field.
    DarkLiveRangeMap livemap;
    ordered_map<const PHV::Field*, ordered_map<const IR::BFN::Unit*, PHV::FieldUse>>
        fieldToUnitUseMap;

    profile_t init_apply(const IR::Node* root) override;
    void end_apply() override;

    /// Calculate and set the live range for field @f.
    void setFieldLiveMap(const PHV::Field* f);

 public:
    explicit DarkLiveRange(
            PhvInfo& p,
            const ClotInfo& c,
            const DependencyGraph& g,
            FieldDefUse& f,
            const PHV::Pragmas& pragmas,
            const PhvUse& u)
        : phv(p), clot(c), dg(g), defuse(f), noOverlay(pragmas.pa_no_overlay()), uses(u),
          noInitFields(pragmas.pa_no_init().getFields()),
          notParsedFields(pragmas.pa_deparser_zero().getNotParsedFields()),
          notDeparsedFields(pragmas.pa_deparser_zero().getNotDeparsedFields()),
          overlay(phv.dark_mutex()) { }
};

#endif  /* BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_ */
