#ifndef EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_
#define EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_

#include <array>
#include <iterator>
#include <map>
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/ordered_set.h"
#include "lib/safe_vector.h"
#include "ir/ir.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/phv/phv.h"

/**
 * The purpose of this class is the base abstract class for any parameter that can appear
 * as any section of bits on the action data bus.  This by itself does not coordinate to any
 * particular location in the bus or relationship to PHV, but is just information that can
 * be classified as ActionData
 */
class ActionDataParam {
 /*
 // Probably belong outside of this class, in another subclass
 protected:
    le_bitrange _phv_bits = { 0, 0 };
    int _right_shift = 0;
 */

 public:
    // virtual const ActionDataParam *shared_param(const ActionDataParam *, int &start_bit) = 0;
    virtual int size() const = 0;
    virtual const ActionDataParam *split(int lo, int hi) const = 0;
    virtual bool only_one_overlap_solution() const = 0;

    virtual bool is_next_bit_of_param(const ActionDataParam *) const = 0;
    virtual const ActionDataParam *get_extended_param(unsigned extension,
        const ActionDataParam *) const = 0;
    virtual const ActionDataParam *overlap(const ActionDataParam *ad, bool guaranteed_one_overlap,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const = 0;
    virtual bool equiv_value(const ActionDataParam *) const = 0;
    virtual void dbprint(std::ostream &out) const = 0;
    template<typename T> const T *to() const { return dynamic_cast<const T*>(this); }
    template<typename T> bool is() const { return to<T>() != nullptr; }
};

/**
 * This class is to represent a slice of an IR::MAU::ActionArg, essentially any argument that
 * appears as a direct argument of an action and is used in an ALU operation:
 *
 * Let's take the following example:
 *
 * action act(bit<8> param1, bit<8> param2) {
 *     hdr.f1 = param1;
 *     hdr.f2 = param2;
 * }
 *
 * All valid bitranges of param1 and param2, e.g. param1[7:0] or param2[5:4] would be valid
 * instantiations of the Argument class
 */
class Argument : public ActionDataParam {
    cstring _name;
    le_bitrange _param_field;


 public:
    cstring name() const { return _name; }
    le_bitrange param_field() const { return _param_field; }

    Argument(cstring n, le_bitrange pf) : _name(n), _param_field(pf) {}

    const ActionDataParam *split(int lo, int hi) const override {
        le_bitrange split_range = { _param_field.lo + lo, _param_field.lo + hi };
        BUG_CHECK(_param_field.contains(split_range), "Illegally splitting a parameter, as the "
                  "split contains bits outside of the range");
        return new Argument(_name, split_range);
    }

    bool only_one_overlap_solution() const override { return true; }

    bool is_next_bit_of_param(const ActionDataParam *ad) const override {
        if (size() != 1) return false;
        const Argument *arg = ad->to<Argument>();
        if (arg == nullptr) return false;
        return arg->_name == _name && arg->_param_field.hi + 1 == _param_field.lo;
    }

    const ActionDataParam *get_extended_param(unsigned extension,
             const ActionDataParam *) const override {
         auto rv = new Argument(*this);
         rv->_param_field.hi += extension;
         return rv;
    }

    const ActionDataParam *overlap(const ActionDataParam *ad, bool guaranteed_one_overlap,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const override;
    bool equiv_value(const ActionDataParam *ad) const override {
        const Argument *arg = ad->to<Argument>();
        if (arg == nullptr) return false;
        return _name == arg->_name && _param_field == arg->_param_field;
    }
    int size() const override { return _param_field.size(); }
    void dbprint(std::ostream &out) const override { out << _name << " " << _param_field; }
};

/**
 * This class represents a section of IR::MAU::ActionDataConstant, or an IR::Constant that
 * cannot be created as the src1 operand of an ALU operation.  The constant instead must come
 * from Action Ram.
 *
 * Similar to IR::Constant, the constant has a value and a bit size.  Due to the size of the
 * constant theoretically being infinite, a bitvec is used to store the value (though in
 * theory, an mpz_class could have been used as well 
 */
class Constant : public ActionDataParam {
    bitvec _value;
    size_t _size;
    le_bitrange range() const { return {0, static_cast<int>(_size) - 1}; }

