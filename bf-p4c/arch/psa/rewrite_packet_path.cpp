#include "p4/methodInstance.h"
#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/coreLibrary.h"
#include "lib/ordered_set.h"
#include "bf-p4c/midend/type_checker.h"
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

struct TranslatePacketPathIfStatement : public Transform {
    TranslatePacketPathIfStatement(const PacketPathInfo& info, PSA::ProgramStructure* structure,
                                   gress_t gress)
        : info(info), structure(structure), gress(gress)
    { setName("TranslatePacketPathIfStatement"); }

    const IR::Expression *preorder(IR::MethodCallExpression *mce) override {
        if (auto expr = mce->method->to<IR::PathExpression>()) {
            if (auto path = expr->path->to<IR::Path>()) {
                if (path->name == "psa_resubmit") {
                    generated_metadata = "__resubmit_data";
                    condition = create_condition(path->name);
                    return condition;
                } else if (path->name == "psa_clone_i2e") {
                    generated_metadata = "__clone_i2e_data";
                    condition = create_condition(path->name);
                    return condition;
                } else if (path->name == "psa_clone_e2e") {
                    generated_metadata = "__clone_e2e_data";
                    condition = create_condition(path->name);
                    return condition;
                } else if (path->name == "psa_recirculate") {
                    generated_metadata = "__recirculate_data";
                    condition = create_condition(path->name);
                    return condition;
                }
            }
        }
        return mce;
    }

    IR::Expression* create_condition(cstring packetPath) {
        IR::Expression* expr = nullptr;
        if (packetPath == "psa_resubmit") {
            expr = new IR::LAnd(new IR::LNot(
                        new IR::Member(new IR::PathExpression(COMPILER_META), IR::ID("drop"))),
                        new IR::Member(new IR::PathExpression(COMPILER_META), IR::ID("resubmit")));
        } else if (packetPath == "psa_clone_i2e") {
            expr = new IR::Member(
                         new IR::PathExpression(COMPILER_META), IR::ID("clone_i2e"));
        } else if (packetPath == "psa_clone_e2e") {
            expr = new IR::Member(
                         new IR::PathExpression(COMPILER_META), IR::ID("clone_e2e"));
        } else if (packetPath == "psa_recirculate") {
            auto drop = new IR::LNot(new IR::Member(
                         new IR::PathExpression(COMPILER_META), IR::ID("drop")));
            auto recircPort = new IR::Equ(new IR::Member(new IR::PathExpression(
                                                  IR::ID("eg_intr_md")), "egress_port"),
                                                  new IR::Constant(IR::Type::Bits::get(9), 68));
            expr = new IR::LAnd(drop, recircPort);
        }
        return expr;
    }

    const IR::Member *preorder(IR::Member *node) override {
        auto membername = node->member.name;
        auto expr = node->expr->to<IR::PathExpression>();
        if (!expr) return node;
        auto pathname = expr->path->name;

        if (pathname == info.paramNameInParser) {
            auto path = new IR::Member(new IR::PathExpression(COMPILER_META),
                                       IR::ID(generated_metadata));
            auto member = new IR::Member(path, membername);
            return member;
        }

        if (pathname == info.paramNameInDeparser) {
            auto path = new IR::Member(new IR::PathExpression(COMPILER_META),
                                       IR::ID(generated_metadata));
            auto member = new IR::Member(path, membername);
            return member;
        }

        if (gress == INGRESS) {
            if (pathname == structure->ingress_deparser.psaParams.at("metadata")) {
                auto path = new IR::PathExpression(structure->ingress.psaParams.at("metadata"));
                auto member = new IR::Member(path, membername);
                return member;
            } else if (pathname == structure->ingress_deparser.psaParams.at("hdr")) {
                auto path = new IR::PathExpression(structure->ingress.psaParams.at("hdr"));
                auto member = new IR::Member(path, membername);
                return member;
            }
        } else if (gress == EGRESS) {
             if (pathname == structure->egress_deparser.psaParams.at("metadata")) {
                auto path = new IR::PathExpression(structure->egress.psaParams.at("metadata"));
                auto member = new IR::Member(path, membername);
                return member;
            } else if (pathname == structure->egress_deparser.psaParams.at("hdr")) {
                auto path = new IR::PathExpression(structure->egress.psaParams.at("hdr"));
                auto member = new IR::Member(path, membername);
                return member;
            }
        }
        return node;
    }

    const IR::IfStatement* convert(const IR::Node* node) {
        auto result = node->apply(*this);
        return result->to<IR::IfStatement>();
    }

    const PacketPathInfo& info;
    PSA::ProgramStructure* structure;
    IR::Expression* condition = nullptr;
    gress_t gress;
    cstring generated_metadata;
};

