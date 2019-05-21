#include "bf-p4c/parde/deparser_checksum_update.h"

#include <map>

#include "ir/ir.h"
#include "ir/pattern.h"
#include "lib/error.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/device.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/parde/parser_info.h"
#include "logging/filelog.h"
namespace {

struct ChecksumUpdateInfo {
    ChecksumUpdateInfo(cstring dest, const IR::Vector<IR::BFN::FieldLVal>* sources,
           std::map<int, int> sourceToOffset) :
        dest(dest), sources(sources), sourceToOffset(sourceToOffset) { }

    cstring dest;

    const IR::Vector<IR::BFN::FieldLVal>* sources;
    const IR::BFN::FieldLVal* povBit = nullptr;
    std::map<int, int> sourceToOffset;
    ordered_set<std::pair<const IR::Member*, bool>> updateConditions;
    // one deparse updated bit for each condition
    std::map<const IR::Member*, const IR::TempVar*> deparseUpdated;

    const IR::TempVar* deparseOriginal = nullptr;
};

using ChecksumUpdateInfoMap = std::map<cstring, ChecksumUpdateInfo*>;


using ParserStateChecksumMap = std::map<const IR::ParserState*,
    std::vector<const IR::MethodCallExpression*>>;

static bool checksumUpdateSanityCheck(const IR::AssignmentStatement* assignment) {
    auto destField = assignment->left->to<IR::Member>();
    auto methodCall = assignment->right->to<IR::MethodCallExpression>();
    if (!methodCall || !methodCall->method)
        return false;

    auto member = methodCall->method->to<IR::Member>();
    if (!member || member->member != "update")
        return false;

    if (!destField || !destField->expr->is<IR::HeaderRef>()) {
        ::error("Destination of checksum calculation must be a header field: %1%",
                destField);
        return false;
    }

    if (destField->type->width_bits() != 16) {
        ::error("Output of checksum calculation can only be stored in a 16-bit field: %1%",
                destField);
        return false;
    }
    LOG4("checksum update field: " << destField);

    const IR::ListExpression* sourceList =
        (*methodCall->arguments)[0]->expression->to<IR::ListExpression>();

    if (!sourceList || sourceList->components.empty()) {
        ::error("Invalid list of fields for checksum calculation: %1%", methodCall);
            return false;
    }

    for (auto* source : sourceList->components) {
        if (auto* member = source->to<IR::Member>()) {
            if (!member->expr->is<IR::HeaderRef>()) {
                ::error("Invalid field in the checksum calculation: %1%", source);
                return false;
            }
        } else if (source->is<IR::Constant>()) {
            // TODO can constant be any bit width? signed?
        }
    }

    if (sourceList->components.empty()) {
        ::error("Expected at least one field in the checksum calculation: %1%",
                methodCall);
        return false;
    }

    return true;
}
bool checkIncorrectCsumFields(const IR::HeaderOrMetadata* last,
                                 const IR::HeaderOrMetadata* current) {
       // if current field is from a different header, fields till current field should add up
       // to multiple of 8 bits
    if (last != current && last && last->is<IR::Header>()) {
        return true;
      // Only metadata are allowed after a constant which is not multiple of 8
    } else if (!last && current->is<IR::Header>()) {
        return true;
    } else {
        return false;
    }
}


ChecksumUpdateInfo*
analyzeUpdateChecksumStatement(const IR::AssignmentStatement* assignment) {
    if (!checksumUpdateSanityCheck(assignment))
        return nullptr;

    auto destField = assignment->left->to<IR::Member>();
    auto methodCall = assignment->right->to<IR::MethodCallExpression>();

    const IR::ListExpression* sourceList =
        (*methodCall->arguments)[0]->expression->to<IR::ListExpression>();
    const IR::HeaderOrMetadata* currentFieldHeaderRef = nullptr;
    const IR::HeaderOrMetadata* lastFieldHeaderRef = nullptr;
    std::map<int, int> sourceToOffset;
    auto* sources = new IR::Vector<IR::BFN::FieldLVal>;
    int offset = 0;
    std::stringstream msg;

    // Along with collecting checksum update fields, following checks are performed:
    // * Fields of a header should always be byte aligned. This rule is relaxed for metadata.
    // * Sum of all the bits in the checksum list should be equal to a multiple of 8.

    for (auto* source : sourceList->components) {
        if (source->is<IR::Member>() || source->is<IR::Constant>()) {
            if (auto* constant = source->to<IR::Constant>()) {
                if (constant->asInt() != 0) {
                ::fatal_error("Non-zero constant entry in checksum calculation"
                        " not implemented yet: %1%", source);
                }
                currentFieldHeaderRef = nullptr;
            } else if (auto* member = source->to<IR::Member>()) {
                currentFieldHeaderRef = member->expr->to<IR::ConcreteHeaderRef>()->ref;
                sources->push_back(new IR::BFN::FieldLVal(member));
                sourceToOffset[sources->size() - 1] = offset;
            }

            if (offset % 8 && checkIncorrectCsumFields(lastFieldHeaderRef, currentFieldHeaderRef)) {
                msg << "In checksum update list, fields before " << source
                    << " do not add up to a multiple of 8 bits. Total bits until " << source
                    << " : " << offset;
                ::fatal_error("%1% %2%", source->srcInfo, msg.str());
            }

            lastFieldHeaderRef = currentFieldHeaderRef;
            offset += source->type->width_bits();
            LOG4("checksum update includes field:" << source);

        } else if (auto* header = source->to<IR::ConcreteHeaderRef>()) {
            auto headerRef = header->baseRef();
            if (offset % 8 && checkIncorrectCsumFields(lastFieldHeaderRef, headerRef)) {
                std::stringstream msg;
                msg << "In checksum update list, fields before the header " << header
                    << " do not add up to a multiple of 8 bits. Total bits until " << header
                    << " : " << offset;
                ::fatal_error("%1% %2%", source->srcInfo, msg.str());
            }

            for (auto field : headerRef->type->fields) {
                auto* member = new IR::Member(field->type, header, field->name);
                sources->push_back(new IR::BFN::FieldLVal(member));
                sourceToOffset[sources->size() - 1] = offset;
                LOG4("checksum update includes field:" << field);
                offset += member->type->width_bits();
            }
            lastFieldHeaderRef = headerRef;
        } else {
            :: error("Invalid entry in checksum calculation %1%", source);
        }
    }
    if (sources->size() && offset % 8) {
        std::stringstream msg;
        msg << "Fields in checksum update list do not add up to a multiple of 8 bits."
            << " Total bits: "<< offset;
        ::fatal_error("%1%", msg.str());
    }

    auto info = new ChecksumUpdateInfo(destField->toString(), sources, sourceToOffset);

    return info;
}

static std::pair<const IR::Member*, bool>
analyzeUpdateChecksumCondition(const IR::IfStatement* ifstmt) {
    bool leftOk = false, rightOk = false, updateConditionNegated = false;
    if (!ifstmt->ifTrue || ifstmt->ifFalse) {
        return std::make_pair(nullptr, false);
    }
    auto* condition = ifstmt->condition;
    Pattern::Match<IR::Member> field;
    Pattern::Match<IR::Constant> constant;
    if (condition) {
       if (auto* eq = condition->to<IR::Equ>()) {
           if ((field == constant).match(eq)) {
              if (constant->type->width_bits() == 1) {
                  rightOk = true;
                  if (constant->value != 0) {
                      updateConditionNegated = false;
                  } else {
                      updateConditionNegated = true;
                  }
              }
              if (field->type->width_bits() == 1) {
                  leftOk = true;
              }
           }
           if (leftOk && rightOk)
              return std::make_pair(eq->left->to<IR::Member>(), updateConditionNegated);
       } else {
            if (auto* NotCondition = condition->to<IR::LNot>()) {
                condition = NotCondition->expr;
                updateConditionNegated = true;
            }
            if (auto* condMember = condition->to<IR::Member>()) {
               if (condMember->type->is<IR::Type_Boolean>()) {
                   return std::make_pair(condMember, updateConditionNegated);
               }
            }
       }
       std::stringstream msg;
       msg << "Tofino only supports 1-bit checksum update condition in the deparser; "
           << "Please move the update condition into the control flow";

       ::error("%1%: %2%", msg.str(), condition);
    }
    return std::make_pair(nullptr, updateConditionNegated);
}

struct CollectUpdateChecksums : public Inspector {
    ChecksumUpdateInfoMap checksums;
    bool preorder(const IR::AssignmentStatement* assignment) {
        auto csum = analyzeUpdateChecksumStatement(assignment);

        if (csum && checksums.count(csum->dest))
            csum = checksums.at(csum->dest);

        if (csum) {
            auto ifStmt = findContext<IR::IfStatement>();
            if (ifStmt) {
                auto updateCondition = analyzeUpdateChecksumCondition(ifStmt);
                if (updateCondition.first) {
                    csum->updateConditions.insert(updateCondition);
                }
            }

            checksums[csum->dest] = csum;
        }

        return false;
    }
};

struct GetChecksumPovBits : public Inspector {
    ChecksumUpdateInfoMap& checksums;

