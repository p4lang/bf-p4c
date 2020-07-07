#include <boost/optional/optional_io.hpp>
#include "lib/algorithm.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/cluster_phv_operations.h"

int ActionPhvConstraints::ConstraintTracker::current_action = 0;

Visitor::profile_t ActionPhvConstraints::init_apply(const IR::Node *root) {
    profile_t rv = Inspector::init_apply(root);
    meter_color_destinations.clear();
    special_no_pack.clear();
    constraint_tracker.clear();
    prelim_constraints_ok = true;
    same_byte_fields.clear();
    determine_same_byte_fields();
    return rv;
}

bool ActionPhvConstraints::preorder(const IR::MAU::Action *act) {
    auto *tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, false, false, tbl);
    ActionAnalysis::FieldActionsMap field_actions_map;
    aa.set_field_actions_map(&field_actions_map);
    act->apply(aa);
    constraint_tracker.add_action(act, field_actions_map);
    prelim_constraints_ok &= early_check_ok(act);
    return true;
}

void ActionPhvConstraints::end_apply() {
    LOG7("*****Printing  ActionPhvConstraints Maps*****");
    constraint_tracker.printMapStates();
    LOG7("*****End Print ActionPhvConstraints Maps*****");
}

void ActionPhvConstraints::ConstraintTracker::clear() {
    LOG6("CLEARING ActionPhvConstraints");
    current_action = 0;
    field_writes_to_actions.clear();
    action_to_writes.clear();
    action_to_reads.clear();
    write_to_reads_per_action.clear();
    read_to_writes_per_action.clear();
    statefulWrites.clear();
}

void ActionPhvConstraints::ConstraintTracker::add_action(
        const IR::MAU::Action *act,
        const ActionAnalysis::FieldActionsMap field_actions_map) {
    LOG5("Action PHV Constraints: Analyzing " << act);
    for (auto &field_action : Values(field_actions_map)) {
        le_bitrange write_range;
        auto *write_field = phv.field(field_action.write.expr, &write_range);
        if (write_field == nullptr)
            BUG("Action does not have a write?");
        PHV::FieldSlice write(write_field, write_range);
        field_writes_to_actions[write_field][write_range].insert(act);
        OperandInfo fw(write, current_action);
        fw.operation = field_action.name;
        if (field_action.name == "set") {
            fw.flags |= OperandInfo::MOVE;
        } else if (PHV_Field_Operations::BITWISE_OPS.count(field_action.name)) {
            fw.flags |= OperandInfo::BITWISE;
        } else {
            fw.flags |= OperandInfo::WHOLE_CONTAINER; }

        fw.action_name = field_action.name;
        LOG5("    ...write: " << fw);
        action_to_writes[act].insert(fw);
        for (auto &read : field_action.reads) {
            OperandInfo fr;
            fr.unique_action_id = current_action;
            if (read.type == ActionAnalysis::ActionParam::PHV) {
                le_bitrange read_range;
                auto* f_used = phv.field(read.expr, &read_range);
                fr.phv_used = PHV::FieldSlice(f_used, read_range);
                read_to_writes_per_action[f_used][act][read_range].insert(write);
                action_to_reads[act].insert(*fr.phv_used);
            } else if (read.type == ActionAnalysis::ActionParam::ACTIONDATA) {
                fr.ad = true;
                fr.special_ad = read.speciality;
                if (LOGGING(5) && read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL)
                    LOG5("      ...speciality action data read: " << fr);
            } else if (read.type == ActionAnalysis::ActionParam::CONSTANT) {
                fr.constant = true;
                if (read.expr->is<IR::Constant>()) {
                    const auto* constExpr = read.expr->to<IR::Constant>();
                    if (constExpr->fitsLong())
                        fr.const_value = constExpr->asLong();
                    else
                        fr.const_value = -1;
                } else {
                    fr.const_value = -1;
                }
            } else {
                BUG("Read must either be of a PHV, action data, or constant."); }

            // xxx(Deep): This condition is to satisfy the current table placement requirement that
            // any destination written by meter colors must be allocated to an 8-bit PHV
            if (read.speciality == ActionAnalysis::ActionParam::METER_COLOR)
                self.meter_color_destinations.insert(write.field());

            // xxx(Deep): This condition is to satisfy the current table placement requirement that
            // any destination written by METER_ALU, METER_COLOR, HASH_DIST, or RANDOM must not be
            // packed with other fields written in the same action. To enable this, maintain a list
            // of all actions where such writes happen for the given field.
            if (read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL) {
                self.special_no_pack[write.field()].insert(act);
                if (read.speciality == ActionAnalysis::ActionParam::METER_ALU) {
                    int lo, hi;
                    if (auto sl = read.expr->to<IR::Slice>()) {
                        lo = sl->getL();
                        hi = sl->getH();
                    } else {
                        lo = 0;
                        hi = read.size() - 1;
                    }
                    std::pair<int, int> write_range_pair = std::make_pair(write_range.lo,
                            write_range.hi);
                    std::pair<int, int> read_range_pair = std::make_pair(lo, hi);
                    statefulWrites[write_field][write_range].insert(
                            std::make_pair(write_range_pair, read_range_pair));
                    LOG5("\t  ...adding stateful read range [" << lo << ", " << hi << "] and "
                         "write range [" << write_range_pair.first << ", " <<
                         write_range_pair.second << "]");
                }
            }

            if (field_action.reads.size() > 1) {
                fr.flags |= OperandInfo::ANOTHER_OPERAND;
            }
            fr.operation = field_action.name;
            if (field_action.name == "set") {
                fr.flags |= OperandInfo::MOVE;
            } else if (PHV_Field_Operations::BITWISE_OPS.count(field_action.name)) {
                fr.flags |= OperandInfo::BITWISE;
            } else {
                fr.flags |= OperandInfo::WHOLE_CONTAINER; }
            fr.action_name = field_action.name;
            LOG5("    ...read: " << fr);
            write_to_reads_per_action[write_field][act][write_range].push_back(fr); } }

    current_action++;
}

bool ActionPhvConstraints::checkSpecialityPacking(ordered_set<const PHV::Field*>& fields) const {
    ordered_set<const PHV::Field*> special_writes;
    // Detect all the speciality writes in the container
    for (const PHV::Field* f : fields) {
        if (special_no_pack.count(f))
            special_writes.insert(f); }

    // If no special writes, detected return true
    if (special_writes.size() == 0) return true;

    // If special writes present, check against all other actions
    for (const PHV::Field* f : special_writes) {
        for (const IR::MAU::Action* act : special_no_pack.at(f)) {
            for (auto& fo_wr : constraint_tracker.writes(act)) {
                if (!fo_wr.phv_used) continue;
                const PHV::Field* f_wr = fo_wr.phv_used->field();
                if (f_wr == f) continue;
                if (fields.count(f_wr))
                    return false; } } }

    return true;
}

std::vector<ActionPhvConstraints::OperandInfo> ActionPhvConstraints::ConstraintTracker::sources(
        PHV::FieldSlice dst,
        const IR::MAU::Action* act) const {
    std::vector<OperandInfo> rv;

    // Check whether this field is ever a dst.
    if (write_to_reads_per_action.find(dst.field()) == write_to_reads_per_action.end())
        return rv;

    auto& by_action = write_to_reads_per_action.at(dst.field());
    if (by_action.find(act) == by_action.end())
        return rv;

    // Find the range containing @dst, if any.
    auto& by_range = by_action.at(act);
    const le_bitrange *containing = nullptr;
    for (auto& kv : by_range) {
        if (kv.first.contains(dst.range())) {
            BUG_CHECK(containing == nullptr,
                      "Field %1% written to more than once in action %2%",
                      dst.field()->name, act);
            containing = &(kv.first); } }
    if (containing == nullptr)
        return rv;

    // Shrink each source field operand to correspond to the slice of the
    // destination, if any.  The offset of `dst` in `containing` must
    // correspond to the shrunken range to the source operand range.
    unsigned offset = dst.range().lo - containing->lo;    // Positive because containing.

    for (auto field_op : by_range.at(*containing)) {
        // Skip non-PHV operands.
        if (!field_op.phv_used) {
            rv.push_back(field_op);
            continue; }
        auto& used = field_op.phv_used;
        le_bitrange shifted = StartLen(used->range().lo + offset, dst.range().size());
        le_bitinterval src_int = used->range().intersectWith(shifted);
        if (auto src_range = toClosedRange(src_int)) {
            // Copy field_op, then update `phv_used` in the copy.
            rv.push_back(field_op);
            rv.back().phv_used = PHV::FieldSlice(used->field(), *src_range); } }

    return rv;
}

ordered_set<PHV::FieldSlice> ActionPhvConstraints::ConstraintTracker::destinations(
        PHV::FieldSlice src,
        const IR::MAU::Action* act) const {
    ordered_set<PHV::FieldSlice> rv;

    // Check whether this field is ever a source.
    if (read_to_writes_per_action.find(src.field()) == read_to_writes_per_action.end())
        return rv;

    auto& by_action = read_to_writes_per_action.at(src.field());
    if (by_action.find(act) == by_action.end())
        return rv;

    // Find the range containing @src, if any.
    for (auto& kv : by_action.at(act)) {
        if (!kv.first.contains(src.range()))
            continue;

        // Shrink each destination field operand to correspond to the slice of the
        // source, if any.  The offset of `src` in `kv.first` must
        // correspond to the shrunken range to the destination operand range.
        unsigned offset = src.range().lo - kv.first.lo;    // Positive because containing.
        for (auto slice : kv.second) {
            le_bitrange shifted = StartLen(slice.range().lo + offset, src.range().size());
            le_bitinterval src_int = slice.range().intersectWith(shifted);
            if (auto src_range = toClosedRange(src_int))
                rv.insert(PHV::FieldSlice(slice.field(), *src_range)); } }

    return rv;
}

const ordered_set<ActionPhvConstraints::OperandInfo>&
ActionPhvConstraints::ConstraintTracker::writes(const IR::MAU::Action* act) const {
    static ordered_set<OperandInfo> empty;
    if (action_to_writes.find(act) == action_to_writes.end())
        return empty;
    return action_to_writes.at(act);
}

const ordered_set<PHV::FieldSlice>&
ActionPhvConstraints::ConstraintTracker::reads(const IR::MAU::Action* act) const {
    static ordered_set<PHV::FieldSlice> empty;
    if (action_to_reads.find(act) == action_to_reads.end())
        return empty;
    return action_to_reads.at(act);
}

ordered_set<const IR::MAU::Action*>
ActionPhvConstraints::ConstraintTracker::read_in(PHV::FieldSlice src) const {
    ordered_set<const IR::MAU::Action*> rv;
    if (read_to_writes_per_action.find(src.field()) == read_to_writes_per_action.end())
        return rv;
    for (auto by_action : read_to_writes_per_action.at(src.field())) {
        for (auto by_range : by_action.second)
            if (by_range.first.contains(src.range()))
                rv.insert(by_action.first); }
    return rv;
}

ordered_set<const IR::MAU::Action*>
ActionPhvConstraints::ConstraintTracker::written_in(PHV::FieldSlice dst) const {
    ordered_set<const IR::MAU::Action*> rv;
    if (!field_writes_to_actions.count(dst.field())) return rv;
    for (auto& kv : field_writes_to_actions.at(dst.field())) {
        if (kv.first.overlaps(dst.range()))
            rv.insert(kv.second.begin(), kv.second.end()); }
    return rv;
}

ordered_set<int> ActionPhvConstraints::ConstraintTracker::source_alignment(
        PHV::AllocSlice dst,
        PHV::FieldSlice src) const {
    ordered_set<int> rv;
    for (auto* act : written_in(dst)) {
        for (auto& opInfo : sources(dst, act)) {
            if (!opInfo.phv_used || *opInfo.phv_used != src)
                continue;
            LOG6("\t\t\t\tSource alignment " << dst << " / ");
            LOG6("\t\t\t\t\t\t" << src);
            LOG6("\t\t\t\t\t\t" << "(opInfo: "
                 << *opInfo.phv_used << ") @ " << dst.container_slice().lo);
            LOG6("\t\t\t\t...induced by action " << act->name);
            rv.insert(dst.container_slice().lo); } }

    return rv;
}

boost::optional<int> ActionPhvConstraints::ConstraintTracker::can_be_both_sources(
        std::vector<PHV::AllocSlice> &slices, ordered_set<PHV::FieldSlice> &packing_slices,
        PHV::FieldSlice src) const {
    ordered_set<const IR::MAU::Action *> two_aligned_actions;
    bitvec alignment;

    int single_alignment_point = -1;
    struct LocalAlignmentInfo {
        bitvec alignment;
        bool has_ad = false;
    };


    ordered_map<const IR::MAU::Action *, LocalAlignmentInfo> act_to_alignment;

    for (auto dst : slices) {
        for (auto* act : written_in(dst)) {
            auto local_alignment = act_to_alignment[act];
            for (auto& opInfo : sources(dst, act)) {
                if (!opInfo.phv_used)
                    local_alignment.has_ad = true;
                else if (*opInfo.phv_used == src)
                    local_alignment.alignment.setbit(dst.container_slice().lo);
            }
            alignment |= local_alignment.alignment;
        }
    }

    for (auto entry : act_to_alignment) {
        auto loc_align = entry.second;
        if (loc_align.alignment.popcount() == 2) {
            if (loc_align.has_ad)
                return boost::none;
            two_aligned_actions.insert(entry.first);
        } else if (loc_align.alignment.popcount() == 1) {
            if (single_alignment_point >= 0 &&
                loc_align.alignment.min().index() != single_alignment_point)
                return boost::none;
            single_alignment_point = loc_align.alignment.min().index();
        }
    }

    for (auto *act : two_aligned_actions) {
        std::map<PHV::FieldSlice, std::vector<le_bitrange>> src_to_dst_bits;
        bitvec written_bits;
        PHV::Container container;
        for (auto dst : slices) {
            for (auto &opInfo : sources(dst, act)) {
                if (!opInfo.phv_used) continue;
                auto it = std::find(packing_slices.begin(), packing_slices.end(), *opInfo.phv_used);
                if (it == packing_slices.end()) continue;
                le_bitrange container_bits = dst.container_slice();
                src_to_dst_bits[*it].push_back(container_bits);
                written_bits.setrange(container_bits.lo, container_bits.size());
            }
            container = dst.container();
            if (dst.field()->is_padding())
                written_bits.setrange(dst.container_slice().lo, dst.width());
        }

        if (written_bits.popcount() != int(container.size()))
            return boost::none;

        for (auto entry : src_to_dst_bits) {
            if (entry.second.size() == 1) {
                continue;
            } else if (entry.second.size() > 2) {
                return boost::none;
            } else {
                // This is an extremely conservative check but will get us past P4C-2350
                if (entry.first != src)
                    return boost::none;
            }
        }
    }
    return single_alignment_point >= 0 ? single_alignment_point : alignment.min().index();
}

void ActionPhvConstraints::ConstraintTracker::print_field_ordering(
        std::vector<PHV::AllocSlice>& slices) const {
    ordered_map<PHV::AllocSlice, size_t> field_slices_to_writes;
    ordered_map<PHV::AllocSlice, size_t> field_slices_to_reads;
    for (auto sl : slices) {
        PHV::FieldSlice slice(sl.field(), sl.field_slice());
        field_slices_to_writes[sl] = written_in(slice).size();
        field_slices_to_reads[sl] = read_in(slice).size(); }

    LOG6("\t\t\t\t\t\t\tField Ordering Map");
    for (auto sl : slices) {
        LOG6("\t\t\t\t\t\t\t" << sl << "\t" << field_slices_to_writes[sl] << "\t" <<
                field_slices_to_reads[sl]); }
}

void ActionPhvConstraints::sort(std::list<const PHV::SuperCluster::SliceList*>& slice_list) {
    auto SliceListComparator = [this](
            const PHV::SuperCluster::SliceList* l,
            const PHV::SuperCluster::SliceList* r) {
        auto l_reads = 0;
        auto l_writes = 0;
        auto r_reads = 0;
        auto r_writes = 0;

        for (auto& sl : *l) {
            l_reads += this->constraint_tracker.read_in(sl).size();
            l_writes += this->constraint_tracker.written_in(sl).size(); }

        for (auto &sl : *r) {
            r_reads += this->constraint_tracker.read_in(sl).size();
            r_writes += this->constraint_tracker.written_in(sl).size(); }

        if (l_writes < r_writes) {
            return true;
        } else if (l_writes > r_writes) {
            return false;
        } else {
            if (l_reads > r_reads) {
                return true;
            } else {
                return false; } } };
    slice_list.sort(SliceListComparator);
    LOG6("Slice list on output");
    for (auto sl : slice_list) {
        LOG6("  " << sl);
    }
}

void ActionPhvConstraints::sort(std::vector<PHV::FieldSlice>& slice_list) {
    std::sort(slice_list.begin(), slice_list.end(),
        [this](PHV::FieldSlice l, PHV::FieldSlice r) {
            auto l_reads = this->constraint_tracker.read_in(l).size();
            auto l_writes = this->constraint_tracker.written_in(l).size();
            auto r_reads = this->constraint_tracker.read_in(r).size();
            auto r_writes = this->constraint_tracker.written_in(r).size();
            if (l_writes != r_writes)
                return l_writes < r_writes;
            return l_reads > r_reads; });
}

