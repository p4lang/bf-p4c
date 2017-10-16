#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_

#include <vector>

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

    /// The available kinds of extractors, specified as sizes in bits.
    virtual std::vector<unsigned> extractorKinds() const = 0;

    /// The number of extractors of each kind available in each hardware parser
    /// state.
    virtual unsigned extractorCount() const = 0;

    /// The size of the input buffer, in bits.
    virtual int bitInputBufferSize() const = 0;

    /// The size of the input buffer, in bytes.
    int byteInputBufferSize() const { return bitInputBufferSize() / 8; }
};

class TofinoPardeSpec : public PardeSpec {
 public:
    size_t byteIngressMetadataPrefixSize() const override { return 8; }
    size_t byteIngressPerPortMetadataSize() const override { return 8; }
    size_t byteIngressPrePacketPaddingSize() const override { return 0; }
    size_t byteEgressMetadataSize() const override { return 2; }

    std::vector<unsigned> extractorKinds() const override { return {8, 16, 32 }; }

    unsigned extractorCount() const override { return 4; }

    int bitInputBufferSize() const override { return 256; }
};

#if HAVE_JBAY
// XXX(zma) same as TofinoPardeSpec for now
class JBayPardeSpec : public PardeSpec {
 public:
    size_t byteIngressMetadataPrefixSize() const override { return 8; }
    size_t byteIngressPerPortMetadataSize() const override { return 16; }
    size_t byteIngressPrePacketPaddingSize() const override { return 8; }
    size_t byteEgressMetadataSize() const override { return 2; }

    std::vector<unsigned> extractorKinds() const override { return {8, 16, 32 }; }

    unsigned extractorCount() const override { return 4; }

    int bitInputBufferSize() const override { return 256; }
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_ */
