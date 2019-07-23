#include <assert.h>
#include "bf-p4c/common/utils.h"
#include "bf-p4c/mau/instruction_memory.h"
#include "ir/ir.h"

bool IR::MAU::Table::operator==(const IR::MAU::Table &a) const {
    return name == a.name &&
           gress == a.gress &&
           gateway_cond == a.gateway_cond &&
           logical_id == a.logical_id &&
           gateway_rows == a.gateway_rows &&
           gateway_payload == a.gateway_payload &&
           match_table == a.match_table &&
           attached == a.attached &&
           actions == a.actions &&
           next == a.next &&
           match_key == a.match_key &&
           always_run == a.always_run &&
           has_dark_init == a.has_dark_init &&
           layout == a.layout &&
           ways == a.ways &&
           resources == a.resources;
}

IR::MAU::Table::Layout &IR::MAU::Table::Layout::operator +=(const IR::MAU::Table::Layout &a) {
    total_actions += a.total_actions;
    entries += a.entries;
    gateway |= a.gateway;
    ternary |= a.ternary;
    hash_action |= a.hash_action;
    atcam |= a.atcam;
    has_range |= a.has_range;
    proxy_hash |= a.proxy_hash;
    requires_versioning |= a.requires_versioning;
    ixbar_bytes += a.ixbar_bytes;
    ixbar_width_bits += a.ixbar_width_bits;
    match_width_bits += a.match_width_bits;
    if (a.action_data_bytes > action_data_bytes)
        action_data_bytes = a.action_data_bytes;


    if (a.action_data_bytes_in_table > action_data_bytes_in_table)
        action_data_bytes_in_table = a.action_data_bytes_in_table;

    overhead_bits += a.overhead_bits;
    immediate_bits += a.immediate_bits;
    meter_addr += a.meter_addr;
    stats_addr += a.stats_addr;
    action_addr += a.action_addr;
    ghost_bytes += a.ghost_bytes;
    partition_bits += partition_bits;
    partition_count += partition_count;
    return *this;
}

IR::MAU::Table::IndirectAddress
    &IR::MAU::Table::IndirectAddress::operator +=(const IR::MAU::Table::IndirectAddress &a) {
    shifter_enabled |= a.shifter_enabled;
    address_bits += a.address_bits;
    per_flow_enable |= a.per_flow_enable;
    meter_type_bits += a.meter_type_bits;
    return *this;
}

/** This function can only be used before TablePlacement, or essentially when the IR::MAU::Table
 *  resources object is not yet saved.
 *
 *  This is currently created as a key during the try_place_table algorithm.  These keys,
 *  after the IR is updated in the TablePlacement preorders, should be identical to the keys
 *  after table placement
 */
UniqueId IR::MAU::Table::pp_unique_id(const IR::MAU::AttachedMemory *at,
        bool is_gw, int stage_table, int logical_table,
        UniqueAttachedId::pre_placed_type_t ppt) const {
    BUG_CHECK(!is_placed(), "Illegal call of the pp_unique_id function");

    UniqueId rv;
    rv.name = name;
    if (for_dleft())
        rv.speciality = UniqueId::DLEFT;
    if (layout.atcam)
        rv.speciality = UniqueId::ATCAM;

    // Note that for ATCAM/DLEFT tables, if the logical table isn't provided, then the
    // logical table is initialized to 0.  This is because all indirect attached tables
    // for an ATCAM are attached to logical table 0 in the assembler.  It is a lot easier
    // to call particular functions with this known ahead of time
    if (rv.speciality != UniqueId::NONE && logical_table == -1)
        rv.logical_table = 0;
    else
        rv.logical_table = logical_table;

    rv.stage_table = stage_table;
    rv.is_gw = is_gw;
    if (ppt != UniqueAttachedId::NO_PP)
        rv.a_id = UniqueAttachedId(ppt);
    else if (at != nullptr)
        rv.a_id = at->unique_id();

    return rv;
}

/** Building a unique id for a table after table placement.  Stage Table and Logical Table
 *  information as well as speciality information come directly from the IR.
 *
 *  If creating a unique id for an AttachedMemory table underneath a table in the DAG,
 *  then an AttachedMemory can be passed to the function.  The same is true for gateway information
 *
 *  A unique_id was created every time this function is called.  The reason these stay
 *  consistent through all of the passes is that the name of the table, the stage split of
 *  the table and the logical split of the table do not change after table placement.
 *
 *  For the AttachedMemory ids, these stay consistent if the name and type of the IR class
 *  remain consistent throughout the entirety of the allocation, which is the current invariant
 */
UniqueId IR::MAU::Table::unique_id(const IR::MAU::AttachedMemory *at, bool is_gw) const {
    BUG_CHECK(is_placed(), "Illegal call of the unique_id function");

    UniqueId rv;
    rv.name = name;
    rv.stage_table = stage_split;
    rv.logical_table = logical_split;

    if (for_dleft())
        rv.speciality = UniqueId::DLEFT;
    if (layout.atcam)
        rv.speciality = UniqueId::ATCAM;

    rv.is_gw = is_gw;
    if (at != nullptr)
        rv.a_id = at->unique_id();

    return rv;
}

