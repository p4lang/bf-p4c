#ifndef EXTENSIONS_BF_P4C_MAU_ACTION_ANALYSIS_H_
#define EXTENSIONS_BF_P4C_MAU_ACTION_ANALYSIS_H_

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/safe_vector.h"

class PhvInfo;
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
 *
 *  This pass can run before and after PHV allocation, and before and after table placement.
 *  The pass is also designed to run when action format allocation is done before PHV
 *  allocation, but a PHV allocation has been completed
 */
class ActionAnalysis : public MauInspector, TofinoWriteContext {
 public:
    static constexpr int LOADCONST_MAX = 20;
    static constexpr int CONST_SRC_MAX = 3;
    static constexpr int JBAY_CONST_SRC_MIN = 2;
    static constexpr int MAX_PHV_SOURCES = 2;
    /** A way to encapsulate the information contained within a single operand of an instruction,
     *  whether the instruction is read from or written to.  Also contains the information on
     *  what particular bits of the mask are encapsulated.
     */
    struct ActionParam {
        enum type_t { PHV, ACTIONDATA, CONSTANT, TOTAL_TYPES } type;
        const IR::Expression *expr;
        enum speciality_t { NO_SPECIAL, HASH_DIST, METER_COLOR, RANDOM, METER_ALU }
             speciality = NO_SPECIAL;

        ActionParam() : expr(nullptr) {}
        ActionParam(type_t t, const IR::Expression *e)
            : type(t), expr(e) {}

        ActionParam(type_t t, const IR::Expression *e, speciality_t s)
            : type(t), expr(e), speciality(s) {}

        int size() const {
            BUG_CHECK(expr->type, "Untyped expression in backend action");
            return expr->type->width_bits();
        }

        friend std::ostream &operator<<(std::ostream &out, const ActionParam &);

        // void dbprint(std::ostream &out) const;
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
        safe_vector<ActionParam> reads;
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

        bool is_shift() {
            return name == "shru" || name == "shrs" || name == "shl";
        }

        friend std::ostream &operator<<(std::ostream &out, const FieldAction &);
    };

    /** Information on the PHV fields and action data that are read by an individual
     *  field instruction.  write_bits correspond to the bits in the container being written
     *  and read_bits are the bits of one of the sources.  This information is used
     *  for verification and combining the PHV fields into MultiOperands.
     */
    struct Alignment {
        le_bitrange write_bits;
        le_bitrange read_bits;
        Alignment(le_bitrange wb, le_bitrange rb) : write_bits(wb), read_bits(rb) {}
    };

    /** Information on all PHV reads affecting a single container.  Again used for verification
     *  and combining fields into MultiOperand.  Understood to be the bits written and read by
     *  the entire container, rather than in individual instruction in the container.  From
     *  these total alignment structures, we can determine if deposit-fields or bitmasked-sets
     *  are possible/necessary
     */
    struct TotalAlignment {
        safe_vector<Alignment> indiv_alignments;
        bitvec write_bits;
        bitvec read_bits;

        int right_shift = 0;
        bool is_src1 = false;

        void add_alignment(le_bitrange wb, le_bitrange rb) {
            indiv_alignments.emplace_back(wb, rb);
            write_bits.setrange(wb.lo, wb.size());
            read_bits.setrange(rb.lo, rb.size());
        }

        bool equiv_bit_totals() const { return write_bits.popcount() == read_bits.popcount(); }

        bool aligned() const {
            return right_shift == 0;
        }

        bool contiguous() const {
            return write_bits.is_contiguous();
        }

        bool wrapped_contiguous(PHV::Container container) const;
        bool deposit_field_src1(PHV::Container container) const;
        bool deposit_field_src2(PHV::Container container) const;
        bool verify_individual_alignments(PHV::Container &container);
        bool is_wrapped_shift(PHV::Container container, int *lo = nullptr, int *hi = nullptr) const;

        int bitrange_size() const {
            BUG_CHECK(write_bits.is_contiguous(), "Converting a bitvec to a bitrange requires "
                      "the bitrange to be continuous");
            return write_bits.max().index() - write_bits.min().index() + 1;
        }

        TotalAlignment operator |(const TotalAlignment &ta) {
            TotalAlignment rv;
            rv.indiv_alignments.insert(rv.indiv_alignments.end(), indiv_alignments.begin(),
                                       indiv_alignments.end());
            rv.indiv_alignments.insert(rv.indiv_alignments.begin(), ta.indiv_alignments.begin(),
                                       ta.indiv_alignments.end());

            rv.write_bits = write_bits | ta.write_bits;
            rv.read_bits = read_bits | ta.read_bits;
            return rv;
        }
    };

    /** Information on the action data field contained within the instruction.  The action data
     *  could be affected by multiple individual fields.  Assumes that only one action data field
     *  appears in each instruction, as the ALU can only use one action data field.
     */
    struct ActionDataInfo {
        bool initialized = false;
        TotalAlignment alignment;

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

    /** Information on where a particular constant is used within a container instruction
     */
    struct ConstantPosition {
        unsigned value;
        le_bitrange range;
        ConstantPosition(unsigned v, le_bitrange r) : value(v), range(r) { }
    };

