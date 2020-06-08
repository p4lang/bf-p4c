#ifndef EXTENSIONS_BF_P4C_ARCH_FROMV1_0_CHECKSUM_H_
#define EXTENSIONS_BF_P4C_ARCH_FROMV1_0_CHECKSUM_H_

#include "v1_program_structure.h"
#include "bf-p4c/midend/parser_graph.h"
#include "bf-p4c/arch/intrinsic_metadata.h"

typedef std::map<const IR::Declaration*, std::set<cstring>> DeclToStates;

struct ChecksumInfo {
    bool with_payload;
    const IR::Expression* cond;
    const IR::Expression* fieldList;
    const IR::Expression* destField;
    std::set<gress_t> parserUpdateLocations;
    std::set<gress_t> deparserUpdateLocations;
    boost::optional<cstring> residulChecksumName;
};

namespace BFN {
namespace V1 {

class TranslateParserChecksums : public PassManager {
 public:
    std::map<const IR::Expression*, IR::Member*> residualChecksums;
    std::set<const IR::Expression*> needBridging;
    std::map<const IR::Expression*, ordered_set<const IR::Member*>> residualChecksumPayloadFields;
    std::map<const IR::Expression*, std::map<gress_t, const IR::ParserState*>> destToGressToState;
    std::map<gress_t,
          std::map<cstring, IR::Statement*>> checksumDepositToHeader;
    DeclToStates ingressVerifyDeclToStates;
    P4ParserGraphs parserGraphs;

    TranslateParserChecksums(ProgramStructure *structure,
                             P4::ReferenceMap *refMap,
                             P4::TypeMap *typeMap);
};

static bool analyzeChecksumCall(const IR::MethodCallStatement *statement, cstring which) {
    auto methodCall = statement->methodCall->to<IR::MethodCallExpression>();
    if (!methodCall) {
        ::warning("Expected a non-empty method call expression: %1%", statement);
        return false;
    }
    auto method = methodCall->method->to<IR::PathExpression>();
    if (!method || (method->path->name != which)) {
        ::warning("Expected an %1% statement in %2%", statement, which);
        return false;
    }
    if (methodCall->arguments->size() != 4) {
        ::warning("Expected 4 arguments for %1% statement: %2%", statement, which);
        return false;
    }

    auto destField = (*methodCall->arguments)[2]->expression->to<IR::Member>();
    CHECK_NULL(destField);

    auto condition = (*methodCall->arguments)[0]->expression;
    CHECK_NULL(condition);

    bool nominalCondition = false;
    if (auto mc = condition->to<IR::MethodCallExpression>()) {
        if (auto m = mc->method->to<IR::Member>()) {
            if (m->member == "isValid") {
                if (m->expr->equiv(*(destField->expr))) {
                    nominalCondition = true; } } } }

    auto bl = condition->to<IR::BoolLiteral>();
    if (which == "verify_checksum" && !nominalCondition && (!bl || bl->value != true))
        ::error("Tofino does not support conditional checksum verification: %1%", destField);

    auto algorithm = (*methodCall->arguments)[3]->expression->to<IR::Member>();
    if (!algorithm || (algorithm->member != "csum16"))
        ::error("Tofino only supports \"csum16\" for checksum calculation: %1%", destField);

    return true;
}

static IR::Declaration_Instance*
createChecksumDeclaration(ProgramStructure *structure,
                          const IR::MethodCallStatement*) {
    // auto mc = csum->methodCall->to<IR::MethodCallExpression>();

    // auto typeArgs = new IR::Vector<IR::Type>();
    auto inst = new IR::Type_Name("Checksum");

    auto csum_name = cstring::make_unique(structure->unique_names, "checksum", '_');
    structure->unique_names.insert(csum_name);
    auto args = new IR::Vector<IR::Argument>();
    auto decl = new IR::Declaration_Instance(csum_name, inst, args);

    return decl;
}

static IR::AssignmentStatement*
createChecksumError(const IR::Declaration* decl, gress_t gress) {
     auto methodCall = new IR::Member(new IR::PathExpression(decl->name), "verify");
     auto verifyCall = new IR::MethodCallExpression(methodCall, {});
     auto rhs = new IR::Cast(IR::Type::Bits::get(1), verifyCall);

     cstring intr_md;

     if (gress == INGRESS)
         intr_md = "ig_intr_md_from_prsr";
     else if (gress == EGRESS)
         intr_md = "eg_intr_md_from_prsr";
     else
         BUG("Unhandled gress: %1%.", gress);

     auto parser_err = new IR::Member(
         new IR::PathExpression(intr_md), "parser_err");

     auto lhs = new IR::Slice(parser_err, 12, 12);
     return new IR::AssignmentStatement(lhs, rhs);
}

static std::vector<gress_t>
getChecksumUpdateLocations(const IR::MethodCallExpression* call,
                           const IR::BlockStatement* block,
                           cstring pragma) {
    std::vector<gress_t> updateLocations;
    if (pragma == "calculated_field_update_location")
        updateLocations = { EGRESS };
    else if (pragma == "residual_checksum_parser_update_location")
        updateLocations = { INGRESS };
    else
        BUG("Invalid use of function getChecksumUpdateLocation");

    for (auto annot : block->annotations->annotations) {
        if (annot->name.name == pragma) {
            auto& exprs = annot->expr;
            auto gress = exprs[0]->to<IR::StringLiteral>();
            auto pCall = exprs[1]->to<IR::MethodCallExpression>();
            if (!pCall->equiv(*call)) continue;
            if (gress->value == "ingress")
                updateLocations = { INGRESS };
            else if (gress->value == "egress")
                updateLocations = { EGRESS };
            else if (gress->value == "ingress_and_egress")
                updateLocations = { INGRESS, EGRESS };
            else
                ::error("Invalid use of @pragma %1%, valid value "
                    " is ingress/egress/ingress_and_egress", pragma);
        }
    }

    return updateLocations;
}

class CollectParserChecksums : public Inspector {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