const IR::MAU::BackendAttached *IR::MAU::Table::get_attached(UniqueId id) const {
    for (auto *at : attached)
        if (unique_id(at->attached) == id)
            return at;
    return nullptr;
}

bool IR::MAU::Table::hit_miss_p4() const {
    for (auto &n : next) {
        if (n.first == "$hit" || n.first == "$miss")
            return true;
    }
    return false;
}

bool IR::MAU::Table::action_chain() const {
    for (auto &n : next) {
        if (n.first[0] != '$') {
            return true;
        }
    }
    return has_exit_action() && has_non_exit_action();
}

bool IR::MAU::Table::has_default_path() const {
    for (auto &n : next) {
        if (n.first == "$default")
            return true;
    }
    return false;
}

bool IR::MAU::Table::has_exit_action() const {
    for (auto &n : actions)
        if (n.second->exitAction) return true;
    return false;
}

// FIXME -- consider memoizing these boolean predicate functions for speed...
bool IR::MAU::Table::has_exit_recursive() const {
    if (has_exit_action()) return true;
    for (auto *n : Values(next))
        for (auto *t : n->tables)
            if (t->has_exit_recursive()) return true;
    return false;
}

bool IR::MAU::Table::has_non_exit_action() const {
    for (auto &n : actions)
        if (!n.second->exitAction) return true;
    return false;
}

int IR::MAU::Table::action_next_paths() const {
    int action_paths = 0;
    for (auto &n : next) {
        if (n.first == "$default" || n.first[0] != '$')
            action_paths++;
    }
    if (has_exit_action())
        action_paths++;
    return action_paths;
}

bool IR::MAU::Table::getAnnotation(cstring name, int &val) const {
    if (!match_table) return false;
    if (auto annot = match_table->annotations->getSingle(name)) {
        if (annot->expr.size() != 1) {
            error(ErrorType::ERR_UNEXPECTED, "%2% pragma provided to table %3% has multiple "
                  "parameters, while only one is expected", annot, name, externalName());
        } else if (auto constant = annot->expr.at(0)->to<IR::Constant>()) {
            val = constant->asInt();
            return true;
        } else {
            error(ErrorType::ERR_INVALID, "%2% pragma provided to table %3% is not a constant",
                  annot, name, externalName()); } }
    return false;
}

bool IR::MAU::Table::getAnnotation(cstring name, ID &val) const {
    if (!match_table) return false;
    if (auto annot = match_table->annotations->getSingle(name)) {
        if (annot->expr.size() != 1) {
            error(ErrorType::ERR_UNEXPECTED, "%2% pragma provided to table %3% has multiple "
                  "parameters, while only one is expected", annot, name, externalName());
        } else if (auto v = annot->expr.at(0)->to<IR::StringLiteral>()) {
            val = *v;
            return true;
        } else {
            error(ErrorType::ERR_INVALID, "%2% pragma provided to table %3% is not a "
                  "string literal", annot, name, externalName()); } }
    return false;
}

bool IR::MAU::Table::getAnnotation(cstring name, std::vector<ID> &val) const {
    if (!match_table) return false;
    bool rv = false;
    for (auto *annot : match_table->getAnnotations()->annotations) {
        if (annot->name != name) continue;
        rv = true;  // found at least 1
        for (auto *expr : annot->expr) {
            if (auto v = expr->to<IR::StringLiteral>())
                val.push_back(*v);
            else
                error(ErrorType::ERR_INVALID, "%2% pragma provided to table %3% is not a "
                      "string literal", annot, name, externalName()); } }
    return rv;
}

int IR::MAU::Table::get_placement_priority() const {
    int rv = 0;
    getAnnotation("placement_priority", rv);
    return rv;
}

