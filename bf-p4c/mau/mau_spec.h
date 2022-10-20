#ifndef EXTENSIONS_BF_P4C_MAU_MAU_SPEC_H_
#define EXTENSIONS_BF_P4C_MAU_MAU_SPEC_H_

#define UNSUPPORTED BUG("unsupported api");

#include "ir/ir.h"

// device-specific parameters for MAU/PPU.
class IXBarSpec {
 public:
    /* common */
    virtual int ternaryBytesPerGroup() const { UNSUPPORTED };
    virtual int ternaryGroups() const { UNSUPPORTED };
    virtual int tcam_rows() const { UNSUPPORTED };
    virtual int tcam_columns() const { UNSUPPORTED };

    /* tofino */
    virtual int byteGroups() const { UNSUPPORTED };
    virtual int exactBytesPerGroup() const { UNSUPPORTED };
    virtual int exactGroups() const { UNSUPPORTED };
    virtual int fairModeHashBits() const { UNSUPPORTED };
    virtual int gatewaySearchBytes() const { UNSUPPORTED };
    virtual int hashDistBits() const { UNSUPPORTED };
    virtual int hashDistExpandBits() const { UNSUPPORTED };
    virtual int hashDistMaxMaskBits() const { UNSUPPORTED };
    virtual int hashDistSlices() const { UNSUPPORTED };
    virtual int hashDistUnits() const { UNSUPPORTED };
    virtual int hashGroups() const { UNSUPPORTED };
    virtual int hashIndexGroups() const { UNSUPPORTED };
    virtual int hashMatrixSize() const { UNSUPPORTED };
    virtual int hashParityBit() const { UNSUPPORTED };
    virtual int hashSingleBits() const { UNSUPPORTED };
    virtual int hashTables() const { UNSUPPORTED };
    virtual int lpfInputBytes() const { UNSUPPORTED };
    virtual int maxHashBits() const { UNSUPPORTED };
    virtual int meterAluHashBits() const { UNSUPPORTED };
    virtual int meterAluHashParityByteStart() const { UNSUPPORTED };
    virtual int meterPrecolorSize() const { UNSUPPORTED };
    virtual int ramLineSelectBits() const { UNSUPPORTED };
    virtual int ramSelectBitStart() const { UNSUPPORTED };
    virtual int repeatingConstraintSect() const { UNSUPPORTED };
    virtual int resilientModeHashBits() const { UNSUPPORTED };
    virtual int ternaryBytesPerBigGroup() const { UNSUPPORTED };
    virtual int tofinoMeterAluByteOffset() const { UNSUPPORTED };

    /* flatrock */
    virtual int bytesPerWord() const { UNSUPPORTED };
    virtual int exactBytes() const { UNSUPPORTED };
    virtual int exactMatchSTMUnits() const { UNSUPPORTED };
    virtual int exactMatchUnits() const { UNSUPPORTED };
    virtual int exactWords() const { UNSUPPORTED };
    virtual int gatewayFixedBytes() const { UNSUPPORTED };
    virtual int gatewayRows() const { UNSUPPORTED };
    virtual int gatewayVecBytes() const { UNSUPPORTED };
    virtual int xcmpBytes() const { UNSUPPORTED };
    virtual int xcmpWords() const { UNSUPPORTED };
};

class IMemSpec {
 public:
    virtual int rows() const { UNSUPPORTED };
    virtual int colors() const { UNSUPPORTED };
    virtual int color_bits() const { UNSUPPORTED };
};

class TofinoIXBarSpec : public IXBarSpec {
 public:
    TofinoIXBarSpec() {}

