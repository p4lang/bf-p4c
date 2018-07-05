#include "bf-p4c/phv/pragma/pa_no_init.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

bool PragmaNoInit::preorder(const IR::BFN::Pipe* pipe) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("%1%", "@pragma pa_no_init's arguments "
                      "must be string literals, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PHV::pragma::NO_INIT)
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 2) {
            ::warning("@pragma pa_no_init must "
                      "have 2 arguments, %1% are found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field_ir = exprs[1]->to<IR::StringLiteral>();

        if (!check_pragma_string(gress) || !check_pragma_string(field_ir))
            continue;

        // check gress correct
        if (!PHV::Pragmas::gressValid("pa_no_init", gress->value))
            continue;

        auto field_name = gress->value + "::" + field_ir->value;
        const PHV::Field* field = phv_i.field(field_name);
        if (!field) {
            ::warning("@pragma pa_no_init's argument %1% does not match any phv fields, "
                      "skipped", field_name);
            continue; }

        if (!field->metadata) {
            ::warning("@pragma pa_no_init ignored for non-metadata field %1%", field_name);
            continue;
        }

        fields.insert(field);
        LOG1("@pragma pa_no_init set for " << field_name);
    }
    return true;
}

std::ostream& operator<<(std::ostream& out, const PragmaNoInit& pa_no) {
    std::stringstream logs;
    for (auto* f : pa_no.getFields())
        logs << "@pa_no_init specifies that " << f->name << " should be marked no_split" <<
            std::endl;
    out << logs.str();
    return out;
}
