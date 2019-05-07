#ifndef BF_P4C_MAU_INPUT_XBAR_H_
#define BF_P4C_MAU_INPUT_XBAR_H_

#include <array>
#include <map>
#include <random>
#include <unordered_set>
#include "bf-p4c/mau/ixbar_expr.h"
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"
#include "lib/alloc.h"
#include "lib/hex.h"
#include "lib/safe_vector.h"


class IXBarRealign;
struct TableResourceAlloc;

/// Compiler generated random number function for use as hash seed on the input crossbar.
struct IXBarRandom {
    static std::random_device seed_generator;
    static unsigned seed;
    static std::mt19937 mersenne_generator;
    /// Uniform distribution producing a 10-bit random number.
    static std::uniform_int_distribution<unsigned> distribution10;
    /// Uniform distribution producing either a 0 or a 1.
    static std::uniform_int_distribution<unsigned> distribution1;
    /// @returns a new random number which can be represented by @numBits.
    /// If numBits != 10 or numBits != 12, then this function returns a random bit.
    static unsigned nextRandomNumber(unsigned numBits = 1);
};

struct IXBar {
    static constexpr int EXACT_GROUPS = 8;
    static constexpr int EXACT_BYTES_PER_GROUP = 16;
    static constexpr int HASH_TABLES = 16;
    static constexpr int HASH_GROUPS = 8;
    static constexpr int HASH_INDEX_GROUPS = 4;  /* groups of 10 bits for indexing */
    static constexpr int HASH_SINGLE_BITS = 12;  /* top 12 bits of hash table individually */
    static constexpr int RAM_SELECT_BIT_START = 40;
    static constexpr int RAM_LINE_SELECT_BITS = 10;
    static constexpr int HASH_MATRIX_SIZE = RAM_SELECT_BIT_START + HASH_SINGLE_BITS;
    static constexpr int HASH_DIST_SLICES = 3;
    static constexpr int HASH_DIST_BITS = 16;
    static constexpr int HASH_DIST_EXPAND_BITS = 7;
    static constexpr int HASH_DIST_MAX_MASK_BITS = HASH_DIST_BITS + HASH_DIST_EXPAND_BITS;
    static constexpr int HASH_DIST_UNITS = 2;
    static constexpr int TOFINO_METER_ALU_BYTE_OFFSET = 8;
    static constexpr int LPF_INPUT_BYTES = 4;
    static constexpr int TERNARY_GROUPS = StageUse::MAX_TERNARY_GROUPS;
    static constexpr int BYTE_GROUPS = StageUse::MAX_TERNARY_GROUPS/2;
    static constexpr int TERNARY_BYTES_PER_GROUP = 5;
    static constexpr int TERNARY_BYTES_PER_BIG_GROUP = 11;
    static constexpr int GATEWAY_SEARCH_BYTES = 4;
    static constexpr int RESILIENT_MODE_HASH_BITS = 51;
    static constexpr int FAIR_MODE_HASH_BITS = 14;
    static constexpr int METER_ALU_HASH_BITS = 51;
    static constexpr int METER_PRECOLOR_SIZE = 2;
    static constexpr int MAX_HASH_BITS = 51;
    static constexpr int REPEATING_CONSTRAINT_SECT = 4;

    struct Loc {
        int group = -1, byte = -1;
        Loc() = default;
        Loc(int g, int b) : group(g), byte(b) {}
        Loc(const Loc &) = default;
        explicit operator bool() const { return group >= 0 && byte >= 0; }
        operator std::pair<int, int>() const { return std::make_pair(group, byte); }
        /// return the byte number in the total order
        bool operator==(const Loc &loc) const {
            return group == loc.group && byte == loc.byte;
        }
        bool operator!=(const Loc &loc) const { return !(*this == loc); }
        int getOrd(const bool isTernary = false) const {
            if ((*this)) {
                if (isTernary)
                    return EXACT_GROUPS * EXACT_BYTES_PER_GROUP +
                        ((group/2) * TERNARY_BYTES_PER_BIG_GROUP) +
                        (group % 2) * (TERNARY_BYTES_PER_GROUP) +
                        (group % 2) /* mid byte */ + byte;
                else
                    return (group * EXACT_BYTES_PER_GROUP) + byte;
            } else {
                return -1;
            }
        }
        bool allocated() const { return group >= 0 && byte >= 0; }
    };

