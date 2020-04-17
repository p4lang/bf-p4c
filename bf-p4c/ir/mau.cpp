#include <assert.h>
#include "bf-p4c/common/utils.h"
#include "bf-p4c/mau/instruction_memory.h"
#include "ir/ir.h"

namespace IR {
namespace MAU {

// These must be implemented here because C++ requires the definitions and instantiations of
// function templates to be in the same compilation unit.
void Table::visit_children(Visitor& v) { visit_children(this, v); }
void Table::visit_children(Visitor& v) const { visit_children(this, v); }

template<class THIS>
void Table::visit_children(THIS* self, Visitor& v) {
    // We visit the table in a way that reflects its control flow: at branches, we visit with
    // clones of the visitor; at join points, we merge the clones back together. IMPORTANT: we must
    // ensure that each node is visited exactly once.
    //
    // A table is executed as follows. First, the gateway conditions in "gateway_rows" are
    // evaluated.
    //
    // If no gateway condition is satisfied, the table keys are evaluated. If "next" has a
    // "$try_next_stage" entry, then we nondeterministically choose whether to execute that entry.
    // If there is no "$try_next_stage", or if we choose not to execute it, then we execute a table
    // action, according to the control-plane program. The entry corresponding to "$hit" or "$miss"
    // in "next" is then executed, according to whether the table hit or miss; if neither entry
    // exists, then the "$default" entry in "next" is executed, if it exists.
    //
    // If any condition is satisfied, we have a gateway-inhibited table. The payload in
    // "gateway_payload" is executed, before executing the entry in "next" corresponding to the
    // satisfied condition.

    // Visit gateway conditions.
    for (auto& gw : self->gateway_rows) {
        auto& cond = gw.first;
        v.visit(cond, "gateway_row");
    }

    // Now, we fall into one of four cases, depending on whether the table uses its gateway
    // payload, and on whether the table has a match component.
    bool have_gateway_payload = self->uses_gateway_payload();
    bool have_match_table = !self->gateway_only();

    if (have_gateway_payload && have_match_table) {
        auto& gateway_visitor = v.flow_clone();
        visit_gateway_inhibited(self, gateway_visitor);
        visit_match_table(self, v);
        v.flow_merge(gateway_visitor);
    } else if (have_gateway_payload) {
        visit_gateway_inhibited(self, v);
    } else if (have_match_table) {
        visit_match_table(self, v);
    } else {
        // Have neither a gateway payload nor a match table. This table is a no-op; fall through to
        // attached tables.
    }

    // FIXME -- attached tables are not properly visited here in the control-flow order,
    // FIXME -- because we don't really know which actions will trigger them.  They
    // FIXME -- should be visited after the action(s) that trigger them and before
    // FIXME -- the next tables that happen after those actions?
    // FIXME -- If the actions contain references to them, then they'll be visited when
    // FIXME -- the action is visited, and this will be a 'revisit'
    self->attached.visit_children(v);
}

template<class THIS>
void Table::visit_gateway_inhibited(THIS* self, Visitor& v) {
    // Visit gateway payload.
    v.visit(self->gateway_payload, "gateway_payload");

    // Now, visit actions for when the table is gateway-inhibited.

    // Save the control-flow state. We use v to visit the first execution path through the gateway
    // actions. On subsequent paths, we visit with a copy of this saved state, and merge the result
    // into v.
    Visitor* saved = &v.flow_clone();

    // This is the visitor we will use to visit the various gateway actions. Initially, this is
    // v. After the first execution path, this becomes nullptr, and will be lazily instantiated
    // with a copy of "saved", as needed.
    Visitor* current = &v;

    std::set<cstring> gw_tags_seen;
    bool fallen_through = false;
    for (auto& gw : self->gateway_rows) {
        auto tag = gw.second;
        if (!tag || gw_tags_seen.count(tag)) continue;

        gw_tags_seen.emplace(tag);

        if (self->next.count(tag)) {
            if (!current) current = &saved->flow_clone();
            current->visit(self->next.at(tag), tag);
            if (current != &v) v.flow_merge(*current);
            current = nullptr;

            continue;
        }

        // No matching action, so fall through from "saved" if we haven't done so already.
        if (!fallen_through) {
            if (current) {
                // "current" hasn't been used yet, so just consume it.
                current = nullptr;
            } else {
                v.flow_merge(*saved);
            }

            fallen_through = true;
        }
    }
}

template<class THIS>
void Table::visit_match_table(THIS* self, Visitor& v) {
    // Visit match keys.
    self->match_key.visit_children(v);

    // Save the current control-flow state. We use v to visit the first execution path through the
    // table. On subsequent paths, we visit with a copy of this saved state, and merge the result
    // into v.
    Visitor* saved = &v.flow_clone();

    // This is the visitor we will use to visit the various parts of the table. Initially, this is
    // v. After the first execution path, this becomes nullptr, and will be lazily instantiated
    // with a copy of "saved", as needed.
    Visitor* current = &v;

    // Handle all exiting actions. For these actions, we don't want to merge the control-flow back
    // into v.
    for (auto& action : Values(self->actions)) {
        if (!action->exitAction) continue;

        auto exit_visitor = &saved->flow_clone();
        exit_visitor->visit(action);
        exit_visitor->flow_merge_global_to("-EXIT-");
    }

    // Handle non-exiting actions, while being careful to avoid visiting "next" entries multiple
    // times.

    // This map ensures that we visit the "next" entries in a specific order later on.
    ordered_map<cstring, Visitor*> next_visitors;
    bool have_hit_miss = self->next.count("$hit") || self->next.count("$miss");
    if (have_hit_miss) {
        next_visitors["$hit"] = nullptr;
        next_visitors["$miss"] = nullptr;
    } else {
        next_visitors["$default"] = nullptr;
    }

    // These visitors that will need to be merged back into v once we're done handling "next".
    std::vector<Visitor*> unmerged_table_chain_visitors;

    // Visit all actions to populate next_visitors with visitors to visit "next".
    for (auto& kv : self->actions) {
        auto action_name = kv.first;
        auto& action = kv.second;

        if (action->exitAction) continue;

        // Visit the action.
        if (!current) current = &saved->flow_clone();
        current->visit(action);

        // Figure out which keys in the next_visitors table need updating.

        // Can separate table using hit/miss from tables using action chaining, as in P4
        // semantically, a table can not use both hit/miss and action chaining. Potentially if that
        // changes, we will have to support it with a layered approach to the next table
        // propagation
        std::vector<cstring> keys;
        if (have_hit_miss) {
            // Table uses hit/miss chaining.
            if (!action->miss_only()) keys.push_back("$hit");
            if (!action->hit_only()) keys.push_back("$miss");
        } else {
            // Table uses action chaining.
            if (self->next.count(action_name)) {
                // Action has a "next" entry. Handle it here directly; some visitors apparently
                // expect the chained table sequence to be visited immediately after the action.
                current->visit(self->next.at(action_name), action_name);

                // At this point, v may have already been used to visit a sibling action and may be
                // waiting to visit the "$default" entry in "next". So, we defer merging into v
                // until we are done visiting "next".
                if (current != &v) unmerged_table_chain_visitors.push_back(current);
                current = nullptr;
                continue;
            }

            // The action has no "next" entry. It chains to the entry for "$default".
            keys.push_back("$default");
        }

        // Merge the current visitor into the next_visitors table.
        bool current_used = false;
        for (auto key : keys) {
            BUG_CHECK(next_visitors.count(key), "Unexpected 'next' key: %s", key);
            auto& next_visitor = next_visitors.at(key);
            if (next_visitor) {
                next_visitor->flow_merge(*current);
            } else if (current_used) {
                next_visitor = &current->flow_clone();
            } else {
                next_visitor = current;
                current_used = true;
            }
        }

        current = nullptr;
    }

    // Now visit "next".
    for (auto kv : next_visitors) {
        auto next_action_key = kv.first;
        auto next_visitor = kv.second;

        if (self->next.count(next_action_key)) {
            if (!next_visitor) next_visitor = &saved->flow_clone();
            next_visitor->visit(self->next.at(next_action_key), next_action_key);
        }

        // At this point, v may not have visited its entry in "next" yet. Defer merging into v
        // until we are done visiting "next".
        if (next_visitor && next_visitor != &v)
            unmerged_table_chain_visitors.push_back(next_visitor);
    }

    // Handle any deferred merges.
    for (auto to_merge : unmerged_table_chain_visitors)
        v.flow_merge(*to_merge);

    // Visit $try_next_stage, if it exists.
    if (self->next.count("$try_next_stage")) {
        if (!current) current = &saved->flow_clone();
        current->visit(self->next.at("$try_next_stage"), "$try_next_stage");
        if (current != &v) v.flow_merge(*current);
        current = nullptr;
    }
}

}  // namespace MAU
}  // namespace IR