 public:
    std::vector<const IR::MethodCallStatement*> verifyChecksums;
    std::vector<const IR::MethodCallStatement*> residualChecksums;
    std::map<const IR::MethodCallStatement*, std::vector<gress_t>> parserUpdateLocations;
    std::map<const IR::MethodCallStatement*, std::vector<gress_t>> deparserUpdateLocations;

    CollectParserChecksums(P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
            : refMap(refMap), typeMap(typeMap) {
        setName("CollectParserChecksums");
    }

    void postorder(const IR::MethodCallStatement *node) override {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        CHECK_NULL(mce);
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto ef = mi->to<P4::ExternFunction>()) {
            if (ef->method->name == "verify_checksum" &&
                analyzeChecksumCall(node, "verify_checksum")) {
                verifyChecksums.push_back(node);
            } else if (ef->method->name == "update_checksum_with_payload" &&
                analyzeChecksumCall(node, "update_checksum_with_payload")) {
                residualChecksums.push_back(node);

                auto block = findContext<IR::BlockStatement>();
                parserUpdateLocations[node] =
                    getChecksumUpdateLocations(mce, block,
                                       "residual_checksum_parser_update_location");
                deparserUpdateLocations[node] =
                    getChecksumUpdateLocations(mce, block,
                                         "calculated_field_update_location");
            }
        }
    }
};

class InsertParserChecksums : public Inspector {
 public:
    InsertParserChecksums(TranslateParserChecksums* translate,
                          const CollectParserChecksums* collect,
                          const P4ParserGraphs* graph,
                          ProgramStructure *structure)
        : translate(translate),
          collect(collect),
          graph(graph),
          structure(structure) { }

 private:
    TranslateParserChecksums* translate;
    const CollectParserChecksums* collect;
    const P4ParserGraphs* graph;
    ProgramStructure *structure;

    std::map<const IR::MethodCallStatement*, const IR::Declaration*> verifyDeclarationMap;

    std::map<const IR::MethodCallStatement*, IR::Declaration_Instance*>
        ingressParserResidualChecksumDecls, egressParserResidualChecksumDecls;

    unsigned residualChecksumCnt = 0;

    typedef std::map<const IR::ParserState*, std::vector<const IR::Member*> > StateToExtracts;
    typedef std::map<const IR::Member*, const IR::ParserState*> ExtractToState;

