#ifndef EXTENSIONS_BF_P4C_MAU_ACTION_ANALYSIS_H_
#define EXTENSIONS_BF_P4C_MAU_ACTION_ANALYSIS_H_

#include "mau_visitor.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/phv/phv_fields.h"

struct TableResourceAlloc;

/** The purpose of this class is to look through the actions specified by the table and
 *  determine if they are Tofino compliant.  The analysis can be run before and after
 *  phv allocation, as well as before and after action data formats are decided.
 *
 *  Tofino compliant is defined in the following way
 *      - One write / up to 2 reads per action on a container
 *      - Only one source from action data, other can be from PHV
 *      - Alignment restrictions on these sources
 *      - Only one action per container
 *
 *  The pass also constructs a field_actions/container_actions structure, depending on before
 *  or after PHV allocation.  The container actions is especially useful, as it breaks the
 *  instruction into a container by container basis.  The instructions after instruction
 *  selection are done on a field by field basis, and thus having a container view of the
 *  actions is necessary for having a correct view of the action data requirements, as well
 *  as reshaping the instructions from field by field to container by container
 */
class ActionAnalysis : public MauInspector, TofinoWriteContext {
 public:
    static constexpr int LOADCONST_MAX = 20;
    static constexpr int CONST_SRC_MAX = 3;
    /** A way to encapsulate the information contained within a single operand of an instruction,
     *  whether the instruction is read from or written to.  Also contains the information on
     *  what particular bits of the mask are encapsulated.
     */
    struct ActionParam {
        enum type_t { PHV, ACTIONDATA, CONSTANT, TOTAL_TYPES } type;
        const IR::Expression *expr;

        ActionParam() : expr(nullptr) {}
        ActionParam(type_t t, const IR::Expression *e)
            : type(t), expr(e) {}

        int size() const {
            return expr->type->width_bits();
        }

        void dbprint(std::ostream &out) const;
        const IR::Expression *unsliced_expr() const;
    };

    /** Information on the entire instruction, essentially what field is written and from which
     *  fields the field is written from.  These can be broken down and analyzed on a container
     *  by container basis.
     */
    struct FieldAction {
        bool write_found = false;
        cstring name;
        ActionParam write;
        vector<ActionParam> reads;
        void clear() {
            write_found = false;
            reads.clear();
        }

        void setWrite(ActionParam w) {
            write_found = true;
            write = w;
        }

        bool requires_split = false;
        bool constant_to_ad = false;

        void dbprint(std::ostream &out) const;
    };

    /** Information on the PHV fields and action data that are read by an individual
     *  field instruction.  write_bits correspond to the bits in the container being written
     *  and read_bits are the bits of one of the sources.  This information is used
     *  for verification and combining the PHV fields into MultiOperands.
     */
    struct Alignment {
        bitvec write_bits;
        bitvec read_bits;
        Alignment(bitvec wb, bitvec rb) : write_bits(wb), read_bits(rb) {}
    };

    /** Information on all PHV reads affecting a single container.  Again used for verification
     *  and combining fields into MultiOperand.  Understood to be the bits written and read by
     *  the entire container, rather than in individual instruction in the container.  From
     *  these total alignment structures, we can determine if deposit-fields or bitmasked-sets
     *  are possible/necessary
     */
    struct TotalAlignment {
        vector<Alignment> indiv_alignments;
        bool aligned = false;
        bitvec write_bits;
        bitvec read_bits;

        void add_alignment(const bitvec &wb, const bitvec &rb) {
            indiv_alignments.emplace_back(wb, rb);
            write_bits |= wb;
            read_bits |= rb;
        }
    };
    /** Information on the action data field contained within the instruction.  The action data
     *  could be affected by multiple individual fields.  Assumes that only one action data field
     *  appears in each instruction, as the ALU can only use one action data field.
     */
    struct ActionDataInfo {
        bool initialized = false;
        TotalAlignment ad_alignment;

        cstring action_data_name;
        bool immediate = false;
        int start = -1;
        int total_field_affects = 0;
        int field_affects = 0;
        int size  = -1;

        void initialize(cstring adn, bool imm, int s, int tfa) {
            initialized = true;
            action_data_name = adn;
            immediate = imm;
            start = s;
            total_field_affects = tfa;
            field_affects = 1;
        }
    };



    /** Information on all of the indivdidual reads and writes within a single PHV container
     *  in an action function.  Essentially coordinate to all the action that can happen
     *  within a single VLIW ALU
     */
    struct ContainerAction {
        bool to_deposit_field = false;  ///> determined by tofino_compliance check
        bool to_bitmasked_set = false;  ///> determined by tofino_compliance_check
        bool impossible = false;
        bool unhandled_action = false;
        bool constant_to_ad = false;

        ///> Eventually we want to craft correct backtrack/error messages from all
        ///> of these error messages.  In the meantime, used for tracking action
        ///> data issues
        enum error_code_t { NO_PROBLEM = 0,
                            MULTIPLE_CONTAINER_ACTIONS = 1,
                            READ_PHV_MISMATCH = (1 << 1),
                            ACTION_DATA_MISMATCH = (1 << 2),
                            CONSTANT_MISMATCH = (1 << 3),
                            TOO_MANY_SOURCES = (1 << 4),
                            IMPOSSIBLE_ALIGNMENT = (1 << 5),
                            CONSTANT_TO_ACTION_DATA = (1 << 6),
                            MULTIPLE_ACTION_DATA = (1 << 7) };
        unsigned error_code = NO_PROBLEM;
        cstring name;
        ActionDataInfo adi;
        TotalAlignment constant_alignment;
        std::map<PHV::Container, TotalAlignment> phv_alignment;