 public:
    Constant(int v, size_t sz) : _value(v), _size(sz) {}
    Constant(bitvec v, size_t sz) : _value(v), _size(sz) {}

    const ActionDataParam *split(int lo, int hi) const override;
    bool only_one_overlap_solution() const override { return false; }
    bool is_next_bit_of_param(const ActionDataParam *ad) const override;
    const ActionDataParam *get_extended_param(unsigned extension,
        const ActionDataParam *ad) const override;
    const ActionDataParam *overlap(const ActionDataParam *ad, bool only_one_overlap_solution,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const override;
    bool equiv_value(const ActionDataParam *ad) const override;
    bitvec value() const { return _value; }
    int size() const override { return _size; }
    void dbprint(std::ostream &out) const override {
        out << "0x" << _value << " : " << _size << " bits";
    }
};

struct ALUParameter {
    const ActionDataParam *param;
    le_bitrange phv_bits;
    int right_shift;

    ALUParameter(const ActionDataParam *p, le_bitrange pb)
        : param(p), phv_bits(pb), right_shift(0) {}
};

enum ALUOPConstraint_t { ISOLATED, BITMASKED_SET, DEPOSIT_FIELD };

class ActionDataRamSection;

/**
 * This class is the representation of the src1 of a single ALU operation when the src1 comes
 * from the Action Data Bus.  Essentially a single PHV instruction could be represented as,
 * (somewhat):
 *      PHV Container number(phv_bits) = function(ADB SLOT number(slot_bits))
 *
 * This class represents the data contained within slot-hi to slot-lo.  What is known at
 * Action Format allocation are both which container the data is headed to and which bits
 * of the container are used.
 *
 * The purpose of the allocation is to both figure out the slot_bits ( which is just the PHV
 * bits barrel_shifted right by a certain amount), as well as a potential RAM location to store
 * this Action Data.
 */
class ActionDataForSingleALU2 {
    // The location of the P4 parameters, i.e. what bits contain particular bitranges.  This
    // is knowledge required for the driver to pack the RAM
    safe_vector<ALUParameter> _params;
    // The bits that are to be written in the PHV Container
    bitvec _phv_bits;
    // The amount to barrel-shift right the phv_bits in order to know the associated slot_bits
    int _right_shift;
    PHV::Container _container;
    // Information on how the data is used, in order to potentially pack in RAM space other
    // ActionDataForSingleALU2s
    ALUOPConstraint_t _constraint;

 public:
    void add_param(ALUParameter &ap) {
        _params.push_back(ap);
        _phv_bits.setrange(ap.phv_bits.lo, ap.phv_bits.size());
    }
    bool contains_only_one_overlap_solution() const {
        for (auto param : _params) {
            if (param.param->only_one_overlap_solution())
                return true;
        }
        return false;
    }


    bitvec phv_bits() const { return _phv_bits; }
    size_t size() const { return _container.size(); }
    bool is_constrained(ALUOPConstraint_t cons) const {
        return _constraint == cons;
    }
    size_t index() const { return ceil_log2(size()) - 3; }
    ALUOPConstraint_t constraint() const { return _constraint; }

    ActionDataForSingleALU2(PHV::Container cont, ALUOPConstraint_t cons)
        : _right_shift(0), _container(cont), _constraint(cons) { }
    const ActionDataRamSection *create_RamSection(bool shift_to_lsb) const;
    const ActionDataForSingleALU2 *add_right_shift(int right_shift) const;
};

struct SharedActionDataParam {
    const ActionDataParam *param;
    int a_start_bit;
    int b_start_bit;

    SharedActionDataParam(const ActionDataParam *p, int a, int b)
        : param(p), a_start_bit(a), b_start_bit(b) { }
};

using bits_iter_t = safe_vector<const ActionDataParam *>::iterator;

/**
 * The next two classes hold information passed down recursively through any PackingConstraint
 * function call, in order to understand the size of the recursive_constraints vector and
 * how to interpret information.
 */
struct RotationInfo {
 private:
    bits_iter_t bits_begin;
    bits_iter_t bits_end;

