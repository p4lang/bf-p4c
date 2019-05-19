#ifndef EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_H_
#define EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_H_

#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "ir/ir.h"
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/cstring.h"
#include "lib/ordered_map.h"
#include "lib/safe_vector.h"

class PhvInfo;

/** The purpose of this structure is to optimize the action data format of a table's action
 *  data table and if possible, an immediate format.  Essentially action data is broken into
 *  3 bit widths matching the size of the PHV containers.  The bytes from each individual
 *  action data must go somewhere onto the action data bus.
 *
 *  P4 tables can have multiple actions, which can range in the type of action data that each
 *  action has.  Tofino must allocate enough space in order to handle the action with the
 *  most action data for every match.  Every action has a different range of action data as well.
 *
 *  The transfer from Action Data Format to Action Bus is through the American Flag Xbar.  The
 *  lowest bytes of action data format are least constrained on where they can go on the
 *  xbar, and higher bytes have fewer locations.  Thus the general consensus is to have action
 *  data headed to 8 bit PHV in lower sections, followed by 16 bit PHV in higher sections, and
 *  32 bit PHV in the highest, if we cannot overlap the 32 bits.
 *
 *  Also, because actions are mutually exclusive, they can share spaces on the action data bus.
 *  However, 8-bit and 16-bit action data cannot overlap on the bus.
 *
 *  Let's consider the following action a1 and a2 both use two 8 bit and 1 16-bit action data.
 *  Thus we want to layout the action data format as:
 *
 *  a1 8 8 16
 *  a2 8 8 16
 *
 *  As this only requires two action data bus bytes for 8 bits and two action data bus bytes
 *  for the 16 bit action data.  If we layout the action as:
 *
 *  a1 16  8 8
 *  a2 8 8 16
 *
 *  Then this requires 4 bytes of action data bus bytes for both the 8 bit and 16 bit action
 *  data, which is suboptimal.
 */

struct ActionFormat {
 public:
    enum cont_type_t {BYTE, HALF, FULL, CONTAINER_TYPES};
    enum ad_source_t {ADT, IMMED, METER, LOCATIONS};
    enum bitmasked_t {NORMAL, BITMASKED, BITMASKED_TYPES};

    enum ad_constraint_t { BITMASKED_SET, ISOLATED };

    static constexpr int CONTAINER_SIZES[3] = {8, 16, 32};
    static constexpr int IMMEDIATE_BYTES = 4;

    /** This data structure describes action data headed to a single ALU operation.
     *  Thus, each struct has a container parameter, as each one can contain a container
     *
     *  Each action data operation is filled with at least one parameter.  This information
     *  is contained within the ArgLoc, or exactly where each ActionArg / other information
     *  headed to an ALU is individually stored
     */
    struct ActionDataForSingleALU {
        struct ArgLoc {
            cstring name;       ///< name of the arg
            // FIXME: Convert these to le_bitranges as this would be correct
            bitvec phv_loc;     ///< The bits which these act on in the phv container
            bitvec slot_loc;    ///< The bits within the action data slot that we use
            int field_bit;      ///< The starting bit of the argument
            bool single_loc = true;
            // Constants
            bool is_constant = false;
            int constant_value = 0;
            ArgLoc(cstring n, bitvec pl, int fb, bool sl)
                : name(n), phv_loc(pl), field_bit(fb), single_loc(sl) {}
            void set_as_constant(int cv) {
                is_constant = true;
                constant_value = cv;
            }
            int field_hi() const { return field_bit + phv_loc.popcount() - 1; }
            int phv_cont_lo() const { return phv_loc.min().index(); }
            int slot_lo() const { return slot_loc.min().index(); }
            int slot_hi() const { return slot_loc.max().index(); }
            le_bitrange slot_br() const {
                BUG_CHECK(slot_loc.is_contiguous(), "Slot location is not contiguous");
                return le_bitrange(slot_lo(), slot_hi());
            }
            int width() const { return phv_loc.popcount(); }
            void dbprint(std::ostream &out) const {
                out << name << "[" << field_bit << ":" << field_hi() << "]";
                out << " PHV 0x" << phv_loc;
                out << " slot 0x" << slot_loc;
            }

            ActionAnalysis::ActionParam::speciality_t speciality
                = ActionAnalysis::ActionParam::NO_SPECIAL;
            bool operator==(const ArgLoc &a) const;

            /** The alias needed for a single action parameter */
            cstring get_asm_name() const {
                cstring ret_name = name;
                if (!single_loc) {
                    int lo = field_bit;
                    int hi = field_hi();
                    ret_name = ret_name + + "." + std::to_string(lo) + "-" + std::to_string(hi);
                }
                return ret_name;
            }
        };

