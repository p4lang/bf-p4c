#include "validate_actions.h"

#include "bf-p4c/mau/action_analysis.h"
#include "ir/ir.h"
#include "lib/log.h"

bool ValidateActions::preorder(const IR::MAU::Action *act) {
    auto tbl = findContext<IR::MAU::Table>();
    LOG4("ValidateActions for table: " << tbl->externalName());
    ActionAnalysis::FieldActionsMap field_actions_map;
    ActionAnalysis::ContainerActionsMap container_actions_map;
    ActionAnalysis aa(phv, phv_alloc, ad_alloc, tbl, false, false);  // action block is parallel.
    if (phv_alloc)
        aa.set_container_actions_map(&container_actions_map);
    else
        aa.set_field_actions_map(&field_actions_map);
    aa.set_error_verbose();
    aa.set_verbose();
    act->apply(aa);
    warning_found |= aa.warning_found();
    error_found |= aa.error_found();
    return false;
}

Visitor::profile_t ValidateActions::init_apply(const IR::Node *root) {
    profile_t rv = Inspector::init_apply(root);
    warning_found = false;
    return rv;
}

void ValidateActions::end_apply() {
    cstring error_message;
    if (phv_alloc)
        error_message = "PHV allocation creates an invalid container action within a Tofino ALU";
    else
        error_message = "Instruction selection creates an instruction that the rest of the "
                        "compiler cannot correctly interpret";
    if (error_found) {
        ::error(error_message);
    } else if (warning_found) {
        if (stop_compiler)
            ::error(error_message);
        else
            ::warning(error_message);
    }
}