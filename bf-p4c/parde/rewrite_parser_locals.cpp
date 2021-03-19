#include "bf-p4c/parde/rewrite_parser_locals.h"

bool GetSelectFieldInfo::preorder(const IR::BFN::Select* select) {
    auto state = findContext<IR::BFN::ParserState>();
    auto save = select->source->to<IR::BFN::SavedRVal>();
    if (save) {
        auto field = phv.field(save->source);
        select_field_to_state[field].insert(state);
    }
    return true;
}

bool AddParserMatchDefs::preorder(IR::BFN::Extract* extract) {
    auto parser = findOrigCtxt<IR::BFN::Parser>();
    auto state = findOrigCtxt<IR::BFN::ParserState>();
    auto graph = parserInfo.graph(parser);
    auto dest_field = phv.field(extract->dest->field);
    if (getSelectField.select_field_to_state.count(dest_field) &&
        extract->dest->field->is<IR::TempVar>() && !uses.is_used_mau(dest_field)) {
        for (auto select_state : getSelectField.select_field_to_state.at(dest_field)) {
            if (graph.is_ancestor(state, select_state)) {
                auto match = new IR::BFN::MatchLVal(extract->dest->field);
                LOG3("Match Value added in " << extract << " in state " << state->name);
                extract->dest = match;
                break;
            }
        }
    }
    return true;
}

RewriteParserMatchDefs::RewriteParserMatchDefs(const PhvInfo& phv) {
    auto* parserInfo = new CollectParserInfo;
    auto* selectFieldInfo = new GetSelectFieldInfo(phv);
    auto* uses = new PhvUse(phv);
    addPasses({
        uses,
        new ResolveExtractSaves(phv),
        parserInfo,
        selectFieldInfo,
        new AddParserMatchDefs(phv, *parserInfo, *selectFieldInfo, *uses)
    });
}

