#include <functional>
#include "bf-p4c/common/utils.h"
#include "bf-p4c/device.h"
#include "bf-p4c/mau/flatrock/memories.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "lib/bitops.h"
#include "lib/log.h"
#include "lib/range.h"

namespace Flatrock {

static const char *use_type_to_str[] = {
    "EXACT", "ATCAM", "TERNARY", "GATEWAY", "TIND", "IDLETIME",
    "COUNTER", "METER", "SELECTOR", "STATEFUL", "ACTIONDATA"
};

static const char *sram_group_type_to_str[] = {
    "Exact", "Action", "Stats", "Meter", "Register", "Selector", "Tind", "Idletime", "Atcam"
};

/** When anlyzing tables, the order is occasionally important, so we sort in order of
 * this priority.  For now the only important one is anaylyzing dleft tables before any
 * non-dleft table that may share the stateful ALU
 */
int Memories::table_alloc::analysis_priority() const {
    return table->for_dleft() ? 0 : 1;
}

/** Building a UniqueId per table alloc.  The stage table comes from initialization, all other
 *  data must be provided
 */
UniqueId Memories::table_alloc::build_unique_id(const IR::MAU::AttachedMemory *at,
        bool is_gw, int logical_table, UniqueAttachedId::pre_placed_type_t ppt) const {
    return table->pp_unique_id(at, is_gw, stage_table, logical_table, ppt);
}

/**
 * The memuse map holds the allocation of each table that has RAM array requirements.
 * These include:
 *     RAMs dedicated to match data
 *     RAMs dedicated to any of the BackendAttached Objects
 *         - These can exist from the P4 program: (i.e. counter, meter)
 *         - These can be implied by requirements (i.e. direct action data, ternary indirect)
 *
 * The key in the memuse map refers to a unique one of these objects, and the key is then
 * used to build a unique name for the assembly file.
 *
 * The other major issue is that multiple tables can access the same P4 object, (i.e. an
 * action profile).  There must be a unique allocation per P4 based object.
 *
 * In the memory use object, currently the P4 object is attached only to one table.  The table
 * that this P4 object is attached to has a unique id based on that table name.  All other tables
 * that use that P4 object keep a link to that table in the unattached_tables map.
 *
 * Thus the memory object initially decides which shared P4 object the table will be linked
 * to within the map, as well as keeps a map of the namespace around how to find the linked
 * table within the asm_output file.
 */

/**
 * Given the input parameters, this will return all of the UniqueIds associated with this
 * particular IR::MAU::Table object.  Generally this is a one-to-one relationship with
 * a few exceptions.
 *
 * ATCAM tables: The match portion and any direct BackendAttached tables (action data/idletime),
 * have multiple logical table units per allocation
 *
 * DLEFT tables: currently split so that each dleft cache is split as a logical table (though
 * in the long term this could be even stranger).  However by correctly setting up this
 * function, the corner casing only happens here
 *
 * This leaves room for any other odd corner casing we need to support
 */
safe_vector<UniqueId> Memories::table_alloc::allocation_units(const IR::MAU::AttachedMemory *at,
        bool is_gw, UniqueAttachedId::pre_placed_type_t ppt) const {
    safe_vector<UniqueId> rv;
    if (table->layout.atcam) {
        if (((at && at->direct) || at == nullptr) && is_gw == false) {
            for (int lt = 0; lt < layout_option->logical_tables(); lt++) {
                rv.push_back(build_unique_id(at, is_gw, lt, ppt));
            }
        } else {
            rv.push_back(build_unique_id(at, is_gw, 0, ppt));
        }
    } else if (table->for_dleft()) {
        for (int lt = 0; lt < layout_option->logical_tables(); lt++) {
            rv.push_back(build_unique_id(at, is_gw, lt, ppt));
        }
    } else {
        rv.push_back(build_unique_id(at, is_gw, -1, ppt));
    }
    return rv;
}

/**
 * Given the particular input parameters, this will return all of the UniqueIds that will not
 * have a provided allocation, but will be necessary to account for in the unattached_tables
 * map.
 *
 * ATCAM tables: For any indirect BackendAttached Tables, the UniqueId for any logical table > 0
 * will appear in the unattached object
 *
 * DLEFT some point in the future, maybe if other tables are attached, not just the stateful
 * ALU table.
 */
safe_vector<UniqueId> Memories::table_alloc::unattached_units(const IR::MAU::AttachedMemory *at,
    UniqueAttachedId::pre_placed_type_t ppt) const {
    safe_vector<UniqueId> rv;
    if (table->layout.atcam) {
        if (at && at->direct == false) {
            for (int lt = 1; lt < layout_option->logical_tables(); lt++) {
                rv.push_back(build_unique_id(at, false, lt, ppt));
            }
        }
    }
    return rv;
}

/**
 * The union of the allocation_units and the unattached_units
 */
safe_vector<UniqueId> Memories::table_alloc::accounted_units(const IR::MAU::AttachedMemory *at,
    UniqueAttachedId::pre_placed_type_t ppt) const {
    safe_vector<UniqueId> rv = allocation_units(at, false, ppt);
    safe_vector<UniqueId> vec2 = unattached_units(at, ppt);
    safe_vector<UniqueId> intersect;
    std::set_intersection(rv.begin(), rv.end(), vec2.begin(), vec2.end(),
                          std::back_inserter(intersect));
    BUG_CHECK(intersect.empty(), "%s: Error when accounting for uniqueness in logical units "
              "to address in memory allocation", table->name);
    rv.insert(rv.end(), vec2.begin(), vec2.end());
    return rv;
}

UniqueId Memories::SRAM_group::build_unique_id() const {
    return ta->build_unique_id(attached, false, logical_table, ppt);
}

Memories::result_bus_info Memories::SRAM_group::build_result_bus(int width_sect) const {
    if (ta->table_format->result_bus_words().getbit(width_sect))
        return result_bus_info(build_unique_id().build_name(), width_sect, logical_table);
    return result_bus_info();
}

void Memories::SRAM_group::dbprint(std::ostream &out) const {
    out << "SRAM group: " << ta->table->name << ", type: " << sram_group_type_to_str[type]
        << ", width: " << width << ", number: " << number;
    out << " { is placed: " << placed << ", depth " << depth
        << ", left to place " << left_to_place() << " }";
}

int Memories::mems_needed(int entries, int depth, int per_mem_row) {
    int mems_needed = (entries + per_mem_row * depth - 1) / (depth * per_mem_row);
    return mems_needed;
}

void Memories::clear_uses() {
    gateway_use.clear();
    tind_bus.clear();
    scm_tbl_id = 0;
    sram_use.clear();
    memset(sram_inuse, 0, sizeof(sram_inuse));
    sram_search_bus.clear();
    sram_print_search_bus.clear();
    sram_result_bus.clear();
    sram_print_result_bus.clear();
    scm_tbl_id = 0;
}

void Memories::clear() {
    tables.clear();
    clear_table_vectors();
    clear_uses();
}

void Memories::clear_table_vectors() {
    exact_tables.clear();
    exact_match_ways.clear();
    ternary_tables.clear();
    tind_tables.clear();
    tind_groups.clear();
    action_tables.clear();
    action_groups.clear();
    tind_result_bus_tables.clear();
}

void Memories::clear_allocation() {
    for (auto ta : tables) {
        for (auto &kv : *(ta->memuse)) {
            kv.second.clear_allocation();
        }
    }
}

/* Creates a new table_alloc object for each of the tables within the memory allocation */
void Memories::add_table(const IR::MAU::Table *t, const IR::MAU::Table *gw,
        TableResourceAlloc *resources, const LayoutOption *lo, const ActionData::Format::Use *af,
        ActionData::FormatType_t ft, int entries, int stage_table,
        attached_entries_t attached_entries) {
    table_alloc *ta;
    auto gw_ixbar = resources->gateway_ixbar.get();
    // auto gw_ixbar = dynamic_cast<const IXBar::Use *>(resources->gateway_ixbar.get());
    if (!t->conditional_gateway_only()) {
        auto match_ixbar = resources->match_ixbar.get();
        // auto match_ixbar = dynamic_cast<const IXBar::Use *>(resources->match_ixbar.get());
        if (lo->layout.gateway_match || !ft.matchThisStage())
            match_ixbar = gw_ixbar;
        ta = new table_alloc(t, match_ixbar, &resources->table_format, &resources->instr_mem, af,
                             &resources->memuse, lo, ft, entries, stage_table,
                             std::move(attached_entries));
    } else {
        ta = new table_alloc(t, gw_ixbar, nullptr, nullptr, nullptr, &resources->memuse, lo, ft,
                             entries, stage_table, std::move(attached_entries));
    }
    LOG2("Adding table " << ta->table->name << " with " << entries << " entries");
    tables.push_back(ta);
    if (gw != nullptr)  {
        auto *ta_gw = new table_alloc(gw, gw_ixbar, nullptr, nullptr, nullptr, &resources->memuse,
                                      lo, ft, -1, stage_table, {});
        LOG2("Adding gateway table " << ta_gw->table->name << " to table "
             << ta_gw->table->name);
        ta_gw->link_table(ta);
        ta->link_table(ta_gw);
        tables.push_back(ta_gw);
    }
}

/** Due to gateways potentially requiring search buses that could may be used
 *  by exact match tables, the memories allocation can be run multiple times.  The difference
 *  factor would be the total number of RAMs per row exact match tables can be allocated to.
 *  If an exact match table can fit in a single row, only one search bus is required, which
 *  will provide access for gateways.
 *
 *  The algorithm is making a trade-off between search buses, and balance for other tables
 *  such as tind, synth2port, and action tables later.
 */
bool Memories::single_allocation_balance(unsigned column_mask) {
    LOG3("Allocating all exact tables");
    if (!allocate_all_exact(column_mask))
        return false;

    LOG3("Allocating all action data tables");
    if (!allocate_all_actiondata(column_mask))
        return false;

    LOG3(" Allocating all ternary tables");
    if (!allocate_all_ternary()) {
        return false;
    }

    LOG3(" Allocating all ternary indirect tables");
    if (!allocate_all_tind()) {
        return false;
    }

    return true;
}

/* Function that tests whether all added tables can be allocated to the stage */
bool Memories::allocate_all() {
    mem_info mi;

    failure_reason = cstring();
    LOG3("Analyzing tables " << tables << IndentCtl::indent);
    if (!analyze_tables(mi)) {
        LOG3_UNINDENT;
        if (!failure_reason) failure_reason = "analyze_tables failed";
        return false;
    }
    unsigned column_mask = 0x1F;  // Set all 5 columns within a stage
                                  // FIXME -- there's 2 rams per 'unit', so should this be 0x3ff?
    bool finished = false;
    calculate_entries();

    clear_uses();
    clear_allocation();
    if (single_allocation_balance(column_mask)) {
        finished = true;
    }

    LOG3_UNINDENT;
    if (!finished) {
        if (!failure_reason) failure_reason = "unknown failure";
        return false;
    }

    LOG2("Memory allocation fits");
    return true;
}

/* This class is responsible for filling in all of the particular lists with the corresponding
   twoport tables, as well as getting the sharing of indirect action tables and selectors correct
*/
class SetupAttachedTables : public MauInspector {
    Memories &mem;
    Memories::table_alloc *ta;
    int entries;
    const attached_entries_t &attached_entries;
    Memories::mem_info &mi;
    bool stats_pushed = false, meter_pushed = false, stateful_pushed = false;

