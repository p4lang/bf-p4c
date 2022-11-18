#ifndef BF_ASM_FLATROCK_PARSER_H_
#define BF_ASM_FLATROCK_PARSER_H_

#include <boost/optional.hpp>
#include "bf-p4c/common/flatrock.h"
#include "../parser.h"
#include "asm-types.h"
#include "target.h"
#include "vector.h"

bool check_range_state_subfield(value_t msb, value_t lsb, bool only8b = false);

struct PovSelect {
    struct PovSelectKey {
        enum { FLAGS = 0, STATE = 1} src = FLAGS;
        uint8_t start = 0;
        bool used = false;
    } key[Target::Flatrock::PARSER_POV_SELECT_NUM];

    bool input(value_t data);
    bool check_match(const match_t match) const;
};

struct InitialPredicationVector : virtual public Parsable, virtual public Configurable {
    struct NextTblConfig {
        match_t key;
        uint8_t next_tbl;
    };

    gress_t gress;
    PovSelect pov_select;
    NextTblConfig next_tbl_config[Target::Flatrock::PARSER_PRED_VEC_TCAM_DEPTH];

    void input(VECTOR(value_t) args, value_t data) override;
    void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;
    void write_config_parser(Target::Flatrock::parser_regs &, json::map &json) const;
    void write_config_pseudo_parser(Target::Flatrock::parser_regs &, json::map &json) const;
 private:
    bool input_mappings(const value_t &v);
};

class PhvBuilderGroup {
    boost::optional<int> group_id;  // If not set, the PHV builder group is not specified.
    gress_t gress; /* -- INGRESS: parser, EGRESS: pseudo parser */
    PovSelect pov_select;

    enum phe_source_valid {
        BOTH, PARSER, PSEUDO_PARSER
    };
    enum other_subtype {
        NONE, CONSTANT, POV_FLAGS, POV_STATE, CHKSUM_ERROR,
        UDF0, UDF1, UDF2, UDF3, GHOST, TM, BRIDGE,
    };
    struct OtherInputConfig {
        int max;
        enum phe_source_valid where_valid;
        enum other_subtype subtype;
    };

    struct OtherWriteConfig {
        uint8_t subtype_value;
        uint8_t fixed_val;
        uint8_t var_width;
    };

    struct PheSourcePacket8 {
        uint8_t hdr_id;
        uint8_t offset[Target::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES];
    };
    struct PheSourcePacket16 {
        uint8_t hdr_id;
        uint8_t offset[Target::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES];
        bool swap[Target::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES];
    };
    struct PheSourcePacket32 {
        uint8_t hdr_id;
        uint8_t offset;
        enum {NO_REVERSE, REVERSE, REVERSE_16B_WORDS} reverse;
    };
    struct PheSourceOther{
        enum other_subtype subtype;
        uint8_t value;
    };

    struct Extract {
        boost::optional<int> extract_id;
        match_t match_pov = {0, 0};
        struct PheSource {
            enum phe_source_type {
                INVALID, PACKET8_SOURCE, PACKET16_SOURCE, PACKET32_SOURCE, OTHER_SOURCE
            } type = INVALID;
            union {
                PheSourcePacket8 packet8;
                PheSourcePacket16 packet16;
                PheSourcePacket32 packet32;
                PheSourceOther other[Target::Flatrock::PARSER_PHV_BUILDER_OTHER_PHE_SOURCES];
            };
        };
        PheSource phe_source[Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES];
    } extracts[Target::Flatrock::PARSER_PHV_BUILDER_GROUP_EXTRACTS_NUM];

    bool check_register(value_t reg_name, int phe_source_id, int slice_size,
            bitvec &used_regs, int &val_index);
    bool check_gress(OtherInputConfig &config, value_t value);
    bool input_extract(VECTOR(value_t) args, value_t key, value_t data);
    bool input_phe_source_pair(VECTOR(value_t) args, Extract& extract, value_t data);
    bool input_other_phe_source(VECTOR(value_t) args, Extract::PheSource& phe_source,
            const int phe_source_id, value_t data);
    bool input_packet_phe_source(VECTOR(value_t) args, Extract::PheSource& phe_source,
            const int phe_source_id, value_t data);

