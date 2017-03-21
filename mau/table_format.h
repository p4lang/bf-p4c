#ifndef _TOFINO_MAU_TABLE_FORMAT_H_
#define _TOFINO_MAU_TABLE_FORMAT_H_

#include "lib/bitvec.h"
#include "lib/bitops.h"
#include "ir/ir.h"
#include "input_xbar.h"
#include "resource_estimate.h"

// Info for the allocation scheme for individual byte off of the input crossbar
struct ByteInfo {
 public:
    IXBar::Use::Byte byte;  // Obviously the byte
    int bit_count;          // Number of bits in the byte, not ghosted
    int use_index;          // What number it is in the vector

    explicit ByteInfo(const IXBar::Use::Byte b, int bc, int ui)
        : byte(b), bit_count(bc), use_index(ui) {}

    void dbprint(std::ostream &out) const {
        out << "Byte " << byte << " bit_count " << bit_count << " use_index " << use_index;
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

    enum type_t {MATCH, ACTION, IMMEDIATE, VERS, COUNTER, METER, INDIRECT_ACTION, SELECTOR,
                 ENTRY_TYPES };

    struct Use {
        struct match_group_use {
            // int is the number of bits in allocation
            // bitvec is the mask, if bitvec.popcount() < Byte.hi - Byte.lo then it is
            // an 8 bit field that's partially ghosted,
            // if bitvec.popcount() > byte.hi - byte.lo then it is
            // a misaligned field where the mask was not known until PHV allocation
            map<IXBar::Use::Byte, std::pair<int, bitvec>> match;
            bitvec mask[ENTRY_TYPES];
            bitvec match_byte_mask;
            bitvec allocated_bytes;
        };

        vector<match_group_use> match_groups;
        // ghost bits should be the same for all match entries
        map<IXBar::Use::Byte, std::pair<int, bitvec>> ghost_bits;
        void clear() {
            ghost_bits.clear();
            match_groups.clear();
        }
        bitvec immed_mask;
    };

 private:
    Use *use;
    const IR::MAU::Table::LayoutOption &layout_option;
    const IXBar::Use &match_ixbar;
    const IR::MAU::Table *tbl;

    // Vector for a hash group, as large tables could potentially use multiple hash groups
    vector<IXBar::Use::Byte> single_match;

    bitvec total_use;  // Total bitvec for all entries in table format
    bitvec match_byte_use;   // Bytes used by all match byte masks
    vector<bitvec> byte_use;  // Vector of individual byte by byte masks

    // Size of the following vectors is the layout_option.way->width
    vector<int> match_groups_per_RAM;  // Which RAM sections contain the match groups
    vector<int> overhead_groups_per_RAM;  // Which RAM sections contain overhead info
    vector<int> ixbar_group_per_width;  // Specifically which ixbar group coordinates to which RAM

    // Match group index in use coordinate to whenever they are found in the match_groups_per_RAM
    // i.e. if the match_groups_per_RAM looks like [2, 2], then use->match_groups[0] and
    // use->match_groups[1] are in the first RAM, etc.  Same thing applies for overhead groups

    // Size of outer vector is layout_option.way->match_groups.  Essentially which RAMs does
    // each match group use, for allocating version bits.
    vector<vector<int>> match_group_info;

    bool balanced = true;
    int ghost_bits_count = 0;
    bool next_table = false;
    bitvec ghost_start;

 public:
    TableFormat(const IR::MAU::Table::LayoutOption &l, const IXBar::Use &mi,
                const IR::MAU::Table *t)
        : layout_option(l), match_ixbar(mi), tbl(t) {}
    bool find_format(Use *u);
    bool analyze_layout_option();
    bool analyze_skinny_layout_option(int per_RAM, vector<std::pair<int, int>> &sizes);
    bool analyze_wide_layout_option(vector<std::pair<int, int>> &sizes);
    bool allocate_next_table();
    bool allocate_indirect_ptr(int total, type_t type, int group, int RAM);
    bool allocate_all_indirect_ptrs();
    bool allocate_all_immediate(bool no_match);
    bool allocate_all_instr_selection();
    bool allocate_all_match();
    void determine_byte_types(bitvec &unaligned_bytes, bitvec &chosen_ghost_bytes);
    bool allocate_easy_bytes(bitvec &unaligned_bytes, bitvec &chosen_ghost_bytes,
        int &easy_size);
    bool allocate_difficult_bytes(bitvec &unaligned_bytes, bitvec &chosen_ghost_bytes,
        int easy_size);
    void determine_difficult_vectors(vector<ByteInfo> &unaligned_match,
        vector<ByteInfo> &unaligned_ghost, vector<ByteInfo> &ghost_anywhere,
        bitvec &unaligned_bits, bitvec &chosen_ghost_bits, int ghosted_group);
    bool allocate_byte_vector(vector<ByteInfo> &bytes, int prev_allocated, bool ghost_anywhere);
    void easy_byte_fill(int RAM, int group, ByteInfo &byte, int &starting_byte,
        bool protect, bool ghost_anywhere);
    int determine_next_group(int current_group, int RAM);
    bool allocate_one_version(int starting_byte, int group);
    bool allocate_all_version();
    void verify();
};

#endif /* _TOFINO_MAU_TABLE_FORMAT_H_ */
