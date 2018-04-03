#include "ir/ir.h"
#include "lib/ordered_set.h"
#include "psa_program_structure.h"
#include "rewrite_packet_path.h"

namespace BFN {

namespace PSA {

namespace {

struct WriteFromStruct {
    /// the destination of the write (a metadata struct).
    const IR::Node* dest;

    /// the source of the write (a metadata struct).
    const IR::Node* source;
};

struct WriteFromField {
    /// the destination of the write (a metadata field).
    const IR::Member* dest;

    /// the source of the write (a metadata field).
    const IR::Member* source;
};

struct WriteFromConst {
    /// The destination of the write (a metadata field).
    const IR::Member* dest;

    /// The source of the write (a numeric constant).
    const IR::Constant* value;
};

struct RecirculateMetadata {
    /// The name of recirc_md in ingress parser
    cstring paramNameInParser;

    /// The name of recirc_md in egress deparser
    cstring paramNameInDeparser;

    ///
    ordered_set<const IR::AssignmentStatement*> fieldReadToReplace;

    ///
    ordered_set<const IR::AssignmentStatement*> fieldWriteToReplace;

    /// The assignment statement that will be replaced with buff.extract call.
    const IR::AssignmentStatement* structReadToReplace = nullptr;

    /// The assignment statement that will be replaced with pkt.emit call.
    const IR::AssignmentStatement* structWriteToReplace = nullptr;

    /// Metadata for the recirc operation

    /// Writes from metadata fields that need to be translated into extracts
    /// from the input buffer in the parser
    std::vector<WriteFromField> fieldWrites;

    /// Write from metadata structs that need to be translated into extracts
    /// from the input buffer in the parser
    std::vector<WriteFromStruct> structWrites;

    /// Write from constant that need to be translated into extracts
    /// from the input buffer in the parser. Or optimized away.
    std::vector<WriteFromConst> constantWrites;

    /// A P4 type for the recirc data, based on the type of the parameter to
    /// the parser.
    const IR::Type* p4Type = nullptr;
};

struct ResubmitMetadata {
    /// The name of the resubmit_metadata in ingress parser param.
    cstring paramNameInParser;

    /// The name of the resubmit_metadata in egress deparser param.
    cstring paramNameInDeparser;

    /// The resubmit.emit
    const IR::AssignmentStatement* assignmentStatementToReplace = nullptr;

    /// Writes from metadata fields that need to be translated into extracts
    /// from the input buffer in the parser
    std::vector<WriteFromField> fieldWrites;

    /// Write from metadata structs that need to be translated into extracts
    /// from the input buffer in the parser
    std::vector<WriteFromStruct> structWrites;

    /// Write from constant that need to be translated into extracts
    /// from the input buffer in the parser. Or optimized away.
    std::vector<WriteFromConst> constantWrites;

    /// A P4 type for the resubmit data, based on the type of the parameter to
    /// the parser.
    const IR::Type* p4Type = nullptr;
};

struct CloneMetadata {
    /// The name of the resubmit_metadata in ingress parser param.
    cstring paramNameInParser;

    /// The name of the resubmit_metadata in egress deparser param.
    cstring paramNameInDeparser;

    ///
    ordered_set<const IR::AssignmentStatement*> fieldReadToReplace;

    ///
    ordered_set<const IR::AssignmentStatement*> fieldWriteToReplace;

    /// The assignment statement that will be replaced with buff.extract call.
    const IR::AssignmentStatement* structReadToReplace = nullptr;

    /// The assignment statement that will be replaced with pkt.emit call.
    const IR::AssignmentStatement* structWriteToReplace = nullptr;

    /// Writes from metadata fields that need to be translated into extracts
    /// from the input buffer in the parser
    std::vector<WriteFromField> fieldWrites;

    /// Write from metadata structs that need to be translated into extracts
    /// from the input buffer in the parser
    std::vector<WriteFromStruct> structWrites;

    /// Write from constant that need to be translated into extracts
    /// from the input buffer in the parser. Or optimized away.
    std::vector<WriteFromConst> constantWrites;

