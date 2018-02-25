#include "bf-p4c/phv/pragma/pa_atomic.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

bool PragmaAtomic::preorder(const IR::BFN::Pipe* pipe) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("%1%", "@pragma pa_atomic's arguments "
                      "must be string literals, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PHV::pragma::ATOMIC)
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 2) {
            ::warning("@pragma pa_atomic must "
                      "have 2 arguments, %1% are found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field_ir = exprs[1]->to<IR::StringLiteral>();

        if (!check_pragma_string(gress) || !check_pragma_string(field_ir))
            continue;

        // check gress correct
        if (gress->value != "ingress" && gress->value != "egress") {
            ::warning("@pragma pa_atomic's first argument "
                      "must be either ingress/egress, instead of %1%, skipped", gress);
            continue; }

        // check field name
        auto field_name = gress->value + "::" + field_ir->value;
        auto field = phv_i.field(field_name);
        if (!field) {
            ::warning("@pragma pa_atomic's argument "
                      "%1% does not match any phv fields, skipped", field_name);
            continue; }

        // Make sure the field can fit into an available container fully
        if (field->size > int(PHV::Size::b32)) {
            ::warning("@pragma pa_atomic's argument %1% can not be atomic, "
                      "because the size of field is greater than the size of "
                      "the largest container", field_name);
            continue; }

        // set no_pack
        fields.insert(field);
        field->set_no_split(true);
        LOG1("@pragma pa_atomic set " << field->name << " to be no_split");
    }
    return true;
}

std::ostream& operator<<(std::ostream& out, const PragmaAtomic& pa_a) {
    std::stringstream logs;
    for (auto* f : pa_a.getFields())
        logs << "@pa_atomic specifies that " << f->name << " should be marked no_split" <<
            std::endl;
    out << logs.str();
    return out;
}
