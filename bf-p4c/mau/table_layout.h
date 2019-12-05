#ifndef BF_P4C_MAU_TABLE_LAYOUT_H_
#define BF_P4C_MAU_TABLE_LAYOUT_H_

#include "bf-p4c/mau/action_format.h"
#include "bf-p4c/mau/attached_output.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/safe_vector.h"

class LayoutOption {
 public:
    IR::MAU::Table::Layout layout;
    IR::MAU::Table::Way way;
    safe_vector<int> way_sizes;
    safe_vector<int> partition_sizes;
    safe_vector<int> dleft_hash_sizes;
    int entries = 0;
    int srams = 0, maprams = 0, tcams = 0;
    int select_bus_split = -1;
    int action_format_index = -1;
    bool previously_widened = false;
    bool identity = false;
    LayoutOption() {}
    explicit LayoutOption(const IR::MAU::Table::Layout l, int i)
        : layout(l), action_format_index(i) {}
    LayoutOption(const IR::MAU::Table::Layout l, const IR::MAU::Table::Way w, int i)
        : layout(l), way(w), action_format_index(i) {}
    void clear_mems() {
        srams = 0;
        maprams = 0;
        tcams = 0;
        entries = 0;
        select_bus_split = -1;
        way_sizes.clear();
        partition_sizes.clear();
        dleft_hash_sizes.clear();
    }

    int logical_tables() const {
        if (partition_sizes.size() > 0)
            return static_cast<int>(partition_sizes.size());
        else if (dleft_hash_sizes.size() > 0)
            return static_cast<int>(dleft_hash_sizes.size());
        return 1;
    }
};

class LayoutChoices {
 public:
    using FormatType_t = ActionData::FormatType_t;
    using LayoutOptionsPerType = std::map<ActionData::FormatType_t, safe_vector<LayoutOption>>;
    using ActionFormatsPerType =
            std::map<ActionData::FormatType_t, safe_vector<ActionData::Format::Use>>;

    std::map<cstring /* table name */, MeterALU::Format::Use> total_meter_output_format;
    std::map<cstring, LayoutOptionsPerType> total_layout_options;
    std::map<cstring, ActionFormatsPerType> total_action_formats;

    safe_vector<LayoutOption> get_layout_options(const IR::MAU::Table *t,
                                                 ActionData::FormatType_t type) const {
        safe_vector<LayoutOption> empty;
        if (t == nullptr)
            return empty;
        if (total_layout_options.count(t->name) == 0)
            return empty;
        auto &lo_by_type = total_layout_options.at(t->name);
        if (lo_by_type.count(type) == 0)
            return empty;
        return lo_by_type.at(type);
    }

    safe_vector<ActionData::Format::Use> get_action_formats(const IR::MAU::Table *t,
                                                            ActionData::FormatType_t type) const;
    MeterALU::Format::Use get_attached_formats(const IR::MAU::Table *t) const {
        MeterALU::Format::Use empty;
        if (t == nullptr)
            return empty;
        else if (total_meter_output_format.find(t->name) == total_meter_output_format.end())
            return empty;
        return total_meter_output_format.at(t->name);
    }

    void clear() {
        total_layout_options.clear();
        total_action_formats.clear();
        total_meter_output_format.clear();
    }
};

extern std::ostream &operator<<(std::ostream &, ActionData::FormatType_t);

/** Checks to see if the action(s) have hash distribution or rng access somewhere */
class GetActionRequirements : public MauInspector {
    bool _hash_dist_needed = false;
    bool _rng_needed = false;
    bool preorder(const IR::MAU::HashDist *) {
        _hash_dist_needed = true;
        return false;
    }
    bool preorder(const IR::MAU::RandomNumber *) {
        _rng_needed = true;
        return false;
    }

 public:
    bool is_hash_dist_needed() { return _hash_dist_needed; }
    bool is_rng_needed() { return _rng_needed; }
};


class RandomExternUsedOncePerAction : public MauInspector {
    using RandExterns = ordered_set<const IR::MAU::RandomNumber *>;
    using RandKey = std::pair<const IR::MAU::Table *, const IR::MAU::Action *>;
    ordered_map<RandKey, RandExterns> rand_extern_per_action;
    void postorder(const IR::MAU::RandomNumber *rn) override;

