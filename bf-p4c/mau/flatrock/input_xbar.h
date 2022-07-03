#ifndef BF_P4C_MAU_FLATROCK_INPUT_XBAR_H_
#define BF_P4C_MAU_FLATROCK_INPUT_XBAR_H_

#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/common/alloc.h"
#include "bf-p4c/mau/mau_spec.h"

class Slice;

namespace Flatrock {

class IXBar : public ::IXBar {
 public:
    static constexpr int GATEWAY_FIXED_BYTES = 5;
    static constexpr int GATEWAY_VEC_BYTES = 8;
    static constexpr int GATEWAY_ROWS = 24;
    static constexpr int EXACT_BYTES = 20;
    static constexpr int EXACT_WORDS = 5;
    static constexpr int XCMP_BYTES = 16;
    static constexpr int XCMP_WORDS = 12;
    static constexpr int BYTES_PER_WORD = 4;
    static constexpr int EXACT_MATCH_UNITS = 8;  /* 4 STM + 4 LAMB */
    static constexpr int EXACT_MATCH_STM_UNITS = 4;  /* first 4 units */
    static constexpr int TERNARY_GROUPS = 20;
    static constexpr int TERNARY_BYTES_PER_GROUP = 5;

    using Loc = ::IXBar::Loc;
    using FieldInfo = ::IXBar::FieldInfo;

    struct Use : public ::IXBar::Use {
        int exact_unit = -1;

        void clear() override {
            ::IXBar::Use::clear();
            exact_unit = -1; }
        Use *clone() const { return new Use(*this); }
        void emit_salu_bytemasks(std::ostream &, indent_t) const { BUG(""); }
        void emit_ixbar_asm(const PhvInfo &phv, std::ostream& out, indent_t indent,
                            const TableMatch *fmt, const IR::MAU::Table *) const;
        bitvec galois_matrix_bits() const { BUG(""); }
        const std::map<int, const IR::Expression *> &hash_computed_expressions() const { BUG(""); }
        int hash_groups() const { BUG(""); return 0; }
        int hash_dist_hash_group() const { BUG(""); return 0; }
        std::string hash_dist_used_for() const { BUG(""); return ""; }
        bool is_parity_enabled() const { return false; }
        TotalBytes match_hash(safe_vector<int> *hash_groups) const;
        bitvec meter_bit_mask() const { BUG(""); }
        int total_input_bits() const { BUG(""); }
        void update_resources(int, BFN::Resources::StageResources &) const;
        const char *way_source_kind() const { return "xme"; }

     private:
        int slot_size(int group) const;
        void gather_bytes(const PhvInfo &phv, std::map<int, std::map<int, Slice>> &sort,
                          const IR::MAU::Table *tbl) const;
    };
    static Use &getUse(autoclone_ptr<::IXBar::Use> &ac);
    static const Use &getUse(const autoclone_ptr<::IXBar::Use> &ac);
    IXBar();

 private:
    /** IXBar tracks the use of all the input xbar bytes in a single stage.  Each byte use is set
     * to record the container it will be getting and the bit offset within the container.
     * Word use are set to just the (first) container as the bit offset is always 0.
     * NOTE: Changes here require changes to .gdbinit pretty printer */
    BFN::Alloc1D<std::pair<PHV::Container, int>, GATEWAY_VEC_BYTES>                 gateway_use;
    // FIXME -- maybe allocate gateway rows as part of memory alloc (as was done for
    // gateway units on tofino1/2/3) rather than here?
    BFN::Alloc1D<std::pair<PHV::Container, int>, GATEWAY_ROWS>                      gateway_rows;
    // FIXME -- each exact/ternary can select between 8 sources based on gateway output
    BFN::Alloc1D<std::pair<PHV::Container, int>, EXACT_BYTES>                       exact_byte_use;
    BFN::Alloc1D<PHV::Container, EXACT_WORDS>                                       exact_word_use;
    BFN::Alloc1D<std::pair<PHV::Container, int>, XCMP_BYTES>                        xcmp_byte_use;
    BFN::Alloc1D<PHV::Container, XCMP_WORDS>                                        xcmp_word_use;
    BFN::Alloc2D<std::pair<PHV::Container, int>, TERNARY_GROUPS, TERNARY_BYTES_PER_GROUP>
                                                                                    ternary_use;
    /* reverse maps of the above -- the 'group' encoding is a bit weird.  exact and xcmp
     * use 0 for bytes groups and 1 for word groups.  gateway uses 0 for vector group and
     * 1 for the fixed bytes.  Ternary groups correspond to the SCM inputs */
    std::multimap<PHV::Container, Loc>          gateway_fields;
    std::multimap<PHV::Container, Loc>          exact_fields;
    std::multimap<PHV::Container, Loc>          ternary_fields;
    std::multimap<PHV::Container, Loc>          xcmp_fields;