    /** Information on all constants within a single container instruction
     */
    struct ConstantInfo {
        bool initialized = false;
        TotalAlignment alignment;
        safe_vector<ConstantPosition> positions;
        unsigned build_constant();
        unsigned build_shiftable_constant();
        // built as part of the check_constant_to_actiondata function
        unsigned constant_value;
        unsigned valid_instruction_constant(int container_size) const;
    };


    /** Information on all of the individual reads and writes within a single PHV container
     *  in an action function. Essentially coordinate to all the action that can happen
     *  within a single VLIW ALU
     */
    struct ContainerAction {
        bool verbose = false;
        bool to_deposit_field = false;  ///> determined by tofino_compliance check
        bool to_bitmasked_set = false;  ///> determined by tofino_compliance_check
        // If the src1 = dest, but isn't directly specified by the parameters.  Only necessary
        // when to_deposit_field = true
        bool implicit_src1 = false;  ///> determined by tofino_compliance_check
        // If the src2 = dest, but isn't directly specified by the parameters.  Only necessary
        // when to_deposit_field == true
        bool implicit_src2 = false;  ///> determined by tofino_compliance_check
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
                            TOO_MANY_PHV_SOURCES = (1 << 4),
                            IMPOSSIBLE_ALIGNMENT = (1 << 5),
                            CONSTANT_TO_ACTION_DATA = (1 << 6),
                            MULTIPLE_ACTION_DATA = (1 << 7),
                            ILLEGAL_OVERWRITE = (1 << 8),
                            BIT_COLLISION = (1 << 9),
                            OPERAND_MISMATCH = (1 << 10),
                            UNHANDLED_ACTION_DATA = (1 << 11),
                            DIFFERENT_READ_SIZE = (1 << 12),
                            MAU_GROUP_MISMATCH = (1 << 13),
                            PHV_AND_ACTION_DATA = (1 << 14),
                            PARTIAL_OVERWRITE = (1 << 15),
                            MULTIPLE_SHIFTS = (1 << 16),
                            ILLEGAL_ACTION_DATA = (1 << 17),
                            REFORMAT_CONSTANT = (1 << 18),
                            UNRESOLVED_REPEATED_ACTION_DATA = (1 << 19) };
        unsigned error_code = NO_PROBLEM;
        cstring name;
        ActionDataInfo adi;
        ConstantInfo ci;
        bitvec invalidate_write_bits;
        std::map<PHV::Container, TotalAlignment> phv_alignment;

        int counts[ActionParam::TOTAL_TYPES] = {0, 0, 0};
        safe_vector<FieldAction> field_actions;
        int total_types() {
            return counts[ActionParam::PHV] + counts[ActionParam::ACTIONDATA]
                   + counts[ActionParam::CONSTANT];
        }

        int operands() const {
            if (field_actions.size() == 0)
                BUG("Cannot call operands function on empty container process");
            return field_actions[0].reads.size();
        }

        int ad_sources() const {
            return std::min(1, counts[ActionParam::ACTIONDATA] + counts[ActionParam::CONSTANT]);
        }

        int read_sources() const {
            return ad_sources() + counts[ActionParam::PHV];
        }

        bool is_shift() const {
            return name == "shru" || name == "shrs" || name == "shl";
        }

        bool has_ad_or_constant() const {
            return ad_sources() > 0;
        }

        bool partial_overwrite() const {
            return ((error_code & PARTIAL_OVERWRITE) != 0 && !to_deposit_field) || to_bitmasked_set;
        }

        bool unresolved_ad() const {
            return (error_code & UNRESOLVED_REPEATED_ACTION_DATA) != 0;
        }

        bool ad_renamed() const {
            return adi.field_affects > 1 || unresolved_ad();
        }

        bool no_sources() const {
            return name == "invalidate";
        }

        void set_mismatch(ActionParam::type_t type) {
            if (type == ActionParam::PHV)
                error_code |= READ_PHV_MISMATCH;
            else if (type == ActionParam::ACTIONDATA)
                error_code |= ACTION_DATA_MISMATCH;
            else
                error_code |= CONSTANT_MISMATCH;
        }

        bool action_data_isolated() {
            return name != "set";
        }

        bool set_invalidate_write_bits(le_bitrange write) {
            if (name != "invalidate") return false;
            invalidate_write_bits.setrange(write.lo, write.size());
            return true;
        }

        // FIXME: Can potentially use rotational shifts at some point
        // bool is_contig_rotate(bitvec check, int &shift, int size);
        // bitvec rotate_contig(bitvec orig, int shift, int size);

        void verify_speciality(PHV::Container container, cstring action_name);
        bool verify_shift(cstring &error_message, PHV::Container container, const PhvInfo &phv);
        bool verify_phv_mau_group(PHV::Container container);
        bool verify_one_alignment(TotalAlignment &tot_alignment, int size, int &unaligned_count,
            int &non_contiguous_count);
        void move_source_to_bit(safe_vector<int> &bit_uses, TotalAlignment &ta);
        bool verify_source_to_bit(int operands, PHV::Container container);
        bool verify_overwritten(PHV::Container container, const PhvInfo &phv);
        bool verify_only_read(const PhvInfo &phv);
        bool verify_possible(cstring &error_message, PHV::Container container,
                             cstring action_name, const PhvInfo &phv);

