#include "bf-p4c/phv/pragma/pa_deparser_zero.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

const std::vector<cstring>*
PragmaDeparserZero::supported_pragmas = new std::vector<cstring>{
    PHV::pragma::NOT_PARSED,
    PHV::pragma::NOT_DEPARSED,
    PHV::pragma::DISABLE_DEPARSE_ZERO
};

Visitor::profile_t PragmaDeparserZero::init_apply(const IR::Node* root) {
    notParsedFields.clear();
    notDeparsedFields.clear();
    disableDeparseZeroFields.clear();
    headerFields.clear();
    for (auto& f : phv_i)
        headerFields[f.header()].insert(&f);
    return Inspector::init_apply(root);
}

bool PragmaDeparserZero::preorder(const IR::BFN::Pipe* pipe) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir, cstring pragma_name) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("@pragma %1%'s arguments must be string literals, skipped", pragma_name);
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        cstring pragma_name = annotation->name.name;

        if (std::find(supported_pragmas->begin(), supported_pragmas->end(), pragma_name) ==
                supported_pragmas->end())
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 2) {
            ::warning("@pragma %1% must have 2 arguments, %2% are found, skipped", pragma_name,
                    exprs.size());
            continue; }

        // No need to check correct gress because CollectGlobalPragmas pass checks this for this
        // pragma.
        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field_ir = exprs[1]->to<IR::StringLiteral>();
        if (!check_pragma_string(gress, pragma_name) || !check_pragma_string(field_ir, pragma_name))
            continue;

        if (pragma_name == PHV::pragma::DISABLE_DEPARSE_ZERO)
            if (!PHV::Pragmas::gressValid(pragma_name, gress->value))
                continue;

        cstring header_name = gress->value + "::" + field_ir->value;
        LOG1("    Marking pragma " << pragma_name << " for header " << header_name);
        if (!headerFields.count(header_name))
            continue;
        for (const auto* f : headerFields.at(header_name))
            if (pragma_name == PHV::pragma::NOT_PARSED)
                notParsedFields.insert(f);
            else if (pragma_name == PHV::pragma::NOT_DEPARSED)
                notDeparsedFields.insert(f);
            else if (pragma_name == PHV::pragma::DISABLE_DEPARSE_ZERO)
                disableDeparseZeroFields.insert(f);
    }

    // Remove the fields specified with pa_disable_deparse_0_optimization from the notParsedFields
    // and notDeparsedFields.
    if (disableDeparseZeroFields.size() == 0) return true;
    for (const auto* f : disableDeparseZeroFields) {
        if (notParsedFields.count(f))
            notParsedFields.erase(f);
        if (notDeparsedFields.count(f))
            notDeparsedFields.erase(f);
    }
    return false;
}

void PragmaDeparserZero::end_apply() {
    if (!LOGGING(1)) return;
    if (notParsedFields.size() > 0) {
        LOG1("\tFields marked notParsed: ");
        for (const auto* f : notParsedFields)
            LOG1("\t  " << f);
    }
    if (notDeparsedFields.size() > 0) {
        LOG1("\n\tFields marked notDeparsed: ");
        for (const auto* f : notDeparsedFields)
            LOG1("\t  " << f);
    }
    if (disableDeparseZeroFields.size() > 0) {
        LOG1("\n\tFields marked disable deparse zero:");
        for (const auto* f : disableDeparseZeroFields)
            LOG1("\t  " << f);
    }
    return;
}

std::ostream& operator<<(std::ostream& out, const PragmaDeparserZero& pa_np) {
    std::stringstream logs;
    logs << "@pragma not_parsed specified for: " << std::endl;
    for (const auto* f : pa_np.getNotParsedFields())
        logs << "    " << f->name << std::endl;
    logs << std::endl << "@pragma not_deparsed specified for: " << std::endl;
    for (const auto* f : pa_np.getNotDeparsedFields())
        logs << "    " << f->name << std::endl;
    out << logs.str();
    return out;
}