    profile_t init_apply(const IR::Node *root) {
        profile_t rv = MauInspector::init_apply(root);
        if (ta->layout_option == nullptr) return rv;
        bool tind_check = ta->layout_option->layout.ternary &&
                          !ta->layout_option->layout.no_match_miss_path() &&
                          !ta->layout_option->layout.gateway_match &&
                          ta->format_type.matchThisStage();
        if (tind_check) {
            if (ta->table_format->has_overhead()) {
                for (auto u_id : ta->allocation_units(nullptr, false, UniqueAttachedId::TIND_PP)) {
                    auto &alloc = (*ta->memuse)[u_id];
                    alloc.type = Memories::Use::TIND;
                    alloc.used_by = ta->table->externalName();
                    mi.tind_tables++;
                }
                int per_row = TernaryIndirectPerWord(&ta->layout_option->layout, ta->table);
                mem.tind_tables.push_back(ta);
                mi.tind_RAMs += mem.mems_needed(entries, Memories::SRAM_DEPTH, per_row);
            } else {
                mem.tind_result_bus_tables.push_back(ta);
            }
        }

        if (ta->layout_option->layout.direct_ad_required()) {
            for (auto u_id : ta->allocation_units(nullptr, false, UniqueAttachedId::ADATA_PP)) {
                auto &alloc = (*ta->memuse)[u_id];
                alloc.type = Memories::Use::ACTIONDATA;
                alloc.used_by = ta->table->externalName();
                if (ta->layout_option->layout.pre_classifier)
                    alloc.used_by += "_preclassifier";
                alloc.used_by += "$action";

                mi.action_tables++;
            }
            mem.action_tables.push_back(ta);
            int width = 1;
            int per_row = ActionDataPerWord(&ta->layout_option->layout, &width);
            int depth = mem.mems_needed(entries, Memories::SRAM_DEPTH, per_row);
            mi.action_bus_min += width; mi.action_RAMs += depth * width;
        }
        return rv;
    }

    /* In order to only visit the attached tables of the current table */
    bool preorder(const IR::MAU::TableSeq *) { return false; }
    bool preorder(const IR::MAU::Action *) { return false; }

    bool preorder(const IR::MAU::TernaryIndirect *) {
        BUG("Should be no Ternary Indirect before table placement is complete");
    }

    bool preorder(const IR::MAU::Table* tbl) {
        visit(tbl->attached);
        return false;
    }

