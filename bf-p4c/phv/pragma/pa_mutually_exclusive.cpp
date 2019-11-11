#include "bf-p4c/phv/pragma/pa_mutually_exclusive.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

/// BFN::Pragma interface
const char *PragmaMutuallyExclusive::name = "pa_mutually_exclusive";
const char *PragmaMutuallyExclusive::description =
    "Specifies that the two fields/headers are mutually exclusive with each other.";
const char *PragmaMutuallyExclusive::help =
    "@pragma pa_mutually_exclusive gress inst_1.node_1 inst_2.node_2\n"
    "+ attached to P4 header instances\n"
    "\n"
    "Specifies that the two indicated nodes which may be either single "
    "fields or simple headers can be considered mutually exclusive of "
    "one another. In the case of simple header nodes, the exclusivity "
    "applies to the fields of the header. "
    "PHV allocation uses field exclusivity to optimize container usage "
    "by overlaying mutually exclusive fields in the same container. "
    "This pragma does not guarantee that the mutually exclusive fields "
    "will occupy the same container.  It gives the compiler the "
    "option to do so. The gress value can be either ingress or egress.";

bool PragmaMutuallyExclusive::preorder(const IR::BFN::Pipe* pipe) {
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
        auto node1_ir = exprs[1]->to<IR::StringLiteral>();
        auto node2_ir = exprs[2]->to<IR::StringLiteral>();
        LOG4(" @pragma pa_mutually_exclusive's arguments << " << gress->value << ", "
             << node1_ir->value << ", " << node2_ir->value);

        if (!check_pragma_string(gress) || !check_pragma_string(node1_ir)
            || !check_pragma_string(node2_ir))
            continue;

        // check gress correct
        if (!PHV::Pragmas::gressValid("pa_mutually_exclusive", gress->value))
            continue;

        auto node1_name = gress->value + "::" + node1_ir->value;
        auto node2_name = gress->value + "::" + node2_ir->value;
        auto field1 = phv_i.field(node1_name);
        auto field2 = phv_i.field(node2_name);
        auto s_hdr1 = field1 ? nullptr : phv_i.simple_hdr(node1_name);
        auto s_hdr2 = field2 ? nullptr : phv_i.simple_hdr(node2_name);
        auto n1_flds = ordered_set<const PHV::Field*>();
        auto n2_flds = ordered_set<const PHV::Field*>();

        if (field1) {
            n1_flds.insert(field1);
        } else if (s_hdr1) {
            phv_i.get_hdr_fields(node1_name, n1_flds);

        } else {
            continue;
        }

        if (field2) {
            n2_flds.insert(field2);
        } else if (s_hdr2) {
            phv_i.get_hdr_fields(node2_name, n2_flds);

        } else {
            continue;
        }

        for (auto fld1 : n1_flds) {
            for (auto fld2 : n2_flds) {
                LOG4("Adding into mutually exclusive pairs: " << fld1->name << " <--> " <<
                     fld2->name);

                pa_mutually_exclusive_i[fld1].insert(fld2);
                pa_mutually_exclusive_i[fld2].insert(fld1);
            }
        }
    }
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
