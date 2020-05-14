#include "p4/methodInstance.h"
#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "lib/ordered_set.h"
#include "bf-p4c/arch/bridge_metadata.h"
#include "rewrite_packet_path.h"

namespace BFN {

namespace PSA {

// TODO(hanw): write an analysis to find how many field list to generate for resubmit
// insert the assignment to idx to each path in the if statement.
// write a converter to insert idx to if statement after each iftrue.
// use a stack and visitor framework

// generate the following in deparser:
// if (resubmit_idx == 3w0)
//    resubmit.emit({});
// if (resubmit_idx == 3w1)
//    resubmit.emit({});
// if (resubmit_idx == 3w2)
//    resubmit.emit({});

struct RewriteResubmit : public Transform {
    explicit RewriteResubmit(const PacketPathInfo& resubmit)
        : resubmit(resubmit) {
        setName("RewriteResubmit");
    }

    const IR::Type_StructLike *preorder(IR::Type_StructLike *type) override {
        prune();

        if (type->name == "compiler_generated_metadata_t") {
            // Inject a new field to hold the extract resubmit data
            LOG4("Injecting field for resubmit data into: " << type);
            CHECK_NULL(resubmit.p4Type);
            type->fields.push_back(new IR::StructField("__resubmit_data", resubmit.p4Type));
        } else {
            // XXX(hanw): resubmit metadata to be extracted as a header
            auto rt = resubmit.p4Type;
            if (auto t = rt->to<IR::Type_Name>()) {
                if (type->name == t->path->name) {
                    auto nt = new IR::Type_Header(type->name, type->annotations, type->fields);
                    return nt;
                }
            }
        }
        return type;
    }

    const IR::BFN::TnaParser *preorder(IR::BFN::TnaParser *parser) override {
        if (parser->thread != INGRESS || parser->name != "ingressParserImpl") {
            prune();
            return parser;
        }
        return parser;
    }

    // replace the resubmit extract call with extract() to resubmit md
    const IR::ParserState *preorder(IR::ParserState *state) override {
        if (state->name != "__resubmit") return state;
        prune();

        auto *tnaContext = findContext<IR::BFN::TnaParser>();
        BUG_CHECK(tnaContext, "resubmit state not within translated parser?");
        BUG_CHECK(tnaContext->thread == INGRESS, "resubmit state not in ingress?");

        // clear existing statements
        state->components.clear();

        auto cgMeta = tnaContext->tnaParams.at(BFN::COMPILER_META);
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("__resubmit_data"));
        auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        auto *extract = new IR::MethodCallStatement(callExpr);
        LOG4("Generated extract for resubmit data: " << extract);
        state->components.push_back(extract);

        return state;
    }

    const IR::Member *preorder(IR::Member *node) override {
        auto membername = node->member.name;
        auto expr = node->expr->to<IR::PathExpression>();
        if (!expr) return node;
        auto pathname = expr->path->name;

        if (auto *parser = findContext<IR::BFN::TnaParser>()) {
            if (parser->thread != INGRESS) {
                return node; }
        } else if (auto *control = findContext<IR::BFN::TnaDeparser>()) {
            if (control->thread != INGRESS) {
                return node; }
        } else {
            return node;
        }

        if (pathname == resubmit.paramNameInParser) {
            auto path = new IR::Member(new IR::PathExpression(BFN::COMPILER_META),
                                       IR::ID("__resubmit_data"));
            auto member = new IR::Member(path, membername);
            return member;
        }

        if (pathname == resubmit.paramNameInDeparser) {
            auto path = new IR::Member(new IR::PathExpression(BFN::COMPILER_META),
                                       IR::ID("__resubmit_data"));
            auto member = new IR::Member(path, membername);
            return member;
        }

        return node;
    }

