#include "bf-p4c/mau/handle_assign.h"
#include "lib/safe_vector.h"
#include "bf-p4c/mau/resource_estimate.h"


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

Visitor::profile_t AssignActionHandle::ValidateSelectors::init_apply(const IR::Node *root) {
    profile_t rv = MauInspector::init_apply(root);
    selector_keys.clear();
    initial_table.clear();
    return rv;
}

bool AssignActionHandle::ValidateSelectors::preorder(const IR::MAU::Selector *sel) {
    if (findContext<IR::MAU::StatefulAlu>())
        return false;
    auto tbl = findContext<IR::MAU::Table>();
    safe_vector<PHV::FieldSlice> field_slice_vec;

    for (auto ixbar_read : tbl->match_key) {
        le_bitrange field_bits = {0, 0};
        if (!ixbar_read->for_selection())
            continue;
        auto *field = phv.field(ixbar_read->expr, &field_bits);
        if (field == nullptr) {
            ::error("%s: Can currently only handle PHV fields on selection only, and selector "
                    "%s has a non-field key on table %s", sel->srcInfo, sel->name, tbl->name);
            return false;
        }
        field_slice_vec.emplace_back(field, field_bits);
    }

    if (field_slice_vec.empty()) {
        ::error("%s: On Table %s, the Selector %s is provided no keys", sel->srcInfo, tbl->name,
                sel->name);
        return false;
    }

    auto sel_entry = selector_keys.find(sel);
    if (sel_entry != selector_keys.end() &&
        sel->max_pool_size > StageUseEstimate::SINGLE_RAMLINE_POOL_SIZE) {
        /**
         * Due to the register rams.match.merge.mau_meter_alu_to_logical_map being an OXBar,
         * one can only assign a single logical table to a wide hash mod.  Thus, a selector
         * that requires a hash mod cannot be shared
         */
        ::error("%s: The selector %s cannot be shared between tables %s and %s, because "
                "it requires a max pool size of %d.  In order to share a selector on Barefoot "
                "HW, the max pool size must be %d", sel->srcInfo, sel->name, tbl->name,
                initial_table.at(sel), sel->max_pool_size,
                StageUseEstimate::SINGLE_RAMLINE_POOL_SIZE);
    }

    if (sel_entry == selector_keys.end()) {
        selector_keys[sel] = field_slice_vec;
        initial_table[sel] = tbl;
    } else {
        auto sel_slice_vec = sel_entry->second;
        if (sel_slice_vec != field_slice_vec) {
            ::error("%s: The key for selector %s on table %s does not match the key for the "
                    "selector on table %s.  Barefoot requires the selector key to be identical "
                    "per selector", sel->srcInfo, sel->name, tbl->name, initial_table.at(sel));
        }
    }
    return false;
}