 public:
     explicit SetupAttachedTables(Memories &m, Memories::table_alloc *t, int e,
                                  const attached_entries_t &ae, Memories::mem_info &i)
    : mem(m), ta(t), entries(e), attached_entries(ae), mi(i) {}
};

void Memories::set_logical_memuse_type(table_alloc *ta, Use::type_t type) {
    for (auto u_id : ta->allocation_units()) {
        (*ta->memuse)[u_id].type = type;
        (*ta->memuse)[u_id].used_by = ta->table->externalName();
    }
}

/* Run a quick analysis on all tables added by the table placement algorithm,
   and add the tables to their corresponding lists */
bool Memories::analyze_tables(mem_info &mi) {
    mi.clear();
    clear_table_vectors();
    std::stable_sort(tables.begin(), tables.end(), [](table_alloc *a, table_alloc *b) {
        return a->analysis_priority() < b->analysis_priority(); });
    for (auto *ta : tables) {
        auto table = ta->table;
        int entries = ta->provided_entries;
        if (entries == -1 || entries == 0) {
            auto unique_id = ta->build_unique_id(nullptr, true);
            if (ta->table_link != nullptr) {
                unique_id = ta->table_link->build_unique_id(nullptr, true);
            } else {
                mi.independent_gw_tables++;
                mi.logical_tables++;
            }
            (*ta->memuse)[unique_id].type = Use::GATEWAY;
            LOG4("Gateway table for " << ta->table->name);
            if (any_of(Values(ta->attached_entries),
                       [](attached_entries_element_t ent){ return ent.entries > 0; })) {
                // at least one attached table so need a no match table
                no_match_hit_tables.push_back(ta);
                ta->link_table(ta);  // link to itself to produce payload
                set_logical_memuse_type(ta, Use::EXACT);
                mi.no_match_tables++;
            } else {
                continue;
            }
        } else if (ta->layout_option->layout.no_match_rams()) {
            mi.logical_tables += ta->layout_option->logical_tables();
            if (ta->layout_option->layout.no_match_hit_path() ||
                ta->layout_option->layout.gateway_match) {
                // payload gateway tables are realy "no_match_hit_and_miss" -- they need
                // both the hit path from the gateway and the miss path.  So they really should
                // be allocated as empty exact match tables, but this is the closest we have
                no_match_hit_tables.push_back(ta);
                set_logical_memuse_type(ta, Use::EXACT);
            } else {
                BUG_CHECK(!ta->table->for_dleft(), "DLeft tables can only be "
                          "part of the hit path");
                set_logical_memuse_type(ta, Use::TERNARY);
                // In order to potentially provide potential sizes for attached tables,
                // must at least have a size of 1
                BUG("flatrock does not support no-match-miss tables");
            }
            mi.no_match_tables++;
        } else if (!table->layout.ternary) {
            set_logical_memuse_type(ta, Use::EXACT);
            exact_tables.push_back(ta);
            mi.match_tables += ta->layout_option->logical_tables();
            mi.logical_tables += ta->layout_option->logical_tables();
            int width = ta->layout_option->way.width;
            int groups = ta->layout_option->way.match_groups;
            int depth = mems_needed(entries, SRAM_DEPTH, groups);
            mi.result_bus_min += width;
            mi.match_RAMs += depth;
        } else {
           set_logical_memuse_type(ta, Use::TERNARY);
           ternary_tables.push_back(ta);
           mi.ternary_tables += ta->layout_option->logical_tables();
           mi.logical_tables += ta->layout_option->logical_tables();
           int bytes = table->layout.match_bytes;
           int TCAMs_needed = (bytes + 4)/5;
           int depth = mems_needed(entries, TCAM_DEPTH, 1);
           mi.ternary_TCAMs += TCAMs_needed * depth;
        }
        SetupAttachedTables setup(*this, ta, entries, ta->attached_entries, mi);
        ta->table->apply(setup);
    }
    return mi.constraint_check(logical_tables_allowed, failure_reason);
}

bool Memories::mem_info::constraint_check(int lt_allowed, cstring &failure_reason) const {
    auto total_tables = match_tables + no_match_tables + ternary_tables + independent_gw_tables;
    if (total_tables > Memories::TABLES_MAX) {
        LOG6(" match_tables(" << match_tables << ") + no_match_tables(" <<
                no_match_tables << ") + ternary_tables(" << ternary_tables <<
                ") + independent_gw_tables(" << independent_gw_tables <<
                ") > Memories::TABLES_MAX(" << Memories::TABLES_MAX << ")");
        failure_reason = "too many tables total";
        return false; }

    if (match_RAMs > Memories::N_ISTM_ROWS * Memories::STM_COLS_PER_STAGE) {
        LOG6(" match_RAMs(" << match_RAMs << ") > Memories::N_ISTM_ROWS(" <<
            Memories::N_ISTM_ROWS << ") * Memories::SRAM_COLUMNS(" << Memories::SRAM_COLUMNS
            << ")");
        failure_reason = "too many srams";
        return false; }

    if (tind_tables > Memories::TERNARY_TABLES_MAX) {
        LOG6(" tind_tables(" << tind_tables << ") > Memories::TERNARY_TABLES_MAX("
            << Memories::TERNARY_TABLES_MAX << ")");
        failure_reason = "too many tind tables";
        return false; }

    if (logical_tables > lt_allowed) {
        LOG6(" logical_tables(" << logical_tables << ") > lt_allowed(" <<
           lt_allowed << ")");
        failure_reason = "too many logical tables";
        return false; }

    return true;
}

void Memories::calculate_entries() {
    for (auto ta : exact_tables) {
        // Multiple entries if the table is using an SRAM to hold the dleft initial key
        BUG_CHECK(ta->allocation_units().size() == size_t(ta->layout_option->logical_tables()),
                  "Logical table mismatch on %s", ta->table->name);
        ta->calc_entries_per_uid.resize(ta->layout_option->logical_tables(), ta->provided_entries);
    }

    for (auto ta : ternary_tables) {
        BUG_CHECK(ta->allocation_units().size() == size_t(ta->layout_option->logical_tables()),
                  "Logical table mismatch on %s", ta->table->name);
        ta->calc_entries_per_uid.resize(ta->layout_option->logical_tables(), ta->provided_entries);
    }
}

/* Calculate the size of the ways given the number of RAMs necessary */
safe_vector<int> Memories::way_size_calculator(int ways, int RAMs_needed) {
    safe_vector<int> vec;
    if (ways == -1) {
    // FIXME: If the number of ways are not provided, not yet considered
    } else {
        for (int i = 0; i < ways; i++) {
            if (RAMs_needed < ways - i) {
                RAMs_needed = ways - i;
            }

            int depth = (RAMs_needed + ways - i - 1)/(ways - i);
            int log2sz = floor_log2(depth);
            if (depth != (1 << log2sz))
                depth = 1 << (log2sz + 1);

            RAMs_needed -= depth;
            vec.push_back(depth);
        }
    }
    return vec;
}

/**
 * Find the rows of SRAMs that can hold the table, verified as well by the busses set in SRAM
 */
safe_vector<std::pair<int, int>>
Memories::available_SRAMs_per_row(unsigned mask, SRAM_group *group, int width_sect) {
    safe_vector<std::pair<int, int>> available_rams;
    auto group_search_bus = group->build_search_bus(width_sect);
    auto group_result_bus = group->build_result_bus(width_sect);
    for (int i = 0; i < N_ISTM_ROWS; i++) {
        if (!search_bus_available(i, group_search_bus))
            continue;
        if (group_result_bus.init && !result_bus_available(i, group_result_bus))
            continue;
        available_rams.push_back(std::make_pair(i, bitcount(mask & ~sram_inuse[i])));
    }

    std::sort(available_rams.begin(), available_rams.end(),
             [&](const std::pair<int, int> a, const std::pair<int, int> b) {
        int t;
        if (a.second != 0 && b.second == 0) return true;
        if (a.second == 0 && b.second != 0) return false;

        // Prefer sharing a search bus/result bus if there is one to share
        auto bus = sram_search_bus[a.first];
        bool a_matching_bus = bus[0] == group_search_bus || bus[1] == group_search_bus;
        bus = sram_search_bus[b.first];
        bool b_matching_bus = bus[0] == group_search_bus || bus[1] == group_search_bus;
        if (a_matching_bus != b_matching_bus)
            return a_matching_bus;

        if ((t = a.second - b.second) != 0) return t > 0;
        return b > a;
    });
    return available_rams;
}

/* Simple now.  Just find rows with the available RAMs that it is asking for */
safe_vector<int> Memories::available_match_SRAMs_per_row(unsigned selected_columns_mask,
        unsigned total_mask, std::set<int> used_rows, SRAM_group *group, int width_sect) {
    safe_vector<int> matching_rows;
    auto group_search_bus = group->build_search_bus(width_sect);
    auto group_result_bus = group->build_result_bus(width_sect);

    for (int i = 0; i < N_ISTM_ROWS; i++) {
        if (used_rows.find(i) != used_rows.end()) continue;
        if (!search_bus_available(i, group_search_bus))
            continue;
        if (group_result_bus.init && !result_bus_available(i, group_result_bus))
            continue;

        if (bitcount(selected_columns_mask & ~sram_inuse[i]) == bitcount(selected_columns_mask))
            matching_rows.push_back(i);
    }

    std::sort(matching_rows.begin(), matching_rows.end(),
              [=] (const int a, const int b) {
        int t;
        if ((t = bitcount(~sram_inuse[a] & total_mask) -
                 bitcount(~sram_inuse[b] & total_mask)) != 0)
            return t < 0;

        auto bus = sram_search_bus[a];
        bool a_matching_bus = bus[0] == group_search_bus || bus[1] == group_search_bus;
        bus = sram_search_bus[b];
        bool b_matching_bus = bus[0] == group_search_bus || bus[1] == group_search_bus;

        if (a_matching_bus != b_matching_bus)
            return a_matching_bus;

        return a > b;
    });
    return matching_rows;
}

/* Based on the number of ways provided by the layout option, the ways sizes and
   select masks are initialized and provided to the way allocation algorithm */
void Memories::break_exact_tables_into_ways() {
    Log::TempIndent indent;
    LOG3("Breaking exact tables into ways" << indent);
    exact_match_ways.clear();

    for (auto *ta : exact_tables) {
        auto match_ixbar = dynamic_cast<const IXBar::Use *>(ta->match_ixbar);
        BUG_CHECK(match_ixbar, "No match ixbar allocated?");
        if (match_ixbar->has_lamb()) continue;
        for (auto u_id : ta->allocation_units()) {
            (*ta->memuse)[u_id].ways.clear();
            (*ta->memuse)[u_id].row.clear();
            int index = 0;
            for (auto &way : match_ixbar->way_use) {
                SRAM_group *wa
                      = new SRAM_group(ta, ta->layout_option->way_sizes[index],
                                       ta->layout_option->way.width, index, way.source,
                                       SRAM_group::EXACT);
                wa->logical_table = u_id.logical_table;

                exact_match_ways.push_back(wa);
                (*ta->memuse)[u_id].ways.emplace_back(ta->layout_option->way_sizes[index],
                                                      way.select_mask);
                index++;
            }
        }
        BUG_CHECK(match_ixbar->way_use.size() == ta->layout_option->way_sizes.size(),
                  "Mismatch of memory ways(%d) and ixbar ways(%d)",
                  match_ixbar->way_use.size(), ta->layout_option->way_sizes.size());
    }
    std::sort(exact_match_ways.begin(), exact_match_ways.end(),
              [=](const SRAM_group *a, const SRAM_group *b) {
         int t;
         if ((t = a->width - b->width) != 0) return t > 0;
         if ((t = (a->left_to_place()) - (b->left_to_place())) != 0) return t > 0;
         return a->logical_table < b->logical_table;
    });
    LOG5("Exact match ways (sorted): ");
    for (auto emw : exact_match_ways) { LOG5("  " << emw); }
}

/* Selects the best way to begin placing on the row, based on what was previously placed
   within this row.
*/
Memories::SRAM_group *Memories::find_best_candidate(SRAM_group *placed_wa, int row, int &loc) {
    if (exact_match_ways.empty()) return nullptr;
    auto bus = sram_search_bus[row];

    loc = 0;
    for (auto emw : exact_match_ways) {
        auto group_bus = emw->build_search_bus(placed_wa->width - 1);
        if ((!bus[0].free() && bus[0] == group_bus) || (!bus[1].free() && bus[1] == group_bus))
            return emw;
        loc++;
    }

    if (!bus[0].free() && !bus[1].free()) {
        return nullptr;
    }

    // FIXME: Perhaps do a best fit algorithm here
    loc = 0;
    return exact_match_ways[0];
}

/* Fill out the remainder of the row with other ways! */
bool Memories::fill_out_row(SRAM_group *placed_way, int row, unsigned column_mask) {
    LOG6("Filling out row");
    int loc = 0;
    // FIXME: Need to adjust to the proper mask provided by earlier function
    while (bitcount(column_mask & ~sram_inuse[row]) > 0) {
        SRAM_group *way = find_best_candidate(placed_way, row, loc);
        if (way == nullptr)
            return true;

        match_selection match_select;
        if (!determine_match_rows_and_cols(way, row, column_mask, match_select))
            return false;
        fill_out_match_alloc(way, match_select);

        if (way->all_placed())
            exact_match_ways.erase(exact_match_ways.begin() + loc);
    }
    return true;
}

bool Memories::search_bus_available(int search_row, search_bus_info &sbi) {
    for (auto bus : sram_search_bus[search_row]) {
        if (bus.free() || bus == sbi)
            return true;
    }
    return false;
}

bool Memories::result_bus_available(int search_row, result_bus_info &mbi) {
    for (auto bus : sram_result_bus[search_row]) {
        if (bus.free() || bus == mbi)
            return true;
    }
    return false;
}

/* Returns the search bus that we are selecting on this row */
int Memories::select_search_bus(SRAM_group *group, int width_sect, int row) {
     auto group_search_bus = group->build_search_bus(width_sect);
     int index = 0;
     for (auto bus : sram_search_bus[row]) {
         if (bus == group_search_bus)
             return index;
         index++;
     }

     index = 0;
     for (auto bus : sram_search_bus[row]) {
         if (bus.free())
             return index;
         index++;
     }
     return -1;
}

int Memories::select_result_bus(SRAM_group *group, int width_sect, int row) {
     auto group_result_bus = group->build_result_bus(width_sect);
     if (!group_result_bus.init)
         return -1;
     int index = 0;
     for (auto bus : sram_result_bus[row]) {
          if (bus == group_result_bus)
              return index;
          index++;
     }
     index = 0;
     for (auto bus : sram_result_bus[row]) {
         if (bus.free())
             return index;
         index++;
     }
     return -2;
}

/* Picks an empty/most open row, and begins to fill it in within a way */
bool Memories::find_best_row_and_fill_out(unsigned column_mask) {
    Log::TempIndent indent;
    LOG6("Filling out best row" << indent);
    SRAM_group *way = exact_match_ways[0];
    safe_vector<std::pair<int, int>> available_rams
        = available_SRAMs_per_row(column_mask, way, way->width - 1);
    // No memories left to place anything
    if (available_rams.size() == 0) {
        failure_reason = "no rams left in exact_match.find_best_row";
        return false; }

    int row = available_rams[0].first;
    match_selection match_select;
    if (available_rams[0].second == 0) {
        failure_reason = "empty row in exact_match.find_best_row";
        return false; }
    if (!determine_match_rows_and_cols(way, row, column_mask, match_select))
        return false;
    fill_out_match_alloc(way, match_select);

    if (way->all_placed())
        exact_match_ways.erase(exact_match_ways.begin());

    if (bitcount(~sram_inuse[row] & column_mask) == 0)
        return true;
    else
        return fill_out_row(way, row, column_mask);
}

/* Allocates all of the ways */
bool Memories::allocate_all_exact(unsigned column_mask) {
    allocation_count = 0;
    break_exact_tables_into_ways();
    while (exact_match_ways.size() > 0) {
        if (find_best_row_and_fill_out(column_mask) == false) {
            return false;
        }
    }
    compress_ways();

    for (auto *ta : exact_tables) {
        for (auto u_id : ta->allocation_units()) {
            LOG4("Exact match table " << u_id.build_name());
            auto alloc = (*ta->memuse)[u_id];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
            }
            int wayno = 0;
            for (auto way : alloc.ways) {
                LOG4("Rams for way " << wayno);
                for (auto ram : way.rams) {
                    LOG4(ram.first << ", " << ram.second);
                }
                wayno++;
            }
        }
    }
    return true;
}

