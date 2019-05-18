#include "bf-p4c/phv/pragma/pa_mutually_exclusive.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

/// BFN::Pragma interface
const char *PragmaMutuallyExclusive::name = "pa_mutually_exclusive";
const char *PragmaMutuallyExclusive::description =
    "Specifies that the two fields are mutually exclusive with each other.";
const char *PragmaMutuallyExclusive::help =
    "@pragma pa_mutually_exclusive gress inst_1.field_1 inst_2.field_2\n"
    "+ attached to P4 header instances\n"
    "\n"
    "Specifies that the two indicated fields can be considered mutually "
    "exclusive of one another.  PHV allocation uses field exclusivity to "
    "optimize container usage by overlaying mutually exclusive fields in "
    "the same container.  This pragma does not guarantee that the two "
    "fields will occupy the same container.  It gives the compiler the "
    "option to do so.  The gress value can be either ingress or egress.";

bool PragmaMutuallyExclusive::preorder(const IR::BFN::Pipe* pipe) {
    if (disable_pragmas.count(PragmaMutuallyExclusive::name))
        return false;
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            ::warning("%1%", "@pragma pa_mutually_exclusive's arguments must be strings, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PragmaMutuallyExclusive::name)
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 3) {
            ::warning("@pragma pa_mutually_exclusive must "
                      "have 3 arguments, only %1% found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field1_ir = exprs[1]->to<IR::StringLiteral>();
        auto field2_ir = exprs[2]->to<IR::StringLiteral>();

        if (!check_pragma_string(gress) || !check_pragma_string(field1_ir)
            || !check_pragma_string(field2_ir))
            continue;

        // check gress correct
        if (!PHV::Pragmas::gressValid("pa_mutually_exclusive", gress->value))
            continue;

        auto field1_name = gress->value + "::" + field1_ir->value;
        auto field2_name = gress->value + "::" + field2_ir->value;
        auto field1 = phv_i.field(field1_name);
        auto field2 = phv_i.field(field2_name);

        if (!field1) {
            ::warning("@pragma pa_mutually_exclusive's argument "
                      "%1% does not match any phv fields, skipped", field1_name);
            continue; }
        if (!field2) {
            ::warning("@pragma pa_mutually_exclusive's argument "
                      "%1% does not match any phv fields, skipped", field2_name);
            continue; }
        pa_mutually_exclusive_i[field1].insert(field2);
        pa_mutually_exclusive_i[field2].insert(field1); }
    return false;
}

std::ostream& operator<<(std::ostream& out, const PragmaMutuallyExclusive& pa_me) {
    std::stringstream logs;
    logs <<  "Printing all fields marked mutually exclusive by @pragma pa_mutually_exclusive" <<
        std::endl;
    for (auto entry : pa_me.mutex_fields()) {
        for (auto f : entry.second) {
            logs << "Fields " << entry.first->name << " and " << f->name << " are marked mutually "
                "exclusive." << std::endl; } }
    out << logs.str();
    return out;
}