        int counts[ActionParam::TOTAL_TYPES] = {0, 0, 0};
        vector<FieldAction> field_actions;
        int total_types() {
            return counts[ActionParam::PHV] + counts[ActionParam::ACTIONDATA]
                   + counts[ActionParam::CONSTANT];
        }

        int operands() {
            if (field_actions.size() == 0)
                BUG("Cannot call operands function on empty container process");
            return field_actions[0].reads.size();
        }

        bool is_shift() {
            return name == "shru" || name == "shrs" || name == "shl";
        }


        bool constant_set = false;
        int constant_used = 0;

        // FIXME: Can potentially use rotational shifts at some point
        // bool is_contig_rotate(bitvec check, int &shift, int size);
        // bitvec rotate_contig(bitvec orig, int shift, int size);

        bool verify_one_alignment(TotalAlignment &tot_alignment, int size, int &unaligned_count,
            bool bitmasked_set = false);
        bool total_overwritten(PHV::Container container);
        bool verify_all_alignment(bool bitmasked_set = false);

        bitvec total_write() const;
        bool convert_constant_to_actiondata() {
            return (error_code & CONSTANT_TO_ACTION_DATA) != 0;
        }
    };

    typedef ordered_map<const IR::MAU::Instruction *, FieldAction> FieldActionsMap;
    typedef std::map<PHV::Container, ContainerAction> ContainerActionsMap;

 private:
    const PhvInfo &phv;
    bool phv_alloc = false;
    bool ad_alloc = false;

    bool action_data_misaligned = false;
    bool verbose = false;

    FieldActionsMap *field_actions_map = nullptr;
    ContainerActionsMap *container_actions_map = nullptr;
    const IR::MAU::Table *tbl;
    FieldAction field_action;

    bool is_sliced = false;
    int lo = -1; int hi = -1;
    void initialize_phv_field(const IR::Expression *expr);
    void initialize_action_data(const IR::Expression *expr);
    const IR::Expression *isActionParam(const IR::Expression *expr,
        bitrange *bits_out = nullptr, ActionParam::type_t *type = nullptr);

    bool preorder(const IR::MAU::Action *) override { visitOnce(); return true; }
    bool preorder(const IR::MAU::Table *) override { visitOnce(); return true; }
    bool preorder(const IR::MAU::TableSeq *) override { visitOnce(); return true; }

    bool preorder(const IR::Slice *) override;
    bool preorder(const IR::ActionArg *) override;
    bool preorder(const IR::Expression *) override;
    bool preorder(const IR::MAU::ActionDataConstant *) override;
    bool preorder(const IR::Constant *) override;
    bool preorder(const IR::MAU::AttachedOutput *) override;
    bool preorder(const IR::MAU::HashDist *) override;
    bool preorder(const IR::MAU::StatefulAlu *) override;
    bool preorder(const IR::MAU::Instruction *) override;
    bool preorder(const IR::Primitive *) override;
    void postorder(const IR::MAU::Instruction *) override;
    void postorder(const IR::MAU::Action *) override;

    bool verify_phv_read_instr(const ActionParam &write, const ActionParam &read,
            ContainerAction &cont_action);
    bool verify_action_data_instr(const ActionParam &write, const ActionParam &read,
            ContainerAction &cont_action, cstring action_name, PHV::Container container);
    bool verify_constant_instr(const ActionParam &write, const ActionParam &read,
            ContainerAction &cont_action);
    void action_data_align(const ActionParam &write, ContainerAction &cont_action);

    bool tofino_instruction_constant(int value, int max_shift, int container_size);
    bool check_constant_to_actiondata(ContainerAction &cont_action, PHV::Container container);
    bool check_container_instruction();
    bool check_2_PHV_instruction(ContainerAction &cont_action, PHV::Container container);
    bool check_1_PHV_instruction(ContainerAction &cont_action, PHV::Container container);
    bool check_0_PHV_instruction(ContainerAction &cont_action);

    bool verify_container_action(ContainerAction &cont_action, PHV::Container container);
    void verify_P4_action_for_tofino(cstring action_name);

    bool verify_P4_action_without_phv();
    bool verify_P4_action_with_phv(cstring action_name);

 public:
    bool misaligned_actiondata() {
        return action_data_misaligned;
    }

    void set_field_actions_map(FieldActionsMap *fam) {
        if (ad_alloc == true)
            return;
        field_actions_map = fam;
    }

    void set_container_actions_map(ContainerActionsMap *cam) {
        if (phv_alloc == false)
            return;
        container_actions_map = cam;
    }

    void set_verbose() { verbose = true; }

    ActionAnalysis(const PhvInfo &p, bool pa, bool aa, const IR::MAU::Table *t)
        : phv(p), phv_alloc(pa), ad_alloc(aa), tbl(t) { visitDagOnce = false; }
};

#endif /* EXTENSIONS_BF_P4C_MAU_ACTION_ANALYSIS_H_ */
