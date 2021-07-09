#ifndef BF_P4C_MAU_TOFINO_INPUT_XBAR_H_
#define BF_P4C_MAU_TOFINO_INPUT_XBAR_H_

#include "bf-p4c/mau/input_xbar.h"

#include <array>
#include <map>
#include <random>
#include <unordered_set>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/mau/attached_entries.h"
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"
#include "lib/alloc.h"
#include "lib/hex.h"
#include "lib/safe_vector.h"

namespace Tofino {

struct IXBar : public ::IXBar::Base {
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

 private:
    static int get_meter_alu_hash_bits() {
        // If hash parity is enabled reserve a bit for parity
        if (!BackendOptions().disable_gfm_parity)
            return METER_ALU_HASH_BITS - 1;
        return METER_ALU_HASH_BITS;
    }

    static int get_hash_single_bits() { return ::IXBar::get_hash_single_bits(); }

    static int get_hash_matrix_size() {
        return RAM_SELECT_BIT_START + get_hash_single_bits();
    }

    static int get_max_hash_bits() {
        // If hash parity is enabled reserve a bit for parity
        if (!BackendOptions().disable_gfm_parity)
            return MAX_HASH_BITS - 1;
        return MAX_HASH_BITS;
    }

    using Loc = ::IXBar::Loc;
    using byte_speciality_t = ::IXBar::byte_speciality_t;
    // FIXME -- should have a better way of importing all the byte_speciality_t values
    static constexpr auto NONE = ::IXBar::NONE;
    static constexpr auto ATCAM_DOUBLE = ::IXBar::ATCAM_DOUBLE;
    static constexpr auto ATCAM_INDEX = ::IXBar::ATCAM_INDEX;
    static constexpr auto RANGE_LO = ::IXBar::RANGE_LO;
    static constexpr auto RANGE_HI = ::IXBar::RANGE_HI;
    static constexpr auto BYTE_SPECIALITIES = ::IXBar::BYTE_SPECIALITIES;

    using FieldInfo = ::IXBar::FieldInfo;
    using parity_status_t = ::IXBar::parity_status_t;
    // FIXME -- should have a better waby of importing all the parity_status_t values
    static constexpr auto PARITY_NONE = ::IXBar::PARITY_NONE;
    static constexpr auto PARITY_ENABLED = ::IXBar::PARITY_ENABLED;
    static constexpr auto PARITY_DISABLED = ::IXBar::PARITY_DISABLED;

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

    // map from field names to tables that use those fields (mostly for debugging)
    std::map<cstring, std::set<cstring>>        field_users;

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
    parity_status_t  hash_group_parity_use[HASH_GROUPS] = { PARITY_NONE };

    // Added on update to be verified
    bitvec hash_used_per_function[HASH_GROUPS] = { bitvec() };

    int hash_dist_groups[HASH_DIST_UNITS] = {-1, -1};
    friend class IXBarRealign;

    /* API for unit tests */
 public:
    Alloc2Dbase<std::pair<cstring, int>> &get_exact_use() { return exact_use; }
    Alloc2Dbase<std::pair<cstring, int>> &get_ternary_use() { return ternary_use; }
    Alloc1D<std::pair<cstring, int>, BYTE_GROUPS> &get_byte_group_use() { return byte_group_use; }

    // map (type, group, byte) coordinate to linear xbar output space
    unsigned toIXBarOutputByte(bool ternary, int group, int byte) {
        unsigned offset = 0;
        if (ternary) {
            unsigned mid_byte_count = (group / 2) + (group % 2);
            offset = (group / 2) * 10  + (group % 2) * 5 + byte + mid_byte_count;
        } else {
            offset = group * 16 + byte;
        }
        return offset;
    }

 private:
    std::set<cstring>                                       dleft_updates;

 public:
    using byte_type_t = ::IXBar::byte_type_t;
    // FIXME -- should have a better waby of importing all the byte_type_t values
    static constexpr auto NO_BYTE_TYPE = ::IXBar::NO_BYTE_TYPE;
    static constexpr auto ATCAM = ::IXBar::ATCAM;
    static constexpr auto PARTITION_INDEX = ::IXBar::PARTITION_INDEX;
    static constexpr auto RANGE = ::IXBar::RANGE;
    using HashDistDest_t = ::IXBar::HashDistDest_t;
    // FIXME -- should have a better waby of importing all the HashDistDest_t values
    static constexpr auto HD_IMMED_LO = ::IXBar::HD_IMMED_LO;
    static constexpr auto HD_IMMED_HI = ::IXBar::HD_IMMED_HI;
    static constexpr auto HD_STATS_ADR = ::IXBar::HD_STATS_ADR;
    static constexpr auto HD_METER_ADR = ::IXBar::HD_METER_ADR;
    static constexpr auto HD_ACTIONDATA_ADR = ::IXBar::HD_ACTIONDATA_ADR;
    static constexpr auto HD_PRECOLOR = ::IXBar::HD_PRECOLOR;
    static constexpr auto HD_HASHMOD = ::IXBar::HD_HASHMOD;
    static constexpr auto HD_DESTS = ::IXBar::HD_DESTS;

