#include "bf-p4c/phv/finalize_physical_liverange.h"
#include <sstream>
#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/parde/clot/clot.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/slice_alloc.h"
#include "lib/exceptions.h"
#include "lib/safe_vector.h"

namespace PHV {

namespace {

/// return all overlapping AllocSlices without taking subslice based on range. We need to use
/// these AllocSlices as keys for updating live ranges.
safe_vector<AllocSlice> find_all_overlapping_alloc_slices(
        const Field* f, const le_bitrange range, const PHV::AllocContext* ctx, bool is_write) {
    safe_vector<AllocSlice> rst;
    const PHV::FieldUse use(is_write ? PHV::FieldUse::WRITE : PHV::FieldUse::READ);
    f->foreach_alloc(StartLen(0, f->size), ctx, &use, [&](const PHV::AllocSlice& slice) {
        if (slice.field_slice().overlaps(range)) {
            rst.push_back(slice);
        }
    });
    return rst;
}

StageAndAccess to_stage_and_access(const IR::BFN::Unit* unit,
                                   const bool is_write,
                                   const PHV::Field* f) {
    if (unit->is<IR::BFN::ParserState>() || unit->is<IR::BFN::Parser>() ||
        unit->is<IR::BFN::GhostParser>()) {
        return {-1, FieldUse(FieldUse::WRITE)};
    } else if (unit->is<IR::BFN::Deparser>()) {
        return {Device::numStages(), FieldUse(FieldUse::READ)};
    } else if (unit->is<IR::MAU::Table>()) {
        const auto* t = unit->to<IR::MAU::Table>();
        return {t->stage(), FieldUse(is_write ? FieldUse::WRITE : FieldUse::READ)};
    } else {
        BUG("unknown unit: %1%, field: %2%", unit, f);
    }
}

}  // namespace

void FinalizePhysicalLiverange::update_liverange(const safe_vector<AllocSlice>& slices,
                                                 const StageAndAccess& op) {
    for (const auto& slice : slices) {
        // update AllocSlice-based live range.
        LOG1("update live range of " << slice << ": " << op);
        if (live_ranges_i.count(slice)) {
            live_ranges_i.at(slice).extend(op);
        } else {
            live_ranges_i.emplace(slice, LiveRange(op, op));
        }
    }
}

/// collect table to stage.
bool FinalizePhysicalLiverange::preorder(const IR::MAU::Table* t) {
    tables_i.insert(t);
    table_stages_i[TableSummary::getTableIName(t)].insert(t->stage());
    return true;
}

void FinalizePhysicalLiverange::mark_access(const PHV::Field* f, le_bitrange bits,
                                            const IR::BFN::Unit* unit, bool is_write,
                                            bool allow_unallocated) {
    // skip clot-allocated unused fields.
    if (clot_i.fully_allocated(FieldSlice(f, bits))) {
        return;
    }
    const StageAndAccess access = to_stage_and_access(unit, is_write, f);
    const auto alloc_slices =
        find_all_overlapping_alloc_slices(f, bits, AllocContext::of_unit(unit), is_write);
    if (alloc_slices.empty() && !allow_unallocated) {
        // (1) Temp vars will be allocated later.
        // (2) It is safe to ignore access in deparser when
        //     clot_i.allocated_unmodified_undigested(f) is true.
        //     It means that the live range of the field is shrunken due to clot allocation.
        // (3) We did not handle digest type field perfectly so that there might be
        //     duplicated padding fields added, although allocation are still correct.
        //     An example case:
        //     remove `(f->padding && f->is_digest())` and run p4_16_samples/issue1043-bmv2.p4
        BUG_CHECK(
            phv_i.isTempVar(f) ||
            (unit->is<IR::BFN::Deparser>() && clot_i.allocated_unmodified_undigested(f)) ||
            (f->padding && f->is_digest()),
            "cannot find corresponding slice, field: %1%, range: %2%, is_write: %3%.\n unit: %4%",
            f, bits, is_write, unit);
        // memorize live range of unallocated temp vars.
        if (phv_i.isTempVar(f)) {
            if (temp_var_live_ranges_i.count(f)) {
                temp_var_live_ranges_i.at(f).extend(access);
            } else {
                temp_var_live_ranges_i.emplace(f, LiveRange(access, access));
            }
        }
        return;
    }
    update_liverange(alloc_slices, access);
}

bool FinalizePhysicalLiverange::preorder(const IR::Expression* e) {
    LOG5("FinalizePhysicalLiverange preorder : " << e);;
    le_bitrange bits;
    const PhvInfo& phv = phv_i;  // const ref to ensure that we do not create new fields.
    auto* f = phv.field(e, &bits);
    if (!f) {
        LOG5("Found non-field expr: " << e);
        return true;
    }
    LOG5("Found " << f->name << " " << bits << " from " << e);
    const auto* unit = findContext<IR::BFN::Unit>();
    BUG_CHECK(unit, "cannot find unit: %1%", e);
    const bool is_write = isWrite();
    // There could be unallocated parser temp vars that are not eliminated before lowering.
    const bool allow_unallocated = unit->is<IR::BFN::ParserState>() ||
                                   unit->is<IR::BFN::Parser>() ||
                                   unit->is<IR::BFN::GhostParser>();
    mark_access(f, bits, unit, is_write, allow_unallocated);
    // NOTE: We do not need to visit alias source/destinations because we have already reinstate
    // all aliased field in IR.
    return false;
}

void FinalizePhysicalLiverange::end_apply() {
    // update AllocSlices' live range.
    for (auto& f : phv_i) {
        for (auto& slice : f.get_alloc()) {
            BUG_CHECK(
                slice.isPhysicalStageBased(),
                "FinalizePhysicalLiverange can only be applied on physical-stage AllocSlices");
            // Although it should be safe to drop allocated but unreferenced slices,
            // but because most analysis pass were built on field-level, dropping them
            // will make some later passes fail. For example,
            // the CheckForUnallocated pass, which is using phv_uses.
            // LOG here is a good place to see how many bits we can save by updating those
            // passed to fieldslice-level.
            if (!live_ranges_i.count(slice)) {
                LOG1("Found allocated but unreferenced AllocSlice: " << slice);
            } else {
                const auto old = LiveRange(slice.getEarliestLiveness(), slice.getLatestLiveness());
                const auto& updated = live_ranges_i.at(slice);
                LOG3("Finalizing " << old << " => " << updated << " : " << slice);
                slice.setLiveness(updated.start, updated.end);
            }
        }
        // sort alloc by MSB and earliest live range.
        f.sort_alloc();
    }
    // update physical stage info.
    PhvInfo::clearPhysicalStageInfo();
    for (const auto* table : tables_i) {
        BUG_CHECK(table_stages_i.count(TableSummary::getTableIName(table)),
                  "cannot find stage info of table: %1%", table);
        PhvInfo::setPhysicalStages(table, table_stages_i.at(TableSummary::getTableIName(table)));
    }

    // BUG_CHECK for overlapped live ranges of overlaying but non-mutex fields.
    // Slice Filtering Function
    std::function<bool(const PHV::AllocSlice* sl)> need_skip_slices =
        [&](const PHV::AllocSlice* sl) -> bool {
        if (!sl) return true;
        if (!sl->field()) return true;
        // skip alias destination fields and deparsed-zero fields
        if (sl->field()->aliasSource != nullptr || sl->field()->is_deparser_zero_candidate())
            return true;
        // skip
        return (sl->isUninitializedRead());
    };

    // Temporarily disabled (print warnings instead of BUG_CHECK),
    // because post-table-placement table-mutex pass seems to be incorrect.
    // In barefoot_academy/p4c-2756.p4, it complains about
    // table ipv6_lpm_0 reads ... stage 1, while table ipv6_host_0 writes ... stage 0
    // but in P4 codes, they are mutex.
    // if (!ipv6_host.apply().hit) {
    //     ipv6_lpm.apply();
    // }

    // BUG_CHECK that all non-mutex nor liverange-disjoint but overlaid fields are accessed
    // mutex tables only.
    // Two non-mutex fields, f_a and f_b, are overlaid in B0.
    // f_a's live range: [-1w, 4r]
    // f_b's live range: [3w, 7r]
    // It's not a BUG, because when the table t_a that writes f_a are mutex
    // with table t_b that reads f_b, hence they will not cause read / write violations
    //
    //             stage 3         stage 4
    //    |---- t_a writes B0
    // ---|
    //    |--------------------- t_b reads B0
    //
    for (const auto& c_slices : phv_i.getContainerToSlicesMap(nullptr, &need_skip_slices)) {
        const auto& slices = c_slices.second;
        if (slices.size() <= 1) continue;
        for (auto i = slices.begin(); i != (slices.end() - 1); i++) {
            for (auto j = i + 1; j != slices.end(); j++) {
                const auto& si = *i;
                const auto& sj = *j;
                if (!si.container_slice().overlaps(sj.container_slice())) {
                    continue;
                }
                if (phv_i.field_mutex()(si.field()->id, sj.field()->id)) {
                    continue;
                }
                if (si.isLiveRangeDisjoint(sj)) {
                    continue;
                }
                bool is_i_before_j = si.getEarliestLiveness() < sj.getEarliestLiveness();
                const PHV::AllocSlice& from = is_i_before_j ? si : sj;
                const PHV::AllocSlice& to   = is_i_before_j ? sj : si;
                for (const auto& from_locpair : defuse_i.getAllUses(from.field()->id)) {
                    const auto from_table = from_locpair.first->to<IR::MAU::Table>();
                    if (!from_table) continue;
                    for (const auto& to_locpair : defuse_i.getAllDefs(to.field()->id)) {
                        const auto to_table = to_locpair.first->to<IR::MAU::Table>();
                        if (!to_table) continue;
                        if (TableSummary::getTableIName(from_table) ==
                            TableSummary::getTableIName(to_table))
                            continue;  // same table is okay!
                        if (from_table->stage() <= to_table->stage()) continue;
                        // BUG_CHECK(tb_mutex_i(from_table, to_table),
                        //           "Overlaying slices with overlapped live range without "
                        //           "non-mutex table access is not allowed. table %1% reads %2% "
                        //           "at stage %3%, while table %4% writes %5% at stage %6%",
                        //           from_table->name, from, from_table->stage(), to_table->name,
                        //           to, to_table->stage());
                        if (!tb_mutex_i(from_table, to_table)) {
                            ::warning(
                                "Overlaying slices with overlapped live range are not allowed to "
                                "be accessed by non-mutex tables. table %1% reads %2% "
                                "at stage %3%, while table %4% writes %5% at stage %6%."
                                "This could be a false-positive alarm due to imprecise table mutex "
                                "analysis in post-table-placement phase. If two tables above are "
                                "mutually exclusive, it is safe to ignore this warning.",
                                from_table->externalName(), cstring::to_cstring(from),
                                from_table->stage(), to_table->externalName(),
                                cstring::to_cstring(to), to_table->stage());
                        }
                    }
                }
            }
        }
    }

    if (LOGGING(3)) {
        // log final phv allocation
        LOG3("PHV Allocation Result After Live Range Finalization");
        for (const auto& f : phv_i) {
            for (const auto& alloc_sl : f.get_alloc()) {
                LOG3(alloc_sl);
            }
        }
        // log table to physical stages
        LOG3("Table Physical Liverange Map After Live Range Finalization");
        for (const auto& kv : PhvInfo::table_to_physical_stages) {
            const cstring table = kv.first;
            std::stringstream ss;
            ss << table << ": ";
            cstring sep = "";
            for (const auto& v : kv.second) {
                ss << sep << v;
                sep = ", ";
            }
            LOG3(ss.str());
        }
        // log temp var physical liveranges
        for (const auto& kv : temp_var_live_ranges_i) {
            LOG3("liverange of temp var " << kv.first << ":" << kv.second);
        }
    }
}

}  // namespace PHV
