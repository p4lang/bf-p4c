#ifndef EXTENSIONS_BF_P4C_PARDE_P4I_P4I_JSON_TYPES_H_
#define EXTENSIONS_BF_P4C_PARDE_P4I_P4I_JSON_TYPES_H_

#include <boost/optional.hpp>
#include <vector>

#include "lib/cstring.h"
#include "lib/json.h"

struct ToJsonObject {
    virtual ~ToJsonObject() {}
    virtual Util::JsonObject* toJson() const = 0;
};

template<class T>
Util::JsonArray* toJsonArray(const std::vector<T>& array) {
    Util::JsonArray* rst = new Util::JsonArray();
    for (const auto& v : array) {
        rst->append(v.toJson()); }
    return rst;
}

struct P4iParserExtract : ToJsonObject {
    int extractor_id;                     // required, Which extractor is being used.
    int bit_width;                        // required, Size of extractor.
    boost::optional<int> buffer_offset;   // Offset in the input buffer.
    boost::optional<int> constant_value;  // Constant to be extracted.
    int dest_container;                   // required, PHV container address.

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("extractor_id", new Util::JsonValue(extractor_id));
        rst->emplace("bit_width", new Util::JsonValue(bit_width));
        if (buffer_offset) {
            rst->emplace("buffer_offset", new Util::JsonValue(*buffer_offset)); }
        if (constant_value) {
            rst->emplace("constant_value", new Util::JsonValue(*constant_value)); }
        rst->emplace("dest_container", new Util::JsonValue(dest_container));
        return rst;
    }
};

struct P4iParserClotField : ToJsonObject {
    cstring name;
    int field_msb;
    int field_lsb;
    int clot_offset;

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("name", new Util::JsonValue(name));
        rst->emplace("field_msb", new Util::JsonValue(field_msb));
        rst->emplace("field_lsb", new Util::JsonValue(field_lsb));
        rst->emplace("clot_offset", new Util::JsonValue(clot_offset));
        return rst;
    }
};

struct P4iParserClot : ToJsonObject {
    cstring issue_state;
    int offset;
    unsigned tag;
    int length;
    bool has_checksum;
    std::vector<std::vector<P4iParserClotField>> field_lists;

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        auto* fls = new Util::JsonArray();
        for (auto field_list : field_lists) {
            auto fl = new Util::JsonArray();
            for (auto f : field_list)
                fl->append(f.toJson());
            fls->append(fl);
        }
        rst->emplace("field_lists", fls);
        rst->emplace("issue_state", new Util::JsonValue(issue_state));
        rst->emplace("offset", new Util::JsonValue(offset));
        rst->emplace("tag", new Util::JsonValue(tag));
        rst->emplace("length", new Util::JsonValue(length));
        rst->emplace("has_checksum", new Util::JsonValue(has_checksum));
        return rst;
    }
};

struct P4iFieldAlloc : ToJsonObject {
    cstring name;
    bool is_readonly;
    bool is_modified;
    bool is_checksum;
    int bit_width;
    int num_bits_in_clots;
    int num_bits_in_phvs;
    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("name", new Util::JsonValue(name));
        rst->emplace("is_readonly", new Util::JsonValue(is_readonly));
        rst->emplace("is_modified", new Util::JsonValue(is_modified));
        rst->emplace("is_checksum", new Util::JsonValue(is_checksum));
        rst->emplace("bit_width", new Util::JsonValue(bit_width));
        rst->emplace("num_bits_in_clots", new Util::JsonValue(num_bits_in_clots));
        rst->emplace("num_bits_in_phvs", new Util::JsonValue(num_bits_in_phvs));
        return rst;
    }
};