        // the same arithmetic alu can be used to compute on multiple meter alu outputs.
        safe_vector<ArgLoc> arg_locs;
        // the size of the arithmetic alu.
        int alu_size = 0;
        // the phv container used by the arithmetic alu.
        PHV::Container container;
        bool container_valid = false;
        // The 'write' bits of the ALU operation that corresponds to the 'read'
        // bits or slot bit.
        bitvec phv_bits;      ///< Total mask
        // bits used by all arglocs in an ALU operation. Instruction adjustment
        // uses this information to create the correct instruction for the ALU.
        bitvec slot_bits;

        // constraint imposed by the action.
        unsigned constraints = 0;
        // source of the action data.
        unsigned specialities = 0;


        bool is_constrained(ad_constraint_t adc) const {
            return ((1U << adc) & constraints) != 0U;
        }

        void set_constraint(ad_constraint_t adc) {
            constraints |= (1U << adc);
        }

        bool bitmasked_set = false;  ///< If the placement requires a mask as well

        // used for packing params into the same adb slot or ram line.
        bool can_condense_into(const ActionDataForSingleALU &a) const;
        bool contained_within(const ActionDataForSingleALU &a) const;
        bool operator==(const ActionDataForSingleALU &a) const;
        bool contained_exactly_within(const ActionDataForSingleALU &a) const;
        void shift_slot_bits(int shift);
        void set_slot_bits(const ActionDataForSingleALU &a);
        // Everything above is determined during initialization

        // Everything below is determined during the action_format algorithm
        int start = -1;    ///< Byte offset within the action data table
        bool immediate = false;  ///< Whether the byte is within an adt or immediate

        cstring action_name;  ///< Potential rename if multiple action args within one placement
        cstring mask_name;  ///< A name that coordinates the mask to be setup in asm_output
        bool single_rename = false;

        int gen_index() const {
            return ceil_log2(alu_size / 8);
        }

        /** The alias needed in the format of the action for a placement */
        cstring get_action_name() const {
            BUG_CHECK(action_name.isNull() == (arg_locs.size() == 1 && !single_rename),
                      "Action Format arg_loc size doesn't match name");
            if (arg_locs.size() == 1 && !single_rename)
                return arg_locs[0].get_asm_name();
            else
                return action_name;
        }

        bool requires_alias() const {
            return single_rename || arg_locs.size() > 1;
        }

        /** Returns the mask name.  Only can be called on a placement that has bitmasked-set */
        cstring get_mask_name() const {
            BUG_CHECK(bitmasked_set && arg_locs.size() > 1, "Cannot call get_mask_name on "
                      "a placement that has no bitmask");
            return mask_name;
        }

        bool placed() const {
            return start >= 0;
        }

        void dbprint(std::ostream &out) const {
            if (container_valid) {
                out << "ALU:" << container.toString();
            }

            out << " PHV: 0x" << phv_bits << " Slot 0x" << slot_bits;
            out << " ArgLocs: { ";
            size_t index = 0;
            for (auto arg_loc : arg_locs) {
                out << arg_loc;
                if (index != arg_locs.size() - 1)
                    out << ", ";
                index++;
            }
            out << " } ";

            if (placed()) {
                out << " Position: { Start Byte : " << start;
                out << ", Immediate : " << immediate << " } ";
            }
        }
    };

    /** Used to describe a single location on a RAM for a section of Action Data.  Multiple ALUs
     *  may use the same action data, i.e.:
     *      hdr.f1 = param;
     *      hdr.f2 = param;
     *
     *  If f1 and f2 are in different containers, then two separate ALUs are used.  However,
     *  only one section of action data bit placement might be needed, as these ALUs can pull
     *  from the same place.
     *
     *  The purpose of this is to separate the placement of Action Data on a RAM line from the
     *  action data used within an ALU.
     */
    struct ActionDataFormatSlot {
        // represents multiple params packed in the same action line.
        safe_vector<ActionDataForSingleALU *> action_data_alus;
        int slot_size;  ///> A size between 8, 16, and 32 bits, limited by the alu size
        bool bitmasked_set;
        unsigned global_constraints;
        unsigned specialities;

        bitvec balance[ActionFormat::CONTAINER_TYPES];
        bitvec total_range;

        bool is_constrained(ad_constraint_t adc) const {
            return ((1U << adc) & global_constraints) != 0U;
        }