    enum byte_speciality_t {
        NONE,
        // Byte has to appear twice in the match for S0Q1 and S1Q0, but only once on the IXBar
        ATCAM_DOUBLE,
        // Byte does not have to appear on the match, as it is the partition index
        ATCAM_INDEX,
        // TCAM byte encoded with the 4b_lo_range match
        RANGE_LO,
        // TCAM byte encoded with the 4b_hi_range match
        RANGE_HI,
        BYTE_SPECIALITIES
    };

    /** Information on a single stretch of field within a Input XBar Byte, which comes
     *  from the P4 program, i.e. say the following was a key:
     *
     *      key { hdr.nibble1 : exact;  hdr.nibble2 : exact; }
     *
     *  where hdr.nibble1 and hdr.nibble2 are both 4 bit fields in the same Container Byte,
     *  i.e. H0(0..7).  Then each P4 field would have a FieldInfo, and the Use::Byte would
     *  have a vector of two FieldInfo objects.
     */
    struct FieldInfo {
        cstring field;  ///> name of the field
        int lo;         ///> lo field bit in that byte
        int hi;         ///> hi field bit in that byte
        int cont_lo;    ///> mod 8 location in the container that the bitrange of field begins
        boost::optional<cstring> aliasSource;
                        ///> name of alias source field, if present

        FieldInfo(cstring n, int l, int h, int cl, boost::optional<cstring> a)
            : field(n), lo(l), hi(h), cont_lo(cl) {
            if (a)
                aliasSource = *a;
            else
                aliasSource = boost::none;
        }

        cstring get_use_name() const {
            if (aliasSource == boost::none)
                return field;
            else
                return *aliasSource;
        }

        bool operator==(const FieldInfo &fi) const {
            return field == fi.field && lo == fi.lo && hi == fi.hi;
        }
        bool operator<(const FieldInfo &fi) const {
            if (field != fi.field) return field < fi.field;
            if (lo != fi.lo) return lo < fi.lo;
            if (hi != fi.hi) return hi < fi.hi;
            return false;
        }

        bool operator!=(const FieldInfo &fi) const {
            return !((*this) == fi);
        }

        int width() const {
            return hi - lo + 1;
        }

        int cont_hi() const { return cont_lo + width() - 1; }

        le_bitrange range() const { return { lo, hi }; }

        bitvec cont_loc() const {
            return bitvec(cont_lo, width());
        }

        std::string visualization_detail() const;
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
    unsigned                                    hash_index_inuse[HASH_INDEX_GROUPS] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_INDEX_GROUPS>    hash_index_use;
    Alloc2D<cstring, HASH_TABLES, HASH_SINGLE_BITS>     hash_single_bit_use;
    unsigned                                    hash_single_bit_inuse[HASH_SINGLE_BITS] = { 0 };
    Alloc1D<cstring, HASH_GROUPS>                      hash_group_print_use;
    unsigned                                    hash_group_use[HASH_GROUPS] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_DIST_SLICES>     hash_dist_use;
    bitvec                                      hash_dist_inuse[HASH_TABLES] = { bitvec() };
    Alloc2D<cstring, HASH_TABLES, HASH_DIST_SLICES * HASH_DIST_BITS>   hash_dist_bit_use;
    bitvec                                      hash_dist_bit_inuse[HASH_TABLES] = { bitvec() };

    int hash_dist_groups[HASH_DIST_UNITS] = {-1, -1};
    friend class IXBarRealign;


 public:
    /** attached tables that have been accounted for in the current IXBar state -- since
     * they might be attached to more than one match table, and we only want to account
     * for them once. */
    ordered_set<const IR::MAU::AttachedMemory *>            attached_tables;
    std::set<cstring>                                       dleft_updates;

