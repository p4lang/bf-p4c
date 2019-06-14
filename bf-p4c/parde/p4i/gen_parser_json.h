#ifndef EXTENSIONS_BF_P4C_PARDE_P4I_GEN_PARSER_JSON_H_
#define EXTENSIONS_BF_P4C_PARDE_P4I_GEN_PARSER_JSON_H_

#include <vector>
#include <map>

#include "bf-p4c/device.h"
#include "bf-p4c/logging/resources.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/parde/p4i/p4i_json_types.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "lib/cstring.h"
#include "lib/json.h"

class GenerateParserP4iJson : public ParserInspector {
    const ClotInfo& clotInfo;
    std::vector<P4iParser> parsers;
    std::vector<P4iParserClotUsage> clot_usage;
    bool collected;

    std::map<const IR::BFN::LoweredParserState*, int> state_ids;
    std::map<const IR::BFN::LoweredParserMatch*, int> tcam_ids[2];

    int getStateId(const IR::BFN::LoweredParserState* state);
    int getTcamId(const IR::BFN::LoweredParserMatch* match, gress_t gress);

    std::vector<P4iParserMatchOn> generateMatches(
            const IR::BFN::LoweredParserState* prev_state,
            const IR::BFN::LoweredParserMatch* match);

    std::vector<P4iParserSavesTo> generateSaves(const IR::BFN::LoweredParserMatch* match);

    std::vector<P4iParserExtract> generateExtracts(const IR::BFN::LoweredParserMatch* match);

    P4iParserStateTransition
    generateStateTransitionByMatch(const IR::BFN::LoweredParserState* next_state,
                         const IR::BFN::LoweredParserState* prev_state,
                         const IR::BFN::LoweredParserMatch* match);

    // Clots
    std::map<unsigned, unsigned> clot_tag_to_checksum_unit;
    void generateClotInfo(const IR::BFN::LoweredParserMatch* match,
                          const IR::BFN::LoweredParserState* state,
                          const gress_t gress);
    P4iParserClot
    generateExtractClot(const IR::BFN::LoweredExtractClot* match,
                        const IR::BFN::LoweredParserState* state);

    /// A parser match is a parser state.
    bool preorder(const IR::BFN::LoweredParserState* state) override;
    void end_apply() override { collected = true; }

 public:
    explicit GenerateParserP4iJson(const ClotInfo& clotInfo)
        : clotInfo(clotInfo), parsers(2), clot_usage(2), collected(false) {
        bool using_clots = Device::currentDevice() == Device::JBAY && BackendOptions().use_clot;

        for (auto gress : (gress_t[2]) {INGRESS, EGRESS}) {
            parsers[gress].parser_id = 0;
            parsers[gress].n_states = 256;
            parsers[gress].gress = cstring::to_cstring(gress);

            if (!using_clots) continue;

            clot_usage[gress].gress = gress;
            clot_usage[gress].num_clots = Device::numClots();
        }

        if (using_clots) {
            // Populate information for CLOT-eligible fields.
            for (auto field : *clotInfo.clot_eligible_fields()) {
                P4iFieldAlloc field_alloc;
                field_alloc.name = canon_name(field->name);
                field_alloc.is_readonly = clotInfo.is_readonly(field);
                field_alloc.is_modified = clotInfo.is_modified(field);
                field_alloc.is_checksum = clotInfo.is_checksum(field);
                field_alloc.bit_width = field->size;
                field_alloc.num_bits_in_clots = 0;
                field_alloc.num_bits_in_phvs = 0;

                for (auto entry : *clotInfo.slice_clots(field)) {
                    auto slice = entry.first;
                    field_alloc.num_bits_in_clots += slice->size();
                }

                field->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
                    field_alloc.num_bits_in_phvs += alloc.width;
                });

                clot_usage[field->gress].clot_eligible_fields.emplace_back(field_alloc);
            }
        }
    }

    Util::JsonArray* getParsersJson() const {
        BUG_CHECK(collected, "Calling ParserJsonGen without run pass");
        return toJsonArray(parsers);
    }

    Util::JsonArray* getClotsJson() const {
        BUG_CHECK(collected, "Calling ParserJsonGen without run pass");
        return toJsonArray(clot_usage);
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_P4I_GEN_PARSER_JSON_H_ */
