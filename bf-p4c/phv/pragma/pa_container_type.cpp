#include "bf-p4c/phv/pragma/pa_container_type.h"

#include <string>
#include <numeric>

#include "lib/log.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

/// BFN::Pragma interface
const char *PragmaContainerType::name = "pa_container_type";
const char *PragmaContainerType::description =
    "Forces the allocation of a field in the specified container type.";
const char *PragmaContainerType::help = "??";  // FIXME

bool PragmaContainerType::add_constraint(const IR::BFN::Pipe* pipe,
        const IR::Expression* expr, cstring field_name, cstring kind) {
    // check field name
    PHV::Field* field = phv_i.field(field_name);
    if (!field) {
        PHV::Pragmas::reportNoMatchingPHV(pipe, expr, field_name);
        return false;
    }
    if (kind == "mocha") {
        field->set_mocha_candidate(true);
        field->set_dark_candidate(false);
    } else if (kind == "dark") {
        field->set_mocha_candidate(false);
        field->set_dark_candidate(true);
    } else if (kind == "normal") {
        field->set_mocha_candidate(false);
        field->set_dark_candidate(false);
    } else if (kind == "tagalong") {
        ::warning("@prama pa_container_type currently does not support tagalong containers, "
                  "skipped", field_name);
        return false;
    } else {
        ::warning("@pragma pa_container_type's argument %1% does not match any valid container "
                  "types, skipped", field_name);
        return false;
    }
    fields[field] = kind;
    return true;
}

bool PragmaContainerType::preorder(const IR::BFN::Pipe* pipe) {
    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PragmaContainerType::name)
            continue;

        auto& exprs = annotation->expr;

        if (!PHV::Pragmas::checkStringLiteralArgs(exprs)) {
            continue;
        }

        const unsigned min_required_arguments = 3;  // gress, field, type
        unsigned required_arguments = min_required_arguments;
        unsigned expr_index = 0;
        const IR::StringLiteral *pipe_arg = nullptr;
        const IR::StringLiteral *gress_arg = nullptr;

        if (!PHV::Pragmas::determinePipeGressArgs(exprs, expr_index,
                required_arguments, pipe_arg, gress_arg)) {
            continue;
        }

        if (!PHV::Pragmas::checkNumberArgs(annotation, required_arguments,
                min_required_arguments, true, PragmaContainerType::name,
                "`gress', `field', `type'")) {
            continue;
        }

        if (!PHV::Pragmas::checkPipeApplication(annotation, pipe, pipe_arg)) {
            continue;
        }

        auto field_ir = exprs[expr_index++]->to<IR::StringLiteral>();
        auto container_type = exprs[expr_index++]->to<IR::StringLiteral>();

        auto field_name = gress_arg->value + "::" + field_ir->value;
        LOG1("Adding container type " << container_type->value << " for " << field_name);
        add_constraint(pipe, field_ir, field_name, container_type->value);
    }
    return true;
}

std::ostream& operator<<(std::ostream& out, const PragmaContainerType& pa_ct) {
    std::stringstream logs;
    for (auto kv : pa_ct.getFields())
        logs << "@pa_container_type specifies that " << kv.first->name << " should be allocated to "
            "a " << kv.second << " container." << std::endl;
    out << logs.str();
    return out;
}