    enum byte_type_t { NO_BYTE_TYPE, ATCAM, PARTITION_INDEX, RANGE };
    enum HashDistDest_t  { HD_IMMED_LO, HD_IMMED_HI, HD_STATS_ADR, HD_METER_ADR,
                           HD_ACTIONDATA_ADR, HD_PRECOLOR, HD_HASHMOD, HD_DESTS };

    /** IXbar::Use tracks the input xbar use of a single table */
    struct Use {
        /* everything is public so anyone can read it, but only IXBar should write to this */
        enum flags_t { NeedRange = 1, NeedXor = 2,
                       Align16lo = 4, Align16hi = 8, Align32lo = 16, Align32hi = 32 };
        bool            ternary = false;
        bool            atcam = false;
        bool            gw_search_bus = false;
        int             gw_search_bus_bytes = 0;
        bool            gw_hash_group = false;

        bool search_data() const { return gw_search_bus || gw_hash_group; }

        // FIXME: Could be better created initialized through a constructor
        enum type_t { MATCH, GATEWAY, PROXY_HASH, SELECTOR, METER, STATEFUL_ALU, HASH_DIST, TYPES }
            type = TYPES;

        HashDistDest_t hash_dist_type = HD_DESTS;

        std::string used_by;
        std::string used_for() const;
        std::string hash_dist_used_for() const;

        /* tracking individual bytes (or parts of bytes) placed on the ixbar */
        struct Byte {
            // the PHV container name
            cstring     name;
            //
            int         lo;
            Loc         loc;
            // the PHV container bits the match will be performed on
            bitvec      bit_use;
            // the PHV container bits that are potentially non-zero valued
            bitvec      non_zero_bits;
            // flags describing alignment and gateway use/requirements
            int         flags = 0;
            unsigned specialities = 0;
            safe_vector<FieldInfo> field_bytes;

            void set_spec(byte_speciality_t bs) {
                specialities |= (1 << bs);
            }

            void clear_spec(byte_speciality_t bs) {
                specialities &= ~(1 << bs);
            }

            bool is_spec(byte_speciality_t bs) const {
                return specialities & (1 << bs);
            }

            // Which search bus this byte belongs to.  Used rather than groups in table format
            // as the Byte can appear once on the input xbar
            int         search_bus = -1;
            // Given a byte appearing multiple times within the match format, which one it is
            int         match_index = 0;
            // A index given to each range index, as there are constraints on the multirange
            // distribution that leads to some restrictions on range fields
            int         range_index = -1;
            // When converting a byte to proxy hash, this is the byte in the table format
            // in which the hash is provide
            bool        proxy_hash = false;

            Byte(cstring n, int l) : name(n), lo(l) {}
            Byte(cstring n, int l, int g, int gb) : name(n), lo(l), loc(g, gb) {}
            Byte(const Byte &) = default;
            operator std::pair<cstring, int>() const { return std::make_pair(name, lo); }
            bool operator==(const std::pair<cstring, int> &a) const {
                return name == a.first && lo == a.second; }
            bool operator==(const Byte &b) const {
                return name == b.name && lo == b.lo;
            }
            bool operator<(const Byte &b) const {
                if (name != b.name) return name < b.name;
                if (lo != b.lo) return lo < b.lo;
                if (match_index != b.match_index) return match_index < b.match_index;
                // Sort by specialities to prevent combining bytes that have different
                // specialities in create_alloc
                if (specialities != b.specialities) return specialities < b.specialities;
                // Due to limitations in range fields being spread across multiple TCAM,
                // only one range field is allowed per byte
                if (range_index != b.range_index) return range_index < b.range_index;
                if (field_bytes != b.field_bytes) return field_bytes < b.field_bytes;
                return false;
            }
            bool is_range() const { return is_spec(RANGE_LO) || is_spec(RANGE_HI); }
            void unallocate() { search_bus = -1;  loc.group = -1;  loc.byte = -1; }
            std::string visualization_detail() const;
            bool is_subset(const Byte &b) const;

            bool can_add_info(const FieldInfo &fi) const;
            void add_info(const FieldInfo &fi);
        };
        safe_vector<Byte>    use;

