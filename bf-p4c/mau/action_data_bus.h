#ifndef BF_P4C_MAU_ACTION_DATA_BUS_H_
#define BF_P4C_MAU_ACTION_DATA_BUS_H_

#include <lib/alloc.h>
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/mau/action_format.h"

/** Algorithm for the allocation of the action data bus.  The action data bus is broken into
 *  3 parts, a BYTE, HALF, and FULL region.  The byte and half regions are mutually exclusive,
 *  while the full region shares places with the byte and half region.  There are 32 outputs
 *  for each type of container region.  The bytes 0-31 are for the byte region, bytes 32-95
 *  are for the half region, and all 128 bytes are for the full regions.  Because actions
 *  within the same table are mutually exclusive, FULLs can potentially share locations with
 *  BYTES and HALFs on the action data bus.
 *
 *  The version of the algorithm updates the tables that have been previously allocated.  It
 *  then attempts to allocate the BYTES and HALVES.  Then the algorithm checks to see if the
 *  regions can be shared, and if not, allocates a separate byte.
 *
 *  The rules for allocation are set by the uArch on section 5.2.5.1/6.2.5.1 on the Action Data
 *  Bus.  The section is titled Action Output HV Xbar Programming, under the section Action
 *  Output HV Xbar(s) in the Section RAM Array.  The bytes are broken into 16 byte regions
 *  and bytes in particular offsets of the action data table have to be allocated contiguously
 *  within these 16 byte regions.  The constraints are better detailed over the alloc_bytes,
 *  alloc_halves, and alloc_fulls function calls.
 *
 *  For immediate actions, the constraints are detailed in the uArch in section 5.4.4.2/6.4.4.2.
 *  The section is titled Immediate Action Data, under Address Distribution, under Match Central.
 *  The constraints are similar to action data tables in that regions of the immediate data must
 *  be contiguously allocated within a 16 byte region of the action data bus.  With immediate
 *  action data, the input allocation must be 4 byte contiguous.
 */
struct ActionDataBus {
    static constexpr int OUTPUTS = 32;
    static constexpr int ADB_BYTES = 128;
    static constexpr int PAIRED_OFFSET = 16;
    static constexpr int BYTES_PER_RAM = 16;
    static constexpr int ADB_STARTS[3] = {0, 32, 96};
    static constexpr int IMMED_SECT = 4;


 private:
    Alloc2D<cstring, ActionFormat::CONTAINER_TYPES, OUTPUTS> cont_use;
    Alloc1D<cstring, ADB_BYTES> total_use;


    bitvec cont_in_use[ActionFormat::CONTAINER_TYPES];
    bitvec total_in_use;

    vector<std::pair<int, int>> immed_starts;


 public:
    struct Loc {
        int byte;
        ActionFormat::cont_type_t type;
        Loc(int b, ActionFormat::cont_type_t t) : byte(b), type(t) {}
    };
    /** Information on the sharing of resources between the BYTE/HALF regions and a potential
     *  full setion sharing the same location in the action data table
     */
    struct FullShare {
        bool full_in_use = false;
        unsigned shared_status = 0;
        int shared_byte[2] = {-1, -1};
        bool full_bitmasked_set = false;
        int full_bitmasked_index = -1;
        void init_full_bitmask(int fbi) {
            full_bitmasked_set = true;
            full_bitmasked_index = fbi;
        }
    };


    /** The bytes used by an individual table, stored in the TableResourceAlloc */
    struct Use {
        /** An individual space within the Use.  Used to update the reserved space */
        struct ReservedSpace {
            Loc location;
            int byte_offset = -1;  ///> Bytes from the lsb of the Action Data Format
            bool immediate = false;  ///> Is in action immediate or not
            ReservedSpace(Loc l, int bo)
                : location(l), byte_offset(bo) {}
            ReservedSpace(Loc l, int bo, bool im)
                : location(l), byte_offset(bo), immediate(im) {}
        };
        vector<ReservedSpace> reserved_spaces;
        void clear() {
            reserved_spaces.clear();
        }
    };

