#include "bf-p4c/phv/pragma/pa_no_init.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

/// BFN::Pragma interface
const char *PragmaNoInit::name = "pa_no_init";
const char *PragmaNoInit::description =
    "Specifies that the field does not require initialization.";
const char *PragmaNoInit::help = "@pragma pa_no_init gress inst_name.field_name\n"
    "+ attached to P4 header instances\n"
    "\n"
    "Specifies that the indicated metadata field does not require "
    "initialization to 0 before its first use because the control plane "
    "guarantees that, in cases where this field's value is needed, it will "
    "always be written before it is read.\n"
    "\n"
    "Use this pragma if your program contains logic to ensure that it only "
    "evaluates this field's value when executing control paths in which a "
    "meaningful value has been written to the field, whereas for other "
    "control paths your program may read from the field but does not care "
    "what value appears there.  For such programs, the compiler cannot "
    "determine that the control plane program logic guarantees a write "
    "before a desired read.  This indeterminacy occurs when some control "
    "paths exist that require reading from the field before writing to it, "
    "while other control paths result in the field being read even though "
    "it was not written with a meaningful value, but in these latter "
    "control paths the program does not care what value appears in the "
    "field.\n"
    "\n"
    "The pragma is ignored if the field’s allocation does not require "
    "initialization.  It is also ignored if it is attached to any "
    "field other than a metadata field.  The gress value can be either "
    "ingress or egress.  Use this pragma with care.  If that unexpected "
    "control flow path is exercised, the field will have an unknown value.";

bool PragmaNoInit::preorder(const IR::BFN::Pipe* pipe) {
    if (disable_pragmas.count(PragmaNoInit::name))
        return false;

    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("%1%", "@pragma pa_no_init's arguments "
                      "must be string literals, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PragmaNoInit::name)
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
