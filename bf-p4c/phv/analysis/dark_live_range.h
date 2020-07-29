#ifndef BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_
#define BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_

#include "lib/symbitmatrix.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/map_tables_to_actions.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/phv/analysis/dominator_tree.h"
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
    using ReadWritePair = std::pair<const PHV::AllocSlice*, const PHV::AllocSlice*>;

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
    };

    struct OrderedFieldInfo {
        const PHV::AllocSlice& field;
        StageAndAccess minStage;
        StageAndAccess maxStage;
        ordered_set<const IR::BFN::Unit*> units;

        explicit OrderedFieldInfo(
                const PHV::AllocSlice& f,
                const StageAndAccess acc,
                const AccessInfo& a)
            : field(f) {
            // Initial access means that minStage = maxStage.
            minStage = std::make_pair(acc.first, acc.second);
            maxStage = std::make_pair(acc.first, acc.second);
            for (const auto* u : a.first)
                units.insert(u);
        }

        void addAccess(StageAndAccess s, const AccessInfo& a) {
            // Check that the access is not the same as the min access.
            BUG_CHECK(minStage != s, "New access cannot be the same as the min access.");
            // Check that the access is not the same as the max access recorded so far.
            BUG_CHECK(maxStage != s, "New access cannot be the same as the max access.");
            // Check that the access to be added represents a stage after the max access recorded so
            // far.
            BUG_CHECK(maxStage.first < s.first ||
                     (maxStage.first == s.first && maxStage.second < s.second),
                     "New access must be greater than max access.");
            maxStage.first = s.first;
            maxStage.second = s.second;
            units.insert(a.first.begin(), a.first.end());
        }

        bool operator == (const OrderedFieldInfo& other) const {
            if (field != other.field) return false;
            if (minStage != other.minStage) return false;
            if (maxStage != other.maxStage) return false;
            if (units.size() != other.units.size()) return false;
            for (const auto* u : units)
                if (!other.units.count(u)) return false;
            for (const auto* u : other.units)
                if (!units.count(u)) return false;
            return true;
        }

        bool operator != (const OrderedFieldInfo& other) const {
            return !(*this == other);
        }
    };

    using OrderedFieldSummary = std::vector<OrderedFieldInfo>;

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
    const BuildDominatorTree                &domTree;
    const ActionPhvConstraints              &actionConstraints;
    // const MauBacktracker                    &alloc;

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

    const TablesMutuallyExclusive           &tableMutex;
    const MapTablesToActions                &tablesToActions;

    int DEPARSER;

    /// Map of field ID to the live range for each field.
    DarkLiveRangeMap livemap;
    ordered_map<const PHV::Field*, ordered_map<const IR::BFN::Unit*, PHV::FieldUse>>
        fieldToUnitUseMap;
    ordered_set<const PHV::Field*> doNotInitToDark;
    ordered_set<const IR::MAU::Action*> doNotInitActions;
    ordered_set<const IR::MAU::Table*> doNotInitTables;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Table* tbl) override;
    bool preorder(const IR::MAU::Action* act) override;
    void end_apply() override;

    /// Calculate and set the live range for field @f.
    void setFieldLiveMap(const PHV::Field* f);

    boost::optional<OrderedFieldSummary> produceFieldsInOrder(
            const ordered_set<PHV::AllocSlice>& fields) const;

    boost::optional<ReadWritePair> getFieldsLiveAtStage(
            const ordered_set<PHV::AllocSlice>& fields,
            const int stage) const;

    bool validateLiveness(const OrderedFieldSummary& slices) const;

    const IR::MAU::Table* getGroupDominator(
            const PHV::Field* f,
            const ordered_set<const IR::BFN::Unit*>& f_units,
            gress_t gress) const;

    bool increasesDependenceCriticalPath(
            const IR::MAU::Table* use,
            const IR::MAU::Table* init) const;

    boost::optional<PHV::Allocation::ActionSet> getInitActions(
            const PHV::Container& c,
            const OrderedFieldInfo& field,
            const IR::MAU::Table* t,
            const PHV::Transaction& alloc) const;

    boost::optional<PHV::DarkInitMap> getInitPointsForTable(
            const PHV::ContainerGroup& group,
            const PHV::Container& c,
            const IR::MAU::Table* t,
            const OrderedFieldInfo& lastField,
            const OrderedFieldInfo& currentField,
            PHV::DarkInitMap& initMap,
            bool moveLastFieldToDark,
            bool initializeCurrentField,
            bool initializeFromDark,
            const PHV::Transaction& alloc) const;

    const PHV::Container getBestDarkContainer(
            const ordered_set<PHV::Container>& darkContainers,
            const OrderedFieldInfo& field,
            const PHV::Transaction& alloc) const;

    bool mustMoveToDark(
            const OrderedFieldInfo& field,
            const OrderedFieldSummary& fieldsInOrder) const;

    bool mustInitializeCurrentField(
            const OrderedFieldInfo& field,
            const ordered_set<const IR::BFN::Unit*>& fieldUses) const;

    bool mustInitializeFromDarkContainer(
            const OrderedFieldInfo& field,
            const OrderedFieldSummary& fieldsInOrder) const;

    bool mutexSatisfied(const OrderedFieldInfo& info, const IR::MAU::Table* t) const;

    bool cannotInitInAction(
            const PHV::Container& c,
            const IR::MAU::Action* action,
            const PHV::Transaction& alloc) const;

    boost::optional<PHV::DarkInitEntry> getInitForLastFieldToDark(
            const PHV::Container& c,
            const PHV::ContainerGroup& group,
            const IR::MAU::Table* t,
            const OrderedFieldInfo& field,
            const PHV::Transaction& alloc,
            const PHV::StageAndAccess nxtFieldMaxStage) const;

    boost::optional<PHV::DarkInitEntry> getInitForCurrentFieldFromDark(
            const PHV::Container& c,
            const IR::MAU::Table* t,
            const OrderedFieldInfo& field,
            PHV::DarkInitMap& initMap,
            const PHV::Transaction& alloc) const;

    boost::optional<PHV::DarkInitEntry> getInitForCurrentFieldWithZero(
            const PHV::Container& c,
            const IR::MAU::Table* t,
            const OrderedFieldInfo& field,
            const PHV::Transaction& alloc) const;

    bool ignoreReachCondition(
            const OrderedFieldInfo& currentField,
            const OrderedFieldInfo& lastField,
            const ordered_set<std::pair<const IR::BFN::Unit*, const IR::BFN::Unit*>>& conflicts)
        const;

    bool isGroupDominatorEarlierThanFirstUseOfCurrentField(
            const OrderedFieldInfo& currentField,
            const ordered_set<const IR::BFN::Unit*>& doms,
            const IR::MAU::Table* groupDominator) const;

    boost::optional<PHV::DarkInitEntry> generateInitForLastStageAlwaysInit(
            const OrderedFieldInfo& field,
            const OrderedFieldInfo* previousField,
            const PHV::DarkInitMap& darkInitMap) const;

 public:
    boost::optional<PHV::DarkInitMap> findInitializationNodes(
            const PHV::ContainerGroup& group,
            const PHV::Container& c,
            const ordered_set<PHV::AllocSlice>& fields,
            const PHV::Transaction& alloc) const;

    explicit DarkLiveRange(
            PhvInfo& p,
            const ClotInfo& c,
            const DependencyGraph& g,
            FieldDefUse& f,
            const PHV::Pragmas& pragmas,
            const PhvUse& u,
            const BuildDominatorTree& d,
            const ActionPhvConstraints& actions,
            const MauBacktracker&,
            const TablesMutuallyExclusive& t,
            const MapTablesToActions& m)
        : phv(p), clot(c), dg(g), defuse(f), noOverlay(pragmas.pa_no_overlay()), uses(u),
          domTree(d), actionConstraints(actions),
          noInitFields(pragmas.pa_no_init().getFields()),
          notParsedFields(pragmas.pa_deparser_zero().getNotParsedFields()),
          notDeparsedFields(pragmas.pa_deparser_zero().getNotDeparsedFields()),
          overlay(phv.dark_mutex()), tableMutex(t), tablesToActions(m) { }
};

