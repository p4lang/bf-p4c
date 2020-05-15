#include <string>
#include <numeric>
#include <sstream>

#include "lib/log.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/common/table_printer.h"
#include "bf-p4c/phv/pragma/pa_alias.h"
#include "bf-p4c/phv/pragma/phv_pragmas.h"

/// BFN::Pragma interface
const char *PragmaAlias::name = "pa_alias";
const char *PragmaAlias::description =
    "Specifies that two fields are aliased";
const char *PragmaAlias::help =
    "@pragma pa_alias gress inst1.field_name_1 inst_2.field_name_2 "
    "<inst_3.field_name_3 ...>\n"
    "+ attached to P4 header instances\n"
    "\n"
    "Specifies that each packet and/or metadata field instance specified "
    "in the pragma must be considered as an alias to every other field "
    "instance specified in the same pragma. The set of field instances "
    "(aliasing fields) specified with every pa_alias pragma must have at "
    "least two members. "
    "Note that the list of aliasing fields can only have a maximum of one "
    "packet field/intrinsic metadata field instance. "
    "Use this pragma with care, as it merges the constraints of all fields."
    "The gress value can be either ingress or egress. The fields must all "
    "be of the same width. Note that incorrect aliasing may result in "
    "incorrect behavior--the compiler will allocate all the fields specified "
    "in the pragma to the same containers, without additional correctness "
    "checks. "
    "Finally, any field can appear in only one pa_alias pragma. If the same "
    "field appears in multiple pa_alias pragmas, then the compiler ignores all "
    "but one of those pragmas, and emits a warning for all the other pragmas "
    "that are not enforced.";

Visitor::profile_t PragmaAlias::init_apply(const IR::Node* root) {
    aliasMap.clear();
    fieldsWithExpressions.clear();
    fieldsWithAliasing.clear();
    return Inspector::init_apply(root);
}

bool PragmaAlias::preorder(const IR::Expression* expr) {
    const PHV::Field* f = phv_i.field(expr);
    if (!f) return true;
    fieldsWithExpressions[f->id] = true;
    return true;
}

boost::optional<std::pair<const PHV::Field*, const PHV::Field*>> PragmaAlias::mayAddAlias(
        const PHV::Field* field1,
        const PHV::Field* field2,
        bool suppressWarning) {
    if (fieldsWithAliasing[field1->id]) {
        WARN_CHECK(suppressWarning,
                "@pragma pa_alias for fields %1% and %2% ignored because "
                "field %1% already aliases with a different field %3%",
                field1->name, field2->name,
                (aliasMap.count(field1->name) ? aliasMap[field1->name].field : ""));
        return boost::none; }

    if (fieldsWithAliasing[field2->id]) {
        WARN_CHECK(suppressWarning,
                "@pragma pa_alias for fields %1% and %2% ignored because "
                "field %2% already aliases with a different field %3%",
                field1->name, field2->name,
                (aliasMap.count(field2->name) ? aliasMap[field2->name].field : ""));
        return boost::none; }

    if (field1->isPacketField() && field2->isPacketField()) {
        WARN_CHECK(suppressWarning,
                "@pragma pa_alias does not support aliasing of two packet header fields "
                "%1% and %2%",
                field1->name, field2->name);
        return boost::none;
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
            return boost::none;
        }
    }
    BUG_CHECK(aliasDest && aliasSrc, "Internal compiler error: Did not calculate aliasDest and "
            "aliasSrc");
    if (aliasSrc->size > aliasDest->size) {
        WARN_CHECK(suppressWarning,
                "@pragma pa_alias ignored because metadata field %1%<%2%> is larger than the "
                "packet field %3%<%4%>",
                   aliasSrc->name, aliasSrc->size, aliasDest->name, aliasDest->size);
        return boost::none;
    }
    // If the field to be replaced has an alignment that is different from the field replacing it,
    // then do not do that alias (might create conflicting alignment requirements).
    if (aliasSrc->alignment != boost::none) {
        if (aliasDest->alignment == boost::none) {
            WARN_CHECK(suppressWarning,
                    "@pragma pa_alias ignored because metadata field %1% has alignment %2%, "
                    "while packet field %3% has no alignment requirement",
                    aliasSrc->name, aliasSrc->alignment->align, aliasDest->name);
            return boost::none;
        } else if (*(aliasDest->alignment) != *(aliasSrc->alignment)) {
            WARN_CHECK(suppressWarning,
                    "@pragma pa_alias ignored because metadata field %1% has alignment %2%, "
                    "while packet field %3% has alignment %4%", aliasSrc->name,
                    aliasSrc->alignment->align, aliasDest->name, aliasDest->alignment->align);
            return boost::none;
        }
    }
    if (aliasDest && aliasSrc) {
        std::pair<const PHV::Field*, const PHV::Field*> rv;
        rv.first = aliasDest;
        rv.second = aliasSrc;
        return rv;
    }
    return boost::none;
}

