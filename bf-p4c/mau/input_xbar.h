#ifndef BF_P4C_MAU_INPUT_XBAR_H_
#define BF_P4C_MAU_INPUT_XBAR_H_

#include <array>
#include <map>
#include <unordered_set>
#include "bf-p4c/mau/table_layout.h"
#include "ir/ir.h"
#include "lib/alloc.h"
#include "lib/hex.h"
#include "lib/safe_vector.h"

class IXBarRealign;
struct TableResourceAlloc;

struct IXBar {
    static constexpr int EXACT_GROUPS = 8;
    static constexpr int EXACT_BYTES_PER_GROUP = 16;
    static constexpr int HASH_TABLES = 16;
    static constexpr int HASH_GROUPS = 8;
    static constexpr int HASH_INDEX_GROUPS = 4;  /* groups of 10 bits for indexing */
    static constexpr int HASH_SINGLE_BITS = 12;  /* top 12 bits of hash table individually */
    static constexpr int HASH_DIST_SLICES = 3;
    static constexpr int HASH_DIST_BITS = 16;
    static constexpr int HASH_DIST_UNITS = 2;
    static constexpr int TOFINO_METER_ALU_BYTE_OFFSET = 8;
    static constexpr int LPF_INPUT_BYTES = 4;
    static constexpr int TERNARY_GROUPS = StageUse::MAX_TERNARY_GROUPS;
    static constexpr int BYTE_GROUPS = StageUse::MAX_TERNARY_GROUPS/2;
    static constexpr int TERNARY_BYTES_PER_GROUP = 5;
    static constexpr int TERNARY_BYTES_PER_BIG_GROUP = 11;
    static constexpr int GATEWAY_SEARCH_BYTES = 4;
    struct Loc {
        int group = -1, byte = -1;
        Loc() = default;
        Loc(int g, int b) : group(g), byte(b) {}
        Loc(const Loc &) = default;
        explicit operator bool() const { return group >= 0 && byte >= 0; }
        operator std::pair<int, int>() const { return std::make_pair(group, byte); }
        /// return the byte number in the total order
        int getOrd(const bool isTernary = false) const {
            if ((*this)) {
                if (isTernary)
                    return EXACT_GROUPS * EXACT_BYTES_PER_GROUP +
                        (group * TERNARY_BYTES_PER_BIG_GROUP) + byte;
                else
                    return (group * EXACT_BYTES_PER_GROUP) + byte;
            } else {
                return -1;
            }
        }
    };

 private:
    /** IXBar tracks the use of all the input xbar bytes in a single stage.  Each byte use is set
     * to record the name of the field it will be getting and the bit offset within the field.
     * cstrings here are field names as used in PhvInfo (so PhvInfo::field can be used to find
     * out details about the field)
     * NOTE: Changes here require changes to .gdbinit pretty printer */
    Alloc2D<std::pair<cstring, int>, EXACT_GROUPS, EXACT_BYTES_PER_GROUP>       exact_use;
    Alloc2D<std::pair<cstring, int>, TERNARY_GROUPS, TERNARY_BYTES_PER_GROUP>   ternary_use;
    Alloc1D<std::pair<cstring, int>, BYTE_GROUPS>                               byte_group_use;
    Alloc2Dbase<std::pair<cstring, int>> &use(bool ternary) {
        if (ternary) return ternary_use;
        return exact_use; }
    /* reverse maps of the above, mapping field names to sets of group+byte */
    std::multimap<cstring, Loc>         exact_fields;
    std::multimap<cstring, Loc>         ternary_fields;
    std::multimap<cstring, Loc> &fields(bool ternary) {
        return ternary ? ternary_fields : exact_fields; }

    /* Track the use of hashtables/groups too -- FIXME -- should it be a separate data structure?
     * strings here are table names
     * NOTE: Changes here require changes to .gdbinit pretty printer */
    Alloc2D<cstring, HASH_TABLES, HASH_INDEX_GROUPS>    hash_index_use;
    unsigned                                    hash_index_inuse[HASH_INDEX_GROUPS] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_SINGLE_BITS>     hash_single_bit_use;
    unsigned                                    hash_single_bit_inuse[HASH_SINGLE_BITS] = { 0 };
    Alloc1D<cstring, HASH_GROUPS>                      hash_group_print_use;
    unsigned                                    hash_group_use[HASH_GROUPS] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_DIST_SLICES>     hash_dist_use;
    unsigned                                    hash_dist_inuse[HASH_TABLES] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_DIST_SLICES * HASH_DIST_BITS>   hash_dist_bit_use;
    unsigned long                               hash_dist_bit_inuse[HASH_TABLES] = { 0 };

