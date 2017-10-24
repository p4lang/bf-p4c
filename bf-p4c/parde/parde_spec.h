#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_

#include <vector>
#include <map>

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

    /// @return the size in bytes of the padding between the ingress static
    /// per-port metadata and the beginning of the packet.
    virtual size_t byteIngressPrePacketPaddingSize() const = 0;

    /// @return the total size of all ingress metadata on this device.
    size_t byteTotalIngressMetadataSize() const {
        return byteIngressMetadataPrefixSize() +
               byteIngressPerPortMetadataSize() +
               byteIngressPrePacketPaddingSize();
    }

    /// @return the size in bytes of the egress metadata "header" on this
    /// device.
    virtual size_t byteEgressMetadataSize() const = 0;

    /// The size of the input buffer, in bits.
    virtual int bitInputBufferSize() const = 0;

    /// The size of the input buffer, in bytes.
    int byteInputBufferSize() const { return bitInputBufferSize() / 8; }

    /// Specifies the available kinds of extractors, specified as sizes in bits,
    /// and the number of extractors of each kind available in each hardware parser
    /// state.
    virtual const std::map<unsigned, unsigned>& extractorSpec() const = 0;
};

class TofinoPardeSpec : public PardeSpec {
 public:
    size_t byteIngressMetadataPrefixSize() const override { return 8; }
    size_t byteIngressPerPortMetadataSize() const override { return 8; }
    size_t byteIngressPrePacketPaddingSize() const override { return 0; }
    size_t byteEgressMetadataSize() const override { return 2; }

    int bitInputBufferSize() const override { return 256; }

    const std::map<unsigned, unsigned>& extractorSpec() const override {
        static const std::map<unsigned, unsigned> extractorSpec = {
            {8,  4},
            {16, 4},
            {32, 4}
        };
        return extractorSpec;
    }
};

#if HAVE_JBAY
class JBayPardeSpec : public PardeSpec {
 public:
    size_t byteIngressMetadataPrefixSize() const override { return 8; }
    size_t byteIngressPerPortMetadataSize() const override { return 16; }
    size_t byteIngressPrePacketPaddingSize() const override { return 8; }
    size_t byteEgressMetadataSize() const override { return 2; }

    int bitInputBufferSize() const override { return 256; }

    const std::map<unsigned, unsigned>& extractorSpec() const override {
        static const std::map<unsigned, unsigned> extractorSpec = {
            {16, 20}
        };
        return extractorSpec;
    }
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_ */
