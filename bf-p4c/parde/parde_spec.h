#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_

#include <map>
#include <vector>

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/match_register.h"
#include "bf-p4c/bf-p4c-options.h"

/**
 * \defgroup parde Parser & deparser
 * \brief Content related to parser and deparser
 *
 * # General information
 *
 * There are some basic visitors defined for parde:
 * - PardeInspector
 * - PardeModifier
 * - PardeTransform
 * - ParserInspector
 * - ParserModifier
 * - ParserTransform
 * - DeparserInspector
 * - DeparserModifier
 * - DeparserTransform
 *
 * The assembler representations for parde:
 * - Deparser
 * - BaseAsmParser
 *
 * The parde can also be affected at the beginning of \ref midend by architecture translation,
 * see \ref ArchTranslation for more information.
 *
 * # Parser
 *
 * In frontend and midend, the IR::P4Parser %IR node is used to represent a parser.
 * During architecture translation, i.e. within the BFN::ArchTranslation midend pass,
 * the Tofino parser becomes represented with the IR::BFN::TnaParser %IR node.
 *
 * In backend, after transformation within the BFN::BackendConverter post-midend pass,
 * the Tofino parser is represented with the IR::BFN::Parser %IR node.
 * Within the LowerParser pass, the parser is transformed (lowered) into the representation
 * that is closer to how HW works. For Tofino 1/2/3, IR::BFN::LoweredParser is produced,
 * while for %Flatrock, IR::Flatrock::Parser and IR::Flatrock::PseudoParser are produced.
 *
 * In assembler, the Tofino 1/2/3 parser is represented with the Parser class,
 * while %Flatrock is represented with the FlatrockParser class.
 * Specific differences of Tofino 1 vs 2 vs 3 are implemented using template specialization.
 *
 * # Deparser
 *
 * The deparser reassembles packets prior to storage in TM (Tofino 1-3) and prior to transmission
 * via the MAC (all chips).
 *
 * ## Target constants
 *
 * Tofino1:
 * - Target::Tofino::DEPARSER_CHECKSUM_UNITS = 6
 * - Target::Tofino::DEPARSER_CONSTANTS = 0
 * - Target::Tofino::DEPARSER_MAX_POV_BYTES = 32
 * - Target::Tofino::DEPARSER_MAX_POV_PER_USE = 1
 * - Target::Tofino::DEPARSER_MAX_FD_ENTRIES = 192
 *
 * Tofino2:
 * - Target::JBay::DEPARSER_CHECKSUM_UNITS = 8
 * - Target::JBay::DEPARSER_CONSTANTS = 8
 * - Target::JBay::DEPARSER_MAX_POV_BYTES = 16
 * - Target::JBay::DEPARSER_MAX_POV_PER_USE = 1
 * - Target::JBay::DEPARSER_CHUNKS_PER_GROUP = 8
 * - Target::JBay::DEPARSER_CHUNK_SIZE = 8
 * - Target::JBay::DEPARSER_CHUNK_GROUPS = 16
 * - Target::JBay::DEPARSER_CLOTS_PER_GROUP = 4
 * - Target::JBay::DEPARSER_TOTAL_CHUNKS = DEPARSER_CHUNK_GROUPS * DEPARSER_CHUNKS_PER_GROUP = 128
 * - Target::JBay::DEPARSER_MAX_FD_ENTRIES = DEPARSER_TOTAL_CHUNKS = 128
 *
 * Tofino3:
 * - Target::Cloudbreak::DEPARSER_CHECKSUM_UNITS = 8
 * - Target::Cloudbreak::DEPARSER_CONSTANTS = 8
 * - Target::Cloudbreak::DEPARSER_MAX_POV_BYTES = 16
 * - Target::Cloudbreak::DEPARSER_MAX_POV_PER_USE =  1
 * - Target::Cloudbreak::DEPARSER_CHUNKS_PER_GROUP = 8
 * - Target::Cloudbreak::DEPARSER_CHUNK_SIZE = 8
 * - Target::Cloudbreak::DEPARSER_CHUNK_GROUPS = 16
 * - Target::Cloudbreak::DEPARSER_CLOTS_PER_GROUP = 4
 * - Target::Cloudbreak::DEPARSER_TOTAL_CHUNKS = DEPARSER_CHUNK_GROUPS * DEPARSER_CHUNKS_PER_GROUP
 *                                             = 128
 * - Target::Cloudbreak::DEPARSER_MAX_FD_ENTRIES = DEPARSER_TOTAL_CHUNKS = 128
 *
 * ## Midend passes
 *
 * Midend passes related to deparsing:
 *  - BFN::CheckHeaderAlignment (in BFN::PadFlexibleField) - Ensures that headers are byte aligned.
 *  - \ref DesugarVarbitExtract - Generates emit statements for variable-length headers.
 *  - BFN::ParserEnforceDepthReq - Adds emit statements for padding headers to ensure the minimum
 *                                 parse depth.
 *  - \ref SimplifyNestedIf - Simplifies nested if statements into simple if statements that the
 *                           deparser can process.
 *
 * ## Backend passes
 *
 * Backend passes related to deparsing:
 *  - AddDeparserMetadata - Adds deparser metadata parameters.
 *  - AddMetadataPOV - Adds POV bits for metadata used by the deparser (Tofino 2/3/5). Tofino 1
 *                     uses the valid bit associated with each %PHV; Tofino 2+ use POV bits
 *                     instead. Tofino 5 requires POV bits for only a subset of metadata.
 *  - BFN::AsmOutput - Outputs the deparser assembler. Uses DeparserAsmOutput and the passes it
 *                     invokes.
 *  - CollectClotInfo - Collects information for generating CLOTs.
 *  - \ref DeparserCopyOpt - Optimize copy assigned fields prior to deparsing.
 *  - \ref ExtractChecksum - Replaces EmitField with EmitChecksum emits in deparser. Also
 *                           creates tables and optimizes conditions and fields that the
 *                           checksum uses. Invoked from BFN::BackendConverter.
 *  - BFN::ExtractDeparser - Convert IR::BFN::TnaDeparser objects to IR::BFN::Deparser objects. The
 *                           pass generates emit and digest objects as part of this process.
 *  - GreedyClotAllocator - CLOT allocation. Enforces deparser CLOT rules during allocation.
 *  - InsertParserClotChecksums - Identifies CLOT fields used in deparser checksums to allow the
 *                                checksum to be calculated in the parser (Tofino 2/3).
 *  - LowerParser - Replaces high-level parser and deparser %IR that operate on fields with
 *                  low-level parser and deparser %IR that operate on %PHV containers.
 *  - \ref ResetInvalidatedChecksumHeaders - Reset fields that are used in deparser checksum
 *                                           operations and that are invalidated in the MAU
 *                                           (Tofino 1).
 */