        bool allocated() { return !use.empty(); }

        /* which of the 16 hash tables we are using (bitvec) */
        unsigned        hash_table_inputs[HASH_GROUPS] = { 0 };
        /* hash seed for different hash groups */
        bitvec          hash_seed[HASH_GROUPS];

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
                                       // slice = bit / 10
            // Upper 12 bits. Also want a seed over the bits used in the mask.
            unsigned    mask;
            Way() = delete;
            Way(int g, int s, unsigned m) : group(g), slice(s), mask(m) {} };
        safe_vector<Way>     way_use;

        struct MeterAluHash {
            bool allocated = false;
            int group = -1;
            bitvec bit_mask;
            IR::MAU::HashFunction algorithm;
            std::map<int, const IR::Expression *> computed_expressions;

            void clear() {
                allocated = false;
                group = -1;
                bit_mask.clear();
                // identity_positions.clear();
                computed_expressions.clear();
            }
        };
        MeterAluHash meter_alu_hash;

        struct HashDistHash {
            bool allocated = false;
            int group = -1;
            bitvec galois_matrix_bits;
            IR::MAU::HashFunction algorithm;
            std::map<int, le_bitrange> galois_start_bit_to_p4_hash;

            void clear() {
                allocated = false;
                group = -1;
                galois_matrix_bits.clear();
                galois_start_bit_to_p4_hash.clear();
            }
        };

        struct ProxyHashKey {
            bool allocated = false;
            int group = -1;
            bitvec hash_bits;
            IR::MAU::HashFunction algorithm;
            cstring alg_name;

            void clear() {
                allocated = false;
                group = -1;
                hash_bits.clear();
            }
        };

        ProxyHashKey proxy_hash_key_use;

        // The order in the P4 program that the fields appear in the list
        safe_vector<const IR::Expression *> field_list_order;
        HashDistHash hash_dist_hash;

        void clear() {
            use.clear();
            memset(hash_table_inputs, 0, sizeof(hash_table_inputs));
            bit_use.clear();
            way_use.clear();
            meter_alu_hash.clear();
            for (size_t i = 0; i < HASH_GROUPS; i++)
                hash_seed[i].clear();
            hash_dist_hash.clear();
            proxy_hash_key_use.clear();
            field_list_order.clear();
        }

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

            void dbprint(std::ostream &out) const {
                out << "Search bus: " << search_bus << ", IXBar group: " << ixbar_group
                    << ", Bytes : " << bytes << ", Bits : " << bits;
            }
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
        int total_input_bits() const {
            int rv = 0;
            for (auto fl : field_list_order) {
                rv += fl->type->width_bits();
            }
            return rv;
        }
    };

    /** The purpose of this structure is to capture that multiple stretch of fields can
     *  be contained within the same container byte.  In the add_use function, each FieldInfo
     *  object will be created, and linked to a corresponding container byte.  Later, in the
     *  create_alloc function, these individual FieldInfo object will be used to create at least
     *  a single byte, (and maybe more due to overlay issues), that the compiler needs to allocate
     *  for an input xbar.
     */
    typedef std::map<Use::Byte, safe_vector<FieldInfo>> ContByteConversion;

    static HashDistDest_t dest_location(const IR::Node *node, bool precolor = false);
    static std::string hash_dist_name(HashDistDest_t dest);

    struct HashDistIRUse {
        IXBar::Use use;
        le_bitrange p4_hash_range;
        HashDistDest_t dest;
        // Only currently used for dynamic hash.  Goal is to remove
        const IR::MAU::HashDist *original_hd;
        cstring dyn_hash_name;
        bool is_dynamic() const { return !dyn_hash_name.isNull(); }
    };

    struct HashDistUse {
        safe_vector<HashDistIRUse> ir_allocations;
        int expand = -1;
        int unit = -1;
        int shift = -1;
        bitvec mask;

        std::set<cstring> outputs;

        int hash_group() const;
        bitvec destinations() const;
        unsigned hash_table_inputs() const;

