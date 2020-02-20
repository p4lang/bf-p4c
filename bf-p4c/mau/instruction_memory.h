#ifndef BF_P4C_MAU_INSTRUCTION_MEMORY_H_
#define BF_P4C_MAU_INSTRUCTION_MEMORY_H_

#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/ir/gress.h"
#include "lib/alloc.h"

class GenerateVLIWInstructions : public MauInspector, TofinoWriteContext {
    PhvInfo &phv;
    ActionData::FormatType_t format_type;
    SplitAttachedInfo &split_attached;
    bool preorder(const IR::MAU::TableSeq *) override { return false; }
    bool preorder(const IR::MAU::BackendAttached *) override { return false; }
    bool preorder(const IR::MAU::AttachedOutput *) override { return false; }
    bool preorder(const IR::MAU::StatefulCounter *) override { return false; }
    bool preorder(const IR::MAU::Action *) override;
    // Do not visit the stateful primitives
    bool preorder(const IR::MAU::StatefulCall *) override { return false; }
    bool preorder(const IR::MAU::Instruction *) override { return true; }
    bool preorder(const IR::Expression *) override;
    bitvec current_vliw;
    ordered_map<const IR::MAU::Action *, bitvec> table_instrs;

 public:
    bitvec get_instr(const IR::MAU::Action *act) {
        return table_instrs[act];
    }
    GenerateVLIWInstructions(PhvInfo &p, ActionData::FormatType_t ft,
            SplitAttachedInfo &sai)
       : phv(p), format_type(ft), split_attached(sai) { visitDagOnce = false; }
};

/** Algorithms for the allocation of the Instruction Memory.  The Instruction Memory is defined
 *  in the uArch section 6.1.10.3 Action Instruction Memory.
 *
 *  The instruction memory is a 32 row x (PHV ALUs) per gress memory.  Each action in
 *  P4 corresponds to a single RAM row in the IMEM.  Each slot of a row corresponds to the
 *  instruction for that particular ALU.  A noop instruction for an ALU is an all 0 encoded
 *  instruction.  Thus an action in the P4 code coordinates to a single line in the
 *  instruction memory.  For all PHVs that a particular action writes, the slots on that row
 *  will have the corresponding action, and for all PHVs that the particular action doesn't
 *  write, a noop, encoded as all 0s will let the PHV pass directly through.  These instructions
 *  are called VLIW instructions, as one RAM line coordinates to hundreds of individual
 *  ALU instructions.
 *
 *  When a stage decides which actions to run, the RAM lines containing these actions are
 *  all ORed together to make a single instruction to be run by the ALUs.  This is the root
 *  of action dependency.  If two actions in the same packet operate on the same ALU,
 *  then their corresponding instruction opcodes will be ORed together, causing the instruction
 *  to be garbled and incorrect.  (N.B.  There is a possibility of removing action dependencies,
 *  if it is known that this ORing won't have any semantic change to the instruction)
 *
 *  Each instruction memory line has two colors.  Two actions can be stored per RAM line as
 *  the actions on that RAM line can have a different color.  This will only work if the
 *  intersection of the PHV writes for these actions are an empty set, as each individual
 *  ALU instruction can be marked a certain color.
 *
 *  Furthermore, actions can be shared across multiple tables, as long as the action opcodes
 *  are identical.  The main corner case for this is a noop action, which usually appears
 *  in several tables.  In both gresses, currently, the algorithm always reserves the first
 *  imem slot with the 0 color to be noop.  Gateways that inhibit can potentially run an
 *  action as well, if the pfe for the imem is always defaulted on.  Thus when the payload
 *  is all 0s, the instruction just runs a noop
 */
struct InstructionMemory {
    static constexpr int IMEM_ROWS = 32;
    static constexpr int IMEM_COLORS = 2;
    static constexpr int NOOP_ROW = 0;
    static constexpr int NOOP_COLOR = 0;
    static constexpr int ROW_ADDR_SHIFT = 1;
    static constexpr int COLOR_ADDR_SHIFT = 0;
    std::set<cstring> atcam_updates;

    Alloc2D<cstring, IMEM_ROWS, IMEM_COLORS> ingress_imem_use;
    Alloc2D<cstring, IMEM_ROWS, IMEM_COLORS> egress_imem_use;

    Alloc2D<bitvec, IMEM_ROWS, IMEM_COLORS> ingress_imem_slot_inuse;
    Alloc2D<bitvec, IMEM_ROWS, IMEM_COLORS> egress_imem_slot_inuse;

    /** Instruction Memory requires two things:
     *    1. The RAM line position/color of a word
     *    2. The code for running this instruction that is written on the RAM line.
     *
     *  Each match saves with it an action to run.  Rather than store a full address
     *  per match key, which would be 6 bits apiece, if the total number of possible
     *  hit actions are <= 8, then the address just needs to be a unique code between
     *  0 and ceil_log2(hit_actions).
     *
     *  The row and color correspond to the instruction memory row and color, while
     *  the mem_code is used by the context JSON to know what to write on the SRAM for
     *  running this particular action.
     */
    struct Use {
        struct VLIW_Instruction {
            bitvec non_noop_instructions;
            int row;
            int color;
            int mem_code = -1;

            // The address for the RAM line is in this format
            unsigned gen_addr() const {
                return (color << COLOR_ADDR_SHIFT) | (row << ROW_ADDR_SHIFT);
            }
            VLIW_Instruction(bitvec nni, int r, int c)
                : non_noop_instructions(nni), row(r), color(c) {}
        };
        std::map<cstring, VLIW_Instruction> all_instrs;

        void clear() {
            all_instrs.clear();
        }
    };

    std::map<const IR::MAU::ActionData *, const Use *> shared_action_profiles;
        // std::map<cstring, InstructionMemory::Use::VLIW_Instruction>> shared_action_profiles;

    Alloc2Dbase<cstring> &imem_use(gress_t gress) {
        if (gress == INGRESS || gress == GHOST)
            return ingress_imem_use;
        return egress_imem_use;
    }

    Alloc2Dbase<bitvec> &imem_slot_inuse(gress_t gress) {
        if (gress == INGRESS || gress == GHOST)
            return ingress_imem_slot_inuse;
        return egress_imem_slot_inuse;
    }
    bool is_noop_slot(int row, int color);
    bool find_row_and_color(bitvec current_bv, gress_t gress,
                                int &row, int &color, bool &first_noop);

 public:
    bool allocate_imem(const IR::MAU::Table *tbl, Use &alloc, PhvInfo &phv, bool gw_linked,
        ActionData::FormatType_t format_type, SplitAttachedInfo &sai);
    bool shared_instr(const IR::MAU::Table *tbl, Use &alloc, bool gw_linked);
    void update(cstring name, const Use &alloc, gress_t gress);
    void update(cstring name, const TableResourceAlloc *alloc, gress_t gress);
    void update(cstring name, const TableResourceAlloc *alloc, const IR::MAU::Table *tbl);
    void update(const IR::MAU::Table *tbl);
    InstructionMemory() { }
};

#endif /* BF_P4C_MAU_INSTRUCTION_MEMORY_H_ */
