#ifndef BF_P4C_MAU_FLATROCK_INSTRUCTION_MEMORY_H_
#define BF_P4C_MAU_FLATROCK_INSTRUCTION_MEMORY_H_

#include "bf-p4c/mau/instruction_memory.h"

namespace Flatrock {

struct InstructionMemory : public ::InstructionMemory {
    static constexpr int IMEM_ROWS = 8;
    static constexpr int IMEM_COLORS = 4;

    BFN::Alloc2D<cstring, IMEM_ROWS, IMEM_COLORS> imem_use_;
    BFN::Alloc2D<bitvec, IMEM_ROWS, IMEM_COLORS> imem_slot_inuse_;

    BFN::Alloc2Dbase<cstring> &imem_use(gress_t) {
        return imem_use_;
    }

    BFN::Alloc2Dbase<bitvec> &imem_slot_inuse(gress_t) {
        return imem_slot_inuse_;
    }

    InstructionMemory() : ::InstructionMemory(Device::imemSpec()) {}
};

}  // end namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_INSTRUCTION_MEMORY_H_ */
