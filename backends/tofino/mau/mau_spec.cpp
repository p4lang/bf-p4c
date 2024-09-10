#include "backends/tofino/mau/mau_spec.h"

#define MAU_SPEC_UNSUPPORTED                                     \
    BUG("Unsupported: a base class was used in a context/place " \
        "where only a derived one is permitted.");

int TofinoIMemSpec::rows() const { return 32; }

int TofinoIMemSpec::colors() const { return 2; }

int TofinoIMemSpec::color_bits() const { return 1; }

int TofinoIMemSpec::address_bits() const { return 6; }

int TofinoIMemSpec::map_table_entries() const { return 8; }

#if HAVE_FLATROCK
int FlatrockIMemSpec::rows() const { return 8; }

int FlatrockIMemSpec::colors() const { return 4; }

int FlatrockIMemSpec::color_bits() const { return 2; }

int FlatrockIMemSpec::address_bits() const { return 5; }

int FlatrockIMemSpec::map_table_entries() const { return 16; }
#endif

int IXBarSpec::byteGroups() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::exactBytesPerGroup() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::exactGroups() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::fairModeHashBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::gatewaySearchBytes() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashDistBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashDistExpandBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashDistMaxMaskBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashDistSlices() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashDistUnits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashGroups() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashIndexGroups() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashMatrixSize() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashParityBit() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashSingleBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::hashTables() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::lpfInputBytes() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::maxHashBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::meterAluHashBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::meterAluHashParityByteStart() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::meterPrecolorSize() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::ramLineSelectBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::ramSelectBitStart() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::repeatingConstraintSect() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::resilientModeHashBits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::ternaryBytesPerBigGroup() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::tofinoMeterAluByteOffset() const { MAU_SPEC_UNSUPPORTED }

#if HAVE_FLATROCK
int IXBarSpec::bytesPerWord() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::exactBytes() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::exactMatchSTMUnits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::exactMatchUnits() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::exactWords() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::gatewayFixedBytes() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::gatewayRows() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::gatewayVecBytes() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::xcmpBytes() const { MAU_SPEC_UNSUPPORTED }

int IXBarSpec::xcmpWords() const {MAU_SPEC_UNSUPPORTED }
#endif

IR::Node *MauSpec::postTransformTables(IR::MAU::Table *const table) const {
    return table;
}

int MauSpec::tcam_rows() const { return Tofino_tcam_rows; }

int MauSpec::tcam_columns() const { return Tofino_tcam_columns; }

int MauSpec::tcam_width() const { return 44; }

int MauSpec::tcam_depth() const { return 512; }

TofinoIXBarSpec::TofinoIXBarSpec() = default;

int TofinoIXBarSpec::byteGroups() const { return StageUse::MAX_TERNARY_GROUPS / 2; }

int TofinoIXBarSpec::hashDistMaxMaskBits() const { return hashDistBits() + hashDistExpandBits(); }

int TofinoIXBarSpec::hashMatrixSize() const { return ramSelectBitStart() + hashSingleBits(); }

int TofinoIXBarSpec::ternaryGroups() const { return StageUse::MAX_TERNARY_GROUPS; }

int TofinoIXBarSpec::exactBytesPerGroup() const { return 16; }

int TofinoIXBarSpec::exactGroups() const { return 8; }

int TofinoIXBarSpec::fairModeHashBits() const { return 14; }

int TofinoIXBarSpec::gatewaySearchBytes() const { return 4; }

int TofinoIXBarSpec::hashDistBits() const { return 16; }

int TofinoIXBarSpec::hashDistExpandBits() const { return 7; }

int TofinoIXBarSpec::hashDistSlices() const { return 3; }

int TofinoIXBarSpec::hashDistUnits() const { return 2; }

int TofinoIXBarSpec::hashGroups() const { return 8; }

int TofinoIXBarSpec::hashIndexGroups() const { return 4; }

int TofinoIXBarSpec::hashParityBit() const { return 51; }

int TofinoIXBarSpec::hashSingleBits() const { return 12; }

int TofinoIXBarSpec::hashTables() const { return 16; }

int TofinoIXBarSpec::lpfInputBytes() const { return 4; }

int TofinoIXBarSpec::maxHashBits() const { return 52; }

