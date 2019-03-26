#include "bf-p4c/device.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/parde/gen_deparser.h"
#include "bf-p4c/bf-p4c-options.h"

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

class GenerateDeparser : public Inspector {
    const IR::BFN::Pipe                         *pipe;
    IR::BFN::Deparser                           *dprsr;
    const IR::Expression                        *pred = nullptr;
    ordered_map<cstring, IR::BFN::Digest *>     digests;
    ordered_map<cstring, cstring>               nameMap;

    void generateDigest(IR::BFN::Digest *&digest, cstring name,
                        const IR::Expression *list, cstring controlPlaneName = nullptr);
    void simpl_concat(std::vector<const IR::Expression*>& slices, const IR::Concat* expr) {
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
            slices.push_back(expr->right); } }

    void process_concat(IR::Vector<IR::BFN::FieldLVal>& vec, const IR::Concat* expr) {
        std::vector<const IR::Expression *> slices;
        simpl_concat(slices, expr);
        for (auto *item : slices) {
            if (item->is<IR::Constant>()) {
                ::warning("Tofino does not support emitting constant %1% "
                          "in digest, skipped", item);
                continue; }
            vec.push_back(new IR::BFN::FieldLVal(item)); }
    }

    bool preorder(const IR::Declaration_Instance *decl) override {
        nameMap.emplace(decl->name.name, decl->controlPlaneName());
        return false;
    }

    bool preorder(const IR::IfStatement *ifstmt) override {
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

    bool preorder(const IR::MethodCallExpression* mc) override {
        auto method = mc->method->to<IR::Member>();
        if (!method) return true;
        if (method->member == "emit") {
            auto dname = method->expr->to<IR::PathExpression>();
            if (!dname) return true;

            auto type = dname->type->to<IR::Type_Extern>();
            if (!type) return true;

            if (type->name == "packet_out") {
                if (pred) error("Conditional emit %s not supported", mc);
                generateEmits((*mc->arguments)[0]->expression,
                    [&](const IR::Expression* field, const IR::Expression* povBit) {
                    dprsr->emits.push_back(new IR::BFN::EmitField(mc->srcInfo, field, povBit)); });
            } else if (type->name == "Mirror") {
                // Convert session_id, { field_list } --> { session_id, field_list }
                auto list = mc->arguments->at(1)->expression->to<IR::ListExpression>();
                auto expr = new IR::ListExpression(
                    list->srcInfo, list->type, list->components);
                expr->components.insert(expr->components.begin(),
                                        mc->arguments->at(0)->expression);
                generateDigest(digests["mirror"], "mirror", expr);
            } else if (type->name == "Resubmit") {
                auto num_args = mc->arguments->size();
                auto expr = (num_args == 0) ? new IR::ListExpression({})
                                            : mc->arguments->at(0)->expression;
                generateDigest(digests["resubmit"], "resubmit", expr);
            } else if (type->name == "Pktgen") {
                auto expr = mc->arguments->at(0)->expression;
                generateDigest(digests["pktgen"], "pktgen", expr);
            } else {
                fatal_error(ErrorType::ERR_UNSUPPORTED,
                            "Unsupported method call %1% in deparser", mc);
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
            fatal_error(ErrorType::ERR_UNSUPPORTED, "Unsupported method call %1% in deparser", mc);
            return true;
        }
    }

    void end_apply() override {
       for (const auto& kv : digests) {
           auto name = kv.first;
           auto digest = kv.second;
           for (auto fieldList : digest->fieldLists) {
               if (fieldList->idx < 0 ||
                   fieldList->idx > static_cast<int>(Device::maxCloneId(dprsr->gress))) {
                   ::error("Invalid %1% index %2% in %3%", name, fieldList->idx, dprsr->gress);
               }
           }
       }

       // COMPILER-914: In Tofino, clone id - 0 is reserved in i2e
       // due to a hardware bug. Hence, valid clone ids are 1 - 7.
       // We check mirror id 0 is not used in the program, and create a dummy
       // mirror (with id = 0) for i2e;
       if (dprsr->gress == INGRESS && Device::currentDevice() == Device::TOFINO &&
           BackendOptions().arch == "v1model") {
           // TODO(zma) it's not very clear to me how to handle this for TNA program
           // in particular, the mirror id is a user defined field. So we probably
           // need to find the field reference of mirror id in the program.

           auto mirror = digests["mirror"];
           if (mirror) {
               for (auto fieldList : mirror->fieldLists) {
                   if (fieldList->idx == 0)
                       ::error("Invalid mirror index 0, valid i2e mirror indices are 1-7");
               }
           } else {
               auto deparserMetadataHdr =
                   getMetadataType(pipe, "ingress_intrinsic_metadata_for_deparser");
               auto select = gen_fieldref(deparserMetadataHdr, "mirror_type");
               mirror = new IR::BFN::Digest("mirror", select);
               dprsr->digests.addUnique("mirror", mirror);
           }

           IR::Vector<IR::BFN::FieldLVal> sources;
           auto compilerMetadataHdr = getMetadataType(pipe, "compiler_generated_meta");
           auto mirrorId = gen_fieldref(compilerMetadataHdr, "mirror_id");
           sources.push_back(new IR::BFN::FieldLVal(mirrorId));
           auto dummy = new IR::BFN::DigestFieldList(0, sources, nullptr);
           mirror->fieldLists.push_back(dummy);
       }
    }

 public:
    explicit GenerateDeparser(const IR::BFN::Pipe* p, IR::BFN::Deparser *d) : pipe(p), dprsr(d) {}
};

// FIXME -- factor this with Digests::add_to_digest in digest.h?
void GenerateDeparser::generateDigest(IR::BFN::Digest *&digest, cstring name,
                                      const IR::Expression *expr, cstring controlPlaneName) {
    int digest_index = 0;
    const IR::Literal *k = nullptr;
    const IR::Expression *select;
    if (!pred) {
        // error(ErrorType::ERR_UNSUPPORTED, "unconditional %2%.emit", expr->srcInfo, name);
        error("%s Unsupported unconditional %s.emit", expr->srcInfo, name);
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
        error("Unsupported condition %s in %s.emit", pred, name);
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

}  // namespace

IR::BFN::Deparser::Deparser(gress_t gr, const IR::BFN::Pipe* pipe, const IR::P4Control* dp)
        : AbstractDeparser(gr) {
    CHECK_NULL(dp);
    dp->apply(GenerateDeparser(pipe, this));
}

void BFN::ExtractDeparser::postorder(const IR::BFN::TnaDeparser* deparser) {
    gress_t thread = deparser->thread;
    rv->thread[thread].deparser = new IR::BFN::Deparser(thread, rv, deparser);
}