 public:
    void input(VECTOR(value_t) args, const int lineno, const int group, value_t data);
    void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false);
};

/**
 * @brief Representation of the %Flatrock parser in assembler
 * @ingroup parde
 */
class FlatrockParser : public BaseParser, virtual public Parsable {
    /**
     * Have state names been initialized in the parser ingress -> states section?
     * If not, only state masks can be used in corresponsing elements.
     */
    bool states_init = false;
    /// Mapping of the state name to the corresponding state mask
    std::map<std::string, match_t> states;
    /**
     * Maps a state @p name to the corresponding state mask.
     * If not initialized so far, it reports an error.
     * @returns corresponding state mask.
     */
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
    /**
     * @brief Representation of a row of the %Flatrock parser port metadata table in assembler
     *
     * If @a port is not set, the row is unused.
     */
    struct PortMetadataItem : virtual public Parsable, virtual public Configurable {
        int lineno = -1;
        boost::optional<int> port;
        unsigned char data[Target::Flatrock::PARSER_PORT_METADATA_WIDTH];

        void input(VECTOR(value_t) args, value_t data) override;
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;
    } port_metadata[Target::Flatrock::PARSER_PORT_METADATA_ITEMS];
    ///< Port metadata table

    /// Base class for the %Flatrock parser ALU0 and ALU1 instructions
    struct alu_instruction : virtual public Parsable {
        virtual uint32_t build_opcode() const = 0;
        virtual bool is_invalid() const = 0;
    };

    /**
     * @brief The representation of the %Flatrock parser ALU0 instruction in assembler
     *
     * ALU0 updates the packet pointer.
     */
    struct alu0_instruction : public alu_instruction, public Flatrock::alu0_instruction {
        uint32_t build_opcode() const override;
        void input(VECTOR(value_t) args, value_t data) override;
        bool is_invalid() const override {
            return opcode == Flatrock::alu0_instruction::INVALID;
        }
    };

    /**
     * @brief The representation of the %Flatrock parser ALU1 instruction in assembler
     *
     * ALU1 updates the analyzer state field.
     */
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

    /**
     * @brief The representation of the %Flatrock parser profile in assembler
     *
     * If @a id is not set, the profile is unused.
     */
    struct Profile : virtual public Parsable, virtual public Configurable {
        int lineno = -1;
        boost::optional<int> id;
        struct Match {
            match_t port;
            match_t inband_metadata;
        } match;
        int initial_pktlen;  ///< Packet length adjustment value
        int initial_seglen;  ///< Segment length adjustment value
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
    ///< %Profile table

    /**
     * @brief The representation of the %Flatrock parser analyzer stage in assembler
     *
     * If @a stage is not set, the analyzer stage is unused.
     */
    class AnalyzerStage {
     private:
        boost::optional<int> stage;
        boost::optional<value_t> name;
        /**
         * @brief The representation of a rule in the %Flatrock parser analyzer stage in assembler
         */
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

            boost::optional<Flatrock::ModifyFlags<16>> modify_flags16;
            boost::optional<Flatrock::ModifyFlags<4>> modify_flags4;
            boost::optional<Flatrock::ModifyFlag> modify_flag0;
            boost::optional<Flatrock::ModifyFlag> modify_flag1;
            boost::optional<Flatrock::ModifyChecksum> modify_checksum;
            boost::optional<Flatrock::PushHdrId> push_hdr_id;
        } rules[Target::Flatrock::PARSER_ANALYZER_STAGE_RULES];
        ///< Rules within a single analyzer stage

        const FlatrockParser *parser = nullptr;
        friend class FlatrockParser;

     public:
        void input(VECTOR(value_t) args, int stage_, boost::optional<value_t> name_, value_t data);
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false);