    explicit GetChecksumPovBits(ChecksumUpdateInfoMap& checksums)
        : checksums(checksums) { }

    // FIXME -- yet another 'deep' comparison for expressions
    bool equiv(const IR::Expression* a, const IR::Expression* b) {
        if (a == b) return true;
        if (typeid(*a) != typeid(*b)) return false;
        if (auto ma = a->to<IR::Member>()) {
            auto mb = b->to<IR::Member>();
            return ma->member == mb->member && equiv(ma->expr, mb->expr); }
        if (auto ra = a->to<IR::ConcreteHeaderRef>()) {
            auto rb = b->to<IR::ConcreteHeaderRef>();
            return ra->equiv(*rb); }
        return false;
    }

    bool preorder(const IR::BFN::EmitField* emit) override {
        auto source = emit->source->field->to<IR::Member>();
        if (checksums.count(source->toString())) {
            auto csum = checksums.at(source->toString());
            csum->povBit = emit->povBit;

            std::set<std::pair<const IR::Member*, bool>> redundants;
            for (auto uc : csum->updateConditions) {
                if (equiv(csum->povBit->field, uc.first))
                    redundants.insert(uc);
            }

            for (auto uc : redundants) {
                // Checksum update condition is header validity bit
                csum->updateConditions.erase(uc);
            }

            // TODO(zma) If the condition bit dominates the header validity bit
            // in the parse graph, we can also safely ignore the condition.
        }

        return false;
    }