    /// A P4 type for the resubmit data, based on the type of the parameter to
    /// the parser.
    const IR::Type* p4Type = nullptr;
};

struct FindResubmitData : public Inspector {
    explicit FindResubmitData(PSA::ProgramStructure *structure)
        : structure(structure) {
        setName("FindResubmitData");
    }

    boost::optional<ResubmitMetadata> resubmit;

    bool preorder(const IR::BFN::TranslatedP4Parser* node) override {
        // process ingress parser for resubmit data
        if (node->thread != INGRESS)
            return false;

        if (!resubmit)
            resubmit.emplace();

        resubmit->paramNameInParser = structure->psaPacketPathNames.at("parser::resubmit_md");
        resubmit->p4Type = structure->psaPacketPathTypes.at("parser::resubmit_md");
        return true;
    }

    bool preorder(const IR::BFN::TranslatedP4Deparser* node) override {
        // only process ingress deparser to find assignments on resubmit metadata.
        if (node->name != structure->getBlockName(PSA::ProgramStructure::INGRESS_DEPARSER))
            return false;

        resubmit->paramNameInDeparser = structure->psaPacketPathNames.at("deparser::resubmit_md");
        return true;
    }

    /// sanity check: the start state must have only select statement on istd.packet_path
    /// or extract statement on packet_in. Both statement cannot co-exist in the same
    /// start state in PSA.
    void postorder(const IR::AssignmentStatement* node) override {
        /// if not resubmit_md
        BUG_CHECK(structure->psaPacketPathNames.count("deparser::resubmit_md") != 0,
                  "No resubmit metadata found in the P4 program");

        if (auto expr = node->left->to<IR::PathExpression>()) {
            if (expr->path->name == structure->psaPacketPathNames.at("deparser::resubmit_md")) {
                resubmit->structWrites.push_back(WriteFromStruct {
                    node->left->getNode(),
                    node->right->getNode()
                });
                resubmit->assignmentStatementToReplace = node;
            }
        }
        // XXX(hanw): handle writes to IR::Member.
    }

 private:
    PSA::ProgramStructure *structure;
};

/// @pre assume that all structs are flattened, and the IR::Member is a member
/// of a struct / header.
struct FindRecirculateData : public Inspector {
    FindRecirculateData(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                        PSA::ProgramStructure *structure)
        : structure(structure), refMap(refMap), typeMap(typeMap) {
        setName("FindRecirculateData");
    }
    boost::optional<RecirculateMetadata> recirculate;

    void findRecirculateDataInParser(const IR::AssignmentStatement* node,
                                     const IR::BFN::TranslatedP4Parser* /* parser */) {
        if (auto expr = node->right->to<IR::PathExpression>()) {
            if (expr->path->name == recirculate->paramNameInParser) {
                LOG4("struct read " << expr->path->name);
                recirculate->structReadToReplace = node;
            }
        } else if (auto member = node->left->to<IR::Member>()) {
            if (auto type = member->expr->type->to<IR::Type_StructLike>()) {
                CHECK_NULL(recirculate->p4Type);
                if (auto typeName = recirculate->p4Type->to<IR::Type_Name>()) {
                    if (type->name == typeName->path->name) {
                        BUG_CHECK(node->right->is<IR::Member>(),
                                "No source field found in %1%", node);
                        recirculate->fieldWrites.push_back(WriteFromField{
                            member, node->right->to<IR::Member>()
                        });
                        recirculate->fieldReadToReplace.insert(node);
                    }
                } else {
                    BUG("Unhandled recirculate type %1%", recirculate->p4Type);
                }
            }
        }
    }

    void findRecirculateDataInDeparser(const IR::AssignmentStatement* node,
                                       const IR::BFN::TranslatedP4Deparser * /* control */) {
        if (auto expr = node->left->to<IR::PathExpression>()) {
            if (expr->path->name == recirculate->paramNameInDeparser) {
                LOG4("struct write " << expr->path->name);
                recirculate->structWrites.push_back(WriteFromStruct {
                    node->left->getNode(),
                    node->right->getNode()
                });
                recirculate->structWriteToReplace = node;
            }
        } else if (auto member = node->left->to<IR::Member>()) {
            if (auto expr = member->expr->to<IR::PathExpression>()) {
                if (expr->path->name == recirculate->paramNameInDeparser) {
                    recirculate->fieldWriteToReplace.insert(node);
                }
            }
        } else {
            BUG("Unhandled member %1%", node);
        }
    }

