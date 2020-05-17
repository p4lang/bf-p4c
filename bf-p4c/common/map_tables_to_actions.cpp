#include "bf-p4c/common/map_tables_to_actions.h"

Visitor::profile_t MapTablesToActions::init_apply(const IR::Node* root) {
    tableToActionsMap.clear();
    defaultActions.clear();
    actionMap.clear();
    return Inspector::init_apply(root);
}

const PHV::Allocation::ActionSet
MapTablesToActions::getActionsForTable(const IR::MAU::Table* t) const {
    BUG_CHECK(t, "Null table encountered");
    PHV::Allocation::ActionSet emptySet;
    if (!tableToActionsMap.count(t)) return emptySet;
    return tableToActionsMap.at(t);
}

const PHV::Allocation::ActionSet
MapTablesToActions::getDefaultActionsForTable(const IR::MAU::Table* t) const {
    BUG_CHECK(t, "Null table encountered");
    PHV::Allocation::ActionSet emptySet;
    if (!defaultActions.count(t)) return emptySet;
    return defaultActions.at(t);
}

boost::optional<const IR::MAU::Table*>
MapTablesToActions::getTableForAction(const IR::MAU::Action* act) const {
    BUG_CHECK(act, "Null action encountered.");
    if (!actionMap.count(act)) return boost::none;
    return actionMap.at(act);
}

bool MapTablesToActions::preorder(const IR::MAU::Table* t) {
    for (auto kv : t->actions) {
        const auto* action = kv.second;
        tableToActionsMap[t].insert(action);
        actionMap[action] = t;
        LOG6("\tAdd action " << action->name << " in table " << t->name);
        if (action->miss_only() || action->init_default)
            defaultActions[t].insert(kv.second);
    }
    return true;
}

void MapTablesToActions::printTableActionsMap(
        const MapTablesToActions::TableActionsMap& tblActMap,
        cstring logMessage) const {
    LOG5("\t  " << logMessage);
    for (auto kv : tblActMap) {
        std::stringstream ss;
        ss << "\t\t" << kv.first->name << "\t:\t";
        for (const auto* act : kv.second)
            ss << act->name << " ";
        LOG5(ss.str());
    }
}

void MapTablesToActions::end_apply() {
    if (LOGGING(5)) {
        printTableActionsMap(tableToActionsMap, "Printing tables to actions map");
        printTableActionsMap(defaultActions, "Printing tables to default actions map");
        LOG5("Printing action to tables map");
        for (auto kv : actionMap)
            LOG5("\t" << kv.first->name << "\t:\t" << kv.second->name);
    }
}