    int byteGroups() const override { return StageUse::MAX_TERNARY_GROUPS/2; }
    int exactBytesPerGroup() const override { return 16; }
    int exactGroups() const override { return 8; }
    int fairModeHashBits() const override { return 14; }
    int gatewaySearchBytes() const override { return 4; }
    int hashDistBits() const override { return 16; }
    int hashDistExpandBits() const override { return 7; }
    int hashDistMaxMaskBits() const override { return hashDistBits() + hashDistExpandBits(); }
    int hashDistSlices() const override { return 3; }
    int hashDistUnits() const override { return 2; }
    int hashGroups() const override { return 8; }
    int hashIndexGroups() const override { return 4; }  /* groups of 10 bits for indexing */
    int hashMatrixSize() const override { return ramSelectBitStart() + hashSingleBits(); }
    int hashParityBit() const override { return 51; }  /* If enabled reserved parity bit position */
    int hashSingleBits() const override { return 12; }  /* top 12 bits of hash table individually */
    int hashTables() const override { return 16; }
    int lpfInputBytes() const override { return 4; }
    int maxHashBits() const override { return 52; }
    int meterAluHashBits() const override { return 52; }
    int meterAluHashParityByteStart() const override { return 48; }
    int meterPrecolorSize() const override { return 2; }
    int ramLineSelectBits() const override { return 10; }
    int ramSelectBitStart() const override { return 40; }
    int repeatingConstraintSect() const override { return 4; }
    int resilientModeHashBits() const override { return 51; }
    int ternaryBytesPerBigGroup() const override { return 11; }
    int ternaryBytesPerGroup() const override { return 5; }
    int ternaryGroups() const override { return StageUse::MAX_TERNARY_GROUPS; }
    int tofinoMeterAluByteOffset() const override { return 8; }
    int tcam_rows() const override { return 12; }
    int tcam_columns() const override { return 2; }
};

class TofinoIMemSpec : public IMemSpec {
    int rows() const override { return 32; };
    int colors() const override { return 2; };
    int color_bits() const override { return 1; };
};

class FlatrockIXBarSpec : public IXBarSpec {
 public:
    FlatrockIXBarSpec() {}

    int bytesPerWord() const override { return 4; }
    int exactBytes() const override { return 20; }
    int exactMatchSTMUnits() const override { return 4; }  /* first 4 units */
    int exactMatchUnits() const override { return 8; }   /* 4 STM + 4 LAMB */
    int exactWords() const override { return 5; }
    int gatewayFixedBytes() const override { return 5; }
    int gatewayRows() const override { return 24; }
    int gatewayVecBytes() const override { return 8; }
    int ternaryBytesPerGroup() const override { return 5; }
    int ternaryGroups() const override { return 16; }
    int xcmpBytes() const override { return 16; }
    int xcmpWords() const override { return 12; }
    int tcam_rows() const override { return 20; }
    int tcam_columns() const override { return 1; }
};

class FlatrockIMemSpec : public IMemSpec {
    int rows() const override { return 8; };
    int colors() const override { return 4; };
    int color_bits() const override { return 2; };
};

class MauSpec {
 public:
    virtual const IXBarSpec& getIXBarSpec() const = 0;
    virtual const IMemSpec& getIMemSpec() const = 0;

    // Called at the end of table rewriting in TablePlacement::TransformTables to do
    // any target-specific fixups needed
    virtual IR::Node *postTransformTables(IR::MAU::Table *tbl) const { return tbl; }
};


class TofinoMauSpec : public MauSpec {
    const TofinoIXBarSpec ixbar_;
    const TofinoIMemSpec imem_;

 public:
    TofinoMauSpec() {}
    const IXBarSpec& getIXBarSpec() const override { return ixbar_; }
    const IMemSpec& getIMemSpec() const override { return imem_; }
};

class JBayMauSpec : public MauSpec {
    const TofinoIXBarSpec ixbar_;
    const TofinoIMemSpec imem_;

 public:
    JBayMauSpec() {}
    const IXBarSpec& getIXBarSpec() const override { return ixbar_; }
    const IMemSpec& getIMemSpec() const override { return imem_; }
};

class CloudbreakMauSpec : public MauSpec {
    const TofinoIXBarSpec ixbar_;
    const TofinoIMemSpec imem_;

 public:
    CloudbreakMauSpec() {}
    const IXBarSpec& getIXBarSpec() const override { return ixbar_; }
    const IMemSpec& getIMemSpec() const override { return imem_; }
};

class FlatrockMauSpec : public MauSpec {
    const FlatrockIXBarSpec ixbar_;
    const FlatrockIMemSpec imem_;

 public:
    FlatrockMauSpec() {}
    const IXBarSpec& getIXBarSpec() const override { return ixbar_; }
    const IMemSpec& getIMemSpec() const override { return imem_; }

    IR::Node *postTransformTables(IR::MAU::Table *tbl) const override;
};

#endif  /* EXTENSIONS_BF_P4C_MAU_MAU_SPEC_H_ */