 public:
    RotationInfo(safe_vector<const ActionDataParam *>::iterator bb,
        safe_vector<const ActionDataParam *>::iterator be) : bits_begin(bb), bits_end(be) { }

    int size() const { return bits_end - bits_begin; }
    void rotate(int bit_rotation);
    RotationInfo split(int first_bit, int sz) const;
};

struct LocalPacking {
    ///> How wide the packing structure is
    int bit_width;
    ///> The bits that are enabled
    bitvec bits_in_use;

    bool empty() const { return bits_in_use.empty(); }
    le_bitrange max_br_in_use() const {
        return { bits_in_use.min().index(), bits_in_use.max().index() };
    }
    LocalPacking(int bw, bitvec b) : bit_width(bw), bits_in_use(b) {}
    LocalPacking split(int first_bit, int sz) const;

    void dbprint(std::ostream &out) const {
        out << "bits: " << bit_width << " 0x" << bits_in_use;
    }
};

/**
 * Recursive Constraint indicating how data can be moved and rotated in the ActionDataRAMSection.
 * This is due to the multiple levels of action data headed to potentially different sizes of
 * ALU operations.  Please read the ActionDataRamSection comments for further details.
 */
class PackingConstraint {
    ///> The ActionDataRAMSection can be barrel-shifted by any rotation where:
    ///> rotation % rotational_granularity == 0
    int rotational_granularity = -1;

    ///> Information on rotational ability of potential bytes/half-words underneath
    ///> the rotational_granularity
    safe_vector<PackingConstraint> recursive_constraints;

    bool under_rotate(LocalPacking &lp, le_bitrange open_range, int &final_bit,
        int right_shift) const;
    bool over_rotate(LocalPacking &lp, le_bitrange open_range, int &final_bit,
        int right_shift) const;

 public:
    PackingConstraint expand(int current_size, int expand_size) const;
    bool is_rotational() const { return rotational_granularity > 0; }
    bool can_rotate(int bit_width, int init_bit, int final_bit) const;
    void rotate(RotationInfo &ri, int init_bit, int final_bit);
    bool can_rotate_in_range(LocalPacking &lp, le_bitrange open_range, int &final_bit) const;
    int get_granularity() const { return rotational_granularity; }
    int bit_rotation_position(int bit_width, int init_bit, int final_bit, int init_bit_comp) const;
    safe_vector<PackingConstraint> get_recursive_constraints() const {
        return recursive_constraints;
    }

    PackingConstraint merge(const PackingConstraint &pc, const LocalPacking &lp,
        const LocalPacking &pc_lp) const;

    PackingConstraint() { }
    PackingConstraint(int rg, safe_vector<PackingConstraint> &pc)
        : rotational_granularity(rg), recursive_constraints(pc) {}
};

using ActionDataPositions = std::map<int, const ActionDataParam *>;

enum SlotType_t { BYTE, HALF, FULL, SLOT_TYPES, DOUBLE_FULL = SLOT_TYPES, SECT_TYPES = 4 };
size_t slot_size_bits(SlotType_t);

using ActionDataBusInputs = std::array<bitvec, SLOT_TYPES>;

/**
 * This class represents the positions of data in an entry of RAM.
 *
 * During the condense portion of the algorithm, each ActionDataRamSection has not been assigned
 * a position on either an ActionData RAM, or a portion of immediate.  Rather each
 * ActionDataRamSection can be thought of as a vector of bits that have a size, and that this
 * size constrains where this data can eventually appear on a RAM line.
 *
 * Note the following constraint on ALU operations:
 *
 *     - For an ALU operation PHV_Container[hi..lo] = f(ADB[adb_hi..adb_lo])
 *       the action data source must appear at most in a single action data bus location
 *
 * This adb_hi and adb_lo coordinate to a action_RAM_hi and action_RAM_lo, as data gets pulled
 * from the Action Data Table through the Action Data Bus and finally to an ALU.
 *
 * The constraint arising is:
 *     action_RAM_hi / size(PHV_Container) == action_RAM_lo / size(PHV_Container), integer division
 *
 * This guarantees that the data appears in the same action data bus slot.
 *
 * Thus the action_data_bits vector, which will be of size 8, 16, or 32 (or 64 explained later),
 * will eventually have to be packed in the Action RAM on a mod_offset of its size, as it can
 * be thought of as a source of RAM bits for an ALU operation.
 *
 * It is more extensible than the ActionDataForSingleALU, as a section of RAM can be sent to
 * multiple ALUs.  Furthermore, portions of a ActionDataRAMSection can be sent to a single ALU.
 * Say for instance, the following happens.
 *
 * 32 bits of action data:
 *    The first byte can be sent to an 8 bit ALU.
 *    The third and fourth byte can be sent to a 16 bit ALU.
 *    The entire four bytes can be sent to a 32 bit ALU.
 *
 * This would capture 3 separate ActionDataForSingleALU operations within an ActionDataRamSection.
 * Furthermore, the constraints mentioned about action_RAM_lo and action_RAM_hi would have to
 * be captured for all 3 ActionDataForSingleALU operations.  This is the purpose of the
 * PackingConstraint, which has recursive information on how data can possibly be moved in order
 * to more efficiently pack data.
 *
 * Lastly, because bitmasked-sets need to appear in even-odd pairs of ActionDataBus slots, the
 * algorithm currently requires the allocation of these to be contiguous, as contiguous RAM
 * bytes/half-words/full-words are much easier to enforce contiguity on the ActionDataBus.  This
 * leads to up to 64 bit (2 * 32 bit sources)
 */
class ActionDataRamSection {
    ///> A vector of ActionDataParam data bits that are of size 1/nullptr if that bit is not used
    safe_vector<const ActionDataParam *> action_data_bits;
    ///> Recursive PackingConstraint on how data can rotate
    PackingConstraint pack_info;

