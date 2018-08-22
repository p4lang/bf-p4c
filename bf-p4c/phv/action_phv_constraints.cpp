#include <boost/optional/optional_io.hpp>
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/cluster_phv_operations.h"

int ActionPhvConstraints::ConstraintTracker::current_action = 0;

Visitor::profile_t ActionPhvConstraints::init_apply(const IR::Node *root) {
    profile_t rv = Inspector::init_apply(root);
    meter_color_destinations.clear();
    special_no_pack.clear();
    constraint_tracker.clear();
    return rv;
}

bool ActionPhvConstraints::preorder(const IR::MAU::Action *act) {
    auto *tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, false, false, tbl);
    ActionAnalysis::FieldActionsMap field_actions_map;
    aa.set_field_actions_map(&field_actions_map);
    act->apply(aa);
    constraint_tracker.add_action(act, field_actions_map);
    return true;
}

void ActionPhvConstraints::ConstraintTracker::clear() {
    LOG6("CLEARING ActionPhvConstraints");
    current_action = 0;
    field_writes_to_actions.clear();
    action_to_writes.clear();
    write_to_reads_per_action.clear();
    read_to_writes_per_action.clear();
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
            } else if (read.type == ActionAnalysis::ActionParam::CONSTANT) {
                fr.constant = true;
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
            if (read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL)
                self.special_no_pack[write.field()].insert(act);

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
    boost::optional<le_bitrange> containing = boost::none;
    for (auto& kv : by_range) {
        if (kv.first.contains(dst.range())) {
            BUG_CHECK(containing == boost::none,
                      "Field %1% written to more than once in action %2%",
                      dst.field()->name, act);
            containing = kv.first; } }
    if (!containing)
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
    if (field_writes_to_actions.find(dst.field()) == field_writes_to_actions.end())
        return rv;

    for (auto& kv : field_writes_to_actions.at(dst.field())) {
        if (kv.first.contains(dst.range()))
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
            LOG6("\t\t\t\t...induced by action " << act);
            rv.insert(dst.container_slice().lo); } }

    return rv;
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
            return l;
        } else if (l_writes > r_writes) {
            return r;
        } else {
            if (l_reads > r_reads) {
                return l;
            } else {
                return r; } } };

    slice_list.sort(SliceListComparator);
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

void ActionPhvConstraints::end_apply() {
    LOG7("*****Printing  ActionPhvConstraints Maps*****");
    constraint_tracker.printMapStates();
    LOG7("*****End Print ActionPhvConstraints Maps*****");
}

ActionPhvConstraints::NumContainers ActionPhvConstraints::num_container_sources(
        const PHV::Allocation &alloc,
        PHV::Allocation::MutuallyLiveSlices container_state,
        const IR::MAU::Action* action,
        UnionFind<PHV::FieldSlice>& packing_constraints) {
    ordered_set<PHV::Container> containerList;
    size_t num_unallocated = 0;
    for (auto slice : container_state) {
        auto reads = constraint_tracker.sources(slice, action);
        if (reads.size() == 0)
            LOG5("\t\t\t\tSlice " << slice << " is not written in action " << action->name);
        for (auto operand : reads) {
            if (operand.ad || operand.constant) {
                LOG6("\t\t\t\t" << operand << " doesn't count as a container source");
                continue; }
            const PHV::Field* fieldRead = operand.phv_used->field();
            le_bitrange rangeRead = operand.phv_used->range();

            LOG6("\t\t\t\t\tInserting " << fieldRead->name << " [" << rangeRead.lo << ", " <<
                    rangeRead.hi << "] into copacking_constraints");
            packing_constraints.insert(*operand.phv_used);

            ordered_set<PHV::Container> per_source_containers;
            ordered_set<PHV::AllocSlice> per_source_slices = alloc.slices(fieldRead, rangeRead);
            for (auto source : container_state)
                if (source.field() == fieldRead && source.field_slice().overlaps(rangeRead))
                    per_source_slices.insert(source);

            for (auto source_slice : per_source_slices) {
                per_source_containers.insert(source_slice.container());
                LOG5("\t\t\t\t\tSource slice for " << slice << " : " << source_slice); }
            if (per_source_containers.size() == 0) {
                LOG5("\t\t\t\tSource " << fieldRead->name << " has not been allocated yet.");
                ++num_unallocated;
            } else {
                containerList.insert(per_source_containers.begin(), per_source_containers.end()); }
        } }
    LOG5("\t\t\t\tNumber of allocated sources  : " << containerList.size());
    LOG5("\t\t\t\tNumber of unallocated sources: " << num_unallocated);
    LOG5("\t\t\t\tTotal number of sources      : " << (containerList.size() + num_unallocated));
    return NumContainers(containerList.size(), num_unallocated);
}