     private:
        void input_rule(VECTOR(value_t) args, value_t key, value_t data);
        bool input_push_hdr(Rule &rule, value_t value);
        template <uint8_t width>
        boost::optional<Flatrock::ModifyFlags<width>> load_modify_flags(Rule &rule, value_t value);
        boost::optional<Flatrock::ModifyFlag> load_modify_flag(Rule &rule, value_t value);
        bool input_modify_checksum(Rule &rule, value_t value);
    } analyzer[Target::Flatrock::PARSER_ANALYZER_STAGES];  ///< Analyzer

    PhvBuilderGroup phv_builder[Target::Flatrock::PARSER_PHV_BUILDER_GROUPS];  ///< %PHV builder

    // Two IPVs, one for the normal thread, one for the ghost thread
    InitialPredicationVector initial_predication_vector[2];

    struct ChecksumCheckers : virtual public Parsable, virtual public Configurable {
        int lineno = -1;

        struct Mask {
            uint32_t words[Target::Flatrock::PARSER_CSUM_MASK_WIDTH];
            bool used = false;
            int lineno = -1;
        } masks[Target::Flatrock::PARSER_CSUM_MASKS];

        struct Config {
            match_t match_pov;
            uint8_t mask_sel;
            uint8_t hdr_id;
            bool used = false;
            int lineno = -1;
        };

        struct Unit {
            PovSelect pov_select;
            Config configs[Target::Flatrock::PARSER_PROFILES];
            bool used = false;
            int lineno = -1;
        } units[Target::Flatrock::PARSER_CHECKSUM_UNITS];

        void input_unit(std::size_t id, value_t &data);
        void input_config(std::size_t unit_id, std::size_t id, value_t &data);
        void input_mask(std::size_t id, value_t &data);

        void write_unit(std::size_t id, Target::Flatrock::parser_regs &regs);
        void write_pov_select(std::size_t unit_id, Target::Flatrock::parser_regs &regs);
        void write_config(std::size_t unit_id, std::size_t id, Target::Flatrock::parser_regs &regs);
        void write_mask(std::size_t id, Target::Flatrock::parser_regs &regs);

        void validate();

        void input(VECTOR(value_t) args, value_t data) override;
        void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;
    } csum_checkers;

    void input_states(VECTOR(value_t) args, value_t key, value_t value);
    void input_port_metadata(VECTOR(value_t) args, value_t key, value_t value);
    void input_profile(VECTOR(value_t) args, value_t key, value_t value);
    void input_analyzer_stage(VECTOR(value_t) args, value_t key, value_t value);
    void input_initial_predication_vector(VECTOR(value_t) args, value_t key, value_t value);
    void input_checksum_checkers(VECTOR(value_t) args, value_t key, value_t value);

    void input(VECTOR(value_t) args, value_t data) override;
    void write_config(RegisterSetBase &regs, json::map &json, bool legacy = false) override;

    match_t state(value_t name) const;
    bool get_state_match(match_t &state_match, value_t name) const;

    FlatrockParser() {
        for (int i = 0; i < Target::Flatrock::PARSER_PROFILES; i++)
            profiles[i].parser = this;
        for (int i = 0; i < Target::Flatrock::PARSER_ANALYZER_STAGES; i++)
            analyzer[i].parser = this;

        initial_predication_vector[0].gress = INGRESS;
        initial_predication_vector[1].gress = GHOST;
    }
};

/**
 * @brief Representation of the %Flatrock pseudo parser in assembler
 * @ingroup parde
 */
class FlatrockPseudoParser : virtual public Parsable, virtual public Configurable {
 public:
    int pov_flags_pos = -1;
    int pov_state_pos = -1;
    PhvBuilderGroup phv_builder[Target::Flatrock::PARSER_PHV_BUILDER_GROUPS];  ///< %PHV builder
    InitialPredicationVector initial_predication_vector;

    void input(VECTOR(value_t) args, value_t data) override;
    void write_hdr_config(Target::Flatrock::parser_regs &regs);
    void write_config(RegisterSetBase &regs, json::map &json, bool legacy = true) override;

    FlatrockPseudoParser() {
        initial_predication_vector.gress = EGRESS;
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