struct P4iParserClotUsage : ToJsonObject {
    gress_t gress;
    int num_clots;
    std::vector<P4iParserClot> clots;
    std::vector<P4iFieldAlloc> clot_eligible_fields;

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("gress", new Util::JsonValue(::toString(gress)));
        rst->emplace("num_clots", new Util::JsonValue(clots.size()));
        rst->emplace("clots", toJsonArray(clots));
        rst->emplace("clot_eligible_fields", toJsonArray(clot_eligible_fields));
        return rst;
    }
};

struct P4iParserSavesTo : ToJsonObject {
    int hardware_id;                     // required, Register ID being saved to.
    int buffer_offset;                   // required, buffer offset in input buffer.

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("hardware_id", new Util::JsonValue(hardware_id));
        rst->emplace("buffer_offset", new Util::JsonValue(buffer_offset));
        return rst;
    }
};

struct P4iParserMatchOn : ToJsonObject {
    int hardware_id;                     // required, Register ID being matched on.
    int bit_width;                       // required, Size of the register.
    boost::optional<cstring> value_set;  // Parser value set name matched on.
    boost::optional<cstring> value;          // Value matched on.
    boost::optional<int> mask;           // Value or value set mask.

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("hardware_id", new Util::JsonValue(hardware_id));
        rst->emplace("bit_width", new Util::JsonValue(bit_width));
        if (value_set) {
            rst->emplace("value_set", new Util::JsonValue(*value_set)); }
        if (value) {
            rst->emplace("value", new Util::JsonValue(*value)); }
        return rst;
    }
};

struct P4iParserStateTransition : ToJsonObject {
    int next_state_id;  // required, enum=range(0,256), Unique state identifier.
    int previous_state_id = 0;   // required, The id of the previous state for this transition.
    int tcam_row;  // required, enum=range(0, 256), Parser TCAM row.
    int shifts;    // required, enum=range(0,33), Number of bytes shifted in the buffer.
    std::vector<P4iParserExtract> extracts;   // required, List of extractors in use.
    std::vector<P4iParserMatchOn> matches;  // required, List of matches in use.
    std::vector<P4iParserSavesTo> saves;  // required, List of saves in use.
    bool has_counter;    // required, True if the state uses a counter.
    cstring next_state_name;  // required, Name of the state in this row.
    cstring previous_state_name;  // optional

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("previous_state_name", new Util::JsonValue(previous_state_name));
        rst->emplace("previous_state_id", new Util::JsonValue(previous_state_id));
        rst->emplace("next_state_name", new Util::JsonValue(next_state_name));
        rst->emplace("next_state_id", new Util::JsonValue(next_state_id));
        rst->emplace("tcam_row", new Util::JsonValue(tcam_row));
        rst->emplace("shifts", new Util::JsonValue(shifts));
        rst->emplace("extracts", toJsonArray(extracts));
        rst->emplace("matchesOn", toJsonArray(matches));
        rst->emplace("savesTo", toJsonArray(saves));
        rst->emplace("has_counter", new Util::JsonValue(has_counter));
        return rst;
    }
};

struct P4iPhase0 : ToJsonObject {
    std::string table_name;
    std::string action_name;
    P4iPhase0() : table_name(""), action_name("") {}
    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        BFN::Visualization::usagesToCtxJson(rst, table_name, action_name);
        return rst;
    }
};

struct P4iParser : ToJsonObject {
    int parser_id;  // required, enum=range(0, 18), Parser ID
    cstring gress;  // required, enum=["ingress", "egress"], The gress this parser belongs to.
    int n_states;    // required, number of states available in the parser (TCAM rows).
    std::vector<P4iParserStateTransition> states;  // required, Array of state resource utilization.
    P4iPhase0 phase0;

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("parser_id", new Util::JsonValue(parser_id));
        rst->emplace("gress", new Util::JsonValue(gress));
        rst->emplace("nStates", new Util::JsonValue(n_states));
        rst->emplace("states", toJsonArray(states));
        if (gress == "ingress")
            rst->emplace("phase0", phase0.toJson());
        return rst;
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_P4I_P4I_JSON_TYPES_H_ */