 private:
    const PacketPathInfo& resubmit;
};

struct RewriteRecirculate : public Transform {
    PSA::ProgramStructure* structure;
    P4::TypeMap* typeMap;
    P4::ReferenceMap* refMap;
    IR::IndexedVector<IR::StatOrDecl>* recircAssignments;
    explicit RewriteRecirculate(PSA::ProgramStructure* structure, P4::TypeMap* typeMap,
                                P4::ReferenceMap* refMap,
                                IR::IndexedVector<IR::StatOrDecl>* recircAssignments)
    : structure(structure), typeMap(typeMap), refMap(refMap),
      recircAssignments(recircAssignments) {
        setName("RewriteRecirculate");
    }
    IR::IndexedVector<IR::StructField> fields;

    // Add flexible annotation to recirculate header
    profile_t init_apply(const IR::Node* root) override {
        for (auto& recircField :
                structure->recirculate.structType->to<IR::Type_StructLike>()->fields) {
            auto *fieldAnnotations = new IR::Annotations();
            fieldAnnotations->annotations.push_back(
                            new IR::Annotation(IR::ID("flexible"), {}));
            fields.push_back(new IR::StructField(recircField->name, fieldAnnotations,
                                                 recircField->type));
        }
        return Transform::init_apply(root);
    }

    IR::Type_StructLike* postorder(IR::Type_StructLike* type) override {
        prune();
        if (type->name == structure->recirculate.structType->to<IR::Type_StructLike>()->name) {
           type->fields = fields;
        }
        return type;
    }

    // Create a state to extract recirculated data and assign them to metadata
    IR::ParserState* create_recirculate_state(const IR::BFN::TnaParser* tnaContext) {
        auto statements = new IR::IndexedVector<IR::StatOrDecl>();
        auto cgMeta = tnaContext->tnaParams.at(BFN::COMPILER_META);
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("__recirculate_data"));
        auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        auto *extract = new IR::MethodCallStatement(callExpr);
        LOG4("Generated extract for recirculate data: " << extract);
        statements->push_back(extract);
        // add assignment
        auto pathname = structure->egress_parser.psaParams.at("metadata");
        auto path = new IR::PathExpression(pathname);
        auto mdType = typeMap->getTypeType(structure->metadataType, true);
        for (auto& recircField:
                structure->recirculate.structType->to<IR::Type_StructLike>()->fields) {
            auto leftMember = new IR::Member(path, recircField->name);
            for (auto f : mdType->to<IR::Type_StructLike>()->fields) {
                if (f->name == recircField->name) {
                    auto rightMember = new IR::Member(member, recircField->name);
                    auto setMetadata = new IR::AssignmentStatement(leftMember, rightMember);
                    statements->push_back(setMetadata);
                    break;
                }
            }
        }