bool Memories::allocate_all_actiondata(unsigned column_mask) {
    for (auto *ta : action_tables) {
        for (auto u_id : ta->allocation_units(nullptr, false, UniqueAttachedId::ADATA_PP)) {
            LOG4("Action data table for: " << u_id.build_name() << " col=0x" << hex(column_mask));
            auto alloc = (*ta->memuse)[u_id];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
            }
        }
    }
    return true;
}

void Memories::compress_row(Use &alloc) {
    std::stable_sort(alloc.row.begin(), alloc.row.end(),
        [=](const Memories::Use::Row a, const Memories::Use::Row b) {
            int t;
            if ((t = a.row - b.row) != 0) return t < 0;
            if ((t = a.bus - b.bus) != 0) return t < 0;
            return a.alloc < b.alloc;
        });
    for (size_t i = 0; i + 1 < alloc.row.size(); i++) {
        if (alloc.row[i].row == alloc.row[i+1].row &&
            alloc.row[i].bus == alloc.row[i+1].bus) {
            BUG_CHECK(alloc.row[i].word == alloc.row[i+1].word, "SRAMs that share a row "
                      "and bus must share the same word");
            alloc.row[i].col.insert(alloc.row[i].col.end(), alloc.row[i+1].col.begin(),
                                    alloc.row[i+1].col.end());
            alloc.row.erase(alloc.row.begin() + i + 1);
            i--;
        }
    }

    std::stable_sort(alloc.row.begin(), alloc.row.end(),
        [=](const Memories::Use::Row &a, const Memories::Use::Row &b) {
        int t;
        if ((t = a.alloc - b.alloc) != 0) return t < 0;
        if ((t = a.word - b.word) != 0) return t < 0;
        return a.row < b.row;
    });
}

