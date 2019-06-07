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
        return { MatchRegister("half"),
                 MatchRegister("byte0"),
                 MatchRegister("byte1") };
    }

    int numParsers() const override { return 18; }
    int numTcamRows() const override { return 256; }

    unsigned maxClotsPerState() const override { BUG("No CLOTs in Tofino"); }
    unsigned byteMaxClotSize() const override { BUG("No CLOTs in Tofino"); }
    unsigned numClotsPerGress() const override { BUG("No CLOTs in Tofino"); }

    unsigned maxClotsLivePerGress() const override {
        BUG("No CLOTs in Tofino");
    }

    unsigned byteInterClotGap() const override { BUG("No CLOTs in Tofino"); }
};

#if HAVE_JBAY
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
        return { MatchRegister("byte0"),
                 MatchRegister("byte1"),
                 MatchRegister("byte2"),
                 MatchRegister("byte3") };
    }

    // TBD
    int numParsers() const override { return 36; }
    int numTcamRows() const override { return 256; }

    unsigned maxClotsPerState() const override { return 2; }
    unsigned byteMaxClotSize() const override { return 64; }
    unsigned numClotsPerGress() const override { return 64; }
    unsigned maxClotsLivePerGress() const override { return 16; }
    unsigned byteInterClotGap() const override { return 3; }
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_ */
