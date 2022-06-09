#ifndef BF_ASM_FLATROCK_PARSER_H_
#define BF_ASM_FLATROCK_PARSER_H_

#include <boost/optional.hpp>
#include "bf-p4c/common/flatrock_parser.h"
#include "../parser.h"
#include "asm-types.h"
#include "flatrock/pseudo_parser.h"
#include "target.h"
#include "vector.h"

bool check_range_state_subfield(value_t msb, value_t lsb, bool only8b = false);

class FlatrockParser : public BaseParser, virtual public Parsable {
    bool states_init = false;
    std::map<std::string, match_t> states;  // state name -> state mask
    const match_t *_state_mask(int lineno, std::string name) const {
        if (!states_init) {
            error(lineno, "parser ingress -> states has not been initialized; "
                          "only state masks can be used until initialization");
            return nullptr;
        }
        if (states.count(name) == 0) {
            error(lineno, "undefined state: %s", name.c_str());
            return nullptr;
        }
        return &states.at(name);
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
        virtual uint32_t build_opcode() const = 0;
        virtual bool is_invalid() const = 0;
    };

    struct alu0_instruction : public alu_instruction, public Flatrock::alu0_instruction {
        uint32_t build_opcode() const override;
        void input(VECTOR(value_t) args, value_t data) override;
        bool is_invalid() const override {
            return opcode == Flatrock::alu0_instruction::INVALID;
        }
    };

    struct alu1_instruction : public alu_instruction, public Flatrock::alu1_instruction {
        uint32_t build_opcode() const override;
        void input(VECTOR(value_t) args, value_t data) override;
        bool is_invalid() const override {
            return opcode == Flatrock::alu1_instruction::INVALID;
        }
    };

    /**
     * @brief State bit vector of the parser (profile, analyzer)
     *
     * The state vector keeps 80 bits of the state and 80 bits of the mask. Zero bit
     * of the mask means passing bit from the upper stage through. One outputs
     * the appropriate state bit.
     */
    class ParserStateVector {
     private:
        uint8_t value[Target::Flatrock::PARSER_STATE_WIDTH];
        uint8_t mask[Target::Flatrock::PARSER_STATE_WIDTH];

     public:
        /**
         * @brief Ctor - all bits are zero, the mask passes all bits through.
         */
        ParserStateVector();

        /**
         * @brief Ctor
         *
         * @param match The matching constant. The wildcarded bits are zeroed in the state
         * and the mask passes such bits through. Bits above 64 bits are zeroed and passed
         * through.
         */
        explicit ParserStateVector(match_t match);

        /**
         * @brief Ctor
         *
         * As well as other constructors, the wildcard bits are zeroed and the mask
         * is set to pass them through.
         *
         * @param hi Hi 2 bytes of the state vector and the mask
         * @param lo Low 8 bytes of the state vector and the mask
         */
        explicit ParserStateVector(match_t hi, match_t lo);

        /* -- default copying and moving is wanted here */

        /**
         * @brief Parse parser value to the state vector
         *
         * @param[out] target The output state vector
         * @param[in] value The parser value
         * @return True if the state vector is successfully parsed. False if an error happens.
         * @note The strong guarantee
         */
        static bool parse_state_vector(ParserStateVector &target, value_t value);

        /**
         * @brief Make all bits valid (set all bits)
         */
        void forceSetMask();

        /**
         * @brief Write the state value into Flatrock registers
         */
        void writeValue(ubits<16> &hi, ubits<32> &mid, ubits<32> &lo) const;

        /**
         * @brief Write the state mask into Flatrock registers
         */
        void writeMask(ubits<16> &hi, ubits<32> &mid, ubits<32> &lo) const;

     private:
        static bool input_state_value(uint8_t target[Target::Flatrock::PARSER_STATE_WIDTH * 8],
                                      const value_t value);
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
        ParserStateVector initial_state;
        unsigned char initial_flags[Target::Flatrock::PARSER_FLAGS_WIDTH];
        int initial_ptr;
        int initial_w0_offset;
        int initial_w1_offset;
        int initial_w2_offset;
        struct alu0_instruction initial_alu0_instruction;
        struct alu1_instruction initial_alu1_instruction;
        Flatrock::metadata_select metadata_select[Target::Flatrock::PARSER_PROFILE_MD_SEL_NUM];

        void input_match(VECTOR(value_t) args, value_t key, value_t value);
        void input_metadata_select(VECTOR(value_t) args, value_t key, value_t value);

        void input(VECTOR(value_t) args, value_t data) override;
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;

        const FlatrockParser *parser = nullptr;
    } profiles[Target::Flatrock::PARSER_PROFILES];

    class AnalyzerStage {
     private:
        boost::optional<int> stage;  // If not set, the analyzer stage is not specified
        boost::optional<value_t> name;
        struct Rule {
            struct Match {
                match_t state = {0, 0};
                match_t w1 = {0, 0};
                match_t w0 = {0, 0};
            } match;

            ParserStateVector next_state;
            bool next_skip_extraction = false;
            int next_w0_offset = 0;
            int next_w1_offset = 0;
            int next_w2_offset = 0;
            struct alu0_instruction next_alu0_instruction;
            struct alu1_instruction next_alu1_instruction;
            struct PushHdrId {
                uint8_t hdr_id = 0xff;
                uint8_t offset = 0;
            };
            boost::optional<PushHdrId> push_hdr_id;
        } rules[Target::Flatrock::PARSER_ANALYZER_STAGE_RULES];

        const FlatrockParser *parser = nullptr;
        friend class FlatrockParser;

     public:
        void input(VECTOR(value_t) args, int stage_, boost::optional<value_t> name_, value_t data);
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false);

     private:
        void input_rule(VECTOR(value_t) args, value_t key, value_t data);
        bool input_push_hdr(Rule& rule, value_t value);
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

    match_t state(value_t name) const;
    bool get_state_match(match_t &state_match, value_t name) const;

    FlatrockParser() {
        for (int i = 0; i < Target::Flatrock::PARSER_PROFILES; i++)
            profiles[i].parser = this;
        for (int i = 0; i < Target::Flatrock::PARSER_ANALYZER_STAGES; i++)
            analyzer[i].parser = this;
    }
};

class FlatrockAsmParser : public BaseAsmParser {
 public:
    /* -- These members are public just because wrongly written tests.
     *    Never access them directly in the production code. */
    FlatrockParser parser;
    FlatrockPseudoParser pseudo_parser;

 private:
    /* -- The parser_regs structure is registered into a singleton
     *    in the ubits class. Hence, it's not possible to keep
     *    separated structure in the parser and in the pseudo-parser */
    Target::Flatrock::parser_regs cfg_registers;

 public:
    FlatrockAsmParser();
    ~FlatrockAsmParser();

    /**
     * @brief Get the configuration registers
     *
     * This method returns read-only reference to the configuration
     * registers constructed by the output() method.
     */
    const Target::Flatrock::parser_regs &get_cfg_registers() const;

    void start(int lineno, VECTOR(value_t) args) override;
    void input(VECTOR(value_t) args, value_t data) override;
    void output(json::map &) override;
};

#endif  // BF_ASM_FLATROCK_PARSER_H_
