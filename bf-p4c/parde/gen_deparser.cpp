
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/device.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/gen_deparser.h"
#include "bf-p4c/bf-p4c-options.h"

namespace BFN {

template <typename Func>
void generateEmits(const IR::Expression* expression, Func func) {
    auto* header = expression->to<IR::HeaderRef>();
    BUG_CHECK(header != nullptr,
              "Emitting something other than a header: %1%", expression);
    auto* headerType = header->type->to<IR::Type_StructLike>();
    BUG_CHECK(headerType != nullptr,
              "Emitting header with non-structlike type: %1%", headerType);

    auto* povBit = new IR::Member(IR::Type::Bits::get(1), header, "$valid");
    for (auto* field : headerType->fields) {
        IR::Expression* fieldRef = new IR::Member(field->type, header, field->name);
        func(fieldRef, povBit);
    }
}

void ExtractDeparser::simpl_concat(std::vector<const IR::Expression*>& slices,
        const IR::Concat* expr) {
    if (expr->left->is<IR::Constant>()) {
        slices.push_back(expr->left);
    } else if (auto lhs = expr->left->to<IR::Concat>()) {
        simpl_concat(slices, lhs);
    } else {
        slices.push_back(expr->left); }

    if (expr->right->is<IR::Constant>()) {
        slices.push_back(expr->right);
    } else if (auto rhs = expr->right->to<IR::Concat>()) {
        simpl_concat(slices, rhs);
    } else {
        slices.push_back(expr->right);
    }
}

void ExtractDeparser::process_concat(IR::Vector<IR::BFN::FieldLVal>& vec,
        const IR::Concat* expr) {
    std::vector<const IR::Expression *> slices;
    simpl_concat(slices, expr);
    for (auto *item : slices) {
        if (item->is<IR::Constant>()) {
            ::warning("Tofino does not support emitting constant %1% "
                      "in digest, skipped", item);
            continue; }
        vec.push_back(new IR::BFN::FieldLVal(item)); }
}

bool ExtractDeparser::preorder(const IR::Declaration_Instance *decl) {
    LOG3("process declaration " << decl->name.name << " as " << decl->controlPlaneName());
    nameMap.emplace(decl->name.name, decl->controlPlaneName());
    return false;
}

bool ExtractDeparser::preorder(const IR::IfStatement *ifstmt) {
    const IR::Expression *old_pred = pred;
    pred = ifstmt->condition;
    if (old_pred) pred = new IR::LAnd(old_pred, pred);
    visit(ifstmt->ifTrue, "ifTrue");
    if (ifstmt->ifFalse) {
        pred = new IR::LNot(ifstmt->condition);
        if (old_pred) pred = new IR::LAnd(old_pred, pred);
        visit(ifstmt->ifFalse, "ifFalse");
    }
    pred = old_pred;
    return false;
}

/**
 * Converting IR::MethodCallExpression to IR::BFN::DigestFieldList.
 *
 * The MethodCallExpression can be 'emit' or 'pack' depending on
 * the extern.
 *
 * The field list expression in 'emit' can be either
 * ListExpression if the emit is generated by the p4-14-to-16 translation,
 * or StructInitializerExpression if the emit is directly from p4-16.
 *
 * In P4-14, the FieldList construct is translated to ListExpression
 * with a type of tuple<N>.
 *
 * In P4-16, TNA requires the 'emit' call to only accept 'header', which
 * has a type that is used later in the backend to repack & optimize
 * the layout of the header to minimize phv use.
 */
bool ExtractDeparser::preorder(const IR::MethodCallExpression* mc) {
    auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);

    if (!mi->is<P4::ExternMethod>())
        return false;