        cstring used_by;
        std::string used_for() const;

        void clear() {
            ir_allocations.clear();
            expand = -1;
            unit = -1;
            shift = 0;
            mask.clear();
            outputs.clear();
        }
    };

    /**
     * Class to capture the idea of a P4 hash function.  This is the P4 related inputs, an
     * algorithm, and the particular slice of P4 hash.
     *
     * 
     * From the current language:
     *     Hash hash<type>(HashAlgorithm);
     *     hash.get({ f1, constant1, f2, f3})[hi..lo];
     *
     * the inputs are the fields within the function, the algorithm is HashAlgorithm defined in
     * the extern, and the hash_bits are the hi..lo portion of the slice
     */

    /*
    struct P4HashFunction {
        safe_vector<const IR::Expression *> inputs;
        le_bitrange hash_bits;
        IR::MAU::HashFunction algorithm;
        P4HashFunction split(le_bitrange split) const;
    };
    */


    /**
     * The Hash Distribution Unit is captured in uArch section 6.4.3.5.3 Hash Distribution.
     * This is sourcing calculations from the Galois matrix and sends them to various locations
     * in the MAU, as discussed in the comments above allocHashDist.
     *
     * This captures the data that will pass to a single possible destination after the expand
     * but before the Mask/Shift block
     */
    struct HashDistAllocPostExpand {
        P4HashFunction *func;
        le_bitrange bits_in_use;
        HashDistDest_t dest;
        int shift;
        // Only currently used for dynamic hash.  Goal is to remove
        const IR::MAU::HashDist *original_hd;
        // Workaround for multi-stage fifo tests.  Goal is to remove this as well and have
        // the hash/compiler to generate this individually and determine it, but that's not
        // very optimal in the given structure
        bool chained_addr = false;
        bitvec possible_shifts() const;

     public:
        HashDistAllocPostExpand(P4HashFunction *f, le_bitrange b, HashDistDest_t d, int s)
            : func(f), bits_in_use(b), dest(d), shift(s) {}
    };


    class XBarHashDist : public MauInspector {
        safe_vector<HashDistAllocPostExpand> alloc_reqs;
        IXBar &self;
        const PhvInfo &phv;
        const IR::MAU::Table *tbl;
        const ActionFormat::Use *af;
        const LayoutOption *lo;
        TableResourceAlloc *resources;

        void build_action_data_req(const IR::MAU::HashDist *hd);
        void build_req(const IR::MAU::HashDist *hd, const IR::Node *rel_node);

        void build_function(const IR::MAU::HashDist *hd, P4HashFunction **func,
            le_bitrange *bits = nullptr);
        bool preorder(const IR::MAU::HashDist *) override;
        bool preorder(const IR::MAU::TableSeq *) override { return false; }
        bool preorder(const IR::MAU::AttachedOutput *) override { return false; }
        bool preorder(const IR::MAU::StatefulCall *) override { return false; }
        void immediate_inputs(const IR::MAU::HashDist *hd);

     public:
        void hash_action();
        bool allocate_hash_dist();
        XBarHashDist(IXBar &s, const PhvInfo &p, const IR::MAU::Table *t,
                const ActionFormat::Use *a, const LayoutOption *l, TableResourceAlloc *r)
            : self(s), phv(p), tbl(t), af(a), lo(l), resources(r) {}
    };

/* A problem occurred with the way the IXbar was allocated that requires backtracking
     * and trying something else */
    struct failure : public Backtrack::trigger {
        int     stage = -1, group = -1;
        failure(int stg, int grp) : trigger(OTHER), stage(stg), group(grp) {}
    };

    enum AvailBytesPerRepeatingSect_t { AV_FULL = 1, AV_HALF = 2, AV_BYTE = 4 };

/* An individual SRAM group or half of a TCAM group */
    struct grp_use {
        enum type_t { MATCH, HASH_DIST, FREE };
        int group;
        /**
         * The byte positions in the grp_use that are equivalent some input xbar bytes, i.e.
         * if 2 tables are matching on the same field, after the first one is allocated, the
         * second would see this on the grp_use as possible to share
         */
        bitvec found;