    BFN::Alloc1D<cstring, EXACT_MATCH_UNITS>    exact_hash_use;         // 1:1 mapping between hash
    unsigned                                    exact_hash_inuse = 0;   // and exact match units

    // map from container to tables that use those fields (mostly for dbprint)
    std::map<PHV::Container, std::set<cstring>>        field_users;

    // pairs of container bytes that need to be xor'd to do a gateway match
    typedef std::map<std::pair<PHV::Container, int>, std::pair<PHV::Container, int>> xor_map_t;

    // FIXME -- figure out some way to refactor these `find_alloc` routines together
    void find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                    safe_vector<IXBar::Use::Byte *> &alloced,
                    std::multimap<PHV::Container, Loc> &fields,
                    BFN::Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use,
                    bool allow_word, const xor_map_t *xor_map = nullptr);
    bool do_alloc(safe_vector<IXBar::Use::Byte *> &alloced,
                  BFN::Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use,
                  const xor_map_t *xor_map = nullptr);
    bool do_alloc(safe_vector<IXBar::Use::Byte *> &alloced,
                  BFN::Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use,
                  BFN::Alloc1Dbase<PHV::Container> &word_use);
    bool gateway_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                            safe_vector<IXBar::Use::Byte *> &alloced,
                            const xor_map_t &xor_map);
    bool exact_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                          safe_vector<IXBar::Use::Byte *> &alloced,
                          int exact_unit);
    bool exact_find_hash(IXBar::Use &alloc, const LayoutOption *lo);
    bool ternary_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                            safe_vector<IXBar::Use::Byte *> &alloced);
    bool xcmp_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                         safe_vector<IXBar::Use::Byte *> &alloced);

    bool allocGateway(const IR::MAU::Table *, const PhvInfo &, Use &, const LayoutOption *);
    void setupMatchAlloc(const IR::MAU::Table *, const PhvInfo &, ContByteConversion &, Use &);
    void setupActionAlloc(const IR::MAU::Table *, const PhvInfo &, ContByteConversion &, Use &);
    bool allocExact(const IR::MAU::Table *, const PhvInfo &, Use &,
                    const LayoutOption *, const ActionData::Format::Use *);
    bool allocTernary(const IR::MAU::Table *, const PhvInfo &, Use &,
                      const LayoutOption *, const ActionData::Format::Use *);
    class GetActionUse;
    bool allocActions(const IR::MAU::Table *, const PhvInfo &, Use &);
    bool allocSelector(const IR::MAU::Selector *, const IR::MAU::Table *, const PhvInfo &,
                       Use &, cstring);
    bool allocStateful(const IR::MAU::StatefulAlu *, const IR::MAU::Table *, const PhvInfo &,
                       Use &);
    bool allocMeter(const IR::MAU::Meter *, const IR::MAU::Table *, const PhvInfo &, Use &);

    bool allocTable(const IR::MAU::Table *, const PhvInfo &, TableResourceAlloc &,
                    const LayoutOption *, const ActionData::Format::Use *,
                    const attached_entries_t &);
    void update(cstring name, const ::IXBar::Use &alloc);
    void add_collisions();
    void verify_hash_matrix() const;
    void dbprint(std::ostream &) const;
};

}  // namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_INPUT_XBAR_H_ */
