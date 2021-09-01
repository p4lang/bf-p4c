#ifndef BF_P4C_MAU_INPUT_XBAR_H_
#define BF_P4C_MAU_INPUT_XBAR_H_

#include <array>
#include <map>
#include <random>
#include <unordered_set>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/lib/dyn_vector.h"
#include "bf-p4c/mau/attached_entries.h"
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
    // FIXME -- make these per-device params
    static constexpr int EXACT_GROUPS = 8;
    static constexpr int EXACT_BYTES_PER_GROUP = 16;
    static constexpr int HASH_TABLES = 16;
    static constexpr int HASH_GROUPS = 8;
    static constexpr int HASH_INDEX_GROUPS = 4;  /* groups of 10 bits for indexing */
    static constexpr int HASH_SINGLE_BITS = 12;  /* top 12 bits of hash table individually */
    static constexpr int HASH_PARITY_BIT = 51;  /* If enabled reserved parity bit position */
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
    static constexpr int METER_ALU_HASH_BITS = 52;
    static constexpr int METER_ALU_HASH_PARITY_BYTE_START = 48;
    static constexpr int METER_PRECOLOR_SIZE = 2;
    static constexpr int REPEATING_CONSTRAINT_SECT = 4;
    static constexpr int MAX_HASH_BITS = 52;

    static int get_hash_single_bits() {
        // If hash parity is enabled reserve a bit for parity
        if (!BackendOptions().disable_gfm_parity)
            return HASH_SINGLE_BITS - 1;
        return HASH_SINGLE_BITS;
    }

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

    enum byte_type_t { NO_BYTE_TYPE, ATCAM, PARTITION_INDEX, RANGE };
    enum HashDistDest_t  { HD_IMMED_LO, HD_IMMED_HI, HD_STATS_ADR, HD_METER_ADR,
                           HD_ACTIONDATA_ADR, HD_PRECOLOR, HD_HASHMOD, HD_DESTS };
    enum parity_status_t { PARITY_NONE, PARITY_ENABLED, PARITY_DISABLED };

    /** IXbar::Use tracks the input xbar use of a single table */
    struct Use {
        /* everything is public so anyone can read it, but only IXBar should write to this */
        enum flags_t { NeedRange = 1, NeedXor = 2,
                       Align16lo = 4, Align16hi = 8, Align32lo = 16, Align32hi = 32 };
        bool            gw_search_bus = false;
        int             gw_search_bus_bytes = 0;
        bool            gw_hash_group = false;
        parity_status_t parity = PARITY_NONE;

        bool search_data() const { return gw_search_bus || gw_hash_group; }
        bool is_parity_enabled() const { return parity == PARITY_ENABLED; }

        // FIXME: Could be better created initialized through a constructor
        enum type_t { EXACT_MATCH, ATCAM_MATCH, TERNARY_MATCH, TRIE_MATCH, GATEWAY,
                      PROXY_HASH, SELECTOR, METER, STATEFUL_ALU, HASH_DIST, TYPES }
            type = TYPES;

        HashDistDest_t hash_dist_type = HD_DESTS;

        std::string used_by;
        std::string used_for() const;
        std::string hash_dist_used_for() const;

        /* tracking individual bytes (or parts of bytes) placed on the ixbar */
        struct Byte {
            // the PHV container
            PHV::Container      container;
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

            // Byte(cstring n, int l) : container(n), lo(l) {}
            // Byte(cstring n, int l, int g, int gb) : container(n), lo(l), loc(g, gb) {}
            Byte(PHV::Container c, int l) : container(c), lo(l) {}
            Byte(PHV::Container c, int l, int g, int gb) : container(c), lo(l), loc(g, gb) {}
            Byte(const Byte &) = default;
            operator std::pair<PHV::Container, int>() const {
                return std::make_pair(container, lo); }
            operator std::pair<cstring, int>() const {
                return std::make_pair(container.toString(), lo); }
            bool operator==(const std::pair<PHV::Container, int> &a) const {
                return container == a.first && lo == a.second; }
            bool operator==(const std::pair<cstring, int> &a) const {
                return container.toString() == a.first && lo == a.second; }
            bool operator==(const Byte &b) const {
                return container == b.container && lo == b.lo;
            }
            bool operator<(const Byte &b) const {
                if (container != b.container) return container < b.container;
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
            std::vector<FieldInfo> get_slices_for_visualization() const;
            bool is_subset(const Byte &b) const;
            bool only_one_nibble_in_use() const {
                BUG_CHECK(!bit_use.empty(), "IXBar byte has no data");
                if (is_range()) return false;
                return bit_use.getslice(0, 4).empty() || bit_use.getslice(4, 4).empty();
            }

            bool can_add_info(const FieldInfo &fi) const;
            void add_info(const FieldInfo &fi);
        };
        safe_vector<Byte>    use;

        bool allocated() { return !use.empty(); }

        /* which of the 16 hash tables we are using (bitvec) */
        dyn_vector<unsigned>    hash_table_inputs;
        /* hash seed for different hash groups */
        dyn_vector<bitvec>      hash_seed;

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

        /* tracks hash use for Stateful and Selectors (and meter?) */
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
        } meter_alu_hash;

        /* tracks hash dist use (and hashes */
        struct HashDistHash {
            bool allocated = false;
            int group = -1;
            bitvec galois_matrix_bits;
            IR::MAU::HashFunction algorithm;
            std::map<int, le_bitrange> galois_start_bit_to_p4_hash;
            const IR::Expression *hash_gen_expr = nullptr;   // expression from HashGenExpr
            cstring name;    // Original name in case of hash distribution unit sharing

            void clear() {
                allocated = false;
                group = -1;
                galois_matrix_bits.clear();
                galois_start_bit_to_p4_hash.clear();
            }
        } hash_dist_hash;

        struct ProxyHashKey {
            bool allocated = false;
            int group = -1;
            bitvec hash_bits;
            IR::MAU::HashFunction algorithm;

            void clear() {
                allocated = false;
                group = -1;
                hash_bits.clear();
            }
        } proxy_hash_key_use;

        struct SaluInputSource {
            unsigned    data_bytemask = 0;
            unsigned    hash_bytemask = 0;  // redundant with meter_alu_hash.bit_mask?

            void clear() { data_bytemask = hash_bytemask = 0; }
            bool empty() const { return !data_bytemask && !hash_bytemask; }
        } salu_input_source;

        // The order in the P4 program that the fields appear in the list
        safe_vector<const IR::Expression *> field_list_order;
        LTBitMatrix symmetric_keys;


        void clear() {
            type = TYPES;
            gw_search_bus = false;
            gw_search_bus_bytes = 0;
            gw_hash_group = false;
            parity = PARITY_NONE;
            used_by.clear();
            use.clear();
            hash_table_inputs.clear();
            bit_use.clear();
            way_use.clear();
            meter_alu_hash.clear();
            hash_seed.clear();
            hash_dist_hash.clear();
            proxy_hash_key_use.clear();
            salu_input_source.clear();
            field_list_order.clear();
        }
        bool empty() const {
            return type == TYPES && use.empty() && bit_use.empty() && way_use.empty() &&
                !meter_alu_hash.allocated && !hash_dist_hash.allocated &&
                !proxy_hash_key_use.allocated && salu_input_source.empty(); }

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

    static HashDistDest_t dest_location(const IR::Node *node, bool precolor = false);
    static std::string hash_dist_name(HashDistDest_t dest);

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
        const IR::MAU::HashDist *created_hd;
        // Workaround for multi-stage fifo tests.  Goal is to remove this as well and have
        // the hash/compiler to generate this individually and determine it, but that's not
        // very optimal in the given structure
        bool chained_addr = false;
        bitvec possible_shifts() const;

     public:
        HashDistAllocPostExpand(P4HashFunction *f, le_bitrange b, HashDistDest_t d, int s)
            : func(f), bits_in_use(b), dest(d), shift(s) {}
    };

    struct HashDistIRUse {
        IXBar::Use use;
        le_bitrange p4_hash_range;
        HashDistDest_t dest;
        // Only currently used for dynamic hash.  Goal is to remove
        const IR::MAU::HashDist *created_hd = nullptr;
        cstring dyn_hash_name;
        bool is_dynamic() const { return !dyn_hash_name.isNull(); }
    };

    struct HashDistUse {
        // Source of this translated HashDistUse.
        safe_vector<HashDistAllocPostExpand> src_reqs;

        safe_vector<HashDistIRUse> ir_allocations;
        int expand = -1;
        int unit = -1;
        int shift = -1;
        bitvec mask;

        std::set<cstring> outputs;

        int hash_group() const;
        bitvec destinations() const;
        unsigned hash_table_inputs() const;
        bitvec galois_matrix_bits() const;

        cstring used_by;
        std::string used_for() const;

        void clear() {
            src_reqs.clear();
            ir_allocations.clear();
            expand = -1;
            unit = -1;
            shift = 0;
            mask.clear();
            outputs.clear();
        }
    };

    /* A problem occurred with the way the IXbar was allocated that requires backtracking
     * and trying something else */
    struct failure : public Backtrack::trigger {
        int     stage = -1, group = -1;
        failure(int stg, int grp) : trigger(OTHER), stage(stg), group(grp) {}
    };

 protected:
    ordered_map<const IR::MAU::AttachedMemory *, const IXBar::Use &> allocated_attached;

    /** The purpose of ContByteConversion is to capture that multiple stretch of fields can
     *  be contained within the same container byte.  In the add_use function, each FieldInfo
     *  object will be created, and linked to a corresponding container byte.  Later, in the
     *  create_alloc function, these individual FieldInfo object will be used to create at
     *  least a single byte, (and maybe more due to overlay issues), that the compiler needs
     * to allocate for an input xbar.  */
    typedef std::map<Use::Byte, safe_vector<FieldInfo>> ContByteConversion;
    static void add_use(ContByteConversion &map_alloc, const PHV::Field *field,
                        const PhvInfo &phv, const IR::MAU::Table *ctxt,
                        boost::optional<cstring> aliasSourceName,
                        const le_bitrange *bits = nullptr, int flags = 0,
                        byte_type_t byte_type = NO_BYTE_TYPE,
                        unsigned extra_align = 0, int range_index = 0);
    void create_alloc(ContByteConversion &map_alloc, IXBar::Use &alloc);
    void create_alloc(ContByteConversion &map_alloc, safe_vector<Use::Byte> &bytes);

    struct KeyInfo {
        bool hash_dist = false;
        bool is_atcam = false;
        bool partition = false;
        int partition_bits = 0;
        int range_index = 0;
        bool repeats_allowed = true;
        KeyInfo() { }
    };

    /* This is for adding fields to be allocated in the ixbar allocation scheme.  Used by
       match tables, selectors, and hash distribution */
    class FieldManagement : public Inspector {
        ContByteConversion *map_alloc;
        safe_vector<const IR::Expression *> &field_list_order;
        std::map<cstring, bitvec> *fields_needed;
        const PhvInfo &phv;
        KeyInfo &ki;
        const IR::MAU::Table* tbl;

        bool preorder(const IR::ListExpression *) override;
        bool preorder(const IR::Mask *) override;
        bool preorder(const IR::MAU::TableKey *read) override;
        bool preorder(const IR::Constant *c) override;
        bool preorder(const IR::MAU::ActionArg *aa) override;
        bool preorder(const IR::Expression *e) override;
        void postorder(const IR::BFN::SignExtend *c) override;
        void end_apply() override;

     public:
        FieldManagement(ContByteConversion *map_alloc,
                        safe_vector<const IR::Expression *> &field_list_order,
                        const IR::Expression *field, std::map<cstring, bitvec> *fields_needed,
                        const PhvInfo &phv, KeyInfo &ki, const IR::MAU::Table* t)
        : map_alloc(map_alloc), field_list_order(field_list_order),
          fields_needed(fields_needed), phv(phv), ki(ki), tbl(t) { field->apply(*this); }
    };

 public:
    virtual bool allocTable(const IR::MAU::Table *, const PhvInfo &, TableResourceAlloc &,
                            const LayoutOption *, const ActionData::Format::Use *,
                            const attached_entries_t &) = 0;
    virtual void update(cstring name, const Use &alloc) = 0;
    virtual void update(cstring name, const HashDistUse &hash_dist_alloc) = 0;
    virtual void update(const IR::MAU::Table *tbl, const TableResourceAlloc *rsrc);
    // virtual void update(cstring name, const TableResourceAlloc *alloc) = 0;
    virtual void update(const IR::MAU::Table *tbl);
    virtual void add_collisions() = 0;
    virtual void verify_hash_matrix() const = 0;
    virtual void dbprint(std::ostream &) const = 0;
    virtual ~IXBar() {}

    static IXBar *create();
};

inline std::ostream &operator<<(std::ostream &out, const IXBar::Loc &l) {
    return out << '(' << l.group << ',' << l.byte << ')'; }

inline std::ostream &operator<<(std::ostream &out, const IXBar::FieldInfo &fi) {
    out << fi.visualization_detail();
    return out;
}

std::ostream &operator<<(std::ostream &, const IXBar::Use &);
inline std::ostream &operator<<(std::ostream &out, const IXBar::Use::Byte &b) {
    out << b.container << '[' << b.lo << ".." << (b.lo + 7) << ']';
    if (b.loc) out << b.loc;
    out << " 0x" << b.bit_use;
    if (b.flags) out << " flags=" << hex(b.flags);
    out << " " << b.visualization_detail();
    return out;
}

inline std::ostream &operator<<(std::ostream &out, const IXBar &i) {
    i.dbprint(out);
    return out;
}

#endif /* BF_P4C_MAU_INPUT_XBAR_H_ */