class PardeSpec {
 public:
    /// @return the size in bytes of the ingress intrinsic metadata header
    /// WARNING this should match "ingress_intrinsic_metadata_t" in tofino.p4
    size_t byteIngressIntrinsicMetadataSize() const { return 8; }

    /// @return the size in bytes of the ingress static per-port metadata on
    /// this device. (This is the "phase 0" data.) On resubmitted packets, the
    /// same region is used for resubmit metadata.
    virtual size_t bytePhase0Size() const = 0;
    size_t bitPhase0Size() const { return bytePhase0Size() * 8; }

    /// @return the size in bits or bytes of the reserved resubmit tag on this device.
    size_t bitResubmitTagSize() const { return 8; }
    size_t byteResubmitTagSize() const { return 1; }

    /// @return the size in bits or bytes of the resubmit data on this device.
    size_t bitResubmitSize() const { return bitPhase0Size(); }
    size_t byteResubmitSize() const { return bytePhase0Size(); }

    /// @return the size in bytes of the padding between the ingress static
    /// per-port metadata and the beginning of the packet.
    virtual size_t byteIngressPrePacketPaddingSize() const = 0;
    size_t bitIngressPrePacketPaddingSize() const {
        return byteIngressPrePacketPaddingSize() * 8;
    }

    /// @return the total size of all ingress metadata on this device.
    size_t byteTotalIngressMetadataSize() const {
        return byteIngressIntrinsicMetadataSize() +
               bytePhase0Size() +
               byteIngressPrePacketPaddingSize();
    }

    /// The size of input buffer, in bytes.
    int byteInputBufferSize() const { return 32; }

    /// The region of the input buffer that contains special intrinsic
    /// metadata rather than packet data. In bytes.
    nw_byterange byteInputBufferMetadataRange() const {
        return StartLen(32, 32);
    }