        bool verify_set_alignment(PHV::Container &container, TotalAlignment &ad_alignment);
        void determine_src1();
        bool verify_alignment(PHV::Container &container);

        bitvec total_write() const;
        bool convert_constant_to_actiondata() const {
            return (error_code & CONSTANT_TO_ACTION_DATA) != 0;
        }
        friend std::ostream &operator<<(std::ostream &out, const ContainerAction&);
    };

    typedef ordered_map<const IR::MAU::Instruction *, FieldAction> FieldActionsMap;
    typedef std::map<PHV::Container, ContainerAction> ContainerActionsMap;

 private:
    const PhvInfo &phv;
    bool phv_alloc = false;
    bool ad_alloc = false;
    bool warning = false;

    bool action_data_misaligned = false;
    bool verbose = false;
    bool error_verbose = false;

    FieldActionsMap *field_actions_map = nullptr;
    ContainerActionsMap *container_actions_map = nullptr;
    const IR::MAU::Table *tbl;
    FieldAction field_action;
    ordered_set<std::pair<cstring, le_bitrange>> single_ad_params;
    ordered_set<std::pair<cstring, le_bitrange>> multiple_ad_params;

    void initialize_phv_field(const IR::Expression *expr);
    void initialize_action_data(const IR::Expression *expr);
    ActionParam::speciality_t classify_attached_output(const IR::MAU::AttachedOutput *);
    bool preorder(const IR::MAU::Action *) override { visitOnce(); return true; }
    bool preorder(const IR::MAU::Table *) override { visitOnce(); return true; }
    bool preorder(const IR::MAU::TableSeq *) override { visitOnce(); return true; }
    bool preorder(const IR::Annotation *) override { return false; }

    bool preorder(const IR::Slice *) override;
    bool preorder(const IR::MAU::ActionArg *) override;
    bool preorder(const IR::Cast *) override;
    bool preorder(const IR::Expression *) override;
    bool preorder(const IR::Member *) override;
    bool preorder(const IR::MAU::ActionDataConstant *) override;
    bool preorder(const IR::Constant *) override;
    bool preorder(const IR::MAU::AttachedOutput *) override;
    bool preorder(const IR::MAU::HashDist *) override;
    bool preorder(const IR::MAU::RandomNumber *) override;
    bool preorder(const IR::MAU::StatefulAlu *) override;
    bool preorder(const IR::MAU::Instruction *) override;
    bool preorder(const IR::MAU::StatefulCall *) override;
    bool preorder(const IR::Primitive *) override;
    void postorder(const IR::MAU::Instruction *) override;
    void postorder(const IR::MAU::Action *) override;

    bool initialize_invalidate_alignment(const ActionParam &write, ContainerAction &cont_action);
    bool initialize_alignment(const ActionParam &write, const ActionParam &read,
        ContainerAction &cont_action, cstring &error_message, PHV::Container container,
        cstring action_name);
    bool init_phv_alignment(const ActionParam &read, ContainerAction &cont_action,
                            le_bitrange write_bits, cstring &error_message);
    bool init_ad_alloc_alignment(const ActionParam &read, ContainerAction &cont_action,
        le_bitrange write_bits, cstring action_name, PHV::Container container);
    bool init_constant_alignment(const ActionParam &read, ContainerAction &cont_action,
        le_bitrange write_bits, cstring action_name, PHV::Container container);
    bool init_simple_alignment(const ActionParam &read, ContainerAction &cont_action,
        le_bitrange write_bits);
    void initialize_constant(const ActionParam &read, ContainerAction &cont_action,
        le_bitrange write_bits, le_bitrange read_bits);

    bool valid_instruction_constant(unsigned value, int max_shift, int min_shift,
                                    int complement_size);
    void check_constant_to_actiondata(ContainerAction &cont_action, PHV::Container container);
    void add_to_single_ad_params(ContainerAction &cont_action);
    void check_single_ad_params(ContainerAction &cont_action);

    void verify_P4_action_for_tofino(cstring action_name);
    bool verify_P4_action_without_phv(cstring action_name);
    bool verify_P4_action_with_phv(cstring action_name);

 public:
    const IR::Expression *isActionParam(const IR::Expression *expr,
        le_bitrange *bits_out = nullptr, ActionParam::type_t *type = nullptr);
    const IR::MAU::ActionArg *isActionArg(const IR::Expression *expr,
        le_bitrange *bits_out = nullptr);

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
    void set_error_verbose() { error_verbose = true; }
    bool warning_found() { return warning; }

    ActionAnalysis(const PhvInfo &p, bool pa, bool aa, const IR::MAU::Table *t)
        : phv(p), phv_alloc(pa), ad_alloc(aa), tbl(t) { visitDagOnce = false; }
};

#endif /* EXTENSIONS_BF_P4C_MAU_ACTION_ANALYSIS_H_ */