void ActionPhvConstraints::determine_same_byte_fields() {
    ordered_map<const PHV::Field*, le_bitrange> header_bytes;
    for (const auto& f : phv) {
        if (f.metadata || f.pov) continue;
        le_bitrange hdr_byte_range = f.byteAlignedRangeInBits();
        LOG7("\t  Range for " << f.name << " : " << hdr_byte_range);
        for (auto kv : header_bytes) {
            if (kv.first->header() != f.header()) continue;
            if (kv.second.overlaps(hdr_byte_range)) {
                LOG6("\t" << kv.first->name << " and " << f.name << " share a byte");
                same_byte_fields[kv.first].insert(&f);
                same_byte_fields[&f].insert(kv.first);
            }
        }
        header_bytes[&f] = hdr_byte_range;
    }
}

const ordered_set<PHV::FieldSlice>
ActionPhvConstraints::get_slices_in_same_byte(const PHV::FieldSlice& slice) const {
    ordered_set<PHV::FieldSlice> rv;
    rv.insert(PHV::FieldSlice(slice.field(), slice.range()));
    if (!same_byte_fields.count(slice.field())) return rv;
    le_bitrange limit = slice.byteAlignedRangeInBits();
    LOG7("    Range for slice " << limit);
    for (const auto* f : same_byte_fields.at(slice.field())) {
        LOG7("    Checking same byte field: " << f->name);
        le_bitrange f_limit = f->byteAlignedRangeInBits();
        if (limit.contains(f_limit)) {
            rv.insert(PHV::FieldSlice(f, StartLen(0, f->size)));
        } else if (limit.overlaps(f_limit)) {
            LOG7("      Field " << f->name << " overlaps with " << slice);
            // XXX(Deep): Need to handle this case.
        }
    }
    return rv;
}

bool ActionPhvConstraints::early_check_ok(const IR::MAU::Action* act) {
    const auto& writes_in_act = constraint_tracker.writes(act);
    ordered_map<PHV::FieldSlice, OperandInfo> slice_to_info;
    for (auto& info : writes_in_act) {
        BUG_CHECK(info.phv_used != boost::none, "Write slice cannot be NULL.");
        slice_to_info[*(info.phv_used)] = info;
    }

    std::stringstream error_msg;
    bool rv = true;
    ordered_set<PHV::FieldSlice> slicesConsidered;
    for (auto& slice : Keys(slice_to_info)) {
        // We have already checked constraints related to @slice if the slice is in slicesConsidered
        // set. Therefore, go to the next slice.
        if (slicesConsidered.count(PHV::FieldSlice(slice.field(), slice.range()))) continue;
        std::stringstream ss;
        const auto slices_in_same_byte = get_slices_in_same_byte(slice);
        if (!valid_container_operation_type(act, slices_in_same_byte, ss)) {
            rv = false;
            error_msg << ss.str();
        }
        slicesConsidered.insert(slices_in_same_byte.begin(), slices_in_same_byte.end());
    }
    if (!rv) ::error("%1%", error_msg.str());
    return rv;
}

int ActionPhvConstraints::min_stage(const IR::MAU::Action* action) const {
    auto tbl = tableActionsMap.getTableForAction(action);
    if (!tbl) BUG("Action %1% not defined as part of a table.", action->name);
    return dg.min_stage(*tbl);
}

ActionPhvConstraints::NumContainers ActionPhvConstraints::num_container_sources(
        const PHV::Allocation &alloc,
        PHV::Allocation::MutuallyLiveSlices container_state,
        const IR::MAU::Action* action,
        ActionPhvConstraints::PackingConstraints& packing_constraints) {
    ordered_set<PHV::Container> containerList;
    ordered_map<PHV::FieldSlice, PHV::FieldSlice> readSlices;
    size_t num_unallocated = 0;
    size_t doubleAllocatedCount = 0;
    size_t doubleUnallocatedCount = 0;
    ordered_map<const PHV::Field*, ordered_set<PHV::FieldSlice>> unallocFieldToSlices;
    int stage = min_stage(action);
    for (auto slice : container_state) {
        auto reads = constraint_tracker.sources(slice, action);
        // No need to include metadata initialization here because metadata initialized always
        // happens with a constant/action data as source.
        if (reads.size() == 0)
            LOG5("\t\t\t\tSlice " << slice << " is not written in action " << action->name);
        for (auto operand : reads) {
            if (operand.ad || operand.constant) {
                LOG6("\t\t\t\t" << operand << " doesn't count as a container source");
                continue; }
            const PHV::Field* fieldRead = operand.phv_used->field();
            le_bitrange rangeRead = operand.phv_used->range();
            bool thisUnallocated = false;
            if (readSlices.count(*(operand.phv_used))) {
                LOG5("\t\t\t\t" << fieldRead->name << " [" << rangeRead.lo << ", " << rangeRead.hi
                     << "] already read earlier for source " << readSlices.at(*(operand.phv_used)));
                thisUnallocated = true;
            } else {
                readSlices[*(operand.phv_used)] = PHV::FieldSlice(slice.field(),
                        slice.field_slice());
            }

            LOG1("\t\t\t\t\tInserting " << fieldRead->name << " [" << rangeRead.lo << ", " <<
                    rangeRead.hi << "] into copacking_constraints for action " << action->name);
            packing_constraints[action].insert(*operand.phv_used);

            ordered_set<PHV::Container> per_source_containers;
            ordered_set<PHV::AllocSlice> per_source_slices =
                alloc.slices(fieldRead, rangeRead, stage, PHV::FieldUse(PHV::FieldUse::READ));
            for (auto source : container_state)
                if (source.field() == fieldRead && source.field_slice().overlaps(rangeRead))
                    per_source_slices.insert(source);

            for (auto source_slice : per_source_slices) {
                per_source_containers.insert(source_slice.container());
                LOG5("\t\t\t\t\tSource slice for " << slice << " : " << source_slice); }
            if (per_source_containers.size() == 0) {
                LOG5("\t\t\t\tSource " << *(operand.phv_used) << " has not been allocated yet.");
                unallocFieldToSlices[fieldRead].insert(*(operand.phv_used));
                if (thisUnallocated) ++doubleUnallocatedCount;
            } else {
                containerList.insert(per_source_containers.begin(), per_source_containers.end());
                if (thisUnallocated) ++doubleAllocatedCount;
            }
        }
    }
    for (auto kv : unallocFieldToSlices) {
        LOG5("\t\t\t\tSource field: " << kv.first->name);
        if (kv.first->no_split()) {
            ++num_unallocated;
            continue;
        }
        for (auto slice : kv.second) {
            LOG5("\t\t\t\t  Unallocated slice: " << slice);
            ++num_unallocated;
        }
    }
    LOG5("\t\t\t\tDouble allocation, allocated: " << doubleAllocatedCount <<
         ", unallocated: " << doubleUnallocatedCount);
    LOG5("\t\t\t\tNumber of allocated sources  : " << containerList.size() + doubleAllocatedCount);
    LOG5("\t\t\t\tNumber of unallocated sources: " << num_unallocated + doubleUnallocatedCount);
    LOG5("\t\t\t\tTotal number of sources      : " << (containerList.size() + num_unallocated +
         doubleAllocatedCount + doubleUnallocatedCount));
    NumContainers rv(containerList.size() + doubleAllocatedCount, num_unallocated +
            doubleUnallocatedCount);
    if (doubleUnallocatedCount)
        rv.double_unallocated = true;
    return rv;
}

boost::optional<PHV::AllocSlice> ActionPhvConstraints::getSourcePHVSlice(
        const PHV::Allocation &alloc,
        const std::vector<PHV::AllocSlice>& slices,
        PHV::AllocSlice& slice,
        const IR::MAU::Action* action) {
    LOG5("\t\t\t\tgetSourcePHVSlices for action: " << action->name << " and slice " << slice);
    int stage = min_stage(action);
    auto *field = slice.field();
    auto reads = constraint_tracker.sources(slice, action);

    if (reads.size() == 0)
        LOG5("\t\t\t\tField " << field->name << " is not written in action " << action->name);
    else
        LOG5("\t\t\t\tField " << field->name << " is written in action "  << action->name <<
             " using " << reads.size() << " operands");

    for (auto operand : reads) {
        if (operand.ad || operand.constant) continue;
        const PHV::Field* fieldRead = operand.phv_used->field();
        le_bitrange rangeRead = operand.phv_used->range();
        ordered_set<PHV::AllocSlice> per_source_slices =
            alloc.slices(fieldRead, rangeRead, stage, PHV::FieldUse(PHV::FieldUse::READ));
        for (auto& packed_slice : per_source_slices) LOG5("\t\t\t\t\tSlice: " << packed_slice);

        // Add any source slices found in @slices, which are the proposed packing.
        for (auto &packed_slice : slices)
            // XXX(cole): Should this be overlaps() or contains()?
            if (packed_slice.field() == fieldRead && packed_slice.field_slice().overlaps(rangeRead))
                per_source_slices.insert(packed_slice);

        LOG5("\t\t\t\t\tSlice read: " << PHV::FieldSlice(fieldRead, rangeRead));
        LOG5("\t\t\t\t\tNumber of source slices: " << per_source_slices.size());

        if (per_source_slices.size() > 1) {
            // Adjacent slices of the same field as the multiple sources ok
            if (!are_adjacent_field_slices(per_source_slices))
                BUG("Multiple source slices found in getSourcePHVSlice() for %1%", fieldRead->name);
        } else if (per_source_slices.size() == 1) {
            return *per_source_slices.begin(); } }

    return boost::optional<PHV::AllocSlice>{};
}

//  Note: If both action data and constant are used in the same action as operands on the same
//  container, action data allocation folds them into one action data parameter to ensure a
//  legal Tofino action. Same is true when multiple action data and/or multiple constants are used
//  as operands on the same container in the same action.
bool ActionPhvConstraints::has_ad_or_constant_sources(
        const PHV::Allocation::MutuallyLiveSlices& slices,
        const IR::MAU::Action* action,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions) const {
    for (auto slice : slices) {
        for (auto operand : constraint_tracker.sources(slice, action)) {
            if (operand.ad || operand.constant) {
                LOG5("\t\t\t\t  Field " << slice.field()->name <<
                     " written using action data/constant in action " << action->name);
                return true; } }
        // If the field is initialized due to metadata initialization in @action, then add
        // constant/action data source for the field.
        if (initActions.count(slice.field()) && initActions.at(slice.field()).count(action)) {
            LOG5("\t\t\t\t  Field " << slice.field()->name << " initialized for live range "
                 "shrinking in action " << action->name);
            return true; }
    }
    return false;
}

ActionPhvConstraints::ActionDataUses ActionPhvConstraints::all_or_none_constant_sources(
        const PHV::Allocation::MutuallyLiveSlices& slices,
        const IR::MAU::Action* action,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions) const {
    ordered_set<PHV::AllocSlice> slices_written_by_ad;
    ordered_set<PHV::AllocSlice> slices_written_by_special_ad;
    ordered_set<PHV::AllocSlice> padding_slices;
    bool has_non_special_slices_written_by_constant_only = true;
    unsigned speciality_type = ActionAnalysis::ActionParam::NO_SPECIAL;
    for (auto slice : slices) {
        for (auto operand : constraint_tracker.sources(slice, action)) {
            if (operand.ad || operand.constant) {
                slices_written_by_ad.insert(slice);
                if (operand.special_ad) {
                    speciality_type |= operand.special_ad;
                    slices_written_by_special_ad.insert(slice);
                } else {
                    has_non_special_slices_written_by_constant_only &= operand.constant;
                }
            }
        }
        if (initActions.count(slice.field()) && initActions.at(slice.field()).count(action))
            slices_written_by_ad.insert(slice);
        bool is_padding = !uses.is_referenced(slice.field()) || slice.field()->padding;
        if (is_padding)
            padding_slices.insert(slice);
    }
    if (LOGGING(5))
        for (auto slice : slices_written_by_special_ad)
            LOG5("\t\t\t\t\t  Special AD slice: " << slice);
    unsigned num_slices_written_by_special_ad = slices_written_by_special_ad.size();
    unsigned num_slices_written_by_ad = slices_written_by_ad.size();
    unsigned num_slices_padding = padding_slices.size();
    LOG5("\t\t\t\t\tSpecial AD slices: " << num_slices_written_by_special_ad <<
         ", AD slices: " << num_slices_written_by_ad << ", Padding slices: " << num_slices_padding);
    BUG_CHECK(num_slices_written_by_special_ad <= num_slices_written_by_ad,
              "Slices written by speciality action data cannot be greater than slices written by "
              "action data");
    if (num_slices_written_by_ad == 0) {
        LOG5("\t\t\t\t  No slice in proposed packing written by action data/constant in action "
             << action->name);
        return ALL_AD_CONSTANT; }

    // If there is a slice written by speciality action data and another slice written by other
    // action data that must always be packed in the same container, then do not return
    // COMPLEX_AD_PACKING_REQ. Instead, allow the failure to happen in table placement later.
    bool check_speciality_packing = true;
    for (auto& sl_ad : slices_written_by_ad) {
        int offset_ad = sl_ad.field()->offset;
        int left_sl_ad = (offset_ad + sl_ad.field_slice().lo) / 8;
        int right_sl_ad = ROUNDUP(offset_ad + sl_ad.field_slice().hi, 8);
        for (auto& sl_special : slices_written_by_special_ad) {
            // Only applicable for header fields as the strict parser alignment requirements are
            // only for headers.
            if (sl_ad.field()->metadata || sl_special.field()->metadata) continue;
            // If the slices are of fields belonging to different headers, then we do not have any
            // pack-together constraints from the parser.
            if (sl_ad.field()->header() != sl_special.field()->header()) continue;
            int offset_special = sl_special.field()->offset;
            int left_sl_special = (offset_special + sl_special.field_slice().lo) / 8;
            int right_sl_special = ROUNDUP(offset_special + sl_special.field_slice().hi, 8);
            LOG6("\t\t\t\t  Slice ad: " << sl_ad << ", offset: " << offset_ad << ", lo: " <<
                    left_sl_ad << ", hi: " << right_sl_ad);
            LOG6("\t\t\t\t  Slice special: " << sl_special << ", offset: " << offset_special <<
                    ", lo: " << left_sl_special << ", hi: " << right_sl_special);
            // If there is an overlap between two different slices (they share the same byte), then
            // the left limit of the later slice is going to be 1 less than the right limit of the
            // earlier slice.
            if (sl_ad != sl_special &&
               (left_sl_special + 1 == right_sl_ad || left_sl_ad + 1 == right_sl_special)) {
                LOG5("\t\t\t\t  Slices " << sl_ad << " and " << sl_special << " must be packed in "
                     "the same container and share a byte.");
                check_speciality_packing = false;
            }
        }
    }

    if (check_speciality_packing && num_slices_written_by_special_ad != 0 &&
            num_slices_written_by_ad != num_slices_written_by_special_ad) {
        // For an action where some slices are written by a HASH_DIST operation and the other slices
        // are all written by constants (not action data), packing is possible.
        if (speciality_type == ActionAnalysis::ActionParam::HASH_DIST &&
                has_non_special_slices_written_by_constant_only) {
            LOG5("\t\t\t\t  Can combine HASH_DIST sources with constant data.");
        } else {
            // We currently disable packing of field slices if there is a mixture of speciality
            // action data and normal action data reads in the same action. This may be relaxed in
            // the future when action data packing becomes more efficient.
            LOG5("\t\t\t\t  This packing will require combining a speciality action data with "
                 "other action data for action " << action->name << ". The compiler currently does "
                 "not support this feature.");
            return COMPLEX_AD_PACKING_REQ; }
    }
    if (num_slices_written_by_ad + num_slices_padding == slices.size()) {
        LOG5("\t\t\t\t  All slices in proposed packing written by action data/constant in action "
             << action->name);
        return ALL_AD_CONSTANT; }
    LOG5("\t\t\t\t  Only " << num_slices_written_by_ad << " out of " << slices.size() << " slices "
         " in proposed packing are written by action data/constant in action " << action->name);
    return SOME_AD_CONSTANT;
}

int ActionPhvConstraints::unallocated_bits(PHV::Allocation::MutuallyLiveSlices slices,
        const PHV::Container c) const {
    int size_used = 0;
    for (auto slice : slices)
        size_used += slice.width();
    if (int(c.size()) < size_used)
        LOG4("Total size of mutually live slices is greater than the size of the container");
    return (c.size() - size_used);
}