    bool preorder(const IR::BFN::TranslatedP4Parser* node) override {
        // only process ingress parser for recirculate metadata read
        if (!node || node->name != "ingressParserImpl")
            return false;

        // check recirculate metadata is not an empty struct.
        auto type = structure->psaPacketPathTypes.at("parser::recirc_md");
        if (auto name = type->to<IR::Type_Name>()) {
            auto decl = refMap->getDeclaration(name->path);
            if (auto stype = decl->to<IR::Type_StructLike>()) {
                auto width = stype->width_bits();
                if (width == 0) {
                    LOG4("No recirculate data to be parsed");
                    return false;
                }
            }
        }

        // mark 'recirculate' as valid
        if (!recirculate)
            recirculate.emplace();

        recirculate->paramNameInParser = structure->psaPacketPathNames.at("parser::recirc_md");

        if (!recirculate->p4Type)
            recirculate->p4Type = structure->psaPacketPathTypes.at("parser::recirc_md");
        return true;
    }

    bool preorder(const IR::BFN::TranslatedP4Deparser* node) override {
        // only process egress deparser for recirculate metadata write
        if (!node || node->name != "egressDeparserImpl")
            return false;

        // check recirculate metadata is not an empty struct.
        auto type = structure->psaPacketPathTypes.at("deparser::recirc_md");
        if (auto name = type->to<IR::Type_Name>()) {
            auto decl = refMap->getDeclaration(name->path);
            if (auto stype = decl->to<IR::Type_StructLike>()) {
                auto width = stype->width_bits();
                if (width == 0) {
                    LOG4("No recirculate data to be emitted");
                    return false;
                }
            }
        }

        // mark 'recirculate' as valid
        if (!recirculate)
            recirculate.emplace();

        recirculate->paramNameInDeparser = structure->psaPacketPathNames.at("deparser::recirc_md");

        if (!recirculate->p4Type)
            recirculate->p4Type = structure->psaPacketPathTypes.at("deparser::recirc_md");
        return true;
    }

    /// find writes to recirc_md in egress deparser
    bool preorder(const IR::AssignmentStatement *node) override {
        if (auto control = findContext<IR::BFN::TranslatedP4Deparser>())
            findRecirculateDataInDeparser(node, control);

        if (auto parser = findContext<IR::BFN::TranslatedP4Parser>())
            findRecirculateDataInParser(node, parser);

        return false;
    }

 private:
    PSA::ProgramStructure *structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
};

struct FindCloneData : public Inspector {
    explicit FindCloneData(PSA::ProgramStructure *structure, gress_t gress)
        : structure(structure) {
        setName("FindCloneData");

        if (gress == INGRESS)
            packetPath = "clone_i2e_md";
        else
            packetPath = "clone_e2e_md";
    }

    boost::optional<CloneMetadata> clone;

    bool preorder(const IR::BFN::TranslatedP4Parser* node) override {
        LOG1("inspecting parser " << node);
        // process ingress parser for clone data
        if (node->thread != EGRESS)
            return false;

        if (!clone)
            clone.emplace();

        clone->paramNameInParser = structure->psaPacketPathNames.at("parser::" + packetPath);
        clone->p4Type = structure->psaPacketPathTypes.at("parser::" + packetPath);
        return true;
    }

    bool preorder(const IR::BFN::TranslatedP4Deparser*) override {
        clone->paramNameInDeparser = structure->psaPacketPathNames.at("deparser::" + packetPath);
        return true;
    }

    /// sanity check: the start state must have only select statement on istd.packet_path
    /// or extract statement on packet_in. Both statement cannot co-exist in the same
    /// start state in PSA.
    void postorder(const IR::AssignmentStatement* node) override {
        LOG1("found assignment " << node);
        /// if not resubmit_md
        BUG_CHECK(structure->psaPacketPathNames.count("deparser::" + packetPath) != 0,
                  "No clone metadata found in the P4 program");

        if (auto expr = node->left->to<IR::PathExpression>()) {
            if (expr->path->name == structure->psaPacketPathNames.at("deparser::" + packetPath)) {
                clone->structWrites.push_back(WriteFromStruct {
                    node->left->getNode(),
                    node->right->getNode()
                });
            }
        }
    }

