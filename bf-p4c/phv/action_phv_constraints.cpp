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
            } else {
                BUG("Read must either be of a PHV, action data, or constant."); }

            if (field_action.reads.size() > 1)
                fr.flags |= FieldOperation::ANOTHER_OPERAND;
            if (field_action.name == "set")
                fr.flags |= FieldOperation::MOVE;
            else
                fr.flags |= FieldOperation::WHOLE_CONTAINER;
            write_to_reads_per_action[write][act].push_back(fr); } }

    current_action++;
    return true;
}

void ActionPhvConstraints::end_apply() {
    LOG3("*****Printing  ActionPhvConstraints Maps*****");
    printMapStates();
    LOG3("*****End Print ActionPhvConstraints Maps*****");
}

// TODO: Account for multiple containers per field
uint32_t ActionPhvConstraints::num_sources(std::vector <const PhvInfo::Field*> fields,
        const IR::MAU::Action* action) {
    ordered_set<PHV_Container *> containerList;
    uint32_t num_ad_sources = 0;
    LOG3("Fields size: " << fields.size());
    for (auto field : fields) {
        LOG3("Field name: " << field->name);
        if (write_to_reads_per_action[field][action].size() == 0)
            LOG3("Not written in this action");
        for (auto operand : write_to_reads_per_action[field][action]) {
            if (operand.ad) {
                LOG3("Found action data source");
                num_ad_sources++;
            } else if (operand.constant) {
                LOG3("Found constant");
                num_ad_sources++;
            } else {
                const PhvInfo::Field* fieldRead = operand.phv_used;
                    LOG3("Field read: " << fieldRead->name);
                    // TODO: What if container has not yet been allocated?
                    if (fieldRead->phv_containers().size() == 0)
                        LOG3("Container not assigned to PHV.");
                    LOG3("Number of containers read: " << fieldRead->phv_containers().size());
                    for (auto container : fieldRead->phv_containers()) {
                        LOG3("Inserting container " << container);
                        containerList.insert(container); } } } }

        // TODO: Take into account number of action data sources
        LOG3("Number of operands for " << action->name << ": " <<
                (containerList.size()));
        for (auto container : containerList)
            LOG3("Container: " << container);
        LOG3("Number of action data or constant operands: " << num_ad_sources);
        return (containerList.size());
    }

// TODO: Alignment constraints on fields
// TODO: Return constraints instead of boolean
// TODO: Distinguish between various non-move operations (only one operation may
// be performed on the same container)
// TODO: Handle cases where fields span more than one container
unsigned ActionPhvConstraints::can_cohabit(std::vector<const PhvInfo::Field*>& fields) {
    /* Merge actions for all the candidate fields into a set */
    ordered_set<const IR::MAU::Action *> set_of_actions;
    for (auto field : fields) {
        set_of_actions.insert(field_writes_to_actions[field].begin(),
                field_writes_to_actions[field].end()); }

    for (auto &action : set_of_actions) {
        LOG3("Action: " << action->name);
        uint32_t num_srcs = num_sources(fields, action);
        if (num_srcs == 1) {
            LOG3("One source detected");
            // TODO: Add check for similarity of the set operations
            continue;
        } else if (num_srcs == 0) {
            LOG3("Can there be zero sources?");
            continue;
        } else if (num_srcs > 2) {
            LOG3("Action " << action->name << " uses more than two sources");
            return ActionAnalysis::ContainerAction::TOO_MANY_SOURCES;
        } else {
            LOG3("Two sources");
            unsigned type_of_operation = 0;
            for (auto field : fields) {
                boost::optional<FieldOperation> fw = is_written(action, field);
                if (!fw) {
                    // One of the fields in the container is not written
                    // So, all other writes to this container in this action
                    // must be a move operation (bitmasks required)
                    LOG3("Field " << field->name << " is not written in action " << action->name);
                    return ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE;
                } else {
                    if (fw->flags & FieldOperation::MOVE) {
                        // The write to the current field under consideration is
                        // a set operation
                        type_of_operation |= FieldOperation::MOVE;
                        LOG3("Seeing move operation for field " << field->name);
                    } else if (fw->flags & FieldOperation::WHOLE_CONTAINER) {
                        // Operations on whole containers, so no partial
                        // container based operations possible
                        // TODO: Finer granularity analysis based on which whole
                        // container operation it is
                        // For e.g. add and and cannot be part of an action on
                        // the same container
                        type_of_operation |= FieldOperation::WHOLE_CONTAINER;
                        LOG3("Seeing non-move operation for field: " << field->name);
                    } else {
                        LOG3("Should this ever happen?" << field->name);
                        LOG3("type_of_operation: " << fw->flags); } } }

            if ((type_of_operation & FieldOperation::MOVE) && (type_of_operation &
                                FieldOperation::WHOLE_CONTAINER)) {
                LOG3("move and non-move operations seen together in action " << action->name);
                return ActionAnalysis::ContainerAction::MULTIPLE_CONTAINER_ACTIONS; } } }

    LOG3("can_cohabit did not detect any issues");
    return ActionAnalysis::ContainerAction::NO_PROBLEM;
}

boost::optional<ActionPhvConstraints::FieldOperation> ActionPhvConstraints::is_written(const
        IR::MAU::Action *act, const PhvInfo::Field* field) {
    FieldOperation f(field);
    LOG3("Trying to find: " << field->name);
    ordered_set<FieldOperation>::iterator location = action_to_writes[act].find(f);
    if (location == action_to_writes[act].end()) {
        LOG3("Did not find");
        return boost::optional<FieldOperation>{};
    } else {
        LOG3("Found " << (*location).phv_used->name);
        return *location; }
}

void ActionPhvConstraints::printMapStates() {
    if (!LOGGING(3)) return;
    for (auto &act : action_to_writes) {
        LOG3("Action: " << act.first->name << " writes fields: ");
        for (auto &fi : act.second) {
            LOG3("\t\t" << fi.phv_used->name << ", written by a MOVE? " << (fi.flags ==
                        FieldOperation::MOVE)); } }

        for (auto &f : write_to_reads_per_action) {
            const PhvInfo::Field* key = f.first;
            LOG3("Key field: " << key->name << " uses operands: ");
            for (auto &fi : f.second) {
                LOG3("\tAction: " << fi.first->name);
                for (auto &fii : fi.second) {
                    if (!fii.ad && !fii.constant)
                        LOG3("\t\tField: " << fii.phv_used->name);
                    else
                        LOG3("\t\tAction data."); } } }

        for (auto &f : read_to_writes_per_action) {
            const PhvInfo::Field* key = f.first;
            LOG3("Key field: " << key->name << " is read by the field(s): ");
            for (auto &fi : f.second) {
                LOG3("\tAction: " << fi.first->name);
                for (auto &fii : fi.second)
                    LOG3("\t\tField: " << fii->name); } }
}

bool ActionPhvConstraints::is_in_field_writes_to_actions(cstring write, const IR::MAU::Action*
        action) const {
    const PhvInfo::Field* write_field = phv.field(write);
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
        const PhvInfo::Field* write_field = phv.field(write);
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
    const PhvInfo::Field* write_field = phv.field(write);
    const PhvInfo::Field* read_field = phv.field(read);
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