bool ActionPhvConstraints::valid_container_operation_type(
        const IR::MAU::Action* action,
        const ordered_set<PHV::FieldSlice>& slices,
        std::stringstream& ss) const {
    unsigned type_of_operation = 0;
    ordered_set<PHV::FieldSlice> fields_not_written;
    ordered_map<cstring, ordered_set<PHV::FieldSlice>> operations_to_fields;
    cstring operation;
    cstring action_name = canon_name(action->externalName());

    cstring hdr = (*(slices.begin())).field()->header();

    ss << "This program violates action constraints imposed by " << Device::name() <<
        "." << std::endl << std::endl;
    ss << "  The following field slices must be allocated in the same container as they are "
          "present within the same byte of header " << hdr << ":" << std::endl;
    for (auto& slice : slices) {
        ss << "\t" << slice.shortString() << std::endl;
        boost::optional<OperandInfo> fw = constraint_tracker.is_written(slice, action);
        bool is_padding = !uses.is_referenced(slice.field()) || slice.field()->padding;
        // Unreferenced fields may be overwritten no issues.
        if (!fw) {
            if (!is_padding)
                fields_not_written.insert(slice);
        } else if (fw->flags & OperandInfo::MOVE) {
            type_of_operation |= OperandInfo::MOVE;
            operations_to_fields["assignment"].insert(slice);
            operation = "assignment";
        } else if (fw->flags & OperandInfo::BITWISE) {
            type_of_operation |= OperandInfo::BITWISE;
            operations_to_fields[fw->operation].insert(slice);
            operation = fw->operation;
        } else if (fw->flags & OperandInfo::WHOLE_CONTAINER) {
            type_of_operation |= OperandInfo::WHOLE_CONTAINER;
            operations_to_fields[fw->operation].insert(slice);
            operation = fw->operation;
        }
    }

    // If there are multiple instruction types for the same container in the same action, then
    // violates action constraints. Therefore, return false.
    if (operations_to_fields.size() > 1) {
        ss << std::endl;
        ss << "  However, the program requires multiple instruction types for the same container "
              "in the same action (" << action_name << "):" << std::endl;
        for (auto kv : operations_to_fields) {
            ss << "\tThe following slice(s) are written using " << kv.first << " instruction." <<
                std::endl;
            for (auto& slice : kv.second)
                ss << "\t  " << slice.shortString() << std::endl;
        }
        ss << std::endl << "Therefore, the program requires an action impossible to synthesize for "
           << Device::name() << " ALU. Rewrite action " << action_name << " to use the same " <<
           "instruction for all the above field slices that must be in the same container."<<
           std::endl;
        return false;
    }

    // If there is a WHOLE_CONTAINER or a BITWISE operation writing to this container, and some
    // slice in the container is not written, then the unwritten slice would be overwritten
    // illegally. Therefore, flag an error message for this, and return false.
    if (((type_of_operation & OperandInfo::WHOLE_CONTAINER) ||
                (type_of_operation & OperandInfo::BITWISE)) && fields_not_written.size() > 0) {
        ss << std::endl;
        ss << "  However, the following fields slice(s) are written in action " << action_name <<
              " by the " << operation << " instruction, which operates on the entire container:" <<
              std::endl;
        for (auto& slice : operations_to_fields.at(operation))
            ss << "\t" << slice.shortString() << std::endl;
        ss << std::endl << "  As a result, the following field slice(s) not written in action " <<
            action_name << " will be overwritten illegally:" << std::endl;
        for (auto& slice : fields_not_written)
            ss << "\t" << slice.shortString() << std::endl;
        ss << std::endl << "Therefore, the program requires an action impossible to synthesize for "
           << Device::name() << " ALU." << std::endl;
        return false;
    }

    return true;
}


unsigned ActionPhvConstraints::container_operation_type(
        const IR::MAU::Action* action,
        const PHV::Allocation::MutuallyLiveSlices& slices,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions) const {
    LOG5("\t\t\tChecking container operation type for action: " << action->name);
    unsigned type_of_operation = 0;
    size_t num_fields_not_written = 0;
    ordered_set<const PHV::Field*> observed_fields;
    cstring operation;

    for (auto slice : slices) {
        auto field_slice = PHV::FieldSlice(slice.field(), slice.field_slice());
        boost::optional<OperandInfo> fw = constraint_tracker.is_written(field_slice, action);
        bool is_padding = !uses.is_referenced(slice.field()) || slice.field()->padding;
        if (!fw) {
            if (initActions.count(slice.field()) && initActions.at(slice.field()).count(action)) {
                // This slice is written by metadata initialization for this action.
                type_of_operation |= OperandInfo::MOVE;
            } else if (!is_padding) {
                num_fields_not_written++;
            }
        } else if (fw->flags & OperandInfo::MOVE) {
            type_of_operation |= OperandInfo::MOVE;
        } else if (fw->flags & OperandInfo::BITWISE) {
            type_of_operation |= OperandInfo::BITWISE;
            if (operation == cstring()) {
                LOG5("\t\t\t\t  First bitwise operation found: " << fw->operation);
                operation = fw->operation;
            } else if (operation == fw->operation) {
                LOG5("\t\t\t\t  Subsequent bitwise operation found: " << fw->operation);
            } else {
                LOG5("\t\t\t\t  Action " << action->name << " uses multiple different bitwise "
                        "operations for slices in the proposed packing.");
                return OperandInfo::MIXED;
            }
        } else if (fw->flags & OperandInfo::WHOLE_CONTAINER) {
            type_of_operation |= OperandInfo::WHOLE_CONTAINER;
            // Check if it a whole container operation on adjacent slices of the same field
            observed_fields.insert(slice.field());
        } else {
            ::warning("Detected a write that is neither move nor whole container "
                    "operation.");
        }
    }

    // If there is a WHOLE_CONTAINER operation present, check if the slices written by the whole
    // container operations belong to the same field. If yes, then return
    // OperandInfo::WHOLE_CONTAINER_SAME_FIELD. If not, then return
    // OperandInfo::WHOLE_CONTAINER, which means that the proposed packing is not valid.
    // For debugging purposes, we distinguish cases where we have a mixture between bitwise/move
    // and whole container operations. Additionally, if a whole container operation is detected
    // in the action and we find that there is a slice not written in the same action
    // (num_fields_not_written > 0), then the proposed packing is not valid, which is indicated
    // by returning OperandInfo::MIXED (mix of not written and whole container write).
    if (type_of_operation & OperandInfo::WHOLE_CONTAINER) {
        if (num_fields_not_written) {
            LOG5("\t\t\t\tAction " << action->name << " uses a whole container operation but "
                    << num_fields_not_written << " slices are not written in this action.");
            return OperandInfo::MIXED; }

        if (type_of_operation & OperandInfo::MOVE) {
            LOG5("\t\t\t\tAction " << action->name << " uses both whole container and move "
                    "operations for slices in the proposed packing.");
            return OperandInfo::MIXED; }

        LOG5("\t\t\t\tNumber of fields written to by this whole container operation: " <<
                observed_fields.size());
        if (observed_fields.size() == 1)
            return OperandInfo::WHOLE_CONTAINER_SAME_FIELD;

        return OperandInfo::WHOLE_CONTAINER; }

    // For BITWISE operations, we have already checked above that the bitwise operation used per
    // action is the same for all slices in the proposed packing. We also must make sure that no
    // field slice in the proposed packing is unwritten when the bitwise operation is used.
    // Finally, for debug purposes, we explicitly flag cases where there is a mixture of MOVE
    // and BITWISE operations.
    if (type_of_operation & OperandInfo::BITWISE) {
        if (num_fields_not_written) {
            LOG5("\t\t\t\tAction " << action->name << " uses a bitwise operation but " <<
                    num_fields_not_written << " slices are not written in this action.");
            return OperandInfo::MIXED; }
        if (type_of_operation & OperandInfo::MOVE) {
            LOG5("\t\t\t\tAction " << action->name << " uses both bitwise and move operations "
                    "for slices in the proposed packing.");
            return OperandInfo::MIXED; }
        return OperandInfo::BITWISE; }

    return OperandInfo::MOVE;
}

bool ActionPhvConstraints::are_adjacent_field_slices(
        const PHV::Allocation::MutuallyLiveSlices& container_state) const {
    le_bitrange last;
    bool firstSlice = true;
    const PHV::Field* field = nullptr;
    for (auto slice : container_state) {
        bool is_padding = !uses.is_referenced(slice.field()) || slice.field()->padding;
        if (is_padding) continue;
        auto range = slice.field_slice();
        if (firstSlice) {
            last = range;
            firstSlice = false;
            field = slice.field();
        } else {
            if (field != slice.field()) return false;
            if (last.hi + 1 != range.lo) {
                LOG5("\t\t\t\t\tSlices [" << last.lo << ", " << last.hi << "] and [" << range.lo <<
                        ", " << range.hi << "] of field " << field->name << " are not adjacent.");
                return false; }
            last = range; } }
    return true;
}

unsigned ActionPhvConstraints::count_container_holes(const PHV::Allocation::MutuallyLiveSlices&
        container_state) const {
    le_bitrange last;
    bool firstSlice = true;
    cstring lastField;
    unsigned numBreaks = 0;
    for (auto slice : container_state) {
        le_bitrange range = slice.container_slice();
        // No checks for the first slice
        if (firstSlice) {
            lastField = slice.field()->name;
            last = range;
            firstSlice = false;
            continue; }
        if (last.hi + 1 != range.lo) {
            LOG7("\t\t\t\t\tSlices [" << last.lo << ", " << last.hi << "] of field " <<
                    lastField << " and [" << range.lo << ", " << range.hi << "] of field " <<
                    slice.field() << " are not adjacent.");
            numBreaks += 1; }
        last = range;
        lastField = slice.field()->name; }
    return numBreaks;
}

bool ActionPhvConstraints::pack_slices_together(
        const PHV::Allocation &alloc,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        ActionPhvConstraints::PackingConstraints& packing_constraints,
        const IR::MAU::Action* action,
        bool pack_unallocated_only,  /*If true, only unallocated slices will be packed together*/
        bool ad_source_present /* action data/constant source present */) {
    const PHV::Field* no_pack_source_field = nullptr;
    if (pack_unallocated_only)
        LOG5("\t\t\t\t\tPack all unallocated slices together. All bits in container are occupied.");
    else
        LOG5("\t\t\t\t\tPack all slices together.");
    int stage = min_stage(action);
    ordered_set<PHV::FieldSlice> pack_together;
    ordered_set<PHV::FieldSlice> pack_together_no_pack;
    ordered_set<const PHV::Field*> pack_together_fields;
    bool pack_together_has_no_pack = false;
    for (auto slice : container_state) {
        for (auto operand : constraint_tracker.sources(slice, action)) {
            if (operand.ad || operand.constant)
                continue;
            const PHV::Field* fieldRead = operand.phv_used->field();
            le_bitrange rangeRead = operand.phv_used->range();
            if (pack_unallocated_only) {
                ordered_set<PHV::Container> containers;
                ordered_set<PHV::AllocSlice> per_source_slices =
                    alloc.slices(fieldRead, rangeRead, stage, PHV::FieldUse(PHV::FieldUse::READ));

                // Add any source slices found in @slices, which are the proposed packing.
                for (auto &packed_slice : container_state)
                    // XXX(cole): Should this be overlaps() or contains()?
                    if (packed_slice.field() == fieldRead &&
                            packed_slice.field_slice().overlaps(rangeRead))
                        per_source_slices.insert(packed_slice);

                for (auto slice : per_source_slices)
                    containers.insert(slice.container());
                if (containers.size() != 0)
                    continue; }

            // Insert the slices to be packed together into the UnionFind structure
            LOG1("\t\t\t\t\tInserting " << fieldRead->name << " [" << rangeRead.lo << ", " <<
                    rangeRead.hi << "] into copacking_constraints for action " << action->name);
            if (fieldRead->is_solitary() &&
               (no_pack_source_field == nullptr || fieldRead == no_pack_source_field)) {
                // If the source is no-pack and there is no other no-pack field encountered, then
                // add this to the no-pack slice list. Also do the same if this slice belongs to the
                // already noted no-pack field.
                no_pack_source_field = fieldRead;
                LOG6("\t\t\t\t\tFound a no-pack field, so we need a second source");
                pack_together_no_pack.insert(PHV::FieldSlice(fieldRead, rangeRead));
            } else {
                // Note if we have a second no-pack source.
                if (fieldRead->is_solitary()) {
                    pack_together_fields.insert(fieldRead);
                    pack_together_has_no_pack = true;
                }
                LOG1("pack together " << fieldRead);
                pack_together.insert(PHV::FieldSlice(fieldRead, rangeRead));
            }
        }
    }

    // The first no-pack source always goes by itself in the pack_together_no_pack set. If
    // pack_together_has_no_pack is set, then it means we have at least a second no-pack source. If
    // there are more than two no-pack sources or if another field without no-pack is also required
    // to have a conditional constraint, then pack_together_fields will have more than one member.
    // However, if there is a second no-pack source, pack_together_fields cannot have more than one
    // member either. Therefore, throw an error.
    if (pack_together_has_no_pack && pack_together_fields.size() > 1) {
        LOG5("\t\t\t\t  Conditional constraints require use of more than two PHV containers.");
        return false;
    }

    // If there are multiple containers required for the conditional constraints--indicated by both
    // pack_together and pack_together_no_pack sets having members present, and the allocation also
    // has an action data/constant source, then this allocation is invalid.
    if (ad_source_present && pack_together.size() > 0 && pack_together_no_pack.size() > 0) {
        LOG5("\t\t\t\t  Conditional constraints require use of two PHV containers as sources. "
             "However, this is impossible because one of the two allowed sources is action "
             "data/constant.");
        return false;
    }

    if (LOGGING(5)) {
        std::stringstream ss;
        for (auto slice : pack_together)
            ss << slice;
        LOG5("\t\t\t\t\tPack together: " << ss.str()); }

    PHV::FieldSlice *firstSlice = nullptr;
    // Pack all the non no-pack slices together.
    for (auto slice : pack_together) {
        if (firstSlice == nullptr) {
            LOG5("\t\t\t\t\t\tSetting first slice to  " << slice);
            firstSlice = new PHV::FieldSlice(slice.field(), slice.range()); }
        LOG5("\t\t\t\t\tUnion " << *firstSlice << " with " << slice);
        packing_constraints[action].makeUnion(*firstSlice, slice); }
    // Pack the no-pack slices together in the second source.
    firstSlice = nullptr;
    for (auto slice : pack_together_no_pack) {
        if (firstSlice == nullptr) {
            LOG5("\t\t\t\t\t\tSetting first slice to " << slice);
            firstSlice = new PHV::FieldSlice(slice.field(), slice.range()); }
        LOG5("\t\t\t\t\tUnion " << *firstSlice << " with " << slice);
        packing_constraints[action].makeUnion(*firstSlice, slice); }
    return true;
}

// At this point, any packing is valid, having passed the can_pack() method. Also, if fields are
// mutually exclusive, they are written by different actions and in different tables, so the writes
// to those mutually exclusive fields should not have an effect on the number of bitmasked-set
// instructions detected.
int ActionPhvConstraints::count_bitmasked_set_instructions(
        const std::vector<PHV::AllocSlice>& slices,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions) const {
    int numBitmaskedSet = 0;
    if (slices.size() == 0) return 0;
    // Create a set out of the vector of slices, because has_ad_or_constant_sources() only takes the
    // set.
    ordered_set<PHV::AllocSlice> setOfSlices;
    for (auto& slice : slices)
        setOfSlices.insert(slice);

    // Merge actions for all candidate fields into a set.
    ordered_set<const IR::MAU::Action*> allActionsForSlices;
    for (auto& slice : slices) {
        const auto& writingActions = constraint_tracker.written_in(slice);
        allActionsForSlices.insert(writingActions.begin(), writingActions.end());
        if (initActions.count(slice.field()))
            allActionsForSlices.insert(initActions.at(slice.field()).begin(),
                    initActions.at(slice.field()).end());
    }
    // For every action, check if bitmasked-set would be synthesized for the writes to slices.
    for (auto& action : allActionsForSlices) {
        bool has_ad_constant_sources = has_ad_or_constant_sources(setOfSlices, action, initActions);
        // Bitmasked-set instructions require an action data source.
        if (!has_ad_constant_sources)
            continue;
        // Determine the set of fields in the packing (slices) that are not written by action.
        ordered_set<PHV::AllocSlice> fieldsNotWrittenTo;
        for (auto slice : slices) {
            if (!constraint_tracker.is_written(slice, action) &&
                !(initActions.count(slice.field()) && initActions.at(slice.field()).count(action)))
                fieldsNotWrittenTo.insert(slice);
        }
        if (is_bitmasked_set(slices, fieldsNotWrittenTo))
            numBitmaskedSet++;
    }
    return numBitmaskedSet;
}

bool ActionPhvConstraints::is_bitmasked_set(
        const std::vector<PHV::AllocSlice>& container_state,
        const ordered_set<PHV::AllocSlice>& fields_not_written_to) const {
    bitvec written;
    for (auto& slice : container_state) {
        if (fields_not_written_to.count(slice))
            continue;
        auto container_range = slice.container_slice();
        bitvec writtenThisSlice(container_range.lo, container_range.size());
        written |= writtenThisSlice;
    }
    // Contiguity is enough because we don't currently support making action data rotationally
    // equivalent. If the bits written are contiguous, then this instruction is going to be realized
    // using deposit-field rather than bitmasked-set.
    if (written.is_contiguous())
        return false;
    return true;
}

bool ActionPhvConstraints::pack_conflicts_present(
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const std::vector<PHV::AllocSlice>& slices,
        const PHV::SuperCluster& sc) const {
    // Check that none of the new slices have pack conflicts with the already allocated slices
    // (container_state).
    for (auto sl1 : container_state) {
        for (auto sl2 : slices) {
            if (sl1.field() == sl2.field()) continue;
            if (hasPackConflict(sl1.field(), sl2.field())) {
                LOG5("\t\t\t" << sl1.field()->name << " cannot be packed in the same stage with " <<
                     sl2.field()->name);
                return true; } } }
    // If the supercluster is not sliceable, this is all we check.
    if (!sc.isSliceable()) return false;

    // If the supercluster is further sliceable, we also check the pack conflicts between slices
    // within the candidate set.
    for (auto sl1 : slices) {
        for (auto sl2 : slices) {
            if (sl1.field() == sl2.field()) continue;
            if (hasPackConflict(sl1.field(), sl2.field())) {
                LOG5("\t\t\tAllocation candidate " << sl1.field()->name << " cannot be packed in "
                     "the same stage with " << sl2.field()->name);
                return true; } } }
    return false;
}

