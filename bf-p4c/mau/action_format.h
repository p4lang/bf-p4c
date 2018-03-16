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

/** Different Constraints
 *  # Not handled yet
 *  - ActionArg could be the read for multiple parameters
 *     - These parameters could have different PHV structure
 *  # Not handled yet
 *  - Smaller fields could potentially share action data bytes, potentially going to 
 *    mutliple different ALUs.
 *     - Do masks also need to be potentially stored
 *     - One would need a potential bit mask for these entries
 *  # Attempt to handle in first pass
 *  - Based on action data bus structure, the smaller containers should try to be in the 
 *    lower bytes
 */



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
    enum location_t {ADT, IMMED, LOCATIONS};
    enum bitmasked_t {NORMAL, BITMASKED, BITMASKED_TYPES};
    static constexpr int CONTAINER_SIZES[3] = {8, 16, 32};
    static constexpr int IMMEDIATE_BYTES = 4;

    /** Delineates where a specific container is contained within an action format, whether
     *  it is an action data table or in the immediate.  The start tells what byte the
     *  container begins at, and the size is how many bits the container needs
     */
    struct ActionDataPlacement {
        struct ArgLoc {
            cstring name;       ///< name of the arg
            bitvec data_loc;    ///< The location within the container of this action data
            int field_bit;      ///< The starting bit which the arg is allocating over
            bool single_loc = true;
            bool is_constant = false;
            int constant_value = 0;
            ArgLoc(cstring n, bitvec dl, int fb, bool sl)
                : name(n), data_loc(dl), field_bit(fb), single_loc(sl) {}
            void set_as_constant(int cv) {
                is_constant = true;
                constant_value = cv;
            }
            int field_hi() const { return field_bit + data_loc.popcount() - 1; }
            int cont_lo() const { return data_loc.min().index(); }

            ActionAnalysis::ActionParam::speciality_t speciality
                = ActionAnalysis::ActionParam::NO_SPECIAL;
            bool operator==(const ArgLoc &a) const;

            /** The alias needed for a single action parameter */
            cstring get_asm_name() const {
                cstring ret_name = name;
                if (!single_loc) {
                    int lo = field_bit;
                    int hi = field_bit + data_loc.popcount() - 1;
                    ret_name = ret_name + + "." + std::to_string(lo) + "-" + std::to_string(hi);
                }
                return ret_name;
            }
        };

        safe_vector<ArgLoc> arg_locs;
        int size;          ///< Number of bits needed
        bitvec range;      ///< Total mask
        bool bitmasked_set = false;  ///< If the placement requires a mask as well
        unsigned specialities = 0;
        bool immediate = false;

        bool operator==(const ActionDataPlacement &a) const;

        // Everything above is determined during initialization

        // Everything below is determined during the action_format algorithm
        int start = -1;    ///< Byte offset within the action data table
        cstring action_name;  ///< Potential rename if multiple action args within one placement
        cstring mask_name;  ///< A name that coordinates the mask to be setup in asm_output

        int gen_index() const {
            return ceil_log2(size / 8);
        }

        /** The alias needed in the format of the action for a placement */
        cstring get_action_name() const {
            BUG_CHECK(action_name.isNull() == (arg_locs.size() == 1), "Action Format"
                      " arg_loc size doesn't match name");
            if (arg_locs.size() == 1)
                return arg_locs[0].get_asm_name();
            else
                return action_name;
        }

        /** Returns the mask name.  Only can be called on a placement that has bitmasked-set */
        cstring get_mask_name() const {
            BUG_CHECK(bitmasked_set && arg_locs.size() > 1, "Cannot call get_mask_name on "
                      "a placement that has no bitmask");
            return mask_name;
        }

        ActionDataPlacement() {}
    };

    /** Used for a container by container analysis of laying out the action format of a table.
     *  Essentially per action, how many containers are used, what types they are, 
     *  and if there is some immediate data, what the max lengths of each type of container
     *  is being used
     */
    struct ActionContainerInfo {
        cstring action;
        enum order_t {FIRST_8, FIRST_16, EITHER, NOT_SET} order = NOT_SET;
        int counts[LOCATIONS][CONTAINER_TYPES] = {{0, 0, 0}, {0, 0, 0}};
        int bitmasked_sets[LOCATIONS][CONTAINER_TYPES] = {{0, 0, 0}, {0, 0, 0}};
        int minmaxes[BITMASKED_TYPES][CONTAINER_TYPES] = {{9, 17, 33}, {9, 17, 33}};
        // int bm_minmaxes[CONTAINER_TYPES] = {9, 17, 33};

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
        }

        void reset();
        int total_action_data_bytes() const {
            return total_bytes(ADT) + total_bytes(IMMED);
        }

        int total_bytes(location_t loc) const {
            return counts[loc][BYTE] + counts[loc][HALF] * 2 + counts[loc][FULL] * 4;
        }

        int total(location_t loc, bitmasked_t bm, cont_type_t type) const;

        cont_type_t best_candidate_to_move(int overhead_bytes);

        int find_maximum_immed(bool meter_color, int hash_dist_bytes);
        void finalize_min_maxes();

        bool overlaps(int max_bytes, location_t loc) {
            if (counts[loc][BYTE] + 2 * counts[loc][HALF] > max_bytes)
                return true;
            return false;
        }
        ActionContainerInfo() {}
    };


    typedef safe_vector<ActionDataPlacement> SingleActionPlacement;
    typedef std::map<cstring, safe_vector<ActionDataPlacement>> ArgFormat;
    typedef std::map<std::pair<cstring, int>, safe_vector<int>> ArgPlacementData;
    typedef std::map<std::pair<cstring, int>, cstring> ConstantRenames;

    int action_bytes[LOCATIONS] = {0, 0};
    int action_data_bytes = 0;

    typedef std::map<const IR::MAU::HashDist *, safe_vector<ActionDataPlacement>> HashDistInfo;

    /** Contains all of the information on all the action data format and individual arguments
     *  Because we only currently have either only an action data table or action data through
     *  immediate, this structure contains both of these structures.  Eventually, like GLASS,
     *  we need to be able to split information between action data tables and immediate.
     *  At that point, a LayoutOption will also correspond with an ActionFormat::Use.  In
     *  the meantime, we can keep them as separate structures.
     */
    struct Use {
        ArgFormat action_data_format;
        std::map<cstring, ArgPlacementData> arg_placement;
        std::map<cstring, ConstantRenames> constant_locations;
        HashDistInfo hash_dist_placement;

        int action_data_bytes[LOCATIONS];

        bitvec immediate_mask;
        bitvec total_layouts[LOCATIONS][CONTAINER_TYPES];
        bitvec hash_dist_layouts[CONTAINER_TYPES];

        bitvec full_layout_bitmasked;
        bool meter_reserved = false;

        void clear() {
            action_data_format.clear();
            immediate_mask.clear();
        }

        cstring get_format_name(int start_byte, cont_type_t type, bool immediate, bitvec range,
            bool use_range, bool bitmasked_set = false) const;
        bool is_meter_color(int start_byte, bool immediate) const;
        bool is_hash_dist(int byte_offset, const IR::MAU::HashDist **hd, int &field_lo,
                          int &field_hi) const;
        int find_hash_dist(const IR::MAU::HashDist *hd, int field_lo, int field_hi,
                           int &hash_lo, int &hash_hi, int &section) const;
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
    ActionContainerInfo hash_counts;
    safe_vector<ActionContainerInfo> action_counts;

    ArgFormat init_format;
    HashDistInfo init_hash_dist_placement;
    std::map<cstring, ConstantRenames> renames;

    bool split_started = false;

    bool analyze_all_actions();
    void create_placement_non_phv(ActionAnalysis::FieldActionsMap &field_actions_map,
                                  cstring action_name);
    void create_placement_phv(ActionAnalysis::ContainerActionsMap &container_actions_map,
                              cstring action_name);
    void create_from_actiondata(ActionDataPlacement &adp,
        const ActionAnalysis::ActionParam &read, int container_bit,
        const IR::MAU::HashDist **hd);
    void create_from_constant(ActionDataPlacement &adp,
        const ActionAnalysis::ActionParam &read, int field_bit, int container_bit,
        int &constant_to_ad_count, PHV::Container container, ConstantRenames &constant_renames);

    void initialize_action_counts();
    bool initialize_hash_dist_counts();
    void calculate_maximum();
    bool new_action_format(bool immediate_allowed, bool &finished);
    void setup_use(safe_vector<Use> &uses);
    void space_containers();

    void space_all_table_containers();
    int offset_constraints_and_total_layouts();
    void space_8_and_16_containers(int max_small_bytes);
    int check_full_bitmasked(ActionContainerInfo &aci, int max_small_bytes);
    void space_32_containers();

    int space_hash_dist();
    void space_all_immediate_containers(int start_byte);
    void space_individ_immed(ActionContainerInfo &aci, int start_byte);
    void space_32_immed(ActionContainerInfo &aci);
    void space_all_meter_color();

    void align_hash_dist(bitvec hash_layouts_placed[CONTAINER_TYPES]);
    void align_action_data_layouts();
    void reserve_meter_color(ArgFormat &format, ActionContainerInfo &aci,
                             bitvec layouts_placed[CONTAINER_TYPES]);
    void align_section(SingleActionPlacement &placement_vec, SingleActionPlacement &output_vec,
        ActionContainerInfo &aci, location_t loc, bitmasked_t bm,
        bitvec layouts_placed[CONTAINER_TYPES],
        int placed[BITMASKED_TYPES][CONTAINER_TYPES]);
    void find_immed_last(ArgFormat &format, ActionContainerInfo &aci,
        bitvec layouts_placed[CONTAINER_TYPES], int placed[BITMASKED_TYPES][CONTAINER_TYPES]);
    void sort_and_asm_name(safe_vector<ActionDataPlacement> &placement_vec);
    void calculate_placement_data(safe_vector<ActionDataPlacement> &placement_vec,
                                  ArgPlacementData &apd);
    void calculate_immed_mask();

 public:
    ActionFormat(const IR::MAU::Table *t, const PhvInfo &p, bool ad)
        : tbl(t), phv(p), alloc_done(ad) {
         max_total.action = "$MAX_TOTAL";
    }

    void allocate_format(safe_vector<Use> &uses, bool immediate_allowed);
};

#endif /* EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_H_ */
