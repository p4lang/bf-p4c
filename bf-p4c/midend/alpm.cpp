#include <cmath>
#include "ir/ir.h"
#include "frontends/p4/methodInstance.h"
#include "frontends/p4/coreLibrary.h"
#include "bf-p4c/common/pragma/all_pragmas.h"
#include "lib/bitops.h"
#include "lib/log.h"
#include "alpm.h"

namespace BFN {

const std::set<unsigned> SplitAlpm::valid_partition_values = {1024, 2048, 4096, 8192};
const cstring SplitAlpm::ALGORITHMIC_LPM_PARTITIONS  = PragmaAlpmPartitions::name;
const cstring SplitAlpm::ALGORITHMIC_LPM_SUBTREES_PER_PARTITION =
    PragmaAlpmSubtreePartitions::name;

namespace {

/**
 * Helper functions to extract extern instance from table properties.
 * Originally implemented in as part of the control-plane repo.
 */
boost::optional<P4::ExternInstance> getExternInstanceFromProperty(
        const IR::P4Table* table,
        const cstring& propertyName,
        P4::ReferenceMap* refMap,
        P4::TypeMap* typeMap) {
    auto property = table->properties->getProperty(propertyName);
    if (property == nullptr) return boost::none;
    if (!property->value->is<IR::ExpressionValue>()) {
        ::error("Expected %1% property value for table %2% to be an expression: %3%",
                propertyName, table->controlPlaneName(), property);
        return boost::none;
    }

    auto expr = property->value->to<IR::ExpressionValue>()->expression;
    auto name = property->controlPlaneName();
    auto externInstance = P4::ExternInstance::resolve(expr, refMap, typeMap, name);
    if (!externInstance) {
        ::error("Expected %1% property value for table %2% to resolve to an "
                "extern instance: %3%", propertyName, table->controlPlaneName(),
                property);
        return boost::none; }

    return externInstance;
}

}  // namespace

const IR::IndexedVector<IR::Declaration>* SplitAlpm::create_temp_var(
        const IR::P4Table* tbl, unsigned number_actions,
        unsigned partition_index_bits,
        unsigned atcam_subset_width) {
    auto tempvar = new IR::IndexedVector<IR::Declaration>();

    tempvar->push_back(new IR::Declaration_Variable(
                IR::ID(tbl->name + "_partition_index"),
                IR::Type_Bits::get(partition_index_bits)));

    if (number_actions > 1) {
        tempvar->push_back(new IR::Declaration_Variable(
                    IR::ID(tbl->name + "_partition_key"),
                    IR::Type_Bits::get(atcam_subset_width))); }

    return tempvar;
}

const IR::IndexedVector<IR::Declaration>* SplitAlpm::create_preclassifer_actions(
        const IR::P4Table* tbl,
        unsigned number_actions,
        unsigned partition_index_bits,
        unsigned atcam_subset_width,
        unsigned shift_granularity,
        const IR::Expression* lpm_key) {
    auto actions = new IR::IndexedVector<IR::Declaration>();

    auto params = new IR::ParameterList();
    params->push_back(new IR::Parameter(IR::ID("index"), IR::Direction::None,
                IR::Type_Bits::get(partition_index_bits)));

    for (unsigned n = 0; n < number_actions; n++) {
        auto body = new IR::BlockStatement;

        body->push_back(new IR::AssignmentStatement(
                    new IR::PathExpression(IR::ID(tbl->name + "_partition_index")),
                    new IR::PathExpression(IR::ID("index"))));

        if (number_actions > 1) {
            body->push_back(new IR::AssignmentStatement(
                        new IR::PathExpression(IR::ID(tbl->name + "_partition_key")),
                        new IR::Slice(
                            new IR::Shr(lpm_key,
                                new IR::Constant(lpm_key->type->width_bits() -
                                    atcam_subset_width - n * shift_granularity)),
                            atcam_subset_width-1, 0))); }

        auto name = tbl->name + "_set_partition_index_" + cstring::to_cstring(n);
        actions->push_back(new IR::P4Action(IR::ID(name), params, body)); }

    return actions;
}

const IR::P4Table* SplitAlpm::create_atcam_table(const IR::P4Table* tbl,
        unsigned partition_count,
        unsigned subtrees_per_partition, unsigned number_actions,
        int atcam_subset_width, int shift_granularity) {
    auto properties = new IR::IndexedVector<IR::Property>;

    // create partition_index
    IR::Vector<IR::KeyElement> keys;
    if (number_actions > 1) {
        keys.push_back(new IR::KeyElement(
                    new IR::PathExpression(IR::ID(tbl->name + "_partition_key")),
                    new IR::PathExpression(IR::ID("lpm"))));
    } else {
        for (auto k : tbl->getKey()->keyElements) {
            keys.push_back(k); } }
    keys.push_back(new IR::KeyElement(
                new IR::PathExpression(IR::ID(tbl->name + "_partition_index")),
                new IR::PathExpression(IR::ID("atcam_partition_index"))));
    properties->push_back(new IR::Property("key",
                          new IR::Key(keys), false));

    // create partition_key for further alpm optimization
    properties->push_back(new IR::Property("actions", tbl->getActionList(), false));

    // create size
    properties->push_back(new IR::Property("size",
        new IR::ExpressionValue(tbl->getSizeProperty()), false));

    // create default_action
    if (tbl->getDefaultAction()) {
        properties->push_back(new IR::Property("default_action",
                              new IR::ExpressionValue(tbl->getDefaultAction()),
                              false)); }

    if (auto prop = tbl->properties->getProperty("idle_timeout")) {
        properties->push_back(prop);
    }

    properties->push_back(new IR::Property("as_atcam",
                new IR::Annotations({new IR::Annotation(IR::Annotation::hiddenAnnotation, {})}),
                new IR::ExpressionValue(new IR::BoolLiteral(true)), false));

    properties->push_back(new IR::Property("as_alpm",
                new IR::Annotations({new IR::Annotation(IR::Annotation::hiddenAnnotation, {})}),
                new IR::ExpressionValue(new IR::BoolLiteral(true)), false));

    properties->push_back(new IR::Property("atcam_partition_count",
                new IR::Annotations({new IR::Annotation(IR::Annotation::hiddenAnnotation, {})}),
                new IR::ExpressionValue(new IR::Constant(partition_count)), false));

    properties->push_back(new IR::Property("atcam_subtrees_per_partition",
                new IR::Annotations({new IR::Annotation(IR::Annotation::hiddenAnnotation, {})}),
                new IR::ExpressionValue(new IR::Constant(subtrees_per_partition)), false));

    if (atcam_subset_width != -1) {
        properties->push_back(new IR::Property("atcam_subset_width",
                    new IR::Annotations({new IR::Annotation(IR::Annotation::hiddenAnnotation, {})}),
                    new IR::ExpressionValue(new IR::Constant(atcam_subset_width)), false));
    }

    if (shift_granularity != -1) {
        properties->push_back(new IR::Property("shift_granularity",
                    new IR::Annotations({new IR::Annotation(IR::Annotation::hiddenAnnotation, {})}),
                    new IR::ExpressionValue(new IR::Constant(shift_granularity)), false));
    }

    auto table_property = new IR::TableProperties(*properties);
    auto table = new IR::P4Table(tbl->srcInfo, IR::ID(tbl->name), tbl->annotations, table_property);
    return table;
}

const IR::P4Table* SplitAlpm::create_preclassifier_table(const IR::P4Table* tbl,
        unsigned number_entries, unsigned number_actions, unsigned partition_index_bits) {
    auto properties = new IR::IndexedVector<IR::Property>;

    // create key
    IR::Vector<IR::KeyElement> keys;
    for (auto f : tbl->getKey()->keyElements) {
        if (f->matchType->path->name == "lpm") {
            auto k = new IR::KeyElement(f->annotations, f->expression,
                     new IR::PathExpression("lpm"));
            keys.push_back(k);
        } else {
            keys.push_back(f);
        }
    }
    properties->push_back(new IR::Property("key",
                          new IR::Key(keys), false));

    // create action
    IR::IndexedVector<IR::ActionListElement> action_list;
    for (unsigned n = 0; n < number_actions; n++) {
        auto name = tbl->name + "_set_partition_index_" + cstring::to_cstring(n);
        action_list.push_back(new IR::ActionListElement(
                    new IR::MethodCallExpression(new IR::PathExpression(IR::ID(name)), {})));
    }

    properties->push_back(new IR::Property("actions",
                new IR::ActionList(action_list), false));

    // Assume that the preclassifier always has an catch-all entry to set the
    // default partition index to 0.
    if (number_actions != 0) {
        auto act = new IR::PathExpression(IR::ID(tbl->name + "_set_partition_index_0"));
        auto args = new IR::Vector<IR::Argument>();
        args->push_back(new IR::Argument(
            new IR::Constant(IR::Type::Bits::get(partition_index_bits), 0)));
        auto methodCall = new IR::MethodCallExpression(act, args);
        auto prop = new IR::Property(
                IR::ID(IR::TableProperties::defaultActionPropertyName),
                new IR::ExpressionValue(methodCall),
                /* isConstant = */ false);
        properties->push_back(prop);
    }

    // size field is not used
    properties->push_back(new IR::Property("size",
                new IR::ExpressionValue(tbl->getSizeProperty()), false));

    properties->push_back(new IR::Property("alpm_preclassifier",
                new IR::Annotations({new IR::Annotation(IR::Annotation::hiddenAnnotation, {})}),
                new IR::ExpressionValue(new IR::BoolLiteral(true)), false));

    properties->push_back(new IR::Property("alpm_preclassifier_number_entries",
                new IR::Annotations({new IR::Annotation(IR::Annotation::hiddenAnnotation, {})}),
                new IR::ExpressionValue(new IR::Constant(number_entries)), false));

    if (auto prop = tbl->properties->getProperty("requires_versioning")) {
        properties->push_back(prop);
    }


    auto table_property = new IR::TableProperties(*properties);
    auto name = tbl->name + "__alpm_preclassifier";
    auto table = new IR::P4Table(tbl->srcInfo, IR::ID(name), tbl->annotations, table_property);

    return table;
}

bool SplitAlpm::values_through_pragmas(const IR::P4Table *tbl,
                                       int &number_partitions,
                                       int &number_subtrees_per_partition) {
    auto annot = tbl->getAnnotations();
    if (auto s = annot->getSingle(ALGORITHMIC_LPM_PARTITIONS)) {
        ERROR_CHECK(s->expr.size() > 0, "%s: Please provide a valid %s "
                "for table %s", tbl->srcInfo, ALGORITHMIC_LPM_PARTITIONS, tbl->name);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a valid %s "
                "for table %s", tbl->srcInfo, ALGORITHMIC_LPM_PARTITIONS, tbl->name);

        auto alg_lpm_partitions_value = static_cast<unsigned>(pragma_val->value);
        if (valid_partition_values.find(alg_lpm_partitions_value) != valid_partition_values.end()) {
            number_partitions = static_cast<int>(pragma_val->value);
        } else {
            ::error("Unsupported %s value of %s for table %s."
                            "\n  Allowed values are 1024, 2048, 4096, and 8192.",
                    ALGORITHMIC_LPM_PARTITIONS, pragma_val->value, tbl->name);
        }
    }