    auto em = mi->to<P4::ExternMethod>();
    if (em->method->name == "emit") {
        if (em->actualExternType->getName() == "packet_out") {
            if (pred) error("Conditional emit %s not supported", mc);
            generateEmits((*mc->arguments)[0]->expression,
                [&](const IR::Expression* field, const IR::Expression* povBit) {
                dprsr->emits.push_back(new IR::BFN::EmitField(mc->srcInfo, field, povBit)); });
        } else if (em->actualExternType->getName() == "Mirror") {
            auto expr = mc->arguments->at(1)->expression;
            // field list is ListExpression if source is P4-14
            if (auto list = expr->to<IR::ListExpression>()) {
                // Convert session_id, { field_list } --> { session_id, field_list }
                auto expr = new IR::ListExpression(
                        list->srcInfo, list->type, list->components);
                expr->components.insert(expr->components.begin(),
                                        mc->arguments->at(0)->expression);
                generateDigest(digests["mirror"], "mirror", expr, mc);
            }
            // field list is StructInitializerExpression if source is P4-16
            if (auto list = expr->to<IR::StructInitializerExpression>()) {
                // Convert session_id, { field_list } --> { session_id, field_list }
                auto combined = new IR::IndexedVector<IR::NamedExpression>();
                combined->push_back(new IR::NamedExpression("$session_id",
                                                            mc->arguments->at(0)->expression));
                combined->append(list->components);
                auto mirror_field_list =
                        new IR::StructInitializerExpression(list->name, *combined, true);
                generateDigest(digests["mirror"], "mirror", mirror_field_list, mc);
            }
        } else if (em->actualExternType->getName() == "Resubmit") {
            auto num_args = mc->arguments->size();
            auto expr = (num_args == 0) ? new IR::ListExpression({})
                                        : mc->arguments->at(0)->expression;
            generateDigest(digests["resubmit"], "resubmit", expr, mc);
        } else if (em->actualExternType->getName() == "Pktgen") {
            auto expr = mc->arguments->at(0)->expression;
            generateDigest(digests["pktgen"], "pktgen", expr, mc);
        } else {
            fatal_error(ErrorType::ERR_UNSUPPORTED,
                        "Unsupported method call %1% in deparser", mc);
        }
    } else if (em->method->name == "pack") {
        if (em->actualExternType->getName() == "Digest") {
            LOG3("generate digest " << em->object->getName());
            auto cpn = nameMap.find(em->object->getName());
            BUG_CHECK(cpn != nameMap.end(), "unable to find digest %1%", em->object->getName());
            generateDigest(digests["learning"], "learning",
                           mc->arguments->at(0)->expression, mc, cpn->second);
        }
    }
    return false;
}

// FIXME -- factor this with Digests::add_to_digest in digest.h?
void ExtractDeparser::generateDigest(IR::BFN::Digest *&digest, cstring name,
                                      const IR::Expression *expr,
                                      const IR::MethodCallExpression* mc,
                                      cstring controlPlaneName) {
    int digest_index = 0;
    const IR::Literal *k = nullptr;
    const IR::Expression *select;
    if (!pred) {
        fatal_error(ErrorType::ERR_UNSUPPORTED, "unconditional %2%.emit", mc, name);
        return;
    } else if (auto eq = pred->to<IR::Equ>()) {
        if ((k = eq->left->to<IR::Constant>()))
            select = eq->right;
        else if ((k = eq->right->to<IR::Constant>()))
            select = eq->left;
        else if ((k = eq->left->to<IR::BoolLiteral>()))
            select = eq->right;
        else if ((k = eq->right->to<IR::BoolLiteral>()))
            select = eq->left;
    } else if (auto bo = pred->to<IR::Member>()) {
        // 'if (boolean)' is the same as 'if (boolean == 1)'
        if (bo->type->to<IR::Type_Boolean>()) {
            k = new IR::BoolLiteral(true);
            digest_index = 0;
            select = pred;
        }
    }
    if (!k) {
        fatal_error(ErrorType::ERR_UNSUPPORTED, "condition %2% in %3%.emit", mc, pred, name);
        return;
    } else if (k->is<IR::Constant>()) {
            digest_index = k->to<IR::Constant>()->asInt(); }

    if (!digest) {
        digest = new IR::BFN::Digest(name, select);
        dprsr->digests.addUnique(name, digest);
    } else if (!select->equiv(*digest->selector->field)) {
        error("Inconsistent %s selectors, %s and %s", name, select,
              digest->selector->field);
    }

    for (auto fieldList : digest->fieldLists) {
        if (fieldList->idx == digest_index) {
            return;
        }
    }

    IR::Vector<IR::BFN::FieldLVal> sources;
    if (!expr) {
        // Treat as an empty list.
    } else if (auto* list = expr->to<const IR::Vector<IR::Expression>>()) {
        for (auto* item : *list) {
            if (item->is<IR::Concat>()) {
                process_concat(sources, item->to<IR::Concat>());
            } else {
                sources.push_back(new IR::BFN::FieldLVal(item)); }
        }
    } else if (auto* list = expr->to<IR::ListExpression>()) {
        for (auto* item : list->components) {
            if (item->is<IR::Concat>()) {
                process_concat(sources, item->to<IR::Concat>());
            } else {
                sources.push_back(new IR::BFN::FieldLVal(item)); }
        }
    } else if (auto *ref = expr->to<IR::ConcreteHeaderRef>()) {
        if (auto *st = expr->type->to<IR::Type_StructLike>()) {
            for (auto *item : st->fields) {
                sources.push_back(new IR::BFN::FieldLVal(gen_fieldref(ref->ref, item->name)));
            }
        }
    } else if (auto* initializer = expr->to<IR::StructInitializerExpression>()) {
        for (auto *item : initializer->components) {
            if (item->expression->is<IR::Concat>()) {
                process_concat(sources, item->expression->to<IR::Concat>());
            } else {
                sources.push_back(new IR::BFN::FieldLVal(item->expression)); }
        }
    } else {
            sources.push_back(new IR::BFN::FieldLVal(expr));
    }

    auto* fieldList = new IR::BFN::DigestFieldList(digest_index, sources, controlPlaneName);
    digest->fieldLists.push_back(fieldList);
}

}  // namespace BFN