int IR::MAU::Table::get_provided_stage(const int *init_stage, int *req_entries) const {
    if (gateway_only()) {
        int min_stage = -1;
        for (auto *seq : Values(next)) {
            int i = -1;
            for (auto *tbl : seq->tables) {
                if (seq->deps[++i]) continue;  // ignore tables dependent on earlier tables in seq
                int stage = tbl->get_provided_stage(nullptr, nullptr);
                if (stage < 0) return -1;  // no minimum stage
                if (stage < min_stage || min_stage == -1)
                    min_stage = stage; } }
        return min_stage; }
    if (!match_table) return -1;

    auto checkPragma = [](const IR::Annotation *annot) {
        bool valid_pragma = true;
        if (annot->expr.size() == 1 || annot->expr.size() == 2) {
            auto stage_pos = annot->expr.at(0)->to<IR::Constant>();
            if (stage_pos == nullptr)
                valid_pragma = false;
            else if (stage_pos->asInt() < 0)
                valid_pragma = false;

            if (annot->expr.size() == 2) {
                auto entries = annot->expr.at(1)->to<IR::Constant>();
                if (entries == nullptr)
                    valid_pragma = false;
                else if (entries->asInt() <= 0)
                    valid_pragma = false;
            }
        } else {
            valid_pragma = false;
        }
        if (!valid_pragma)
            ::error(ErrorType::ERR_INVALID, "Stage pragma provided can have only one or two "
                    "constant parameters >= 0", annot);
        return valid_pragma;
    };

    int geq_stage = init_stage != nullptr ? *init_stage : -1;
    const IR::Annotation *min_stage_annot = nullptr;
    const IR::Annotation *max_stage_annot = nullptr;
    auto stage_annotations = match_table->annotations->where([](const IR::Annotation *annot)
                                                             { return annot->name == "stage"; });
    if (!stage_annotations)
        return -1;

    for (auto *annot : stage_annotations->annotations) {
        if (!checkPragma(annot))
            return -1;

        int curr_stage = annot->expr.at(0)->to<IR::Constant>()->asInt();
        if (curr_stage >= geq_stage) {
            if (min_stage_annot == nullptr) {
                min_stage_annot = annot;
            } else {
                int min_stage = min_stage_annot->expr.at(0)->to<IR::Constant>()->asInt();
                min_stage_annot = curr_stage < min_stage ? annot : min_stage_annot;
            }
        }

        if (max_stage_annot == nullptr) {
            max_stage_annot = annot;
        } else {
            int max_stage = max_stage_annot->expr.at(0)->to<IR::Constant>()->asInt();
            max_stage_annot = curr_stage < max_stage ? max_stage_annot : annot;
        }
    }

    const IR::Annotation *stage_annot = min_stage_annot ? min_stage_annot : max_stage_annot;
    if (!stage_annot)
        return -1;

    if (req_entries) {
        if (stage_annot->expr.size() == 2) {
            *req_entries = stage_annot->expr.at(1)->to<IR::Constant>()->asInt();
        } else {
            *req_entries = -1;
        }
    }

    return stage_annot->expr.at(0)->to<IR::Constant>()->asInt();
}

int IR::MAU::Table::get_random_seed() const {
    int val = -1;
    if (getAnnotation("random_seed", val))
        ERROR_CHECK(val >= 0, "%s: random_seem pragma provided to table %s must be >= 0",
                    srcInfo, externalName());
    return val;
}

int IR::MAU::Table::get_pragma_max_actions() const {
    int pragma_val;
    if (getAnnotation("max_actions", pragma_val)) {
        int num_actions = actions.size();
        int max_limit = InstructionMemory::IMEM_ROWS * InstructionMemory::IMEM_COLORS;
        if (pragma_val < num_actions) {
            error(ErrorType::ERR_INVALID, "Invalid max_actions pragma usage on table %2%.  "
                  "The maximum actions (%3%) specified cannot be less than the number of "
                  "callable actions listed (%4%).",
                  srcInfo, externalName(), pragma_val, num_actions);
            return -1;
        } else if (pragma_val > max_limit) {
            error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "Invalid max_actions pragma usage on "
                  "table %2%.  The maximum actions specified (%3%) cannot exceed %4%.",
                  srcInfo, externalName(), pragma_val, max_limit);
            return -1;
        } else if (pragma_val > num_actions) {
            return pragma_val;
        }
    }
    return -1;
}

bool IR::MAU::Table::is_force_immediate() const {
    int pragma_val;
    if (getAnnotation("force_immediate", pragma_val)) {
            if (pragma_val == 0 || pragma_val == 1) {
                return pragma_val == 1;
            } else {
              error(ErrorType::ERR_INVALID, "Invalid force_immediate pragma usage on table %2%.  "
                    "Only 0 and 1 are allowed.", srcInfo, externalName());
              return false; } }
    return false;
}

int IR::MAU::Table::hit_actions() const {
    int _hit_actions = 0;
    for (auto act : Values(actions)) {
        if (!act->miss_only())
            _hit_actions++;
    }
    int pragma_max_actions = get_pragma_max_actions();
    if (pragma_max_actions > 0) return pragma_max_actions;
    return _hit_actions;
}

bool IR::MAU::Table::for_dleft() const {
    for (auto &k : match_key)
        if (k->for_dleft()) return true;
    return false;
}

cstring IR::MAU::Table::externalName() const {
    return match_table ? match_table->externalName() : name;
}

void IR::MAU::Table::remove_gateway() {
    std::set<cstring> gateway_rows_next_table;
    for (auto &gw : gateway_rows) {
        if (gw.second.isNull()) continue;
        gateway_rows_next_table.insert(gw.second);
    }

    gateway_name = cstring();
    gateway_rows.clear();
    for (auto gw_next : gateway_rows_next_table) {
        next.erase(gw_next);
    }
}

cstring IR::MAU::Action::externalName() const {
    if (auto *name_annot = annotations->getSingle("name"))
        return IR::Annotation::getName(name_annot);
    return name.toString();
}

int IR::MAU::HashGenExpression::nextId = 0;
