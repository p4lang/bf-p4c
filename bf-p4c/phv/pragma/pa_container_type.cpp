#include "bf-p4c/phv/pragma/pa_container_type.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

bool PragmaContainerType::add_constraint(cstring field_name, cstring kind) {
    // check field name
    PHV::Field* field = phv_i.field(field_name);
    if (!field) {
        ::warning("@pragma pa_container_type's argument "
                  "%1% does not match any phv fields, skipped", field_name);
        return false; }
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
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("%1%", "@pragma pa_container_type's arguments "
                      "must be string literals, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PHV::pragma::CONTAINER_TYPE)
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 3) {
            ::warning("@pragma pa_atomic must "
                      "have 3 arguments, %1% are found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field_ir = exprs[1]->to<IR::StringLiteral>();
        auto container_type = exprs[2]->to<IR::StringLiteral>();

        if (!check_pragma_string(gress) || !check_pragma_string(field_ir) ||
            !check_pragma_string(container_type))
            continue;

        // check gress correct
        if (!PHV::Pragmas::gressValid("pa_container_type", gress->value))
            continue;

        auto field_name = gress->value + "::" + field_ir->value;
        LOG1("Adding container type " << container_type->value << " for " << field_name);
        add_constraint(field_name, container_type->value);
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