 private:
    PSA::ProgramStructure *structure;
    cstring packetPath;
};

struct RewriteResubmitIfPresent : public Transform {
    explicit RewriteResubmitIfPresent(const boost::optional<ResubmitMetadata>& resubmit)
        : resubmit(resubmit) {
        setName("RewriteResubmitIfPresent");
    }

    const IR::P4Program* preorder(IR::P4Program* program) override {
        if (!resubmit) {
            LOG4("No resubmit metadata found; skipping resubmit translation");
            prune();
            return program;
        }
        return program;
    }

    const IR::Type_StructLike *preorder(IR::Type_StructLike *type) override {
        prune();

        if (type->name == "compiler_generated_metadata_t") {
            // Inject a new field to hold the extract resubmit data
            LOG4("Injecting field for resubmit data into: " << type);
            CHECK_NULL(resubmit->p4Type);
            type->fields.push_back(new IR::StructField("$resubmit_data", resubmit->p4Type));
        } else {
            // XXX(hanw): resubmit metadata to be extracted as a header
            auto rt = resubmit->p4Type;
            if (auto t = rt->to<IR::Type_Name>()) {
                if (type->name == t->path->name) {
                    auto nt = new IR::Type_Header(type->name, type->annotations, type->fields);
                    return nt;
                }
            }
        }
        return type;
    }

    const IR::BFN::TranslatedP4Parser *preorder(IR::BFN::TranslatedP4Parser *parser) override {
        if (parser->thread != INGRESS || parser->name != "ingressParserImpl") {
            prune();
            return parser;
        }
        return parser;
    }

    // replace the resubmit extract call with extract() to resubmit md
    const IR::ParserState *preorder(IR::ParserState *state) override {
        if (state->name != "$resubmit") return state;
        prune();

        auto *tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "resubmit state not within translated parser?");
        BUG_CHECK(tnaContext->thread == INGRESS, "resubmit state not in ingress?");

        // clear existing statements
        state->components.clear();

        auto cgMeta = tnaContext->tnaParams.at("compiler_generated_meta");
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("$resubmit_data"));
        auto *args = new IR::Vector<IR::Expression>({member});
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

        gress_t thread;
        if (auto *parser = findContext<IR::BFN::TranslatedP4Parser>()) {
            thread = parser->thread;
        } else if (auto *control = findContext<IR::BFN::TranslatedP4Deparser>()) {
            thread = control->thread;
        } else {
            LOG3("Member expression " << node << " is not inside a translated control; "
                "won't translate it");
            return node;
        }

        if (pathname == resubmit->paramNameInParser) {
            auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                                       IR::ID("$resubmit_data"));
            auto member = new IR::Member(path, membername);
            return member;
        }
        return node;
    }

 private:
    const boost::optional<ResubmitMetadata>& resubmit;
};

struct RewriteRecirculateIfPresent : public Transform {
    explicit RewriteRecirculateIfPresent(const boost::optional<RecirculateMetadata>& recirculate)
    : recirculate(recirculate) {
        setName("RewriteRecirculateIfPresent");
    }

    const IR::P4Program* preorder(IR::P4Program* program) override {
        // Skip this pass entirely if no recirculate metadata is found.
        if (!recirculate) {
            LOG4("No recirculate metadata found; skipping recirculate translation");
            prune();
            return program;
        }
        return program;
    }

    const IR::Type_StructLike *preorder(IR::Type_StructLike *type) override {
        prune();
        if (type->name == "compiler_generated_metadata_t") {
            // Inject a new field to hold the extract resubmit data
            LOG4("Injecting field for recirculate data into: " << type);
            type->fields.push_back(new IR::StructField("$recirculate_data", recirculate->p4Type));
        } else {
            // XXX(hanw): recirculate metadata to be extracted as a header
            auto rt = recirculate->p4Type;
            if (auto t = rt->to<IR::Type_Name>()) {
                if (type->name == t->path->name) {
                    auto nt = new IR::Type_Header(type->name, type->annotations, type->fields);
                    return nt;
                }
            }
        }
        return type;
    }

