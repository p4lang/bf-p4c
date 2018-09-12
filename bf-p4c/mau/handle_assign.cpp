#include "handle_assign.h"


bool AssignActionHandle::ActionProfileImposedConstraints::preorder(const IR::MAU::ActionData *ad) {
    auto tbl = findContext<IR::MAU::Table>();

    std::set<cstring> actions;
    for (auto act : Values(tbl->actions)) {
        actions.insert(act->name);
    }

    if (profile_actions.count(ad) == 0) {
        profile_actions[ad] = actions;
        return false;
    }

    auto curr_actions = profile_actions.at(ad);
    std::set<cstring> intersect;
    std::set_intersection(actions.begin(), actions.end(), curr_actions.begin(), curr_actions.end(),
                          std::inserter(intersect, intersect.end()));
    std::set<cstring> difference;
    if (intersect.size() < actions.size()) {
        std::set_difference(actions.begin(), actions.end(), intersect.begin(), intersect.end(),
                            std::inserter(difference, difference.end()));
    } else if (intersect.size() < curr_actions.size()) {
        std::set_difference(curr_actions.begin(), curr_actions.end(), intersect.begin(),
                            intersect.end(), std::inserter(difference, difference.end()));
    }

    if (!difference.empty()) {
        cstring sep = "";
        cstring non_shared_actions = "";
        for (auto entry : difference) {
            non_shared_actions += sep + entry;
            sep = ", ";
        }
        error("%s: Currently in p4c, any table using an action profile is required to use "
              "the same actions, and the following actions don't appear in all table using "
              "the action profile %s : %s", ad->srcInfo, ad->name, non_shared_actions);
    }
    return false;
}

Visitor::profile_t AssignActionHandle::DetermineHandle::init_apply(const IR::Node *root) {
    profile_t rv = MauInspector::init_apply(root);
    handle_position = 0;
    return rv;
}

/**
 * Assign the action handle
 */
bool AssignActionHandle::DetermineHandle::preorder(const IR::MAU::Action *act) {
    auto tbl = findContext<IR::MAU::Table>();
    const IR::MAU::ActionData *ad = nullptr;
    for (auto ba : tbl->attached) {
        ad = ba->attached->to<IR::MAU::ActionData>();
        if (ad != nullptr)
            break;
    }

    if (ad == nullptr) {
        self.handle_assignments[act] = next_handle();
        return false;
    }

    auto &profile_map = profile_assignments[ad];
    if (profile_map.count(act->name)) {
        self.handle_assignments[act] = profile_map.at(act->name);
    } else {
        unsigned handle = next_handle();
        profile_map[act->name] = handle;
        self.handle_assignments[act] = handle;
    }
    return false;
}

/**
 * Modify the action with the action handle
 */
bool AssignActionHandle::AssignHandle::preorder(IR::MAU::Action *act) {
    auto orig_act = getOriginal()->to<IR::MAU::Action>();
    act->handle = self.handle_assignments.at(orig_act);
    return false;
}