/** Adjust the Use structures so that there is is only one Use::Row object per row and bus.
 *  Otherwise, the algorithm will complain of a bus collision on a row for the same table
 */
void Memories::compress_ways() {
    for (auto *ta : exact_tables) {
        for (auto u_id : ta->allocation_units()) {
            auto &alloc = (*ta->memuse)[u_id];
            compress_row(alloc);
        }
    }
}

/** Given an initial row to place a way or partition on, determine which search/match bus,
 *  and which RAMs in that row to assign to the partition.  If the match is wide, then one
 *  must find rows with columns.  Due to the constraint that wide matches must be in the same
 *  row in order for the hit signals to be able to traverse wide matches, the columns in each
 *  row must be the same.
 */
bool Memories::determine_match_rows_and_cols(SRAM_group *group, int row, unsigned column_mask,
                                            match_selection &match_select) {
    Log::TempIndent indent;
    LOG6("Determining match rows and cols" << indent);

    // Pick a bus
    int search_bus = select_search_bus(group, group->width - 1, row);
    BUG_CHECK(search_bus >= 0, "Search somehow found an impossible bus");
    int result_bus = select_result_bus(group, group->width - 1, row);
    BUG_CHECK(result_bus >= -1, "Somehow found an impossible result bus");
    match_select.rows.push_back(row);
    match_select.search_buses[row] = search_bus;
    match_select.result_buses[row] = result_bus;
    int cols = 0;
    std::set<int> determined_rows;
    determined_rows.emplace(row);
    match_select.widths[row] = group->width - 1;

    // Pick available columns
    for (int i = 0; i < SRAM_COLUMNS && cols < group->left_to_place(); i++) {
        if (((1 << i) & column_mask) == 0) continue;
        if (sram_use[row][i]) continue;
        match_select.column_mask |= (1 << i);
        match_select.cols.push_back(i);
        LOG7("Adding column " << i);
        cols++;
    }

    // If the match is wide, pick rows that have these columns available
    for (int i = group->width - 2; i >= 0; i--) {
        safe_vector<int> matching_rows =
            available_match_SRAMs_per_row(match_select.column_mask, column_mask,
                                          determined_rows, group, i);
        if (matching_rows.size() == 0) {
            failure_reason = "empty row for wide match in determine_match_rows_and_cols";
            return false; }
        int wide_row = matching_rows[0];
        match_select.rows.push_back(wide_row);
        search_bus = select_search_bus(group, i, wide_row);
        BUG_CHECK(search_bus >= 0, "Search somehow found an impossible bus");
        result_bus = select_result_bus(group, i, wide_row);
        BUG_CHECK(result_bus >= -1, "Search somehow found an impossible result bus");
        match_select.search_buses[wide_row] = search_bus;
        match_select.result_buses[wide_row] = result_bus;
        match_select.widths[wide_row] = i;
        determined_rows.emplace(wide_row);
    }

    std::sort(match_select.rows.begin(), match_select.rows.end());
    std::reverse(match_select.rows.begin(), match_select.rows.end());
    std::sort(match_select.cols.begin(), match_select.cols.end());

    return true;
}

/** Given a list of rows and columns, save this in the Memories::Use object for each table,
 *  as well as store this information within the Memories object structure
 */