    void end_apply() override {
        std::set<cstring> toElim;

        for (auto& csum : checksums)
            if (csum.second->povBit == nullptr)
                toElim.insert(csum.first);

        for (auto csum : toElim) {
            LOG4("eliminate unpredicated checksum");
            checksums.erase(csum);
        }
    }
};

/// Substitute computed checksums into the deparser code by replacing EmitFields for
/// the destination field with EmitChecksums.
struct SubstituteUpdateChecksums : public Transform {
    explicit SubstituteUpdateChecksums(const ChecksumUpdateInfoMap& checksums)
        : checksums(checksums) { }

 private:
    IR::BFN::Deparser*
    preorder(IR::BFN::Deparser* deparser) override {
        IR::Vector<IR::BFN::Emit> newEmits;

        for (auto* p : deparser->emits) {
            bool rewrite = false;

            auto* emit = p->to<IR::BFN::EmitField>();
            if (emit->source->field->is<IR::Member>()) {
                auto* source = emit->source->field->to<IR::Member>();
                if (checksums.find(source->toString()) != checksums.end()) {
                    auto emitChecksums = rewriteEmitChecksum(emit);
                    for (auto* ec : emitChecksums) {
                        newEmits.push_back(ec);
                    }
                    rewrite = true;
                }
            }

            if (!rewrite)
                newEmits.push_back(emit);
        }

        deparser->emits = newEmits;
        return deparser;
    }