/** This pass is the pass manager for dark containers based overlay and provides external interfaces
  * to PHV analysis for the same purpose.
  */
class DarkOverlay : public PassManager {
 private:
    TablesMutuallyExclusive         tableMutex;
    DarkLiveRange                   initNode;

 public:
    bool suitableForDarkOverlay(const PHV::AllocSlice& slice) const;

    boost::optional<PHV::DarkInitMap> findInitializationNodes(
            const PHV::ContainerGroup& group,
            const ordered_set<PHV::AllocSlice>& alloced,
            const PHV::AllocSlice& slice,
            const PHV::Transaction& alloc) const {
        if (!suitableForDarkOverlay(slice)) return boost::none;
        ordered_set<PHV::AllocSlice> fields;
        PHV::Container c;
        for (auto& sl : alloced) {
            fields.insert(PHV::AllocSlice(sl));
            if (c == PHV::Container())
                c = sl.container();
            else
                BUG_CHECK(c == sl.container(),
                          "Containers for dark overlay candidates are different.");
        }
        BUG_CHECK(c != PHV::Container(),
                  "Container candidate for dark overlay cannot be NULL.");
        BUG_CHECK(c == slice.container(), "Needs to be the same container");
        fields.insert(PHV::AllocSlice(slice));
        return initNode.findInitializationNodes(group, c, fields, alloc);
    }

    explicit DarkOverlay(
            PhvInfo& p,
            const ClotInfo& c,
            const DependencyGraph& g,
            FieldDefUse& f,
            const PHV::Pragmas& pragmas,
            const PhvUse& u,
            const ActionPhvConstraints& actions,
            const BuildDominatorTree& d,
            const MapTablesToActions& m,
            const MauBacktracker& a);
};

#endif  /* BF_P4C_PHV_ANALYSIS_DARK_LIVE_RANGE_H_ */