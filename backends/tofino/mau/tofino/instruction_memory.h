#ifndef BF_P4C_MAU_TOFINO_INSTRUCTION_MEMORY_H_
#define BF_P4C_MAU_TOFINO_INSTRUCTION_MEMORY_H_

#include "backends/tofino/mau/instruction_memory.h"

namespace Tofino {

struct InstructionMemory : public ::InstructionMemory {
    static constexpr int IMEM_ROWS = 32;
    static constexpr int IMEM_COLORS = 2;

    BFN::Alloc2D<cstring, IMEM_ROWS, IMEM_COLORS> ingress_imem_use;
    BFN::Alloc2D<cstring, IMEM_ROWS, IMEM_COLORS> egress_imem_use;

    BFN::Alloc2D<bitvec, IMEM_ROWS, IMEM_COLORS> ingress_imem_slot_inuse;
    BFN::Alloc2D<bitvec, IMEM_ROWS, IMEM_COLORS> egress_imem_slot_inuse;

    BFN::Alloc2Dbase<cstring> &imem_use(gress_t gress) {
        if (gress == INGRESS || gress == GHOST)
            return ingress_imem_use;
        return egress_imem_use;
    }

    BFN::Alloc2Dbase<bitvec> &imem_slot_inuse(gress_t gress) {
        if (gress == INGRESS || gress == GHOST)
            return ingress_imem_slot_inuse;
        return egress_imem_slot_inuse;
    }

    InstructionMemory() : ::InstructionMemory(Device::imemSpec()) {}
};

}  // end namespace Tofino

#endif /* BF_P4C_MAU_TOFINO_INSTRUCTION_MEMORY_H_ */
