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
        if (ctxt) {
            auto leftMember = stmt->left->to<IR::Member>();
            if (!leftMember) return false;
            auto leftPathEx = leftMember->expr->to<IR::PathExpression>();
            if (!leftPathEx) return false;
            auto leftPath = leftPathEx->path->to<IR::Path>();
            if (!leftPath) return false;
            auto rightBool = stmt->right->to<IR::BoolLiteral>();
            if (ctxt->thread == INGRESS) {
                if (leftPath && rightBool &&
                    leftPath->name == COMPILER_META && leftMember->member == "resubmit" &&
                    rightBool->value == true) {
                    resubmit |= true;
                } else if (leftPath && rightBool &&
                    leftPath->name == COMPILER_META && leftMember->member == "clone_i2e" &&
                    rightBool->value == true) {
                    clone_i2e |= true;
                }
            } else {
                if (leftPath && rightBool &&
                    leftPath->name == COMPILER_META && leftMember->member == "clone_e2e" &&
                    rightBool->value == true) {
                    clone_e2e |= true;
                }
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

    void updateFields(IR::Type_StructLike* type) {
        IR::IndexedVector<IR::StructField> fields;
        auto *fieldAnnotations = new IR::Annotations();
        fieldAnnotations->annotations.push_back(
                            new IR::Annotation(IR::ID("flexible"), {}));
        if ((fpa->clone_i2e && structure->clone_i2e.structType->to<IR::Type_StructLike>()->name) ||
           (fpa->clone_e2e && structure->clone_e2e.structType->to<IR::Type_StructLike>()->name)) {
            fields.push_back(new IR::StructField("mirror_source", fieldAnnotations,
                                                                  IR::Type::Bits::get(8)));
        }
        for (auto& f : type->fields) {
            fields.push_back(new IR::StructField(f->name, fieldAnnotations, f->type));
        }
        type->fields = fields;
        return;
    }

    IR::Type_StructLike* postorder(IR::Type_StructLike* type) override {
        prune();
        if (type->name == structure->recirculate.structType->to<IR::Type_StructLike>()->name ||
            type->name == structure->resubmit.structType->to<IR::Type_StructLike>()->name ||
            type->name == structure->clone_i2e.structType->to<IR::Type_StructLike>()->name ||
            type->name == structure->clone_e2e.structType->to<IR::Type_StructLike>()->name) {
            updateFields(type);
        }
        return type;
    }

    // Add assignment statement to copy packet data to metadata
    void copyToMetadata(IR::ParserState* state, const PacketPathInfo& packetPath,
                        const IR::Member* packetMeta) {
        auto pathname = structure->egress_parser.psaParams.at("metadata");
        auto path = new IR::PathExpression(pathname);
        for (auto& pf : packetPath.structType->to<IR::Type_StructLike>()->fields) {
            auto leftMember = new IR::Member(path, pf->name);
            for (auto f : structure->metadataType->to<IR::Type_StructLike>()->fields) {
                if (f->name == pf->name) {
                    auto rightMember = new IR::Member(packetMeta, f->name);
                    auto setMetadata = new IR::AssignmentStatement(leftMember, rightMember);
                    state->components.push_back(setMetadata);
                    break;
                }
            }
        }
        return;
    }

    void addExtract(IR::ParserState* state, const IR::Member* extractMember,
                    const IR::BFN::TnaParser* parser) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(extractMember) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        auto *extract = new IR::MethodCallStatement(callExpr);
        state->components.push_back(extract);
        return;
    }

    // Create a state to extract recirculated data and assign them to metadata
    IR::ParserState* create_recirculate_state(const IR::BFN::TnaParser* tnaContext) {
        auto statements = new IR::IndexedVector<IR::StatOrDecl>();
        auto select = new IR::PathExpression(IR::ID("__skip_to_packet"));
        auto newStateName = IR::ID(cstring("__recirculate"));
        auto *newState = new IR::ParserState(newStateName, *statements, select);
        auto cgMeta = tnaContext->tnaParams.at(BFN::COMPILER_META);
        auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("__recirculate_data"));
        addExtract(newState, member, tnaContext);
        copyToMetadata(newState, structure->recirculate, member);
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
        auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("__resubmit_data"));
        if (structure->resubmit.ifStatement) {
            addExtract(state, member, tnaContext);
        } else {
            auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("advance"));
            auto constant = new IR::Constant(IR::Type::Bits::get(32), 64);
            auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(constant) });
            auto *callExpr = new IR::MethodCallExpression(method, args);
            auto *advance = new IR::MethodCallStatement(callExpr);
            state->components.push_back(advance);
        }
        // If resubmit is enabled then add assignment statements
        if (fpa->resubmit) {
            copyToMetadata(state, structure->resubmit, member);
            // Add assignment statement for packet path
            auto packetPath = new IR::Member(new IR::PathExpression(cgMeta), IR::ID("packet_path"));
            auto packetPathStmt = new IR::AssignmentStatement(packetPath,
                                                    new IR::Constant(IR::Type::Bits::get(8), 5));
            state->components.push_back(packetPathStmt);
            auto resubmitEn =  new IR::Member(new IR::PathExpression(cgMeta), IR::ID("resubmit"));
            state->components.push_back(new IR::AssignmentStatement(resubmitEn,
                                                                new IR::BoolLiteral(false)));
        }
        return;
    }

    void updateMirrorState(IR::ParserState* state) {
        auto *tnaContext = findContext<IR::BFN::TnaParser>();
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        if (!fpa->clone_i2e && !fpa->clone_e2e) {
            auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("advance"));
            auto constant = new IR::Constant(IR::Type::Bits::get(32), 0);
            auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(constant) });
            auto *callExpr = new IR::MethodCallExpression(method, args);
            auto *advance = new IR::MethodCallStatement(callExpr);
            state->components.push_back(advance);
            return;
        }
        auto selectCases = new IR::Vector<IR::SelectCase>();
        if (fpa->clone_e2e) {
            selectCases->push_back(new IR::SelectCase(new IR::Mask(
                                                  new IR::Constant(IR::Type::Bits::get(8), 31),
                               new IR::Constant(IR::Type::Bits::get(8), 25)),
                               new IR::PathExpression("__mirror_egress")));
        }
        if (fpa->clone_i2e) {
            selectCases->push_back(new IR::SelectCase(new IR::Mask(
                                                   new IR::Constant(IR::Type::Bits::get(8), 31),
                                   new IR::Constant(IR::Type::Bits::get(8), 8)),
                                     new IR::PathExpression("__mirror_ingress")));
        }
        auto *method = new IR::Member(new IR::PathExpression(packetInParam), IR::ID("lookahead"));
        auto *typeArgs = new IR::Vector<IR::Type>({ IR::Type::Bits::get(8) });
        auto *lookaheadExpr = new IR::MethodCallExpression(method, typeArgs,
                                                       new IR::Vector<IR::Argument>);
        auto selectOn = new IR::ListExpression({lookaheadExpr});
        auto selectExpression = new IR::SelectExpression(selectOn, *selectCases);
        state->selectExpression = selectExpression;
        return;
    }

    const IR::ParserState *preorder(IR::ParserState *state) override {
        if (state->name == "__phase0") {
            addRecirculateState(state);
        } else if (state->name == "__resubmit") {
            updateResubmitState(state);
            addRecirculateState(state);
        } else if (state->name == "__mirrored") {
            updateMirrorState(state);
        }
        return state;
    }

    IR::ParserState* create_mirror_state(IR::BFN::TnaParser* tnaContext, gress_t gress) {
        cstring gress_str = gress ? "egress" : "ingress";
        auto statements = new IR::IndexedVector<IR::StatOrDecl>();
        auto cgMeta = tnaContext->tnaParams.at(BFN::COMPILER_META);
        auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID(gress ? "__clone_e2e_data" : "__clone_i2e_data"));
        auto select = new IR::PathExpression(IR::ID("__egress_p4_entry_point"));
        auto newStateName = IR::ID(cstring("__mirror_" + gress_str));
        auto *newState = new IR::ParserState(newStateName, *statements, select);
        newState->annotations = newState->annotations
            ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                 new IR::StringLiteral(cstring("$__mirror_" + gress_str)));
        addExtract(newState, member, tnaContext);
        // Add assignment statement for packet path
        auto cloneType = gress ? structure->clone_e2e : structure->clone_i2e;
        copyToMetadata(newState, cloneType, member);
        auto packetPath = new IR::Member(new IR::PathExpression(cgMeta), IR::ID("packet_path"));
        auto packetPathStmt = new IR::AssignmentStatement(packetPath,
                                                new IR::Constant(IR::Type::Bits::get(8),
                                                     gress ? 4 : 3));
        newState->components.push_back(packetPathStmt);
        auto cloneEn =  new IR::Member(new IR::PathExpression(cgMeta),
                                            IR::ID(gress ? "clone_e2e" : "clone_i2e"));
        newState->components.push_back(new IR::AssignmentStatement(cloneEn,
                                                                new IR::BoolLiteral(false)));
        return newState;
    }

    // Include __recirculate state in ingress parser
    const IR::BFN::TnaParser* preorder(IR::BFN::TnaParser* node) override {
        if (node->thread == gress_t::INGRESS) {
            node->states.push_back(create_recirculate_state(node));
        } else {
            if (fpa->clone_i2e) {
                node->states.push_back(create_mirror_state(node, INGRESS));
            } else if (fpa->clone_e2e) {
                node->states.push_back(create_mirror_state(node, EGRESS));
            }
        }
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

    IR::BFN::TnaDeparser*
    deparserMirror(IR::BFN::TnaDeparser* control) {
        auto declArgs = new IR::Vector<IR::Argument>({});
        auto declType = new IR::Type_Name("Mirror");
        auto decl = new IR::Declaration_Instance("mirror", declType, declArgs);
        IR::IndexedVector<IR::Declaration> parameters;
        parameters.push_back(decl);
        for (auto p : control->controlLocals) {
             parameters.push_back(p);
        }
        control->controlLocals = parameters;
        auto* method = new IR::Member(new IR::PathExpression("mirror"),
                                      IR::ID("emit"));
        auto cgMetadataParam = control->tnaParams.at(COMPILER_META);
        auto* args = new IR::Vector<IR::Argument>();
        auto typeArgs = new IR::Vector<IR::Type>();
        auto* member = new IR::Member(new IR::PathExpression(cgMetadataParam),
                         IR::ID(control->thread ? "__clone_e2e_data" : "__clone_i2e_data"));
        auto mirror_id = new IR::Member(new IR::PathExpression(cgMetadataParam),
                                        IR::ID("mirror_id"));
        args->push_back(new IR::Argument(mirror_id));
        args->push_back(new IR::Argument(member));
        auto cloneMetaType = control->thread ? structure->clone_e2e.p4Type :
                                               structure->clone_i2e.p4Type;
        typeArgs->push_back(cloneMetaType);
        auto* callExpr = new IR::MethodCallExpression(method, typeArgs, args);
        // Add if(mirror_type == 0) to emit
        auto ig_dprsr = control->tnaParams.at(control->thread ? "eg_intr_md_for_dprsr"
                                              : "ig_intr_md_for_dprsr");
        IR::IndexedVector<IR::StatOrDecl> components;
        components.push_back(new IR::MethodCallStatement(callExpr));
        auto mirror  = new IR::Member(new IR::PathExpression(ig_dprsr), "mirror_type");
        auto condition = new IR::Equ(mirror, new IR::Constant(IR::Type::Bits::get(3),
                                      control->thread ? 1 : 0));
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
        } else if (control->thread == INGRESS && fpa->clone_i2e) {
            deparserMirror(control);
        } else if (control->thread == EGRESS && fpa->clone_e2e) {
            deparserMirror(control);
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

    void add_clone_data(cstring clone, cstring compilerMeta, IR::BFN::TnaControl* control) {
        auto* compilerCloneHeader = new IR::Member(new IR::PathExpression(compilerMeta),
                     IR::ID(clone == "clone_i2e" ? "__clone_i2e_data" : "__clone_e2e_data"));
        auto intr_dprsr = control->tnaParams.at(clone == "clone_i2e" ? "ig_intr_md_for_dprsr" :
                                                "eg_intr_md_for_dprsr");
        auto mirrorType = new IR::Member(new IR::PathExpression(intr_dprsr),
                                           IR::ID("mirror_type"));
        IR::IndexedVector<IR::StatOrDecl> components;
        components.push_back(new IR::AssignmentStatement(mirrorType,
                        new IR::Constant(IR::Type::Bits::get(3), clone == "clone_i2e" ? 0 : 1)));
        components.push_back(new IR::AssignmentStatement(
                         new IR::Member(compilerCloneHeader, IR::ID("mirror_source")),
                         new IR::Constant(IR::Type::Bits::get(8), clone == "clone_i2e" ? 8 : 25)));
        IR::IfStatement* newifStmt = nullptr;
        if (clone == "clone_i2e") {
            TranslatePacketPathIfStatement cvt_clone_i2e(structure->clone_i2e, structure, INGRESS);
            if (structure->clone_i2e.ifStatement) {
                auto ifStmt = cvt_clone_i2e.convert(structure->clone_i2e.ifStatement);
                components.push_back(ifStmt->to<IR::IfStatement>()->ifTrue);
            }
            auto block = new IR::BlockStatement(components);
            newifStmt = new IR::IfStatement(cvt_clone_i2e.create_condition("psa_clone_i2e"),
                                             block, nullptr);
        } else {
            TranslatePacketPathIfStatement cvt_clone_e2e(structure->clone_e2e, structure, EGRESS);
            if (structure->clone_e2e.ifStatement) {
                auto ifStmt = cvt_clone_e2e.convert(structure->clone_e2e.ifStatement);
                components.push_back(ifStmt->to<IR::IfStatement>()->ifTrue);
            }
            auto block = new IR::BlockStatement(components);
            newifStmt = new IR::IfStatement(cvt_clone_e2e.create_condition("psa_clone_e2e"),
                                             block, nullptr);
        }
        auto* body = control->body->clone();
        body->components.push_back(newifStmt);
        control->body = body;
    }

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
        } else if (control->thread == EGRESS && fpa->clone_e2e) {
            add_clone_data("clone_e2e", cgMetadataParam, control);
        } else if (control->thread == INGRESS && fpa->clone_i2e) {
            add_clone_data("clone_i2e", cgMetadataParam, control);
        }
        return control;
    }
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
    });
}

}  // namespace PSA

}  // namespace BFN