    StateToExtracts stateToExtracts;
    ExtractToState extractToState;

    struct CollectExtractMembers : public Inspector {
        CollectExtractMembers(
            StateToExtracts& stateToExtracts, ExtractToState& extractToState) :
                stateToExtracts(stateToExtracts), extractToState(extractToState) { }

        StateToExtracts& stateToExtracts;
        ExtractToState& extractToState;

        void postorder(const IR::MethodCallStatement* statement) override {
            auto* call = statement->methodCall;
            auto* method = call->method->to<IR::Member>();
            auto* state = findContext<IR::ParserState>();

            if (method && method->member == "extract") {
                for (auto m : *(call->arguments)) {
                    auto* mem = m->expression->to<IR::Member>();
                    stateToExtracts[state].push_back(mem);
                    extractToState[mem] = state;
                }
            }
        }
    };

    profile_t init_apply(const IR::Node* root) override {
        CollectExtractMembers cem(stateToExtracts, extractToState);
        root->apply(cem);
        return Inspector::init_apply(root);
    }

    // FIXME -- yet another 'deep' comparison for expressions
    static bool equiv(const IR::Expression *a, const IR::Expression *b) {
        if (a == b) return true;
        if (typeid(*a) != typeid(*b)) return false;
        if (auto ma = a->to<IR::Member>()) {
            auto mb = b->to<IR::Member>();
            return ma->member == mb->member && equiv(ma->expr, mb->expr); }
        if (auto pa = a->to<IR::PathExpression>()) {
            auto pb = b->to<IR::PathExpression>();
            return pa->path->name == pb->path->name; }
        return false;
    }

    static bool belongsTo(const IR::Member* a, const IR::Member* b) {
        if (!a || !b) return false;

        // case 1: a is field, b is field
        if (equiv(a, b)) return true;

        // case 2: a is field, b is header
        if (a->type->is<IR::Type::Bits>()) {
            if (equiv(a->expr, b)) return true;
        }

        return false;
    }

    void implementVerifyChecksum(const IR::MethodCallStatement* vc,
                                 const IR::ParserState* state) {
        cstring stateName = state->name;
        auto& extracts = stateToExtracts[state];

        auto mc = vc->methodCall->to<IR::MethodCallExpression>();

        auto fieldlist = mc->arguments->at(1)->expression;
        auto destfield = mc->arguments->at(2)->expression;

        // check if any of the fields or dest belong to extracts
        // TODO(zma) verify on ingress only?

        const IR::Declaration* decl = nullptr;

        if (verifyDeclarationMap.count(vc)) {
            decl = verifyDeclarationMap.at(vc);
        } else {
            decl = createChecksumDeclaration(structure, vc);
            verifyDeclarationMap[vc] = decl;
            structure->ingressParserDeclarations.push_back(decl);
        }

        for (auto f : fieldlist->to<IR::ListExpression>()->components) {
            for (auto extract : extracts) {
                if (belongsTo(f->to<IR::Member>(), extract)) {
                    auto addCall = new IR::MethodCallStatement(mc->srcInfo,
                        new IR::Member(new IR::PathExpression(decl->name), "add"),
                                                              { new IR::Argument(f) });

                    structure->ingressParserStatements[stateName].push_back(addCall);
                    translate->ingressVerifyDeclToStates[decl].insert(state->name);
                }
            }
        }

        for (auto extract : extracts) {
            if (belongsTo(destfield->to<IR::Member>(), extract)) {
                BUG_CHECK(decl, "No fields have been added before verify?");

                auto addCall = new IR::MethodCallStatement(mc->srcInfo,
                        new IR::Member(new IR::PathExpression(decl->name), "add"),
                                                              { new IR::Argument(destfield) });

                structure->ingressParserStatements[stateName].push_back(addCall);
                translate->ingressVerifyDeclToStates[decl].insert(state->name);
            }
        }
    }

    ordered_set<const IR::Member*>
    collectResidualChecksumPayloadFields(const IR::ParserState* state) {
        ordered_set<const IR::Member*> rv;

        auto descendants = graph->get_all_descendants(state);

        for (auto d : descendants) {
            auto& extracts = stateToExtracts[d];
            for (auto m : extracts)
                rv.insert(m);
        }

        return rv;
    }

