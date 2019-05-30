#include "pa_alias.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

/// BFN::Pragma interface
const char *PragmaAlias::name = "pa_alias";
const char *PragmaAlias::description =
    "Specifies that two fields are aliased";
const char *PragmaAlias::help =
    "@pragma pa_alias gress inst_1.field_name_1 inst_2.field_name_2\n"
    "+ attached to P4 header instances\n"
    "\n"
    "Specifies that the two packet and/or metadata field instances are to "
    "be considered as aliases to one another.  Use this pragma with care, "
    "as it merges the constraints of both fields.  The gress value can be "
    "either ingress or egress.  The two fields must be the same bit width. "
    "A field can only be aliased with one other field currently.";

Visitor::profile_t PragmaAlias::init_apply(const IR::Node* root) {
    aliasMap.clear();
    fieldsWithExpressions.clear();
    return Inspector::init_apply(root);
}

bool PragmaAlias::preorder(const IR::Expression* expr) {
    const PHV::Field* f = phv_i.field(expr);
    if (!f) return true;
    fieldsWithExpressions[f->id] = true;
    return true;
}

bool PragmaAlias::addAlias(
        const PHV::Field* field1,
        const PHV::Field* field2,
        bool suppressWarning) {
    if (aliasMap.count(field1->name)) {
        WARN_CHECK(suppressWarning,
                "@pragma pa_alias for fields %1% and %2% ignored because "
                "field %1% already aliases with %3%",
                field1->name, field2->name, aliasMap[field1->name].field);
        return false; }

    if (aliasMap.count(field2->name)) {
        WARN_CHECK(suppressWarning,
                "@pragma pa_alias for fields %1% and %2% ignored because "
                "field %1% already aliases with %3%",
                field2->name, field1->name, aliasMap[field2->name].field);
        return false; }

    if (field1->isPacketField() && field2->isPacketField()) {
        WARN_CHECK(suppressWarning,
                "@pragma pa_alias does not support aliasing of two packet header fields "
                "%1% and %2%",
                field1->name, field2->name);
        return false;
    }

    const PHV::Field* aliasSrc = nullptr;
    const PHV::Field* aliasDest = nullptr;
    if (field2->metadata && !field1->metadata) {
        aliasSrc = field2;
        aliasDest = field1;
    } else if (field1->metadata && !field2->metadata) {
        aliasSrc = field1;
        aliasDest = field2;
    } else if (field1->metadata && field2->metadata) {
        // When the aliasing relationship is between a metadata and a header field, the header field
        // is chosen as the alias destination. When the aliasing relationship is between two
        // metadata fields and one of those metadata fields is not used in an IR::Expression object,
        // then the other metadata field is chosen as the alias destination.
        bool field1Expr = fieldsWithExpressions[field1->id];
        bool field2Expr = fieldsWithExpressions[field2->id];
        if (!field1Expr && field2Expr) {
            aliasSrc = field1;
            aliasDest = field2;
        } else if (field1Expr && !field2Expr) {
            aliasSrc = field2;
            aliasDest = field1;
        } else if (field1Expr && field2Expr) {
            if (field1->size != field2->size)
                aliasSrc = (field1->size < field2->size) ? field1 : field2;
            else
                aliasSrc = (field1->alignment == boost::none) ? field1 : field2;
            aliasDest = (aliasSrc == field1) ? field2 : field1;
        } else {
            WARN_CHECK(suppressWarning,
                    "@pragma pa_alias ignored because no uses found for fields %1% and %2%",
                    field1->name, field2->name);
            return false;
        }
    }
    BUG_CHECK(aliasDest && aliasSrc, "Internal compiler error: Did not calculate aliasDest and "
            "aliasSrc");
    if (aliasSrc->size > aliasDest->size) {
        WARN_CHECK(suppressWarning,
                "@pragma pa_alias ignored because metadata field %1% is larger than the "
                "packet field %2%",
                aliasSrc->size, aliasDest->size);
        return false;
    }
    // If the field to be replaced has an alignment that is different from the field replacing it,
    // then do not do that alias (might create conflicting alignment requirements).
    if (aliasSrc->alignment != boost::none) {
        if (aliasDest->alignment == boost::none) {
            WARN_CHECK(suppressWarning,
                    "@pragma pa_alias ignored because metadata field %1% has alignment %2%, "
                    "while packet field %3% has no alignment requirement",
                    aliasSrc->name, aliasSrc->alignment->align, aliasDest->name);
            return false;
        } else if (*(aliasDest->alignment) != *(aliasSrc->alignment)) {
            WARN_CHECK(suppressWarning,
                    "@pragma pa_alias ignored because metadata field %1% has alignment %2%, "
                    "while packet field %3% has alignment %4%", aliasSrc->name,
                    aliasSrc->alignment->align, aliasDest->name, aliasDest->alignment->align);
            return false;
        }
    }
    if (aliasDest && aliasSrc) {
        aliasMap[aliasSrc->name] = { aliasDest->name, boost::none };
        return true;
    }
    return false;
}

void PragmaAlias::postorder(const IR::BFN::Pipe* pipe) {
    if (disable_pragmas.count(PragmaAlias::name))
        return;
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            ::warning("%1%", "@pragma pa_alias's arguments must be strings, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PragmaAlias::name)
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

        if (!check_pragma_string(gress) || !check_pragma_string(field1_ir)
            || !check_pragma_string(field2_ir))
            continue;

        // check gress correct
        if (!PHV::Pragmas::gressValid("pa_alias", gress->value))
            continue;

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

        if (addAlias(field1, field2))
            LOG3("\t  Added alias between fields " << field1->name << " and " << field2->name);
    }
    LOG1("Processed " << aliasMap.size() << " pragmas");
}

std::ostream& operator<<(std::ostream& out, const PragmaAlias& pa_a) {
    std::stringstream logs;
    logs <<  "Printing fields marked as an alias by @pragma pa_alias" << std::endl;
    for (auto kv : pa_a.getAliasMap()) {
        logs << "ALIAS " << kv.first << " -> " << kv.second.field << std::endl; }
    out << logs.str();
    return out;
}

std::ostream &operator<<(std::ostream& out, const PragmaAlias::AliasDestination& dest) {
    out << dest.field;
    if (dest.range)
        out << "[" << dest.range->hi << ":" << dest.range->lo << "]";
    return out;
}
