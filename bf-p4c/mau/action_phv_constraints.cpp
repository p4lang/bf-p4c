#include "action_phv_constraints.h"
#include "action_analysis.h"

Visitor::profile_t ActionPhvConstraints::init_apply(const IR::Node *root) {
    profile_t rv = MauInspector::init_apply(root);
    shared_writes.clear();
    write_to_reads.clear();
    read_to_writes.clear();
    current_action = 0;
    return rv;
}

/** Builds the data structures to be used in the API function call */
bool ActionPhvConstraints::preorder(const IR::MAU::Action *act) {
    ActionAnalysis::FieldActionsMap field_actions_map;
    auto *tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, false, false, tbl);
    aa.set_field_actions_map(&field_actions_map);
    act->apply(aa);
    for (auto &field_action : Values(field_actions_map)) {
        auto *write = phv.field(field_action.write.expr);
        if (write == nullptr) {
            BUG("Action does not have a write?");
            continue;
        }
        for (auto &other_field_action : Values(field_actions_map)) {
            auto *other_write = phv.field(other_field_action.write.expr);
            if (other_write == nullptr) {
                BUG("Action does not have a write?");
                continue;
            }
            if (other_write == write) continue;
            shared_writes[write].insert(other_write);
        }
        for (auto &read : field_action.reads) {
            FieldRead fr;
            fr.unique_action_id = current_action;
            if (read.type == ActionAnalysis::ActionParam::PHV) {
                fr.phv_read = phv.field(read.expr);
                read_to_writes[fr.phv_read].insert(write);
            } else {
                fr.ad_or_constant = true;
            }
            if (field_action.reads.size() > 1)
                fr.flags |= FieldRead::ANOTHER_OPERAND;
            if (field_action.name == "set")
                fr.flags |= FieldRead::MOVE;
            else
                fr.flags |= FieldRead::SINGLE_CONTAINER;
            write_to_reads[write].push_back(fr);
        }
    }
    current_action++;
    return false;
}

/** For GTest functions.  Checks if the shared_writes ordered_map entry is valid or not
 */
bool ActionPhvConstraints::is_in_shared_writes(cstring write, cstring shared_write) const {
    auto *write_field = phv.field(write);
    auto *shared_write_field = phv.field(shared_write);
    if (write_field == nullptr || shared_write_field == nullptr)
        return false;
    if (shared_writes.find(write_field) == shared_writes.end())
        return false;
    auto &shared_writes_set = shared_writes.at(write_field);
    if (shared_writes_set.find(shared_write_field) == shared_writes_set.end())
        return false;
    return true;
}

/** For GTest functions.  Checks if the write_to_reads ordered_map entry is valid or not
 */
bool ActionPhvConstraints::is_in_write_to_reads(cstring write, cstring read) const {
    auto *write_field = phv.field(write);
    auto *read_field = phv.field(read);
    if (write_field == nullptr || (read_field == nullptr && read != "ad_or_constant"))
        return false;
    if (write_to_reads.find(write_field) == write_to_reads.end())
        return false;
    auto &read_vec = write_to_reads.at(write_field);
    for (auto field_read : read_vec) {
        if (read_field && field_read.phv_read == read_field)
            return true;
        if (read_field == nullptr && field_read.ad_or_constant)
            return true;
    }
    return false;
}

/** For GTest functions.  Checks if the read_to_writes ordered_map entry is valid or not
 */
bool ActionPhvConstraints::is_in_read_to_writes(cstring read, cstring write) const {
    auto *read_field = phv.field(read);
    auto *write_field = phv.field(write);
    if (read_field == nullptr || write_field == nullptr)
        return false;
    if (read_to_writes.find(read_field) == read_to_writes.end())
        return false;
    auto &writes_set = read_to_writes.at(read_field);
    if (writes_set.find(write_field) == writes_set.end())
        return false;
    return true;
}