    void implementParserResidualChecksum(const IR::MethodCallStatement *rc,
                                         const IR::ParserState* state,
                                         const std::vector<gress_t>& parserUpdateLocations,
                                         const std::vector<gress_t>& deparserUpdateLocations) {
        cstring stateName = state->name;
        auto& extracts = stateToExtracts[state];

        auto mc = rc->methodCall->to<IR::MethodCallExpression>();

        auto condition = mc->arguments->at(0)->expression;
        auto fieldlist = mc->arguments->at(1)->expression;
        auto destfield = mc->arguments->at(2)->expression;
        if (parserUpdateLocations.size() == 1 &&
            parserUpdateLocations[0] == INGRESS &&
            deparserUpdateLocations.size() == 1 &&
            deparserUpdateLocations[0] == EGRESS) {
            translate->needBridging.insert(destfield);
        }

        if (!translate->residualChecksums.count(destfield)) {
            auto *compilerMetadataPath =
                    new IR::PathExpression(COMPILER_META);
            auto* cgAnnotation = new IR::Annotations({
                       new IR::Annotation(IR::ID("__compiler_generated"), { })});

            auto *compilerMetadataDecl = const_cast<IR::Type_Struct*>(
                structure->type_declarations.at("compiler_generated_metadata_t")
                         ->to<IR::Type_Struct>());
            compilerMetadataDecl->annotations = cgAnnotation;

            std::stringstream residualFieldName;
            residualFieldName << "residual_checksum_";
            residualFieldName << residualChecksumCnt++;

            auto* residualChecksum = new IR::Member(compilerMetadataPath,
                                              residualFieldName.str().c_str());

            compilerMetadataDecl->fields.push_back(
                new IR::StructField(residualFieldName.str().c_str(),
                                    IR::Type::Bits::get(16)));

            translate->residualChecksums[destfield] = residualChecksum;
            translate->destToGressToState[destfield][deparserUpdateLocations[0]] = state;
        }

        for (auto location : parserUpdateLocations) {
            std::vector<const IR::Declaration *>* parserDeclarations = nullptr;
            std::vector<const IR::StatOrDecl *>* parserStatements = nullptr;

            std::map<const IR::MethodCallStatement*,
                    IR::Declaration_Instance*>* parserResidualChecksumDecls = nullptr;

            if (location == INGRESS) {
                parserDeclarations = &structure->ingressParserDeclarations;
                parserStatements = &structure->ingressParserStatements[stateName];
                parserResidualChecksumDecls = &ingressParserResidualChecksumDecls;
            } else if (location == EGRESS) {
                parserDeclarations = &structure->egressParserDeclarations;
                parserStatements = &structure->egressParserStatements[stateName];
                parserResidualChecksumDecls = &egressParserResidualChecksumDecls;
            }

            IR::Declaration_Instance* decl = nullptr;
            auto it = parserResidualChecksumDecls->find(rc);
            if (it == parserResidualChecksumDecls->end()) {
                decl = createChecksumDeclaration(structure, rc);
                parserDeclarations->push_back(decl);
                (*parserResidualChecksumDecls)[rc] = decl;
            } else {
                decl = parserResidualChecksumDecls->at(rc);
            }
            const IR::Expression* constant = nullptr;
            for (auto extract : extracts) {
                std::vector<const IR::Expression*> exprList;
                for (auto f : fieldlist->to<IR::ListExpression>()->components) {
                    if (f->is<IR::Constant>()) {
                        constant = f;
                    } else if (belongsTo(f->to<IR::Member>(), extract)) {
                        if (constant) {
                            exprList.emplace_back(constant);
                            constant = nullptr;
                            // If immediate next field after the constant is extracted in this field
                            // then the constant belongs to subtract field list of this state
                        }
                        exprList.emplace_back(f);

                     } else {
                        constant = nullptr;
                     }
                }
                for (auto e : exprList) {
                    auto subtractCall = new IR::MethodCallStatement(mc->srcInfo,
                                    new IR::Member(new IR::PathExpression(decl->name), "subtract"),
                                    { new IR::Argument(e)});

                    parserStatements->push_back(subtractCall);
               }

                if (belongsTo(destfield->to<IR::Member>(), extract)) {
                    auto subtractCall = new IR::MethodCallStatement(mc->srcInfo,
                        new IR::Member(new IR::PathExpression(decl->name), "subtract"),
                                                              { new IR::Argument(destfield) });

                    parserStatements->push_back(subtractCall);
                    auto* residualChecksum = translate->residualChecksums.at(destfield);

                    auto* deposit = new IR::MethodCallStatement(
                            mc->srcInfo,
                            new IR::Member(new IR::PathExpression(decl->name),
                                                          "subtract_all_and_deposit"),
                            {new IR::Argument(residualChecksum)});

                    translate->checksumDepositToHeader[location][extract->member] = deposit;
                    if (auto boolLiteral = condition->to<IR::BoolLiteral>()) {
                        if (!boolLiteral->value) {
                            // Do not add the if-statement if the condition is always true.
                            deposit = nullptr;
                        }
                    }

                    if (deposit) {
                        auto payloadFields = collectResidualChecksumPayloadFields(state);
                        translate->residualChecksumPayloadFields[destfield] = payloadFields;
                    }
                }
            }
        }
    }