void Memories::fill_out_match_alloc(SRAM_group *group, match_selection &match_select) {
    Log::TempIndent indent;
    LOG6("Filling out match alloc for SRAM group" << indent);
    auto unique_id = group->build_unique_id();
    auto &alloc = (*group->ta->memuse)[unique_id];
    auto name = unique_id.build_name();

    // Save row and column information
    for (auto row : match_select.rows) {
        auto bus = match_select.search_buses.at(row);
        auto result_bus = match_select.result_buses.at(row);
        int width = match_select.widths.at(row);
        alloc.row.emplace_back(row, bus, width, allocation_count);
        alloc.row.back().result_bus = result_bus;
        auto &back_row = alloc.row.back();
        for (auto col : match_select.cols) {
            sram_use[row][col] = name;
            back_row.col.push_back(col);
        }
        LOG7("Adding row to alloc: " << back_row);

        auto group_search_bus = group->build_search_bus(width);
        auto group_result_bus = group->build_result_bus(width);
        sram_inuse[row] |= match_select.column_mask;
        if (!sram_search_bus[row][bus].free()) {
            BUG_CHECK(sram_search_bus[row][bus] == group_search_bus,
                      "Search bus initialization mismatch");
        } else {
            sram_search_bus[row][bus] = group_search_bus;
            sram_print_search_bus[row][bus] = group_search_bus.name;
            LOG7("Setting sram search bus on row " << row << " and bus "
                    << result_bus << " for " << sram_print_search_bus[row][bus]);
        }

        if (result_bus >= 0) {
            if (!sram_result_bus[row][result_bus].free()) {
                BUG_CHECK(sram_result_bus[row][result_bus] == group_result_bus,
                          "Result bus initializaton mismatch");
            } else {
                sram_result_bus[row][result_bus] = group_result_bus;
                sram_print_result_bus[row][result_bus] = group_result_bus.name;
                LOG7("Setting sram result bus on row " << row << " and result bus "
                        << result_bus << " for " << sram_print_result_bus[row][result_bus]);
            }
        }
    }

    group->placed += bitcount(match_select.column_mask);
    // Store information on ways. Only one RAM in each way will be searched per
    // packet. The RAM is chosen by the select bits in the upper 12 bits of the
    // hash matrix
    for (auto col : match_select.cols) {
        LOG7("For column " << col);
        safe_vector<std::pair<int, int>> ram_pairs(match_select.rows.size());
        for (auto row : match_select.rows) {
            ram_pairs[match_select.widths.at(row)] = std::make_pair(row, col);
        }
        std::reverse(ram_pairs.begin(), ram_pairs.end());
        alloc.ways[group->number].rams.insert(alloc.ways[group->number].rams.end(),
                                              ram_pairs.begin(), ram_pairs.end());
        alloc.ways[group->number].stage_rams[local_stage] = ram_pairs;
        LOG7("Adding rams on way for stage " << local_stage);
        for (auto [r, c] : ram_pairs)
            LOG7("\t[ " << r << ", " << c << " ] ");
    }
    allocation_count++;
}

/* Number of continuous TCAMs needed for table width */
int Memories::ternary_TCAMs_necessary(table_alloc *ta) {
    return ta->table_format->tcam_use.size();
}

/* Finds the stretch on the ternary array that can hold entries */
bool Memories::find_ternary_stretch(int TCAMs_necessary,
                                    BFN::Alloc1D<const IR::MAU::Table *, TCAM_ROWS> &tcam_use,
                                    int &row) {
    int clear_cols = 0;

    for (int i = 0; i < TCAM_ROWS; i++) {
        if (tcam_use[i]) {
            clear_cols = 0;
            continue;
        }

        clear_cols++;
        if (clear_cols == TCAMs_necessary) {
            row = i - clear_cols + 1;
            return true;
        }
    }
    failure_reason = "find_ternary_stretch failed";
    return false;
}

/* Allocates all ternary entries within the stage */
bool Memories::allocate_all_ternary() {
    std::sort(ternary_tables.begin(), ternary_tables.end(),
        [=](const table_alloc *a, table_alloc *b) {
        int t;
        if ((t = a->table->layout.match_bytes - b->table->layout.match_bytes) != 0) return t > 0;
        return a->total_entries() > b->total_entries();
    });

    // FIXME: All of this needs to be changed on this to match up with xbar
    for (auto *ta : ternary_tables) {
        int lt_entry = 0;
        for (auto u_id : ta->allocation_units()) {
            int TCAMs_necessary = ternary_TCAMs_necessary(ta);

            // FIXME: If the table is just a default action table, essentially a hack
            if (TCAMs_necessary == 0)
                continue;
            int row = 0;;
            Memories::Use &alloc = (*ta->memuse)[u_id];
            int id_off = ta->table->gress == EGRESS ? TERNARY_TABLES_MAX : 0;
            if (ta->layout_option->local_tinds) {
                // Find the most appropriate physical table id 7..0
                for (int id = TERNARY_TABLES_MAX - 1 + id_off; id >= id_off; id--) {
                    if (!(scm_tbl_id & (1 << id))) {
                        alloc.table_id = id % 8;
                        scm_tbl_id |= (1 << id);
                        break;
                    }
                }
            } else {
                // Find the most appropriate physical table id 0..3
                for (int id = 0 + id_off; id < TERNARY_TABLES_WITH_STM_TIND_MAX + id_off; id++) {
                    if (!(scm_tbl_id & (1 << id))) {
                        alloc.table_id = id % TERNARY_TABLES_MAX;
                        scm_tbl_id |= (1 << id);
                        break;
                    }
                }
            }
            if (alloc.table_id == -1) {
                failure_reason = "no tcam logical id available";
                return false;
            }

            int ingress_stage = (ta->table->gress != EGRESS) ?
                                local_stage : EGRESS_STAGE0_INGRESS_STAGE - local_stage;
            scm_alloc_stage &alloc_stage = scm_curr_alloc.stage_to_alloc[ingress_stage];
            scm_curr_alloc.tbl_to_local_stage[ta->table] = ingress_stage;
            int group = 0;
            for (int i = 0; i < ta->calc_entries_per_uid[lt_entry] / TCAM_DEPTH; i++) {
                if (!find_ternary_stretch(TCAMs_necessary, alloc_stage.tcam_use, row))
                    return false;
                for (int i = row; i < row + TCAMs_necessary; i++) {
                    alloc_stage.tcam_use[i] = ta->table;
                    alloc_stage.tcam_grp[i] = group;
                    alloc_stage.tcam_in_use |= 1 << i;
                    alloc.loc_to_gb.emplace(std::piecewise_construct,
                        std::forward_as_tuple(local_stage, i),
                        std::forward_as_tuple(std::make_pair(group, Use::NONE)));
                }
                group++;
            }
            lt_entry++;
        }
    }

    for (auto *ta : ternary_tables) {
        for (auto u_id : ta->allocation_units()) {
            auto &alloc = (*ta->memuse)[u_id];
            LOG4("Allocation of " << u_id.build_name());
            for (auto loc : alloc.loc_to_gb) {
                int group = -1;
                Use::h_bus_t bus = Use::NONE;
                const Use::ScmLoc &scm_loc = loc.first;
                std::tie(group, bus) = loc.second;
                LOG4("Group is " << group);
                LOG4("Row is " << scm_loc.row << " and bus is " << bus);
            }
        }
    }
    LOG7(scm_curr_alloc);
    return true;
}

/* Breaks up the tables requiring tinds into groups that can be allocated within the
   SRAM array */
void Memories::find_tind_groups() {
    tind_groups.clear();
    for (auto *ta : tind_tables) {
        int lt_entry = 0;
        for (auto u_id : ta->allocation_units(nullptr, false, UniqueAttachedId::TIND_PP)) {
            // Cannot use the TernaryIndirectPerWord function call, as the overhead allocated
            // may differ than the estimated overhead in the layout_option
            BUG_CHECK(ta->table_format->has_overhead(), "Allocating a ternary indirect table "
                 "%s with no overhead", u_id.build_name());
            bitvec overhead = ta->table_format->overhead();
            int tind_size = 1 << ceil_log2(overhead.max().index() + 1);
            tind_size = std::max(tind_size, 8);
            int per_word = TableFormat::SINGLE_RAM_BITS / tind_size;
            int depth = mems_needed(ta->calc_entries_per_uid[lt_entry], SRAM_DEPTH, per_word);
            tind_groups.push_back(new SRAM_group(ta, depth, 0, SRAM_group::TIND));
            tind_groups.back()->logical_table = u_id.logical_table;
            tind_groups.back()->ppt = UniqueAttachedId::TIND_PP;

            if (ta->layout_option->local_tinds) {
                for (auto match_u_id : ta->allocation_units()) {
                    Memories::Use &alloc = (*ta->memuse)[match_u_id];
                    tind_groups.back()->scm_table_id = alloc.table_id;
                }
            }
        }
    }
    std::sort(tind_groups.begin(), tind_groups.end(),
              [=](const SRAM_group *a, const SRAM_group *b) {
        int t;
        if ((t = a->scm_table_id - b->scm_table_id) != 0) return t > 0;
        if ((t = (a->left_to_place()) - (b->left_to_place())) != 0) return t > 0;
        if ((t = a->logical_table - b->logical_table) != 0) return t < 0;
        return a->logical_table < b->logical_table;
    });
}

