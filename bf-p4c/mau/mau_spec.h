#ifndef EXTENSIONS_BF_P4C_MAU_MAU_SPEC_H_
#define EXTENSIONS_BF_P4C_MAU_MAU_SPEC_H_

#define UNSUPPORTED BUG("Unsupported: a base class was used in a context/place " \
                        "where only a derived one is permitted.");

#include "ir/ir.h"

// device-specific parameters for MAU/PPU.

class IMemSpec {
 public:
    virtual int rows()       const = 0;  //  pure virtual
    virtual int colors()     const = 0;  //  pure virtual
    virtual int color_bits() const = 0;  //  pure virtual
};

class TofinoIMemSpec : public IMemSpec {
    int rows()       const override { return 32; };
    int colors()     const override { return  2; };
    int color_bits() const override { return  1; };
};

class FlatrockIMemSpec : public IMemSpec {
    int rows()       const override { return 8; };
    int colors()     const override { return 4; };
    int color_bits() const override { return 2; };
};

class IXBarSpec {
 public:
    /* --- common --- */
    virtual int ternaryBytesPerGroup() const = 0;  //  pure virtual
    virtual int ternaryGroups()        const = 0;  //  pure virtual

    // the next two: support for "legacy code" [as of Nov. 10 2022] that gets these via IXBarSpec
    virtual int tcam_rows()            const = 0;  //  pure virtual
    virtual int tcam_columns()         const = 0;  //  pure virtual

    /* --- Tofino[1, 2, 3] --- */
    virtual int byteGroups()                  const { UNSUPPORTED };
    virtual int exactBytesPerGroup()          const { UNSUPPORTED };
    virtual int exactGroups()                 const { UNSUPPORTED };
    virtual int fairModeHashBits()            const { UNSUPPORTED };
    virtual int gatewaySearchBytes()          const { UNSUPPORTED };
    virtual int hashDistBits()                const { UNSUPPORTED };
    virtual int hashDistExpandBits()          const { UNSUPPORTED };
    virtual int hashDistMaxMaskBits()         const { UNSUPPORTED };
    virtual int hashDistSlices()              const { UNSUPPORTED };
    virtual int hashDistUnits()               const { UNSUPPORTED };
    virtual int hashGroups()                  const { UNSUPPORTED };
    virtual int hashIndexGroups()             const { UNSUPPORTED };
    virtual int hashMatrixSize()              const { UNSUPPORTED };
    virtual int hashParityBit()               const { UNSUPPORTED };
    virtual int hashSingleBits()              const { UNSUPPORTED };
    virtual int hashTables()                  const { UNSUPPORTED };
    virtual int lpfInputBytes()               const { UNSUPPORTED };
    virtual int maxHashBits()                 const { UNSUPPORTED };
    virtual int meterAluHashBits()            const { UNSUPPORTED };
    virtual int meterAluHashParityByteStart() const { UNSUPPORTED };
    virtual int meterPrecolorSize()           const { UNSUPPORTED };
    virtual int ramLineSelectBits()           const { UNSUPPORTED };
    virtual int ramSelectBitStart()           const { UNSUPPORTED };
    virtual int repeatingConstraintSect()     const { UNSUPPORTED };
    virtual int resilientModeHashBits()       const { UNSUPPORTED };
    virtual int ternaryBytesPerBigGroup()     const { UNSUPPORTED };
    virtual int tofinoMeterAluByteOffset()    const { UNSUPPORTED };

    /* --- FlatRock --- */
    virtual int bytesPerWord()                const { UNSUPPORTED };
    virtual int exactBytes()                  const { UNSUPPORTED };
    virtual int exactMatchSTMUnits()          const { UNSUPPORTED };
    virtual int exactMatchUnits()             const { UNSUPPORTED };
    virtual int exactWords()                  const { UNSUPPORTED };
    virtual int gatewayFixedBytes()           const { UNSUPPORTED };
    virtual int gatewayRows()                 const { UNSUPPORTED };
    virtual int gatewayVecBytes()             const { UNSUPPORTED };
    virtual int xcmpBytes()                   const { UNSUPPORTED };
    virtual int xcmpWords()                   const { UNSUPPORTED };