    std::vector<IR::BFN::Emit*>
    rewriteEmitChecksum(const IR::BFN::EmitField* emit) {
        auto* source = emit->source->field->to<IR::Member>();
        auto* csumInfo = checksums.at(source->toString());

        std::vector<IR::BFN::Emit*> emitChecksums;

        if (!csumInfo->updateConditions.empty()) {
            // If update condition is specified, we create two emits: one for
            // the updated checksum, and one for the original checksum from header.
            // The POV bits for these emits are inserted by the compiler (see
            // pass "InsertChecksumConditions" below).

            for (auto uc : csumInfo->updateConditions) {
                auto* emitUpdatedChecksum = new IR::BFN::EmitChecksum(
                                 new IR::BFN::FieldLVal(csumInfo->deparseUpdated.at(uc.first)),
                                    *(csumInfo->sources),
                                        new IR::BFN::ChecksumLVal(source));
                emitUpdatedChecksum->source_index_to_offset = csumInfo->sourceToOffset;

                emitChecksums.push_back(emitUpdatedChecksum);
            }

            auto* emitOriginalChecksum = new IR::BFN::EmitField(source, csumInfo->deparseOriginal);

            emitChecksums.push_back(emitOriginalChecksum);
        } else {
            // If no user specified update condition, the semantic is
            // to deparse based on the header validity bit.

            auto* emitUpdatedChecksum = new IR::BFN::EmitChecksum(
                                      emit->povBit,
                                        *(csumInfo->sources),
                                          new IR::BFN::ChecksumLVal(source));
            emitUpdatedChecksum->source_index_to_offset = csumInfo->sourceToOffset;
            emitChecksums.push_back(emitUpdatedChecksum);
        }

        // TODO(zma) if user specifies the update conditon, but never set it anywhere,
        // we should treat it as if no condition is specified.

        return emitChecksums;
    }

    std::map<const IR::Member*, const IR::Member*> negatedUpdateConditions;

    const ChecksumUpdateInfoMap& checksums;
};

/// If checksum update is unconditional, we don't need to allocate PHV space to store
/// the original header checksum field, nor do we need to extract the header checksum
/// field (since we will deparse the checksum from the computed value in the deparser).
/// This pass replaces the unconditional checksum field with the "ChecksumLVal" so that
/// PHV allocation doesn't allocate container for it.
/// FIXME(zma) check if checksum is used in MAU
struct SubstituteChecksumLVal : public Transform {
    explicit SubstituteChecksumLVal(const ChecksumUpdateInfoMap& checksums)
        : checksums(checksums) { }

    IR::BFN::ParserPrimitive* preorder(IR::BFN::Extract* extract) override {
        prune();
        if (checksums.find(extract->dest->toString()) != checksums.end()) {
            auto csumInfo = checksums.at(extract->dest->toString());

            if (csumInfo->updateConditions.empty()) {
                if (auto lval = extract->dest->to<IR::BFN::FieldLVal>()) {
                    return new IR::BFN::Extract(
                        new IR::BFN::ChecksumLVal(lval->field),
                        extract->source);
                }
            }
        }

        return extract;
    }

    const ChecksumUpdateInfoMap& checksums;
};

/// For each user checksum update condition bit, e.g.
///
///   calculated_field hdr.checksum  {
///       update tcp_checksum if (meta.update_checksum == 1);
///   }
///
/// we need to create two bits to predicate two FD entries in the
/// deparser, one for the updated checksum value, the other for
/// the original checksum value from packet.
/// The logic for these two bits are:
///
///   $deparse_updated_csum = update_checksum & hdr.$valid
///   $deparse_original_csum = !update_checksum & hdr.$valid
///
/// At the end of the table sequence of each gress, we insert
/// a table that runs an action that contains the two instructions
/// for all user condition bits. This is the correct place to insert
/// the table since header maybe become validated/invalidated
/// anywhere in the parser or MAU. It is possible that we could
/// insert these instructions earlier in the table sequence (thus
/// saving a table) if the compiler can figure out an action
/// is predicated by the header validity bit, but this should be a
/// general table "fusing" optimization in the backend.

struct InsertChecksumConditions : public Transform {
    explicit InsertChecksumConditions(const ChecksumUpdateInfoMap& checksums, gress_t gress)
        : checksums(checksums), gress(gress) { }

