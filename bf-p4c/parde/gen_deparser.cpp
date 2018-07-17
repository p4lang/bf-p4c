#include <boost/range/adaptor/reversed.hpp>

#include "frontends/p4/callGraph.h"
#include "ir/ir.h"
#include "bf-p4c/parde/gen_deparser.h"

namespace {

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

IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field) {
    const IR::Type *ftype = nullptr;
    auto f = hdr->type->getField(field);
    if (f != nullptr)
        ftype = f->type;
    else
        BUG("Couldn't find metadata field %s in %s", field, hdr->name);
    return new IR::Member(ftype, new IR::ConcreteHeaderRef(hdr), field);
}

class GenerateDeparser : public Inspector {
    IR::BFN::Deparser                           *dprsr;
    const IR::Expression                        *pred = nullptr;
    ordered_map<cstring, IR::BFN::Digest *>     digests;
    ordered_map<cstring, cstring>               nameMap;

    void generateDigest(IR::BFN::Digest *&digest, cstring name,
                        const IR::Expression *list, cstring controlPlaneName = nullptr);
    bool equiv(const IR::Expression *a, const IR::Expression *b) const;

    bool preorder(const IR::Declaration_Instance *decl) {
        nameMap.emplace(decl->name.name, decl->controlPlaneName());
        return false;
    }

    bool preorder(const IR::IfStatement *ifstmt) {
        const IR::Expression *old_pred = pred;
        pred = ifstmt->condition;
        if (old_pred) pred = new IR::LAnd(old_pred, pred);
        visit(ifstmt->ifTrue, "ifTrue");
        if (ifstmt->ifFalse) {
            pred = new IR::LNot(ifstmt->condition);
            if (old_pred) pred = new IR::LAnd(old_pred, pred);
            visit(ifstmt->ifFalse, "ifFalse"); }
        pred = old_pred;
        return false; }

    bool preorder(const IR::MethodCallExpression* mc) {
        auto method = mc->method->to<IR::Member>();
        if (!method) return true;
        if (method->member == "emit") {
            auto dname = method->expr->to<IR::PathExpression>();
            if (!dname) return true;

            auto type = dname->type->to<IR::Type_Extern>();
            if (!type) return true;

            if (type->name == "packet_out") {
                if (pred) error("Conditional emit %s not supported", mc);
                generateEmits((*mc->arguments)[0]->expression, [&](const IR::Expression* field,
                                                                   const IR::Expression* povBit) {
                    dprsr->emits.push_back(new IR::BFN::Emit(mc->srcInfo, field, povBit)); });
            } else if (type->name == "Mirror") {
                // Convert session_id, { field_list } --> { session_id, field_list }
                auto list = mc->arguments->at(1)->expression->to<IR::ListExpression>();
                auto expr = new IR::ListExpression(
                    list->srcInfo, list->type, list->components);
                expr->components.insert(expr->components.begin(),
                                        mc->arguments->at(0)->expression);
                generateDigest(digests["mirror"], "mirror", expr);
            } else if (type->name == "Resubmit") {
                generateDigest(digests["resubmit"], "resubmit",
                               mc->arguments->at(0)->expression);
            } else {
                error("Unsupported method call %s in deparser", mc);
            }
            return false;
        } else if (method->member == "update") {
            // XXX(hanw): call to checksum.update() in deparser is handled in checksum.cpp
            return false;
        } else if (method->member == "pack") {
            auto dname = method->expr->to<IR::PathExpression>();
            if (!dname) return true;
            auto cpn = nameMap.find(dname->path->name);
            BUG_CHECK(cpn != nameMap.end(), "unable to find digest %1%", dname->path->name);
            generateDigest(digests["learning"], "learning",
                           mc->arguments->at(0)->expression, cpn->second);
            return false;
        } else {
            error("Unsupported method call %s in deparser", mc);
            return true;
        }
    }

 public:
    explicit GenerateDeparser(IR::BFN::Deparser *d) : dprsr(d) {}
};

// FIXME -- factor this with Digests::add_to_digest in digest.h?
void GenerateDeparser::generateDigest(IR::BFN::Digest *&digest, cstring name,
                                      const IR::Expression *expr, cstring controlPlaneName) {
    const IR::Constant *k = nullptr;
    const IR::Expression *select;
    if (!pred) {
        error("%s:Unconditional %s.emit not supported", expr->srcInfo, name);
        return;
    } else if (auto eq = pred->to<IR::Equ>()) {
        if ((k = eq->left->to<IR::Constant>()))
            select = eq->right;
        else if ((k = eq->right->to<IR::Constant>()))
            select = eq->left; }
    if (!k) {
        error("%s.emit condition %s not supported", name, pred);
        return; }
    if (!digest) {
        digest = new IR::BFN::Digest(name, select);
        dprsr->digests.addUnique(name, digest);
    } else if (!equiv(select, digest->selector->field)) {
        error("Inconsistent %s selectors, %s and %s", name, select,
              digest->selector->field); }

    IR::Vector<IR::BFN::FieldLVal> sources;
    if (!expr) {
        // Treat as an empty list.
    } else if (auto* list = expr->to<const IR::Vector<IR::Expression>>()) {
        for (auto* item : *list)
          sources.push_back(new IR::BFN::FieldLVal(item));
    } else if (auto* list = expr->to<IR::ListExpression>()) {
        for (auto* item : list->components)
          sources.push_back(new IR::BFN::FieldLVal(item));
    } else if (auto *ref = expr->to<IR::ConcreteHeaderRef>()) {
        if (auto *st = expr->type->to<IR::Type_StructLike>()) {
            for (auto *item : st->fields) {
                sources.push_back(new IR::BFN::FieldLVal(gen_fieldref(ref->ref, item->name)));
            }
        }
    } else {
        sources.push_back(new IR::BFN::FieldLVal(expr));
    }

    auto* fieldList = new IR::BFN::DigestFieldList(sources, controlPlaneName);
    if (int(digest->fieldLists.size()) <= k->asInt())
        digest->fieldLists.resize(k->asInt() + 1);
    digest->fieldLists.at(k->asInt()) = fieldList;
}

// FIXME -- yet another 'deep' comparison for expressions
bool GenerateDeparser::equiv(const IR::Expression *a, const IR::Expression *b) const {
    if (a == b) return true;
    if (typeid(*a) != typeid(*b)) return false;
    if (auto ma = a->to<IR::Member>()) {
        auto mb = b->to<IR::Member>();
        return ma->member == mb->member && equiv(ma->expr, mb->expr); }
    if (auto pa = a->to<IR::PathExpression>()) {
        auto pb = b->to<IR::PathExpression>();
        return pa->path->name == pb->path->name; }
    if (auto ka = a->to<IR::Constant>()) {
        auto kb = b->to<IR::Constant>();
        return ka->value == kb->value; }
    return false;
}

}  // namespace

IR::BFN::Deparser::Deparser(gress_t gr, const IR::P4Control* dp)
        : AbstractDeparser(gr) {
    CHECK_NULL(dp);
    dp->apply(GenerateDeparser(this));
}

void BFN::ExtractDeparser::postorder(const IR::BFN::TranslatedP4Deparser* deparser) {
    gress_t thread = deparser->thread;
    rv->thread[thread].deparser = new IR::BFN::Deparser(thread, deparser);
}
