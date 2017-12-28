#include "action_phv_constraints.h"

int ActionPhvConstraints::current_action = 0;

Visitor::profile_t ActionPhvConstraints::init_apply(const IR::Node *root) {
    profile_t rv = Inspector::init_apply(root);
    current_action = 0;
    field_writes_to_actions.clear();
    action_to_writes.clear();
    write_to_reads_per_action.clear();
    read_to_writes_per_action.clear();
    return rv;
}

bool ActionPhvConstraints::preorder(const IR::MAU::Action *act) {
    auto *tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, false, false, tbl);
    ActionAnalysis::FieldActionsMap field_actions_map;
    aa.set_field_actions_map(&field_actions_map);
    act->apply(aa);
    for (auto &field_action : Values(field_actions_map)) {
        auto *write = phv.field(field_action.write.expr);
        if (write == nullptr)
            BUG("Action does not have a write?");
        field_writes_to_actions[write].insert(act);
        FieldOperation fw(write, current_action);
        if (field_action.name == "set")
            fw.flags |= FieldOperation::MOVE;
        else
            fw.flags |= FieldOperation::WHOLE_CONTAINER;
        fw.action_name = field_action.name;
        action_to_writes[act].insert(fw);
        for (auto &read : field_action.reads) {
            FieldOperation fr;
            fr.unique_action_id = current_action;
            if (read.type == ActionAnalysis::ActionParam::PHV) {
                fr.phv_used = phv.field(read.expr);
                read_to_writes_per_action[fr.phv_used][act].insert(write);
            } else if (read.type == ActionAnalysis::ActionParam::ACTIONDATA) {
                fr.ad = true;
            } else if (read.type == ActionAnalysis::ActionParam::CONSTANT) {
                fr.constant = true;
                LOG5("Action: " << act->name);
            } else {
                BUG("Read must either be of a PHV, action data, or constant."); }

            if (field_action.reads.size() > 1)
                fr.flags |= FieldOperation::ANOTHER_OPERAND;
            if (field_action.name == "set")
                fr.flags |= FieldOperation::MOVE;
            else
                fr.flags |= FieldOperation::WHOLE_CONTAINER;
            fr.action_name = field_action.name;
            write_to_reads_per_action[write][act].push_back(fr); } }

    current_action++;
    return true;
}

void ActionPhvConstraints::field_ordering(std::vector<PHV::AllocSlice>& slices) {
    ordered_map<PHV::AllocSlice, size_t> field_slices_to_writes;
    ordered_map<PHV::AllocSlice, size_t> field_slices_to_reads;
    for (auto sl : slices) {
        field_slices_to_writes[sl] = field_writes_to_actions[sl.field()].size();
        field_slices_to_reads[sl] = read_to_writes_per_action[sl.field()].size();
    }
    LOG6("\t\t\t\t\t\t\tField Ordering Map");
    for (auto sl : slices) {
        LOG6("\t\t\t\t\t\t\t" << sl << "\t" << field_slices_to_writes[sl] << "\t" <<
                field_slices_to_reads[sl]); }
}

void ActionPhvConstraints::sort(std::list<const PHV::SuperCluster::SliceList*>& slice_list) {
    auto SliceListComparator = [this](const PHV::SuperCluster::SliceList* l, const
            PHV::SuperCluster::SliceList* r) {
        auto l_reads = 0;
        auto l_writes = 0;
        auto r_reads = 0;
        auto r_writes = 0;

        for (auto& sl : *l) {
            l_reads += this->read_to_writes_per_action[sl.field()].size();
            l_writes += this->field_writes_to_actions[sl.field()].size(); }

        for (auto &sl : *r) {
            r_reads += this->read_to_writes_per_action[sl.field()].size();
            r_writes += this->field_writes_to_actions[sl.field()].size(); }

        if (l_writes < r_writes) {
            return l;
        } else if (l_writes > r_writes) {
            return r;
        } else {
            if (l_reads >= r_reads) {
                return l;
            } else {
                return r; } } };

    slice_list.sort(SliceListComparator);
}