    Visitor::profile_t init_apply(const IR::Node *node) override {
        auto rv = MauInspector::init_apply(node);
        rand_extern_per_action.clear();
        return rv;
    }

 public:
    RandomExternUsedOncePerAction() {}
};

class MeterColorMapramAddress : public PassManager {
    ordered_map<const IR::MAU::Table *, bitvec> occupied_buses;
    ordered_map<const IR::MAU::Meter *, bitvec> possible_addresses;

    Visitor::profile_t init_apply(const IR::Node *node) override {
        auto rv = PassManager::init_apply(node);
        occupied_buses.clear();
        possible_addresses.clear();
        return rv;
    }

    class FindBusUsers : public MauInspector {
        MeterColorMapramAddress &self;
        bool preorder(const IR::MAU::IdleTime *) override;
        bool preorder(const IR::MAU::Counter *) override;
        // Don't want to visit AttachedOutputs/StatefulCall
        bool preorder(const IR::MAU::Action *) override { return false; }

     public:
        explicit FindBusUsers(MeterColorMapramAddress &self) : self(self) { }
    };

    class DetermineMeterReqs : public MauInspector {
        MeterColorMapramAddress &self;
        bool preorder(const IR::MAU::Meter *) override;
        // Don't want to visit AttachedOutputs/StatefulCall
        bool preorder(const IR::MAU::Action *) override { return false; }

     public:
        explicit DetermineMeterReqs(MeterColorMapramAddress &self) : self(self) { }
    };

    class SetMapramAddress : public MauModifier {
        MeterColorMapramAddress &self;
        bool preorder(IR::MAU::Meter *) override;
        // Don't want to visit AttachedOutputs/StatefulCall
        bool preorder(IR::MAU::Action *) override { return false; }

     public:
        explicit SetMapramAddress(MeterColorMapramAddress &self) : self(self) { }
    };

 public:
    MeterColorMapramAddress() {
        addPasses({
            new FindBusUsers(*this),
            new DetermineMeterReqs(*this),
            new SetMapramAddress(*this)
        });
    }
};

class DoTableLayout : public MauModifier, Backtrack {
    // In order to know how many field sections can be packed together into the same byte
    struct MatchByteKey {
        cstring name;
        int lo;
        int ixbar_multiplier;
        int match_multiplier;

        MatchByteKey(cstring n, int l, int im, int mm)
            : name(n), lo(l), ixbar_multiplier(im), match_multiplier(mm) { }

        bool operator<(const MatchByteKey &mbk) const {
            if (name != mbk.name) return name < mbk.name;
            if (lo != mbk.lo) return lo < mbk.lo;
            if (ixbar_multiplier < mbk.ixbar_multiplier)
                return ixbar_multiplier < mbk.ixbar_multiplier;
            if (match_multiplier < mbk.match_multiplier)
                return match_multiplier < mbk.match_multiplier;
            return false;
        }
    };

    static constexpr int MIN_PACK = 1;
    static constexpr int MAX_PACK = 9;
    // FIXME: Technically this is 5, but need to update version bit information
    static constexpr int MAX_ENTRIES_PER_ROW = 5;

