#include "frontends/p4/methodInstance.h"
#include "bf-p4c/device.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/extract_deparser.h"
#include "bf-p4c/bf-p4c-options.h"
#include "ir/pattern.h"

namespace BFN {

bool ExtractDeparser::preorder(const P4::IR::Annotation* annot) {
    if (annot->name == "header_ordering") {
        auto ordering = new ordered_set<cstring>;

        for (auto expr : annot->expr) {
            if (auto str = expr->to<P4::IR::StringLiteral>()) {
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

void ExtractDeparser::generateEmits(const P4::IR::MethodCallExpression* mc) {
    auto expr = (*mc->arguments)[0]->expression;

    auto* header = expr->to<P4::IR::HeaderRef>();

    BUG_CHECK(header != nullptr,
              "Emitting something other than a header: %1%", expr);
    auto* headerType = header->type->to<P4::IR::Type_StructLike>();
    BUG_CHECK(headerType != nullptr,
              "Emitting header with non-structlike type: %1%", headerType);

    auto* povBit = new P4::IR::Member(P4::IR::Type::Bits::get(1), header, "$valid");
    for (auto* f : headerType->fields) {
        auto* field = new P4::IR::Member(f->type, header, f->name);
        auto* emit = new P4::IR::BFN::EmitField(mc->srcInfo, field, povBit);

        if (auto concrete = header->to<P4::IR::ConcreteHeaderRef>()) {
            headerToEmits[concrete->ref->name].push_back(emit);
        } else if (auto stack = header->to<P4::IR::HeaderStackItemRef>()) {
            if (auto ref = stack->base_->to<P4::IR::V1InstanceRef>())
                headerToEmits[ref->name].push_back(emit);
            else if (auto ref = stack->base_->to<P4::IR::InstanceRef>())
                headerToEmits[ref->name].push_back(emit);
            else
                BUG("Unknown header stack type: %1%", header);
        }
    }
}

void ExtractDeparser::convertConcatToList(std::vector<const P4::IR::Expression*>& slices,
        const P4::IR::Concat* expr) {
    if (expr->left->is<P4::IR::Constant>()) {
        slices.push_back(expr->left);
    } else if (auto lhs = expr->left->to<P4::IR::Concat>()) {
        convertConcatToList(slices, lhs);
    } else {
        slices.push_back(expr->left); }

    if (expr->right->is<P4::IR::Constant>()) {
        slices.push_back(expr->right);
    } else if (auto rhs = expr->right->to<P4::IR::Concat>()) {
        convertConcatToList(slices, rhs);
    } else {
        slices.push_back(expr->right);
    }
}

void ExtractDeparser::processConcat(P4::IR::Vector<P4::IR::BFN::FieldLVal>& vec,
        const P4::IR::Concat* expr) {
    std::vector<const P4::IR::Expression *> slices;
    convertConcatToList(slices, expr);
    for (auto *item : slices) {
        if (item->is<P4::IR::Constant>())
            vec.push_back(new P4::IR::BFN::FieldLVal(new P4::IR::Padding(item->type)));
        else
            vec.push_back(new P4::IR::BFN::FieldLVal(item));
    }
}

/// Get digest index from the conditional in if statement.
std::tuple<int, const P4::IR::Expression*>
ExtractDeparser::getDigestIndex(const P4::IR::IfStatement* ifstmt, cstring name, bool singleEntry) {
    const P4::IR::Expression *pred = ifstmt->condition;

    const P4::IR::Literal *k = nullptr;
    const P4::IR::Expression* select = nullptr;
    if (auto eq = pred->to<P4::IR::Equ>()) {
        if ((k = eq->left->to<P4::IR::Constant>()))
            select = eq->right;
        else if ((k = eq->right->to<P4::IR::Constant>()))
            select = eq->left;
        else if ((k = eq->left->to<P4::IR::BoolLiteral>()))
            select = eq->right;
        else if ((k = eq->right->to<P4::IR::BoolLiteral>()))
            select = eq->left;
    } else if (auto bo = pred->to<P4::IR::Member>()) {
        // 'if (boolean)' is the same as 'if (boolean == 1)'
        if (bo->type->to<P4::IR::Type_Boolean>()) {
            k = new P4::IR::BoolLiteral(true);
            select = pred;
        }
    }

    int digest_index = 0;
    if (!k) {
        ::P4::error(ErrorType::ERR_UNSUPPORTED,
            "%1%: Unsupported condition %2% in %3%.emit", ifstmt, pred, name);
    } else if (k->is<P4::IR::Constant>() && !singleEntry) {
        digest_index = k->to<P4::IR::Constant>()->asInt();
    } else {
        digest_index = 0;
    }

    return std::make_tuple(digest_index, select);
}

/// Get digest index from constructor parameter
int ExtractDeparser::getDigestIndex(const P4::IR::Declaration_Instance* decl) {
    auto cst = decl->arguments->at(0)->expression->to<P4::IR::Constant>();
    if (!cst)
        fatal_error("%1%: constructor argument must be constant", decl);
    return cst->asInt();
}

P4::IR::ID ExtractDeparser::getTnaParamName(const P4::IR::BFN::TnaDeparser *deparser, P4::IR::ID orig_name) {
    for (auto& kv : deparser->tnaParams) {
        if (kv.second == orig_name.name) {
            return P4::IR::ID(orig_name.srcInfo, kv.first, orig_name.name);
        }
    }
    return orig_name;
}

/// handle deprecated syntax
void ExtractDeparser::processMirrorEmit(const P4::IR::MethodCallExpression* mc,
        const P4::IR::Expression* select, int idx) {
    if (mc->arguments->size() == 1) {
        auto session_id = mc->arguments->at(0)->expression;
        generateDigest(digests["mirror"_cs], "mirror"_cs, session_id, select, idx);
    } else if (mc->arguments->size() == 2) {
        auto expr = mc->arguments->at(1)->expression;
        if (auto list = expr->to<P4::IR::StructExpression>()) {
            // field list is StructExpression if source is P4-16
            // Convert session_id, { field_list } --> { session_id, field_list }
            auto components = new P4::IR::IndexedVector<P4::IR::NamedExpression>();
            auto session_id = new P4::IR::NamedExpression("$session_id"_cs,
                    mc->arguments->at(0)->expression);
            components->push_back(session_id);
            components->append(list->components);
            auto list_type = typeMap->getTypeType(mc->typeArguments->at(0), true);
            auto mirror_field_list =
                new P4::IR::StructExpression(list_type, list->structType, *components);
            generateDigest(digests["mirror"_cs], "mirror"_cs, mirror_field_list, select, idx);
        }
    }
}

void ExtractDeparser::processResubmitEmit(const P4::IR::MethodCallExpression* mc,
        const P4::IR::Expression* select, int idx) {
    auto num_args = mc->arguments->size();
    auto expr = (num_args == 0) ? nullptr  /* no argument in resubmit.emit() */
        : mc->arguments->at(0)->expression;
    generateDigest(digests["resubmit"_cs], "resubmit"_cs, expr, select, idx);
}

void ExtractDeparser::processMirrorEmit(const P4::IR::MethodCallExpression* mc, int idx) {
    auto deparser = findContext<P4::IR::BFN::TnaDeparser>();
    BUG_CHECK(deparser != nullptr,
            "ExtractDeparser must be applied to deparser block");
    int param_idx = Device::archSpec().getDeparserIntrinsicMetadataForDeparserParamIndex();
    auto param = deparser->type->applyParams->parameters.at(param_idx);
    auto st = param->type->to<P4::IR::Type_StructLike>();
    BUG_CHECK(st != nullptr,
            "Parameter type %1% must be a struct", param->type);
    auto name = getTnaParamName(deparser, param->name);
    auto meta = new P4::IR::Metadata(name, st);
    auto member = new P4::IR::Member(P4::IR::Type_Bits::get(Device::mirrorTypeWidth()),
            new P4::IR::ConcreteHeaderRef(meta), "mirror_type"_cs);
    processMirrorEmit(mc, member, idx);
}

void ExtractDeparser::processResubmitEmit(const P4::IR::MethodCallExpression* mc, int idx) {
    auto deparser = findContext<P4::IR::BFN::TnaDeparser>();
    BUG_CHECK(deparser != nullptr,
            "ExtractDeparser must be applied to deparser block");
    int param_idx = Device::archSpec().getDeparserIntrinsicMetadataForDeparserParamIndex();
    auto param = deparser->type->applyParams->parameters.at(param_idx);
    auto st = param->type->to<P4::IR::Type_StructLike>();
    BUG_CHECK(st != nullptr,
            "Parameter type %1% must be a struct", param->type);
    auto name = getTnaParamName(deparser, param->name);
    auto meta = new P4::IR::Metadata(name, st);
    auto member = new P4::IR::Member(new P4::IR::ConcreteHeaderRef(meta),
            "resubmit_type"_cs);
    processResubmitEmit(mc, member, idx);
}

void ExtractDeparser::processDigestPack(const P4::IR::MethodCallExpression* mc, int idx,
        cstring controlPlaneName) {
    auto deparser = findContext<P4::IR::BFN::TnaDeparser>();
    BUG_CHECK(deparser != nullptr,
            "ExtractDeparser must be applied to deparser block");
    int param_idx = Device::archSpec().getDeparserIntrinsicMetadataForDeparserParamIndex();
    auto param = deparser->type->applyParams->parameters.at(param_idx);
    auto st = param->type->to<P4::IR::Type_StructLike>();
    BUG_CHECK(st != nullptr,
            "Parameter type %1% must be a struct", param->type);
    auto name = getTnaParamName(deparser, param->name);
    auto meta = new P4::IR::Metadata(name, st);
    auto member = new P4::IR::Member(new P4::IR::ConcreteHeaderRef(meta),
            "digest_type"_cs);
    generateDigest(digests["learning"_cs], "learning"_cs,
            mc->arguments->at(0)->expression, member, idx,
            controlPlaneName);
}

/**
 * Converting P4::IR::MethodCallExpression to P4::IR::BFN::DigestFieldList.
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
void ExtractDeparser::postorder(const P4::IR::MethodCallExpression* mc) {
    auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);

    if (!mi->is<P4::ExternMethod>())
        return;

    auto em = mi->to<P4::ExternMethod>();

    if (em->actualExternType->name == "packet_out") {
        if (findContext<P4::IR::IfStatement>())
            error("Conditional emit %s not supported", mc);
        generateEmits(mc);
    }

    if (em->actualExternType->name == "Mirror") {
        if (auto inst = em->object->to<P4::IR::Declaration_Instance>()) {
            if (inst->arguments->size() == 0) {
                auto stmt = findContext<P4::IR::IfStatement>();
                if (!stmt) fatal_error(ErrorType::ERR_UNSUPPORTED,
                    "%1%: Unsupported unconditional %2%.emit", mc, inst->externalName());
                int idx;
                const P4::IR::Expression* select;
                std::tie(idx, select) = getDigestIndex(stmt, "Mirror"_cs, false);
                processMirrorEmit(mc, select, idx);
            } else {
                int idx = getDigestIndex(inst);
                processMirrorEmit(mc, idx);
            }
        }
    }

    if (em->actualExternType->name == "Resubmit") {
        if (auto inst = em->object->to<P4::IR::Declaration_Instance>()) {
            if (inst->arguments->size() == 0) {
                auto stmt = findContext<P4::IR::IfStatement>();
                if (!stmt) fatal_error(ErrorType::ERR_UNSUPPORTED,
                    "%1%: Unsupported unconditional %2%.emit", mc, inst->externalName());
                int idx;
                const P4::IR::Expression* select;
                std::tie(idx, select) = getDigestIndex(stmt, "Resubmit"_cs, false);
                processResubmitEmit(mc, select, idx);
            } else {
                int idx = getDigestIndex(inst);
                processResubmitEmit(mc, idx);
            }
        }
    }

    if (em->actualExternType->name == "Pktgen") {
        if (auto inst = em->object->to<P4::IR::Declaration_Instance>()) {
            auto stmt = findContext<P4::IR::IfStatement>();
            if (!stmt) fatal_error(ErrorType::ERR_UNSUPPORTED,
                    "%1%: Unsupported unconditional %2%.emit", mc, inst->externalName());
            const P4::IR::Expression* select;
            // pktgen_tbl has only one entry, digest_index is always 0.
            std::tie(std::ignore, select) = getDigestIndex(stmt, "Pktgen"_cs, false);
            auto expr = mc->arguments->at(0)->expression;
            generateDigest(digests["pktgen"_cs], "pktgen"_cs, expr, select, 0,
                    em->object->controlPlaneName());
        }
    }

    if (em->actualExternType->name == "Digest") {
        if (auto inst = em->object->to<P4::IR::Declaration_Instance>()) {
            if (inst->arguments->size() == 0) {
                auto stmt = findContext<P4::IR::IfStatement>();
                if (!stmt) fatal_error(ErrorType::ERR_UNSUPPORTED,
                        "%1%: Unsupported unconditional %2%.emit", mc, inst->externalName());
                int idx;
                const P4::IR::Expression* select;
                std::tie(idx, select) = getDigestIndex(stmt, "Digest"_cs, false);
                LOG1("index=" << idx <<", select=" << select);
                generateDigest(digests["learning"_cs], "learning"_cs,
                        mc->arguments->at(0)->expression, select, idx,
                        em->object->controlPlaneName());
            } else {
                int idx = getDigestIndex(inst);
                processDigestPack(mc, idx, em->object->controlPlaneName());
            }
        }
    }
}

bool ExtractDeparser::preorder(const P4::IR::AssignmentStatement* stmt) {
     const P4::IR::Type* leftType = nullptr;
     if (stmt->left->is<P4::IR::Member>()) {
         leftType = stmt->left->to<P4::IR::Member>()->expr->type;
     } else if (stmt->left->is<P4::IR::Slice>()) {
         auto slice = stmt->left->to<P4::IR::Slice>();
         auto member =  slice->e0->to<P4::IR::Member>();
         if (member) {
             leftType = member->expr->type;
         }
     } else {
         leftType = stmt->left->type;
     }
     auto methodCall = stmt->right->to<P4::IR::MethodCallExpression>();
     if (!methodCall) {
         auto ifStmt = findContext<P4::IR::IfStatement>();
         AssignmentStmtErrorCheck errorCheck(leftType);
         ifStmt->apply(errorCheck);
         if (!errorCheck.stmtOk) {
             ::P4::error("Assignment to a header field in the deparser is only allowed when "
                    "the source is checksum update, mirror, resubmit or learning digest. "
                    "Please move the assignment into the control flow %1%", stmt);
         }
     }
     return false;
}

/**
 * Collect information to generate assembly output.
 * @param singleEntry is used by jbay pktgen, as the pktgen_tbl has only one entry.
 *
 * The entry index must be 0.
 *
 * FIXME -- factor this with Digests::add_to_digest in digest.h?
 */
void ExtractDeparser::generateDigest(P4::IR::BFN::Digest *&digest, cstring name,
                                      const P4::IR::Expression *expr,
                                      const P4::IR::Expression *select,
                                      int digest_index,
                                      cstring controlPlaneName) {
    if (!digest) {
        digest = new P4::IR::BFN::Digest(name, select);
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

    P4::IR::Vector<P4::IR::BFN::FieldLVal> sources;
    if (!expr) {
        auto* fieldList = new P4::IR::BFN::DigestFieldList(
                digest_index, sources, nullptr, controlPlaneName);
        digest->fieldLists.push_back(fieldList);
    } else if (auto *ref = expr->to<P4::IR::ConcreteHeaderRef>()) {
        // e.g. emit(hdr);
        if (auto *st = expr->type->to<P4::IR::Type_StructLike>()) {
            for (auto *item : st->fields) {
                sources.push_back(new P4::IR::BFN::FieldLVal(gen_fieldref(ref->ref, item->name)));
            }
        }
        auto type = expr->type->to<P4::IR::Type_StructLike>();
        if (type == nullptr)
            ::P4::error("Digest field list %1% must be a struct/header type", expr);
        auto* fieldList =
            new P4::IR::BFN::DigestFieldList(digest_index, sources, type, controlPlaneName);
        digest->fieldLists.push_back(fieldList);
    } else if (auto* initializer = expr->to<P4::IR::StructExpression>()) {
        // e.g. emit({ ... })
        for (auto *item : initializer->components) {
            Pattern::Match<P4::IR::Expression> e1;
            if (item->expression->is<P4::IR::Concat>()) {
                processConcat(sources, item->expression->to<P4::IR::Concat>());
            } else if (auto cst = item->expression->to<P4::IR::Constant>()) {
                if (cst->asInt() == 0) {
                    // assume non-byte aligned zeros are used for padding.
                    if (cst->type->width_bits() % 8 != 0) {
                        sources.push_back(new P4::IR::BFN::FieldLVal(new P4::IR::Padding(cst->type)));
                    } else {
                        auto t = new P4::IR::TempVar(cst->type);
                        t->deparsed_zero = true;
                        sources.push_back(new P4::IR::BFN::FieldLVal(t)); }
                } else {
                    ::P4::error(ErrorType::ERR_UNSUPPORTED,
                            "Non-zero constant value %1% in digest field list"
                            " is not supported on tofino.", cst); }
            } else if ((e1 == 1).match(item->expression) && e1->type->width_bits() == 1) {
                /* explicit comparison of a bit<1> to 1 -- just use the bit<1> directly */
                sources.push_back(new P4::IR::BFN::FieldLVal(e1));
            } else {
                sources.push_back(new P4::IR::BFN::FieldLVal(item->expression)); }
        }

        // Merge padding fields and convert to temp vars for sections occupying whole bytes
        P4::IR::Vector<P4::IR::BFN::FieldLVal> adj_sources;
        if (name == "mirror") {
            bool is_mirror_id = true;
            int offset = 0;
            P4::IR::BFN::FieldLVal* prev_pad_lval = nullptr;
            for (auto* lval : sources) {
                int width = lval->field->type->width_bits();
                if (lval->field->is<P4::IR::Padding>()) {
                    // Merge with existing padding
                    if (prev_pad_lval) {
                        LOG5("Merging pad of " << width << "b and "
                                               << prev_pad_lval->field->type->width_bits() << "b");
                        width += prev_pad_lval->field->type->width_bits();
                        lval = new P4::IR::BFN::FieldLVal(new P4::IR::Padding(P4::IR::Type::Bits::get(width)));
                    }

                    // Output padding for chunks that don't start on a byte boundary but which reach
                    // the end of a byte
                    if ((offset % 8 != 0) && (offset % 8 + width >= 8)) {
                        LOG7("Outputting " << (8 - offset % 8) << "b pad");
                        int pad_width = 8 - offset % 8;
                        adj_sources.push_back(new P4::IR::BFN::FieldLVal(
                            new P4::IR::Padding(P4::IR::Type::Bits::get(pad_width))));
                        offset += pad_width;
                        width -= pad_width;
                    }

                    // Output tempvar for any byte-aligned 8b chunks
                    if (width >= 8) {
                        LOG7("Outputting " << (width & ~0x7) << "b temp var");
                        auto t = new P4::IR::TempVar(P4::IR::Type::Bits::get(width & ~0x7));
                        t->deparsed_zero = true;
                        adj_sources.push_back(new P4::IR::BFN::FieldLVal(t));

                        offset += width & ~0x7;
                        width &= 0x7;
                    }

                    // Record any remaining pad bits
                    prev_pad_lval =
                        width ? new P4::IR::BFN::FieldLVal(new P4::IR::Padding(P4::IR::Type::Bits::get(width)))
                              : nullptr;
                } else {
                    if (prev_pad_lval) {
                        LOG7("Outputting " << prev_pad_lval->field->type->width_bits() << "b pad");
                        adj_sources.push_back(prev_pad_lval);
                        offset += prev_pad_lval->field->type->width_bits();
                    }
                    adj_sources.push_back(lval);
                    offset += width;
                    prev_pad_lval = nullptr;
                }

                // First field is the mirror id/session and is not emitted, so ignore in offset calc
                if (is_mirror_id) {
                    offset = 0;
                    is_mirror_id = false;
                }
            }
            if (prev_pad_lval) {
                LOG7("Outputting " << prev_pad_lval->field->type->width_bits() << "b pad");
                adj_sources.push_back(prev_pad_lval);
                offset += prev_pad_lval->field->type->width_bits();
            }
        } else {
            adj_sources = sources;
        }

        auto type = expr->type->to<P4::IR::Type_StructLike>();
        if (type == nullptr)
            ::P4::error("Digest field list %1% must be a struct/header type", expr);
        auto* fieldList =
            new P4::IR::BFN::DigestFieldList(digest_index, adj_sources, type, controlPlaneName);
        digest->fieldLists.push_back(fieldList);
    } else if (auto session_id = expr->to<P4::IR::Member>()) {
        // e.g. emit(mirror.session_id)
        sources.push_back(new P4::IR::BFN::FieldLVal(session_id));
        auto* fieldList =
            new P4::IR::BFN::DigestFieldList(digest_index, sources, nullptr, controlPlaneName);
        digest->fieldLists.push_back(fieldList);
    } else if (auto cst = expr->to<P4::IR::Constant>()) {
        // e.g. emit(0)
        auto t = new P4::IR::TempVar(cst->type);
        t->deparsed_zero = true;
        sources.push_back(new P4::IR::BFN::FieldLVal(t));
        auto* fieldList =
            new P4::IR::BFN::DigestFieldList(digest_index, sources, nullptr, controlPlaneName);
        digest->fieldLists.push_back(fieldList);
    } else {
        ::P4::error(ErrorType::ERR_UNSUPPORTED,
            "expression %1% in %2%", expr, name);
    }
}

void ExtractDeparser::enforceHeaderOrdering() {
    ordered_map<cstring, std::vector<const P4::IR::BFN::EmitField*>> reordered;

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