    if (auto s = annot->getSingle(ALGORITHMIC_LPM_SUBTREES_PER_PARTITION)) {
        ERROR_CHECK(s->expr.size() > 0, "%s: Please provide a valid %s "
                "for table %s", tbl->srcInfo, ALGORITHMIC_LPM_SUBTREES_PER_PARTITION, tbl->name);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a valid %s "
                "for table %s", tbl->srcInfo, ALGORITHMIC_LPM_SUBTREES_PER_PARTITION, tbl->name);

        auto alg_lpm_subtrees_value = static_cast<int>(pragma_val->value);
        if (alg_lpm_subtrees_value <= 10) {
            number_subtrees_per_partition = alg_lpm_subtrees_value;
        } else {
            ::error("Unsupported %s value of %s for table %s."
                            "\n  Allowed values are in the range [1:10].",
                    ALGORITHMIC_LPM_SUBTREES_PER_PARTITION, pragma_val->value, tbl->name);
        }
    }
    return ::errorCount() == 0;
}

bool SplitAlpm::values_through_impl(const IR::P4Table *tbl,
                                    int &number_partitions,
                                    int &number_subtrees_per_partition,
                                    int &atcam_subset_width,
                                    int &shift_granularity) {
    auto alpm = getExternInstanceFromProperty(tbl, "alpm", refMap, typeMap);

    if (alpm == boost::none)
        return false;
    if (alpm->type->name != "Alpm")
        return false;

    bool argHasName = false;
    for (auto arg : *alpm->arguments) {
        cstring argName = arg->name.name;
        argHasName |= !argName.isNullOrEmpty();
    }
    // p4c requires all or none arguments to have names
    if (argHasName) {
        for (auto arg : *alpm->arguments) {
            cstring argName = arg->name.name;
            if (argName == "number_partitions")
                number_partitions =
                    arg->expression->to<IR::Constant>()->asInt();
            else if (argName == "subtrees_per_partition")
                number_subtrees_per_partition =
                    arg->expression->to<IR::Constant>()->asInt();
            else if (argName == "atcam_subset_width")
                atcam_subset_width =
                    arg->expression->to<IR::Constant>()->asInt();
            else if (argName == "shift_granularity")
                shift_granularity =
                    arg->expression->to<IR::Constant>()->asInt();
        }
    } else {
        if (alpm->arguments->size() > 0) {
            number_partitions =
                alpm->arguments->at(0)->expression->to<IR::Constant>()->asInt();
        } else if (alpm->arguments->size() > 1) {
            number_subtrees_per_partition =
                alpm->arguments->at(1)->expression->to<IR::Constant>()->asInt();
        } else if (alpm->arguments->size() > 2) {
            atcam_subset_width =
                alpm->arguments->at(2)->expression->to<IR::Constant>()->asInt();
        } else if (alpm->arguments->size() > 3) {
            shift_granularity =
                alpm->arguments->at(3)->expression->to<IR::Constant>()->asInt();
        }
    }
    return true;
}