    /// Specifies the available kinds of extractors, specified as sizes in bits,
    /// and the number of extractors of each kind available in each hardware parser
    /// state.
    virtual const std::map<unsigned, unsigned>& extractorSpec() const = 0;

    /// Specifies the available match registers
    virtual const std::vector<MatchRegister> matchRegisters() const = 0;

    /// Specifies the available scracth registers
    virtual const std::vector<MatchRegister> scratchRegisters() const = 0;

    /// Total parsers supported ingress/egress
    virtual int numParsers() const = 0;

    /// Total TCAM Rows supported ingress/egress
    virtual int numTcamRows() const = 0;

    /// The maximum number of CLOTs that can be generated in each parser state.
    virtual unsigned maxClotsPerState() const = 0;

    /// The maximum number of bytes a CLOT can hold.
    virtual unsigned byteMaxClotSize() const = 0;

    /// The number of CLOTs available for allocation in each gress.
    virtual unsigned numClotsPerGress() const = 0;

    /// The maximum number of CLOTs that can be live for each packet in each gress.
    virtual unsigned maxClotsLivePerGress() const = 0;

    /// The minimum number of bytes required between consecutive CLOTs.
    virtual unsigned byteInterClotGap() const = 0;

    /// The maximum offset+length a CLOT can have, in bits.
    virtual unsigned bitMaxClotPos() const = 0;

    /// The minimum parse depth for the given gress
    virtual size_t minParseDepth(gress_t /*gress*/) const { return 0; }

    /// The maximum parse depth for the given gress
    virtual size_t maxParseDepth(gress_t /*gress*/) const { return SIZE_MAX; }

    // Number of deparser consant bytes available
    virtual unsigned numDeparserConstantBytes() const = 0;

    // Number deparser checksum units each gress can support
    virtual unsigned numDeparserChecksumUnits() const = 0;

    // Number of deparser checksum units that can invert its output
    virtual unsigned numDeparserInvertChecksumUnits() const = 0;

    /// Clock frequency
    virtual double clkFreq() const = 0;

    /// Max line rate per-port (Gbps)
    virtual unsigned lineRate() const = 0;

    /// Metadata packer valid vector fields - as vector (Flatrock)
    virtual const std::vector<std::string>& mdpValidVecFields() const = 0;

    /// Metadata packer valid vector fields - as set (Flatrock)
    virtual const std::unordered_set<std::string>& mdpValidVecFieldsSet() const = 0;
};

class TofinoPardeSpec : public PardeSpec {
 public:
    size_t bytePhase0Size() const override { return 8; }
    size_t byteIngressPrePacketPaddingSize() const override { return 0; }

    const std::map<unsigned, unsigned>& extractorSpec() const override {
        static const std::map<unsigned, unsigned> extractorSpec = {
            {8,  4},
            {16, 4},
            {32, 4}
        };
        return extractorSpec;
    }

    const std::vector<MatchRegister> matchRegisters() const override {
        static std::vector<MatchRegister> spec;

        if (spec.empty()) {
            spec = { MatchRegister("half"),
                     MatchRegister("byte0"),
                     MatchRegister("byte1") };
        }

        return spec;
    }

    const std::vector<MatchRegister> scratchRegisters() const override {
        return { };
    }

    int numParsers() const override { return 18; }
    int numTcamRows() const override { return 256; }

    unsigned maxClotsPerState() const override { BUG("No CLOTs in Tofino"); }
    unsigned byteMaxClotSize() const override { BUG("No CLOTs in Tofino"); }
    unsigned numClotsPerGress() const override { return 0; }

    unsigned maxClotsLivePerGress() const override {
        BUG("No CLOTs in Tofino");
    }

    unsigned byteInterClotGap() const override { BUG("No CLOTs in Tofino"); }

    unsigned bitMaxClotPos() const override { BUG("No CLOTs in Tofino"); }

    size_t minParseDepth(gress_t gress) const override { return gress == EGRESS ? 65 : 0; }

    size_t maxParseDepth(gress_t gress) const override { return gress == EGRESS ? 160 : SIZE_MAX; }

    unsigned numDeparserConstantBytes() const override { return 0; }
    unsigned numDeparserChecksumUnits() const override { return 6; }
    unsigned numDeparserInvertChecksumUnits() const override { return 0; }

    double clkFreq() const override { return 1.22; }
    unsigned lineRate() const override { return 100; }

