#ifndef BF_ASM_FLATROCK_PARSER_H_
#define BF_ASM_FLATROCK_PARSER_H_

#include "../parser.h"
#include <boost/optional.hpp>
#include "flatrock/pseudo_parser.h"
#include "asm-types.h"
#include "vector.h"
#include "target.h"

void check_range_state_subfield(value_t msb, value_t lsb, bool only8b = false);

class FlatrockParser : public BaseParser, virtual public Parsable {
    bool states_init = false;
    std::map<std::string, match_t> states;  // state name -> state mask
    const match_t &_state_mask(int lineno, std::string name) const {
        if (!states_init)
            error(lineno, "parser ingress -> states has not been initialized; "
                          "only state masks can be used until initialization");
        if (states.count(name) == 0)
            error(lineno, "undefined state: %s", name.c_str());
        return states.at(name);
    }

 public:
    struct PortMetadataItem : virtual public Parsable, virtual public Configurable {
        int lineno = -1;
        boost::optional<int> port;
        unsigned char data[Target::Flatrock::PARSER_PORT_METADATA_WIDTH];

        void input(VECTOR(value_t) args, value_t data) override;
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;
    } port_metadata[Target::Flatrock::PARSER_PORT_METADATA_ITEMS];

    struct alu_instruction : virtual public Parsable {
        virtual uint32_t build_opcode() = 0;
    };

    struct alu0_instruction : public alu_instruction {
        enum opcode_enum { INVALID = 99, OPCODE_0_NOOP = 10, OPCODE_0 = 0, OPCODE_1 = 1,
            OPCODE_2 = 2, OPCODE_3 = 3, OPCODE_4 = 4, OPCODE_5 = 5, OPCODE_6 = 6 } opcode;
        union {
            struct {} opcode_0_noop;  // ptr += 0

            struct {
                int add_imm8s;
            } opcode_0_1;
            // opcode 0: ptr += imm8s
            // opcode 1: ptr += w2[7:0] + imm8s

            struct {
                int state_msb;
                int state_lsb;
            } opcode_2_3;
            // opcode 2: ptr += state[MSB:LSB], MSB&LSB -> 2/4/8/16-bit state sub-field
            // opcode 3: ptr += (state[MSB:LSB] << 2), MSB&LSB -> 2/4/8/16-bit state sub-field

            struct {
                int mask_imm8u;
                int shift_imm2u;
                int add_imm2u;
            } opcode_4_5_6;
            // opcode 4: ptr += ((w2[7:0] & imm8u) << imm2u) + (imm2u << 2)
            // opcode 5: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
            // opcode 6: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
            //           if ((w2[7:0] & imm8u) >> imm2u) != 0,
            //           then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        };

        alu0_instruction() : opcode(INVALID) {}

        uint32_t build_opcode() override;
        void input(VECTOR(value_t) args, value_t data) override;
    };

    struct alu1_instruction : public alu_instruction {
        enum opcode_enum { INVALID = 99, OPCODE_0 = 0, OPCODE_1 = 1, OPCODE_2 = 2,
            OPCODE_3 = 3, OPCODE_4 = 4, OPCODE_5 = 5, OPCODE_6 = 6, OPCODE_7 = 7} opcode;
        union {
            struct {
                int state_msb;
                int state_lsb;
                int shift_imm4u;
            } opcode_0_1;
            // opcode 0: state[MSB:LSB] >>= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field
            // opcode 1: state[MSB:LSB] <<= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field

            struct {
                int state_msb;
                int state_lsb;
                int add_set_imm8s;
            } opcode_2_3;
            // opcode 2: state[MSB:LSB] += imm8s, MSB&LSB -> 2/4/8/16-bit state sub-field
            // opocde 3: state[MSB:LSB] = imm8s, MSB&LSB -> 2/4/8/16-bit state sub-field

            struct {
                int state_msb;
                int state_lsb;
                int mask_mode;
                int mask_imm4u;
                int shift_dir;
                int shift_imm2u;
                int add_imm2u;
            } opcode_4_5_6_7;
            // opcode 4:
            //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & imm4u) << imm2u) + (imm2u << 2)
            //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & imm4u) >> imm2u) + (imm2u << 2)
            // opcode 5:
            //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & imm4u) << imm2u) + (imm2u << 2)
            //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & imm4u) >> imm2u) + (imm2u << 2)
            // opcode 6:
            //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & imm4u) << imm2u) + (imm2u << 2)
            //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & imm4u) >> imm2u) + (imm2u << 2)
            //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
            // opcode 7:
            //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & imm4u) << imm2u) + (imm2u << 2)
            //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & imm4u) >> imm2u) + (imm2u << 2)
            //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
            // MSB&LSB -> 8-bit state sub-field
        };

