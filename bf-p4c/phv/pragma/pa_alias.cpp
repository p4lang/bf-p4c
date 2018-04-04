#include "pa_alias.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

Visitor::profile_t PragmaAlias::init_apply(const IR::Node* root) {
    pa_alias_i.clear();
    fieldsWithExpressions.clear();
    return Inspector::init_apply(root);
}

bool PragmaAlias::preorder(const IR::Expression* expr) {
    const PHV::Field* f = phv_i.field(expr);
    if (!f) return true;
    fieldsWithExpressions[f->id] = true;
    return true;
}

void PragmaAlias::postorder(const IR::BFN::Pipe* pipe) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            ::warning("%1%", "@pragma pa_alias's arguments must be strings, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PHV::pragma::ALIAS)
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 3) {
            ::warning("@pragma pa_alias must "
                      "have 3 arguments, only %1% found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field1_ir = exprs[1]->to<IR::StringLiteral>();
        auto field2_ir = exprs[2]->to<IR::StringLiteral>();

        // check gress correct
        if (!check_pragma_string(gress) || !check_pragma_string(field1_ir)
            || !check_pragma_string(field2_ir))
            continue;

        if (gress->value != "ingress" && gress->value != "egress") {
            ::warning("@pragma pa_alias's first argument "
                      "must be either ingress/egress, instead of %1%, skipped", gress);
            continue; }

        auto field1_name = gress->value + "::" + field1_ir->value;
        auto field2_name = gress->value + "::" + field2_ir->value;
        auto field1 = phv_i.field(field1_name);
        auto field2 = phv_i.field(field2_name);

        if (!field1) {
            ::warning("@pragma pa_alias's argument "
                      "%1% does not match any phv fields, skipped", field1_name);
            continue; }
        if (!field2) {
            ::warning("@pragma pa_alias's argument "
                      "%1% does not match any phv fields, skipped", field2_name);
            continue; }

        if (field1->size != field2->size) {
            ::warning("@pragma pa_alias ignored because of differing field sizes: %1% "
                      "(%2%b) and %3% (%4%b)", field1->name, field1->size, field2->name,
                      field2->size);
            continue; }

        if (pa_alias_i.count(field1)) {
            ::warning("@pragma pa_alias for fields %1% and %2% ignored because "
                      "field %1% already aliases with %3%", field1_name, field2_name,
                      pa_alias_i[field1]->name);
            continue; }

        if (pa_alias_i.count(field2)) {
            ::warning("@pragma pa_alias for fields %1% and %2% ignored because "
                      "field %1% already aliases with %3%", field2_name, field1_name,
                      pa_alias_i[field2]->name);
            continue; }

        if (field1->isPacketField() && field2->isPacketField())
            ::warning("@pragma pa_alias does not support aliasing of two header fields %1% and %2%",
                      field1_name, field2_name);

        if (field2->metadata && !field1->metadata) {
            pa_alias_i[field2] = field1;
            continue; }

        if (field1->metadata && !field2->metadata) {
            pa_alias_i[field1] = field2;
            continue; }

        // When the aliasing relationship is between a metadata and a header field, the header field
        // is chosen as the alias destination. When the aliasing relationship is between two
        // metadata fields and one of those metadata fields is not used in an IR::Expression object,
        // then the other metadata field is chosen as the alias destination.
        if (field1->metadata && field2->metadata) {
            bool field1Expr = fieldsWithExpressions[field1->id];
            bool field2Expr = fieldsWithExpressions[field2->id];
            if (!field1Expr && field2Expr)
                pa_alias_i[field1] = field2;
            else if (field1Expr && !field2Expr)
                pa_alias_i[field2] = field1;
            else if (field1Expr && field2Expr)
                pa_alias_i[field1] = field2;
            else
                ::warning("@pragma pa_alias ignored because no uses found for fields %1% and %2%",
                          field1_name, field2_name);
            continue; }

        ::warning("@pragma pa_alias does not support alias of fields %1% and %2%", field1_name,
                field2_name);
    }
    LOG1("Processed " << pa_alias_i.size() << " pragmas");
}

void PragmaAlias::end_apply() {
    for (auto kv : pa_alias_i)
        phv_i.setAliasEntry(kv.first->name, kv.second->name);
    LOG1(*this);
}

std::ostream& operator<<(std::ostream& out, const PragmaAlias& pa_a) {
    std::stringstream logs;
    logs <<  "Printing fields marked as an alias by @pragma pa_alias" << std::endl;
    for (auto kv : pa_a.alias_fields()) {
        logs << "ALIAS " << kv.first->name << " (" << kv.first->size << "b) -> " << kv.second->name
             << " (" << kv.second->size << "b)" << std::endl; }
    out << logs.str();
    return out;
}
