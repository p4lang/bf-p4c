#ifndef EXTENSIONS_BF_P4C_PARDE_P4I_GEN_PARSER_JSON_H_
#define EXTENSIONS_BF_P4C_PARDE_P4I_GEN_PARSER_JSON_H_

#include <vector>
#include <map>

#include "bf-p4c/device.h"
#include "bf-p4c/logging/resources.h"
#include "bf-p4c/parde/p4i/p4i_json_types.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "lib/cstring.h"
#include "lib/json.h"

class GenerateParserP4iJson : public ParserInspector {
    std::vector<P4iParser> parsers;
    bool collected;

    std::map<const IR::BFN::LoweredParserState*, int> state_ids;
    std::map<const IR::BFN::LoweredParserMatch*, int> tcam_ids;

    int getStateId(const IR::BFN::LoweredParserState* state);
    int getTcamId(const IR::BFN::LoweredParserMatch* match);

    std::vector<P4iParserMatchOn> generateMatches(
            const IR::BFN::LoweredParserState* prev_state,
            const IR::BFN::LoweredParserState* curr_state,
            const IR::BFN::LoweredParserMatch* match);

    std::vector<P4iParserExtract> generateExtracts(const IR::BFN::LoweredParserMatch* match);

    P4iParserState
    generateStateByMatch(const IR::BFN::LoweredParserState* curr_state,
                         const IR::BFN::LoweredParserState* prev_state,
                         const IR::BFN::LoweredParserMatch* match);

    /// A parser match is a parser state.
    bool preorder(const IR::BFN::LoweredParserState* state) override;
    void end_apply() override { collected = true; }

 public:
    GenerateParserP4iJson() : parsers(2), collected(false) {
        parsers[INGRESS].parser_id = 0;
        parsers[INGRESS].n_states = 256;
        parsers[INGRESS].gress = cstring::to_cstring(INGRESS);
        parsers[EGRESS].parser_id = 0;
        parsers[EGRESS].n_states = 256;
        parsers[EGRESS].gress = cstring::to_cstring(EGRESS);
    }

    Util::JsonArray* getParsersJson() const {
        BUG_CHECK(collected, "Calling ParserJsonGen without run pass");
        return toJsonArray(parsers);
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_P4I_GEN_PARSER_JSON_H_ */