bool ActionPhvConstraints::stateful_destinations_constraints_violated(
        const PHV::Allocation::MutuallyLiveSlices& container_state) const {
    BUG_CHECK(container_state.size() > 0, "No slices in candidate container allocation?");
    size_t size = static_cast<size_t>(container_state.begin()->container().size());
    LOG6("\t\t\tContainer size: " << size);
    const auto& statefulWrites = constraint_tracker.getStatefulWrites();
    for (auto slice : container_state) {
        if (!statefulWrites.count(slice.field())) continue;
        for (auto kv : statefulWrites.at(slice.field())) {
            LOG6("\t\t\tChecking range " << kv.first);
            auto written_field_slice = slice.field_slice();
            if (!kv.first.contains(written_field_slice)) continue;
            for (auto limit : kv.second) {
                auto read_range = limit.second;
                auto write_range = limit.first;
                if (write_range.first != written_field_slice.lo || write_range.second !=
                        written_field_slice.hi)
                    LOG6("\t\t\t  Range " << written_field_slice << " contained in [" <<
                         write_range.first << ", " << write_range.second << "] but not the same as "
                         "it.");
                // Because of the way slicing is done, write_range will always be a superset of
                // written_field_slice. Therefore, written_field_slice's lo will always be greater
                // than or equal to write_range's left coordinate (lo) and written_field_slice's hi
                // will always be lesser than or equal to write_range's right coordinate (hi).
                LOG7("\t\t\t\tlo: " << read_range.first << ", hi: " << read_range.second);
                if (write_range.first != written_field_slice.lo) {
                    read_range.first -= (write_range.first - written_field_slice.lo);
                    LOG7("\t\t\t\tlo factor: " << (written_field_slice.lo - write_range.first));
                }
                if (write_range.second != written_field_slice.hi) {
                    read_range.second -= (write_range.second - written_field_slice.hi);
                    LOG7("\t\t\t\thi factor: " << (written_field_slice.hi - write_range.second));
                }
                LOG7("\t\t\t\tlo: " << read_range.first << ", hi: " << read_range.second);
                if (read_range.first / size == read_range.second / size) continue;
                LOG5("\t\t\tThe alignment of " << slice << " would force the data for ALU operation"
                     "to go to multiple action data bus slots. Therefore, this packing "
                     "is not possible.");
                return true;
            }
        }
    }
    return false;
}

bool ActionPhvConstraints::parser_constant_extract_satisfied(
        const PHV::Container& c,
        const PHV::Allocation::MutuallyLiveSlices& container_state) const {
    if (c.is(PHV::Size::b8)) return true;
    const auto& unionFind = phv.getSameSetConstantExtraction();
    for (auto& slice : container_state) {
        // For each slice, if it is not marked as parser constant extract, do nothing.
        if (!phv.hasParserConstantExtract(slice.field())) continue;
        bitvec range(slice.container_slice().lo, slice.width());
        const auto* sliceSet = unionFind.setOf(const_cast<PHV::Field*>(slice.field()));
        for (auto& slice1 : container_state) {
            if (slice == slice1) continue;
            // If these are different slices of the same field, then don't do anything.
            if (slice.field() == slice1.field()) continue;
            // if the other slice is not marked parser constant extract, then we don't need to do
            // anything.
            if (!phv.hasParserConstantExtract(slice1.field())) continue;
            // If the field is not in the same set as the parser constant extract field, then we are
            // good.
            if (sliceSet->find(const_cast<PHV::Field*>(slice1.field())) == sliceSet->end())
                continue;
            // Both slice and slice1's fields are in the same set. Now we need to make sure they can
            // be allocated into the same container.
            range |= bitvec(slice1.container_slice().lo, slice1.width());
            size_t count = 0;
            bool firstOneFound = false;
            size_t prevBit = 0;
            for (auto b : range) {
                if (!firstOneFound) {
                    // First bit. Just set prevBit and exit.
                    ++count;
                    prevBit = b;
                    firstOneFound = true;
                    continue;
                }
                // Later bit. Increase count by the difference between prevBit and the currentBit.
                count += (b - prevBit);
                // Set prevBit to current bit.
                prevBit = b;
            }
            // Need to pack within 4 consecutive bits for 16b fields and within 3 consecutive bits
            // for 32b fields.
            size_t maxAllowed = c.is(PHV::Size::b16) ? 4 : 3;
            if (count <= maxAllowed) continue;
            LOG5("\t\t\tIn container " << c << ", POV slices " << slice << " and " << slice1 <<
                 " are packed " << count << " (maxAllowed: " << maxAllowed << "b) bits apart." <<
                 " Disallowing this packing to save parser extractors.");
            return false;
        }
    }
    return true;
}

bool ActionPhvConstraints::check_and_generate_constraints_for_move_with_unallocated_sources(
        const PHV::Allocation& alloc,
        const IR::MAU::Action* action,
        const PHV::Container& c,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const NumContainers& sources,
        bool has_ad_constant_sources,
        ordered_map<const IR::MAU::Action*, bool>& phvMustBeAligned,
        ordered_map<const IR::MAU::Action*, size_t>& numSourceContainers,
        ActionPhvConstraints::PackingConstraints& copacking_constraints,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions) {
    // Special packing constraints are introduced when number of source containers > 2 and
    // number of allocated containers is less than or equal to 2.
    // At this point of the loop, sources.num_allocated <= 2, sources.num_unallocated may be any
    // value.
    bool mocha_or_dark = c.is(PHV::Kind::dark) || c.is(PHV::Kind::mocha);
    size_t num_source_containers = sources.num_allocated + sources.num_unallocated;
    PHV::Allocation::MutuallyLiveSlices state_written_to;
    PHV::Allocation::MutuallyLiveSlices state_not_written_to;
    for (auto slice : container_state) {
        bool is_padding = slice.field()->padding || !uses.is_referenced(slice.field());
        if (constraint_tracker.is_written(slice, action))
            // If written by normal instruction.
            state_written_to.insert(slice);
        else if (initActions.count(slice.field()) && initActions.at(slice.field()).count(action))
            // If written by metadata initialization.
            state_written_to.insert(slice);
        else if (!is_padding)
            state_not_written_to.insert(slice);
    }
    size_t num_fields_not_written_to = state_not_written_to.size();
    bool has_bits_not_written_to = num_fields_not_written_to > 0;

    if (has_ad_constant_sources) {
        // At this point, at least one PHV container is present, so we have both action
        // data/constant source as well as a PHV source.
        // Therefore, no fields can be unwritten in any given action.
        if (num_fields_not_written_to) {
            LOG5("\t\t\t\tSome bits not written in action " << action->name << " will get "
                    "clobbered because there is at least one PHV source and another action"
                    " data/ constant source");
            return false; }
        // Any unallocated PHV slices must all be packed within the same container, as there can
        // only be a maximum of one PHV source when an action data/constant source is present.
        // Generate these conditional constraints for this particular case.
        if (sources.num_unallocated > 0) {
            if (!masks_valid(container_state, action, true /*action data only*/, initActions)) {
                LOG5("\t\t\t\tThe action data used for this packing is not contiguous");
                return false; }
            if (!pack_slices_together(alloc, container_state, copacking_constraints, action,
                        false /* pack both allocated and unallocated together */,
                        true /* action data source present */))
                return false;
        }
        // At this point, analysis determines there is at least 1 PHV source. So
        // phvMustBeAligned for this action is true.
        LOG6("\t\t\t\t\tSetting phvMustBeAligned for action " << action->name << " to TRUE");
        phvMustBeAligned[action] = true;
    } else {
        if (num_source_containers == 1) {
            // If both the fields not written to and the fields written to are not contiguous, then
            // there are too many holes in the deposit field operation and so, this packing is not
            // valid. Therefore, always check masks if the number of source containers is 1, and
            // there are fields not written to in this candidate packing. Note that if one of the
            // field sets is contiguous, then a valid deposit-field is possible.
            static PHV::Allocation::LiveRangeShrinkingMap emptyInit;
            if (has_bits_not_written_to) {
                // If the source container is not aligned with the container state being written,
                // then the written container state must be src1, as it would be shifted into the
                // right bit position within the container. This requires the written container
                // state to be contiguous as the mask is expressed as a contiguous [lo, hi] value
                // for the deposit-field. Therefore, for the unaligned case, we should only check
                // the mask validity for the container state written to.
                bool sourceContainerAlignedWithDest = is_aligned(state_written_to, action, alloc);
                bool writtenMaskValid = masks_valid(state_written_to, action,
                        false /* non action data only */, emptyInit);
                if (sourceContainerAlignedWithDest) {
                    if (!writtenMaskValid && !masks_valid(state_not_written_to, action,
                                false /*non action data only*/, emptyInit)) {
                        LOG5("\t\t\t\tMasks found to not be valid for packing");
                        return false;
                    }
                } else if (!writtenMaskValid) {
                    LOG5("\t\t\t\tSource container and destination container are not aligned. "
                         "Therefore, we require a contiguous mask for the container state written. "
                         "However, mask found to not be contiguous.");
                    return false;
                }
            }
            // If the allocation is to a mocha or dark container, and there is an unallocated
            // source, we need to make sure the source and the destination are aligned.
            if (mocha_or_dark && sources.num_unallocated > 0) {
                LOG5("\t\t\t\tSetting phv must be aligned for mocha/dark destination and "
                     "unallocated source");
                phvMustBeAligned[action] = true;
            }
            // No Action data or constant sources and only 1 PHV container as source plus masks for
            // deposit-field found to be valid. So, the packing is valid without any other induced
            // constraints.
            return true; } }
    bool requires_two_containers = sources.num_allocated == 2 ||
        (sources.double_unallocated && sources.num_unallocated == 2);

    // If some field is not written to, then one of the sources for the move has to be the
    // container itself.
    // If this requires two containers, this packing is not possible (TOO_MANY_SOURCES)
    if (num_fields_not_written_to && requires_two_containers) {
        LOG5("\t\t\t\t" << num_fields_not_written_to << " fields not written in action "
                << action->name << " will get clobbered.");
        return false; }

    // If some bits in the container are not written to, then one of the sources of the move has
    // to be the container itself.
    // If requires two containers, this packing is not possible (TOO_MANY_SOURCES)
    if (has_bits_not_written_to && requires_two_containers) {
        LOG5("\t\t\t\tSome unallocated bits in the container will get clobbered by writes in "
                "action" << action->name);
        return false; }

    // One of the PHV must be aligned for the case with 2 sources
    LOG6("\t\t\t\t\tSetting phvMustBeAligned for action " << action->name << " to TRUE");
    phvMustBeAligned[action] = true;

    // If sources.num_allocated == 2 and sources.num_unallocated == 0, then packing is valid and
    // no other packing constraints are induced
    if (sources.num_allocated == 2 && sources.num_unallocated == 0)
        return true;

    // If sources.num_allocated == 2 and sources.num_unallocated > 0, then all unallocated
    // fields have to be packed together with one of the allocated fields
    // XXX(deep): What's the best way to choose which allocated slice to pack with
    if (sources.num_allocated == 2 && sources.num_unallocated > 0)
        if (!pack_slices_together(alloc, container_state, copacking_constraints, action, false))
            return false;

    // For mocha and dark containers, partial container sets are impossible.
    if (mocha_or_dark && sources.num_unallocated > 0) {
        BUG_CHECK(sources.num_allocated <= 1, "Cannot have 2 or more sources for container %1%",
                c);
        // Pack all slices together.
        if (!pack_slices_together(alloc, container_state, copacking_constraints, action, false))
            return false;
    }

    // If sources.num_allocated == 1 and sources.num_unallocated > 0, then
    if (sources.num_allocated <= 1 && sources.num_unallocated > 0) {
        if (num_fields_not_written_to || has_bits_not_written_to) {
            // Pack all slices together (both allocated and unallocated)
            // Can only have src2 as src1 is always the destination container itself
            if (!pack_slices_together(alloc, container_state, copacking_constraints, action, false))
                return false;
            LOG6("\t\t\t\t\tMust pack unallocated fields with allocated fields."
                    " Setting source containers to 1.");
            if (!masks_valid(container_state, action)) {
                LOG5("\t\t\t\tCannot synthesize deposit-field instruction.");
                return false;
            }
            numSourceContainers[action] = 1;
        } else {
            // For this case, sources need not be packed together as we may have (at most) 2
            // source containers
            if (num_source_containers == 2) return true;
            // Only pack unallocated slices together
            if (!pack_slices_together(alloc, container_state, copacking_constraints, action, true))
                return false;
        }
    }
    return true;
}

bool ActionPhvConstraints::generate_conditional_constraints_for_bitwise_op(
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const IR::MAU::Action* action,
        const ordered_set<PHV::FieldSlice>& sources,
        ActionPhvConstraints::PackingConstraints& copacking_constraints)
    const {
    if (sources.size() == 0) return true;
    bool firstSliceProcessed = false;
    bool destSameAsSource = false;
    for (auto& slice : container_state) {
        PHV::FieldSlice sl(slice.field(), slice.field_slice());
        bool sameAsSource = sources.count(sl);
        if (!firstSliceProcessed) {
            destSameAsSource = sameAsSource;
            firstSliceProcessed = true;
        } else {
            if (sameAsSource != destSameAsSource) {
                LOG6("\t\t\t\tCannot generate conditional constraints for bitwise operations.");
                return false; } } }
    if (destSameAsSource) {
        LOG6("\t\t\t\tDo not need to generate conditional constraints for bitwise operations, "
             "as the sources are the same as destination.");
        return true; }
    LOG6("\t\t\t\t\tPrinting source set for bitwise operation");
    for (auto& slice : sources) {
        LOG6("\t\t\t\t\t  " << slice);
        for (auto& slice1 : sources) {
            if (slice == slice1) continue;
            LOG6("\t\t\t\t\t\tInserting " << slice1 << " into copacking_constraints for " <<
                    slice);
            copacking_constraints[action].makeUnion(slice, slice1); } }
    return true;
}

bool ActionPhvConstraints::check_and_generate_constraints_for_bitwise_op_with_unallocated_sources(
        const IR::MAU::Action* action,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const NumContainers& sources,
        PackingConstraints& copacking_constraints)
    const {
    // No unallocated sources, so no need to generate any conditional constraints.
    bool rv = true;
    if (sources.num_unallocated == 0) return rv;
    ordered_set<PHV::FieldSlice> source1;
    ordered_set<PHV::FieldSlice> source2;
    for (auto& slice : container_state) {
        // Get all the sources for a given slice in this action.
        auto sourceSlices = constraint_tracker.sources(slice, action);
        unsigned operandNumber = 0;
        for (auto operand : sourceSlices) {
            // Depending on whether this is the first set or the second set, choose the appropriate
            // set.
            ordered_set<PHV::FieldSlice>* copacking_set = (operandNumber == 0) ? &source1 :
                &source2;
            ++operandNumber;
            if (operand.ad || operand.constant) continue;
            const PHV::Field* fieldRead = operand.phv_used->field();
            le_bitrange rangeRead = operand.phv_used->range();
            copacking_set->insert(PHV::FieldSlice(fieldRead, rangeRead));
        }
    }
    rv &= generate_conditional_constraints_for_bitwise_op(container_state, action, source1,
            copacking_constraints);
    rv &= generate_conditional_constraints_for_bitwise_op(container_state, action, source2,
            copacking_constraints);
    return rv;
}