        /**
         * The byte positions in the grp_use that are not used by any table, and are open.
         * Due to the nature of the constraints mentioned on the comments on is_better_group,
         * the available bytes are stored in an 4 wide array.  At each index i, the bitvec
         * is the available bytes for a 32 bit container byte at byte offset i.
         *
         * The free() function passes a parameter which of these four indices can a particularly
         * constrained byte can allocate to.  For instance, a 32 bit byte 1 will have an
         * can_use of 0x2, a 16 bit byte 0 will have an can_use of 0x5, and an 8 bit byte will
         * have a can_use of 0xf.
         *
         * @seealso is_better_group in input_xbar.cpp
         */
        std::array<bitvec, REPEATING_CONSTRAINT_SECT> _free = { { bitvec() } };
        bitvec free(bitvec can_use) const {
            bitvec rv;
            for (auto bit : can_use)
                rv |= _free.at(bit);
            return rv;
        }

        bitvec max_free() const { return free(bitvec(0, REPEATING_CONSTRAINT_SECT)); }
        bool attempted = false;
        bool hash_open[2] = { true, true };
        type_t hash_table_type[2] = { FREE, FREE };
        int range_index = -1;

        bool hash_dist_avail(int ht) const {
            return hash_table_type[ht] == HASH_DIST || hash_table_type[ht] == FREE;
        }

        bool hash_dist_only(int ht) const {
            return hash_table_type[ht] == HASH_DIST;
        }

        void dbprint(std::ostream &out) const {
            out << group << " found: 0x" << found << " free: 0x" << max_free();
        }

        int total_avail() const { return found.popcount() + max_free().popcount(); }
        bool range_set() const { return range_index != -1; }

        bool is_better_group(const grp_use &b, bool prefer_found,
            int required_allocation_bytes, std::map<int, int> &constraints_to_reqs) const;
        explicit grp_use(int g) : group(g) {}
    };

    struct mid_byte_use {
        int group;
        // @seealso corresponding comments on grp_use
        bool found = false;
        // TODO: This also could be further expanded, similar to the grp_use to be on
        // a constraint basis, but the grp_use has given us enough
        bool free = false;

        bool attempted = false;

        void dbprint(std::ostream &out) const {
            out << group << " found: " << found << " free: " << free;
        }
        explicit mid_byte_use(int g) : group(g) {}
    };

    struct hash_matrix_reqs {
        // The max number of groups that can be used by this table.  Required by gateways,
        // and stateful/meter tables using the search bus
        int max_search_buses = -1;
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

    // Used to determine what phv fields need to be allocated on the input xbar for the
    // stateful ALU to work.  Private internal to allocStateful
    class FindSaluSources : public MauInspector {
        const PhvInfo              &phv;
        ContByteConversion  &map_alloc;
        safe_vector<const IR::Expression *> &field_list_order;
        // Holds which bitranges of fields have been requested, and will not allocate
        // if a bitrange has been requested multiple times
        std::map<cstring, bitvec>  fields_needed;
        const IR::MAU::Table       *tbl;

        profile_t init_apply(const IR::Node *root) override;
        bool preorder(const IR::MAU::StatefulAlu *) override;
        bool preorder(const IR::MAU::SaluAction *) override;
        bool preorder(const IR::Expression *e) override;
        bool preorder(const IR::MAU::HashDist *) override;
        bool preorder(const IR::MAU::IXBarExpression *) override;
        ///> In order to prevent any annotations, i.e. chain_vpn, and determining this as a source
        bool preorder(const IR::Annotation *) override { return false; }
        bool preorder(const IR::Declaration_Instance *) override { return false; }

        static void collapse_contained(std::map<le_bitrange, const IR::Expression *> &m);

     public:
        FindSaluSources(IXBar &, const PhvInfo &phv, ContByteConversion &ma,
                        safe_vector<const IR::Expression *> &flo, const IR::MAU::Table *t)
        : phv(phv), map_alloc(ma), field_list_order(flo), tbl(t) {}