bool IR::MAU::Table::operator==(const IR::MAU::Table &a) const {
    return name == a.name &&
           gress == a.gress &&
           gateway_cond == a.gateway_cond &&
           stage_ == a.stage_ &&
           logical_id == a.logical_id &&
           gateway_rows == a.gateway_rows &&
           gateway_payload == a.gateway_payload &&
           match_table == a.match_table &&
           attached == a.attached &&
           actions == a.actions &&
           next == a.next &&
           match_key == a.match_key &&
           has_dark_init == a.has_dark_init &&
           always_run == a.always_run &&
           suppress_context_json == a.suppress_context_json &&
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
    partition_bits += a.partition_bits;
    partition_count += a.partition_count;
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

const IR::MAU::BackendAttached *IR::MAU::Table::get_attached(const AttachedMemory *am) const {
    for (auto *at : attached)
        if (at->attached == am)
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

bool IR::MAU::Table::is_exit_table() const {
    if (has_exit_action() && !has_non_exit_action()) {
        return true;
    }
    return false;
}

std::vector<const IR::MAU::Action*> IR::MAU::Table::get_exit_actions() const {
    std::vector<const IR::MAU::Action*> exit_actions;
    for (auto &n : actions)
        if (n.second->exitAction)
            exit_actions.push_back(n.second);
    return exit_actions;
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
            error(ErrorType::ERR_UNEXPECTED, "%1%: %2% pragma provided to table %3% has multiple "
                  "parameters, while only one is expected", annot, name, externalName());
        } else if (auto constant = annot->expr.at(0)->to<IR::Constant>()) {
            val = constant->asInt();
            return true;
        } else {
            error(ErrorType::ERR_INVALID, "Invalid %1%: %2% pragma provided to table %3% is not "
                  "a constant", annot, name, externalName()); } }
    return false;
}