int TofinoIXBarSpec::meterAluHashBits() const { return 52; }

int TofinoIXBarSpec::meterAluHashParityByteStart() const { return 48; }

int TofinoIXBarSpec::meterPrecolorSize() const { return 2; }

int TofinoIXBarSpec::ramLineSelectBits() const { return 10; }

int TofinoIXBarSpec::ramSelectBitStart() const { return 40; }

int TofinoIXBarSpec::repeatingConstraintSect() const { return 4; }

int TofinoIXBarSpec::resilientModeHashBits() const { return 51; }

int TofinoIXBarSpec::ternaryBytesPerBigGroup() const { return 11; }

int TofinoIXBarSpec::ternaryBytesPerGroup() const { return 5; }

int TofinoIXBarSpec::tofinoMeterAluByteOffset() const { return 8; }

int TofinoIXBarSpec::tcam_rows() const { return Tofino_tcam_rows; }

int TofinoIXBarSpec::tcam_columns() const { return Tofino_tcam_columns; }

int TofinoIXBarSpec::exactMatchTotalBytes() const { return 8 * 16; }

int TofinoIXBarSpec::ternaryMatchTotalBytes() const { return 6 * 11; }

int TofinoIXBarSpec::xcmpMatchTotalBytes() const { return 0; }

const IXBarSpec &TofinoMauSpec::getIXBarSpec() const { return ixbar_; }

const IMemSpec &TofinoMauSpec::getIMemSpec() const { return imem_; }

const IMemSpec &JBayMauSpec::getIMemSpec() const { return imem_; }

const IXBarSpec &JBayMauSpec::getIXBarSpec() const { return ixbar_; }

#if HAVE_CLOUDBREAK
const IXBarSpec &CloudbreakMauSpec::getIXBarSpec() const { return ixbar_; }

const IMemSpec &CloudbreakMauSpec::getIMemSpec() const { return imem_; }
#endif  /* HAVE_CLOUDBREAK */

#if HAVE_FLATROCK

FlatrockIXBarSpec::FlatrockIXBarSpec() = default;

int FlatrockIXBarSpec::bytesPerWord() const { return 4; }

int FlatrockIXBarSpec::exactBytes() const { return 20; }

int FlatrockIXBarSpec::exactMatchSTMUnits() const { return 4; }

int FlatrockIXBarSpec::exactMatchUnits() const { return 8; }

int FlatrockIXBarSpec::exactWords() const { return 5; }

int FlatrockIXBarSpec::gatewayFixedBytes() const { return 5; }

int FlatrockIXBarSpec::gatewayRows() const { return 24; }

int FlatrockIXBarSpec::gatewayVecBytes() const { return 8; }

int FlatrockIXBarSpec::ramSelectBitStart() const { return 0; }

int FlatrockIXBarSpec::ramLineSelectBits() const { return 10; }

int FlatrockIXBarSpec::ternaryBytesPerGroup() const { return 5; }

int FlatrockIXBarSpec::ternaryGroups() const { return 20; }

int FlatrockIXBarSpec::xcmpBytes() const { return 16; }

int FlatrockIXBarSpec::xcmpWords() const { return 12; }

int FlatrockIXBarSpec::tcam_rows() const { return Flatrock_tcam_rows; }

int FlatrockIXBarSpec::tcam_columns() const { return Flatrock_tcam_columns; }

int FlatrockIXBarSpec::exactMatchTotalBytes() const { return 2 * 20; }

int FlatrockIXBarSpec::ternaryMatchTotalBytes() const { return 20 * 5; }

int FlatrockIXBarSpec::xcmpMatchTotalBytes() const { return 4 * 16; }

const IXBarSpec &FlatrockMauSpec::getIXBarSpec() const { return ixbar_; }

const IMemSpec &FlatrockMauSpec::getIMemSpec() const { return imem_; }

IR::Node *FlatrockMauSpec::postTransformTables(IR::MAU::Table *const table) const { return table; }

int FlatrockMauSpec::tcam_width() const { return 40; }

int FlatrockMauSpec::tcam_depth() const { return 512; }

int FlatrockMauSpec::tcam_rows() const { return Flatrock_tcam_rows; }

int FlatrockMauSpec::tcam_columns() const { return Flatrock_tcam_columns; }

#endif