CanPackReturnType ActionPhvConstraints::can_pack(
        const PHV::Allocation& alloc,
        std::vector<PHV::AllocSlice>& slices,
        PHV::Allocation::MutuallyLiveSlices& original_container_state,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions,
        const PHV::SuperCluster& sc) {
    PHV::Allocation::ConditionalConstraints rv;
    // Allocating zero slices always succeeds...
    if (slices.size() == 0)
        return std::make_tuple(CanPackErrorCode::SLICE_EMPTY, rv);

    ordered_map<const IR::MAU::Action*, unsigned> operationType;
    ordered_map<const IR::MAU::Action*, bool> usesActionDataConstant;
    ordered_map<const IR::MAU::Action*, bool> phvMustBeAligned;
    ordered_map<const IR::MAU::Action*, size_t> numSourceContainers;
    ordered_map<const IR::MAU::Action*, size_t> numUnallocatedContainers;
    PHV::Container c = slices.front().container();

    // Is the container either a mocha or dark container.
    bool mocha_or_dark = c.is(PHV::Kind::dark) || c.is(PHV::Kind::mocha);

    PHV::Allocation::MutuallyLiveSlices container_state;
    LOG4("\t\tOriginal existing container state: ");
    for (auto slice : original_container_state) {
        LOG4("\t\t\t" << slice);
        auto IsDisjoint = [&](const PHV::AllocSlice& sl) {
            return slice.isLiveRangeDisjoint(sl);
        };
        if (std::all_of(slices.begin(), slices.end(), IsDisjoint)) {
            LOG4("\t\t\t  Ignoring original slice because its live range is disjoint with all "
                    "candidate slices.");
        } else {
            container_state.insert(slice);
        }
    }

    LOG4("\t\tChecking whether field slice(s) ");
    for (auto slice : slices)
        LOG4("\t\t\t" << slice.field()->name << " (" << slice.width() << "b)");
    LOG4("\t\tcan be packed into container " << container_state << " already containing " <<
            container_state.size() << " slices");

    if (LOGGING(6))
        constraint_tracker.print_field_ordering(slices);

    // Check if table placement induced any no pack constraints on fields that are candidates for
    // packing. If yes, packing not possible.
    if (pack_conflicts_present(container_state, slices, sc))
        return std::make_tuple(CanPackErrorCode::PACK_CONSTRAINT_PRESENT, boost::none);

    // Create candidate packing
    for (auto slice : slices)
        container_state.insert(slice);

    // Check if any of the fields are stateful ALU writes and check the data bus alignment
    // constraints.
    if (stateful_destinations_constraints_violated(container_state))
        return std::make_tuple(CanPackErrorCode::STATEFUL_DEST_CONSTRAINT, boost::none);

#if 0
    // Check for parser constant extract for non 8b containers.
    if (Device::currentDevice() == Device::TOFINO)
       if (!parser_constant_extract_satisfied(c, container_state))
            return boost::none;
#endif

    // Check if any of the destinations require a speciality read, and therefore, we cannot have a
    // bitmasked-set instruction for this packing.
    auto WriteFromSpeciality = [&](const PHV::AllocSlice& slice) {
        return special_no_pack.count(slice.field());
    };
    if (std::any_of(container_state.begin(), container_state.end(), WriteFromSpeciality)) {
        std::vector<PHV::AllocSlice> existingVector;
        for (auto& sl : container_state) existingVector.push_back(sl);
        if (count_bitmasked_set_instructions(existingVector, initActions) != 0) {
            LOG5("\t\tThis packing requires a bitmasked-set instruction for a slice that reads "
                 "special action data. Therefore, this packing is not possible.");
            return std::make_tuple(CanPackErrorCode::BITMASK_CONSTRAINT, boost::none);
        }
    }

    // Merge actions for all the candidate fields into a set, including initialization actions for
    // any metadata fields overlaid due to live range shrinking.
    ordered_set<const IR::MAU::Action *> set_of_actions;
    for (auto slice : container_state) {
        const auto& writing_actions = constraint_tracker.written_in(slice);
        set_of_actions.insert(writing_actions.begin(), writing_actions.end());
        // Add initialization actions to this set.
        if (initActions.count(slice.field())) {
            for (const auto* a : initActions.at(slice.field())) {
                LOG5("\t\tAdding initialization action " << a->name << " to the set of actions.");
                set_of_actions.insert(a); } } }

    // Debug info: print the names of all actions under consideration for these fields
    if (LOGGING(5)) {
        std::stringstream ss;
        ss << "\t\t\tMust check " << set_of_actions.size() << " actions: ";
        for (auto *act : set_of_actions)
            ss << act->name << " ";
        LOG5(ss.str()); }

    // xxx(Deep): This function checks if any field that gets its value from METER_ALU, HASH_DIST,
    // RANDOM, or METER_COLOR is being packed with other fields written in the same action.
    ordered_set<const PHV::Field*> uniqueFields;
    for (auto& s : container_state)
        uniqueFields.insert(s.field());
    if (!checkSpecialityPacking(uniqueFields))
        return std::make_tuple(CanPackErrorCode::SPECIALTY_DATA, boost::none);

    // Perform analysis related to number of sources for every action. Only MOVE and BITWISE
    // operations get here. Store all the packing constraints induced by this
    // possible packing in this UnionFind structure.

    /* Brief description of how UnionFind is used here:
     * - The UnionFind object contains a set of sets of field slices,
     *   requiring that each field slice in the inner set be packed together.
     *
     * Example,
     *   Metadata m {a, b, c, d, ...}  // Metadata header
     *   Header vlan {                 // VLAN header
     *       bit<3> priority;
     *       bit<1> cfi;
     *       bit<12> tag; }
     *   Also, there are other headers m1 and m2 of type metadata m
     *
     *   Action {
     *       m1.a = m2.a;
     *       priority = m.c;
     *       tag = m.d; }
     *
     * In this case, if container_state is {priority, cfi} and the candidate slice (slice) is tag,
     * then the UnionFind structure will return {{m2.a}, {m.c, m.d}}.
     */
    PackingConstraints copacking_constraints;
    for (const auto* action : set_of_actions) {
        LOG5("\t\t\tNeed to check container sources now for action " << action->name);
        operationType[action] = container_operation_type(action, container_state, initActions);

        if (operationType[action] == OperandInfo::WHOLE_CONTAINER || operationType[action] ==
                OperandInfo::MIXED)
            return std::make_tuple(CanPackErrorCode::MIXED_OPERAND, boost::none);

        if (operationType[action] == OperandInfo::WHOLE_CONTAINER_SAME_FIELD) {
            if (!are_adjacent_field_slices(container_state)) {
                return std::make_tuple(CanPackErrorCode::NONE_ADJACENT_FIELD, boost::none);
            } else {
                LOG5("\t\t\t\tMultiple slices involved in whole container operation are adjacent");
            }
        }

        if (operationType[action] == OperandInfo::BITWISE)
            LOG5("\t\t\t\tDetected bitwise operations");

        // Is there any action data or constant source for the proposed packing in this action?
        bool has_ad_constant_sources = has_ad_or_constant_sources(container_state, action,
                initActions);
        // If there is an action data or constant source, are all slices in the proposed packing
        // written using action data or constant sources.
        auto all_or_none_ad_constant_sources = has_ad_constant_sources ?
            all_or_none_constant_sources(container_state, action, initActions) : NO_AD_CONSTANT;

        // If the action requires combining a speciality action data with a non-speciality action
        // data, we return false because the compiler currently does not support such packing.
        if (all_or_none_ad_constant_sources == COMPLEX_AD_PACKING_REQ)
            return std::make_tuple(CanPackErrorCode::COMPLEX_AD_PACKING, boost::none);

        // If the action involves a bitwise operation for the proposed packing in container c, and
        // only some of the field slices are written using action data or constant sources, then
        // this packing is not valid.
        if (operationType[action] == OperandInfo::BITWISE && !all_or_none_ad_constant_sources)
            return std::make_tuple(CanPackErrorCode::BITWISE_MIXED_AD, boost::none);

        NumContainers sources =
            num_container_sources(alloc, container_state, action, copacking_constraints);
        usesActionDataConstant[action] = has_ad_constant_sources;
        size_t num_source_containers = sources.num_allocated + sources.num_unallocated;
        numSourceContainers[action] = num_source_containers;
        numUnallocatedContainers[action] = sources.num_unallocated;

        // If no PHV containers, then packing is valid
        if (num_source_containers == 0) continue;

        // Dark and mocha containers require the entire container to be written all at once. For
        // dark and mocha containers, ensure that all the field slices in the container are written
        // in every action that writes one of those fields.
        if (mocha_or_dark) {
            // Only one container source for dark/mocha.
            if (sources.num_allocated > 1)
                return std::make_tuple(
                        CanPackErrorCode::TF2_MORE_THAN_ONE_SOURCE, boost::none);
            if (!all_field_slices_written_together(container_state, set_of_actions, initActions))
                return std::make_tuple(
                        CanPackErrorCode::TF2_ALL_WRITTEN_TOGETHER, boost::none);
            phvMustBeAligned[action] = true; }

        // If source fields have already been allocated and number of sources greater than 2, then
        // packing is not possible (TOO_MANY_SOURCES)
        if (sources.num_allocated > 2) {
            LOG5("\t\t\t\tAction " << action->name << " uses more than two PHV sources.");
            return std::make_tuple(CanPackErrorCode::MORE_THAN_TWO_SOURCES, boost::none); }

        // num_source_containers == 2 if execution gets here
        // If source fields have already been allocated and there are two PHV sources in addition to
        // an action data/constant source then packing is not possible (TOO_MANY_SOURCES)
        if (sources.num_allocated == 2 && has_ad_constant_sources) {
            LOG5("\t\t\t\tAction " << action->name << " uses action data/constant in addition to "
                    "two PHV sources");
            return std::make_tuple(CanPackErrorCode::TWO_SOURCES_AND_CONSTANT, boost::none); }

        // Check the validity of packing for move operations, and generate intermediate structures
        // that will be used to create conditional constraints.
        if (operationType[action] == OperandInfo::MOVE) {
            if (!check_and_generate_constraints_for_move_with_unallocated_sources(alloc, action, c,
                    container_state, sources, has_ad_constant_sources, phvMustBeAligned,
                    numSourceContainers, copacking_constraints, initActions))
                return std::make_tuple(CanPackErrorCode::MOVE_AND_UNALLOCATED_SOURCE, boost::none);
        } else if (operationType[action] == OperandInfo::BITWISE) {
            // Check the validity of bitwise operations and generate intermediate structures that
            // will be used to create conditional constraints.
            // At this point, we have already checked (in container_type_operation) that every
            // single slice in the proposed packing has already been written by the same bitwise
            // operation (for this action).
            if (!check_and_generate_constraints_for_bitwise_op_with_unallocated_sources(action,
                    container_state, sources, copacking_constraints))
                return std::make_tuple(CanPackErrorCode::BITWISE_AND_UNALLOCATED_SOURCE,
                        boost::none);
        } else if (operationType[action] != OperandInfo::WHOLE_CONTAINER_SAME_FIELD) {
            BUG("Operation type other than BITWISE and MOVE encountered."); } }

    LOG1("copacking constraint " << copacking_constraints.size());

    LOG5("\t\t\tChecking rotational alignment");
    ordered_map<const IR::MAU::Action*, bool> hasSingleUnallocatedPHVSource;
    ordered_map<const IR::MAU::Action*, bool> hasTwoUnallocatedPHVSources;
    ordered_set<const IR::MAU::Action*> unallocatedSourceRequiresAlignment;
    for (auto &action : set_of_actions) {
        hasSingleUnallocatedPHVSource[action] = false;
        hasTwoUnallocatedPHVSources[action] = false;
        LOG5("\t\t\tphvMustBeAligned: " << phvMustBeAligned[action] <<
             " numSourceContainers: " << numSourceContainers[action] <<
             " action: " << action->name);

        if (phvMustBeAligned[action] && numSourceContainers[action] == 1) {
            // The single phv source must be aligned
            for (auto slice : container_state) {
                LOG5("\t\t\t\tslice: " << slice);
                boost::optional<PHV::AllocSlice> source =
                    getSourcePHVSlice(alloc, slices, slice, action);
                if (!source) {
                    if (numUnallocatedContainers[action] == 1 && mocha_or_dark) {
                        hasSingleUnallocatedPHVSource[action] = true;
                        LOG6("\t\t\t\tFound one unallocated PHV source for mocha/dark destination");
                    }
                    // Detect case where we have an unallocated PHV source and action data/constant
                    // writing to the same container in the same action. For such a case, enforce
                    // alignment constraints for the unallocated PHV source later (guarded using
                    // hasSingleUnallocatedPHVSource variable).
                    if (container_state.size() > 1 && usesActionDataConstant[action] &&
                            numUnallocatedContainers[action] == 1) {
                        hasSingleUnallocatedPHVSource[action] = true;
                        LOG6("\t\t\t\tFound one unallocated PHV source"); }
                    continue; }
                if (slice.container_slice() != source->container_slice()) {
                    LOG1("container slice " << slice << " source " << source);
                    LOG5("\t\t\t\tContainer alignment for slice and source do not match");
                    return std::make_tuple(CanPackErrorCode::SLICE_ALIGNMENT, boost::none); }
            } }

        // TODO(cole): If phvMustBeAligned[action] and one of the fields to be
        // packed is in the UnionFind data structure (i.e. is a source), then
        // fail: It's impossible for a source to be aligned and also packed in
        // the same container as its destination (unless it's the same field).

        if (phvMustBeAligned[action] && numSourceContainers[action] == 2) {
            boost::optional<ClassifiedSources> classifiedSourceSlices =
                verify_two_container_alignment(alloc, container_state, action, c,
                        unallocatedSourceRequiresAlignment);
            if (!classifiedSourceSlices)
                return std::make_tuple(CanPackErrorCode::PACK_AND_ALIGNED, boost::none);
            if (LOGGING(5)) {
                LOG5("\t\t\t\tFirst container source contains " <<
                        classifiedSourceSlices.get()[1].size() << " slice(s)");
                for (auto sl : classifiedSourceSlices.get()[1])
                    LOG5("\t\t\t\t\t" << sl);
                LOG5("\t\t\t\tSecond container source contains " <<
                        classifiedSourceSlices.get()[2].size() << " slice(s)");
                for (auto sl : classifiedSourceSlices.get()[2])
                    LOG5("\t\t\t\t\t" << sl); }
            if (!masks_valid(classifiedSourceSlices.get(), c))
                return std::make_tuple(CanPackErrorCode::INVALID_MASK, boost::none);
            if (numUnallocatedContainers[action] == 2) {
                hasTwoUnallocatedPHVSources[action] = true;
            } else if (numUnallocatedContainers[action] == 1) {
                // Do something else.
                LOG5("\t\t\t\t  Detected one unallocated source.");
                hasSingleUnallocatedPHVSource[action] = true;
            }
        }

        // If there is no alignment restriction on PHV source, we just need to ensure that the
        // different slices in the source PHV must be aligned at the same offset with respect to the
        // destination.
        if (!phvMustBeAligned[action] && numSourceContainers[action] == 1) {
            if (are_adjacent_field_slices(container_state)) {
                // If all fields are adjacent slices of the same field, check if all the sources are
                // adjacent slices of the same field as well
                ordered_set<PHV::AllocSlice> sources;
                for (auto slice : container_state) {
                    boost::optional<PHV::AllocSlice> source =
                        getSourcePHVSlice(alloc, slices, slice, action);
                    if (!source) continue;
                    if (!sources.count(source.get()))
                        sources.insert(source.get()); }
                if (are_adjacent_field_slices(container_state)) {
                    continue; } }

            bool firstSlice = true;
            int firstOffset = 0;
            for (auto slice : container_state) {
                boost::optional<PHV::AllocSlice> source =
                    getSourcePHVSlice(alloc, slices, slice, action);
                if (!source) continue;
                int offset = getOffset(slice.container_slice(), source->container_slice(),
                        slice.container());
                LOG5("\t\t\t\t\tOffset found: " << offset);
                if (firstSlice) {
                    firstOffset = offset;
                    firstSlice = false;
                } else {
                    if (offset!= firstOffset) {
                        LOG5("\t\t\t\tSource slices are at different offsets with respect to "
                                "destination slices");
                        return std::make_tuple(CanPackErrorCode::SLICE_DIFF_OFFSET,
                                boost::none); } } } } }

    // XXX(cole): If there are conditional constraints---i.e. if these slices
    // can only be packed if some unallocated source operands are packed in the
    // right way---then compute a valid bit position for each source operand.
    // Note that this is overly conservative: It requires source operands to be
    // packed together and directly aligned (not rotationally aligned) with
    // their destinations.  This is what glass does, but we should try to relax
    // this constraint in the future.

    if (LOGGING(5) && copacking_constraints.size() > 0) {
        LOG5("Printing copacking constraints");
        for (auto kv : copacking_constraints) {
            LOG5("Action: " << kv.first->name);
            LOG5("\tFields: " << kv.second);
        }
    }

    // Find the copacking constraints.
    ordered_map<int, ordered_set<PHV::FieldSlice>> copacking_set;
    ordered_map<PHV::FieldSlice, PHV::Container> req_container;
    int setIndex = 0;
    for (auto kv : copacking_constraints) {
        LOG5("\t\t\t  Enforcing copacking constraint for action " << kv.first->name);
        for (auto* set : kv.second) {
            // Need to enforce alignment constraints when we have one unallocated PHV source and
            // action data writing to the container in the same action.
            if (set->size() < 2 &&
               (numSourceContainers[kv.first] == 2 || !hasSingleUnallocatedPHVSource[kv.first]))
                continue;
            // If some sources in the same set in copacking_constraints are already allocated, set
            // the container requirement for the unallocated sources in that set.
            if (!assign_containers_to_unallocated_sources(alloc, kv.second, req_container)) {
                LOG5("\t\t\t\tMultiple slices that must go into the same container are allocated "
                        "to different containers");
                return std::make_tuple(CanPackErrorCode::COPACK_UNSATISFIED, boost::none); }
            ordered_set<PHV::FieldSlice> setFieldSlices;
            setFieldSlices.insert(set->begin(), set->end());
            copacking_set[setIndex++] = setFieldSlices;
        }
    }

    // If copacking_constraints has exactly two unallocated PHV source slices, force the smaller
    // slice to be aligned with its destination.
    for (auto kv : copacking_constraints) {
        if (hasTwoUnallocatedPHVSources[kv.first]) {
            LOG5("Detected two unallocated PHV sources for action " << kv.first->name);
            ordered_set<PHV::FieldSlice> field_slices_in_current_container;
            for (auto& sl : container_state) {
                field_slices_in_current_container.insert(PHV::FieldSlice(sl.field(),
                            sl.field_slice()));
                LOG5("\t\t\t\tAdding " << sl << " to field slices in current container");
            }
            boost::optional<PHV::FieldSlice> alignedSlice = get_smaller_source_slice(alloc,
                    kv.second, field_slices_in_current_container);
            if (alignedSlice) {
                bool foundAlignmentConstraint = false;
                for (auto* set : kv.second) {
                    if (set->size() > 1 && set->count(*alignedSlice)) {
                        foundAlignmentConstraint = true;
                        LOG5("\t\t\t\t  Alignment constraint already found on smaller slice: " <<
                             *alignedSlice); }
                }
                if (!foundAlignmentConstraint) {
                    copacking_set[setIndex++] = { *alignedSlice };
                    LOG5("\t\t\t\tEnforcing alignment constraint on smaller slice: " <<
                            *alignedSlice);
                }
            } else {
                LOG5("\t\t\t\tSmaller slice not found");
            }
        } else if (numSourceContainers[kv.first] == 2 && hasSingleUnallocatedPHVSource[kv.first]) {
            LOG5("\t\t\t\tNeed to handle the case here.");
            ordered_set<PHV::FieldSlice> field_slices_in_current_container;
            for (auto& sl : container_state) {
                field_slices_in_current_container.insert(PHV::FieldSlice(sl.field(),
                            sl.field_slice()));
                LOG5("\t\t\t\tAdding " << sl << " to field slices in current container");
            }
            auto unallocatedSlice = get_unallocated_slice(alloc, kv.second,
                    field_slices_in_current_container);
            if (!unallocatedSlice) {
                LOG5("\t\t\t\tUnallocated slice not found");
            } else {
                LOG5("\t\t\t\tUnallocated slice: " << *unallocatedSlice);
                if (unallocatedSourceRequiresAlignment.count(kv.first)) {
                    LOG5("\t\t\t\t  This unallocated slice must be aligned.");
                    copacking_set[setIndex++] = { *unallocatedSlice };
                    LOG5("\t\t\t\tEnforcing alignment constraint on unallocated slice: " <<
                         *unallocatedSlice);
                }
            }
        }
    }

    if (LOGGING(5) && copacking_set.size() > 0) {
        LOG5("\t\t\tPrinting copacking_set");
        for (auto kv : copacking_set) {
            std::stringstream ss;
            ss << "\t\t\t  " << kv.first << " : ";
            for (auto field_slice : kv.second)
                ss << kv.second << " ";
            LOG5(ss.str());
        }
    }

    // Find the right alignment for each slice in the copacking constraints.
    for (auto kv_unallocated : copacking_set) {
        PHV::Allocation::ConditionalConstraint per_unallocated_source;
        // All fields in rv must be placed in the same container.  If there are
        // overlaps based on required alignment, return boost::none.
        ordered_map<const PHV::FieldSlice, le_bitrange> placements;

        for (auto& packing_slice : kv_unallocated.second) {
            ordered_set<int> req_alignment;
            for (auto& slice : slices) {
                auto sources = constraint_tracker.source_alignment(slice, packing_slice);
                req_alignment |= sources; }

            // PROBLEM: the cross product of slices and copacking_set loses which
            // slices correspond to which copacking.

            // Conservatively reject this packing if an operand is required to be aligned at two
            // different positions.
            // XXX(Deep): Possible optimization could be that allocating some other field
            // differently would resolve the multiple requirements for this field's alignment.
            int bitPosition = -1;
            if (req_alignment.size() > 1) {
                auto boost_bitpos
                    = constraint_tracker.can_be_both_sources(slices, kv_unallocated.second,
                                                             packing_slice);
                if (boost_bitpos == boost::none) {
                    LOG5("\t\t\tPacking failed because " << packing_slice <<
                            " would (conservatively) need to be aligned at more than one position: "
                            << cstring::to_cstring(req_alignment));
                    return std::make_tuple(CanPackErrorCode::MULTIPLE_ALIGNMENTS, boost::none); }
                bitPosition = *boost_bitpos;
            } else if (req_alignment.size() == 1) {
                bitPosition = *(req_alignment.begin());
            } else {
                // Alignment requirements could be empty in case the source slices are also
                // unallocated or due to action data/constant writes.
                continue;
            }

            // Check that no other slices are also required to be at this bit
            // position, unless they're mutually exclusive and can be overlaid.
            for (auto& kv : placements) {
                bool isMutex = phv.field_mutex()(
                        kv.first.field()->id,
                        packing_slice.field()->id);
                if (kv.second.overlaps(StartLen(bitPosition, packing_slice.size())) && !isMutex) {
                    LOG5("\t\t\tPacking failed because " << packing_slice << " and " << kv.first <<
                         " slice would (conservatively) need to be aligned at the same position in "
                         "the same container.");
                    return std::make_tuple(CanPackErrorCode::OVERLAPPING_SLICES, boost::none); } }

            // If a slice that is part of the conditional constraints is already allocated, we do
            // not need to actually add the allocated slice to the conditional constraints list.
            // This is because the constraint related to the allocation of the slice to the relevant
            // container is already captured in the container parameter of the unallocated slices
            // within the conditional constraint data.
            if (alloc.slices(packing_slice.field(), packing_slice.range()).size() != 0) {
                LOG5("\t\t\tPacking slice " << packing_slice << " already been allocated.");
                continue;
            }

            placements[packing_slice] = StartLen(bitPosition, packing_slice.size());

            // Set the required bit position.
            if (req_container.count(packing_slice))
                per_unallocated_source[packing_slice] =
                    PHV::Allocation::ConditionalConstraintData(bitPosition,
                            req_container[packing_slice]);
            else
                per_unallocated_source[packing_slice] =
                    PHV::Allocation::ConditionalConstraintData(bitPosition); }

        // Make sure that the same set of conditional constraints have not been generated for any
        // other source.
        bool conditionalConstraintFound = false;
        for (auto kv1 : rv) {
            if (kv1.second.size() != per_unallocated_source.size()) continue;
            bool individualConditionMatch = true;
            for (auto& kv2 : per_unallocated_source) {
                // If slice not found, then this conditional source does not match.
                individualConditionMatch = kv1.second.count(kv2.first) &&
                    (kv1.second.at(kv2.first) == kv2.second);
                if (!individualConditionMatch) break;
            }
            conditionalConstraintFound = individualConditionMatch;
            if (conditionalConstraintFound) break;
        }
        if (!conditionalConstraintFound)
            rv[kv_unallocated.first] = per_unallocated_source;
    }

    return std::make_tuple(CanPackErrorCode::NO_ERROR, rv);
}

