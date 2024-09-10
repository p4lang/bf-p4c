#ifndef BF_P4C_PARDE_UPDATE_PARSER_WRITE_MODE_H_
#define BF_P4C_PARDE_UPDATE_PARSER_WRITE_MODE_H_

#include <ir/ir.h>
#include "ir/pass_manager.h"

#include "backends/tofino/parde/check_parser_multi_write.h"
#include "backends/tofino/parde/parser_info.h"
#include "backends/tofino/phv/phv_fields.h"

struct UpdateParserWriteMode : public PassManager {
    explicit UpdateParserWriteMode(const PhvInfo& phv) {
        auto parser_info = new CollectParserInfo;
        auto* field_to_states = new MapFieldToParserStates(phv);
        auto *check_write_mode_consistency =
            new CheckWriteModeConsistency(phv, *field_to_states, *parser_info);

        addPasses({
            parser_info,
            field_to_states,
            check_write_mode_consistency,
        });
    }
};

#endif /*BF_P4C_PARDE_UPDATE_PARSER_WRITE_MODE_H_*/
