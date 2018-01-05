#include "resubmit.h"
#include "program_structure.h"
#include "ir/ir.h"

namespace BFN {

namespace PSA {

/// sanity check: the start state must have only select statement on istd.packet_path
/// or extract statement on packet_in. Both statement cannot co-exist in the same
/// start state in PSA.
bool
FindResubmitData::preorder(const IR::P4Parser *parser) {
    if (parser->name != structure->getBlockName(ProgramStructure::INGRESS_PARSER))
        return false;

    auto resub_meta = parser->getApplyParameters()->getParameter(4);
    structure->psaTypes.emplace("resub_md", resub_meta->type);
    structure->psaParams.emplace("resub_md", resub_meta->name);

    auto recirc_meta = parser->getApplyParameters()->getParameter(5);
    structure->psaTypes.emplace("recirc_md", recirc_meta->type);
    structure->psaParams.emplace("recirc_md", recirc_meta->name);

    return false;
}

const IR::Type_StructLike*
RewriteResubmitIfPresent::preorder(IR::Type_StructLike *type) {
    prune();
    if (type->name == "compiler_generated_metadata_t") {
        // Inject a new field to hold the extract resubmit data
        LOG4("Injecting field for resubmit data into: " << type);
        type->fields.push_back(new IR::StructField("__resubmit_data",
                                                   structure->psaTypes.at("resub_md")));
    } else {
        // XXX(hanw): resubmit metadata to be extracted as a header
        auto rt = structure->psaTypes.at("resub_md");
        if (auto t = rt->to<IR::Type_Name>()) {
            if (type->name == t->path->name) {
                auto nt = new IR::Type_Header(type->name, type->annotations, type->fields);
                return nt;
            }
        }
    }
    return type;
}

const IR::BFN::TranslatedP4Parser*
RewriteResubmitIfPresent::preorder(IR::BFN::TranslatedP4Parser *parser) {
    if (parser->thread != INGRESS || parser->name != "ingressParserImpl") {
        prune();
        return parser;
    }
    return parser;
}

// replace the resubmit extract call with extract() to resubmit md
const IR::ParserState*
RewriteResubmitIfPresent::preorder(IR::ParserState *state) {
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
    auto *args = new IR::Vector<IR::Expression>({member});
    auto *callExpr = new IR::MethodCallExpression(method, args);
    auto *extract = new IR::MethodCallStatement(callExpr);
    LOG4("Generated extract for resubmit data: " << extract);
    state->components.push_back(extract);

    return state;
}

const IR::Member*
RewriteResubmitIfPresent::preorder(IR::Member *node) {
    auto membername = node->member.name;
    auto expr = node->expr->to<IR::PathExpression>();
    if (!expr) return node;
    auto pathname = expr->path->name;

    gress_t thread;
    if (auto *parser = findContext<IR::BFN::TranslatedP4Parser>()) {
        thread = parser->thread;
    } else if (auto *control = findContext<IR::BFN::TranslatedP4Control>()) {
        thread = control->thread;
    } else {
        LOG3("Member expression " << node << " is not inside a translated control; "
                "won't translate it");
        return node;
    }

    if (pathname == structure->psaParams.at("resub_md")) {
        auto path = new IR::Member(new IR::PathExpression("compiler_generated_meta"),
                                   IR::ID("__resubmit_data"));
        auto member = new IR::Member(path, membername);
        return member;
    }

    return node;
}

}  // namespace PSA

}  // namespace BFN