        void set_constraint(ad_constraint_t adc) {
            global_constraints |= (1U << adc);
        }

        int gen_index() const {
            return ceil_log2(slot_size / 8);
        }

        void shift_up(int shift_bits);
        bool deletable = false;

        int byte_start = -1;
        bool immediate = false;

        explicit ActionDataFormatSlot(ActionDataForSingleALU *ad_alu);
    };

    /** Used for a container by container analysis of laying out the action format of a table.
     *  Essentially per action, how many containers are used, what types they are,
     *  and if there is some immediate data, what the max lengths of each type of container
     *  is being used
     */
    struct ActionContainerInfo {
        cstring action;
        enum order_t {FIRST_8, FIRST_16, EITHER, NOT_SET} order = NOT_SET;
        int counts[LOCATIONS][CONTAINER_TYPES] = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}};
        int bitmasked_sets[LOCATIONS][CONTAINER_TYPES] = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}};
        int minmaxes[BITMASKED_TYPES][CONTAINER_TYPES] = {{9, 17, 33}, {9, 17, 33}};
        // int bm_minmaxes[CONTAINER_TYPES] = {9, 17, 33};

        // where in the ram the container can be placed.
        bitvec layouts[LOCATIONS][CONTAINER_TYPES];
        bool meter_reserved = false;

        int maximum = -1;
        bool offset_constraint = false;
        int offset_full_word = -1;

        void dbprint(std::ostream &out) const {
            out << action << std::endl;
            out << "  Action Data Layout: " << std::endl;
            out << "    Counts: ";
            out << counts[ADT][BYTE] << " " << counts[ADT][HALF] << " " << counts[ADT][FULL];
            out << std::endl << "    Layouts: 0x" << layouts[ADT][BYTE] << " 0x"
                << layouts[ADT][HALF] << " 0x" << layouts[ADT][FULL];
            out << std::endl << "  Immediate: " << std::endl;
            out << "    Counts: ";
            out << counts[IMMED][BYTE] << " " << counts[IMMED][HALF] << " "
                << counts[IMMED][FULL];
            out << std::endl << "    Layouts: 0x" << layouts[IMMED][BYTE] << " 0x"
                << layouts[IMMED][HALF] << " 0x" << layouts[IMMED][FULL];
            out << std::endl << "  Meter Data Layout: " << std::endl;
            out << "    Counts: ";
            out << counts[METER][BYTE] << " " << counts[METER][HALF] << " "
                << counts[METER][FULL];
            out << std::endl << "    Layouts: 0x" << layouts[METER][BYTE] << " 0x"
                << layouts[METER][HALF] << " 0x" << layouts[METER][FULL];
        }

        void reset();
        int total_action_data_bytes() const {
            return total_bytes(ADT) + total_bytes(IMMED);
        }

        int total_bytes(ad_source_t loc) const {
            return counts[loc][BYTE] + counts[loc][HALF] * 2 + counts[loc][FULL] * 4;
        }

        int total(ad_source_t loc, bitmasked_t bm, cont_type_t type) const;

        cont_type_t best_candidate_to_move(int overhead_bytes);

        int find_maximum_immed(bool meter_color, int global_bytes);
        void finalize_min_maxes();

        bool overlaps(int max_bytes, ad_source_t loc) {
            if (counts[loc][BYTE] + 2 * counts[loc][HALF] > max_bytes)
                return true;
            return false;
        }
        ActionContainerInfo() {}
    };

    /** During ActionAnalysis, the algorithm needs to find the location of particular action
     *  arguments within a placement, in order to get the alignment information.
     *  Instead of running an O(n) search everytime, the algorithm creates a map for a quick
     *  lookup.  Again, because this pass can run before and after PHV allocation, the
     *  container information might not be valid
     */
    struct ArgKey {
        cstring name;
        int field_bit = -1;
        bool container_valid = false;
        PHV::Container container;
        int cont_bit = -1;
        bool is_constant = false;

        bool operator<(ArgKey ak) const {
            if (is_constant && !ak.is_constant)
                return false;
            if (!is_constant && ak.is_constant)
                return true;

            if (!is_constant && !ak.is_constant) {
                if (name != ak.name)
                    return name < ak.name;
            }

            if (field_bit != ak.field_bit)
                return field_bit < ak.field_bit;

            if (container_valid && !ak.container_valid)
                return false;
            if (!container_valid && ak.container_valid)
                return true;

            if (container_valid && ak.container_valid) {
                if (container != ak.container)
                    return container < ak.container;
                if (cont_bit != ak.cont_bit)
                    return cont_bit < ak.cont_bit;
            }
            return false;
        }

        void dbprint(std::ostream &out) const {
            if (is_constant)
                out << "constant";
            else
                out << name;
            out << " " << field_bit;
            if (container_valid)
                out << " : " << container.toString() << " " << cont_bit;
        }


        // One for holding action data information
        void init(cstring n, int fb, bool cv, PHV::Container c, int cb) {
            name = n;
            field_bit = fb;
            container_valid = cv;
            container = c;
            cont_bit = cb;
        }

        // One for holding information are where all constants converted to action data
        void init_constant(PHV::Container c, int cb) {
            field_bit = 0;
            container_valid = true;
            container = c;
            cont_bit = cb;
            is_constant = true;
        }
    };

    // The vector locations for the action arguments, within a vector of vectors
    struct ArgValue {
        int placement_index;
        int arg_index;

        explicit ArgValue(int pi, int ai) : placement_index(pi), arg_index(ai) { }
    };

    typedef safe_vector<ActionDataForSingleALU> SingleActionALUPlacement;
    typedef std::map<cstring, SingleActionALUPlacement> TotalALUPlacement;

    typedef safe_vector<ActionDataFormatSlot> SingleActionSlotPlacement;
    typedef std::map<cstring, SingleActionSlotPlacement> TotalSlotPlacement;
    typedef std::map<ArgKey, safe_vector<ArgValue>> ArgPlacementData;
    typedef std::map<ArgKey, ArgValue> ConstantRenames;

    int action_bytes[LOCATIONS] = {0, 0, 0};
    int action_data_bytes = 0;

    /** The algorithm to find locations for Hash Distribution or Random Numbers will have to be
     *  changed in order to handle the possible combination of IR nodes.  The major issue
     *  is that either these IR nodes never can be changed after TableLayout runs, or
     *  that these data structures need to be updated anytime these IR nodes either can be
     *  shared or collapse
     *
     *  Currently each individual Hash.get(...) and random.get(...) is translated into its
     *  own IR::Node, and each individual IR node receives its own placement.  However, plenty
     *  of optimizations can exist where either HashDist units can be shared between actions
     *  or even different tables in where this data gets allocated.  The same can be said
     *  with Random Number resources.  As programs get more complicated, the ability of the
     *  compiler to handle these optimizations will depend significantly on how the state
     *  of their allocations is captured across the ActionFormat, InputXbar and ActionDataBus.
     *  This is all to keep in mind for the next design of these algorithms.
     */
    typedef std::map<const IR::MAU::RandomNumber *, SingleActionALUPlacement> RandNumALUFormat;
    typedef std::map<const IR::MAU::RandomNumber *, SingleActionSlotPlacement> RandNumSlotFormat;
    /** Contains all of the information on all the action data format and individual arguments
     *  Because we only currently have either only an action data table or action data through
     *  immediate, this structure contains both of these structures.  Eventually, like GLASS,
     *  we need to be able to split information between action data tables and immediate.
     *  At that point, a LayoutOption will also correspond with an ActionFormat::Use.  In
     *  the meantime, we can keep them as separate structures.
     */
    struct Use {
        TotalALUPlacement action_data_format;
        // Location of action arguments within the action data format
        std::map<cstring, ArgPlacementData> arg_placement;
        // Location of constants within the action data format
        std::map<cstring, ConstantRenames> constant_locations;
        RandNumALUFormat rand_num_placement;

        int action_data_bytes[LOCATIONS] = { 0, 0 };

        bitvec immediate_mask;
        bitvec total_layouts[LOCATIONS][CONTAINER_TYPES];
        bitvec hash_dist_layouts[CONTAINER_TYPES];
        bitvec rand_num_layouts[CONTAINER_TYPES];
        bitvec global_param_layouts[CONTAINER_TYPES];

        bitvec full_layout_bitmasked;
        bool meter_reserved = false;
        bool phv_alloc = true;

        void clear() {
            action_data_format.clear();
            immediate_mask.clear();
        }

        cstring get_format_name(int start_byte, cont_type_t type, bool immediate, bitvec range,
            bool use_range, bool bitmasked_set = false) const;
        bool is_meter_color(int start_byte, bool immediate) const;
        bool is_rand_num(int byte_offset, const IR::MAU::RandomNumber **rn) const;
        void find_rand_num(const IR::MAU::RandomNumber *rn, int field_lo, int field_hi,
                           int &rng_lo, int &rng_hi) const;
        bool in_layouts(int byte_offset, const bitvec layouts[CONTAINER_TYPES]) const;
        int immediate_bits() const {
            return immediate_mask.max().index() + 1;
        }

        bool is_immed_speciality_in_use() const {
            return !(rand_num_placement.empty() && !meter_reserved);
        }
    };

    struct failure : public Backtrack::trigger {
        cstring action_name;
        explicit failure(cstring an) : trigger(OTHER), action_name(an) {}
    };

    Use *use;
    // Which bytes of the action format correspond to the different container sizes
    // Will be necessary for the action bus allocation

 private:
    const IR::MAU::Table *tbl;
    const PhvInfo &phv;
    bool alloc_done;
    int max_bytes = 0;
    bool meter_color = false;
    ActionContainerInfo max_total;
    safe_vector<ActionContainerInfo> init_action_counts;
    // For Hash Distribution and Random Number
    ActionContainerInfo global_params;
    safe_vector<ActionContainerInfo> action_counts;

    TotalALUPlacement init_alu_format;
    TotalSlotPlacement init_slot_format;

    RandNumALUFormat init_rn_alu_placement;
    RandNumSlotFormat init_rn_slot_placement;

    bool split_started = false;

    bool analyze_all_actions();
    void optimize_sharing();
    void condense_action_data(SingleActionSlotPlacement &info);
    void set_slot_bits(SingleActionSlotPlacement &info);
    void pack_slot_bits(SingleActionSlotPlacement &info);

    void create_placement_non_phv(const ActionAnalysis::FieldActionsMap &field_actions_map,
                                  cstring action_name);
    void create_placement_phv(const ActionAnalysis::ContainerActionsMap &container_actions_map,
                              cstring action_name);
    void create_from_actiondata(ActionDataForSingleALU &adp,
        const ActionAnalysis::ActionParam &read, int container_bit,
        const IR::MAU::RandomNumber **rn);
    void create_from_constant(ActionDataForSingleALU &adp,
        const ActionAnalysis::ActionParam &read, int field_bit, int container_bit,
        int &constant_to_ad_count);

    void initialize_action_counts();
    bool initialize_global_params_counts();
    void calculate_maximum();
    bool new_action_format(bool immediate_allowed, bool &finished);
    void setup_use(safe_vector<Use> &uses);
    void space_containers();

    void space_all_table_containers();
    int offset_constraints_and_total_layouts();
    void space_8_and_16_containers(int max_small_bytes);
    int check_full_bitmasked(ActionContainerInfo &aci, int max_small_bytes);
    void space_32_containers();

    int space_global_params();
    void space_all_immediate_containers(int start_byte);
    void space_individ_immed(ActionContainerInfo &aci, int start_byte);
    void space_32_immed(ActionContainerInfo &aci);
    void space_all_meter_color();
    void resolve_container_info();

    void align_global_params(bitvec global_params_layouts[CONTAINER_TYPES]);
    void align_action_data_layouts();
    void reserve_meter_color(SingleActionSlotPlacement &placement_vec,
        SingleActionSlotPlacement &output_vec, ActionContainerInfo &aci,
        bitvec layouts_placed[CONTAINER_TYPES]);
    void align_section(SingleActionSlotPlacement &placement_vec,
        SingleActionSlotPlacement &output_vec, ActionContainerInfo &aci,
        ActionFormat::ad_source_t loc,
        bitmasked_t bm, bitvec layouts_placed[CONTAINER_TYPES],
        int placed[BITMASKED_TYPES][CONTAINER_TYPES]);
    void find_immed_last(SingleActionSlotPlacement &placement_vec,
        SingleActionSlotPlacement &output_vec, ActionContainerInfo &aci,
        bitvec layouts_placed[CONTAINER_TYPES], int placed[BITMASKED_TYPES][CONTAINER_TYPES]);
    void verify_placement(SingleActionSlotPlacement &slot_placement,
        SingleActionALUPlacement &alu_placement, SingleActionSlotPlacement &orig_placement);
    void determine_asm_name(SingleActionALUPlacement &placement_vec);
    void calculate_placement_data(SingleActionALUPlacement &placement_vec,
                                  ArgPlacementData &apd, ConstantRenames &cr);
    void calculate_immed_mask();

 public:
    ActionFormat(const IR::MAU::Table *t, const PhvInfo &p, bool ad)
        : tbl(t), phv(p), alloc_done(ad) {
         max_total.action = "$MAX_TOTAL";
    }

    void allocate_format(safe_vector<Use> &uses, bool immediate_allowed);
};

#endif /* EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_H_ */