 private:
    IR::MAU::TableSeq*
    preorder(IR::MAU::TableSeq* tableSeq) override {
        bool hasUpdateCondition = false;

        for (auto& csum : checksums) {
            auto csumInfo = csum.second;
            if (!csumInfo->updateConditions.empty()) {
                hasUpdateCondition = true;
                break;
            }
        }

        if (!hasUpdateCondition)
            return tableSeq;

        prune();

        for (auto& csum : checksums) {
            auto csumInfo = csum.second;

            LOG2("insert checksum update condition for " << csumInfo->dest);

            if (!csumInfo->updateConditions.empty()) {
                auto action = new IR::MAU::Action("__checksum_update_condition__");
                action->default_allowed = action->init_default = true;

                if (csumInfo->updateConditions.size() > 2) {
                    std::stringstream msg;

                    msg << csumInfo->dest << " has more than two update conditions. "
                        << "The compiler currently can only support up to two conditions on"
                        << " each calculated field.";

                    ::error("%1%", msg.str());

                    // The ALU can only source two inputs, therefore we can only implement
                    // two input function using the ALU.
                    // TODO(zma) To support more than 2 conditions, we need to use static
                    // entries to implement the truth table of a multi-input function.
                }

                std::pair<const IR::Member*, bool> cond0, cond1;
                int cond_idx = 0;
                for (auto uc : csumInfo->updateConditions) {
                    if (cond0.first)
                        cond1 = uc;
                    else
                        cond0 = uc;

                    csumInfo->deparseUpdated[uc.first] = new IR::TempVar(
                                             IR::Type::Bits::get(1), true,
                        csumInfo->dest + ".$deparse_updated_csum_" + std::to_string(cond_idx++));
                }

                csumInfo->deparseOriginal = new IR::TempVar(
                                         IR::Type::Bits::get(1), true,
                                     csumInfo->dest + ".$deparse_original_csum");

                // $deparse_updated_0 = cond0
                // $deparse_updated_1 = !cond0 & cond1
                // $deparse_original = !cond0 & !cond1

                cstring setdu0_op, setdu1_op, setdo_op;
                setdu0_op = cond0.second ? "not" : "set";
                auto setdu0 = new IR::MAU::Instruction(setdu0_op,
                            { csumInfo->deparseUpdated.at(cond0.first), cond0.first});
                action->action.push_back(setdu0);

                if (cond1.first) {
                    if (!cond0.second && !cond1.second) {
                        setdu1_op = "andca";
                        setdo_op = "nor";
                    } else if (cond0.second && cond1.second) {
                        setdu1_op = "andcb";
                        setdo_op = "and";
                    } else if (cond0.second && !cond1.second) {
                        setdu1_op = "and";
                        setdo_op = "andcb";
                    } else {
                        setdu1_op = "nor";
                        setdo_op = "andca";
                    }
                    auto setdu1 = new IR::MAU::Instruction(setdu1_op,
                            { csumInfo->deparseUpdated.at(cond1.first), cond0.first, cond1.first});
                    auto setdo = new IR::MAU::Instruction(setdo_op,
                            { csumInfo->deparseOriginal, cond0.first, cond1.first});
                    action->action.push_back(setdu1);
                    action->action.push_back(setdo);
                } else {
                    setdo_op = cond0.second ? "set" : "not";
                    auto setdo = new IR::MAU::Instruction(setdo_op,
                                { csumInfo->deparseOriginal, cond0.first});
                    action->action.push_back(setdo);
                }
                cstring tableName = csumInfo->dest + "_encode_update_condition_" +
                                 toString(gress);

                auto gw = new IR::MAU::Table(tableName + "_gw", gress, csumInfo->povBit->field);
                gw->is_compiler_generated = true;

                auto condTable = new IR::MAU::Table(tableName, gress);
                condTable->is_compiler_generated = true;
                condTable->actions[action->name] = action;

                gw->next.emplace("$true", new IR::MAU::TableSeq(condTable));

                auto p4Name = tableName + "_" + cstring::to_cstring(gress);
                condTable->match_table = new IR::P4Table(p4Name.c_str(), new IR::TableProperties());

                tableSeq->tables.push_back(gw);
            }
        }

        return tableSeq;
    }

    const ChecksumUpdateInfoMap& checksums;
    const gress_t gress;
};

struct CollectFieldToState : public Inspector {
    std::map<const IR::Expression*, const IR::BFN::ParserState*> field_to_state;

    bool preorder(const IR::BFN::Extract* extract) override {
        auto state = findContext<IR::BFN::ParserState>();
        CHECK_NULL(state);

        field_to_state[extract->dest->field] = state;
        return false;
    }
};

struct CheckNestedChecksumUpdates : public Inspector {
    const IR::BFN::ParserGraph& graph;
    const std::map<const IR::Expression*, const IR::BFN::ParserState*>& field_to_state;