    using Use = ::IXBar::Use;
    using HashDistAllocPostExpand = ::IXBar::HashDistAllocPostExpand;
    using HashDistIRUse = ::IXBar::HashDistIRUse;
    using HashDistUse = ::IXBar::HashDistUse;

 private:
    ordered_map<const IR::MAU::Table *, const safe_vector<HashDistUse> *> tbl_hash_dists;

    class XBarHashDist : public MauInspector {
        safe_vector<HashDistAllocPostExpand> alloc_reqs;
        IXBar &self;
        const PhvInfo &phv;
        const IR::MAU::Table *tbl;
        // const ActionFormat::Use *af;
        const ActionData::Format::Use *af;
        const LayoutOption *lo;
        TableResourceAlloc *resources;
        const attached_entries_t &attached_entries;

        void build_action_data_req(const IR::MAU::HashDist *hd);
        void build_req(const IR::MAU::HashDist *hd, const IR::Node *rel_node,
            bool created_hd = false);

        void build_function(const IR::MAU::HashDist *hd, P4HashFunction **func,
            le_bitrange *bits = nullptr);
        bool preorder(const IR::MAU::HashDist *) override;
        bool preorder(const IR::MAU::TableSeq *) override { return false; }
        bool preorder(const IR::MAU::AttachedOutput *) override { return false; }
        bool preorder(const IR::MAU::StatefulCall *) override { return false; }

     public:
        void immediate_inputs();
        void hash_action();
        bool allocate_hash_dist();
        XBarHashDist(IXBar &s, const PhvInfo &p, const IR::MAU::Table *t,
                const ActionData::Format::Use *a, const LayoutOption *l, TableResourceAlloc *r,
                const attached_entries_t &ae)
            : self(s), phv(p), tbl(t), af(a), lo(l), resources(r), attached_entries(ae) {}
    };

 private:
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

    using mid_byte_use = grp_use;

 public:  // for gtest only
    struct hash_matrix_reqs {
        // The max number of groups that can be used by this table.  Required by gateways,
        // and stateful/meter tables using the search bus
        int max_search_buses = -1;
        int index_groups = 0;
        int select_bits = 0;
        bool hash_dist = false;
        bool requires_versioning = false;

        static hash_matrix_reqs max(bool hd, bool ternary = false) {
            hash_matrix_reqs rv;
            if (ternary)
                return rv;
            rv.hash_dist = hd;
            if (rv.hash_dist) {
                rv.index_groups = HASH_DIST_SLICES;
            } else {
                rv.index_groups = HASH_INDEX_GROUPS;
                rv.select_bits = IXBar::get_hash_single_bits();
            }
            return rv;
        }

        bool fit_requirements(bitvec hash_matrix_in_use) const;

        hash_matrix_reqs() {}
        hash_matrix_reqs(int ig, int sb, bool hd)
            : index_groups(ig), select_bits(sb), hash_dist(hd) {}
    };

 private:
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
        bool preorder(const IR::MAU::Selector *) override { return false; }

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

    void clear();
    bool allocMatch(bool ternary, const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                    safe_vector<IXBar::Use::Byte *> &alloced, hash_matrix_reqs &hm_reqs);
    bool allocPartition(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                        bool second_try);
    int getHashGroup(unsigned hash_table_input, const hash_matrix_reqs *hm_reqs = nullptr);
    void getHashDistGroups(unsigned hash_table_input, int hash_group_opt[HASH_DIST_UNITS]);
    bool allocProxyHash(const IR::MAU::Table *tbl, const PhvInfo &phv,
        const LayoutOption *lo, Use &alloc, Use &proxy_hash_alloc);
    bool allocProxyHashKey(const IR::MAU::Table *tbl, const PhvInfo &phv, const LayoutOption *lo,
        Use &proxy_hash_alloc, hash_matrix_reqs &hm_reqs);

    bool allocAllHashWays(bool ternary, const IR::MAU::Table *tbl, Use &alloc,
        const LayoutOption *layout_option, size_t start, size_t last,
        const hash_matrix_reqs &hm_reqs);
    bool allocHashWay(const IR::MAU::Table *tbl, const LayoutOption *layout_option,
        size_t index, std::map<int, bitvec> &slice_to_select_bits, Use &alloc,
        unsigned local_hash_table_input, unsigned hf_hash_table_input, int hash_group);
    bool allocGateway(const IR::MAU::Table *, const PhvInfo &phv, Use &alloc,
        const LayoutOption *lo, bool second_try);
    bool allocSelector(const IR::MAU::Selector *, const IR::MAU::Table *, const PhvInfo &phv,
                       Use &alloc, cstring name);
    bool allocStateful(const IR::MAU::StatefulAlu *, const IR::MAU::Table *, const PhvInfo &phv,
                       Use &alloc, bool on_search_bus);
    bool allocMeter(const IR::MAU::Meter *, const IR::MAU::Table *, const PhvInfo &phv,
                    Use &alloc, bool on_search_bus);