const IR::Node* SplitAlpm::postorder(IR::P4Table* tbl) {
    if (alpm_info->alpm_table.count(tbl->name) == 0)
        return tbl;

    int number_partitions = 1024;
    int number_subtrees_per_partition = 2;
    int atcam_subset_width = -1;
    int shift_granularity = -1;
    int lpm_key_width = -1;

    auto lpm_cnt = 0;
    const IR::Expression* lpm_key = nullptr;
    for (auto f : tbl->getKey()->keyElements) {
        if (f->matchType->path->name == "lpm") {
            lpm_cnt += 1;
            lpm_key = f->expression;
            lpm_key_width = f->expression->type->width_bits();
        }
    }
    ERROR_CHECK(lpm_cnt == 1, "To use algorithmic lpm, exactly one field in the match key "
            "must have a match type of lpm.  Table '%s' has %d.", tbl->name, lpm_cnt);


    if (!values_through_impl(tbl, number_partitions, number_subtrees_per_partition,
                atcam_subset_width, shift_granularity) &&
        !values_through_pragmas(tbl, number_partitions, number_subtrees_per_partition))
        return tbl;

    auto partition_index_bits = ::ceil_log2(number_partitions);
    auto number_entries = number_partitions * number_subtrees_per_partition;

    if (atcam_subset_width == -1)
        atcam_subset_width = lpm_key_width;

    if (shift_granularity == -1)
        shift_granularity = lpm_key_width;

    LOG1("atcam_subset_width " << atcam_subset_width << " shift_granularity " << shift_granularity);
    ERROR_CHECK(atcam_subset_width % shift_granularity == 0, "To use algorithmic lpm, "
            "atcam_subset_width must be an integer multiple of shift_granularity.");
    auto number_actions = (lpm_key_width - atcam_subset_width) / shift_granularity + 1;

    auto decls = new IR::IndexedVector<IR::Declaration>();
    decls->append(*create_temp_var(tbl, number_actions, partition_index_bits, atcam_subset_width));

    auto classifier_actions = create_preclassifer_actions(tbl,
            number_actions, partition_index_bits, atcam_subset_width, shift_granularity, lpm_key);
    decls->append(*classifier_actions);

    // create tcam table
    auto classifier_table = create_preclassifier_table(tbl, number_entries, number_actions,
            partition_index_bits);
    decls->push_back(classifier_table);

    // create atcam
    auto atcam_table = create_atcam_table(tbl, number_partitions,
            number_subtrees_per_partition, number_actions, atcam_subset_width, shift_granularity);
    decls->push_back(atcam_table);

    return decls;
}

