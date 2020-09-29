#include "bf-p4c/phv/pragma/pa_mutually_exclusive.h"

#include <string>
#include <numeric>

#include "lib/log.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

/// BFN::Pragma interface
const char *PragmaMutuallyExclusive::name = "pa_mutually_exclusive";
const char *PragmaMutuallyExclusive::description =
    "Specifies that the two fields/headers are mutually exclusive with each other.";
const char *PragmaMutuallyExclusive::help =
    "@pragma pa_mutually_exclusive [pipe] gress inst_1.node_1 inst_2.node_2\n"
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
    "option to do so. The gress value can be either ingress or egress. "
    "If the optional pipe value is provided, the pragma is applied only "
    "to the corresponding pipeline. If not provided, it is applied to "
    "all pipelines.";

bool PragmaMutuallyExclusive::preorder(const IR::BFN::Pipe* pipe) {
    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PragmaMutuallyExclusive::name)
            continue;

        auto& exprs = annotation->expr;

        if (!PHV::Pragmas::checkStringLiteralArgs(exprs)) {
            continue;
        }

        const unsigned min_required_arguments = 3;  // gress, node1, node2
        unsigned required_arguments = min_required_arguments;
        unsigned expr_index = 0;
        const IR::StringLiteral *pipe_arg = nullptr;
        const IR::StringLiteral *gress_arg = nullptr;

        if (!PHV::Pragmas::determinePipeGressArgs(exprs, expr_index,
                required_arguments, pipe_arg, gress_arg)) {
            continue;
        }

        if (!PHV::Pragmas::checkNumberArgs(annotation, required_arguments,
                min_required_arguments, true, PragmaMutuallyExclusive::name,
                "`gress', `node1', `node2'")) {
            continue;
        }

        if (!PHV::Pragmas::checkPipeApplication(annotation, pipe, pipe_arg)) {
            continue;
        }

        auto node1_ir = exprs[expr_index++]->to<IR::StringLiteral>();
        auto node2_ir = exprs[expr_index++]->to<IR::StringLiteral>();

        LOG4(" @pragma pa_mutually_exclusive's arguments << " << gress_arg->value << ", "
             << node1_ir->value << ", " << node2_ir->value);

        auto node1_name = gress_arg->value + "::" + node1_ir->value;
        auto node2_name = gress_arg->value + "::" + node2_ir->value;
        auto field1 = phv_i.field(node1_name);
        if (!field1) {
            PHV::Pragmas::reportNoMatchingPHV(pipe, node1_ir);
        }
        auto field2 = phv_i.field(node2_name);
        if (!field2) {
            PHV::Pragmas::reportNoMatchingPHV(pipe, node2_ir);
        }
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
