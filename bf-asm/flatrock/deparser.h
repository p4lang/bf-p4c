#ifndef FLATROCK_DEPARSER_H_
#define FLATROCK_DEPARSER_H_

#include "asm-types.h"
#include "target.h"
#include "parde.h"
#include <boost/optional.hpp>

/**
 * Packet body offset
 *
 * Indicates where the payload starts within a packet relative to a given header
 */
struct PacketBodyOffset {
    int lineno;
    int hdr;
    int offset;
    int var_start;
    int var_len;

    void input(value_t data);
};

/**
 * Remaining bridge metadata configuration
 */
struct RemainingBridgeMetadataConfig {
    int lineno = -1;
    boost::optional<int> id;
    match_t match;
    int start;
    std::array<boost::optional<int>, Target::Flatrock::PARSER_BRIDGE_MD_WIDTH> bytes;

    void input_item(VECTOR(value_t) args, value_t data, int &bytes_index);
    void input_bytes(VECTOR(value_t) args, value_t key, value_t value);
    void input(VECTOR(value_t) args, value_t data);

    void write_config(Target::Flatrock::deparser_regs &regs);
};

/**
 * Remaining bridge metadata
 */
struct RemainingBridgeMetadata {
    int lineno = -1;
    PovSelect pov_select;
    std::array<RemainingBridgeMetadataConfig,
                Target::Flatrock::PARSER_BRIDGE_MD_CONFIGS> configs;

    void input_config(VECTOR(value_t) args, value_t key, value_t value);
    void input(VECTOR(value_t) args, value_t data);

    void write_config(Target::Flatrock::deparser_regs &regs);
};

#endif  // FLATROCK_DEPARSER_H_