    int hash_dist_groups[HASH_DIST_UNITS] = {-1, -1};
    friend class IXBarRealign;

 public:
    /** attached tables that have been accounted for in the current IXBar state -- since
     * they might be attached to more than one match table, and we only want to account
     * for them once. */
    std::unordered_set<const IR::Attached *>                attached_tables;
    enum byte_type_t { NO_BYTE_TYPE, ATCAM, PARTITION_INDEX, RANGE };


    /** IXbar::Use tracks the input xbar use of a single table */
    struct Use {
        /* everything is public so anyone can read it, but only IXBar should write to this */
        enum flags_t { NeedRange = 1, NeedXor = 2,
                       Align16lo = 4, Align16hi = 8, Align32lo = 16, Align32hi = 32 };
        bool            ternary;
        bool            atcam;
        bool            gw_search_bus;  int gw_search_bus_bytes;
        bool            gw_hash_group;


        // enum use_type_t { Match, Gateway, Selector, StatefulAlu, HashDist, NotSet } use_type;
        /* tracking individual bytes (or parts of bytes) placed on the ixbar */
        struct Byte {
            cstring     field;
            int         lo, hi;
            Loc         loc;
            // the PHV container bits the match will be performed on
            bitvec      bit_use;
            // flags describing alignment and gateway use/requirements
            int         flags = 0;

            // If the byte has to appear twice in the match format for atcam as it is a ternary
            bool        atcam_double = false;
            // If the byte is part of the partition index of an atcam table
            bool        atcam_index = false;

            // If the byte is to be a range match, with the lo nibble used
            bool        range_lo = false;
            // If the byte is to be a range match, with the hi nibble used
            bool        range_hi = false;

            // Which search bus this byte belongs to.  Used rather than groups in table format
            // as the Byte can appear once on the input xbar
            int         search_bus = -1;
            // Given a byte appearing multiple times within the match format, which one it is
            int         match_index = 0;

            Byte(cstring f, int l, int h) : field(f), lo(l), hi(h) {}
            Byte(cstring f, int l, int h, int g, int gb) : field(f), lo(l), hi(h), loc(g, gb) {}
            Byte(const Byte &) = default;
            operator std::pair<cstring, int>() const { return std::make_pair(field, lo); }
            bool operator==(const std::pair<cstring, int> &a) const {
                return field == a.first && lo == a.second; }
            bool operator==(const Byte &b) const {
                return field == b.field && lo == b.lo && hi == b.hi;
            }
            bool operator<(const Byte &b) const {
                if (field != b.field) return field < b.field;
                if (lo != b.lo) return lo < b.lo;
                if (hi != b.hi) return hi < b.hi;
                return match_index < b.match_index;
            }
            bool is_range() const { return range_lo || range_hi; }
            void unallocate() { search_bus = -1;  loc.group = -1;  loc.byte = -1; }
        };
        safe_vector<Byte>    use;

        /* which of the 16 hash tables we are using (bitvec) */
        unsigned        hash_table_inputs[HASH_GROUPS] = { 0 };
        /* values fed through the hash tables onto the upper 12 bits of the hash bus via
         * an identity matrix */
        struct Bits {
            cstring     field;
            int         group;
            int         lo, bit, width;
            Bits(cstring f, int g, int l, int b, int w)
            : field(f), group(g), lo(l), bit(b), width(w) {}
            int hi() const { return lo + width - 1; } };
        safe_vector<Bits>    bit_use;

        /* hash tables used for way address computation */
        struct Way {
            int         group, slice;  // group refers to which 8 of the hash groups used,
                                       // slice refers to the 10b way used
            unsigned    mask;
            Way() = delete;
            Way(int g, int s, unsigned m) : group(g), slice(s), mask(m) {} };
        safe_vector<Way>     way_use;

        struct Select {
            int                         group = -1;
            unsigned                    bit_mask = 0;
            IR::MAU::hash_function      algorithm;
            cstring                     mode;
            explicit Select(int g) : group(g), bit_mask(0) {}
        };
        safe_vector<Select> select_use;

