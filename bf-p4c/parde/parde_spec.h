#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_

#include <map>
#include <vector>

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/epb_config.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/parde/match_register.h"

namespace IR {
class HeaderOrMetadata;
}  // namespace IR

class PardeSpec {
 public:
    /// @return the size in bytes of the ingress metadata "header" that precedes
    /// the static per-port metadata on this device.
    virtual size_t byteIngressMetadataPrefixSize() const = 0;

    /// @return the size in bytes of the ingress static per-port metadata on
    /// this device. (This is the "phase 0" data.) On resubmitted packets, the
    /// same region is used for resubmit metadata.
    virtual size_t byteIngressPerPortMetadataSize() const = 0;

    /// @return the size in bits or bytes of the phase 0 data on this device.
    /// This is just another way to refer to `ingressPerPortMetadataSizeBytes()`
    /// in contexts where it's clear that phase 0 data is intended.
    size_t bitPhase0Size() const { return byteIngressPerPortMetadataSize() * 8; }
    size_t bytePhase0Size() const { return byteIngressPerPortMetadataSize(); }

    /// @return the size in bits or bytes of the reserved resubmit tag on this device.
    size_t bitResubmitTagSize() const { return 8; }
    size_t byteResubmitTagSize() const { return 1; }

    /// @return the size in bits or bytes of the resubmit data on this device.
    size_t bitResubmitSize() const { return byteIngressPerPortMetadataSize() * 8; }
    size_t byteResubmitSize() const { return byteIngressPerPortMetadataSize(); }

    /// @return the size in bytes of the padding between the ingress static
    /// per-port metadata and the beginning of the packet.
    virtual size_t byteIngressPrePacketPaddingSize() const = 0;
    size_t bitIngressPrePacketPaddingSize() const {
        return byteIngressPrePacketPaddingSize() * 8;
    }

    /// @return the total size of all ingress metadata on this device.
    size_t byteTotalIngressMetadataSize() const {
        return byteIngressMetadataPrefixSize() +
               byteIngressPerPortMetadataSize() +
               byteIngressPrePacketPaddingSize();
    }

    /// @return the size in bytes of the egress intrinsic metadata "header" that
    /// will be generated for the given EPB configuration.
    virtual size_t byteEgressMetadataSize(EgressParserBufferConfig config) const = 0;

    /**
     * Generate the ingress intrinsic metadata layout for this device.
     *
     * The returned field packing can be used directly to generate a parser
     * program that extracts the ingress intrinsic metadata.
     *
     * @param header  The header or metadata instance that the field packing
     *                should reference; this is where the output of the
     *                generated parser will be written.
     * @return a fielding packing for the ingress intrinsic metadata.
     */
    virtual BFN::FieldPacking
    ingressMetadataLayout(const IR::HeaderOrMetadata* header) const = 0;

    /**
     * Given an EPB configuration, generate the resulting egress intrinsic
     * metadata layout for this device.
     *
     * The returned field packing can be used directly to generate a parser
     * program that extracts the egress intrinsic metadata.
     *
     * @param config  An EPB configuration indicating which egress intrinsic
     *                metadata fields are enabled.
     * @param header  The header or metadata instance that the field packing
     *                should reference; this is where the output of the
     *                generated parser will be written.
     * @return a fielding packing for the egress intrinsic metadata.
     */
    virtual BFN::FieldPacking
    egressMetadataLayout(EgressParserBufferConfig config,
                         const IR::HeaderOrMetadata* header) const = 0;

    /// @return a default, conservative EPB configuration.
    virtual EgressParserBufferConfig defaultEPBConfig() const = 0;

    /// The amount of packet data that fits in the input buffer, in bits.
    virtual int bitInputBufferSize() const = 0;

    /// The amount of packet data that fits in the input buffer, in bytes.
    int byteInputBufferSize() const { return bitInputBufferSize() / 8; }

    /// The "mapped" region of the input buffer address space, which contains
    /// special intrinsic metadata rather than packet data. In bits.
    virtual nw_bitrange bitMappedInputBufferRange() const = 0;

    /// The "mapped" region of the input buffer address space, which contains
    /// special intrinsic metadata rather than packet data. In bytes.
    nw_byterange byteMappedInputBufferRange() const {
        return bitMappedInputBufferRange().toUnit<RangeUnit::Byte>();
    }

    /// Specifies the available kinds of extractors, specified as sizes in bits,
    /// and the number of extractors of each kind available in each hardware parser
    /// state.
    virtual const std::map<unsigned, unsigned>& extractorSpec() const = 0;

    /// Specifies the available match registers in bits. Note that they can be
    /// combined and used as a larger match key.
    virtual const std::vector<MatchRegister> matchRegisters() const = 0;
};

class TofinoPardeSpec : public PardeSpec {
 public:
    size_t byteIngressMetadataPrefixSize() const override;
    size_t byteIngressPerPortMetadataSize() const override { return 8; }
    size_t byteIngressPrePacketPaddingSize() const override { return 0; }
    size_t byteEgressMetadataSize(EgressParserBufferConfig config) const override;

    BFN::FieldPacking
    ingressMetadataLayout(const IR::HeaderOrMetadata* header) const override;
    BFN::FieldPacking
    egressMetadataLayout(EgressParserBufferConfig config,
                         const IR::HeaderOrMetadata* header) const override;

    EgressParserBufferConfig defaultEPBConfig() const override;

    int bitInputBufferSize() const override { return 256; }

    nw_bitrange bitMappedInputBufferRange() const override {
        return StartLen(256, 256);
    }

    const std::map<unsigned, unsigned>& extractorSpec() const override {
        static const std::map<unsigned, unsigned> extractorSpec = {
            {8,  4},
            {16, 4},
            {32, 4}
        };
        return extractorSpec;
    }

    const std::vector<MatchRegister> matchRegisters() const override {
        return { MatchRegister("half"),
                 MatchRegister("byte0"),
                 MatchRegister("byte1") };
    }
};

#if HAVE_JBAY
class JBayPardeSpec : public PardeSpec {
 public:
    size_t byteIngressMetadataPrefixSize() const override;
    size_t byteIngressPerPortMetadataSize() const override { return 16; }
    size_t byteIngressPrePacketPaddingSize() const override { return 8; }
    size_t byteEgressMetadataSize(EgressParserBufferConfig config) const override;

    BFN::FieldPacking
    ingressMetadataLayout(const IR::HeaderOrMetadata* header) const override;
    BFN::FieldPacking
    egressMetadataLayout(EgressParserBufferConfig config,
                         const IR::HeaderOrMetadata* header) const override;

    EgressParserBufferConfig defaultEPBConfig() const override;

    int bitInputBufferSize() const override { return 256; }

    nw_bitrange bitMappedInputBufferRange() const override {
        return StartLen(256, 256);
    }

    const std::map<unsigned, unsigned>& extractorSpec() const override {
        static const std::map<unsigned, unsigned> extractorSpec = {
            {16, 20}
        };
        return extractorSpec;
    }

    const std::vector<MatchRegister> matchRegisters() const override {
        return { MatchRegister("byte0"),
                 MatchRegister("byte1"),
                 MatchRegister("byte2"),
                 MatchRegister("byte3") };
    }
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_ */
