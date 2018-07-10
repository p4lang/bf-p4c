#include "p4/methodInstance.h"
#include "ir/ir.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "lib/ordered_set.h"
#include "psa_program_structure.h"
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

    const IR::BFN::TranslatedP4Parser *preorder(IR::BFN::TranslatedP4Parser *parser) override {
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

        if (auto *parser = findContext<IR::BFN::TranslatedP4Parser>()) {
            if (parser->thread != INGRESS) {
                return node; }
        } else if (auto *control = findContext<IR::BFN::TranslatedP4Deparser>()) {
            if (control->thread != INGRESS) {
                return node; }
        } else {
            return node;
        }

        if (pathname == resubmit.paramNameInParser) {
            auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                                       IR::ID("__resubmit_data"));
            auto member = new IR::Member(path, membername);
            return member;
        }

        if (pathname == resubmit.paramNameInDeparser) {
            auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
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
    explicit RewriteRecirculate(const PacketPathInfo& recirculate)
    : recirculate(recirculate) {
        setName("RewriteRecirculateIfPresent");
    }

    const IR::Type_StructLike *preorder(IR::Type_StructLike *type) override {
        prune();
        if (type->name == "compiler_generated_metadata_t") {
            // Inject a new field to hold the extract resubmit data
            LOG4("Injecting field for recirculate data into: " << type);
            type->fields.push_back(new IR::StructField("__recirculate_data", recirculate.p4Type));
        } else {
            // XXX(hanw): recirculate metadata to be extracted as a header
            auto rt = recirculate.p4Type;
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
        if (state->name != "__recirculate") return state;
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
                                      IR::ID("__recirculate_data"));
        auto *args = new IR::Vector<IR::Argument>({ new IR::Argument(member) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        auto *extract = new IR::MethodCallStatement(callExpr);
        LOG4("Generated extract for recirculate data: " << extract);
        state->components.push_back(extract);

        return state;
    }

    const IR::Node* preorder(IR::PathExpression* node) override {
        if (auto *parser = findContext<IR::BFN::TranslatedP4Parser>()) {
            if (parser->thread != INGRESS)
                return node;
        } else if (auto *control = findContext<IR::BFN::TranslatedP4Deparser>()) {
            if (control->thread != EGRESS)
                return node;
        } else {
            return node;
        }

        if (node->path->name == recirculate.paramNameInParser ||
            node->path->name == recirculate.paramNameInDeparser) {
            return new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                                  IR::ID("__recirculate_data"));
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

 private:
    const PacketPathInfo& recirculate;
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

        auto *tnaContext = findContext<IR::BFN::TranslatedP4Parser>();
        BUG_CHECK(tnaContext, "clone state not within translated parser?");
        BUG_CHECK(tnaContext->thread == EGRESS, "clone state not in ingress?");

        // clear existing statements
        state->components.clear();

        auto cgMeta = tnaContext->tnaParams.at("compiler_generated_meta");
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

    const IR::Node* preorder(IR::PathExpression* node) override {
        if (node->path->name == clone.paramNameInDeparser) {
            auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                    IR::ID(metadata));
            return path;
        }
        return node;
    }

 private:
    const PacketPathInfo& clone;
    cstring metadata;
};

RewritePacketPath::RewritePacketPath(PSA::ProgramStructure *structure) {
    setName("RewritePacketPath");
    addPasses({
        new RewriteResubmit(structure->resubmit),
        new RewriteRecirculate(structure->recirculate),
        new RewriteClone(structure->clone_i2e, INGRESS),
        new RewriteClone(structure->clone_e2e, EGRESS),
    });
}

}  // namespace PSA

}  // namespace BFN