        struct HashDistHash {
            bool allocated = false;
            int unit = -1;  // which of the two hash
            int group = -1;
            unsigned slice = 0;  // bitmask of the 3 hash distributions pre-units
            unsigned long               bit_mask = 0;
            std::map<int, bitrange>     bit_starts;
            IR::MAU::hash_function      algorithm;

            void clear() {
                allocated = false;
                unit = -1;
                group = -1;
                slice = 0;
                bit_mask = 0;
                bit_starts.clear();
            }
        };

        HashDistHash hash_dist_hash;
        void clear() { use.clear(); memset(hash_table_inputs, 0, sizeof(hash_table_inputs));
                       bit_use.clear(); way_use.clear(); select_use.clear();
                       hash_dist_hash.clear(); }
        unsigned compute_hash_tables();
        int groups() const;  // how many different groups in this use
        void add(const Use &alloc);
        int hash_groups() const;

        typedef safe_vector<safe_vector<Byte> *> TotalBytes;

        struct GroupInfo {
            int search_bus;
            int ixbar_group;
            int bytes;
            int bits;

            GroupInfo(int sb, int ig, int by, int b)
                : search_bus(sb), ixbar_group(ig), bytes(by), bits(b) { }
        };

        struct TotalInfo {
            int hash_group;
            safe_vector<GroupInfo> all_group_info;

            TotalInfo(int hg, safe_vector<GroupInfo> agi)
                : hash_group(hg), all_group_info(agi) { }
        };

        TotalBytes match_hash(safe_vector<int> *hash_groups = nullptr) const;
        TotalBytes atcam_match() const;
        safe_vector<TotalInfo> bits_per_search_bus() const;
        safe_vector<Byte> atcam_partition(int *hash_group = nullptr) const;
        int search_buses_single() const;
        int gateway_group() const;
    };

    struct HashDistUse {
        enum HashDistType { COUNTER_ADR, METER_ADR, ACTION_ADR, IMMEDIATE, PRECOLOR,
                            HASHMOD, UNKNOWN } type = UNKNOWN;
        IXBar::Use use;
        /** The pre-slice number comes from the following calculation:
         *      hash_dist_hash.unit * HASH_DIST_SLICES (3) + (bit position in) hash_dist_hash.slice
         *  This gives each hash distribution slice coming from the input xbar a location within
         *  hash distribution.
         */
        safe_vector<int> pre_slices;
        std::map<int, int> expand;  // Controls the mau_hash_group_expand register
        /** The actual slices, which will be the output in the asm_output, which are the pre-slice
         *  post expansion
         */
        safe_vector<int> slices;
        std::map<int, int> groups;  // Indicates which hash group the hash dist is linked to
        std::map<int, int> shifts;  // Controls the mau_hash_group_shift register per unit
        std::map<int, bitvec> masks;  // Control the mau_hash_group_mask register per unit
        // Classification of what the hash distribution is used for
        const IR::MAU::HashDist *original_hd;
        const IR::Expression *field_list;  // For a comparison between IR::HashDist and this

        void clear() {
            use.clear();
            pre_slices.clear();
            expand.clear();
            slices.clear();
            shifts.clear();
            masks.clear();
        }
        explicit HashDistUse(const IR::MAU::HashDist* hd) : use(), original_hd(hd) {}
    };


    /* A problem occurred with the way the IXbar was allocated that requires backtracking
     * and trying something else */
    struct failure : public Backtrack::trigger {
        int     stage = -1, group = -1;
        failure(int stg, int grp) : trigger(OTHER), stage(stg), group(grp) {}
    };


/* An individual SRAM group or half of a TCAM group */
    struct grp_use {
        enum type_t { MATCH, HASH_DIST, FREE };
        int group;
        bitvec found;
        bitvec free;
        bool attempted = false;
        bool hash_open[2] = { true, true };
        type_t hash_table_type[2] = { FREE, FREE };

        bool hash_dist_avail(int ht) const {
            return hash_table_type[ht] == HASH_DIST || hash_table_type[ht] == FREE;
        }

        bool hash_dist_only(int ht) const {
            return hash_table_type[ht] == HASH_DIST;
        }

        void dbprint(std::ostream &out) const {
            out << group << " found: " << found << " free: " << free;
        }

        int total_avail() const { return found.popcount() + free.popcount(); }

