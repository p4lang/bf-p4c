#ifndef EXTENSIONS_BF_P4C_COMMON_MAP_TABLES_TO_ACTIONS_H_
#define EXTENSIONS_BF_P4C_COMMON_MAP_TABLES_TO_ACTIONS_H_

#include "ir/ir.h"
#include "bf-p4c/phv/utils/utils.h"

/** Create maps of tables to associated actions and associated default actions.
  */
class MapTablesToActions : public Inspector {
 public:
    using TableActionsMap = ordered_map<const P4::IR::MAU::Table*, PHV::ActionSet>;
    using ActionTableMap = ordered_map<const P4::IR::MAU::Action*, const P4::IR::MAU::Table*>;

 private:
    /// tableToActionsMap[t] = Set of actions that can be invoked by table t.
    TableActionsMap tableToActionsMap;

    /// defaultActions[t] = Set of default actions for table t.
    TableActionsMap defaultActions;

    /// actionMap[act] = t, where t is the table from which act is invoked.
    ActionTableMap actionMap;

    profile_t init_apply(const P4::IR::Node* root) override;
    bool preorder(const P4::IR::MAU::Table* t) override;
    void end_apply() override;

    /// Pretty-print maps of type TableActionsMap.
    void printTableActionsMap(const TableActionsMap& tblActMap, cstring logMessage) const;

 public:
    /// @returns the set of actions that can be invoked for a table @p t.
    const PHV::ActionSet& getActionsForTable(const P4::IR::MAU::Table* t) const;

    /// @returns the set of possible default actions for table @p t.
    const PHV::ActionSet& getDefaultActionsForTable(const P4::IR::MAU::Table* t) const;

    /// @return the table from which @p act is invoked.
    std::optional<const P4::IR::MAU::Table*> getTableForAction(const P4::IR::MAU::Action* act) const;
};

#endif  /*  EXTENSIONS_BF_P4C_COMMON_MAP_TABLES_TO_ACTIONS_H_  */