    ///> map of ActionDataForSingleALU operations with their action data requirements allocated
    ///> in this RAMSection


    bool is_better_merge_than(const ActionDataRamSection *comp) const;

 public:
    safe_vector<const ActionDataForSingleALU2 *> alu_requirements;
    // Made public for unit tests.  Not sure if there is a way around this
    bitvec bits_in_use() const;
    safe_vector<le_bitrange> open_holes() const;
    const ActionDataRamSection *expand_to_size(size_t expand_size) const;
    const ActionDataRamSection *can_rotate(int init_bit, int final_bit) const;
    const ActionDataRamSection *rotate_in_range(le_bitrange range) const;
    const ActionDataRamSection *no_overlap_merge(const ActionDataRamSection *ad) const;
    const ActionDataRamSection *merge(const ActionDataRamSection *ad) const;
    const ActionDataRamSection *condense(const ActionDataRamSection *) const;
    const ActionDataRamSection *better_merge_cand(const ActionDataRamSection *) const;
    void gather_shared_params(const ActionDataRamSection *ad,
        safe_vector<SharedActionDataParam> &shared_params, bool only_one_overlap_solution) const;
    PackingConstraint get_pack_info() const { return pack_info; }

    bool is_data_subset_of(const ActionDataRamSection *ad) const;
    bool contains(const ActionDataRamSection *ad_small, int init_bit_pos, int *final_bit_pos) const;
    bool contains_any_rotation_from_0(const ActionDataRamSection *ad_small, int init_bit_pos,
        int *final_bit_pos) const;
    bool contains(const ActionDataForSingleALU2 *ad_alu, int *first_phv_bit_pos = nullptr) const;

    size_t size() const { return action_data_bits.size(); }
    size_t index() const { return ceil_log2(size()) - 3; }
    size_t byte_sz() const { return size() / 8; }
    ActionDataPositions action_data_positions() const;
    explicit ActionDataRamSection(int s) : action_data_bits(s, nullptr) {}
    ActionDataRamSection(int s, PackingConstraint &pc)
        : action_data_bits(s, nullptr), pack_info(pc) { }
    void add_param(int bit, const ActionDataParam *);
    void add_alu_req(const ActionDataForSingleALU2 *rv) { alu_requirements.push_back(rv); }
    ActionDataBusInputs action_data_bus_inputs() const;
};

enum ActionDataLocation_t { ACTION_DATA_TABLE, IMMEDIATE, AD_LOCATIONS, METER_ALU };

/**
 * Used to keep track of the coordination of ActionDataRamSections and the byte offset
 * in the RAM, either ActionData or Immediate based on the allocation scheme
 */
struct RamSectionPosition {
    const ActionDataRamSection *section;
    int byte_offset = -1;
    explicit RamSectionPosition(const ActionDataRamSection *sect) : section(sect) { }
    size_t total_slots_of_type(SlotType_t slot_type) const;
};

/**
 * The allocation of all RamSections for a single action.
 *
 * Please note the difference between slots/sections.  The slots represent the action data xbar
 * input slots, which come from the position of ActionDataForSingleALU2 objects, while the section
 * denote the ActionDataRamSections, built up of many ActionDataForSingleALU2 objects.
 */
struct SingleActionPositions {
    cstring action_name;
    safe_vector<RamSectionPosition> all_inputs;

