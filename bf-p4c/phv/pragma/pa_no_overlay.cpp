#include "bf-p4c/phv/pragma/pa_no_overlay.h"

#include <string>
#include <numeric>

#include "lib/log.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "bf-p4c/arch/bridge_metadata.h"

/// BFN::Pragma interface
const char *PragmaNoOverlay::name = "pa_no_overlay";
const char *PragmaNoOverlay::description =
    "Specifies that the field can not be overlayed with any other field.";
const char *PragmaNoOverlay::help = "@pragma pa_no_overlay [pipe] gress inst_1.field_1\n"
    "+ attached to P4 header instances\n"
    "\n"
    "Specifies that the indicated field cannot be overlayed with any other "
    "field. The gress value can be either ingress or egress. "
    "If the optional pipe value is provided, the pragma is applied only "
    "to the corresponding pipeline. If not provided, it is applied to "
    "all pipelines.";

bool PragmaNoOverlay::add_constraint(cstring field_name) {
    // check field name
    auto field = phv_i.field(field_name);
    if (!field) {
        ::warning("@pragma pa_no_overlay's argument "
                  "%1% does not match any phv fields, skipped", field_name);
        return false; }

    fields.insert(field);
    return true;
}

bool PragmaNoOverlay::preorder(const IR::MAU::Instruction* inst) {
    // XXX(Deep): Until we handle concat operations in the backend properly (by adding metadata
    // fields with concat operations to a slice list, also containing padding fields that must be
    // initialized to 0), we have to disable overlay for any field used in concat operations (concat
    // operations that survive in the backend).
    if (inst->operands.empty()) return true;
    for (auto* operand : inst->operands) {
        if (!operand->is<IR::Concat>()) continue;
        const PHV::Field* f = phv_i.field(operand);
        if (f) {
            add_constraint(f->name);
            LOG1("\tAdding pa_no_overlay on " << f->name << " because of a concat "
                 "operation.");
        }
    }
    return true;
}

bool PragmaNoOverlay::preorder(const IR::BFN::Pipe* pipe) {
    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PragmaNoOverlay::name)
            continue;

        auto& exprs = annotation->expr;

        if (!PHV::Pragmas::checkStringLiteralArgs(exprs)) {
            continue;
        }

        const unsigned min_required_arguments = 2;  // gress, field
        unsigned required_arguments = min_required_arguments;
        unsigned expr_index = 0;
        const IR::StringLiteral *pipe_arg = nullptr;
        const IR::StringLiteral *gress_arg = nullptr;

        if (!PHV::Pragmas::determinePipeGressArgs(exprs, expr_index,
                required_arguments, pipe_arg, gress_arg)) {
            continue;
        }

        if (!PHV::Pragmas::checkNumberArgs(annotation, required_arguments,
                min_required_arguments, true, PragmaNoOverlay::name,
                "`gress', `field'")) {
            continue;
        }

        if (!PHV::Pragmas::checkPipeApplication(annotation, pipe, pipe_arg)) {
            continue;
        }

        auto field_ir = exprs[expr_index++]->to<IR::StringLiteral>();

        auto field_name = gress_arg->value + "::" + field_ir->value;
        add_constraint(field_name);
    }

    // XXX(zma) tmp workaround to disable bridged residual checksum fields from being
    // overlaid. Proper bridged metadata overlay requires mutex analysis on ingress and
    // coordination of ingress deparser and egress parser (TODO).
    for (auto& nf : phv_i.get_all_fields()) {
        std::string f_name(nf.first.c_str());
        if (f_name.find(BFN::COMPILER_META) != std::string::npos
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