    const std::vector<std::string>& mdpValidVecFields() const override {
        static std::vector<std::string> vldVecFields;
        return vldVecFields;
    }

    const std::unordered_set<std::string>& mdpValidVecFieldsSet() const override {
        static std::unordered_set<std::string> vldVecSet;
        return vldVecSet;
    }
};

class JBayPardeSpec : public PardeSpec {
 public:
    size_t bytePhase0Size() const override { return 16; }
    size_t byteIngressPrePacketPaddingSize() const override { return 8; }

    const std::map<unsigned, unsigned>& extractorSpec() const override {
        static const std::map<unsigned, unsigned> extractorSpec = {
            {16, 20}
        };
        return extractorSpec;
    }

    const std::vector<MatchRegister> matchRegisters() const override {
        static std::vector<MatchRegister> spec;

        if (spec.empty()) {
            spec = { MatchRegister("byte0"),
                     MatchRegister("byte1"),
                     MatchRegister("byte2"),
                     MatchRegister("byte3") };
        }

        return spec;
    }

    const std::vector<MatchRegister> scratchRegisters() const override {
        static std::vector<MatchRegister> spec;

        if (spec.empty()) {
            matchRegisters();  // make sure the match registers are created first

            spec = { MatchRegister("save_byte0"),
                     MatchRegister("save_byte1"),
                     MatchRegister("save_byte2"),
                     MatchRegister("save_byte3") };
        }

        return spec;
    }

    // TBD
    int numParsers() const override { return 36; }
    int numTcamRows() const override { return 256; }

    unsigned maxClotsPerState() const override { return 2; }

    // Cap max size to 56 as a workaround of TF2LAB-44
    unsigned byteMaxClotSize() const override {
        return BackendOptions().tof2lab44_workaround ? 56 : 64; }

    unsigned numClotsPerGress() const override { return 64; }
    unsigned maxClotsLivePerGress() const override { return 16; }
    unsigned byteInterClotGap() const override { return 3; }
    unsigned bitMaxClotPos() const override { return 384 * 8; /* 384 bytes */ }

    unsigned numDeparserConstantBytes() const override { return 8; }
    unsigned numDeparserChecksumUnits() const override { return 8; }
    unsigned numDeparserInvertChecksumUnits() const override { return 4; }

    // FIXME: adjust to true clock rate
    double clkFreq() const override { return 1.35; }
    unsigned lineRate() const override { return 400; }

    const std::vector<std::string>& mdpValidVecFields() const override {
        static std::vector<std::string> vldVecFields;
        return vldVecFields;
    }

    const std::unordered_set<std::string>& mdpValidVecFieldsSet() const override {
        static std::unordered_set<std::string> vldVecSet;
        return vldVecSet;
    }
};

class JBayA0PardeSpec : public JBayPardeSpec {
 public:
    unsigned numDeparserInvertChecksumUnits() const override { return 0; }
};

#if HAVE_CLOUDBREAK
class CloudbreakPardeSpec : public JBayPardeSpec {
 public:
    unsigned numDeparserInvertChecksumUnits() const override { return 8; }
};
#endif /* HAVE_CLOUDBREAK */

#if HAVE_FLATROCK
class FlatrockPardeSpec : public TofinoPardeSpec {
 public:
    const std::vector<std::string>& mdpValidVecFields() const override {
        static std::vector<std::string> vldVecFields = {
            "icrc_enable",
            "drop",
            "pgen_trig_vld",
            "iafc_vld",
            "lq_vld",
            "pkt_expan_idx_vld",
            "ucast_egress_port.$valid",
            "mcast_grp_b.$valid",
            "mcast_grp_a.$valid",
            "mirror_bitmap.$valid",     // FIXME: should this be mirror_cos?
            "copy_to_cpu",
            "perfect_hash_table_id",
            "enable_mcast_cutthru",
            "disable_ucast_cutthru",
            "deflect_on_drop",
        };
        return vldVecFields;
    }

    const std::unordered_set<std::string>& mdpValidVecFieldsSet() const override {
        static std::unordered_set<std::string> vldVecSet;
        if (vldVecSet.size() != mdpValidVecFields().size()) {
            vldVecSet.insert(mdpValidVecFields().begin(), mdpValidVecFields().end());
        }
        return vldVecSet;
    }
};
#endif /* HAVE_FLATROCK */

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_ */