void ActionPhvConstraints::sort(std::vector<PHV::FieldSlice>& slice_list) {
    std::sort(slice_list.begin(), slice_list.end(),
            [this](PHV::FieldSlice l, PHV::FieldSlice r) {
            auto l_reads = this->read_to_writes_per_action[l.field()].size();
            auto l_writes = this->field_writes_to_actions[l.field()].size();
            auto r_reads = this->read_to_writes_per_action[r.field()].size();
            auto r_writes = this->field_writes_to_actions[r.field()].size();

            if (l_writes != r_writes)
                return l_writes < r_writes;
            return l_reads >= r_reads; });
}

void ActionPhvConstraints::end_apply() {
    LOG5("*****Printing  ActionPhvConstraints Maps*****");
    printMapStates();
    LOG5("*****End Print ActionPhvConstraints Maps*****");
}

ActionPhvConstraints::NumContainers
ActionPhvConstraints::num_container_sources(
        const PHV::Allocation &alloc,
        PHV::Allocation::MutuallyLiveSlices container_state,
        const IR::MAU::Action* action,
        UnionFind<PHV::FieldSlice>& packing_constraints) {
    ordered_set<PHV::Container> containerList;
    size_t num_unallocated = 0;
    for (auto slice : container_state) {
        auto *field = slice.field();
        auto range = slice.field_slice();
        if (write_to_reads_per_action[field][action].size() == 0)
            LOG5("\t\t\t\tField " << field->name << " is not written in action " << action->name);
        for (auto operand : write_to_reads_per_action[field][action]) {
            if (operand.ad || operand.constant) continue;
            const PHV::Field* fieldRead = operand.phv_used;

            // assume aligned clusters. so, range for operands is the same as the range for
            // destination
            // xxx(deep): Except when the source slice is smaller than the destination slice, the
            // range should reflect the size of the smaller source slice
            // Insert all the source slices into the universe of packing_constraints
            if (range.size() > fieldRead->size) {
                le_bitrange range1 = StartLen(0, fieldRead->size);
                LOG6("\t\t\t\t\tInserting " << fieldRead->name << " [" << range1.lo << ", " <<
                        range1.hi << "] into copacking_constraints");
                packing_constraints.insert(PHV::FieldSlice(fieldRead, range1));
            } else {
                LOG6("\t\t\t\t\tInserting " << fieldRead->name << " [" << range.lo << ", " <<
                        range.hi << "] into copacking_constraints");
                packing_constraints.insert(PHV::FieldSlice(fieldRead, range)); }

            ordered_set<PHV::Container> per_source_containers;
            ordered_set<PHV::AllocSlice> per_source_slices = alloc.slices(fieldRead, range);
            for (auto slice : per_source_slices)
                per_source_containers.insert(slice.container());
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

//  Note: If both action data and constant are used in the same action as operands on the same
//  container, action data allocation folds them into one action data parameter to ensure a
//  legal Tofino action. Same is true when multiple action data and/or multiple constants are used
//  as operands on the same container in the same action.
bool ActionPhvConstraints::has_ad_or_constant_sources(std::vector<const PHV::Field*>& fields, const
        IR::MAU::Action* action) {
    for (auto field : fields) {
        for (auto operand : write_to_reads_per_action[field][action]) {
            if (operand.ad || operand.constant) {
                LOG5("\t\t\t\tField " << field->name << " written using action data/constant in "
                        "action " << action->name);
                return true; } } }
    return false;
}

int ActionPhvConstraints::unallocated_bits(PHV::Allocation::MutuallyLiveSlices slices,
        const PHV::Container c) const {
    int size_used = 0;
    for (auto slice : slices) {
        size_used += slice.width(); }
    if (int(c.size()) < size_used)
        LOG4("Total size of mutually live slices is greater than the size of the container");
    return (c.size() - size_used);
}

unsigned ActionPhvConstraints::container_operation_type(ordered_set<const IR::MAU::Action*>&
        actions, std::vector<const PHV::Field*>& fields) {
    for (auto *action : actions) {
        LOG5("\t\t\tChecking container operation type for action: " << action->name);
        unsigned type_of_operation = 0;
        size_t num_fields_not_written = 0;
        for (auto *f : fields) {
            boost::optional<FieldOperation> fw = is_written(action, f);
            if (!fw) {
                num_fields_not_written++;
            } else {
                if (fw->flags & FieldOperation::MOVE)
                    type_of_operation |= FieldOperation::MOVE;
                else if (fw->flags & FieldOperation::WHOLE_CONTAINER)
                    type_of_operation |= FieldOperation::WHOLE_CONTAINER;
                else
                    ::warning("Detected a write that is neither move nor whole container "
                            "operation."); } }

        // If there is a WHOLE_CONTAINER operation present, do not pack.
        // TODO: In the long run, we need to distinguish between bitwise operations and carry-based
        // operations. For the latter, we cannot pack. For the former, we should ensure that:
        // 1. There is no unwritten field in any action for the proposed packing
        // 2. There is no MOVE operation on any field in the proposed packing in the same action.
        if (type_of_operation & FieldOperation::WHOLE_CONTAINER) {
            if (num_fields_not_written) {
                LOG5("\t\t\t\tAction " << action->name << " uses a whole container operation but "
                        << num_fields_not_written << " fields are not written in this action.");
                return FieldOperation::WHOLE_CONTAINER; }

            if (type_of_operation & FieldOperation::MOVE) {
                LOG5("\t\t\t\tAction " << action->name << " uses both whole container and move "
                        "operations for fields in the proposed packing.");
                return FieldOperation::MIXED; }

            return FieldOperation::WHOLE_CONTAINER; } }

    return FieldOperation::MOVE;
}

void ActionPhvConstraints::pack_slices_together(
        const PHV::Allocation &alloc,
        PHV::Allocation::MutuallyLiveSlices& container_state,
        UnionFind<PHV::FieldSlice>& packing_constraints,
        const IR::MAU::Action* action,
        bool pack_unallocated_only  /*If true, only unallocated slices will be packed together*/) {
    if (pack_unallocated_only)
        LOG5("\t\t\t\t\tPack all unallocated slices together. All bits in container are occupied.");
    else
        LOG5("\t\t\t\t\tPack all slices together.");
    ordered_set<PHV::FieldSlice> pack_together;
    for (auto slice : container_state) {
        auto *field = slice.field();
        auto range = slice.field_slice();
        for (auto operand : write_to_reads_per_action[field][action]) {
            if (operand.ad || operand.constant) continue;
            const PHV::Field* fieldRead = operand.phv_used;
            if (pack_unallocated_only) {
                ordered_set<PHV::Container> containers;
                ordered_set<PHV::AllocSlice> per_source_slices = alloc.slices(fieldRead, range);
                for (auto slice : per_source_slices)
                    containers.insert(slice.container());
                if (containers.size() != 0) continue; }
            // If size of the source is less than the size of the destination slice, then range must
            // be reduced to the size of the smaller source FieldSlice
            if (range.size() > fieldRead->size) {
                le_bitrange range1 = StartLen(0, fieldRead->size);
                // Insert the slices to be packed together into the UnionFind structure
                LOG6("\t\t\t\t\tInserting " << fieldRead->name << " [" << range1.lo << ", " <<
                        range1.hi << "] into copacking_constraints");
                pack_together.insert(PHV::FieldSlice(fieldRead, range1));

            } else {
                // Insert the slices to be packed together into the UnionFind structure
                LOG6("\t\t\t\t\tInserting " << fieldRead->name << " [" << range.lo << ", " <<
                        range.hi << "] into copacking_constraints");
                pack_together.insert(PHV::FieldSlice(fieldRead, range)); } } }

    if (LOGGING(5)) {
        std::stringstream ss;
        for (auto slice : pack_together)
            ss << slice;
        LOG5("\t\t\t\t\tPack together: " << ss); }

    PHV::FieldSlice *firstSlice = nullptr;
    for (auto slice : pack_together) {
        if (firstSlice == nullptr) {
            LOG5("\t\t\t\t\t\tSetting first slice to  " << slice);
            firstSlice = new PHV::FieldSlice(slice.field(), slice.range()); }
        LOG5("\t\t\t\t\tUnion " << *firstSlice << " with " << slice);
        packing_constraints.makeUnion(*firstSlice, slice); }
}

boost::optional<UnionFind<PHV::FieldSlice>>
ActionPhvConstraints::can_pack(const PHV::Allocation& alloc, const PHV::AllocSlice& slice) {
    std::vector<PHV::AllocSlice> slices;
    slices.push_back(slice);
    return can_pack(alloc, slices);
}

boost::optional<UnionFind<PHV::FieldSlice>>
ActionPhvConstraints::can_pack(const PHV::Allocation& alloc, std::vector<PHV::AllocSlice>& slices) {
    PHV::Container c;
    bool container_uninitialized = true;
    int total_slice_width = 0;
    for (auto slice : slices) {
        total_slice_width += slice.width();
        if (container_uninitialized) {
            c = slice.container();
            continue; }
        BUG_CHECK(c == slice.container(), "Candidate field slices assigned to different "
                "containers"); }

    PHV::Allocation::MutuallyLiveSlices container_state = alloc.slicesByLiveness(c, slices);
    LOG6("\t\tExisting container state: ");
    for (auto slice : container_state)
        LOG6("\t\t\t" << slice);

    // Determine if there are any unallocated bits in the container corresponding to the given
    // mutually live slices
    int available_bits = unallocated_bits(container_state, c);
    LOG5("\t\tAvailable bits: " << available_bits);
    LOG5("\t\tRequired width: " << total_slice_width);

    // If no available bits, cannot pack
    if (!available_bits) {
        LOG5("\t\tContainer " << c << " is full");
       return boost::none; }

    // If bits available but lesser in width than the size requested, cannot pack
    // It is important to distinguish between these cases because we might want to slice
    // fields to enable packing in the future
    if (available_bits < total_slice_width) {
        LOG5("\t\tSlice(s) require " << total_slice_width << "b. Container " << c << " has " <<
                available_bits << "b available.");
        return boost::none; }

    // If existing container_state contains only one field which has a deparsed_no_pack() condition,
    // then one cannot pack any other field with it
    if (container_state.size() == 1) {
        LOG5("\t\tSingle slice container");
        for (auto existing_slice : container_state) {
            if (existing_slice.field()->no_pack()) {
                LOG5("\t\tExisting slice has a no pack property");
                return boost::none; } } }

    LOG5("\t\tChecking whether field slice(s) ");
    for (auto slice : slices)
        LOG5("\t\t\t" << slice.field()->name << " (" << slice.width() << "b)");
    LOG5("\t\tcan be packed into container " << container_state << " already containing " <<
            container_state.size() << " slices");

    field_ordering(slices);

    // Create candidate packing
    for (auto slice : slices)
        container_state.insert(slice);

    // Merge actions for all the candidate fields into a set
    std::vector<const PHV::Field *> fields;
    ordered_set<const IR::MAU::Action *> set_of_actions;
    for (auto slice : container_state) {
        auto field = slice.field();
        fields.push_back(field);
        set_of_actions.insert(field_writes_to_actions[field].begin(),
                field_writes_to_actions[field].end()); }

    // Debug info: print the names of all actions under consideration for these fields
    if (LOGGING(5)) {
        std::stringstream ss;
        ss << "\t\t\tActions to be checked are: ";
        for (auto *act : set_of_actions)
            ss << act->name << " ";
        LOG5(ss.str()); }

    // Check if actions on the packing candidates involve WHOLE_CONTAINER operations or a mix of
    // WHOLE_CONTAINER and MOVE operations (FieldOperation::MIXED)
    // If they do, the fields cannot be packed together
    unsigned cont_operation = container_operation_type(set_of_actions, fields);
    if (cont_operation == FieldOperation::WHOLE_CONTAINER || cont_operation ==
            FieldOperation::MIXED) {
        LOG5("\t\t\tCannot pack because of presence of whole container operations");
        return boost::none; }

    // Perform analysis related to number of sources for every action
    // Only MOVE operations get here
    // Store all the packing constraints induced by this possible packing in this UnionFind
    // structure.
    UnionFind<PHV::FieldSlice> copacking_constraints;
    for (auto &action : set_of_actions) {
        LOG5("\t\t\tNeed to check container sources now for action " << action->name);
        NumContainers sources = num_container_sources(alloc, container_state, action,
                copacking_constraints);
        bool has_ad_constant_sources = has_ad_or_constant_sources(fields, action);
        size_t num_source_containers = sources.num_allocated + sources.num_unallocated;

        // If there are less than 2 containers as sources (includes packing of the candidate field),
        // then packing is valid
        if (num_source_containers == 1) continue;
        if (num_source_containers == 0) continue;

        // If source fields have already been allocated and number of sources greater than 2, then
        // packing is not possible (TOO_MANY_SOURCES)
        if (sources.num_allocated > 2) {
            LOG5("\t\t\t\tAction " << action->name << " uses more than two PHV sources.");
            return boost::none; }

        // num_source_containers == 2 if execution gets here
        // If source fields have already been allocated and there are two PHV sources in addition to
        // an action data/constant sourcem then packing is not possible (TOO_MANY_SOURCES)
        if (sources.num_allocated == 2 && has_ad_constant_sources) {
            LOG5("\t\t\t\tAction " << action->name << " uses action data/constant in addition to "
                    "two PHV sources");
            return boost::none; }

        // Special packing constraints are introduced when number of source containers > 2 and
        // number of allocated containers is less than or equal to 2.
        // At this point of the loop, sources.num_allocated <= 2, sources.num_unallocated may be any
        // value.
        size_t num_fields_not_written_to = 0;
        size_t num_bits_not_written_to = available_bits - total_slice_width;
        for (auto field : fields) {
            boost::optional<FieldOperation> fw = is_written(action, field);
            if (!fw) num_fields_not_written_to++; }

        // If some field is not written to, then one of the sources for the move has to be the
        // container itself.
        // If sources.num_allocated == 2, this packing is not possible (TOO_MANY_SOURCES)
        if (num_fields_not_written_to && sources.num_allocated == 2) {
            LOG5("\t\t\t\tSome fields not written in action " << action->name << " will get "
                    "clobbered.");
            return boost::none; }

        // If some bits in the container are not written to, then one of the sources of the move has
        // to be the container itself.
        // If sources.num_allocated == 2, this packing is not possible (TOO_MANY_SOURCES)
        if (num_bits_not_written_to && sources.num_allocated == 2) {
            LOG5("\t\t\t\tSome unallocated bits in the container will get clobbered by writes in "
                    "action" << action->name);
            return boost::none; }

        // If sources.num_allocated == 2 and sources.num_unallocated == 0, then packing is valid and
        // no other packing constraints are induced
        if (sources.num_allocated == 2 && sources.num_unallocated == 0)
            continue;

        // If sources.num_allocated == 2 and sources.num_unallocated > 0, then all unallocated
        // fields have to be packed together with one of the allocated fields
        // xxx(deep): What's the best way to choose which allocated slice to pack with
        if (sources.num_allocated == 2 && sources.num_unallocated > 0) {
            pack_slices_together(alloc, container_state, copacking_constraints, action, false);
        }

        // If sources.num_allocated == 1 and sources.num_unallocated > 0, then
        if (sources.num_allocated <= 1 && sources.num_unallocated > 0) {
            if (num_fields_not_written_to || num_bits_not_written_to) {
                // Pack all slices together (both allocated and unallocated)
                // Can only have src2 as src1 is always the destination container itself
                pack_slices_together(alloc, container_state, copacking_constraints, action, false);
            } else {
                // For this case, sources need not be packed together as we may have (at most) 2
                // source containers
                if (num_source_containers == 2) continue;
                // Only pack unallocated slices together
                pack_slices_together(alloc, container_state, copacking_constraints, action, true); }
        }
    }

    return copacking_constraints;
}

boost::optional<ActionPhvConstraints::FieldOperation> ActionPhvConstraints::is_written(const
        IR::MAU::Action *act, const PHV::Field* field) {
    FieldOperation f(field);
    ordered_set<FieldOperation>::iterator location = action_to_writes[act].find(f);
    if (location == action_to_writes[act].end()) {
        LOG5("\t\t\t\tField " << field->name << " is not written in action " << act->name);
        return boost::optional<FieldOperation>{};
    } else {
        if (LOGGING(5)) {
            std::stringstream ss;
            ss << "\t\t\t\tField " << field->name << " is written in action " << act->name;
            if ((*location).flags & FieldOperation::MOVE)
                ss << " by a MOVE operation.";
            else
                ss << " by a WHOLE_CONTAINER operation.";
            LOG5(ss.str()); }
        return *location; }
}

void ActionPhvConstraints::printMapStates() {
    if (!LOGGING(5)) return;
    for (auto &act : action_to_writes) {
        LOG5("Action: " << act.first->name << " writes fields: ");
        for (auto &fi : act.second) {
            LOG5("\t\t" << fi.phv_used->name << ", written by a MOVE? " << (fi.flags ==
                        FieldOperation::MOVE)); } }

        for (auto &f : write_to_reads_per_action) {
            const PHV::Field* key = f.first;
            LOG5("Key field: " << key->name << " uses operands: ");
            for (auto &fi : f.second) {
                LOG5("\tAction: " << fi.first->name);
                for (auto &fii : fi.second) {
                    if (!fii.ad && !fii.constant)
                        LOG5("\t\tField: " << fii.phv_used->name);
                    else
                        LOG5("\t\tAction data."); } } }

        for (auto &f : read_to_writes_per_action) {
            const PHV::Field* key = f.first;
            LOG5("Key field: " << key->name << " is read by the field(s): ");
            for (auto &fi : f.second) {
                LOG5("\tAction: " << fi.first->name);
                for (auto &fii : fi.second)
                    LOG5("\t\tField: " << fii->name); } }
}

bool ActionPhvConstraints::is_in_field_writes_to_actions(cstring write, const IR::MAU::Action*
        action) const {
    const PHV::Field* write_field = phv.field(write);
    if (write_field == nullptr)
        return false;
    if (field_writes_to_actions.find(write_field) == field_writes_to_actions.end())
        return false;
    auto &action_set = field_writes_to_actions.at(write_field);
    if (action_set.find(action) == action_set.end())
        return false;
    return true;
}

bool ActionPhvConstraints::is_in_action_to_writes(const IR::MAU::Action* action, cstring write)
    const {
        const PHV::Field* write_field = phv.field(write);
        if (write_field == nullptr)
            return false;
        if (action_to_writes.find(action) == action_to_writes.end())
            return false;
        FieldOperation fo(write_field);
        auto &field_set = action_to_writes.at(action);
        if (field_set.find(fo) == field_set.end())
            return false;
        return true;
    }

bool ActionPhvConstraints::is_in_write_to_reads(cstring write, const IR::MAU::Action *act, cstring
        read) const {
    const PHV::Field* write_field = phv.field(write);
    const PHV::Field* read_field = phv.field(read);
    if (write_field == nullptr || read_field == nullptr)
        return false;
    if (write_to_reads_per_action.find(write_field) == write_to_reads_per_action.end())
        return false;
    auto &act_to_reads = write_to_reads_per_action.at(write_field);
    if (act_to_reads.find(act) == act_to_reads.end())
        return false;
    auto &field_set = act_to_reads.at(act);
    FieldOperation fr(read_field);
    if (std::find(field_set.begin(), field_set.end(), read_field) == field_set.end())
        return false;
    return true;
}