    virtual int getExactOrdBase(int group) const = 0;
    virtual int getTernaryOrdBase(int group) const = 0;
    virtual int exactMatchTotalBytes() const = 0;
    virtual int ternaryMatchTotalBytes() const = 0;
    virtual int xcmpMatchTotalBytes() const = 0;
};

// TU-local constants to avoid circular dependencies between IXBarSpec subclasses
//   and their respective MauSpec subclasses, while still preserving DRY compliance.
static constexpr int Flatrock_tcam_rows    = 20;
static constexpr int   Tofino_tcam_rows    = 12;
static constexpr int   Tofino_tcam_columns =  2;
static constexpr int Flatrock_tcam_columns =  1;

class MauSpec {
 public:
    virtual const IXBarSpec& getIXBarSpec() const = 0;  //  pure virtual
    virtual const  IMemSpec&  getIMemSpec() const = 0;  //  pure virtual

    // Called at the end of table rewriting in TablePlacement::TransformTables to do
    // any target-specific fixups needed
    virtual IR::Node* postTransformTables(IR::MAU::Table* const table) const { return table; }

    // The next 4 lines: correct data for Tof.1 + Tof.2 + Tof.3; must override elsewhere for Tof.5
    virtual int tcam_rows()    const { return Tofino_tcam_rows   ; }
    virtual int tcam_columns() const { return Tofino_tcam_columns; }
    virtual int tcam_width()   const { return  44;                 }
    virtual int tcam_depth()   const { return 512;                 }
};

class TofinoIXBarSpec : public IXBarSpec {
 public:
    TofinoIXBarSpec() {}

    int byteGroups()                  const override
        { return StageUse::MAX_TERNARY_GROUPS/2; }

    int hashDistMaxMaskBits()         const override
        { return hashDistBits() + hashDistExpandBits(); }

    int hashMatrixSize()              const override
        { return ramSelectBitStart() + hashSingleBits(); }

    int ternaryGroups()               const override
        { return StageUse::MAX_TERNARY_GROUPS; }

    int exactBytesPerGroup()          const override { return  16; }
    int exactGroups()                 const override { return   8; }
    int fairModeHashBits()            const override { return  14; }
    int gatewaySearchBytes()          const override { return   4; }
    int hashDistBits()                const override { return  16; }
    int hashDistExpandBits()          const override { return   7; }
    int hashDistSlices()              const override { return   3; }
    int hashDistUnits()               const override { return   2; }
    int hashGroups()                  const override { return   8; }

    int hashIndexGroups()             const override { return   4; }
        /* groups of 10 bits for indexing */

    int hashParityBit()               const override { return  51; }
        /* If enabled reserved parity bit position */

    int hashSingleBits()              const override { return  12; }
        /* top 12 bits of hash table individually */

    int hashTables()                  const override { return  16; }
    int lpfInputBytes()               const override { return   4; }
    int maxHashBits()                 const override { return  52; }
    int meterAluHashBits()            const override { return  52; }
    int meterAluHashParityByteStart() const override { return  48; }
    int meterPrecolorSize()           const override { return   2; }
    int ramLineSelectBits()           const override { return  10; }
    int ramSelectBitStart()           const override { return  40; }
    int repeatingConstraintSect()     const override { return   4; }
    int resilientModeHashBits()       const override { return  51; }
    int ternaryBytesPerBigGroup()     const override { return  11; }
    int ternaryBytesPerGroup()        const override { return   5; }
    int tofinoMeterAluByteOffset()    const override { return   8; }