    void postorder(const IR::ParserState *state) override {
        // see if any of the "verify_checksum" or "update_checksum_with_payload" statement
        // is relavent to this state. If so, convert to TNA function calls.
        for (auto* vc : collect->verifyChecksums) {
            implementVerifyChecksum(vc, state);
        }

        for (auto* rc : collect->residualChecksums) {
            implementParserResidualChecksum(rc, state,
                                            collect->parserUpdateLocations.at(rc),
                                            collect->deparserUpdateLocations.at(rc));
        }
    }
};

class InsertChecksumDeposit : public Transform {
 public:
    const V1::TranslateParserChecksums* translate;
    explicit InsertChecksumDeposit(const V1::TranslateParserChecksums* translate) :
                                   translate(translate) { }
    const IR::Node* preorder(IR::ParserState* state) override {
        auto parser = findContext<IR::BFN::TnaParser>();
        if (!translate->checksumDepositToHeader.count(parser->thread)) return state;
        auto components = new IR::IndexedVector<IR::StatOrDecl>();
        auto &checksumDeposit = translate->checksumDepositToHeader.at(parser->thread);
        for (auto component : state->components) {
            components->push_back(component);
            auto methodCall = component->to<IR::MethodCallStatement>();
            if (!methodCall) continue;
            auto call = methodCall->methodCall->to<IR::MethodCallExpression>();
            if (!call) continue;
            if (auto method = call->method->to<IR::Member>()) {
                if (method->member == "extract") {
                    for (auto arg : *call->arguments) {
                        const IR::Member* member = nullptr;
                        if (auto index = arg->expression->to<IR::ArrayIndex>()) {
                            member = index->left->to<IR::Member>();
                        } else if (arg->expression->is<IR::Member>()) {
                            member = arg->expression->to<IR::Member>();
                        }
                        if (member && checksumDeposit.count(member->member)) {
                            components->push_back(checksumDeposit.at(member->member));
                        }
                    }
                }
            }
        }
        state->components = *components;
        return state;
    }
};

class InsertChecksumError : public PassManager {
 public:
    std::map<cstring,
        std::map<const IR::Declaration*,
            std::set<cstring>>> endStates;

    struct ComputeEndStates : public Inspector {
        InsertChecksumError* self;

        explicit ComputeEndStates(InsertChecksumError* self) : self(self) { }

        void printStates(const std::set<cstring>& states) {
            for (auto s : states)
                std::cout << "   " << s << std::endl;
        }