bool PragmaAlias::addAlias(const PHV::Field* f1, const PHV::Field* f2,
        bool suppressWarning, PragmaAlias::CreatedBy who) {
    auto mayAlias = mayAddAlias(f1, f2, suppressWarning);
    if (!mayAlias) return false;
    aliasMap[mayAlias->second->name] = { mayAlias->first->name, boost::none, who };
    fieldsWithAliasing[mayAlias->second->id] = true;
    fieldsWithAliasing[mayAlias->first->id] = true;
    LOG1("\t  " << mayAlias->second->name << " --> " << mayAlias->first->name);
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
        if (annotation->name.name != PragmaAlias::name)
            continue;
        LOG3("Annotation: " << annotation);

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() < 3) {
            ::warning("Skipping @pragma pa_alias with %1% arguments "
                      "(Require 3 or more arguments: gress, field1, field2, ..., fieldn)",
                      exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        std::vector<const IR::StringLiteral*> field_irs;
        for (unsigned i = 1; i < exprs.size(); i++) {
            const IR::StringLiteral* name = exprs[i]->to<IR::StringLiteral>();
            field_irs.push_back(name);
        }
        bool processPragma = true;

        if (!check_pragma_string(gress)) {
            ::fatal_error("Only string allowed as gress value specified in pragma %2%",
                    cstring::to_cstring(gress), cstring::to_cstring(annotation));
            processPragma = false;
        }

        if (!std::all_of(field_irs.begin(), field_irs.end(), check_pragma_string)) {
            ::fatal_error("Non-string field name found in pragma %1%",
                    cstring::to_cstring(annotation));
            processPragma = false;
        }

        // check gress correct
        if (!PHV::Pragmas::gressValid("pa_alias", gress->value)) {
            ::fatal_error("Invalid gress %1% specified for pragma %2%",
                    cstring::to_cstring(gress->value),
                    cstring::to_cstring(annotation));
            processPragma = false;
        }

        if (!processPragma) continue;

        std::vector<const PHV::Field*> fields;
        for (const auto* field_ir : field_irs) {
            cstring field_name = gress->value + "::" + field_ir->value;
            const auto* field = phv_i.field(field_name);
            if (!field) {
                ::warning("Ignoring pragma %1% because argument %2% does not match any "
                          "PHV fields.", cstring::to_cstring(annotation), field_name);
                processPragma = false;
            }
            fields.push_back(field);
        }

        if (!processPragma) continue;

        const PHV::Field* aliasDest = fields[0];
        for (unsigned i = 1; i < fields.size(); i++) {
            const PHV::Field* field2 = fields[i];
            LOG4("\t\tAlias " << aliasDest->name << ", " << field2->name);
            auto mayAlias = mayAddAlias(aliasDest, field2);
            if (!mayAlias) {
                processPragma = false;
                break;
            }
            aliasDest = mayAlias->first;
        }
        if (!processPragma) continue;
        for (const auto* field : fields) {
            if (field == aliasDest) continue;
            aliasMap[field->name] = { aliasDest->name, boost::none, PragmaAlias::PRAGMA };
            fieldsWithAliasing[field->id] = true;
            fieldsWithAliasing[aliasDest->id] = true;
            LOG1("\t  " << field->name << " --> " << aliasDest->name);
        }
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

std::string PragmaAlias::pretty_print() {
    std::stringstream out;
    out << "Alias pragmas:" << std::endl;

    TablePrinter* tp = new TablePrinter(out, {"Source", "Destination",
            "Created By"}, TablePrinter::Align::CENTER);
    tp->addSep();

    for (auto kv : aliasMap) {
        tp->addRow({std::string(kv.first.c_str()),
                    std::string(kv.second.field.c_str()),
                    std::string((kv.second.who == PragmaAlias::PRAGMA) ? "PRAGMA" :
                                (kv.second.who == PragmaAlias::COMPILER) ? "COMPILER" :
                                "UNKNOWN")}); }

    tp->print();
    out << std::endl;
    return out.str();
}
