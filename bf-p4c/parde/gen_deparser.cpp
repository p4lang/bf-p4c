#include "frontends/p4/methodInstance.h"
#include "bf-p4c/device.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/gen_deparser.h"
#include "bf-p4c/bf-p4c-options.h"
#include "ir/pattern.h"

namespace BFN {

bool ExtractDeparser::preorder(const IR::Annotation* annot) {
    if (annot->name == "header_ordering") {
        auto ordering = new ordered_set<cstring>;

        for (auto expr : annot->expr) {
            if (auto str = expr->to<IR::StringLiteral>()) {
                for (auto& o : userEnforcedHeaderOrdering) {
                    if (o->count(str->value))
                        ::fatal_error("%1% is repeated on %2%", str->value, annot);
                }

                ordering->insert(str->value);
            } else {
                ::fatal_error("@pragma header_ordering expects strings as arguments %1%", annot);
            }
        }

        userEnforcedHeaderOrdering.insert(ordering);
    }

    return false;
}

void ExtractDeparser::generateEmits(const IR::MethodCallExpression* mc) {
    auto expr = (*mc->arguments)[0]->expression;

    auto* header = expr->to<IR::HeaderRef>();

    BUG_CHECK(header != nullptr,
              "Emitting something other than a header: %1%", expr);
    auto* headerType = header->type->to<IR::Type_StructLike>();
    BUG_CHECK(headerType != nullptr,
              "Emitting header with non-structlike type: %1%", headerType);

    auto* povBit = new IR::Member(IR::Type::Bits::get(1), header, "$valid");
    for (auto* f : headerType->fields) {
        auto* field = new IR::Member(f->type, header, f->name);
        auto* emit = new IR::BFN::EmitField(mc->srcInfo, field, povBit);

        if (auto concrete = header->to<IR::ConcreteHeaderRef>()) {
            headerToEmits[concrete->ref->name].push_back(emit);
        } else if (auto stack = header->to<IR::HeaderStackItemRef>()) {
            if (auto ref = stack->base_->to<IR::V1InstanceRef>())
                headerToEmits[ref->name].push_back(emit);
            else if (auto ref = stack->base_->to<IR::InstanceRef>())
                headerToEmits[ref->name].push_back(emit);
            else
                BUG("Unknown header stack type: %1%", header);
        }
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
        if (item->is<IR::Constant>())
            vec.push_back(new IR::BFN::FieldLVal(new IR::Padding(item->type)));
        else
            vec.push_back(new IR::BFN::FieldLVal(item));
    }
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
 * XXX(hanw): Fix up digest field list for mirror by appending the
 * mirror_session_id at the beginning of the digest field list. This had to be
 * done here. Had it done earlier in the midend, it would be part of the mirror
 * header type. However, it does not work because we generate parser extract
 * statement from the mirror header type and 'session_id' is not part of the
 * packet that can be parsed. The earliest location to fix up the digest field
 * list is here.
 */
void ExtractDeparser::fixup_mirror_digest(const IR::MethodCallExpression* mc,
        IR::IndexedVector<IR::NamedExpression>* components) {
    auto session_id = new IR::NamedExpression("$session_id", mc->arguments->at(0)->expression);
    components->push_back(session_id);
}

/**
 * Converting IR::MethodCallExpression to IR::BFN::DigestFieldList.
 *
 * The MethodCallExpression can be 'emit' or 'pack' depending on
 * the extern.
 *
 * The field list expression in 'emit' can be either
 * ListExpression if the emit is generated by the p4-14-to-16 translation,
 * or StructExpression if the emit is directly from p4-16.
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

    // TODO: fix code with a helper class.
    auto em = mi->to<P4::ExternMethod>();
    if (em->method->name == "emit") {
        if (em->actualExternType->getName() == "packet_out") {
            if (pred) error("Conditional emit %s not supported", mc);
            generateEmits(mc);
        } else if (em->actualExternType->getName() == "Mirror") {
            if (mc->arguments->size() != 2) {
               generateDigest(digests["mirror"], "mirror", nullptr, mc);
               return false; }
            auto expr = mc->arguments->at(1)->expression;
            if (auto list = expr->to<IR::StructExpression>()) {
                // field list is StructExpression if source is P4-16
                // Convert session_id, { field_list } --> { session_id, field_list }
                auto components = new IR::IndexedVector<IR::NamedExpression>();
                fixup_mirror_digest(mc, components);
                components->append(list->components);
                auto list_type = typeMap->getTypeType(mc->typeArguments->at(0), true);
                auto mirror_field_list =
                    new IR::StructExpression(list_type, list->structType, *components);
                generateDigest(digests["mirror"], "mirror", mirror_field_list, mc);
            }
        } else if (em->actualExternType->getName() == "Resubmit") {
            auto num_args = mc->arguments->size();
            auto expr = (num_args == 0) ? nullptr  /* no argument in resubmit.emit() */
                : mc->arguments->at(0)->expression;
            generateDigest(digests["resubmit"], "resubmit", expr, mc);
        } else if (em->actualExternType->getName() == "Pktgen") {
            auto expr = mc->arguments->at(0)->expression;
            generateDigest(digests["pktgen"], "pktgen", expr, mc, nullptr, true /* singleEntry */);
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

bool ExtractDeparser::preorder(const IR::AssignmentStatement* stmt) {
     const IR::Type* leftType = nullptr;
     if (stmt->left->is<IR::Member>()) {
         leftType = stmt->left->to<IR::Member>()->expr->type;
     } else if (stmt->left->is<IR::Slice>()) {
         auto slice = stmt->left->to<IR::Slice>();
         auto member =  slice->e0->to<IR::Member>();
         if (member) {
             leftType = member->expr->type;
         }
     } else {
         leftType = stmt->left->type;
     }
     auto methodCall = stmt->right->to<IR::MethodCallExpression>();
     if (!methodCall) {
         auto ifStmt = findContext<IR::IfStatement>();
         AssignmentStmtErrorCheck errorCheck(leftType);
         ifStmt->apply(errorCheck);
         if (!errorCheck.stmtOk) {
             ::error("Assignment to a header field in the deparser is only allowed when "
                    "the source is checksum update, mirror, resubmit or learning digest. "
                    "Please move the assignment into the control flow %1%", stmt);
         }
     }
     return false;
}

// FIXME -- factor this with Digests::add_to_digest in digest.h?
// Collect information to generate assembly output.
// @param singleEntry is used by jbay pktgen, as the pktgen_tbl has only one entry.
// the entry index must be 0.
void ExtractDeparser::generateDigest(IR::BFN::Digest *&digest, cstring name,
                                      const IR::Expression *expr,
                                      const IR::MethodCallExpression* mc,
                                      cstring controlPlaneName,
                                      bool singleEntry) {
    int digest_index = 0;
    const IR::Literal *k = nullptr;
    const IR::Expression *select;
    if (!pred) {
        fatal_error(ErrorType::ERR_UNSUPPORTED, "%1%: Unsupported unconditional %2%.emit",
                    mc, name);
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
        fatal_error(ErrorType::ERR_UNSUPPORTED, "%1%: Unsupported condition %2% in %3%.emit",
                    mc, pred, name);
        return;
    } else if (k->is<IR::Constant>() && !singleEntry) {
        digest_index = k->to<IR::Constant>()->asInt();
    } else {
        digest_index = 0;
    }

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
        auto* fieldList = new IR::BFN::DigestFieldList(
                digest_index, sources, nullptr, controlPlaneName);
        digest->fieldLists.push_back(fieldList);
    } else if (auto *ref = expr->to<IR::ConcreteHeaderRef>()) {
        LOG1("concrete header ref " << expr);
        if (auto *st = expr->type->to<IR::Type_StructLike>()) {
            for (auto *item : st->fields) {
                sources.push_back(new IR::BFN::FieldLVal(gen_fieldref(ref->ref, item->name)));
            }
        }
        auto type = expr->type->to<IR::Type_StructLike>();
        if (type == nullptr)
            ::error("Digest field list %1% must be a struct/header type", expr);
        auto* fieldList =
            new IR::BFN::DigestFieldList(digest_index, sources, type, controlPlaneName);
        digest->fieldLists.push_back(fieldList);
    } else if (auto* initializer = expr->to<IR::StructExpression>()) {
        for (auto *item : initializer->components) {
            Pattern::Match<IR::Expression> e1;
            if (item->expression->is<IR::Concat>()) {
                process_concat(sources, item->expression->to<IR::Concat>());
            } else if (auto cst = item->expression->to<IR::Constant>()) {
                // We assume zero is the value for padding fields.
                if (cst->asInt() == 0)
                    sources.push_back(new IR::BFN::FieldLVal(new IR::Padding(cst->type)));
                else
                    ::error(ErrorType::ERR_UNSUPPORTED,
                            "Non-zero constant value %1% in digest field list"
                            " is not supported on tofino.", cst);
            } else if ((e1 == 1).match(item->expression) && e1->type->width_bits() == 1) {
                /* explicit comparison of a bit<1> to 1 -- just use the bit<1> directly */
                sources.push_back(new IR::BFN::FieldLVal(e1));
            } else {
                sources.push_back(new IR::BFN::FieldLVal(item->expression)); }
        }
        LOG3(" digest type " << expr->type);
        auto type = expr->type->to<IR::Type_StructLike>();
        if (type == nullptr)
            ::error("Digest field list %1% must be a struct/header type", expr);
        auto* fieldList =
            new IR::BFN::DigestFieldList(digest_index, sources, type, controlPlaneName);
        digest->fieldLists.push_back(fieldList);
    } else {
        BUG("Unexpected expression as digest field list ", expr);
    }
}

void ExtractDeparser::enforceHeaderOrdering() {
    ordered_map<cstring, std::vector<const IR::BFN::EmitField*>> reordered;

    for (auto& kv : headerToEmits) {
        auto header = kv.first;

        bool inserted = false;

        for (auto& ordering : userEnforcedHeaderOrdering) {
            if (ordering->count(header)) {
                for (auto hdr : *ordering) {
                    if (!reordered.count(hdr)) {
                        reordered[hdr] = headerToEmits[hdr];
                        LOG3("reordered header " << hdr << " because of @pragma header_ordering");
                    }
                }

                inserted = true;
            }
        }

        if (!inserted)
            reordered[header] = kv.second;
    }

    headerToEmits = reordered;
}

void ExtractDeparser::end_apply() {
    if (!userEnforcedHeaderOrdering.empty())
        enforceHeaderOrdering();

    for (auto& kv : headerToEmits) {
        for (auto emit : kv.second) {
            dprsr->emits.push_back(emit);
            LOG3("add " << emit << " to " << dprsr->gress << " deparser");
        }
    }
}

}  // namespace BFN