        std::set<cstring>
        computeChecksumEndStates(const std::set<cstring>& calcStates) {
            auto& parserGraphs = self->translate->parserGraphs;

            if (LOGGING(3)) {
                std::cout << "calc states are:" << std::endl;
                printStates(calcStates);
            }

            std::set<cstring> endStates;

            // A calculation state is a verification end state if no other state of the
            // same calculation is its descendant. Otherwise, include all of the state's
            // children states that are not a calculation state.

            for (auto a : calcStates) {
                bool isEndState = true;
                for (auto b : calcStates) {
                    if (parserGraphs.is_ancestor(a, b)) {
                        isEndState = false;
                        break;
                    }
                }
                if (isEndState) {
                    endStates.insert(a);
                } else {
                    if (parserGraphs.succs.count(a)) {
                        for (auto succ : parserGraphs.succs.at(a)) {
                            if (calcStates.count(succ))
                                continue;

                            for (auto s : calcStates) {
                                if (!parserGraphs.is_ancestor(succ, s)) {
                                    endStates.insert(succ);
                                }
                            }
                        }
                    }
                }
            }

            BUG_CHECK(!endStates.empty(), "Unable to find verification end state?");

            if (LOGGING(3)) {
                std::cout << "end states are:" << std::endl;
                printStates(endStates);
            }

            return endStates;
        }

        bool preorder(const IR::BFN::TnaParser* parser) override {
            // XXX(zma) verify on ingress only
            if (parser->thread != INGRESS)
                return false;

            // compute checksum end states
            for (auto kv : self->translate->ingressVerifyDeclToStates)
                self->endStates[parser->name][kv.first] = computeChecksumEndStates(kv.second);

            return false;
        }
    };

    // XXX(zma) we probably don't want to insert statement into the "accept" state
    // since this is a special state. Add a dummy state before "accept" if it is
    // a checksum verification end state.
    struct InsertBeforeAccept : public Transform {
        const IR::Node* preorder(IR::BFN::TnaParser* parser) override {
            for (auto& kv : self->endStates[parser->name]) {
                if (kv.second.count("accept")) {
                    if (!dummy) {
                        dummy = createGeneratedParserState(
                            "before_accept", {}, "accept");
                        parser->states.push_back(dummy);
                    }
                    kv.second.erase("accept");
                    kv.second.insert("__before_accept");
                    LOG3("add dummy state before \"accept\"");
                }
            }

            return parser;
        }

        const IR::Node* postorder(IR::PathExpression* path) override {
            auto parser = findContext<IR::BFN::TnaParser>();
            auto state = findContext<IR::ParserState>();
            auto select = findContext<IR::SelectCase>();

            if (parser && state && select) {
                bool isCalcState = false;

                for (auto kv : self->translate->ingressVerifyDeclToStates) {
                    for (auto s : kv.second) {
                        if (s == state->name) {
                            isCalcState = true;
                            break;
                        }
                    }
                }

                if (!isCalcState)
                    return path;

                for (auto& kv : self->endStates[parser->name]) {
                    if (path->path->name == "accept" && kv.second.count("__before_accept")) {
                        path = new IR::PathExpression("__before_accept");
                        LOG3("modify transition to \"before_accept\"");
                    }
                }
            }

            return path;
        }

        const IR::ParserState* dummy = nullptr;
        InsertChecksumError* self;

        explicit InsertBeforeAccept(InsertChecksumError* self) : self(self) { }
    };

    struct InsertEndStates : public Transform {
        const IR::Node* preorder(IR::ParserState* state) override {
            auto parser = findContext<IR::BFN::TnaParser>();

            if (state->name == "reject")
                return state;

            for (auto& kv : self->endStates[parser->name]) {
                auto* decl = kv.first;
                for (auto endState : kv.second) {
                    if (endState == state->name) {
                        auto* checksumError = createChecksumError(decl, parser->thread);
                        state->components.push_back(checksumError);

                        LOG3("verify " << toString(parser->thread) << " "
                             << decl->name.name << " in state " << endState);
                    }
                }
            }

            return state;
        }

        InsertChecksumError* self;

        explicit InsertEndStates(InsertChecksumError* self) : self(self) { }
    };

    explicit InsertChecksumError(const V1::TranslateParserChecksums* translate) :
        translate(translate) {
        addPasses({new ComputeEndStates(this),
                   new InsertBeforeAccept(this),
                   new InsertEndStates(this),
             });
    }

    const V1::TranslateParserChecksums* translate;
};

};  // namespace V1
};  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_ARCH_FROMV1_0_CHECKSUM_H_ */