boost::optional<PHV::AllocSlice> ActionPhvConstraints::getSourcePHVSlice(
        const PHV::Allocation &alloc,
        const std::vector<PHV::AllocSlice>& slices,
        PHV::AllocSlice& slice,
        const IR::MAU::Action* action) {
    LOG5("\t\t\t\tgetSourcePHVSlices for action: " << action->name << " and slice " << slice);
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
        ordered_set<PHV::AllocSlice> per_source_slices = alloc.slices(fieldRead, rangeRead);

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
                BUG("Multiple source slices found in getSourcePHVSlice()");
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
        const IR::MAU::Action* action) const {
    for (auto slice : slices) {
        for (auto operand : constraint_tracker.sources(slice, action)) {
            if (operand.ad || operand.constant) {
                LOG5("\t\t\t\t  Field " << slice.field()->name <<
                     " written using action data/constant in action " << action->name);
                return true; } } }
    return false;
}

bool ActionPhvConstraints::all_or_none_constant_sources(
        const PHV::Allocation::MutuallyLiveSlices& slices,
        const IR::MAU::Action* action) const {
    unsigned num_slices_written_by_ad = 0;
    for (auto slice : slices) {
        bool written_by_ad = false;
        for (auto operand : constraint_tracker.sources(slice, action))
            if (operand.ad || operand.constant)
                written_by_ad = true;
        num_slices_written_by_ad += (written_by_ad ? 1 : 0); }
    if (num_slices_written_by_ad == 0) {
        LOG5("\t\t\t\t  No slice in proposed packing written by action data/constant in action "
             << action->name);
        return true; }
    if (num_slices_written_by_ad == slices.size()) {
        LOG5("\t\t\t\t  All slices in proposed packing written by action data/constant in action "
             << action->name);
        return true; }
    LOG5("\t\t\t\t  Only " << num_slices_written_by_ad << " out of " << slices.size() << " slices "
         " in proposed packing are written by action data/constant in action " << action->name);
    return false;
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

unsigned ActionPhvConstraints::container_operation_type(
        const IR::MAU::Action* action,
        const PHV::Allocation::MutuallyLiveSlices& slices) const {
    LOG5("\t\t\tChecking container operation type for action: " << action->name);
    unsigned type_of_operation = 0;
    size_t num_fields_not_written = 0;
    ordered_set<const PHV::Field*> observed_fields;
    cstring operation;

    for (auto slice : slices) {
        auto field_slice = PHV::FieldSlice(slice.field(), slice.field_slice());
        boost::optional<OperandInfo> fw = constraint_tracker.is_written(field_slice, action);
        if (!fw) {
            num_fields_not_written++;
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

        LOG5("\t\t\t\tNumber of slices written to by this whole container operation: " <<
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
    const PHV::Field* field;
    for (auto slice : container_state) {
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

void ActionPhvConstraints::pack_slices_together(
        const PHV::Allocation &alloc,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        UnionFind<PHV::FieldSlice>& packing_constraints,
        const IR::MAU::Action* action,
        bool pack_unallocated_only  /*If true, only unallocated slices will be packed together*/) {
    if (pack_unallocated_only)
        LOG5("\t\t\t\t\tPack all unallocated slices together. All bits in container are occupied.");
    else
        LOG5("\t\t\t\t\tPack all slices together.");
    ordered_set<PHV::FieldSlice> pack_together;
    for (auto slice : container_state) {
        for (auto operand : constraint_tracker.sources(slice, action)) {
            if (operand.ad || operand.constant)
                continue;
            const PHV::Field* fieldRead = operand.phv_used->field();
            le_bitrange rangeRead = operand.phv_used->range();
            if (pack_unallocated_only) {
                ordered_set<PHV::Container> containers;
                ordered_set<PHV::AllocSlice> per_source_slices = alloc.slices(fieldRead, rangeRead);

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
            LOG6("\t\t\t\t\tInserting " << fieldRead->name << " [" << rangeRead.lo << ", " <<
                    rangeRead.hi << "] into copacking_constraints");
            pack_together.insert(PHV::FieldSlice(fieldRead, rangeRead)); } }

    if (LOGGING(5)) {
        std::stringstream ss;
        for (auto slice : pack_together)
            ss << slice;
        LOG5("\t\t\t\t\tPack together: " << ss.str()); }

    PHV::FieldSlice *firstSlice = nullptr;
    for (auto slice : pack_together) {
        if (firstSlice == nullptr) {
            LOG5("\t\t\t\t\t\tSetting first slice to  " << slice);
            firstSlice = new PHV::FieldSlice(slice.field(), slice.range()); }
        LOG5("\t\t\t\t\tUnion " << *firstSlice << " with " << slice);
        packing_constraints.makeUnion(*firstSlice, slice); }
}

// At this point, any packing is valid, having passed the can_pack() method. Also, if fields are
// mutually exclusive, they are written by different actions and in different tables, so the writes
// to those mutually exclusive fields should not have an effect on the number of bitmasked-set
// instructions detected.
int ActionPhvConstraints::count_bitmasked_set_instructions(
        const std::vector<PHV::AllocSlice>& slices) const {
    int numBitmaskedSet = 0;
    if (slices.size() == 0)
        return 0;
    // Create a set out of the vector of slices, because has_ad_or_constant_sources() only takes the
    // set.
    ordered_set<PHV::AllocSlice> setOfSlices;
    for (auto& slice : slices)
        setOfSlices.insert(slice);

    // Merge actions for all candidate fields into a set.
    ordered_set<const IR::MAU::Action*> allActionsForSlices;
    for (auto& slice : slices) {
        const auto& writingActions = constraint_tracker.written_in(slice);
        allActionsForSlices.insert(writingActions.begin(), writingActions.end()); }
    // For every action, check if bitmasked-set would be synthesized for the writes to slices.
    for (auto& action : allActionsForSlices) {
        bool has_ad_constant_sources = has_ad_or_constant_sources(setOfSlices, action);
        // Bitmasked-set instructions require an action data source.
        if (!has_ad_constant_sources)
            continue;
        // Determine the set of fields in the packing (slices) that are not written by action.
        ordered_set<PHV::AllocSlice> fieldsNotWrittenTo;
        for (auto slice : slices)
            if (!constraint_tracker.is_written(slice, action))
                fieldsNotWrittenTo.insert(slice);
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
        written |= writtenThisSlice; }
    // Contiguity is enough because we don't currently support making action data rotationally
    // equivalent. If the bits written are contiguous, then this instruction is going to be realized
    // using deposit-field rather than bitmasked-set.
    if (written.is_contiguous())
        return false;
    return true;
}

bool ActionPhvConstraints::pack_conflicts_present(
        const PHV::Allocation::MutuallyLiveSlices& container_state) const {
    for (auto sl1 : container_state) {
        for (auto sl2 : container_state) {
            if (sl1.field() == sl2.field()) continue;
            if (hasPackConflict(sl1.field(), sl2.field())) {
                LOG5("\t\t\t" << sl1.field()->name << " cannot be packed in the same stage with " <<
                     sl2.field()->name);
                return true; } } }
    return false;
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
        UnionFind<PHV::FieldSlice>& copacking_constraints) {
    // Special packing constraints are introduced when number of source containers > 2 and
    // number of allocated containers is less than or equal to 2.
    // At this point of the loop, sources.num_allocated <= 2, sources.num_unallocated may be any
    // value.
    bool mocha_or_dark = c.is(PHV::Kind::dark) || c.is(PHV::Kind::mocha);
    size_t num_source_containers = sources.num_allocated + sources.num_unallocated;
    PHV::Allocation::MutuallyLiveSlices state_written_to;
    PHV::Allocation::MutuallyLiveSlices state_not_written_to;
    for (auto slice : container_state) {
        if (!constraint_tracker.is_written(slice, action))
            state_not_written_to.insert(slice);
        else
            state_written_to.insert(slice);
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
            if (!masks_valid(container_state, action, true /*action data only*/)) {
                LOG5("\t\t\t\tThe action data used for this packing is not contiguous");
                return false; }
            pack_slices_together(alloc, container_state, copacking_constraints, action, false);
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
            if (has_bits_not_written_to) {
                if (!masks_valid(state_written_to, action, false /*non action data only*/) &&
                    !masks_valid(state_not_written_to, action, false /*non action data only*/)) {
                    LOG5("\t\t\t\tMasks found to not be valid for packing");
                    return false; } }
            // No Action data or constant sources and only 1 PHV container as source plus masks for
            // deposit-field found to be valid. So, the packing is valid without any other induced
            // constraints.
            return true; } }

    // If some field is not written to, then one of the sources for the move has to be the
    // container itself.
    // If sources.num_allocated == 2, this packing is not possible (TOO_MANY_SOURCES)
    if (num_fields_not_written_to && sources.num_allocated == 2) {
        LOG5("\t\t\t\t" << num_fields_not_written_to << " fields not written in action "
                << action->name << " will get clobbered.");
        return false; }

    // If some bits in the container are not written to, then one of the sources of the move has
    // to be the container itself.
    // If sources.num_allocated == 2, this packing is not possible (TOO_MANY_SOURCES)
    if (has_bits_not_written_to && sources.num_allocated == 2) {
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
        pack_slices_together(alloc, container_state, copacking_constraints, action, false);

    // For mocha and dark containers, partial container sets are impossible.
    if (mocha_or_dark && sources.num_unallocated > 0) {
        BUG_CHECK(sources.num_allocated <= 1, "Cannot have 2 or more sources for container %1%",
                c);
        // Pack all slices together.
        pack_slices_together(alloc, container_state, copacking_constraints, action, false); }

    // If sources.num_allocated == 1 and sources.num_unallocated > 0, then
    if (sources.num_allocated <= 1 && sources.num_unallocated > 0) {
        if (num_fields_not_written_to || has_bits_not_written_to) {
            // Pack all slices together (both allocated and unallocated)
            // Can only have src2 as src1 is always the destination container itself
            pack_slices_together(alloc, container_state, copacking_constraints, action, false);
            LOG6("\t\t\t\t\tMust pack unallocated fields with allocated fields."
                    " Setting source containers to 1.");
            numSourceContainers[action] = 1;
        } else {
            // For this case, sources need not be packed together as we may have (at most) 2
            // source containers
            if (num_source_containers == 2) return true;
            // Only pack unallocated slices together
            pack_slices_together(alloc, container_state, copacking_constraints, action, true);
        }
    }
    return true;
}

bool ActionPhvConstraints::generate_conditional_constraints_for_bitwise_op(
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const ordered_set<PHV::FieldSlice>& sources,
        UnionFind<PHV::FieldSlice>& copacking_constraints) const {
    if (sources.size() == 0) return true;
    boost::optional<bool> destSameAsSource;
    for (auto& slice : container_state) {
        PHV::FieldSlice sl(slice.field(), slice.field_slice());
        bool sameAsSource = sources.count(sl);
        if (!destSameAsSource) {
            destSameAsSource = sameAsSource;
        } else {
            if (sameAsSource != *destSameAsSource) {
                LOG6("\t\t\t\tCannot generate conditional constraints for bitwise operations.");
                return false; } } }
    if (destSameAsSource && *destSameAsSource) {
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
            copacking_constraints.makeUnion(slice, slice1); } }
    return true;
}

bool ActionPhvConstraints::check_and_generate_constraints_for_bitwise_op_with_unallocated_sources(
        const IR::MAU::Action* action,
        const PHV::Allocation::MutuallyLiveSlices& container_state,
        const NumContainers& sources,
        UnionFind<PHV::FieldSlice>& copacking_constraints) const {
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
    rv &= generate_conditional_constraints_for_bitwise_op(container_state, source1,
            copacking_constraints);
    rv &= generate_conditional_constraints_for_bitwise_op(container_state, source2,
            copacking_constraints);
    return rv;
}

boost::optional<PHV::Allocation::ConditionalConstraints>
ActionPhvConstraints::can_pack(const PHV::Allocation& alloc, const PHV::AllocSlice& slice) {
    std::vector<PHV::AllocSlice> slices;
    slices.push_back(slice);
    return can_pack(alloc, slices);
}

boost::optional<PHV::Allocation::ConditionalConstraints> ActionPhvConstraints::can_pack(
        const PHV::Allocation& alloc,
        std::vector<PHV::AllocSlice>& slices) {
    PHV::Allocation::ConditionalConstraints rv;
    // Allocating zero slices always succeeds...
    if (slices.size() == 0)
        return rv;

    ordered_map<const IR::MAU::Action*, unsigned> operationType;
    ordered_map<const IR::MAU::Action*, bool> usesActionDataConstant;
    ordered_map<const IR::MAU::Action*, bool> phvMustBeAligned;
    ordered_map<const IR::MAU::Action*, size_t> numSourceContainers;
    ordered_map<const IR::MAU::Action*, size_t> numUnallocatedContainers;
    PHV::Container c = slices.front().container();

    PHV::Allocation::MutuallyLiveSlices container_state = alloc.slicesByLiveness(c, slices);
    LOG6("\t\tExisting container state: ");
    for (auto slice : container_state)
        LOG6("\t\t\t" << slice);

    if (LOGGING(5)) {
        LOG5("\t\tChecking whether field slice(s) ");
        for (auto slice : slices)
            LOG5("\t\t\t" << slice.field()->name << " (" << slice.width() << "b)");
        LOG5("\t\tcan be packed into container " << container_state << " already containing " <<
                container_state.size() << " slices"); }

    if (LOGGING(6))
        constraint_tracker.print_field_ordering(slices);

    // Create candidate packing
    for (auto slice : slices)
        container_state.insert(slice);

    // Check if table placement induced any no pack constraints on fields that are candidates for
    // packing. If yes, packing not possible.
    if (pack_conflicts_present(container_state))
        return boost::none;

    // Merge actions for all the candidate fields into a set
    ordered_set<const IR::MAU::Action *> set_of_actions;
    for (auto slice : container_state) {
        const auto& writing_actions = constraint_tracker.written_in(slice);
        set_of_actions.insert(writing_actions.begin(), writing_actions.end()); }

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
        return boost::none;

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
    UnionFind<PHV::FieldSlice> copacking_constraints;
    for (const auto* action : set_of_actions) {
        LOG5("\t\t\tNeed to check container sources now for action " << action->name);
        operationType[action] = container_operation_type(action, container_state);

        if (operationType[action] == OperandInfo::WHOLE_CONTAINER || operationType[action] ==
                OperandInfo::MIXED)
            return boost::none;

        if (operationType[action] == OperandInfo::WHOLE_CONTAINER_SAME_FIELD) {
            if (!are_adjacent_field_slices(container_state)) {
                return boost::none;
            } else {
                LOG5("\t\t\t\tMultiple slices involved in whole container operation are adjacent");
            }
        }

        if (operationType[action] == OperandInfo::BITWISE)
            LOG5("\t\t\t\tDetected bitwise operations");

        // Is there any action data or constant source for the proposed packing in this action?
        bool has_ad_constant_sources = has_ad_or_constant_sources(container_state, action);
        // If there is an action data or constant source, are all slices in the proposed packing
        // written using action data or constant sources.
        bool all_or_none_ad_constant_sources = has_ad_constant_sources ?
            all_or_none_constant_sources(container_state, action) : true;

        // If the action involves a bitwise operation for the proposed packing in container c, and
        // only some of the field slices are written using action data or constant sources, then
        // this packing is not valid.
        if (operationType[action] == OperandInfo::BITWISE && !all_or_none_ad_constant_sources)
            return boost::none;

        // Is the container either a mocha or dark container.
        bool mocha_or_dark = c.is(PHV::Kind::dark) || c.is(PHV::Kind::mocha);
        if (mocha_or_dark && operationType[action] == OperandInfo::BITWISE) {
            // Mocha or dark containers can only be used in whole container move operations.
            LOG5("\t\t\t\tAction " << action->name << " has a bitwise operation writing to a "
                 " dark or mocha container.");
            return boost::none; }

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
            if (sources.num_allocated > 1) return boost::none;
            if (!all_field_slices_written_together(container_state, set_of_actions))
                return boost::none;
            phvMustBeAligned[action] = true; }

        // If source fields have already been allocated and number of sources greater than 2, then
        // packing is not possible (TOO_MANY_SOURCES)
        if (sources.num_allocated > 2) {
            LOG5("\t\t\t\tAction " << action->name << " uses more than two PHV sources.");
            return boost::none; }

        // num_source_containers == 2 if execution gets here
        // If source fields have already been allocated and there are two PHV sources in addition to
        // an action data/constant source then packing is not possible (TOO_MANY_SOURCES)
        if (sources.num_allocated == 2 && has_ad_constant_sources) {
            LOG5("\t\t\t\tAction " << action->name << " uses action data/constant in addition to "
                    "two PHV sources");
            return boost::none; }

        // Check the validity of packing for move operations, and generate intermediate structures
        // that will be used to create conditional constraints.
        if (operationType[action] == OperandInfo::MOVE) {
            if (!check_and_generate_constraints_for_move_with_unallocated_sources(alloc, action, c,
                    container_state, sources, has_ad_constant_sources, phvMustBeAligned,
                    numSourceContainers, copacking_constraints))
                return boost::none;
        } else if (operationType[action] == OperandInfo::BITWISE) {
            // Check the validity of bitwise operations and generate intermediate structures that
            // will be used to create conditional constraints.
            // At this point, we have already checked (in container_type_operation) that every
            // single slice in the proposed packing has already been written by the same bitwise
            // operation (for this action).
            if (!check_and_generate_constraints_for_bitwise_op_with_unallocated_sources(action,
                    container_state, sources, copacking_constraints))
                return boost::none;
        } else if (operationType[action] != OperandInfo::WHOLE_CONTAINER_SAME_FIELD) {
            BUG("Operation type other than BITWISE and MOVE encountered."); } }


    LOG5("\t\t\tChecking rotational alignment");
    bool hasSingleUnallocatedPHVSource = false;
    bool hasTwoUnallocatedPHVSources = false;
    for (auto &action : set_of_actions) {
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
                    // Detect case where we have an unallocated PHV source and action data/constant
                    // writing to the same container in the same action. For such a case, enforce
                    // alignment constraints for the unallocated PHV source later (guarded using
                    // hasSingleUnallocatedPHVSource variable).
                    if (container_state.size() > 1 && usesActionDataConstant[action] &&
                            numUnallocatedContainers[action] == 1) {
                        hasSingleUnallocatedPHVSource = true;
                        LOG6("\t\t\t\tFound one unallocated PHV source"); }
                    continue; }
                if (slice.container_slice() != source->container_slice()) {
                    LOG5("\t\t\t\tContainer alignment for slice and source do not match");
                    return boost::none; } } }

        // TODO(cole): If phvMustBeAligned[action] and one of the fields to be
        // packed is in the UnionFind data structure (i.e. is a source), then
        // fail: It's impossible for a source to be aligned and also packed in
        // the same container as its destination (unless it's the same field).

        if (phvMustBeAligned[action] && numSourceContainers[action] == 2) {
            boost::optional<ClassifiedSources> classifiedSourceSlices =
                verify_two_container_alignment(alloc, container_state, action, c);
            if (!classifiedSourceSlices)
                return boost::none;
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
                return boost::none;
            if (numUnallocatedContainers[action] == 2)
                hasTwoUnallocatedPHVSources = true; }

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
                LOG6("\t\t\t\t\tOffset found: " << offset);
                if (firstSlice) {
                    firstOffset = offset;
                    firstSlice = false;
                } else {
                    if (offset!= firstOffset) {
                        LOG5("\t\t\t\tSource slices are at different offsets with respect to "
                                "destination slices");
                        return boost::none; } } } } }

    // XXX(cole): If there are conditional constraints---i.e. if these slices
    // can only be packed if some unallocated source operands are packed in the
    // right way---then compute a valid bit position for each source operand.
    // Note that this is overly conservative: It requires source operands to be
    // packed together and directly aligned (not rotationally aligned) with
    // their destinations.  This is what glass does, but we should try to relax
    // this constraint in the future.

    // Find the copacking constraints.
    ordered_map<int, ordered_set<PHV::FieldSlice>> copacking_set;
    ordered_map<PHV::FieldSlice, PHV::Container> req_container;
    int setIndex = 0;
    for (auto* set : copacking_constraints) {
        // Need to enforce alignment constraints when we have one unallocated PHV source and action
        // data writing to the container in the same action.
        if (set->size() < 2 && !hasSingleUnallocatedPHVSource)
            continue;
        if (copacking_set.size() > 0)
            LOG5("\t\t\t\tAction analysis produced more than one set of conditional packing "
                 "constraints.");
        // If some sources in the same set in copacking_constraints are already allocated, set the
        // container requirement for the unallocated sources in that set.
        if (!assign_containers_to_unallocated_sources(alloc, copacking_constraints,
                    req_container)) {
            LOG5("\t\t\t\tMultiple slices that must go into the same container are allocated "
                    "to different containers");
            return boost::none; }
        ordered_set<PHV::FieldSlice> setFieldSlices;
        setFieldSlices.insert(set->begin(), set->end());
        copacking_set[setIndex++] = setFieldSlices; }

    // If copacking_constraints has exactly two unallocated PHV source slices, force the smaller
    // slice to be aligned with its destination.
    if (hasTwoUnallocatedPHVSources) {
        ordered_set<PHV::FieldSlice> field_slices_in_current_container;
        for (auto& sl : container_state)
            field_slices_in_current_container.insert(PHV::FieldSlice(sl.field(), sl.field_slice()));
        boost::optional<PHV::FieldSlice> alignedSlice = get_smaller_source_slice(alloc,
                copacking_constraints, field_slices_in_current_container);
        if (alignedSlice) {
            bool foundAlignmentConstraint = false;
            for (auto* set : copacking_constraints) {
                if (set->size() > 1 && set->count(*alignedSlice)) {
                    foundAlignmentConstraint = true;
                    LOG5("\t\t\t\t  Alignment constraint already found on smaller slice: " <<
                         *alignedSlice); }
            }
            if (!foundAlignmentConstraint) {
                copacking_set[setIndex++] = { *alignedSlice };
                LOG5("\t\t\t\tEnforcing alignment constraint on smaller slice: " << *alignedSlice);
            }
        }
    }
    LOG5("Printing UnionFind struct");
    LOG5(copacking_constraints);

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
            if (req_alignment.size() > 1) {
                LOG5("\t\t\tPacking failed because " << packing_slice <<
                        " would (conservatively) need to be aligned at more than one position: "
                        << cstring::to_cstring(req_alignment));
                return boost::none; }

            // Alignment requirements could be empty in case the source slices are also unallocated
            // or due to action data/constant writes.
            if (req_alignment.size() == 0)
                continue;

            int bitPosition = *(req_alignment.begin());

            // Check that no other slices are also required to be at this bit
            // position, unless they're mutually exclusive and can be overlaid.
            for (auto& kv : placements) {
                bool isMutex = PHV::Allocation::mutually_exclusive(phv.field_mutex,
                        kv.first.field(),
                        packing_slice.field());
                if (kv.second.overlaps(StartLen(bitPosition, packing_slice.size())) && !isMutex) {
                    LOG5("\t\t\tPacking failed because " << packing_slice << " and " << kv.first <<
                         " slice would (conservatively) need to be aligned at the same position in "
                         "the same container.");
                    return boost::none; } }
            placements[packing_slice] = StartLen(bitPosition, packing_slice.size());

            // Set the required bit position.
            if (req_container.count(packing_slice))
                per_unallocated_source[packing_slice] =
                    PHV::Allocation::ConditionalConstraintData(bitPosition,
                            req_container[packing_slice]);
            else
                per_unallocated_source[packing_slice] =
                    PHV::Allocation::ConditionalConstraintData(bitPosition); }
        rv[kv_unallocated.first] = per_unallocated_source; }
    return rv;
}