/* Allocates all of the ternary indirect tables into the first column if they fit.
   FIXME: This is obviously a punt and needs to be adjusted. */
bool Memories::allocate_all_tind() {
    find_tind_groups();
    while (!tind_groups.empty()) {
        auto *tg = tind_groups[0];
        if (tg->ta->layout_option->local_tinds) {
            auto unique_id = tg->build_unique_id();
            auto &alloc = (*tg->ta->memuse)[unique_id];
            int placed_tind = 0;
            int ingress_stage = (tg->ta->table->gress != EGRESS) ?
                                local_stage : EGRESS_STAGE0_INGRESS_STAGE - local_stage;
            scm_alloc_stage &alloc_stage = scm_curr_alloc.stage_to_alloc[ingress_stage];
            // Populate Highest table id first with Local Tind 15..0 for ingress and 0..15 for
            // egress
            auto tids = tg->ta->table->gress == EGRESS ? Range(0, TOTAL_LOCAL_TIND - 1) :
                                                         Range(TOTAL_LOCAL_TIND - 1, 0);
            LOG4("Allocation for " << unique_id.build_name());
            for (int i : tids) {
                if (!alloc_stage.local_tind_use[i]) {
                    alloc_stage.local_tind_use[i] = tg->ta->table;
                    placed_tind++;
                    alloc.local_tind.push_back(i);
                    LOG4("local_tind: " << i << " placed_tind: " << placed_tind);
                    if (placed_tind == tg->ta->layout_option->local_tinds)
                        break;
                }
            }
            if (placed_tind != tg->ta->layout_option->local_tinds) {
                failure_reason = "no local tind row available";
                return false;
            }
            tind_groups.erase(tind_groups.begin());
            continue;
        }
    }
    LOG7(scm_curr_alloc);
    return true;
}

void Memories::fill_placed_scm_table(const IR::MAU::Table *t, const TableResourceAlloc *resources) {
    int group = -1;
    Use::h_bus_t bus = Use::NONE;
    for (auto &kv : resources->memuse) {
        if (kv.second.type == Use::TERNARY) {
            for (auto &kv2 : kv.second.loc_to_gb) {
                const Use::ScmLoc &scm_loc = kv2.first;
                std::tie(group, bus) = kv2.second;
                int ingress_stage = (t->gress != EGRESS) ? scm_loc.stage :
                                                        EGRESS_STAGE0_INGRESS_STAGE - scm_loc.stage;
                scm_alloc_stage &alloc_stage = scm_curr_alloc.stage_to_alloc[ingress_stage];
                alloc_stage.tcam_use[scm_loc.row] = t;
                alloc_stage.tcam_grp[scm_loc.row] = group;
                unsigned mask_loc = 1 << scm_loc.row;
                alloc_stage.tcam_in_use |= mask_loc;
                switch (bus) {
                case Use::LEFT_HBUS1:
                    alloc_stage.left_hbus1[scm_loc.row] = t;
                    alloc_stage.left_hbus1_in_use |= mask_loc;
                    LOG7("Table " << t->name << " use LEFT_HBUS1 on stage:" << ingress_stage <<
                        " row:" << scm_loc.row << " for group:" << group);
                    break;
                case Use::LEFT_HBUS2:
                    alloc_stage.left_hbus2[scm_loc.row] = t;
                    alloc_stage.left_hbus2_in_use |= mask_loc;
                    LOG7("Table " << t->name << " use LEFT_HBUS2 on stage:" << ingress_stage <<
                        " row:" << scm_loc.row << " for group:" << group);
                    break;
                case Use::RIGHT_HBUS1:
                    alloc_stage.right_hbus1[scm_loc.row] = t;
                    alloc_stage.right_hbus1_in_use |= mask_loc;
                    LOG7("Table " << t->name << " use RIGHT_HBUS1 on stage:" << ingress_stage <<
                        " row:" << scm_loc.row << " for group:" << group);
                    break;
                case Use::RIGHT_HBUS2:
                    alloc_stage.right_hbus2[scm_loc.row] = t;
                    alloc_stage.right_hbus2_in_use |= mask_loc;
                    LOG7("Table " << t->name << " use RIGHT_HBUS2 on stage:" << ingress_stage <<
                        " row:" << scm_loc.row << " for group:" << group);
                    break;
                case Use::NONE:
                    scm_curr_alloc.tbl_to_local_stage[t] = ingress_stage;
                    LOG7("Table " << t->name << " use local bus on stage:" << ingress_stage <<
                        " row:" << scm_loc.row << " for group:" << group);
                    break;
                default:
                    BUG("Unhandled horizontal bus type %d", bus);
                    break;
                }
            }
        } else if (kv.second.type == Use::TIND && !kv.second.local_tind.empty()) {
            int local_stage = scm_curr_alloc.tbl_to_local_stage[t];
            scm_alloc_stage &alloc_stage = scm_curr_alloc.stage_to_alloc[local_stage];
            for (int local_tind : kv.second.local_tind) {
                alloc_stage.local_tind_use[local_tind] = t;
                LOG7("Table " << t->name << " use local tind on stage:" << local_stage <<
                    " row:" << local_tind);
            }
        }
    }
}

void Memories::visitUse(const Use &alloc, std::function<void(cstring &, update_type_t)> fn) {
    BFN::Alloc2Dbase<cstring> *use = 0, *mapuse = 0, *bus = 0, *gw_use = 0;
    unsigned *inuse = 0, *map_inuse = 0;
    switch (alloc.type) {
    case Use::EXACT:
        use = &sram_use;
        inuse = sram_inuse;
        bus = &sram_print_search_bus;
        break;
    case Use::TERNARY:
        // Currently not handled
        break;
    case Use::GATEWAY:
        gw_use = &gateway_use;
        //  bus = &sram_print_result_bus;
        break;
    case Use::TIND:
        use = &sram_use;
        inuse = sram_inuse;
        bus = &tind_bus;
        break;
    case Use::ACTIONDATA:
        use = &sram_use;
        inuse = sram_inuse;
        //  bus = &sram_print_result_bus;
        break;
    default:
        BUG("Unhandled memory use type %d in visit", alloc.type); }
    for (auto &r : alloc.row) {
        if (bus && r.result_bus != -1) {
            fn((*bus)[r.row][r.result_bus], UPDATE_RESULT_BUS); }
        if (use) {
            for (auto col : r.col) {
                fn((*use)[r.row][col], UPDATE_RAM);
                if (inuse) {
                    if ((*use)[r.row][col])
                        inuse[r.row] |= 1 << col;
                    else
                        inuse[r.row] &= ~(1 << col); } } }
        if (mapuse) {
            for (auto col : r.mapcol) {
                fn((*mapuse)[r.row][col], UPDATE_MAPRAM);
                if ((*mapuse)[r.row][col])
                    map_inuse[r.row] |= 1 << col;
                else
                    map_inuse[r.row] &= ~(1 << col); } }
        if (gw_use) {
            fn((*gw_use)[r.row][alloc.gateway.unit], UPDATE_GATEWAY);
            if (alloc.gateway.payload_row >= 0)
                fn(payload_use[alloc.gateway.payload_row][alloc.gateway.payload_unit],
                   UPDATE_PAYLOAD);
        }
    }
    if (mapuse) {
        for (auto &r : alloc.color_mapram) {
            for (auto col : r.col) {
                fn((*mapuse)[r.row][col], UPDATE_MAPRAM);
                if ((*mapuse)[r.row][col])
                    map_inuse[r.row] |= 1 << col;
                else
                    map_inuse[r.row] &= ~(1 << col); } } }
}