struct FindPacketPath : public Inspector {
    PSA::ProgramStructure* structure;
    bool resubmit = false;
    bool clone_i2e = false;
    bool clone_e2e = false;
    explicit FindPacketPath(PSA::ProgramStructure* structure): structure(structure) { }
    bool preorder(const IR::AssignmentStatement* stmt) override {
        auto ctxt = findContext<IR::BFN::TnaControl>();
        if (ctxt && ctxt->thread == INGRESS) {
            auto leftMember = stmt->left->to<IR::Member>();
            if (!leftMember) return false;
            auto leftPathEx = leftMember->expr->to<IR::PathExpression>();
            if (!leftPathEx) return false;
            auto leftPath = leftPathEx->path->to<IR::Path>();
            if (!leftPath) return false;
            auto rightBool = stmt->right->to<IR::BoolLiteral>();
            if (leftPath && rightBool &&
                leftPath->name == COMPILER_META && leftMember->member == "resubmit" &&
                rightBool->value == true) {
                resubmit |= true;
            }
        }
        return false;
    }
};

struct PacketPath : public Transform {
    PSA::ProgramStructure* structure;
    P4::TypeMap* typeMap;
    P4::ReferenceMap* refMap;
    FindPacketPath* fpa;
    explicit PacketPath(PSA::ProgramStructure* structure, P4::TypeMap* typeMap,
                                P4::ReferenceMap* refMap,
                                FindPacketPath* fpa)
    : structure(structure), typeMap(typeMap), refMap(refMap), fpa(fpa) {
        setName("PacketPath");
    }

    void addFlexibleAnnot(IR::Type_StructLike* type) {
        IR::IndexedVector<IR::StructField> fields;
        for (auto& f : type->fields) {
            auto *fieldAnnotations = new IR::Annotations();
            fieldAnnotations->annotations.push_back(
                            new IR::Annotation(IR::ID("flexible"), {}));
            fields.push_back(new IR::StructField(f->name, fieldAnnotations, f->type));
        }
        type->fields = fields;
        return;
    }