const IR::Node* SplitAlpm::postorder(IR::MethodCallStatement* node) {
    auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
    if (!mi->is<P4::ApplyMethod>() || !mi->to<P4::ApplyMethod>()->isTableApply())
        return node;
    if (auto tbl = mi->object->to<IR::P4Table>()) {
        if (alpm_info->alpm_table.count(tbl->name) == 0)
            return node;
        auto stmts = new IR::IndexedVector<IR::StatOrDecl>();
        stmts->push_back(new IR::MethodCallStatement(
            new IR::MethodCallExpression(new IR::Member(
                new IR::PathExpression(
                    IR::ID(tbl->name + "__alpm_preclassifier")), IR::ID("apply")), {})));
        stmts->push_back(node);
        auto result = new IR::BlockStatement(*stmts);
        return result;
    }
    return node;
}

const IR::Node* SplitAlpm::postorder(IR::IfStatement* c) {
    HasTableApply hta(refMap, typeMap);
    (void) c->condition->apply(hta);
    if (hta.table == nullptr)
        return c;
    if (alpm_info->alpm_table.count(hta.table->name) == 0)
        return c;
    auto cond = new IR::Member(
            new IR::MethodCallExpression(new IR::Member(
                new IR::PathExpression(
                    IR::ID(hta.table->name + "__alpm_preclassifier")), IR::ID("apply")), {}),
            "hit");
    auto r = new IR::IfStatement(c->srcInfo, cond, c, nullptr);
    LOG1("r " << r);
    return r;
}

