#include "bf-p4c/phv/pragma/pa_solitary.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

bool PragmaSolitary::preorder(const IR::BFN::Pipe* pipe) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("%1%", "@pragma pa_solitary's arguments "
                      "must be string literals, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PHV::pragma::SOLITARY)
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 2) {
            ::warning("@pragma pa_solitary must "
                      "have 2 arguments, %1% are found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field_ir = exprs[1]->to<IR::StringLiteral>();

        if (!check_pragma_string(gress) || !check_pragma_string(field_ir))
            continue;

        // check gress correct
        if (!PHV::Pragmas::gressValid("pa_solitary", gress->value))
            continue;

        // check field name
        auto field_name = gress->value + "::" + field_ir->value;
        auto field = phv_i.field(field_name);
        if (!field) {
            ::warning("@pragma pa_solitary's argument "
                      "%1% does not match any phv fields, skipped", field_name);
            continue; }

        // check if it is non-container-sized header field
        if (field->exact_containers() && (field->size != int(PHV::Size::b8)
                                          && field->size != int(PHV::Size::b16)
                                          && field->size != int(PHV::Size::b32))) {
            ::warning("@pragma pa_solitary's argument %1% can not be solitary, "
                      "because it is a deparsed header field"
                      " and it is not container-sized ", field_name);
            continue; }

        // set no_pack
        field->set_no_pack(true);
        LOG1("@pragma pa_solitary set " << field->name << " to be no_pack");
    }
    return true;
}