        auto select = new IR::PathExpression(IR::ID("__skip_to_packet"));
        auto newStateName = IR::ID(cstring("__recirculate"));
        auto *newState = new IR::ParserState(newStateName, *statements, select);
        newState->annotations = newState->annotations
            ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                 new IR::StringLiteral(cstring("$__recirculate")));
        return newState;
    }

    // Update IngressMetadata state to include a transition to __recirculate state
    // by looking at ig_intr_md.ingress_port
    void addRecirculateState(IR::ParserState* state) {
        auto* tnaContext = findContext<IR::BFN::TnaParser>();
        BUG_CHECK(tnaContext, "Parser state %1% not within translated parser?",
                  state->name);
        if (tnaContext->thread != INGRESS) return;
        auto intMeta = tnaContext->tnaParams.at("ig_intr_md");
        auto member = new IR::Member(new IR::PathExpression(intMeta),
                                         IR::ID("ingress_port"));
        auto selectCases = new IR::Vector<IR::SelectCase>();
        selectCases->push_back(new IR::SelectCase(new IR::Mask(
                                                  new IR::Constant(IR::Type::Bits::get(9), 68),
                               new IR::Constant(IR::Type::Bits::get(9), 0x1FF)),
                               new IR::PathExpression("__recirculate")));
        selectCases->push_back(new IR::SelectCase(
                                   new IR::DefaultExpression(new IR::Type_Dontcare()),
                                   new IR::PathExpression(IR::ID("__skip_to_packet"))));
        IR::Vector<IR::Expression> selectOn;
        selectOn.push_back(member);
        auto selectExpression = new IR::SelectExpression(new IR::ListExpression(selectOn),
                                                         *selectCases);
        state->selectExpression = selectExpression;
        return;
    }

    void updateResubmitState(IR::ParserState* state) {
        auto *tnaContext = findContext<IR::BFN::TnaParser>();
        BUG_CHECK(tnaContext, "resubmit state not within translated parser?");
        BUG_CHECK(tnaContext->thread == INGRESS, "resubmit state not in ingress?");

        // clear existing statements
        state->components.clear();

        auto cgMeta = tnaContext->tnaParams.at(BFN::COMPILER_META);
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("__resubmit_data"));
        auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        auto *extract = new IR::MethodCallStatement(callExpr);
        LOG4("Generated extract for resubmit data: " << extract);
        state->components.push_back(extract);
        return;
    }

    const IR::ParserState *preorder(IR::ParserState *state) override {
        if (state->name == "__phase0") {
            addRecirculateState(state);
        } else if (state->name == "__resubmit") {
            addRecirculateState(state);
        }
        return state;
    }

    // Include __recirculate state in ingress parser
    const IR::BFN::TnaParser* preorder(IR::BFN::TnaParser* node) override {
        if (node->thread == gress_t::INGRESS)
            node->states.push_back(create_recirculate_state(node));
        return node;
    }

    // Add "pkt.emit(md.__recirculate_data);" as the first statement in the
    // egress deparser.
    IR::BFN::TnaDeparser*
    updateEgressDeparser(IR::BFN::TnaDeparser* control) {
        auto packetOutParam = control->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetOutParam),
                                      IR::ID("emit"));

        auto cgMetadataParam = control->tnaParams.at(COMPILER_META);
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                      IR::ID("__recirculate_data"));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto* callExpr = new IR::MethodCallExpression(method, args);

        auto* body = control->body->clone();
        body->components.insert(body->components.begin(),
                                new IR::MethodCallStatement(callExpr));
        control->body = body;
        return control;
    }

    const IR::BFN::TnaDeparser* preorder(IR::BFN::TnaDeparser* control) override {
        if (control->thread == gress_t::EGRESS && recircAssignments->size())
            return updateEgressDeparser(control);
        return control;
    }
};


// Remove and collect the assignment statements in Egress deparser
struct RemoveDeparserAssignment : public Transform {
    PSA::ProgramStructure* structure;
    P4::TypeMap* typeMap;
    P4::ReferenceMap* refMap;
    IR::Type_Header* recirculateHeader;
    IR::IndexedVector<IR::StatOrDecl> recircAssignments;
    explicit RemoveDeparserAssignment(PSA::ProgramStructure* structure, P4::TypeMap* typeMap,
                                P4::ReferenceMap* refMap)
    : structure(structure), typeMap(typeMap), refMap(refMap) {
        setName("RemoveDeparserAssignment");
    }

    IR::Node* postorder(IR::AssignmentStatement* assignment) override {
        auto ctxt = findOrigCtxt<IR::BFN::TnaDeparser>();
        if (!ctxt) {
            return assignment;
        }
        PathLinearizer linearizer;
        assignment->left->apply(linearizer);
        if (!checkIfStatementNeedToMove(assignment)) return assignment;
        auto& path = *linearizer.linearPath;
        auto* nextToLastComponent = path.components[path.components.size() - 2];
        auto* nextToLastComponentType = typeMap->getType(nextToLastComponent);
        if (ctxt->thread == EGRESS &&
            isSameHeaderType(nextToLastComponentType, structure->recirculate.structType)) {
            recircAssignments.push_back(assignment);
            return nullptr;
        }
        return assignment;
    }