        explicit grp_use(int g) : group(g) {}
    };

    struct mid_byte_use {
        int group;
        bool found = false;
        bool free = false;
        bool attempted = false;

        void dbprint(std::ostream &out) const {
            out << group << " found: " << found << " free: " << free;
        }
        explicit mid_byte_use(int g) : group(g) {}
    };

    struct hash_matrix_reqs {
        int index_groups = 0;
        int select_bits = 0;
        bool hash_dist = false;

        static hash_matrix_reqs max(bool hd, bool ternary = false) {
            hash_matrix_reqs rv;
            if (ternary)
                return rv;
            rv.hash_dist = hd;
            if (rv.hash_dist) {
                rv.index_groups = HASH_DIST_SLICES;
            } else {
                rv.index_groups = HASH_INDEX_GROUPS;
                rv.select_bits = HASH_SINGLE_BITS;
            }
            return rv;
        }

        hash_matrix_reqs() {}
        hash_matrix_reqs(int ig, int sb, bool hd)
            : index_groups(ig), select_bits(sb), hash_dist(hd) {}
    };


    void clear();
    bool allocMatch(bool ternary, const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                    safe_vector<IXBar::Use::Byte *> &alloced, hash_matrix_reqs &hm_reqs);
    bool allocPartition(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                        bool second_try);
    int getHashGroup(unsigned hash_table_input);
    void getHashDistGroups(unsigned hash_table_input, int hash_group_opt[2]);
    bool allocAllHashWays(bool ternary, const IR::MAU::Table *tbl, Use &alloc,
                          const LayoutOption *layout_option,
                          size_t start, size_t last);
    bool allocHashWay(const IR::MAU::Table *tbl,
                      const LayoutOption *layout_option,
                      size_t index, size_t start, Use &alloc);
    bool allocGateway(const IR::MAU::Table *, const PhvInfo &phv, Use &alloc, bool second_try);
    bool allocSelector(const IR::MAU::Selector *, const IR::MAU::Table *, const PhvInfo &phv,
                       Use &alloc, cstring name);
    bool allocStateful(const IR::MAU::StatefulAlu *, const PhvInfo &phv, Use &alloc);
    bool allocMeter(const IR::MAU::Meter *, const PhvInfo &phv, Use &alloc);
    bool allocHashDist(const IR::MAU::HashDist *hd, IXBar::HashDistUse::HashDistType hdt,
                       const PhvInfo &phv, const ActionFormat::Use *af, IXBar::Use &alloc,
                       bool second_try, cstring name);
    bool allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                    const LayoutOption *lo, const ActionFormat::Use *af);
    void update(cstring name, const Use &alloc);
    void update(cstring name, const TableResourceAlloc *alloc);
    void update(const IR::MAU::Table *tbl) {
        if (tbl->resources) update(tbl->name, tbl->resources); }
    friend std::ostream &operator<<(std::ostream &, const IXBar &);
    const Loc *findExactByte(cstring name, int byte) const {
        for (auto &p : Values(exact_fields.equal_range(name)))
            if (exact_use.at(p.group, p.byte).second/8 == byte)
                return &p;
        /* FIXME -- what if it's in more than one place? */
        return nullptr; }

 private:
    int groups(bool ternary) const;
    int mid_bytes(bool ternary) const;
    int bytes_per_group(bool ternary) const;

    bool calculate_sizes(safe_vector<Use::Byte> &alloc_use, bool ternary, int &total_bytes_needed,
        int &groups_needed, int &mid_bytes_needed);
    bool find_alloc(safe_vector<Use::Byte> &alloc_use, bool ternary,
        safe_vector<Use::Byte> &alloced, hash_matrix_reqs &hm_reqs, unsigned byte_mask = ~0U);
    void initialize_orders(safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        bool ternary);
    void setup_byte_vectors(safe_vector<Use::Byte> &alloc_use, bool ternary,
        safe_vector<Use::Byte *> &unalloced, safe_vector<Use::Byte *> &alloced,
        safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        hash_matrix_reqs &hm_reqs, unsigned byte_mask);

    void print_groups(safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        bool ternary);
    void fill_out_use(safe_vector<IXBar::Use::Byte *> &alloced, bool ternary);
    void calculate_available_groups(safe_vector<grp_use> &order, hash_matrix_reqs &hm_reqs);
    void calculate_available_hash_dist_groups(safe_vector<grp_use> &order,
        hash_matrix_reqs &hm_reqs);
    grp_use::type_t is_group_for_hash_dist(int hash_table);
    bool violates_hash_constraints(safe_vector <grp_use> &order, bool hash_dist, int group,
        int byte);
    void reset_orders(safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order);
    void calculate_found(safe_vector<Use::Byte *> &unalloced, safe_vector<grp_use> &order,
        safe_vector<mid_byte_use> &mid_byte_order, bool ternary, bool hash_dist,
        unsigned byte_mask);
    void calculate_free(safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        bool ternary, bool hash_dist, unsigned byte_mask);
    void found_bytes(grp_use *grp, safe_vector<IXBar::Use::Byte *> &unalloced, bool ternary,
        int &match_bytes_placed, int search_bus);
    void found_mid_bytes(mid_byte_use *mb_grp, safe_vector<Use::Byte *> &unalloced,
        bool ternary, int &match_bytes_placed, int search_bus, bool &version_placed);
    void free_bytes(grp_use *grp, safe_vector<Use::Byte *> &unalloced,
        safe_vector<Use::Byte *> &alloced, bool ternary, bool hash_dist, int &match_bytes_placed,
        int search_bus);
    void free_mid_bytes(mid_byte_use *mb_grp, safe_vector<Use::Byte *> &unalloced,
        safe_vector<Use::Byte *> &alloced, int &match_bytes_placed, int search_bus,
        bool &version_placed);
    void allocate_byte(grp_use *grp, safe_vector<IXBar::Use::Byte *> &unalloced,
        safe_vector<IXBar::Use::Byte *> *alloced, IXBar::Use::Byte &need, int group,
        int byte, size_t &index, int &free_bytes, int &ixbar_bytes_placed,
        int &match_bytes_placed, int search_bus);
    void allocate_mid_bytes(safe_vector<Use::Byte *> &unalloced,
        safe_vector<Use::Byte *> &alloced, bool ternary, bool prefer_found,
        safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        int mid_bytes_needed, int &bytes_to_allocate, bool &version_placed);
    void allocate_groups(safe_vector<Use::Byte *> &unalloced, safe_vector<Use::Byte *> &alloced,
        bool ternary, bool prefer_found, safe_vector<grp_use> &order,
        safe_vector<mid_byte_use> &mid_byte_order, int &bytes_to_allocate, int groups_needed,
        bool hash_dist, unsigned byte_mask);
    bool version_placeable(bool version_placed, int mid_bytes_needed, int groups_needed);
    bool find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use, bool ternary,
        safe_vector<IXBar::Use::Byte *> &alloced, hash_matrix_reqs &hm_reqs,
        unsigned byte_mask = ~0U);
    hash_matrix_reqs match_hash_reqs(const LayoutOption *lo, size_t start, size_t end,
        bool ternary);
    void layout_option_calculation(const LayoutOption *layout_option,
                                   size_t &start, size_t &last);
    void field_management(const IR::Expression *field, IXBar::Use &alloc,
        std::map<cstring, bitvec> &fields_needed, bool hash_dist, cstring name, const PhvInfo &phv,
        bool is_atcam = false, bool partition = false);
    bool allocHashDistAddress(const IR::MAU::HashDist *hd, const unsigned used_hash_dist_groups,
        const unsigned long used_hash_dist_bits, const unsigned &hash_table_input,
        unsigned &slice, unsigned long &bit_mask, std::map<int, bitrange> &bit_starts,
        cstring name);
    bool allocHashDistImmediate(const IR::MAU::HashDist *hd, const ActionFormat::Use *af,
        const unsigned used_hash_dist_slices, const unsigned &hash_table_input, unsigned &slice,
        unsigned long &bit_mask, std::map<int, bitrange> &bit_starts, cstring name);
};

inline std::ostream &operator<<(std::ostream &out, const IXBar::Loc &l) {
    return out << '(' << l.group << ',' << l.byte << ')'; }

inline std::ostream &operator<<(std::ostream &out, const IXBar::Use::Byte &b) {
    out << b.field << '[' << b.lo << ".." << b.hi << ']';
    if (b.loc) out << b.loc;
    if (b.flags) out << " flags=" << hex(b.flags);
    return out; }

#endif /* BF_P4C_MAU_INPUT_XBAR_H_ */
