#ifndef EXTENSIONS_TOFINO_MAU_ACTION_FORMAT_H_
#define EXTENSIONS_TOFINO_MAU_ACTION_FORMAT_H_

#include "ir/ir.h"
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/cstring.h"
#include "lib/ordered_map.h"
#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

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
    static constexpr int CONTAINER_SIZES[3] = {8, 16, 32};

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
            ArgLoc(cstring n, bitvec dl, int fb, bool sl)
                : name(n), data_loc(dl), field_bit(fb), single_loc(sl) {}
            /** Structure to help determine where an individual field is within the immediate
             *  section.  Used for determine best asm_output for these fields.
             */
            struct ImmediatePlacement {
                bool setup = false;
                bool indexed = false;
                int index = -1;
                int lo = -1; int hi = -1;
                void init(int ind, int l, int h) {
                    setup = true; indexed = true; index = ind; lo = l; hi = h;
                }
                void init(int l, int h) {
                    setup = true; lo = l; hi = h;
                }
                cstring immed_name() const {
                    if (!setup)
                        BUG("Calling immed name on a non-immediate action data");
                    cstring ret = "immediate";
                    if (indexed)
                        ret += std::to_string(index);
                    ret += "(" + std::to_string(lo) + ".." + std::to_string(hi) + ")";
                    return ret;
                }
            };
            ImmediatePlacement immed_plac;
        };
        vector<ArgLoc> arg_locs;
        int size;          ///< Number of bits needed
        bitvec range;      ///< Total mask
        int start = -1;    ///< Byte offset within the action data table
        cstring asm_name;  ///< Potential rename if multiple action args within one placement
        int adf_offset = -1;

        cstring adf_name() const;
        cstring immed_name() const;

        int gen_index() {
            return ceil_log2(size / 8);
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
        int counts[CONTAINER_TYPES] = {0, 0, 0};
        bitvec layouts[CONTAINER_TYPES];
        int minmaxes[CONTAINER_TYPES] = {9, 17, 33};
        int maximum = -1;
        bool offset_constraint = false;
        int offset_full_word = -1;

        void dbprint(std::ostream &out) const {
            out << action << " ";
            out << counts[BYTE] << " " << counts[HALF] << " " << counts[FULL] << " ";
            out << layouts[BYTE] << " " << layouts[HALF] << " " << layouts[FULL];
            out << " ";
            out << minmaxes[BYTE] << " " << minmaxes[HALF] << " " << minmaxes[FULL];
        }

        void reset();
        int total_bytes() const {
            return counts[BYTE] + counts[HALF] * 2 + counts[FULL] * 4;
        }

        /** Counts the maximum number of bytes of each type of container, and finds the
         *  maximum minmax
         */ 
        void maximize(ActionContainerInfo &a) {
            for (int i = 0; i < CONTAINER_TYPES; i++) {
                if (a.counts[i] > counts[i]) {
                    counts[i] = a.counts[i];
                    minmaxes[i] = a.minmaxes[i];
                } else if (a.minmaxes[i] > minmaxes[i]) {
                    minmaxes[i] = a.minmaxes[i];
                }
            }
        }

        int find_maximum_immed();
        void finalize_min_maxes();

        bool overlaps(int max_bytes) {
            if (counts[BYTE] + 2 * counts[HALF] > max_bytes)
                return true;
            return false;
        }
        ActionContainerInfo() {}
    };


    /** Contains information on the individual Arguments, and which field they correspond to.
     *  This structure is not fully complete yet, as I have not yet needed it to provide
     *  information.  This may be necessary for the next PR, and thus it's is being kept around.
     */ 
    struct ArgInfo {
        vector<const PhvInfo::Field *> fields;
        vector<vector<std::pair<int, bitvec>>> act_bus_reqs;

        void append(vector<const PhvInfo::Field *> &a) {
            fields.insert(fields.end(), a.begin(), a.end());
        }

        void append(vector<std::pair<int, bitvec>> &a) {
            act_bus_reqs.push_back(a);
        }

        bool empty() { return fields.empty() && act_bus_reqs.empty(); }
        ArgInfo() {}
    };

    typedef std::map<cstring, ArgInfo> ArgMap;
    typedef std::map<cstring, vector<ActionDataPlacement>> ArgFormat;
    typedef std::map<cstring, vector<std::pair<int, bool>>> ArgPlacementData;
    bool immediate_possible = false;
    vector<ActionContainerInfo> action_counts;

    /** Contains all of the information on all the action data format and individual arguments
     *  Because we only currently have either only an action data table or action data through
     *  immediate, this structure contains both of these structures.  Eventually, like GLASS,
     *  we need to be able to split information between action data tables and immediate.
     *  At that point, a LayoutOption will also correspond with an ActionFormat::Use.  In
     *  the meantime, we can keep them as separate structures.
     */
    struct Use {
        std::map<cstring, ArgMap> arguments;
        bool has_immediate = false;
        ArgFormat action_data_format;
        ArgFormat immediate_format;
        std::map<cstring, ArgPlacementData> arg_placement;
        int action_data_bytes = 0;
        bitvec immediate_mask;
        bitvec total_layouts[CONTAINER_TYPES];
        bitvec total_layouts_immed[CONTAINER_TYPES];

        void clear() {
            arguments.clear();
            action_data_format.clear();
            immediate_format.clear();
            immediate_mask.clear();
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
    int action_data_bytes = 0;
    ActionContainerInfo max_total;

    void space_individ_immed(ActionContainerInfo &aci);
    int offset_constraints_and_total_layouts();
    void space_8_and_16_containers(int max_small_bytes);
    void space_32_containers();
    void space_32_immed(ActionContainerInfo &aci);

 public:
    ActionFormat(const IR::MAU::Table *t, const PhvInfo &p, bool ad)
        : tbl(t), phv(p), alloc_done(ad) {
         max_total.action = "$MAX_TOTAL";
    }

    void allocate_format(Use *use);
    void setup_action_counts(bool immediate);
    void analyze_all_actions();
    void setup_immediate_format();
    void space_all_containers();
    void align_action_data_layouts();
    void space_all_immediate_containers();
    void align_immediate_layouts();
    void sort_and_asm_name(vector<ActionDataPlacement> &placement_vec, bool immediate);
    void calculate_placement_data(vector<ActionDataPlacement> &placement_vec,
                                  ArgPlacementData &apd, bool immediate);
    void determine_format_name();
    void determine_immed_format_name();
};

/** Class for building the initial information for the ActionDataPlacment, as well as the
 *  ArgInfo classes.  Passes over all of the Instructions to determine which need to be spread
 *  out within the class
 */
class ArgumentAnalyzer : public MauInspector, P4WriteContext {
    /** Information on what fields are contained within an individual container.  Must be separated
     *  from the PHV allocation, as this pass can be called before or after PHV allocation
     */
    struct ContainerInfo {
        struct ContainerSection {
            cstring arg_name;
            int field_bit, container_bit, width;
            ContainerSection(cstring a, int fb, int cb, int w)
                : arg_name(a), field_bit(fb), container_bit(cb), width(w) {}
        };
        vector<ContainerSection> sections;
        bool shared = false;
        bool can_shift = true;
    };

 private:
    const PhvInfo &phv;
    ActionFormat::Use *use;
    bool alloc_done = false;
    vector<cstring> action_args;
    vector<const PhvInfo::Field *> fields_used;
    bitvec instr_used;
    ActionFormat::ArgMap arg_map;
    void parse_container_phv(const IR::MAU::Action *af);
    void parse_container_non_phv(const IR::MAU::Action *af);

 public:
     ArgumentAnalyzer(const PhvInfo &p, ActionFormat::Use *u, bool ad)
         : phv(p), use(u), alloc_done(ad) {}
     bool preorder(const IR::MAU::Action *) override;
     bool preorder(const IR::Primitive *) override;
     bool preorder(const IR::MAU::Instruction *) override;
     bool preorder(const IR::Expression *) override;

     void postorder(const IR::MAU::Instruction *) override;
     void postorder(const IR::MAU::Action *) override;
};

#endif /* EXTENSIONS_TOFINO_MAU_ACTION_FORMAT_H_ */