AlpmImplementation::AlpmImplementation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    auto collectAlpmInfo = new CollectAlpmInfo(refMap, typeMap);
    addPasses({
        collectAlpmInfo,
        new SplitAlpm(collectAlpmInfo, refMap, typeMap)
    });
}

void CollectAlpmInfo::postorder(const IR::P4Table* tbl) {
    // Alpm is identified with either extern or pragma
    auto alpm = getExternInstanceFromProperty(tbl, "alpm", refMap, typeMap);
    if (alpm != boost::none) {
        LOG1("add alpm table " << tbl->name);
        alpm_table.insert(tbl->name);
    }

    auto annot = tbl->getAnnotations();
    if (auto s = annot->getSingle(PragmaAlpm::name)) {
        ERROR_CHECK(s->expr.size() > 0, "%s: Please provide a valid alpm "
                "for table %s", tbl->srcInfo, tbl->name);
        if (auto pragma_val = s->expr.at(0)->to<IR::Constant>()) {
            if (pragma_val->asInt())
                alpm_table.insert(tbl->name);
        } else if (auto pragma_val = s->expr.at(0)->to<IR::BoolLiteral>()) {
            if (pragma_val->value)
                alpm_table.insert(tbl->name);
        } else {
            ::error("%s: Please provide a valid alpm for table %s", tbl->srcInfo, tbl->name);
        }
    }
}

}  // namespace BFN
