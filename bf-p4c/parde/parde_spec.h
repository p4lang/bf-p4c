#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_

#include <vector>

class PardeSpec {
 public:
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
    std::vector<unsigned> extractorKinds() const override { return {8, 16, 32 }; }

    unsigned extractorCount() const override { return 4; }

    int bitInputBufferSize() const override { return 256; }
};

#if HAVE_JBAY
// XXX(zma) same as TofinoPardeSpec for now
class JBayPardeSpec : public PardeSpec {
 public:
    std::vector<unsigned> extractorKinds() const override { return {8, 16, 32 }; }

    unsigned extractorCount() const override { return 4; }

    int bitInputBufferSize() const override { return 256; }
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_SPEC_H_ */