    // the next two: support for "legacy code" [as of Nov. 10 2022] that gets these via IXBarSpec
    int tcam_rows()    const override { return Tofino_tcam_rows   ; }
    int tcam_columns() const override { return Tofino_tcam_columns; }

    int getExactOrdBase(int group) const override;
    int getTernaryOrdBase(int group) const override;

    int exactMatchTotalBytes()          const override { return 8*16; }
    int ternaryMatchTotalBytes()        const override { return 6*11; }
    int xcmpMatchTotalBytes()           const override { return 0; }
};

class FlatrockIXBarSpec : public IXBarSpec {
 public:
    FlatrockIXBarSpec() {}

    int bytesPerWord()         const override { return   4; }
    int exactBytes()           const override { return  20; }
    int exactMatchSTMUnits()   const override { return   4; }  /* first 4 units */
    int exactMatchUnits()      const override { return   8; }  /* 4 STM + 4 LAMB */
    int exactWords()           const override { return   5; }
    int gatewayFixedBytes()    const override { return   5; }
    int gatewayRows()          const override { return  24; }
    int gatewayVecBytes()      const override { return   8; }
    int ramSelectBitStart()    const override { return   0; }   // any bits can be ram select
    int ramLineSelectBits()    const override { return  10; }   // FIXME 6 for lamb, 10 for STM
    int ternaryBytesPerGroup() const override { return   5; }
    int ternaryGroups()        const override { return  20; }
    int xcmpBytes()            const override { return  16; }
    int xcmpWords()            const override { return  12; }

    // the next two: support for "legacy code" [as of Nov. 10 2022] that gets these via IXBarSpec
    int tcam_rows()            const override { return Flatrock_tcam_rows   ; }
    int tcam_columns()         const override { return Flatrock_tcam_columns; }

    int getExactOrdBase(int group) const;
    int getTernaryOrdBase(int group) const;

    int exactMatchTotalBytes()          const override { return 2*20; }
    int ternaryMatchTotalBytes()        const override { return 20*5; }
    int xcmpMatchTotalBytes()           const override { return 4*16; }
};

class TofinoMauSpec : public MauSpec {
    const TofinoIXBarSpec ixbar_;
    const TofinoIMemSpec   imem_;

 public:
    TofinoMauSpec() {}
    const IXBarSpec& getIXBarSpec() const override { return ixbar_; }
    const  IMemSpec&  getIMemSpec() const override { return  imem_; }
};

class JBayMauSpec : public MauSpec {
    const TofinoIXBarSpec ixbar_;
    const TofinoIMemSpec   imem_;

 public:
    JBayMauSpec() {}
    const IXBarSpec& getIXBarSpec() const override { return ixbar_; }
    const  IMemSpec&  getIMemSpec() const override { return  imem_; }
};

class CloudbreakMauSpec : public MauSpec {
    const TofinoIXBarSpec ixbar_;
    const TofinoIMemSpec   imem_;

 public:
    CloudbreakMauSpec() {}
    const IXBarSpec& getIXBarSpec() const override { return ixbar_; }
    const  IMemSpec&  getIMemSpec() const override { return  imem_; }
};

class FlatrockMauSpec : public MauSpec {
    const FlatrockIXBarSpec ixbar_;
    const FlatrockIMemSpec imem_;

 public:
    FlatrockMauSpec() {}
    const IXBarSpec& getIXBarSpec() const override { return ixbar_; }
    const  IMemSpec&  getIMemSpec() const override { return  imem_; }

    int tcam_width()                const override { return  40;                   }
    int tcam_depth()                const override { return 512;                   }
    int tcam_rows()                 const override { return Flatrock_tcam_rows   ; }
    int tcam_columns()              const override { return Flatrock_tcam_columns; }

    IR::Node* postTransformTables(IR::MAU::Table*) const override;
    //  preceding line`s decl.: implemented in "flatrock/mau_spec.cpp"
};

#endif  /* EXTENSIONS_BF_P4C_MAU_MAU_SPEC_H_ */