    // Check if the assignment statement given in deparser should be moved to control
    bool checkIfStatementNeedToMove(IR::AssignmentStatement* assignment) {
        PathLinearizer linearizer;
        assignment->left->apply(linearizer);

        // If the destination of the write isn't a path-like expression, or if it's
        // too complex to analyze, err on the side of caution and don't remove it.
        if (!linearizer.linearPath) {
            LOG4("Won't remove egress deparser assignment to complex object: "
                     << assignment);
            return false;
        }

        auto& path = *linearizer.linearPath;
        auto* param = getContainingParameter(path, refMap);
        if (!param) {
            LOG4("Won't remove egress deparser assignment to local object: "
                     << assignment);
            return false;
        }
        auto* paramType = typeMap->getType(param);
        BUG_CHECK(paramType, "No type for param: %1%", param);
        LOG4("param type " << paramType);
        if (!isCompilerGeneratedType(paramType)) {
            LOG4("Won't remove egress deparser assignment to non compiler-generated object: "
                     << assignment);
            return false;
        }
        if (path.components.size() < 2)
            return false;
        return true;
    }
};

// Use the collected assignment statements, recreate new assignment statement using egress
// control paramters and add them in egress control
struct MoveAssignment : public Transform {
    explicit MoveAssignment(PSA::ProgramStructure* structure,
         IR::IndexedVector<IR::StatOrDecl>* recircAssignments)
    : structure(structure), recircAssignments(recircAssignments) { }

    IR::BFN::TnaControl*
    preorder(IR::BFN::TnaControl* control) override {
        prune();
        auto cgMetadataParam = control->tnaParams.at(COMPILER_META);
        if (control->thread == EGRESS && recircAssignments->size()) {
            auto* compilerRecirculateHeader = new IR::Member(
                                      new IR::PathExpression(cgMetadataParam),
                                      IR::ID("__recirculate_data"));
            auto components = rewriteAssignmentStatements(compilerRecirculateHeader,
                                                            recircAssignments);
            // Add if condition : assign the the recirculate data only when egress port is 68
            auto eg_intr_md = control->tnaParams.at("eg_intr_md");
            auto path = new IR::PathExpression(eg_intr_md);
            auto egress_port = new IR::Member(path, "egress_port");
            auto condition = new IR::Equ(egress_port, new IR::Constant(IR::Type::Bits::get(9), 68));
            auto block = new IR::BlockStatement(components);
            auto ifStmt = new IR::IfStatement(condition, block, nullptr);
            auto* body = control->body->clone();
            body->components.push_back(ifStmt);
            control->body = body;
        }
        return control;
    }

    // Rewrite assignment statements using local parameters
    IR::IndexedVector<IR::StatOrDecl>
    rewriteAssignmentStatements(IR::Member* typeMember,
                        IR::IndexedVector<IR::StatOrDecl>* assignments) {
        // First create assignment members that uses egress pipeline params
        IR::IndexedVector<IR::StatOrDecl> block;
        auto metdataParam = structure->egress.psaParams.at("metadata");
        auto metadataPath = new IR::PathExpression(metdataParam);
        // create a setvalid statement
        auto* method = new IR::Member(typeMember, IR::ID("setValid"));
        auto* args = new IR::Vector<IR::Argument>;
        auto* callExpr = new IR::MethodCallExpression(method, args);
        block.push_back(new IR::MethodCallStatement(callExpr));
        for (auto s : *assignments) {
            auto stmt = s->to<IR::AssignmentStatement>();
            IR::Member* newLeftMember = nullptr;
            IR::Member* newRightMember = nullptr;
            if (auto leftMember = stmt->left->to<IR::Member>()) {
                newLeftMember = new IR::Member(typeMember, leftMember->member);
            }
            if (auto rightMember = stmt->right->to<IR::Member>()) {
                newRightMember = new IR::Member(metadataPath, rightMember->member);
            }
            if (newLeftMember && newRightMember) {
                block.push_back(new IR::AssignmentStatement(newLeftMember,
                                                             newRightMember));
            } else {
                ::error("Assignment in Deparser do not have metadata"
                         " fields as operands %1%", stmt);
            }
        }
        return block;
    }
    PSA::ProgramStructure* structure;
    IR::IndexedVector<IR::StatOrDecl>* recircAssignments;
};


