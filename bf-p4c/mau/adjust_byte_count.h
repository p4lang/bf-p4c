#ifndef EXTENSIONS_BF_P4C_MAU_ADJUST_BYTE_COUNT_H_
#define EXTENSIONS_BF_P4C_MAU_ADJUST_BYTE_COUNT_H_

#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/mau/mau_visitor.h"
namespace BFN {

// This pass sets up the adjust byte count value on a counter or a meter.
// It first scans the IR for any counter/meter extern objects and checks if
// their respective methods (count/execute) have an 'adjust_byte_count'
// argument. For all method calls for the same counter/meter the argument value
// is verified to be the same. This is required the counter/meter can only set a
// single value as adjust byte count. Post verification the value is stored in
// the extern object
class AdjustByteCountSetup : public PassManager {
    std::map<const P4::IR::MAU::AttachedMemory*, const int64_t> adjust_byte_counts;

    class Scan : public MauInspector {
        AdjustByteCountSetup &self;
     public :
        explicit Scan(AdjustByteCountSetup &self) : self(self) {}
        bool preorder(const P4::IR::MAU::Primitive *prim) override;
    };

    class Update : public MauTransform {
        AdjustByteCountSetup &self;
     public :
        int get_bytecount(P4::IR::MAU::AttachedMemory *am);
        const P4::IR::MAU::Counter *preorder(P4::IR::MAU::Counter *counter) override;
        const P4::IR::MAU::Meter *preorder(P4::IR::MAU::Meter *meter) override;
        explicit Update(AdjustByteCountSetup &self) : self(self) {}
    };

 public :
    AdjustByteCountSetup();
};

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_MAU_ADJUST_BYTE_COUNT_H_ */