    bool allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                    const LayoutOption *lo, const ActionData::Format::Use *af,
                    const attached_entries_t &ae);

    void update(cstring name, const Use &alloc);
    void update(cstring name, const HashDistUse &hash_dist_alloc);
    virtual void update(const IR::MAU::Table *tbl, const TableResourceAlloc *rsrc);
    virtual void update(const IR::MAU::Table *tbl);
    void add_collisions();
    void verify_hash_matrix() const;
    void dbprint(std::ostream &) const;

    const Loc *findExactByte(cstring name, int byte) const {
        for (auto &p : Values(exact_fields.equal_range(name)))
            if (exact_use.at(p.group, p.byte).second/8 == byte)
                return &p;
        /* FIXME -- what if it's in more than one place? */
        return nullptr; }
    unsigned find_balanced_group(Use &alloc, int way_size);

 public:  // for gtest
    bool find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use, bool ternary,
        safe_vector<IXBar::Use::Byte *> &alloced, hash_matrix_reqs &hm_reqs,
        unsigned byte_mask = ~0U);

 private:
    bitvec can_use_from_flags(int flags) const;
    int groups(bool ternary) const;
    int mid_bytes(bool ternary) const;
    int bytes_per_group(bool ternary) const;

    void increase_ternary_ixbar_space(int &groups_needed, int &nibbles_needed,
        bool requires_versioning);
    bool calculate_sizes(safe_vector<Use::Byte> &alloc_use, bool ternary, int &total_bytes_needed,
        int &groups_needed, int &mid_bytes_needed, bool requires_versioning);
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
        bool ternary, int &match_bytes_placed, int search_bus, bool &prefer_half_bytes,
        bool only_alloc_nibble);
    void free_bytes(grp_use *grp, safe_vector<Use::Byte *> &unalloced,
        safe_vector<Use::Byte *> &alloced, bool ternary, bool hash_dist, int &match_bytes_placed,
        int search_bus);
    void free_mid_bytes(mid_byte_use *mb_grp, safe_vector<Use::Byte *> &unalloced,
        safe_vector<Use::Byte *> &alloced, int &match_bytes_placed, int search_bus,
        bool &prefer_half_bytes, bool only_alloc_nibble);
    void allocate_byte(bitvec *bv, safe_vector<IXBar::Use::Byte *> &unalloced,
        safe_vector<IXBar::Use::Byte *> *alloced, IXBar::Use::Byte &need, int group,
        int byte, size_t &index, int &free_bytes, int &ixbar_bytes_placed,
        int &match_bytes_placed, int search_bus, int *range_index);
    void allocate_mid_bytes(safe_vector<Use::Byte *> &unalloced,
        safe_vector<Use::Byte *> &alloced, bool ternary, bool prefer_found,
        safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        int nibbles_needed, int &bytes_to_allocate);

    int determine_best_group(safe_vector<Use::Byte *> &unalloced, safe_vector<grp_use> &order,
        bool ternary, bool prefer_found, int required_allocation_bytes);

    void allocate_groups(safe_vector<Use::Byte *> &unalloced, safe_vector<Use::Byte *> &alloced,
        bool ternary, bool prefer_found, safe_vector<grp_use> &order,
        safe_vector<mid_byte_use> &mid_byte_order, int &bytes_to_allocate, int groups_needed,
        bool hash_dist, unsigned byte_mask);
    hash_matrix_reqs match_hash_reqs(const LayoutOption *lo, size_t start, size_t end,
        bool ternary);
    void layout_option_calculation(const LayoutOption *layout_option,
                                   size_t &start, size_t &last);

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
        bitvec total_post_expand_bits, const IR::MAU::Table* tbl, cstring name);
    void lockInHashDistArrays(safe_vector<Use::Byte *> *alloced, int hash_group,
        unsigned hash_table_input, int asm_unit, bitvec hash_bits_used, HashDistDest_t dest,
        cstring name);


    bool allocHashDistSection(bitvec post_expand_bits, bitvec possible_shifts, int hash_group,
        int &unit_allocated, bitvec &hash_bits_allocated);
    bool allocHashDistWideAddress(bitvec post_expand_bits, bitvec possible_shifts, int hash_group,
        bool chained_addr, int &unit_allocated, bitvec &hash_bits_allocated);
    bool allocHashDist(safe_vector<HashDistAllocPostExpand> &alloc_reqs, HashDistUse &use,
        const PhvInfo &phv, cstring name, const IR::MAU::Table* tbl, bool second_try);
    void createChainedHashDist(const HashDistUse &hd_alloc, HashDistUse &chained_hd_alloc,
        cstring name);
    void update_hash_parity(IXBar::Use &use, int hash_group);
    parity_status_t update_hash_parity(int hash_group);
};

}  // namespace Tofino

#endif /* BF_P4C_MAU_TOFINO_INPUT_XBAR_H_ */