        alu1_instruction() : opcode(INVALID) {}

        uint32_t build_opcode() override;
        void input(VECTOR(value_t) args, value_t data) override;
    };

    struct metadata_select {
        enum { INVALID, CONSTANT, LOGICAL_PORT_NUMBER, PORT_METADATA,
               INBAND_METADATA, TIMESTAMP, COUNTER } type = INVALID;
        union {
            struct {
                int value;
            } constant;

            struct {} logical_port_number;

            struct {
                int index;
            } port_metadata;

            struct {
                int index;
            } inband_metadata;

            struct {
                int index;
            } timestamp;

            struct {
                int index;
            } counter;
        };
    };

    struct Profile : virtual public Parsable, virtual public Configurable {
        int lineno = -1;
        boost::optional<int> id;  // If not set, the profile is not specified
        struct Match {
            match_t port;
            match_t inband_metadata;
        } match;
        int initial_pktlen;
        int initial_seglen;
        unsigned char initial_state[Target::Flatrock::PARSER_INITIAL_STATE_WIDTH];
        unsigned char initial_flags[Target::Flatrock::PARSER_FLAGS_WIDTH];
        int initial_ptr;
        int initial_w0_offset;
        int initial_w1_offset;
        int initial_w2_offset;
        struct alu0_instruction initial_alu0_instruction;
        struct alu1_instruction initial_alu1_instruction;
        struct metadata_select metadata_select[Target::Flatrock::PARSER_PROFILE_MD_SEL_NUM];

        void input_match(VECTOR(value_t) args, value_t key, value_t value);
        void input_alu0_instruction(VECTOR(value_t) args, value_t key, value_t value);
        void input_alu1_instruction(VECTOR(value_t) args, value_t key, value_t value);
        void input_metadata_select(VECTOR(value_t) args, value_t key, value_t value);

        void input(VECTOR(value_t) args, value_t data) override;
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;

        const FlatrockParser *parser = nullptr;
    } profiles[Target::Flatrock::PARSER_PROFILES];

    struct AnalyzerStage : virtual public Parsable, virtual public Configurable {
        int lineno = -1;
        boost::optional<int> stage;  // If not set, the analyzer stage is not specified
        boost::optional<std::string> name;
        struct Rule {
            struct Match {
                match_t state;
                match_t w1;
                match_t w0;
            } match;
        } rules[Target::Flatrock::PARSER_ANALYZER_STAGE_RULES];

        void input(VECTOR(value_t) args, value_t data) override;
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;

        const FlatrockParser *parser = nullptr;
    } analyzer[Target::Flatrock::PARSER_ANALYZER_STAGES];

    struct PhvBuilderGroup : virtual public Parsable, virtual public Configurable {
        int lineno = -1;
        int id = -1;
        int pov_select[Target::Flatrock::PARSER_PHV_BUILDER_GROUP_POV_SELECT_NUM];
        struct Extract {
            match_t match_pov;
            // TODO source
        } extracts[Target::Flatrock::PARSER_PHV_BUILDER_GROUP_POV_SELECT_NUM];

        void input(VECTOR(value_t) args, value_t data) override;
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;
    } phv_builder[Target::Flatrock::PARSER_PHV_BUILDER_GROUPS];

    void input_states(VECTOR(value_t) args, value_t key, value_t value);
    void input_port_metadata(VECTOR(value_t) args, value_t key, value_t value);
    void input_profile(VECTOR(value_t) args, value_t key, value_t value);
    void input_analyzer_stage(VECTOR(value_t) args, value_t key, value_t value);
    void input_phv_builder_group(VECTOR(value_t) args, value_t key, value_t value);

    void input(VECTOR(value_t) args, value_t data) override;
    void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;
    void output(json::map &) override;

    const match_t state(value_t name) const {
        return _state_mask(name.lineno, name.s);
    }

    FlatrockParser() {
        for (int i = 0; i < Target::Flatrock::PARSER_PROFILES; i++)
            profiles[i].parser = this;
        for (int i = 0; i < Target::Flatrock::PARSER_ANALYZER_STAGES; i++)
            analyzer[i].parser = this;
    }
};

class FlatrockAsmParser : public BaseAsmParser {
    void start(int lineno, VECTOR(value_t) args) override;
    void input(VECTOR(value_t) args, value_t data) override;
    void output(json::map &) override;

 public:
    FlatrockParser parser;
    FlatrockPseudoParser pseudo_parser;

    FlatrockAsmParser() : BaseAsmParser("parser") {}
};

#endif  // BF_ASM_FLATROCK_PARSER_H_
