#include "bf-p4c/phv/finalize_physical_liverange.h"
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
    table_stages_i[TableSummary::getTableName(t)].insert(t->stage());
    return true;
}

void FinalizePhysicalLiverange::mark_access(const PHV::Field* f, le_bitrange bits,
                                            const IR::BFN::Unit* unit, bool is_write,
                                            bool allow_unallocated) {
    // skip clot-allocated fields.
    if (clot_i.fully_allocated(FieldSlice(f, bits))) {
        return;
    }
    const auto alloc_slices =
        find_all_overlapping_alloc_slices(f, bits, AllocContext::of_unit(unit), is_write);
    // XXX(yumin): we did not handle digest type field perfectly so that there might be
    // duplicated padding fields added, although allocation are still correct.
    // An example case:
    // remove `|| (f->padding && f->is_digest())` and run p4_16_samples/issue1043-bmv2.p4
    BUG_CHECK(allow_unallocated || alloc_slices.size() > 0 || (f->padding && f->is_digest()),
              "cannot find corresponding slice, field: %1%, range: %2%, is_write: %3%.\n unit: %4%",
              f, bits, is_write, unit);
    if (unit->is<IR::BFN::ParserState>() || unit->is<IR::BFN::Parser>() ||
        unit->is<IR::BFN::GhostParser>()) {
        update_liverange(alloc_slices, {-1, FieldUse(FieldUse::WRITE)});
    } else if (unit->is<IR::BFN::Deparser>()) {
        update_liverange(alloc_slices, {Device::numStages(), FieldUse(FieldUse::READ)});
    } else if (unit->is<IR::MAU::Table>()) {
        const auto* t = unit->to<IR::MAU::Table>();
        update_liverange(alloc_slices,
                         {t->stage(), FieldUse(is_write ? FieldUse::WRITE : FieldUse::READ)});
    } else {
        BUG("unknown unit: %1%, field: %2%", unit, f);
    }
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
    for (auto& f : phv_i) {
        // slices that liveranges start and end with read.
        // For p4c-2423, ingress::ig_md.pgid_pipe_port_index was read only and never
        // written. In this case, table could be arbitrarily reordered and we may see
        // overlapped live ranges for one field slices, which will break the compilation.
        // This is a very rare case and it is likely a bug of the P4 program.
        ordered_map<le_bitrange, safe_vector<AllocSlice>> read_only_slices;
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
                continue;
            }
            const auto old = LiveRange(slice.getEarliestLiveness(), slice.getLatestLiveness());
            const auto& updated = live_ranges_i.at(slice);
            LOG3("Finalizing " << old << " => " << updated << " : " << slice);
            slice.setLiveness(updated.start, updated.end);
            if (slice.getEarliestLiveness().second.isRead() &&
                slice.getLatestLiveness().second.isRead()) {
                read_only_slices[slice.field_slice()].push_back(slice);
            }
        }
        if (!read_only_slices.empty()) {
            ordered_set<AllocSlice> to_remove;
            for (auto& slices : Values(read_only_slices)) {
                // sort by the start of live range.
                sort(slices.begin(), slices.end(), [](AllocSlice& a, AllocSlice& b) {
                    return a.getEarliestLiveness() < b.getEarliestLiveness();
                });
                // DE-duplicate overlapped live ranges.
                int latest_lr = slices.front().getLatestLiveness().first;
                for (auto itr = slices.begin() + 1; itr != slices.end(); itr++) {
                    if (itr->getLatestLiveness().first <= latest_lr) {
                        LOG3("Removing duplicated : " << *itr);
                        to_remove.insert(*itr);
                    } else {
                        if (itr->getEarliestLiveness().first <= latest_lr) {
                            const auto old =
                                LiveRange(itr->getEarliestLiveness(), itr->getLatestLiveness());
                            itr->setEarliestLiveness({latest_lr + 1, FieldUse(FieldUse::READ)});
                            const auto updated =
                                LiveRange(itr->getEarliestLiveness(), itr->getLatestLiveness());
                            LOG3("Finalizing " << old << " => " << updated << " : " << *itr);
                        }
                        latest_lr = itr->getLatestLiveness().first;
                    }
                }
            }
            if (!to_remove.empty()) {
                safe_vector<AllocSlice> filtered;
                for (auto& slice : f.get_alloc()) {
                    if (to_remove.count(slice)) continue;
                    filtered.push_back(slice);
                }
                f.set_alloc(filtered);
            }
        }
        // sort alloc by MSB and earliest live range.
        f.sort_alloc();
    }
    // update physical stage info.
    PhvInfo::clearPhysicalStageInfo();
    for (const auto* table : tables_i) {
        BUG_CHECK(table_stages_i.count(TableSummary::getTableName(table)),
                  "cannot find stage info of table: %1%", table);
        PhvInfo::setPhysicalStages(table, table_stages_i.at(TableSummary::getTableName(table)));
    }
}

}  // namespace PHV
