#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_

#include <map>
#include <vector>

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/parde/match_register.h"

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

    /// @return the size in bytes of *used fields* in the egress intrinsic metadata header
    /// For now, we assume all fields are used; though this should really be program specific. TODO
    virtual size_t byteEgressIntrinsicMetadataSize() const = 0;

    /// @return bitmask indicating which egress intrinsic metadata fields are used
    /// For now, we assume all fields are used; though this should really be program specific. TODO
    virtual unsigned egressPacketBufferConfig() const { return (1 << 13) - 1; }

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

    /// Specifies the available match registers in bits. Note that they can be
    /// combined and used as a larger match key.
    virtual const std::vector<MatchRegister> matchRegisters() const = 0;
};

class TofinoPardeSpec : public PardeSpec {
 public:
    size_t bytePhase0Size() const override { return 8; }
    size_t byteIngressPrePacketPaddingSize() const override { return 0; }
    size_t byteEgressIntrinsicMetadataSize() const override { return 27; }

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
    size_t bytePhase0Size() const override { return 16; }
    size_t byteIngressPrePacketPaddingSize() const override { return 8; }
    size_t byteEgressIntrinsicMetadataSize() const override { return 28; }

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