        ordered_map<const PHV::Field *, std::map<le_bitrange, const IR::Expression *>>
                                                        phv_sources;
        std::vector<const IR::MAU::IXBarExpression *>   hash_sources;
        bool                                            dleft = false;
    };

    struct KeyInfo {
        bool hash_dist = false;
        bool is_atcam = false;
        bool partition = false;
        int partition_bits = 0;
        int range_index = 0;
        bool repeats_allowed = true;
        KeyInfo() { }
    };

    struct HashDistAllocParams {
        bitvec used_hash_dist_slices;
        bitvec used_hash_dist_bits;

        bitvec slice;
        bitvec bit_mask;
        std::map<int, le_bitrange> bit_starts;

        void clear() {
            used_hash_dist_slices.clear();
            used_hash_dist_bits.clear();
            slice.clear();
            bit_mask.clear();
            bit_starts.clear();
        }
    };

    ordered_map<const IR::MAU::AttachedMemory *, const IXBar::Use &> allocated_attached;

    void clear();
    class FieldManagement;
    bool allocMatch(bool ternary, const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                    safe_vector<IXBar::Use::Byte *> &alloced, hash_matrix_reqs &hm_reqs);
    bool allocPartition(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                        bool second_try);
    int getHashGroup(unsigned hash_table_input);
    void getHashDistGroups(unsigned hash_table_input, int hash_group_opt[HASH_DIST_UNITS]);
    bool allocProxyHash(const IR::MAU::Table *tbl, const PhvInfo &phv,
        const LayoutOption *lo, Use &alloc, Use &proxy_hash_alloc);
    bool allocProxyHashKey(const IR::MAU::Table *tbl, const PhvInfo &phv, const LayoutOption *lo,
        Use &proxy_hash_alloc, hash_matrix_reqs &hm_reqs);

    bool allocAllHashWays(bool ternary, const IR::MAU::Table *tbl, Use &alloc,
                          const LayoutOption *layout_option,
                          size_t start, size_t last);
    bool allocHashWay(const IR::MAU::Table *tbl, const LayoutOption *layout_option,
        size_t index, std::map<int, bitvec> &slice_to_select_bits, Use &alloc);
    bool allocGateway(const IR::MAU::Table *, const PhvInfo &phv, Use &alloc, bool second_try);
    bool allocSelector(const IR::MAU::Selector *, const IR::MAU::Table *, const PhvInfo &phv,
                       Use &alloc, cstring name);
    bool allocStateful(const IR::MAU::StatefulAlu *, const IR::MAU::Table *, const PhvInfo &phv,
                       Use &alloc, bool on_search_bus);
    bool allocMeter(const IR::MAU::Meter *, const IR::MAU::Table *, const PhvInfo &phv,
                    Use &alloc, bool on_search_bus);
    bool allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                    const LayoutOption *lo, const ActionFormat::Use *af);
    void update(cstring name, const Use &alloc);
    void update(cstring name, const HashDistUse &hash_dist_alloc);
    void update(const IR::MAU::Table *tbl, const TableResourceAlloc *rsrc);
    // void update(cstring name, const TableResourceAlloc *alloc);
    void update(const IR::MAU::Table *tbl);
    friend std::ostream &operator<<(std::ostream &, const IXBar &);
    const Loc *findExactByte(cstring name, int byte) const {
        for (auto &p : Values(exact_fields.equal_range(name)))
            if (exact_use.at(p.group, p.byte).second/8 == byte)
                return &p;
        /* FIXME -- what if it's in more than one place? */
        return nullptr; }

 private:
    bitvec can_use_from_flags(int flags) const;
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
    void allocate_byte(bitvec *bv, safe_vector<IXBar::Use::Byte *> &unalloced,
        safe_vector<IXBar::Use::Byte *> *alloced, IXBar::Use::Byte &need, int group,
        int byte, size_t &index, int &free_bytes, int &ixbar_bytes_placed,
        int &match_bytes_placed, int search_bus, int *range_index);
    void allocate_mid_bytes(safe_vector<Use::Byte *> &unalloced,
        safe_vector<Use::Byte *> &alloced, bool ternary, bool prefer_found,
        safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        int mid_bytes_needed, int &bytes_to_allocate, bool &version_placed);