bool ActionPhvConstraints::creates_container_conflicts(
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions,
        const MapTablesToActions& tableActionsMap) const {
    if (container_state.size() == 0) return false;
    LOG5("\tPrinting container conflicts candidates");
    for (auto& slice : container_state)
        LOG5("\t  " << slice);
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Table*>> field_to_table_writes;
    for (auto kv : initActions) {
        for (auto* action : kv.second) {
            auto t = tableActionsMap.getTableForAction(action);
            BUG_CHECK(t, "Action %1% does not have a table associated with it.", action->name);
            field_to_table_writes[kv.first].insert(*t);
        }
    }
    for (auto& slice : container_state) {
        auto actions = actions_writing_fields(slice);
        for (const auto* action : actions) {
            auto t = tableActionsMap.getTableForAction(action);
            BUG_CHECK(t, "Action %1% does not have a table associated with it.", action->name);
            field_to_table_writes[slice.field()].insert(*t);
        }
    }

    if (LOGGING(6)) {
        for (auto kv : field_to_table_writes) {
            std::stringstream ss;
            ss << "\t" << kv.first->name << " : ";
            for (const auto* t : kv.second)
                ss << t->name << " ";
            LOG6(ss.str());
        }
    }

    for (auto kv : field_to_table_writes) {
        for (auto kv1 : field_to_table_writes) {
            // If the same field, ignore.
            if (kv.first == kv1.first) continue;
            // If different fields, check their tables.
            for (const auto* t1 : kv.second) {
                for (const auto* t2 : kv1.second) {
                    if (conflicts.writtenInSameStageDifferentTable(t1, t2)) {
                        LOG5("\t\t  Fields " << kv.first->name << " and " << kv1.first->name <<
                             " are written in different tables in the same stage: "
                             << t1->name << " and " << t2->name << std::endl << "\t\t  " <<
                             "This would produce container conflicts.");
                        return true; } } } } }

    return false;
}

boost::optional<PHV::FieldSlice> ActionPhvConstraints::get_unallocated_slice(
        const PHV::Allocation& alloc,
        const UnionFind<PHV::FieldSlice>& copacking_constraints,
        const ordered_set<PHV::FieldSlice>& container_state) {
    // Get unallocated sources, excluding both allocated sources as well as slices that are being
    // packed in the container_State. Since those slices are in the contianer_state, they must be
    // assumed to be allocated already.
    ordered_set<PHV::FieldSlice> unallocatedSlices;
    LOG5("\t\t\t\tGathering unallocated source for this container:");
    for (auto* set : copacking_constraints) {
        for (auto& sl : *set) {
            if (!container_state.count(sl) && alloc.slices(sl.field(), sl.range()).size() == 0) {
                LOG5("\t\t\t\t\tAdding " << sl);
                unallocatedSlices.insert(sl);
            }
        }
    }
    if (unallocatedSlices.size() != 1) {
        LOG5("\t\t\t\tFound more than one unallocated slice despite expecting only one such "
             "slice.");
        return boost::none;
    }
    return (*(unallocatedSlices.begin()));
}

boost::optional<PHV::FieldSlice> ActionPhvConstraints::get_smaller_source_slice(
        const PHV::Allocation& alloc,
        const UnionFind<PHV::FieldSlice>& copacking_constraints,
        const ordered_set<PHV::FieldSlice>& container_state) {
    // Get unallocated sources, excluding both allocated sources as well as slices that
    // are being packed in the container_state. Since those slices are in the container_state, they
    // are assumed to be allocated already.
    ordered_set<PHV::FieldSlice> twoUnallocatedSlices;
    LOG5("\t\t\t\tGathering unallocated sources for this container:");
    for (auto* set : copacking_constraints) {
        for (auto& sl : *set) {
            if (!container_state.count(sl) && alloc.slices(sl.field(), sl.range()).size() == 0) {
                LOG5("\t\t\t\t\tAdding " << sl);
                twoUnallocatedSlices.insert(sl);
            } else {
                LOG5("\t\t\t\t\tIgnoring allocated slice " << sl); } } }

    if (twoUnallocatedSlices.size() > 2) {
        // If we find more than two unallocated slices, return boost::none.
        LOG5("\t\t\t\tFound more than two unallocated slices.");
        return boost::none; }

    auto min = std::min_element(twoUnallocatedSlices.begin(), twoUnallocatedSlices.end(),
            [&](const PHV::FieldSlice& sl1, const PHV::FieldSlice& sl2) {
        return sl1.size() < sl2.size(); });
    if (min == twoUnallocatedSlices.end())
        return boost::none;
    else
        return *min;
}

bool ActionPhvConstraints::masks_valid(ordered_map<size_t, ordered_set<PHV::AllocSlice>>& sources,
        const PHV::Container c) const {
    LOG5("\t\t\tChecking masks valid for container of size: " << c.size());
    unsigned total_holes = count_container_holes(sources[1]) + count_container_holes(sources[2]);
    LOG7("\t\t\t\tNumber of holes found in total: " << total_holes);
    if (total_holes > 1) {
        LOG5("\t\t\t\tInvalid masks found");
        return false; }
    return true;
}

bool ActionPhvConstraints::masks_valid(
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const IR::MAU::Action* action) const {
    bitvec mask;
    int c_size = -1;
    for (auto& slice : container_state) {
        if (c_size == -1) c_size = slice.container().size();
        if (constraint_tracker.is_written(slice, action))
            mask |= bitvec(slice.container_slice().lo, slice.width());
    }
    if (c_size == -1) return true;
    LOG5("\t\t\t\t  Required mask: " << mask);
    if (mask.is_contiguous()) return true;
    bitvec allOnes(0, c_size);
    bitvec complementMask = allOnes - mask;
    LOG5("\t\t\t\t  Complement mask: " << complementMask);
    if (complementMask.is_contiguous()) return true;
    return false;
}

bool ActionPhvConstraints::masks_valid(
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const IR::MAU::Action* action,
        bool actionDataOnly,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions) const {
    bitvec actionDataConstantMask;
    for (auto slice : container_state) {
        if (actionDataOnly && has_ad_or_constant_sources({ slice }, action, initActions)) {
            LOG5("\t\t\t\t  Action data constant mask for " << slice << " : " <<
                    slice.container_slice().lo << ", " << slice.width());
            actionDataConstantMask |= bitvec(slice.container_slice().lo, slice.width());
        }
        if (!actionDataOnly) {
            LOG5("\t\t\t\t  Mask for " << slice << " : " << slice.container_slice().lo
                    << ", " << slice.width());
            actionDataConstantMask |= bitvec(slice.container_slice().lo, slice.width());
        }
    }
    LOG5("\t\t\t\tRequired mask : " << actionDataConstantMask);
    if (actionDataConstantMask.is_contiguous())
        return true;
    return false;
}

bool ActionPhvConstraints::is_aligned(
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const IR::MAU::Action* action,
        const PHV::Allocation& alloc) const {
    int stage = min_stage(action);
    for (auto& slice : container_state) {
        auto reads = constraint_tracker.sources(slice, action);
        BUG_CHECK(reads.size() > 0, "Slice %1% must be written in action %2%", slice, action->name);
        for (auto operand : reads) {
            BUG_CHECK(operand.phv_used->field(), "There must be a field read for slice %1%", slice);
            ordered_set<PHV::AllocSlice> per_source_slices = alloc.slices(operand.phv_used->field(),
                    operand.phv_used->range(), stage, PHV::FieldUse(PHV::FieldUse::READ));
            for (auto source : container_state)
                if (source.field() == operand.phv_used->field() &&
                        source.field_slice().overlaps(operand.phv_used->range()))
                    per_source_slices.insert(source);
            for (auto source_slice : per_source_slices) {
                if (source_slice.container_slice().lo != slice.container_slice().lo)
                    return false;
            }
        }
    }
    return true;
}

inline int ActionPhvConstraints::getOffset(le_bitrange a, le_bitrange b, PHV::Container c) const {
    return ((a.lo - b.lo) % c.size());
}

/** Steps in verifying alignment of the two PHV sources:
 *
 * 1. Divide the source AllocSlices corresponding to the packing in
 * @container_state into the respective containers (firstContainerSet and
 * secondContainerSet). All slices in each respective ContainerSet must be
 * aligned at the same offset with reference to their destination slices.
 * Also, only one container set can be unaligned with the destination for every
 * instruction.
 *
 * 2. If both firstContainerAligned and secondContainerAligned are
 * simultaneously false, then packing is impossible due to alignment
 * constraints on the instructions.
 *
 * 3. If packing is possible, return the classification of source slices into
 * the respective source containers (modeled as a ClassifiedSources map).
 */
boost::optional<ActionPhvConstraints::ClassifiedSources>
ActionPhvConstraints::verify_two_container_alignment(
        const PHV::Allocation& alloc,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const IR::MAU::Action* action,
        const PHV::Container destination,
        ordered_set<const IR::MAU::Action*>& unallocatedSourceRequiresAlignment) {
    ClassifiedSources rm;
    bool firstContainerSet = false;
    bool secondContainerSet = false;
    bool firstContainerAligned = true;
    bool secondContainerAligned = true;
    int firstOffset = 0;
    int secondOffset = 0;
    ordered_map<size_t, PHV::Container> num_to_source_mapping;

    int stage = min_stage(action);
    for (auto slice : container_state) {
        LOG7("\t\t\t\tClassifying source slice for: " << slice);
        for (auto operand : constraint_tracker.sources(slice, action)) {
            if (operand.ad || operand.constant) continue;
            const PHV::Field* fieldRead = operand.phv_used->field();
            le_bitrange rangeRead = operand.phv_used->range();
            ordered_set<PHV::AllocSlice> per_source_slices =
                alloc.slices(fieldRead, rangeRead, stage, PHV::FieldUse(PHV::FieldUse::READ));
            for (auto sourceSlice : container_state) {
                bool rangeOverlaps = sourceSlice.field_slice().overlaps(rangeRead);
                if (sourceSlice.field() == fieldRead && rangeOverlaps)
                    per_source_slices.insert(sourceSlice); }

            // Combine multiple adjacent source slices.
            PHV::AllocSlice* src_slice = nullptr;
            for (auto& slice : per_source_slices) {
                if (src_slice == nullptr) {
                    src_slice = &slice;
                    continue; }

                // XXX(cole): We might be able to handle slices of the same
                // field in different containers in the future.  Needs more
                // thought.
                BUG_CHECK(src_slice->container() == slice.container(),
                          "Source slices of the same field found in different containers");
                BUG_CHECK(src_slice->container_slice().hi + 1 == slice.container_slice().lo,
                          "Non-adjacent container slices of the same field");
                BUG_CHECK(src_slice->field_slice().hi + 1 == slice.field_slice().lo,
                          "Non-adjacent field slices of the same field");
                src_slice = new PHV::AllocSlice(src_slice->field(),
                                            src_slice->container(),
                                            src_slice->field_slice().lo,
                                            src_slice->container_slice().lo,
                                            src_slice->field_slice().size()
                                                + slice.field_slice().size()); }

            // For every source slice, check alignment individually and divide it up as part of
            // either the first source container or the second source container
            if (src_slice == nullptr) {
                LOG5("\t\t\t\t\tNo source slice found");
                continue; }
            auto sl = *src_slice;
            if (!firstContainerSet) {
                // first container encountered
                num_to_source_mapping[1] = sl.container();
                LOG7("\t\t\t\t\tFirst container is : " << sl.container() << " from : " << sl);
                rm[1].insert(sl);
                if (sl.container_slice() != slice.container_slice()) {
                    LOG5("\t\t\t\t\tFirst container not aligned");
                    firstContainerAligned = false;
                    firstOffset = getOffset(sl.container_slice(), slice.container_slice(),
                            slice.container()); }
                firstContainerSet = true;
            } else if (!secondContainerSet) {
                // first container has already been encountered at this point
                if (num_to_source_mapping[1] == sl.container()) {
                    LOG7("\t\t\t\t\tFound first container : " << sl.container() << " in : " <<
                            sl);
                    rm[1].insert(sl);
                    // check if the slice is aligned and whether this is the same as the
                    // previous source slices from this source container
                    bool sliceAligned = (sl.container_slice() == slice.container_slice());
                    if (firstContainerAligned != sliceAligned) {
                        LOG5("\t\t\t\t\tSource slices are both aligned and unaligned");
                        return boost::optional<ClassifiedSources>{}; }
                    // if the slices are all unaligned, check if the offset of the source and
                    // destination slices are uniform across all slices. If not, packing is
                    // invalid (enforced by setting firstContainerAligned to false).
                    if (!firstContainerAligned) {
                        int offset = getOffset(sl.container_slice(), slice.container_slice(),
                                slice.container());
                        if (firstOffset != offset) {
                            LOG5("\t\t\t\t\tSource slices are aligned at different offsets.");
                            return boost::optional<ClassifiedSources>{}; } }
                } else {
                    // at this point, we have encountered the second source container
                    secondContainerSet = true;
                    num_to_source_mapping[2] = sl.container();
                    LOG7("\t\t\t\t\tSecond container is: " << sl.container() << " from : " <<
                            sl);
                    rm[2].insert(sl);
                    // initialize the offset for the first slice in the second source container
                    if (sl.container_slice() != slice.container_slice()) {
                        LOG5("\t\t\t\t\tSecond container not aligned");
                        secondOffset = getOffset(sl.container_slice(), slice.container_slice(),
                                slice.container());
                        secondContainerAligned = false; } }
            } else {
                // two different containers have already been encountered
                bool sliceAligned = (sl.container_slice() == slice.container_slice());
                int refOffset = 0;
                bool containerAligned;
                if (num_to_source_mapping[1] == sl.container()) {
                    LOG7("\t\t\t\t\tFound first container : " << sl.container() << " in : " <<
                            sl);
                    containerAligned = firstContainerAligned;
                    refOffset = firstOffset;
                    rm[1].insert(sl);
                } else if (num_to_source_mapping[2] == sl.container()) {
                    LOG7("\t\t\t\t\tFound second container: " << sl.container() << " in : " <<
                            sl);
                    containerAligned = secondContainerAligned;
                    refOffset = secondOffset;
                    rm[2].insert(sl);
                } else {
                    BUG("Found a third container source"); }

                // If alignment is different for any source slice, either in first or second
                // source container, then packing is invalid.
                if (containerAligned != sliceAligned) {
                    LOG5("\t\t\t\t\tSource slices are both aligned and unaligned.");
                    return boost::optional<ClassifiedSources>{}; }
                // If offset is different for any source slice, either in first or second source
                // container, then packing is invalid.
                int offset = getOffset(sl.container_slice(), slice.container_slice(),
                        slice.container());
                if (refOffset != offset) {
                    LOG5("\t\t\t\t\tSource slices are aligned at different offsets.");
                    return  boost::optional<ClassifiedSources>{}; } } } }

    // If first container is set and unaligned, and the second container is unallocated, then the
    // second container must be aligned, meaning that the unallocated source must be aligned for
    // this action.
    if (firstContainerSet && !firstContainerAligned && !secondContainerSet)
        unallocatedSourceRequiresAlignment.insert(action);

    // If both source containers are unaligned, then packing is invalid.
    if (!firstContainerAligned && !secondContainerAligned) {
        LOG5("\t\t\t\tBoth source containers cannot be unaligned.");
        return boost::optional<ClassifiedSources>{}; }

    // xxx(Deep): Overly restrictive constraint
    // For deposit-field, if the destination container is also a source, it cannot be the rotated
    // source only.
    // The right way to fix this is to ensure that for fields containers with unallocated bits, all
    // unallocated sources have to be packed in the same container as the allocated sources.
    if (!firstContainerAligned && num_to_source_mapping[1] == destination &&
            num_to_source_mapping[2] != destination) {
        LOG5("\t\t\t\tDestination cannot also be rotated source.");
        return boost::optional<ClassifiedSources>{}; }
    if (!secondContainerAligned && num_to_source_mapping[2] == destination &&
            num_to_source_mapping[1] != destination) {
        LOG5("\t\t\t\tDestination cannot also be rotated source.");
        return boost::optional<ClassifiedSources>{}; }

    return rm;
}