    std::set<const IR::BFN::EmitChecksum*> visited;

    explicit CheckNestedChecksumUpdates(const IR::BFN::ParserGraph& graph,
            const std::map<const IR::Expression*, const IR::BFN::ParserState*>& field_to_state) :
        graph(graph), field_to_state(field_to_state) { }

    void print_error(const IR::BFN::EmitChecksum* a, const IR::BFN::EmitChecksum* b) {
        if (Device::currentDevice() == Device::TOFINO) {
            std::stringstream hint;

            hint << "Consider using checksum units in both ingress and egress deparsers";

            if (BackendOptions().arch == "v1model") {
                hint << " (@pragma calculated_field_update_location/";
                hint << "residual_checksum_parser_update_location)";
            }

            hint << ".";

            ::fatal_error("Tofino does not support nested checksum updates in the same deparser:"
                          " %1%, %2%\n%3%", a->dest->field, b->dest->field, hint.str());

        } else if (Device::currentDevice() == Device::JBAY) {
            P4C_UNIMPLEMENTED("Nested checksum updates is currently "
                              "unsupported by the compiler for Tofino2: %1%, %2%",
                              a->dest->field, b->dest->field);
        } else {
            BUG("Unknown device");
        }
    }

    const IR::BFN::ParserState* find_state(const IR::Expression* a) {
        for (auto& kv : field_to_state) {
            if (kv.first->equiv(*a))
                return kv.second;
        }

        return nullptr;
    }

    bool can_be_on_same_parse_path(const IR::Expression* a, const IR::Expression* b) {
        auto sa = find_state(a);
        auto sb = find_state(b);

        if (sa && sb) {
            if (graph.is_descendant(sa, sb) || graph.is_descendant(sb, sa))
                return true;
        }

        return false;
    }

    bool preorder(const IR::BFN::EmitChecksum* checksum) override {
        for (auto c : visited) {
            if (!can_be_on_same_parse_path(c->dest->field, checksum->dest->field))
                continue;

            for (auto s : checksum->sources) {
                if (c->dest->field->equiv(*s->field))
                    print_error(checksum, c);
            }

            for (auto s : c->sources) {
                if (checksum->dest->field->equiv(*s->field))
                    print_error(checksum, c);
            }
        }

        visited.insert(checksum);

        return false;
    }
};

}  // namespace

namespace BFN {

/// This function extracts checksum from the translated tofino.p4 checksum extern.
/// Error checking should be done during the translation, not in this function.
IR::BFN::Pipe*
extractChecksumFromDeparser(const IR::BFN::TnaDeparser* deparser, IR::BFN::Pipe* pipe) {
    CHECK_NULL(pipe);

    if (!deparser) return pipe;

    if (BackendOptions().verbose > 0)
        Logging::FileLog parserLog(pipe->id, "parser.log");

    auto gress = deparser->thread;

    CollectUpdateChecksums collectChecksums;

    deparser->apply(collectChecksums);
    auto checksums = collectChecksums.checksums;

    if (checksums.empty()) return pipe;

    GetChecksumPovBits getChecksumPovBits(checksums);
    pipe->thread[gress].deparser->apply(getChecksumPovBits);

    SubstituteUpdateChecksums substituteChecksums(checksums);
    SubstituteChecksumLVal substituteChecksumLVal(checksums);
    InsertChecksumConditions insertChecksumConditions(checksums, gress);

    pipe->thread[gress].mau = pipe->thread[gress].mau->apply(insertChecksumConditions);
    pipe->thread[gress].deparser = pipe->thread[gress].deparser->apply(substituteChecksums);
    for (auto& parser : pipe->thread[gress].parsers) {
        parser = parser->apply(substituteChecksumLVal);
    }

    for (auto& parser : pipe->thread[gress].parsers) {
        CollectParserInfo cg;
        parser->apply(cg);

        CollectFieldToState cfs;
        parser->apply(cfs);

        auto graph = cg.graphs().at(parser->to<IR::BFN::Parser>());
        CheckNestedChecksumUpdates checkNestedChecksumUpdates(*graph, cfs.field_to_state);

        pipe->thread[gress].deparser->apply(checkNestedChecksumUpdates);
    }

    return pipe;
}

}  // namespace BFN