    SingleActionPositions(cstring an, safe_vector<RamSectionPosition> ai)
         : action_name(an), all_inputs(ai) { }

    size_t total_slots_of_type(SlotType_t slot_type) const;
    size_t bits_required() const;
    size_t adt_bits_required() const;
    std::array<int, SECT_TYPES> sections_of_size() const;
    std::array<int, SECT_TYPES> minmax_bit_req() const;
    std::array<int, SECT_TYPES> min_bit_of_contiguous_sect() const;
    std::array<bool, SECT_TYPES> can_be_immed_msb(int bits_to_move) const;
    void move_to_immed_from_adt(safe_vector<RamSectionPosition> &rv, size_t slot_sz,
        bool move_min_max_bit_req);
    void move_other_sections_to_immed(int bits_to_move, SlotType_t minmax_sz,
        safe_vector<RamSectionPosition> &immed_vec);
    safe_vector<RamSectionPosition> best_inputs_to_move(int bits_to_move);
};

using AllActionPositions = safe_vector<SingleActionPositions>;

/**
 * Information on the position of a single ActionDataForSingleALU2 on a RAM line.  Due
 * to the constraint, that all of the action data in a single ALU operation has to appear
 * in a single Action Data Bus slot.  Due to the direct extraction through the homerow bus,
 * the following constraint must be satisfied:
 *
 *     - slot_bit_lo / container_size == slot_bit_hi / container_size (integer division)
 *
 * This means that the entirety of a single ALU operation starts a byte and is a particular
 * size.  The start can either be in ActionDataTable RAM or Match RAM (Immediate)
 *
 * Specifically for anything that comes from a Meter ALU, a third location has been provided
 */
struct ActionDataALUPosition {
    // The information on the P4 parameters within this region
    const ActionDataForSingleALU2 *alu_op;
    // Whether the data is in ActionData, Immmediate, or a from a Meter ALU operation
    ActionDataLocation_t ad_loc;
    // The byte offset within the allocation
    size_t start_byte;

 public:
    ActionDataALUPosition(const ActionDataForSingleALU2 *ao, ActionDataLocation_t al, size_t sb)
        : alu_op(ao), ad_loc(al), start_byte(sb) { }
};

using RamSec_vec_t = safe_vector<const ActionDataRamSection *>;
using PossibleCondenses = safe_vector<RamSec_vec_t>;

/**
 * Structure to keep track of a single action allocation for it's action data for a single
 * possible layout.  The orig_inputs is anything that hasn't been yet allocated, and the
 * alloc_inputs is anything that has been allocated during the determination process
 */
struct SingleActionAllocation {
    SingleActionPositions *positions;
    ActionDataBusInputs *all_action_inputs;
    ActionDataBusInputs current_action_inputs = { { bitvec(), bitvec(), bitvec() } };
    safe_vector<RamSectionPosition> orig_inputs;
    safe_vector<RamSectionPosition> alloc_inputs;

    void clear_inputs() {
        orig_inputs.clear();
        alloc_inputs.clear();
    }
    void build_orig_inputs() {
        clear_inputs();
        orig_inputs.insert(orig_inputs.end(), positions->all_inputs.begin(),
                           positions->all_inputs.end());
    }