    /** Location Algorithm: For finding an allocation within the correct type region */
    enum loc_alg_t {FIND_NORMAL, FIND_LOWER, FIND_FULL};

    void clear();

 private:
    int byte_to_output(int byte, ActionFormat::cont_type_t type);
    int output_to_byte(int output, ActionFormat::cont_type_t type);
    int find_byte_sz(ActionFormat::cont_type_t);


    bitvec paired_space(ActionFormat::cont_type_t type, bitvec adjacent, int start_byte);
    bool find_location(ActionFormat::cont_type_t type, bitvec adjacent, int diff,
                       int &start_byte);
    bool find_lower_location(ActionFormat::cont_type_t type, bitvec adjacent,
                             int diff, int &start_byte);
    bool find_full_location(bitvec adjacent, int diff, int &output);

    void analyze_full_share(vector<Use::ReservedSpace> &reserved_spaces,
                            bitvec layouts[ActionFormat::CONTAINER_TYPES],
                            FullShare &full_share, int init_byte_offset,
                            int add_byte_offset, bool immed);
    void analyze_full_shares(vector<Use::ReservedSpace> &reserved_spaces,
                             bitvec layouts[ActionFormat::CONTAINER_TYPES],
                             bitvec full_bitmasked, FullShare full_shares[4],
                             int init_byte_offset);
    void reserve_space(vector<Use::ReservedSpace> &reserved_spaces,
                       ActionFormat::cont_type_t type, bitvec adjacent,
                       int start_byte, int byte_offset, bool immed, cstring name);
    bool fit_adf_section(vector<Use::ReservedSpace> &reserved_spaces, bitvec adjacent,
                         ActionFormat::cont_type_t type, loc_alg_t loc_alg,
                         int init_byte_offset, int sec_begin, int size, cstring name);
    bool alloc_bytes(vector<Use::ReservedSpace> &reserved_spaces,
                     bitvec layout, int init_byte_offset, cstring name);
    bool alloc_halves(vector<Use::ReservedSpace> &reserved_spaces,
                      bitvec layout, int init_byte_offset, cstring name);
    bool alloc_fulls(vector<Use::ReservedSpace> &reserved_spaces,
                     bitvec layouts[ActionFormat::CONTAINER_TYPES],
                     bitvec full_bitmasked, int init_byte_offset, cstring name);
    bool alloc_full_sect(vector<Use::ReservedSpace> &reserved_spaces,
                         FullShare full_shares[4], int begin, int init_byte_offset,
                         cstring name, bitvec full_bitmasked);
    bool alloc_ad_table(const bitvec total_layouts[ActionFormat::CONTAINER_TYPES],
                        const bitvec full_layout_bitmasked,
                        vector<Use::ReservedSpace> &locations, cstring name);

    bool fit_immed_sect(vector<Use::ReservedSpace> &reserved_spaces, bitvec layout,
                        ActionFormat::cont_type_t type, loc_alg_t loc_alg, cstring name);

    bool alloc_unshared_immed(vector<Use::ReservedSpace> &reserved_spaces,
                              ActionFormat::cont_type_t, bitvec layout, cstring name);
    bool alloc_shared_immed(vector<Use::ReservedSpace> &reserved_spaces,
                            bitvec layouts[ActionFormat::CONTAINER_TYPES], cstring name);
    bool alloc_immediate(const bitvec total_layouts[ActionFormat::CONTAINER_TYPES],
                         vector<Use::ReservedSpace> &locations, cstring name);

 public:
    bool alloc_action_data_bus(const IR::MAU::Table *tbl, const LayoutOption *lo,
                               TableResourceAlloc &alloc);

    void update(cstring name, const Use &alloc);
    void update(cstring name, const TableResourceAlloc *alloc);
    void update(const IR::MAU::Table *tbl) {
        if (tbl->resources) update(tbl->name, tbl->resources); }
};

#endif /* BF_P4C_MAU_ACTION_DATA_BUS_H_*/