bool ActionPhvConstraints::assign_containers_to_unallocated_sources(
        const PHV::Allocation& alloc,
        const UnionFind<PHV::FieldSlice>& copacking_constraints,
        ordered_map<PHV::FieldSlice, PHV::Container>& req_container) {
    // For each set in copacking_constraints, check if any sources are allocated and if yes, all
    // unallocated sources in that set have to have the same container number
    for (auto* set : copacking_constraints) {
        PHV::Container c;
        ordered_set<PHV::FieldSlice> unallocated_slices;
        // Find all allocated slices in each set
        for (auto& slice : *set) {
            ordered_set<PHV::AllocSlice> per_source_slices = alloc.slices(slice.field(),
                    slice.range());
            // If this is an unallocated source slice, then examine the next slice after adding it
            // to the unallocated slices set
            if (per_source_slices.size() == 0) {
                unallocated_slices.insert(slice);
                continue; }
            // For each alloc slice, note the container used. If we encounter two different
            // containers, then packing in a single container is not possible. Return false.
            for (auto sl : per_source_slices) {
                // No container allocated so far
                if (c == PHV::Container()) {
                    LOG6("\t\t\t\t\tSlice " << sl << " already allocated to container " <<
                            sl.container());
                    c = sl.container();
                    continue; }
                if (sl.container() != c) {
                    LOG5("\t\t\t\t\tSlice " << sl << " allocated to container " << sl.container() <<
                         " even though other slice(s) in the copacking set are allocated to " <<
                         "container "  << c);
                    return false; } } }
        // If all slices are unallocated, go to the next set in copacking_constraints
        if (c == PHV::Container()) continue;
        for (auto& slice : unallocated_slices) {
            LOG5("\t\t\t\t\tSlice " << slice << " must be allocated to container " << c);
            req_container[slice] = c; } }

    return true;
}

bool ActionPhvConstraints::all_field_slices_written_together(
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const ordered_set<const IR::MAU::Action*>& set_of_actions,
        const PHV::Allocation::LiveRangeShrinkingMap& initActions) const {
    for (auto action : set_of_actions) {
        enum WriteType { NO_INIT, NOT_WRITTEN, WRITTEN } thisActionWrites = NO_INIT;
        // for each AllocSlice in the container, check if it is written by the action.
        for (auto& slice : container_state) {
            boost::optional<OperandInfo> writeStatus = constraint_tracker.is_written(slice, action);
            bool metaInit = false;
            // Metadata initialization done in this action for the field of slice.
            if (initActions.count(slice.field()) && initActions.at(slice.field()).count(action))
                metaInit = true;
            if (!writeStatus && !metaInit) {
                if (thisActionWrites == NO_INIT)
                    // First slice encountered, so set status to field not written.
                    thisActionWrites = NOT_WRITTEN;
                else if (thisActionWrites == WRITTEN)
                    // If a field was written previously, this returns false.
                    return false;
            } else {
                if (thisActionWrites == NO_INIT)
                    // first slice encountered, so set status to field written.
                    thisActionWrites = WRITTEN;
                else if (thisActionWrites == NOT_WRITTEN)
                    // If a field was not written previously, this returns false.
                    return false; } } }
    return true;
}

bool ActionPhvConstraints::checkBridgedPackingConstraints(
        const ordered_set<const PHV::Field*>& packing) const {
    // Mapping from a field to the actions in which the field is written.
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>> actionToWrittenFieldsMap;
    // Represents the list of all actions where the fields in the candidate packing @packing are
    // written.
    ordered_set<const IR::MAU::Action*> allActions;
    for (auto f : packing) {
        auto actions = actions_writing_fields(f);
        const IR::MAU::Action* act = nullptr;
        // The action with the name `act` is used to initialize the bridged metadata header version
        // of the field to the original program version. We do not need to consider the set
        // operations introduced in this compiler-generated action when checking valid packing for
        // the bridged metadata fields. Therefore, we remove this action from the list of actions
        // writing fields.
        for (auto* a : actions)
            if (a->name == "act")
                act = a;
        if (act != nullptr)
            actions.erase(act);
        actionToWrittenFieldsMap[f] = actions;
        allActions.insert(actionToWrittenFieldsMap[f].begin(), actionToWrittenFieldsMap[f].end()); }

    // If there are bits present in a container that won't be written for a given action, we need to
    // make sure that the fields that are written all have either a PHV write or an action data
    // write.
    for (auto* act : allActions) {
        // true if we have encountered a PHV source for one of the fields in the packing.
        boost::optional<bool> foundPHVSource = boost::make_optional(false, false);
        // true if we have encountered an action data/constant source for one of the fields in the
        // packing.
        boost::optional<bool> foundADConstantSource = boost::make_optional(false, false);
        LOG6("\t\t    Action: " << act->name);
        BUG_CHECK(act->name != "act", "Action %1% should have been removed earlier", act->name);
        // For each field in packing:
        for (auto* f : packing) {
            auto hasPHVSource = constraint_tracker.hasPHVSource(f, act);
            auto hasADSource = constraint_tracker.hasActionDataOrConstantSource(f, act);
            LOG6("\t\t\t  Field: " << f->name);
            std::stringstream ss;
            if (hasPHVSource)
                ss << "\t\t\t\tPHV: " << hasPHVSource;
            else
                ss << "\t\t\t\tNo PHV";
            if (hasADSource)
                ss << ", AD/Constant: " << hasADSource;
            else
                ss << ", No AD/Constant.";
            LOG6(ss.str());
            // Mark foundPHVSource as having found the first PHV source.
            if (!foundPHVSource && hasPHVSource) {
                foundPHVSource = *hasPHVSource;
                LOG6("\t\t\t  Setting foundPHVSource to " << foundPHVSource); }

            // Mark foundADConstantSource as having found the first action data/constant source.
            if (!foundADConstantSource && hasADSource) {
                foundADConstantSource = *hasADSource;
                LOG6("\t\t\t  Setting foundADConstantSource to " << foundADConstantSource); }

            // If there was a PHV source, and a field does not have a PHV source, then this packing
            // is not possible. (Underlying principle: Do not mix action data/PHV sources in bridged
            // metadata packing because ensuring a valid deposit-field in those cases becomes very
            // complicated, and such a valid packing is not always possible).
            if (hasPHVSource && foundPHVSource && *hasPHVSource != *foundPHVSource) {
                LOG6("\t\t\t  Returning false");
                return false; }

            // Similarly, if there was an action data/constant source and a field does not have an
            // action data/constant source, then this packing is not possible.
            if (hasADSource && foundADConstantSource && *hasADSource != *foundADConstantSource) {
                LOG6("\t\t\t  Returning false");
                return false; } } }
    return true;
}

bool ActionPhvConstraints::written_in(const PHV::Field* f, const IR::MAU::Action* act) const {
    if (LOGGING(6)) {
        LOG6("\t\t\t\tField " << f->name << " is written by:");
        for (const auto* act : actions_writing_fields(f))
            LOG6("\t\t\t\t  " << act->name);
    }
    return actions_writing_fields(f).count(act);
}

bool ActionPhvConstraints::written_by_ad_constant(
        const PHV::Field* f,
        const IR::MAU::Action* act) const {
    // If field is not written in this action, return false.
    if (!written_in(f, act)) return false;
    PHV::FieldSlice slice(f, StartLen(0, f->size));
    for (auto operand : constraint_tracker.sources(slice, act))
        if (operand.ad || operand.constant)
            return true;
    return false;
}

boost::optional<ActionPhvConstraints::OperandInfo>
ActionPhvConstraints::ConstraintTracker::is_written(
        PHV::FieldSlice slice,
        const IR::MAU::Action *act) const {
    const auto& all_writes = this->writes(act);
    for (auto op : all_writes) {
        if (!op.phv_used)
            continue;
        if (op.phv_used->field() != slice.field())
            continue;
        if (!op.phv_used->range().contains(slice.range()))
            continue;

        ActionPhvConstraints::OperandInfo rv = op;
        rv.phv_used = slice;
        cstring operation = rv.flags & OperandInfo::WHOLE_CONTAINER ? "WHOLE_CONTAINER" :
                            rv.flags & OperandInfo::BITWISE ? "BITWISE" : "MOVE";
        LOG5("\t\t\t\tSlice " << slice << " is written in action " << act->name << " by a " <<
             operation << " operation.");
        return rv; }

    LOG5("\t\t\t\tSlice " << slice << " is not written in action " << act->name);
    return boost::none;
}

bool ActionPhvConstraints::cannot_initialize(
        const PHV::Container& c,
        const IR::MAU::Action* action,
        const PHV::Allocation& alloc) const {
    LOG4("\t\t\tChecking container " << c << " for action " << action->name);
    ordered_map<PHV::FieldSlice, ordered_set<PHV::AllocSlice>> destinationsToBeChecked;
    int stage = min_stage(action);
    for (auto write : constraint_tracker.writes(action)) {
        // For each write in the action, check if the written slice has been allocated yet, and if
        // yes, whether it has been  allocated in container c.
        if (!write.phv_used) BUG("No PHV FieldSlice corresponding to the write");
        const PHV::Field* fieldWritten = write.phv_used->field();
        le_bitrange rangeWritten = write.phv_used->range();
        ordered_set<PHV::AllocSlice> per_destination_slices = alloc.slices(fieldWritten,
                rangeWritten, stage, PHV::FieldUse(PHV::FieldUse::WRITE));
        for (auto dest : per_destination_slices) {
            if (dest.container() != c) continue;
            // This written slice is allocated to the current container.
            PHV::FieldSlice write(dest.field(), dest.field_slice());
            LOG5("\t\t\t  Field slice " << write << " must be checked for PHV/action data/non-zero "
                 "constant sources.");
            for (auto& read : constraint_tracker.sources(write, action)) {
                if (read.ad) return true;
                if (read.phv_used != boost::none) return true;
                if (read.constant && read.const_value != 0) return true;
            }
        }
    }
    return false;
}

ordered_set<const PHV::Field*>
ActionPhvConstraints::actionReads(const IR::MAU::Action* act) const {
    ordered_set<const PHV::Field*> rv;
    for (auto& slice : constraint_tracker.reads(act))
        rv.insert(slice.field());
    return rv;
}

ordered_set<const PHV::Field*>
ActionPhvConstraints::actionWrites(const IR::MAU::Action* act) const {
    ordered_set<const PHV::Field*> rv;
    for (auto fw : constraint_tracker.writes(act)) {
        if (fw.phv_used)
            rv.insert(fw.phv_used->field()); }
    return rv;
}

ordered_set<const PHV::Field*> ActionPhvConstraints::field_sources(const PHV::Field* f) const {
    ordered_set<const PHV::Field*> rv;
    PHV::FieldSlice dest(f, StartLen(0, f->size));
    for (const IR::MAU::Action* act : constraint_tracker.written_in(dest)) {
        auto operands = constraint_tracker.sources(dest, act);
        for (auto it = operands.begin(); it != operands.end(); ++it) {
            if (!(it->phv_used)) continue;
            PHV::FieldSlice sourceFieldSlice = *(it->phv_used);
            rv.insert(sourceFieldSlice.field()); } }
    return rv;
}

ordered_set<const PHV::Field*> ActionPhvConstraints::field_destinations(const PHV::Field* f) const {
    ordered_set<const PHV::Field*> rv;
    PHV::FieldSlice source(f, StartLen(0, f->size));
    for (const IR::MAU::Action* act : constraint_tracker.read_in(source)) {
        auto destinations = constraint_tracker.destinations(source, act);
        for (auto slice : destinations)
            rv.insert(slice.field()); }
    return rv;
}

boost::optional<const PHV::Field*> ActionPhvConstraints::field_destination(
        const PHV::Field* f,
        const IR::MAU::Action* action) const {
    ordered_set<const PHV::Field*> rs;
    PHV::FieldSlice source(f, StartLen(0, f->size));
    for (const IR::MAU::Action* act : constraint_tracker.read_in(source)) {
        if (act != action) continue;
        auto destinations = constraint_tracker.destinations(source, act);
        for (auto slice : destinations)
            rs.insert(slice.field());
    }
    if (rs.size() == 0) return boost::none;
    return (*(rs.begin()));
}

bool ActionPhvConstraints::move_only_operations(const PHV::Field* f) const {
    PHV::FieldSlice dest(f, StartLen(0, f->size));
    // Whenever f is written in an action, if the write is not a MOVE operation, return true
    for (const IR::MAU::Action* act : constraint_tracker.written_in(dest)) {
        auto operands = constraint_tracker.sources(dest, act);
        for (auto it = operands.begin(); it != operands.end(); ++it)
            if (it->flags != OperandInfo::MOVE)
                return false; }
    return true;
}

bool ActionPhvConstraints::can_pack_pov(
        const PHV::SuperCluster::SliceList* slice_list,
        const PHV::Field* f) const {
    LOG3("Considering slice list " << *slice_list);
    ordered_map<const PHV::Field*, size_t> fieldsWithPositions;
    size_t index = 0;
    for (auto& slice : *slice_list)
        fieldsWithPositions[slice.field()] = index++;
    fieldsWithPositions[f] = index++;
    for (auto kv : fieldsWithPositions)
        LOG3(kv.first->name << " : " << kv.second);

    // Conditions:
    // 1. If these fields are all written in the same container with different kind of
    //    operands, then reject this packing.
    ordered_set<const IR::MAU::Action*> set_of_actions;
    for (auto kv : fieldsWithPositions) {
        const auto& writing_actions = constraint_tracker.written_in(PHV::FieldSlice(kv.first));
        set_of_actions.insert(writing_actions.begin(), writing_actions.end());
    }

    unsigned num_fields = fieldsWithPositions.size();
    for (const auto* act : set_of_actions) {
        LOG3("\tChecking action " << act->name);
        ordered_set<const PHV::Field*> written_by_phv;
        ordered_set<const PHV::Field*> written_by_ad;
        ordered_set<const PHV::Field*> not_written;
        for (auto kv : fieldsWithPositions) {
            auto source = constraint_tracker.hasPHVSource(kv.first, act);
            if (!source) {
                not_written.insert(kv.first);
                continue;
            }
            if (*source == true)
                written_by_phv.insert(kv.first);
            else
                written_by_ad.insert(kv.first);
        }

        LOG3("phv: " << written_by_phv.size() << ", ad: " << written_by_ad.size() <<
             ", not written: " << not_written.size());
        if (num_fields % 8 == 0 && not_written.size() == 0) continue;
        if (written_by_phv.size() > 0 && written_by_ad.size() > 0 &&
                (not_written.size() > 0 || num_fields % 8 != 0)) {
            LOG3("Some part of the container will be overwritten.");
            return false;
        }
    }
    return true;
}