bool IR::MAU::Table::getAnnotation(cstring name, ID &val) const {
    if (!match_table) return false;
    if (auto annot = match_table->annotations->getSingle(name)) {
        if (annot->expr.size() != 1) {
            error(ErrorType::ERR_UNEXPECTED, "%1%: %2% pragma provided to table %3% has multiple "
                  "parameters, while only one is expected", annot, name, externalName());
        } else if (auto v = annot->expr.at(0)->to<IR::StringLiteral>()) {
            val = *v;
            return true;
        } else {
            error(ErrorType::ERR_INVALID, "Invalid %1%: %2% pragma provided to table %3% is not a "
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
                error(ErrorType::ERR_INVALID, "Invalid %1%: %2% pragma provided to table %3% is "
                      "not a string literal", annot, name, externalName()); } }
    return rv;
}

int IR::MAU::Table::get_placement_priority_int() const {
    int val = 0;
    if (!match_table) return val;
    bool val_set = false;
    for (auto &annot : match_table->getAnnotations()->annotations) {
        if (annot->name != "placement_priority") continue;
        for (auto *expr : annot->expr) {
            if (auto constant = expr->to<IR::Constant>()) {
                if (val_set)
                    ::error(ErrorType::ERR_INVALID, "Invalid %1%: Only one integer value is "
                            "allowed for a placement_priority on table %2% for its global score",
                            annot, externalName());
                val = constant->asInt();
                val_set = true;
            }
        }
    }
    return val;
}

std::set<cstring> IR::MAU::Table::get_placement_priority_string() const {
    std::set<cstring> rv;
    if (!match_table) return rv;
    for (auto &annot : match_table->getAnnotations()->annotations) {
        if (annot->name != "placement_priority") continue;
        for (auto *expr : annot->expr) {
            if (auto sl = expr->to<IR::StringLiteral>()) {
                rv.insert(sl->value);
            }
        }
    }
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
            ::error(ErrorType::ERR_INVALID, "Invalid %1%: Stage pragma provided can have only "
                    "one or two constant parameters >= 0", annot);
        return valid_pragma;
    };

    int geq_stage = init_stage != nullptr ? *init_stage : -1;
    const IR::Annotation *stage_annot = nullptr;
    auto stage_annotations = match_table->annotations->where([](const IR::Annotation *annot)
                                                             { return annot->name == "stage"; });
    if (!stage_annotations)
        return -1;

    for (auto *annot : stage_annotations->annotations) {
        if (!checkPragma(annot))
            return -1;

        int curr_stage = annot->expr.at(0)->to<IR::Constant>()->asInt();
        if (curr_stage >= geq_stage) {
            if (stage_annot == nullptr) {
                stage_annot = annot;
            } else {
                int min_stage = stage_annot->expr.at(0)->to<IR::Constant>()->asInt();
                stage_annot = curr_stage < min_stage ? annot : stage_annot;
            }
        }
    }

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
            error(ErrorType::ERR_INVALID, "%1%Invalid max_actions pragma usage on table %2%.  "
                  "The maximum actions (%3%) specified cannot be less than the number of "
                  "callable actions listed (%4%).",
                  srcInfo, externalName(), pragma_val, num_actions);
            return -1;
        } else if (pragma_val > max_limit) {
            error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%1%Invalid max_actions pragma usage on "
                  "table %2%.  The maximum actions specified (%3%) cannot exceed %4%.",
                  srcInfo, externalName(), pragma_val, max_limit);
            return -1;
        } else if (pragma_val > num_actions) {
            return pragma_val;
        }
    }
    return -1;
}