    // given data to be recirculated, generate deparser and parser state.
    // replace the resubmit extract call with extract() to resubmit md
    const IR::ParserState *preorder(IR::ParserState *state) override {
        if (state->name != "$recirculate") return state;
        prune();

        auto *tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "recirculate state not within translated parser?");
        BUG_CHECK(tnaContext->thread == INGRESS, "recirculate state not in ingress?");

        // clear existing statements
        state->components.clear();

        auto cgMeta = tnaContext->tnaParams.at("compiler_generated_meta");
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto *member = new IR::Member(new IR::PathExpression(cgMeta),
                                      IR::ID("$recirculate_data"));
        auto *args = new IR::Vector<IR::Expression>({member});
        auto *callExpr = new IR::MethodCallExpression(method, args);
        auto *extract = new IR::MethodCallStatement(callExpr);
        LOG4("Generated extract for recirculate data: " << extract);
        state->components.push_back(extract);

        return state;
    }

    const IR::Member *preorder(IR::Member *node) override {
        auto expr = node->expr->to<IR::PathExpression>();
        if (!expr) return node;
        auto pathname = expr->path->name;

        gress_t thread;
        cstring packetPathName;
        if (auto *parser = findContext<IR::BFN::TranslatedP4Parser>()) {
            thread = parser->thread;
        } else if (auto *control = findContext<IR::BFN::TranslatedP4Deparser>()) {
            thread = control->thread;
        } else {
            LOG3("Member expression " << node << " is not inside a translated control; "
                "won't translate it");
            return node;
        }
        return node;
    }

    const IR::BFN::TranslatedP4Parser* preorder(IR::BFN::TranslatedP4Parser* node) override {
        /// only process ingress parser
        if (node->thread != gress_t::INGRESS)
            prune();
        return node;
    }

    const IR::BFN::TranslatedP4Deparser* preorder(IR::BFN::TranslatedP4Deparser* node) override {
        /// only process egress deparser
        if (node->thread != gress_t::EGRESS)
            prune();
        return node;
    }

    const IR::Statement *preorder(IR::AssignmentStatement *node) override {
        auto orig = getOriginal<IR::AssignmentStatement>();
        if (auto *control = findOrigCtxt<IR::BFN::TranslatedP4Deparser>()) {
            if (orig == recirculate->structWriteToReplace) {
                prune();
                auto args = new IR::Vector<IR::Expression>();
                args->push_back(node->right);
                LOG4("Replacing recirculate metadata assignment: " << node);
                auto extref = new IR::PathExpression("packet");
                auto method = new IR::Member(extref, "emit");
                auto mc = new IR::MethodCallExpression(method, args);
                return new IR::MethodCallStatement(mc);
            } else if (recirculate->fieldWriteToReplace.count(orig) != 0) {
                // TODO: replace with pkt.emit()
                return nullptr;
            }
        } else if (auto *parser = findOrigCtxt<IR::BFN::TranslatedP4Parser>()) {
            if (orig == recirculate->structReadToReplace) {
                auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                                           IR::ID("$recirculate_data"));
                auto stmt = new IR::AssignmentStatement(node->left, path);
                return stmt;
            } else if (recirculate->fieldReadToReplace.count(orig) != 0) {
                auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                                           IR::ID("$recirculate_data"));
                auto member = new IR::Member(path, node->right->to<IR::Member>()->member);
                auto stmt = new IR::AssignmentStatement(node->left, member);
                return stmt;
            }
        }
        return node;
    }

 private:
    const boost::optional<RecirculateMetadata>& recirculate;
};

struct RewriteCloneIfPresent : public Transform {
    explicit RewriteCloneIfPresent(
        const boost::optional<CloneMetadata> &clone, gress_t gress) : clone(clone) {
        setName("RewriteCloneIfPresent");
        if (gress == INGRESS)
            metadata = "$clone_i2e_data";
        else
            metadata = "$clone_e2e_data";
    }

    const IR::P4Program* preorder(IR::P4Program* program) override {
        // Skip this pass entirely if no clone metadata is found.
        if (!clone) {
            LOG4("No clone metadata found; skipping clone translation");
            prune();
            return program;
        }
        return program;
    }