    IR::Type_StructLike* postorder(IR::Type_StructLike* type) override {
        prune();
        IR::IndexedVector<IR::StructField> fields;
        if (type->name == structure->recirculate.structType->to<IR::Type_StructLike>()->name ||
            type->name == structure->resubmit.structType->to<IR::Type_StructLike>()->name) {
            addFlexibleAnnot(type);
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
        if (structure->resubmit.structType->to<IR::Type_StructLike>()->fields.size()) {
            auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
            auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("__resubmit_data"));
            auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
            auto *callExpr = new IR::MethodCallExpression(method, args);
            auto *extract = new IR::MethodCallStatement(callExpr);
            LOG4("Generated extract for resubmit data: " << extract);
            state->components.push_back(extract);
        } else {
            auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("advance"));
            auto constant = new IR::Constant(IR::Type::Bits::get(32), 64);
            auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(constant) });
            auto *callExpr = new IR::MethodCallExpression(method, args);
            auto *advance = new IR::MethodCallStatement(callExpr);
            state->components.push_back(advance);
        }
        // Add assignment statement for packet path
        auto packetPath = new IR::Member(new IR::PathExpression(cgMeta), IR::ID("packet_path"));
        auto packetPathStmt = new IR::AssignmentStatement(packetPath,
                                                new IR::Constant(IR::Type::Bits::get(8), 5));
        state->components.push_back(packetPathStmt);
        auto resubmitEn =  new IR::Member(new IR::PathExpression(cgMeta), IR::ID("resubmit"));
        state->components.push_back(new IR::AssignmentStatement(resubmitEn,
                                                                new IR::BoolLiteral(false)));
        return;
    }

    const IR::ParserState *preorder(IR::ParserState *state) override {
        if (state->name == "__phase0") {
            addRecirculateState(state);
        } else if (state->name == "__resubmit") {
            updateResubmitState(state);
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
    deparseRecirculate(IR::BFN::TnaDeparser* control) {
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

    IR::BFN::TnaDeparser*
    deparserResubmit(IR::BFN::TnaDeparser* control) {
        auto declArgs = new IR::Vector<IR::Argument>({});
        auto declType = new IR::Type_Name("Resubmit");
        auto decl = new IR::Declaration_Instance("resubmit", declType, declArgs);
        IR::IndexedVector<IR::Declaration> parameters;
        parameters.push_back(decl);
        for (auto p : control->controlLocals) {
             parameters.push_back(p);
        }
        control->controlLocals = parameters;
        auto* method = new IR::Member(new IR::PathExpression("resubmit"),
                                      IR::ID("emit"));
        auto cgMetadataParam = control->tnaParams.at(COMPILER_META);
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                      IR::ID("__resubmit_data"));
        auto* args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto typeArgs = new IR::Vector<IR::Type>({structure->resubmit.p4Type});
        auto* callExpr = new IR::MethodCallExpression(method, typeArgs, args);
        // Add if(resubmit_type == 0) to emit
        auto ig_dprsr = control->tnaParams.at("ig_intr_md_for_dprsr");
        IR::IndexedVector<IR::StatOrDecl> components;
        components.push_back(new IR::MethodCallStatement(callExpr));
        auto resubmit = new IR::Member(new IR::PathExpression(ig_dprsr), "resubmit_type");
        auto condition = new IR::Equ(resubmit, new IR::Constant(IR::Type::Bits::get(3), 0));
        auto block = new IR::BlockStatement(components);
        auto ifStmt = new IR::IfStatement(condition, block, nullptr);
        auto* body = control->body->clone();
        body->components.insert(body->components.begin(), ifStmt);
        control->body = body;
        return control;
    }

    const IR::BFN::TnaDeparser* preorder(IR::BFN::TnaDeparser* control) override {
        if (control->thread == EGRESS && structure->recirculate.ifStatement) {
            return deparseRecirculate(control);
        } else if (control->thread == INGRESS && fpa->resubmit) {
            return deparserResubmit(control);
        }
        return control;
    }
};

// Use the collected assignment statements, recreate new assignment statement using egress
// control paramters and add them in egress control
struct MoveAssignment : public Transform {
    PSA::ProgramStructure* structure;
    const FindPacketPath* fpa;
    MoveAssignment(PSA::ProgramStructure* structure,
                   const FindPacketPath* fpa)
    : structure(structure), fpa(fpa) { }

    IR::BFN::TnaControl*
    preorder(IR::BFN::TnaControl* control) override {
        prune();
        auto cgMetadataParam = control->tnaParams.at(COMPILER_META);
        if (control->thread == EGRESS && structure->recirculate.ifStatement) {
            auto* compilerRecirculateHeader = new IR::Member(
                                      new IR::PathExpression(cgMetadataParam),
                                      IR::ID("__recirculate_data"));
            TranslatePacketPathIfStatement cvt_recirc(structure->recirculate, structure, EGRESS);
            auto ifStmt = cvt_recirc.convert(structure->recirculate.ifStatement);
            auto* method = new IR::Member(compilerRecirculateHeader, IR::ID("setValid"));
            auto* args = new IR::Vector<IR::Argument>;
            auto* callExpr = new IR::MethodCallExpression(method, args);
            IR::IndexedVector<IR::StatOrDecl> components;
            components.push_back(ifStmt->to<IR::IfStatement>()->ifTrue);
            components.push_back(new IR::MethodCallStatement(callExpr));
            auto block = new IR::BlockStatement(components);
            auto newifStmt = new IR::IfStatement(ifStmt->condition, block, nullptr);
            auto* body = control->body->clone();
            body->components.push_back(newifStmt);
            control->body = body;
        } else if (control->thread == INGRESS && fpa->resubmit) {
            IR::IndexedVector<IR::StatOrDecl> components;
            auto ig_dprsr = control->tnaParams.at("ig_intr_md_for_dprsr");
            auto resubmitType = new IR::Member(new IR::PathExpression(ig_dprsr),
                                               IR::ID("resubmit_type"));
            components.push_back(new IR::AssignmentStatement(resubmitType,
                                 new IR::Constant(IR::Type::Bits::get(3), 0)));
            // If resubmit is set then create an if statement with condition (!drop && resubmit)
            // This if statement will be used to assign resubmit type
            // Also add the "ifTrue" statements of psa_resubmit in the same if statement
            TranslatePacketPathIfStatement cvt_resubmit(structure->resubmit, structure, INGRESS);
            if (structure->resubmit.ifStatement) {
                auto ifStmt = cvt_resubmit.convert(structure->resubmit.ifStatement);
                components.push_back(ifStmt->to<IR::IfStatement>()->ifTrue);
            }
            auto block = new IR::BlockStatement(components);
            auto newifStmt = new IR::IfStatement(cvt_resubmit.create_condition("psa_resubmit"),
                                                 block, nullptr);
            auto* body = control->body->clone();
            body->components.push_back(newifStmt);
            control->body = body;
        }
        return control;
    }
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

RewritePacketPath::RewritePacketPath(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                     PSA::ProgramStructure* structure) {
    setName("RewritePacketPath");
    auto* findPacketPath = new FindPacketPath(structure);
    addPasses({
        findPacketPath,
        new PacketPath(structure, typeMap, refMap, findPacketPath),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        new MoveAssignment(structure, findPacketPath),
        new P4::ClearTypeMap(typeMap),
        new BFN::TypeChecking(refMap, typeMap, true),
        new RewriteClone(structure->clone_i2e, INGRESS),
        new RewriteClone(structure->clone_e2e, EGRESS),
    });
}

}  // namespace PSA

}  // namespace BFN
