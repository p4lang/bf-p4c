#ifndef EXTENSIONS_BF_P4C_PARDE_P4I_P4I_JSON_TYPES_H_
#define EXTENSIONS_BF_P4C_PARDE_P4I_P4I_JSON_TYPES_H_

#include <boost/optional.hpp>
#include <vector>

#include "lib/cstring.h"
#include "lib/json.h"

struct ToJsonObject {
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

struct P4iParserMatchOn : ToJsonObject {
    int hardware_id;                     // required, Register ID being matched on.
    int bit_width;                       // required, Size of the register.
    boost::optional<cstring> value_set;  // Parser value set name matched on.
    boost::optional<int> value;          // Value matched on.
    boost::optional<int> mask;           // Value or value set mask.
    // Offset in the input buffer to load for the next parse cycle
    boost::optional<int> buffer_offset;

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("hardware_id", new Util::JsonValue(hardware_id));
        rst->emplace("bit_width", new Util::JsonValue(bit_width));
        if (value_set) {
            rst->emplace("value_set", new Util::JsonValue(*value_set)); }
        if (value) {
            rst->emplace("value", new Util::JsonValue(*value)); }
        if (mask) {
            rst->emplace("mask", new Util::JsonValue(*mask)); }
        if (buffer_offset) {
            rst->emplace("buffer_offset", new Util::JsonValue(*buffer_offset)); }
        return rst;
    }
};

struct P4iParserState : ToJsonObject {
    int state_id;  // required, enum=range(0,256), Unique state identifier.
    int tcam_row;  // required, enum=range(0, 256), Parser TCAM row.
    int shifts;    // required, enum=range(0,33), Number of bytes shifted in the buffer.
    std::vector<P4iParserExtract> extracts;   // required, List of extractors in use.
    std::vector<P4iParserMatchOn> matchesOn;  // required, List of matches in use.
    bool has_counter;    // required, True if the state uses a counter.
    cstring state_name;  // required, Name of the state in this row.
    int previous_state_id = 0;   // required, The id of the previous state for this transition.
    cstring previous_state_name;  // optional

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("state_id", new Util::JsonValue(state_id));
        rst->emplace("tcam_row", new Util::JsonValue(tcam_row));
        rst->emplace("shifts", new Util::JsonValue(shifts));
        rst->emplace("extracts", toJsonArray(extracts));
        rst->emplace("matchesOn", toJsonArray(matchesOn));
        rst->emplace("has_counter", new Util::JsonValue(has_counter));
        rst->emplace("state_name", new Util::JsonValue(state_name));
        rst->emplace("previous_state_id", new Util::JsonValue(previous_state_id));
        rst->emplace("previous_state_name", new Util::JsonValue(previous_state_name));
        return rst;
    }
};

struct P4iParser : ToJsonObject {
    int parser_id;  // required, enum=range(0, 18), Parser ID
    cstring gress;  // required, enum=["ingress", "egress"], The gress this parser belongs to.
    int n_states;    // required, number of states available in the parser (TCAM rows).
    std::vector<P4iParserState> states;  // required, Array of state resource utilization.

    Util::JsonObject* toJson() const override {
        auto* rst = new Util::JsonObject();
        rst->emplace("parser_id", new Util::JsonValue(parser_id));
        rst->emplace("gress", new Util::JsonValue(gress));
        rst->emplace("nStates", new Util::JsonValue(n_states));
        rst->emplace("states", toJsonArray(states));
        return rst;
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_P4I_P4I_JSON_TYPES_H_ */