    const IR::Type_StructLike *preorder(IR::Type_StructLike *type) override {
        prune();
        if (type->name == "compiler_generated_metadata_t") {
            // Inject a new field to hold the extract resubmit data
            LOG4("Injecting field for recirculate data into: " << type);
            type->fields.push_back(new IR::StructField(metadata, clone->p4Type));
        } else {
            auto rt = clone->p4Type;
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
        if (state->name != "$clone") return state;
        prune();

        auto *tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "clone state not within translated parser?");
        BUG_CHECK(tnaContext->thread == EGRESS, "clone state not in ingress?");

        // clear existing statements
        state->components.clear();

        auto cgMeta = tnaContext->tnaParams.at("compiler_generated_meta");
        auto packetInParam = tnaContext->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam), IR::ID("extract"));
        auto *member = new IR::Member(new IR::PathExpression(cgMeta), IR::ID(metadata));
        auto *args = new IR::Vector<IR::Expression>({member});
        auto *callExpr = new IR::MethodCallExpression(method, args);
        auto *extract = new IR::MethodCallStatement(callExpr);
        LOG4("Generated extract for clone data: " << extract);
        state->components.push_back(extract);

        return state;
    }

    // only process egress parser
    const IR::BFN::TranslatedP4Parser* preorder(IR::BFN::TranslatedP4Parser* node) override {
        if (node->thread != gress_t::EGRESS)
            prune();
        return node;
    }

    // do not process control block
    const IR::BFN::TranslatedP4Control* preorder(IR::BFN::TranslatedP4Control* node) override {
        prune();
        return node;
    }

    const IR::Statement *preorder(IR::AssignmentStatement *node) override {
        auto orig = getOriginal<IR::AssignmentStatement>();
        if (auto *control = findOrigCtxt<IR::BFN::TranslatedP4Control>()) {
            if (orig == clone->structWriteToReplace) {
                prune();
                auto args = new IR::Vector<IR::Expression>();
                args->push_back(node->right);
                LOG4("Replacing clone metadata assignment: " << node);
                auto extref = new IR::PathExpression("packet");
                auto method = new IR::Member(extref, "emit");
                auto mc = new IR::MethodCallExpression(method, args);
                return new IR::MethodCallStatement(mc);
            } else if (clone->fieldWriteToReplace.count(orig) != 0) {
                // TODO: replace with pkt.emit()
                return nullptr;
            }
        } else if (auto *parser = findOrigCtxt<IR::BFN::TranslatedP4Parser>()) {
            if (orig == clone->structReadToReplace) {
                auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                        IR::ID(metadata));
                auto stmt = new IR::AssignmentStatement(node->left, path);
                return stmt;
            } else if (clone->fieldReadToReplace.count(orig) != 0) {
                auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                        IR::ID(metadata));
                auto member = new IR::Member(path, node->right->to<IR::Member>()->member);
                auto stmt = new IR::AssignmentStatement(node->left, member);
                return stmt;
            }
        }
        return node;
    }

    const IR::Node* preorder(IR::PathExpression* node) override {
        if (node->path->name == clone->paramNameInDeparser) {
            auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                    IR::ID(metadata));
            return path;
        }
        return node;
    }

 private:
    const boost::optional<CloneMetadata>& clone;
    cstring metadata;
};

}  // namespace

TranslatePacketPath::TranslatePacketPath(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                         PSA::ProgramStructure *structure) {
    setName("TranslatePacketPath");
    auto findResubmitData = new FindResubmitData(structure);
    auto findRecircData = new FindRecirculateData(refMap, typeMap, structure);
    auto findCloneI2EData = new FindCloneData(structure, gress_t::INGRESS);
    auto findCloneE2EData = new FindCloneData(structure, gress_t::EGRESS);
    addPasses({
        findResubmitData,
        new RewriteResubmitIfPresent(findResubmitData->resubmit),
        findRecircData,
        new RewriteRecirculateIfPresent(findRecircData->recirculate),
        findCloneI2EData,
        new RewriteCloneIfPresent(findCloneI2EData->clone, gress_t::INGRESS),
        findCloneE2EData,
        new RewriteCloneIfPresent(findCloneE2EData->clone, gress_t::EGRESS),
    });
}

}  // namespace PSA

}  // namespace BFN
