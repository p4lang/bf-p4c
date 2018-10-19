#ifndef BF_P4C_MAU_TABLE_FORMAT_H_
#define BF_P4C_MAU_TABLE_FORMAT_H_

#include <map>
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "ir/ir.h"
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/safe_vector.h"

// Info for the allocation scheme for individual byte off of the input crossbar
struct ByteInfo {
 public:
    IXBar::Use::Byte byte;  // Obviously the byte
    bitvec bit_use;   // Relevant bits of the byte
    int byte_location = -1;

    explicit ByteInfo(const IXBar::Use::Byte b, bitvec bu)
        : byte(b), bit_use(bu) {}

    void dbprint(std::ostream &out) const {
        out << "Byte " << byte << " bit_use " << bit_use << " byte_location"
            << byte_location;
    }
};


struct TableFormat {
    static constexpr int OVERHEAD_BITS = 64;
    static constexpr int SINGLE_RAM_BITS = 128;
    static constexpr int SINGLE_RAM_BYTES = 16;
    static constexpr int GATEWAY_BYTES = 4;
    static constexpr int VERSION_BYTES = 14;
    static constexpr int RAM_GHOST_BITS = 10;
    static constexpr int VERSION_BITS = 4;
    static constexpr int VERSION_NIBBLES = 4;
    static constexpr int MID_BYTE_LO = 0;
    static constexpr int MID_BYTE_HI = 1;
    static constexpr int MID_BYTE_VERS = 3;
    static constexpr int MAX_SHARED_GROUPS = 2;
    static constexpr int MAX_GROUPS_PER_RAM = 5;
    static constexpr int FULL_IMEM_ADDRESS_BITS = 6;
    static constexpr int FULL_NEXT_TABLE_BITS = 8;
    static constexpr int NEXT_MAP_TABLE_ENTRIES = 8;
    static constexpr int IMEM_MAP_TABLE_ENTRIES = 8;
    // MSB bit of the selector length
    static constexpr int SELECTOR_LENGTH_MAX_BIT = 16;

    enum type_t { MATCH, NEXT, ACTION, IMMEDIATE, VERS, COUNTER, COUNTER_PFE, METER, METER_PFE,
                  METER_TYPE, INDIRECT_ACTION, SEL_LEN_MOD, SEL_LEN_SHIFT, ENTRY_TYPES };


    struct Use {
        struct match_group_use {
            // int is the number of bits in allocation
            // bitvec is the mask, if bitvec.popcount() < Byte.hi - Byte.lo then it is
            // an 8 bit field that's partially ghosted,
            // if bitvec.popcount() > byte.hi - byte.lo then it is
            // a misaligned field where the mask was not known until PHV allocation

            /// The byte and byte_mask location in the format
            std::map<IXBar::Use::Byte, bitvec> match;
            bitvec mask[ENTRY_TYPES];
            bitvec match_byte_mask;  // The bytes that are allocaated for matching
            bitvec allocated_bytes;

            void clear_match() {
                match.clear();
                mask[MATCH].clear();
                mask[VERS].clear();
                match_byte_mask.clear();
            }

            bitvec match_bit_mask() const {
                return mask[MATCH] | mask[VERS];
            }

            bitvec entry_info_bit_mask() const {
                bitvec rv;
                for (int i = 0; i < ENTRY_TYPES; i++)
                    rv |= mask[i];
                return rv;
            }

            bitvec overhead_mask() const {
                return entry_info_bit_mask() - match_bit_mask();
            }
        };

        struct TCAM_use {
            int group = -1;
            int byte_group = -1;
            int byte_config = -1;
            bitvec dirtcam;

            void set_group(int _group, bitvec _dirtcam);
            void set_midbyte(int _byte_group, int _byte_config);

            int range_index = -1;
            TCAM_use() {}
        };

        safe_vector<match_group_use> match_groups;
        safe_vector<TCAM_use> tcam_use;
        int split_midbyte = -1;

        std::map<int, safe_vector<int>> ixbar_group_per_width;
        safe_vector<bool> result_bus_needed;
        bitvec avail_sb_bytes;

        /// The byte and individual bits to be ghosted. Ghost bits should be the
        /// same for all match entries.
        std::map<IXBar::Use::Byte, bitvec> ghost_bits;

        void clear() {
            ghost_bits.clear();
            match_groups.clear();
            tcam_use.clear();

            ixbar_group_per_width.clear();
            result_bus_needed.clear();
            avail_sb_bytes.clear();
        }

        bitvec immed_mask;

        IR::MAU::PfeLocation stats_pfe_loc = IR::MAU::PfeLocation::NOT_SET;
        IR::MAU::PfeLocation meter_pfe_loc = IR::MAU::PfeLocation::NOT_SET;
        IR::MAU::TypeLocation meter_type_loc = IR::MAU::TypeLocation::NOT_SET;