struct RewriteClone : public Transform {
    explicit RewriteClone(
        const PacketPathInfo& clone, gress_t gress) : clone(clone) {
        setName("RewriteClone");
        metadata = (gress == INGRESS) ? "__clone_i2e_data" : "__clone_e2e_data";
    }

    const IR::Type_StructLike *preorder(IR::Type_StructLike *type) override {
        prune();
        if (type->name == "compiler_generated_metadata_t") {
            // Inject a new field to hold the extract resubmit data
            LOG4("Injecting field for recirculate data into: " << type);
            type->fields.push_back(new IR::StructField(metadata, clone.p4Type));
        } else {
            auto rt = clone.p4Type;
            if (auto t = rt->to<IR::Type_Name>()) {
                if (type->name == t->path->name) {
                    auto nt = new IR::Type_Header(type->name, type->annotations, type->fields);
                    return nt;
                }
            }
        }
        return type;
    }

    // given data to be cloned, generate deparser and parser state.
    // replace the clone extract call with extract() to clone metadata
    const IR::ParserState *preorder(IR::ParserState *state) override {
        if (state->name != "__mirrored") return state;
        prune();

        auto *tnaContext = findContext<IR::BFN::TnaParser>();
        BUG_CHECK(tnaContext, "clone state not within translated parser?");
        BUG_CHECK(tnaContext->thread == EGRESS, "clone state not in ingress?");

        // clear existing statements
        state->components.clear();

        auto cgMeta = tnaContext->tnaParams.at(BFN::COMPILER_META);
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam), IR::ID("extract"));
        auto *member = new IR::Member(new IR::PathExpression(cgMeta), IR::ID(metadata));
        auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        auto *extract = new IR::MethodCallStatement(callExpr);
        LOG4("Generated extract for clone data: " << extract);
        state->components.push_back(extract);

        return state;
    }

    // only process egress parser
    const IR::BFN::TnaParser* preorder(IR::BFN::TnaParser* node) override {
        if (node->thread != gress_t::EGRESS)
            prune();
        return node;
    }

    // do not process control block
    const IR::BFN::TnaControl* preorder(IR::BFN::TnaControl* node) override {
        prune();
        return node;
    }

    const IR::Node* preorder(IR::PathExpression* node) override {
        if (node->path->name == clone.paramNameInDeparser) {
            auto path = new IR::Member(new IR::PathExpression(BFN::COMPILER_META),
                    IR::ID(metadata));
            return path;
        }
        return node;
    }

 private:
    const PacketPathInfo& clone;
    cstring metadata;
};

struct RecirculatePacket : public PassManager {
    RecirculatePacket(PSA::ProgramStructure* structure, P4::TypeMap* typeMap,
                       P4::ReferenceMap* refMap) {
        auto* removeDeparserAssignments = new RemoveDeparserAssignment(structure,
                                                                       typeMap, refMap);
        addPasses({
            removeDeparserAssignments,
            new RewriteRecirculate(structure, typeMap, refMap,
                                  &removeDeparserAssignments->recircAssignments),
            new P4::ClearTypeMap(typeMap),
            new BFN::TypeChecking(refMap, typeMap, true),
            new MoveAssignment(structure, &removeDeparserAssignments->recircAssignments),
        });
    }
};

RewritePacketPath::RewritePacketPath(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                           PSA::ProgramStructure* structure) {
    setName("RewritePacketPath");
    addPasses({
        new RecirculatePacket(structure, typeMap, refMap),
        new RewriteResubmit(structure->resubmit),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        new RewriteClone(structure->clone_i2e, INGRESS),
        new RewriteClone(structure->clone_e2e, EGRESS),
    });
}

}  // namespace PSA

}  // namespace BFN