    PhvInfo &phv;
    LayoutChoices &lc;
    SplitAttachedInfo &att_info;
    bool alloc_done = false;
    int get_hit_actions(const IR::MAU::Table *tbl);
    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &trig) override;
    bool preorder(IR::MAU::Table *tbl) override;
    bool preorder(IR::MAU::Action *act) override;
    bool preorder(IR::MAU::TableKey *read) override;
    bool preorder(IR::MAU::Selector *sel) override;
    void check_for_alpm(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl,
        cstring &partition_index);
    void check_for_proxy_hash(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl);
    bool check_for_versioning(const IR::MAU::Table *tbl);
    void setup_instr_and_next(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl);
    void setup_match_layout(IR::MAU::Table::Layout &, const IR::MAU::Table *);
    void setup_gateway_layout(IR::MAU::Table::Layout &, IR::MAU::Table *);
    void setup_exact_match(IR::MAU::Table *tbl, IR::MAU::Table::Layout &layout,
        ActionData::FormatType_t format_type, int action_data_bytes_in_table,
        int immediate_bits, int index);
    void setup_layout_options(IR::MAU::Table *tbl,
        safe_vector<IR::MAU::Table::Layout> &layouts_per_type);
    void setup_action_layout(IR::MAU::Table *tbl);
    void setup_ternary_layout_options(IR::MAU::Table *tbl,
        safe_vector<IR::MAU::Table::Layout> &layouts_per_type);
    void setup_layout_option_no_match(IR::MAU::Table *tbl,
        safe_vector<IR::MAU::Table::Layout> &layouts_per_type);
    void setup_indirect_ptrs(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl,
        ActionData::FormatType_t format_type);
    void attach_random_seed(IR::MAU::Table *tbl);
    bool can_be_hash_action(IR::MAU::Table *tbl, std::string &reason);
    void add_hash_action_option(IR::MAU::Table *tbl, IR::MAU::Table::Layout &layout,
        ActionData::FormatType_t format_type, bool &hash_action_only);
    void determine_byte_impacts(const IR::MAU::Table *tbl, IR::MAU::Table::Layout &layout,
        std::map<MatchByteKey, safe_vector<le_bitrange>> &byte_impacts, bool &partition_found,
        cstring partition_index);

 public:
    explicit DoTableLayout(PhvInfo &p, LayoutChoices &l, SplitAttachedInfo &sai)
        : phv(p), lc(l), att_info(sai) {}
    static void check_for_ternary(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl);
    static void check_for_atcam(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl,
                                cstring &partition_index, const PhvInfo& phv);
};

class ValidateActionProfileFormat : public MauInspector {
    const LayoutChoices &lc;

    bool preorder(const IR::MAU::ActionData *) override;

 public:
    explicit ValidateActionProfileFormat(const LayoutChoices &l) : lc(l) { visitDagOnce = false; }
};

class ValidateTableSize : public MauInspector {
    bool preorder(const IR::MAU::Table *) override;

 public:
    ValidateTableSize() { }
};

class ProhibitAtcamWideSelectors : public MauInspector {
    bool preorder(const IR::MAU::Table *) override { visitOnce(); return true; }
    bool preorder(const IR::MAU::Selector *) override;
 public:
     ProhibitAtcamWideSelectors() { visitDagOnce = false; }
};


class CheckPlacementPriorities : public MauInspector {
    ordered_map<cstring, std::set<cstring>> placement_priorities;
    bool run_once = false;

    profile_t init_apply(const IR::Node *root) override {
        auto rv = MauInspector::init_apply(root);
        placement_priorities.clear();
        return rv;
    }

    bool preorder(const IR::MAU::Table *tbl) override;
    void end_apply() override;

 public:
    CheckPlacementPriorities() {}
};

class TableLayout : public PassManager {
    LayoutChoices &lc;
    SplitAttachedInfo &att_info;

    profile_t init_apply(const IR::Node *root) override;
 public:
    TableLayout(PhvInfo &p, LayoutChoices &l, SplitAttachedInfo &sia);
};

/// Run after TablePlacement to assign LR(t) values for counters.
/// Collect RAMs used by each counter in each stage.
/// For each counter in each stage, calculate LR(t) values (if necessary).
class AssignCounterLRTValues : public PassManager {
 private:
  std::map<UniqueId, int> totalCounterRams = {};

 public:
  Visitor::profile_t init_apply(const IR::Node *root) override {
    auto rv = PassManager::init_apply(root);
    totalCounterRams.clear();
    return rv;
  }

  class FindCounterRams : public MauInspector {
   private:
    AssignCounterLRTValues &self_;
   public:
    bool preorder(const IR::MAU::Table *table) override;
    explicit FindCounterRams(AssignCounterLRTValues &self) : self_(self) { }
  };

  class ComputeLRT : public MauModifier {
   private:
    AssignCounterLRTValues &self_;
    void calculate_lrt_threshold_and_interval(const IR::MAU::Table *tbl,
                                              IR::MAU::Counter *cntr);
   public:
    bool preorder(IR::MAU::Counter *cntr) override;
    explicit ComputeLRT(AssignCounterLRTValues &self) : self_(self) { }
  };

  AssignCounterLRTValues() {
    addPasses({
      new FindCounterRams(*this),
      new ComputeLRT(*this)
    });
  }
};

#endif /* BF_P4C_MAU_TABLE_LAYOUT_H_ */