        bool instr_in_overhead() const {
            if (match_groups.empty())
                return false;
            return !match_groups[0].mask[ACTION].empty();
        }
    };

 private:
    Use *use;
    const LayoutOption &layout_option;
    const IXBar::Use &match_ixbar;
    const IR::MAU::Table *tbl;

    // Vector for a hash group, as large tables could potentially use multiple hash groups
    safe_vector<IXBar::Use::Byte> single_match;
    // Match Bytes
    safe_vector<ByteInfo> match_bytes;
    safe_vector<ByteInfo> ghost_bytes;
    std::set<int> fully_ghosted_search_buses;
    safe_vector<int> ghost_bit_buses;

    bitvec total_use;  // Total bitvec for all entries in table format
    bitvec pre_match_total_use;
    bitvec match_byte_use;   // Bytes used by all match byte masks
    // safe_vector<bitvec> byte_use;  // Vector of individual byte by byte masks

    enum packing_algorithm_t { SAVE_GW_SPACE, PACK_TIGHT, PACKING_ALGORITHMS };

    packing_algorithm_t pa = PACKING_ALGORITHMS;

    // Size of the following vectors is the layout_option.way->width

    /// Which RAM sections contain the match groups
    // safe_vector<int> match_groups_per_RAM;
    /// Which RAM sections contain overhead info
    safe_vector<int> overhead_groups_per_RAM;
    /// Specifically which search bus coordinates to which RAM
    safe_vector<int> search_bus_per_width;

    safe_vector<int> full_match_groups_per_RAM;
    safe_vector<int> shared_groups_per_RAM;
    safe_vector<bool> version_allocated;

    // Match group index in use coordinate to whenever they are found in the match_groups_per_RAM
    // i.e. if the match_groups_per_RAM looks like [2, 2], then use->match_groups[0] and
    // use->match_groups[1] are in the first RAM, etc.  Same thing applies for overhead groups

    // Size of outer vector is layout_option.way->match_groups.  Essentially which RAMs does
    // each match group use, for allocating version bits.
    // safe_vector<safe_vector<int>> match_group_info;

    int ghost_bits_count = 0;
    const bitvec immediate_mask;
    bool gw_linked;
    bool skinny = false;
    // bitvec ghost_start;
    bool allocate_overhead();
    bool allocate_all_indirect_ptrs();
    bool allocate_all_immediate();
    bool allocate_all_instr_selection();
    bool allocate_match();
    bool allocate_match_with_algorithm();
    bool is_match_entry_wide() const;

    bool allocate_all_ternary_match();
    void initialize_dirtcam_value(bitvec &dirtcam, const IXBar::Use::Byte &byte);
    void ternary_midbyte(int midbyte, size_t &index, bool lo_midbyte);
    void ternary_version(size_t &index);

    bool analyze_layout_option();
    bool analyze_skinny_layout_option(int per_RAM, safe_vector<IXBar::Use::GroupInfo> &sizes);
    bool analyze_wide_layout_option(safe_vector<IXBar::Use::GroupInfo> &sizes);

    int hit_actions();
    bool allocate_next_table();
    bool allocate_selector_length();
    bool allocate_indirect_ptr(int total, type_t type, int group, int RAM);

    void find_bytes_to_allocate(int width_sect, safe_vector<ByteInfo> &unalloced);
    bool initialize_byte(int byte_offset, int width_sect, ByteInfo &info,
        safe_vector<ByteInfo> &alloced, bitvec &byte_attempt, bitvec &bit_attempted);
    bool allocate_match_byte(ByteInfo &info, safe_vector<ByteInfo> &alloced, int width_sect,
        bitvec &byte_attempt, bitvec &bit_attempt);
    bool allocate_version(int width_sect, const safe_vector<ByteInfo> &alloced,
        bitvec &version_loc, bitvec &byte_attempt, bitvec &bit_attempt);
    void fill_out_use(int group, const safe_vector<ByteInfo> &alloced, bitvec &version_loc);

    void choose_ghost_bits();
    int determine_group(int width_sect, int groups_allocated);

    void allocate_share(int width_sect, safe_vector<ByteInfo> &unalloced_group,
        safe_vector<ByteInfo> &alloced, bitvec &version_loc, bitvec &byte_attempt,
        bitvec &bit_attempt, bool overhead_section);
    bool attempt_allocate_shares();
    bool allocate_shares();
    void allocate_full_fits(int width_sect);
    void redistribute_entry_priority();
    void redistribute_next_table();

 public:
    TableFormat(const LayoutOption &l, const IXBar::Use &mi, const IR::MAU::Table *t,
                const bitvec im, bool gl)
        : layout_option(l), match_ixbar(mi), tbl(t), immediate_mask(im), gw_linked(gl) {}

    bool find_format(Use *u);
    void verify();
};

#endif /* BF_P4C_MAU_TABLE_FORMAT_H_ */