boost::optional<PHV::FieldSlice> ActionPhvConstraints::get_smaller_source_slice(
        const PHV::Allocation& alloc,
        const UnionFind<PHV::FieldSlice>& copacking_constraints,
        const ordered_set<PHV::FieldSlice>& container_state) {
    // Get unallocated sources, excluding both allocated sources as well as slices that
    // are being packed in the container_state. Since those slices are in the container_state, they
    // are assumed to be allocated already.
    ordered_set<PHV::FieldSlice> twoUnallocatedSlices;
    LOG6("\t\t\t\tGathering unallocated sources for this container:");
    for (auto* set : copacking_constraints) {
        for (auto& sl : *set) {
            if (!container_state.count(sl) && alloc.slices(sl.field(), sl.range()).size() == 0) {
                LOG6("\t\t\t\t\tAdding " << sl);
                twoUnallocatedSlices.insert(sl);
            } else {
                LOG6("\t\t\t\t\tIgnoring allocated slice " << sl); } } }

    if (twoUnallocatedSlices.size() > 2) {
        // If we find more than two unallocated slices, return boost::none.
        LOG6("\t\t\t\tFound more than two unallocated slices.");
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
        const IR::MAU::Action* action,
        bool actionDataOnly) const {
    bitvec actionDataConstantMask;
    for (auto slice : container_state) {
        if (actionDataOnly && has_ad_or_constant_sources({ slice }, action)) {
            LOG7("\t\t\t\t  Action data constant mask for " << slice << " : " <<
                    slice.container_slice().lo << ", " << slice.width());
            actionDataConstantMask |= bitvec(slice.container_slice().lo, slice.width());
        }
        if (!actionDataOnly) {
            LOG7("\t\t\t\t  Mask for " << slice << " : " << slice.container_slice().lo
                    << ", " << slice.width());
            actionDataConstantMask |= bitvec(slice.container_slice().lo, slice.width());
        }
    }
    LOG5("\t\t\t\tRequired mask : " << actionDataConstantMask);
    if (actionDataConstantMask.is_contiguous())
        return true;
    return false;
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
        const PHV::Container destination) {
    ClassifiedSources rm;
    bool firstContainerSet = false;
    bool secondContainerSet = false;
    bool firstContainerAligned = true;
    bool secondContainerAligned = true;
    int firstOffset = 0;
    int secondOffset = 0;
    ordered_map<size_t, PHV::Container> num_to_source_mapping;

    for (auto slice : container_state) {
        LOG7("\t\t\t\tClassifying source slice for: " << slice);
        for (auto operand : constraint_tracker.sources(slice, action)) {
            if (operand.ad || operand.constant) continue;
            const PHV::Field* fieldRead = operand.phv_used->field();
            le_bitrange rangeRead = operand.phv_used->range();
            ordered_set<PHV::AllocSlice> per_source_slices = alloc.slices(fieldRead, rangeRead);
            for (auto sourceSlice : container_state) {
                bool rangeOverlaps = sourceSlice.field_slice().overlaps(rangeRead);
                if (sourceSlice.field() == fieldRead && rangeOverlaps)
                    per_source_slices.insert(sourceSlice); }

            // Combine multiple adjacent source slices.
            boost::optional<PHV::AllocSlice> src_slice = boost::none;
            for (auto& slice : per_source_slices) {
                if (!src_slice) {
                    src_slice = slice;
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
                src_slice = PHV::AllocSlice(src_slice->field(),
                                            src_slice->container(),
                                            src_slice->field_slice().lo,
                                            src_slice->container_slice().lo,
                                            src_slice->field_slice().size()
                                                + slice.field_slice().size()); }

            // For every source slice, check alignment individually and divide it up as part of
            // either the first source container or the second source container
            if (!src_slice) {
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
        const ordered_set<const IR::MAU::Action*>& set_of_actions) const {
    for (auto action : set_of_actions) {
        boost::optional<bool> thisActionWrites = boost::none;
        // for each AllocSlice in the container, check if it is written by the action.
        for (auto& slice : container_state) {
            boost::optional<OperandInfo> writeStatus = constraint_tracker.is_written(slice, action);
            if (!writeStatus) {
                if (!thisActionWrites)
                    // First slice encountered, so set status to field not written.
                    thisActionWrites = false;
                else if (*thisActionWrites == true)
                    // If a field was written previously, this returns false.
                    return false;
            } else {
                if (!thisActionWrites)
                    // first slice encountered, so set status to field written.
                    thisActionWrites = true;
                else if (*thisActionWrites == false)
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
        boost::optional<bool> foundPHVSource;
        // true if we have encountered an action data/constant source for one of the fields in the
        // packing.
        boost::optional<bool> foundADConstantSource;
        LOG6("\t\t    Action: " << act->name);
        BUG_CHECK(act->name != "act", "Action %1% should have been removed earlier", act->name);
        // For each field in packing:
        for (auto* f : packing) {
            boost::optional<bool> hasPHVSource = constraint_tracker.hasPHVSource(f, act);
            boost::optional<bool> hasADSource = constraint_tracker.hasActionDataOrConstantSource(f,
                    act);
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