void Memories::update(cstring name, const Use &alloc) {
    visitUse(alloc, [name](cstring &use, update_type_t u_type) {
        if (use && use != name) {
            bool collision = true;
            // A table may have different search buses, but the same result bus.  Say a table
            // required two hash functions (i.e. 5 way table).  The table would require two
            // search / address buses, but only one result bus.  Thus the name repeat is fine
            // for result_buses
            if (u_type == UPDATE_RESULT_BUS && name == use)
                collision = false;

            if (collision)
                BUG_CHECK("conflicting memory use between %s and %s", use, name);
        }
        use = name;
    });
}

void Memories::update(const std::map<UniqueId, Use> &alloc) {
    for (auto &a : alloc) update(a.first.build_name(), a.second);
}

void Memories::remove(cstring name, const Use &alloc) {
    visitUse(alloc, [name](cstring &use, update_type_t) {
        if (use != name)
            BUG("Undo failure for %s", name);
        use = nullptr; });
}
void Memories::remove(const std::map<UniqueId, Use> &alloc) {
    for (auto &a : alloc) remove(a.first.build_name(), a.second);
}

std::ostream &operator<<(std::ostream &out, const Memories::search_bus_info &sbi) {
    out << "search bus " << sbi.name << " width: " << sbi.width_section << " hash_group: "
        << sbi.hash_group;
    return out;
}

std::ostream &operator<<(std::ostream &out, const Memories::result_bus_info &rbi) {
    out << "result bus " << rbi.name << " width: " << rbi.width_section << " hash_group: "
        << rbi.logical_table;
    return out;
}

std::ostream & operator<<(std::ostream &out, const Memories::scm_alloc &scma) {
    // Build table -> abreviated name map using e.g. A00G0000 for the first TCAM table defined
    // on stage 0 group 0.
    std::map<const IR::MAU::Table *, cstring> tbl_to_ab;
    std::map<cstring, const IR::MAU::Table *> ab_to_tbl;
    std::vector<char> next_val(16, 'A');

    if (scma.tbl_to_local_stage.empty())
        return out;

    for (const auto& [tbl, stage] : scma.tbl_to_local_stage) {
        char str[8];
        snprintf(str, sizeof(str), "%02d", stage);
        tbl_to_ab[tbl] = next_val[stage]++ + cstring(str);
        ab_to_tbl[tbl_to_ab[tbl]] = tbl;
    }
    std::vector<std::string> row_str(Memories::TCAM_ROWS);
    std::vector<std::string> tind_str(Memories::TOTAL_LOCAL_TIND/2);  // Output 2 tinds per row
    out << Log::endl;
    for (const auto& [stage, scm_alloc] : scma.stage_to_alloc) {
        char str[8];
        snprintf(str, sizeof(str), "%02d", stage);
        out << "Stage " << cstring(str) << " ";
        for (int row = 0; row < Memories::TCAM_ROWS; row++) {
            std::string &row_ref = row_str[row];
            if (!scm_alloc.tcam_use[row]) {
                row_ref += "-------- ";
                continue;
            }
            row_ref += tbl_to_ab[scm_alloc.tcam_use[row]];
            snprintf(str, sizeof(str), "%04d", scm_alloc.tcam_grp[row]);
            row_ref += "G" + std::string(str) + " ";
        }
        for (int row = 0; row < Memories::TOTAL_LOCAL_TIND; row++) {
            std::string &row_ref = tind_str[row/2];
            if (!scm_alloc.local_tind_use[row]) {
                row_ref += "--- ";
                if (!(row & 1)) row_ref += " ";
                continue;
            }
            row_ref += tbl_to_ab[scm_alloc.local_tind_use[row]];
            row_ref += " ";
            if (!(row & 1)) row_ref += " ";
        }
    }
    // Output the Stage header line
    out << Log::endl;
    for (std::string &out_str : row_str) {
        out << out_str << Log::endl;
    }
    out << "**Local Ternary Indirection Table shows on even and odd pair**" << Log::endl;
    for (std::string &out_str : tind_str) {
        out << out_str << Log::endl;
    }
    for (const auto& [ab, tbl] : ab_to_tbl) {
        out << ab << " Table:" << tbl->name << " Gress:" << tbl->gress << " Num Entries:" <<
        tbl->layout.entries << " Match Bytes:" << tbl->layout.match_bytes << Log::endl;
    }
    return out;
}

/* MemoriesPrinter in .gdbinit should match this */
void Memories::printOn(std::ostream &out) const {
    const BFN::Alloc2Dbase<cstring> *arrays[] = { &sram_print_search_bus,
                &sram_print_result_bus, &tind_bus, &sram_use, &gateway_use };
    std::map<cstring, char>     tables;
    for (auto arr : arrays)
        for (int r = 0; r < arr->rows(); r++)
            for (int c = 0; c < arr->cols(); c++)
                if (arr->at(r, c))
                    tables[arr->at(r, c)] = '?';
    char ch = 'A' - 1;
    for (auto &t : tables) {
        t.second = ++ch;
        if (ch == 'Z') ch = 'a'-1;
        else if (ch == 'z') ch = '0'-1; }
    out << "sb  rb  tib srams  gw" << Log::endl;
    for (int r = 0; r < Memories::SRAM_ROWS; r++) {
        for (auto arr : arrays) {
            for (int c = 0; c < arr->cols(); c++) {
                if (r >= arr->rows()) {
                    out << ' ';
                } else {
                    if (auto tbl = arr->at(r, c)) {
                        out << tables.at(tbl);
                    } else {
                        out << '.'; } } }
            out << "  "; }
        out << Log::endl; }
    for (auto &tbl : tables)
        out << "   " << tbl.second << " " << tbl.first << Log::endl;
}

void dump(const Memories *mem) {
    mem->printOn(std::cout);
}

std::ostream & operator<<(std::ostream &out, const Memories::table_alloc &ta) {
    out << "table_alloc[" << ta.table->match_table->externalName() << ": ";
    for (auto &u : *ta.memuse)
        out << "(" << u.first.build_name() << ", " << use_type_to_str[u.second.type] << ") ";
    out << "]";
    return out;
}

std::ostream &operator<<(std::ostream &out, const safe_vector<Memories::table_alloc *> &v) {
    const char *sep = "";
    for (auto *ta : v) {
        out << sep << ta->table->name;
        sep = ", "; }
    return out;
}

}  // end namespace Flatrock