boost::optional<int> IR::MAU::Table::is_force_immediate() const {
    int pragma_val;
    if (getAnnotation("force_immediate", pragma_val)) {
            if (pragma_val == 0 || pragma_val == 1) {
                return pragma_val;
            } else {
              error(ErrorType::ERR_INVALID, "%1%Invalid force_immediate pragma usage on "
                    "table %2%.  Only 0 and 1 are allowed.", srcInfo, externalName());
              return boost::none; } }
    return boost::none;
}

bool IR::MAU::Table::has_match_data() const {
    for (auto key : match_key) {
        if (key->for_match())
            return true;
    }
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
    for (auto &gw : gateway_rows)
        next.erase(gw.second);
    gateway_rows.clear();
    gateway_name = cstring();
    gateway_cond = cstring();
    gateway_payload = nullptr;
}

cstring IR::MAU::Action::externalName() const {
    if (auto *name_annot = annotations->getSingle("name"))
        return name_annot->getName();
    return name.toString();
}

int IR::MAU::HashGenExpression::nextId = 0;

const IR::MAU::SaluAction *IR::MAU::StatefulAlu::calledAction(
        const IR::MAU::Table* tbl,
        const IR::MAU::Action* act) const {
    auto ta_pair = tbl->name + "-" + act->name.originalName;
    if (!action_map.count(ta_pair)) return nullptr;
    auto *rv = instruction.get<SaluAction>(action_map.at(ta_pair));
    BUG_CHECK(rv, "No action %s in %s", action_map.at(ta_pair), this);
    return rv;
}