    int determine_best_group(safe_vector<Use::Byte *> &unalloced, safe_vector<grp_use> &order,
        bool ternary, bool prefer_found, int required_allocation_bytes);

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
    void create_alloc(ContByteConversion &map_alloc, IXBar::Use &alloc);
    void create_alloc(ContByteConversion &map_alloc, safe_vector<Use::Byte> &bytes);
    int max_bit_to_byte(bitvec bit_mask);
    int max_index_group(int max_bit);
    int max_index_single_bit(int max_bit);
    unsigned index_groups_used(bitvec bv) const;
    unsigned select_bits_used(bitvec bv) const;
    bool hash_use_free(int max_group, int max_single_bit, unsigned hash_table_input);
    void write_hash_use(int max_group, int max_single_bit, unsigned hash_table_input,
        cstring name);
    bool can_allocate_on_search_bus(Use &alloc, const PHV::Field *field, le_bitrange range,
        int ixbar_position);
    bool setup_stateful_search_bus(const IR::MAU::StatefulAlu *salu, Use &alloc,
                                   const FindSaluSources &sources, unsigned &byte_mask);
    bool setup_stateful_hash_bus(const PhvInfo &, const IR::MAU::StatefulAlu *salu, Use &alloc,
                                 const FindSaluSources &sources);
    bitvec determine_final_xor(const IR::MAU::HashFunction *hf, const PhvInfo &phv,
        std::map<int, le_bitrange> &bit_starts,
        safe_vector<const IR::Expression *> field_list, int total_input_bits);
    void determine_proxy_hash_alg(const PhvInfo &, const IR::MAU::Table *tbl, Use &use, int group);

    bool isHashDistAddress(HashDistDest_t dest) const;

    void determineHashDistInUse(int hash_group, bitvec &units_in_use, bitvec &hash_bits_in_use);
    void buildHashDistIRUse(HashDistAllocPostExpand &alloc_req, HashDistUse &use,
        IXBar::Use &all_reqs, const PhvInfo &phv, int hash_group, bitvec hash_bits_used,
        bitvec total_post_expand_bits, unsigned hash_table_input, cstring name);
    void lockInHashDistArrays(safe_vector<Use::Byte *> *alloced, int hash_group,
        unsigned hash_table_input, int asm_unit, bitvec hash_bits_used, HashDistDest_t dest,
        cstring name);


    bool allocHashDistSection(bitvec post_expand_bits, bitvec possible_shifts, int hash_group,
        int &unit_allocated, bitvec &hash_bits_allocated);
    bool allocHashDistWideAddress(bitvec post_expand_bits, bitvec possible_shifts, int hash_group,
        bool chained_addr, int &unit_allocated, bitvec &hash_bits_allocated);
    bool allocHashDist(safe_vector<HashDistAllocPostExpand> &alloc_reqs, HashDistUse &use,
        const PhvInfo &phv, cstring name, bool second_try);
    void createChainedHashDist(const HashDistUse &hd_alloc, HashDistUse &chained_hd_alloc,
        cstring name);
};

inline std::ostream &operator<<(std::ostream &out, const IXBar::Loc &l) {
    return out << '(' << l.group << ',' << l.byte << ')'; }

inline std::ostream &operator<<(std::ostream &out, const IXBar::FieldInfo &fi) {
    out << fi.visualization_detail();
    return out;
}

std::ostream &operator<<(std::ostream &, const IXBar::Use &);
inline std::ostream &operator<<(std::ostream &out, const IXBar::Use::Byte &b) {
    out << b.name << '[' << b.lo << ".." << (b.lo + 7) << ']';
    if (b.loc) out << b.loc;
    out << " 0x" << b.bit_use;
    if (b.flags) out << " flags=" << hex(b.flags);
    out << " " << b.visualization_detail();
    return out;
}

#endif /* BF_P4C_MAU_INPUT_XBAR_H_ */