    void set_positions() {
        BUG_CHECK(orig_inputs.empty() && alloc_inputs.size() == positions->all_inputs.size(),
            "Cannot set the positions of the action as not all have been assigned positions");
        positions->all_inputs.clear();
        positions->all_inputs.insert(positions->all_inputs.end(), alloc_inputs.begin(),
            alloc_inputs.end());
    }
    cstring action_name() const { return positions->action_name; }

    SingleActionAllocation(SingleActionPositions *sap, ActionDataBusInputs *aai)
        : positions(sap), all_action_inputs(aai) {
        build_orig_inputs();
    }
};

class ActionFormat2 {
 public:
    static constexpr int IMMEDIATE_BITS = 32;

    struct Use {
        std::map<cstring, safe_vector<ActionDataALUPosition>> action_data_positions;
        std::array<ActionDataBusInputs, AD_LOCATIONS> action_data_bus_inputs
            = {{ {{ bitvec(), bitvec(), bitvec() }}, {{ bitvec(), bitvec(), bitvec() }} }};
        std::array<int, AD_LOCATIONS> action_data_bytes_in_loc = {{ 0, 0 }};
    };

 private:
    const PhvInfo &phv;
    const IR::MAU::Table *tbl;
    safe_vector<Use> &uses;
    int calc_max_size = 0;
    std::map<cstring, RamSec_vec_t> init_ram_sections;

    std::array<int, AD_LOCATIONS> bytes_per_loc = {{ 0, 0 }};
    safe_vector<ActionDataBusInputs> action_bus_input_bitvecs;
    safe_vector<AllActionPositions> action_bus_inputs;

    std::map<cstring, safe_vector<ActionDataALUPosition>> action_data_positions;

    void create_argument(ActionDataForSingleALU2 &alu, ActionAnalysis::ActionParam &read,
        le_bitrange container_bits);
    void create_constant(ActionDataForSingleALU2 &alu, ActionAnalysis::ActionParam &read,
        le_bitrange container_bits);

    void create_action_data_alus_for_action(ActionAnalysis::ContainerActionsMap &ca_map,
        cstring action_name);
    void analyze_actions();

    void initial_possible_condenses(PossibleCondenses &condenses, const RamSec_vec_t &ram_sects);
    void incremental_possible_condenses(PossibleCondenses &condense, const RamSec_vec_t &ram_sects);

    bitvec bytes_in_use(ActionDataBusInputs &all_inputs) const {
        return all_inputs[BYTE] | all_inputs[HALF] | all_inputs[FULL];
    }
    bool is_better_condense(RamSec_vec_t &ram_sects, const ActionDataRamSection *best,
        size_t best_skip1, size_t best_skip2, const ActionDataRamSection *comp, size_t comp_skip1,
        size_t comp_skip2);
    void condense_action(cstring action_name, RamSec_vec_t &ram_sects);
    void shrink_possible_condenses(PossibleCondenses &pc, RamSec_vec_t &ram_sects,
        const ActionDataRamSection *ad, size_t i_pos, size_t j_pos);
    void set_ram_sect_byte(SingleActionAllocation &single_action_alloc,
        bitvec &allocated_slots_in_action, RamSectionPosition &ram_sect, int byte_position);
    void alloc_adt_slots_of_size(SlotType_t slot_size, SingleActionAllocation &single_action_alloc,
        int max_bytes_required);
    void alloc_immed_slots_of_size(SlotType_t size, SingleActionAllocation &single_action_alloc,
        int max_bytes_required);
    void verify_placement(SingleActionAllocation &single_action_alloc);

    void determine_single_action_input(SingleActionAllocation &single_action_alloc,
        int max_bytes_required);
    bool determine_next_immediate_bytes();
    bool determine_bytes_per_loc(bool &initialized);
    void assign_action_data_table_bytes(AllActionPositions &all_bus_inputs,
        ActionDataBusInputs &total_inputs);
    void assign_immediate_bytes(AllActionPositions &all_bus_inputs,
        ActionDataBusInputs &total_inputs);
    void assign_RamSections_to_bytes();
    void build_potential_format();


 public:
    void allocate_format(int orig_max_size);
    ActionFormat2(const PhvInfo &p, const IR::MAU::Table *t, safe_vector<Use> &u)
        : phv(p), tbl(t), uses(u) {}
};

#endif  /* EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_ */
