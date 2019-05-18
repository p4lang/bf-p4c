#include "bf-p4c/phv/pragma/pa_no_overlay.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

/// BFN::Pragma interface
const char *PragmaNoOverlay::name = "pa_no_overlay";
const char *PragmaNoOverlay::description =
    "Specifies that the field can not be overlayed with any other field.";
const char *PragmaNoOverlay::help = "@pragma pa_no_overlay gress inst_1.field_1\n"
    "+ attached to P4 header instances\n"
    "\n"
    "Specifies that the indicated field cannot be overlayed with any other "
    "field. The gress value can be either ingress or egress.";

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
    if (disable_pragmas.count(PragmaNoOverlay::name))
        return false;

    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("%1%", "@pragma pa_no_overlay's arguments "
                      "must be string literals, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PragmaNoOverlay::name)
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
        if (!PHV::Pragmas::gressValid("pa_no_overlay", gress->value))
            continue;

        auto field_name = gress->value + "::" + field_ir->value;
        add_constraint(field_name);
    }

    // XXX(zma) tmp workaround to disable bridged residual checksum fields from being
    // overlaid. Proper bridged metadata overlay requires mutex analysis on ingress and
    // coordination of ingress deparser and egress parser (TODO).
    for (auto& nf : phv_i.get_all_fields()) {
        std::string f_name(nf.first.c_str());
        if (f_name.find("compiler_generated_meta") != std::string::npos
         && f_name.find("residual_checksum_") != std::string::npos) {
            fields.insert(&nf.second);
        }
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