boost::optional<bool> ActionPhvConstraints::ConstraintTracker::hasPHVSource(
        const PHV::Field* field,
        const IR::MAU::Action* act) const {
    PHV::FieldSlice destination(field, StartLen(0, field->size));
    // Destination field not written in @act, return boost::none.
    if (!written_in(destination).count(act))
        return boost::none;
    // Check each source for the destination field.
    auto operands = sources(destination, act);
    for (auto& op : operands) {
        // If any source has a non-PHV source, then return false.
        if (op.phv_used == boost::none)
            return false;
    }
    return true;
}

boost::optional<bool> ActionPhvConstraints::ConstraintTracker::hasActionDataOrConstantSource(
        const PHV::Field* field,
        const IR::MAU::Action* act) const {
    PHV::FieldSlice destination(field, StartLen(0, field->size));
    // Destination field not written in @act, return boost::none.
    if (!written_in(destination).count(act))
        return boost::none;
    // Check each source for the destination field.
    auto operands = sources(destination, act);
    for (auto& op : operands) {
        // If any source has a non action data or constant source, return false.
        if (op.ad == false && op.constant == false)
            return false;
    }
    return true;
}

UnionFind<PHV::FieldSlice> ActionPhvConstraints::classify_PHV_sources(
        const ordered_set<PHV::FieldSlice>& phvSlices,
        const ordered_map<PHV::FieldSlice, const PHV::SuperCluster::SliceList*>& lists_map) const {
    UnionFind<PHV::FieldSlice> classified_sources;
    ordered_map<const PHV::SuperCluster::SliceList*, PHV::FieldSlice> slice_list_to_slice;
    for (auto& slice : phvSlices) {
        classified_sources.insert(slice);
        // If the slice does not belong to a slice list, then it is to be placed in its own
        // container.
        if (!lists_map.count(slice)) continue;
        // The slice list is already represented in the slice_list_to_slice map. Union the set
        // corresponding to the representative slice with the current slice.
        if (slice_list_to_slice.count(lists_map.at(slice))) {
            classified_sources.makeUnion(slice_list_to_slice.at(lists_map.at(slice)), slice);
            continue;
        }
        // First representative slice of this slice list.
        slice_list_to_slice[lists_map.at(slice)] = slice;
    }
    return classified_sources;
}

void ActionPhvConstraints::throw_too_many_sources_error(
        const ordered_set<PHV::FieldSlice>& actionDataWrittenSlices,
        const ordered_set<PHV::FieldSlice>& notWrittenSlices,
        const UnionFind<PHV::FieldSlice>& phvSources,
        const ordered_map<PHV::FieldSlice, std::pair<int, int>>& phvAlignedSlices,
        const IR::MAU::Action* action,
        std::stringstream& ss) const {
    cstring action_name = canon_name(action->externalName());
    bool adSource = (actionDataWrittenSlices.size() > 0);
    ss << "it requires too many sources.";
    unsigned source_num = 1;
    if (adSource) {
        ss << std::endl << "\tSource " << (source_num++) << " is action data/constant, which "
            "write(s) the following field slices:";
        for (auto& slice : actionDataWrittenSlices) {
            auto sources = constraint_tracker.sources(slice, action);
            std::stringstream ss_source;
            for (auto& source : sources) {
                if (source.ad) {
                    ss_source << ", written by action data";
                    break;
                } else if (source.constant) {
                    ss_source << ", written by constant 0x" << std::hex << source.const_value;
                    break;
                }
            }
            ss << std::endl << "\t  " << slice.shortString() << ss_source.str();
        }
    }
    if (notWrittenSlices.size() > 0) {
        ss << std::endl << "\tSource " << (source_num++) << " is the container itself, imposed "
            "by the following fields that are unwritten in action " << action_name << ":";
        for (auto& slice : notWrittenSlices)
            ss << std::endl << "\t  " << slice.shortString();
    }
    for (const auto* set : phvSources) {
        bool allSlicesUnwritten = true;
        // Ignore the slices in the UnionFind struct that are sources because they are not written
        // in this action. The not-written case has already been handled by the above if-condition.
        for (auto& slice : *set)
            if (!notWrittenSlices.count(slice))
                allSlicesUnwritten = false;
        if (allSlicesUnwritten) continue;
        ss << std::endl << "\tSource " << (source_num++) << " contains the following fields:";
        boost::optional<int> offset = boost::none;
        bool unaligned = false;
        ordered_set<PHV::FieldSlice> printedFields;
        for (auto& slice : *set) {
            if (printedFields.count(slice)) continue;
            ss << std::endl << "\t  " << slice.shortString();
            printedFields.insert(slice);
            if (phvAlignedSlices.count(slice)) {
                int start = phvAlignedSlices.at(slice).second;
                int thisOffset = phvAlignedSlices.at(slice).first - start;
                if (offset != boost::none && *offset == thisOffset)
                    unaligned = true;
                // Start = -1 indicates that the source does not belong to a slice list and
                // therefore, could potentially have multiple possible alignments within its
                // container.
                // XXX(Deep): Potentially improve this by considering bit in byte alignments for
                // fields.
                if (start == -1) continue;
                ss << " @ bits " << start << "-" << (start + slice.size() - 1);
            }
        }
        // Also, output second order alignment violations (the programmer first needs to resolve the
        // too-many-sources error).
        // Also, indicate to the user that PHV sources are not aligned (if possible), which violates
        // alignment constraints when action data/constant is present.
        if (adSource && offset && *offset != 0) {
            ss << std::endl << "  and slices of source " << source_num << " are not allocated "
                << "at the same offsets within the container as the destination slices." <<
                std::endl;
            continue;
        }
        // If each destination in the container has a different offset relative to its source slice
        // (and all those source slices are part of the same source container), that also violates
        // an action constraint.
        if (unaligned) {
            ss << std::endl << "  and slices of source " << source_num << " do not have the "
                "same rotational alignment with respect to their destination slices." <<
                std::endl;
            continue;
        }
    }

    if (adSource) {
        ss << std::endl << "  However, " << Device::name() << " supports only one PHV source, "
            "when action data/constant is present.";
    } else {
        ss << std::endl << "  However, " << Device::name() << " supports only two PHV sources.";
    }
    ss << std::endl << "  Rewrite action " << action_name << " to use at most 2 PHV sources "
        "(and no action data/constant source) or 1 PHV source (if action data/constant is "
        << "necessary)." << std::endl << std::endl;
}

void ActionPhvConstraints::throw_non_contiguous_mask_error(
        const ordered_set<PHV::FieldSlice>& notWrittenSlices,
        const ordered_map<PHV::FieldSlice, ordered_set<PHV::FieldSlice>>& destToSource,
        const ordered_map<PHV::FieldSlice, unsigned>& fieldAlignments,
        cstring action_name,
        std::stringstream& ss) const {
    ss << " of non-contiguous partial container write(s)." << std::endl;
    ss << "\tAction " << action_name << " writes the following fields in the container:" <<
        std::endl;
    for (const auto& kv : destToSource) {
        ss << "\t  " << kv.first.shortString();
        if (kv.first.size() == 1)
            ss << " @ bit " << fieldAlignments.at(kv.first) << std::endl;
        else
            ss << " @ bits " << fieldAlignments.at(kv.first) << "-" <<
                (fieldAlignments.at(kv.first) + kv.first.size() - 1) << std::endl;
    }
    ss << "\tAction " << action_name << " does not write the following container fields:" <<
        std::endl;
    for (auto& slice : notWrittenSlices) {
        ss << "\t  " << slice.shortString();
        if (slice.size() == 1)
            ss << " @ bit " << fieldAlignments.at(slice) << std::endl;
        else
            ss << " @ bits " << fieldAlignments.at(slice) << "-" << (fieldAlignments.at(slice) +
                    slice.size() - 1) << std::endl;
    }
    ss << "  " << Device::name() << " requires at least one of the set of slices written or "
       "slices not written to be contiguous." << std::endl << std::endl;
}

bool ActionPhvConstraints::diagnoseInvalidPacking(
        const IR::MAU::Action* action,
        const PHV::SuperCluster::SliceList* list,
        const ordered_map<PHV::FieldSlice, unsigned>& fieldAlignments,
        const ordered_map<PHV::FieldSlice, const PHV::SuperCluster::SliceList*>& lists_map,
        std::stringstream& ss) const {
    ordered_map<PHV::FieldSlice, ordered_set<PHV::FieldSlice>> destToSource;
    ordered_map<PHV::FieldSlice, ordered_set<PHV::FieldSlice>> sourceToDest;
    ordered_set<PHV::FieldSlice> notWrittenSlices;
    ordered_set<PHV::FieldSlice> actionDataWrittenSlices;
    ordered_map<PHV::FieldSlice, std::pair<int, int>> phvAlignedSlices;
    ordered_set<PHV::FieldSlice> allPHVSlices;
    cstring action_name = canon_name(action->externalName());
    bitvec writtenBitvec;
    bitvec notWrittenBitvec;
    for (auto& slice : *list) {
        auto sources = constraint_tracker.sources(slice, action);
        if (sources.size() == 0) {
            notWrittenSlices.insert(slice);
            notWrittenBitvec |= bitvec(fieldAlignments.at(slice), slice.size());
            allPHVSlices.insert(slice);
            continue;
        }
        writtenBitvec |= bitvec(fieldAlignments.at(slice), slice.size());
        for (auto& info : sources) {
            if (info.ad || info.constant) {
                actionDataWrittenSlices.insert(slice);
            } else {
                BUG_CHECK(info.phv_used != boost::none, "No source associated with OperandInfo?");
                PHV::FieldSlice source_slice = *(info.phv_used);
                destToSource[slice].insert(source_slice);
                sourceToDest[source_slice].insert(slice);
                allPHVSlices.insert(*(info.phv_used));
                if (fieldAlignments.count(source_slice))
                    phvAlignedSlices[source_slice] = std::make_pair(fieldAlignments.at(slice),
                            fieldAlignments.at(source_slice));
                else
                    phvAlignedSlices[source_slice] = std::make_pair(fieldAlignments.at(slice), -1);
            }
        }
    }
    UnionFind<PHV::FieldSlice> phvSources = classify_PHV_sources(allPHVSlices, lists_map);
    size_t numPHVSources = phvSources.numSets();
    LOG4("Number of detected PHV sources: " << numPHVSources);
    LOG4(phvSources);

    bool adSource = (actionDataWrittenSlices.size() > 0);
    size_t allowedPHVSources = adSource ? 1 : 2;
    bool tooManySources = (numPHVSources > allowedPHVSources);

    // Detect the case where multiple PHV sources are required, in addition to action data/constant.
    if (tooManySources) {
        throw_too_many_sources_error(actionDataWrittenSlices, notWrittenSlices, phvSources,
                phvAlignedSlices, action, ss);
        return false;
    }

    // Detect cases where a deposit-field cannot be synthesized because the mask cannot be
    // contiguous.
    if (numPHVSources > 0 && !writtenBitvec.is_contiguous() && !notWrittenBitvec.is_contiguous()) {
        throw_non_contiguous_mask_error(notWrittenSlices, destToSource, fieldAlignments,
                action_name, ss);
        return false;
    }

    return true;
}

bool ActionPhvConstraints::diagnoseSuperCluster(
        const ordered_set<const PHV::SuperCluster::SliceList*>& sc,
        const ordered_map<PHV::FieldSlice, unsigned>& fieldAlignments,
        std::stringstream& error_msg) const {
    // For each slice list, gather all the field slices in it, and the actions that write to that
    // slice list.
    error_msg << "This program violates action constraints imposed by " << Device::name() << "." <<
        std::endl << std::endl;
    ordered_map<PHV::FieldSlice, const PHV::SuperCluster::SliceList*> slice_to_slice_list;
    bool error_found = false;
    for (const auto* list : sc)
        for (auto& slice : *list)
            slice_to_slice_list[slice] = list;
    for (const auto* list : sc) {
        ordered_set<const IR::MAU::Action*> actions;
        ordered_set<PHV::FieldSlice> set_of_slices;
        cstring hdr = (*(list->begin())).field()->header();
        std::stringstream slices;
        slices << "  PHV allocation requires the following field slices to be packed together, "
            "because of the structure of header " << hdr << std::endl;
        for (auto& slice : *list) {
            slices << "\t" << slice.shortString() << std::endl;
            auto actionsWritingSlice = constraint_tracker.written_in(slice);
            actions.insert(actionsWritingSlice.begin(), actionsWritingSlice.end());
            set_of_slices.insert(slice);
        }
        for (const auto* action : actions) {
            cstring action_name = canon_name(action->externalName());
            std::stringstream ss;
            ss << "  Action " << action_name << " must be rewritten.";
            // Check whether the operations in this slice list are of the correct kind.
            if (!valid_container_operation_type(action, set_of_slices, ss)) {
                error_msg << ss.str();
                error_found = true;
                continue;
            }
            ss.str(std::string());
            ss << "  Action " << action_name << " must be rewritten, because ";
            // Then check if the packing for this supercluster is valid.
            if (!diagnoseInvalidPacking(action, list, fieldAlignments, slice_to_slice_list, ss)) {
                error_msg << slices.str() << std::endl;
                error_msg << ss.str();
                error_found = true;
            }
        }
    }
    return error_found;
}

void ActionPhvConstraints::ConstraintTracker::printMapStates() const {
    if (!LOGGING(7)) return;
    for (auto &act : action_to_writes) {
        LOG7("Action: " << act.first->name << " writes fields: ");
        for (auto &fi : act.second) {
            LOG7("\t\t" << fi.phv_used << ", written by a MOVE? "
                 << (fi.flags == OperandInfo::MOVE)); } }

        for (auto &f : write_to_reads_per_action) {
            LOG7("Key field: " << f.first << " uses operands: ");
            for (auto &fi : f.second) {
                LOG7("\tAction: " << fi.first->name);
                for (auto &r : fi.second) {
                    LOG7("\t\tRange: " << r.first);
                    for (auto &fii : r.second) {
                        if (!fii.ad && !fii.constant)
                            LOG7("\t\t\tSlice: " << fii.phv_used);
                        else
                            LOG7("\t\t\tAction data."); } } } }

        for (auto &f : read_to_writes_per_action) {
            LOG7("Key field: " << f.first << " is read by the field(s): ");
            for (auto &fi : f.second) {
                LOG7("\tAction: " << fi.first->name);
                for (auto& r : fi.second) {
                    LOG7("\t\tRange: " << r.first);
                    for (auto &fii : r.second)
                        LOG7("\t\t\tSlice: " << fii); } } }

    for (auto& by_field : field_writes_to_actions) {
        for (auto& by_range : by_field.second) {
            LOG7(PHV::FieldSlice(by_field.first, by_range.first) << " written in:");
            for (auto* act : by_range.second)
                LOG7("    " << act->name); } }
}

bool ActionPhvConstraints::is_in_field_writes_to_actions(
        cstring write,
        const IR::MAU::Action* action) const {
    const PHV::Field* write_field = phv.field(write);
    if (write_field == nullptr)
        return false;
    auto slice = PHV::FieldSlice(write_field, StartLen(0, write_field->size));
    auto acts = constraint_tracker.written_in(slice);
    return (acts.find(action) != acts.end());
}

bool ActionPhvConstraints::is_in_action_to_writes(
        const IR::MAU::Action* action,
        cstring write) const {
    const PHV::Field* write_field = phv.field(write);
    if (write_field == nullptr)
        return false;
    auto ops = constraint_tracker.writes(action);
    return std::any_of(ops.begin(), ops.end(), [&](const OperandInfo& info) {
                            return info.phv_used && info.phv_used->field() == write_field; });
}

bool ActionPhvConstraints::is_in_write_to_reads(
        cstring write,
        const IR::MAU::Action *act,
        cstring read) const {
    const PHV::Field* write_field = phv.field(write);
    const PHV::Field* read_field = phv.field(read);
    if (write_field == nullptr || read_field == nullptr)
        return false;
    auto write_slice = PHV::FieldSlice(write_field, StartLen(0, write_field->size));
    auto reads = constraint_tracker.sources(write_slice, act);
    return std::any_of(reads.begin(), reads.end(), [&](const OperandInfo& info) {
                            return info.phv_used && info.phv_used->field() == read_field; });
}

std::ostream &operator<<(std::ostream &out, const ActionPhvConstraints::OperandInfo& info) {
    out << "[ ";
    if (info.ad)
        out << "ACTION DATA ";
    if (info.constant)
        out << "CONST " << info.const_value << " ";
    if (info.phv_used)
        out << *info.phv_used << " ";
    if (!info.ad && !info.constant && !info.phv_used)
        out << "INVALID OPERAND INFO ";
    out << "]";
    out << "[ ";
    if (info.flags & ActionPhvConstraints::OperandInfo::MOVE)
        out << " MOVE ";
    if (info.flags & ActionPhvConstraints::OperandInfo::BITWISE)
        out << " BITWISE ";
    if (info.flags & ActionPhvConstraints::OperandInfo::WHOLE_CONTAINER)
        out << " WHOLE ";
    if (info.flags & ActionPhvConstraints::OperandInfo::ANOTHER_OPERAND)
        out << " ANOTHER ";
    if (info.flags & ActionPhvConstraints::OperandInfo::MIXED)
        out << " MIXED ";
    if (info.flags & ActionPhvConstraints::OperandInfo::WHOLE_CONTAINER_SAME_FIELD)
        out << " SAME ";
    out << "]";
    return out;
}

std::ostream &operator<<(std::ostream &out, const CanPackErrorCode& ec) {
    out << " CanPackErrorCode: ";
    out << (unsigned) ec;
    return out;
}
