#include "bf-p4c/phv/pragma/pa_no_overlay.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

bool PragmaNoOverlay::add_constraint(cstring field_name) {
    // check field name
    auto field = phv_i.field(field_name);
    if (!field) {
        ::warning("@pragma pa_no_overlay's argument "
                  "%1% does not match any phv fields, skipped", field_name);
        return false; }

    // set no_pack
    fields.insert(field);
    return true;
}

bool PragmaNoOverlay::preorder(const IR::BFN::Pipe* pipe) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("%1%", "@pragma pa_no_overlay's arguments "
                      "must be string literals, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PHV::pragma::NO_OVERLAY)
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 2) {
            ::warning("@pragma pa_no_overlay must "
                      "have 2 arguments, %1% are found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field_ir = exprs[1]->to<IR::StringLiteral>();

        if (!check_pragma_string(gress) || !check_pragma_string(field_ir))
            continue;

        // check gress correct
        if (gress->value != "ingress" && gress->value != "egress") {
            ::warning("@pragma pa_no_overlay's first argument "
                      "must be either ingress/egress, instead of %1%, skipped", gress);
            continue; }

        auto field_name = gress->value + "::" + field_ir->value;
        add_constraint(field_name);
    }

    return true;
}

std::ostream& operator<<(std::ostream& out, const PragmaNoOverlay& pa_no) {
    std::stringstream logs;
    for (auto* f : pa_no.getFields())
        logs << "@pa_no_overlay specifies that " << f->name << " should not be overlaid" <<
            std::endl;
    out << logs.str();
    return out;
}
