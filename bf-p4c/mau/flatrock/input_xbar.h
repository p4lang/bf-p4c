#ifndef BF_P4C_MAU_FLATROCK_INPUT_XBAR_H_
#define BF_P4C_MAU_FLATROCK_INPUT_XBAR_H_

#include "bf-p4c/mau/input_xbar.h"

namespace Flatrock {

class IXBar : public ::IXBar {
    static constexpr int GATEWAY_BYTES = 6;
    static constexpr int GATEWAY_ROWS = 32;
    static constexpr int EXACT_BYTES = 20;
    static constexpr int EXACT_WORDS = 5;
    static constexpr int BYTES_PER_WORD = 4;
    static constexpr int EXACT_MATCH_UNITS = 8;  /* 4 STM + 4 LAMB */
    static constexpr int EXACT_MATCH_STM_UNITS = 4;  /* first 4 units */
    static constexpr int TERNARY_GROUPS = 16;
    static constexpr int TERNARY_BYTES_PER_GROUP = 5;
    static constexpr int ACTION_BYTES = 64;

    using Loc = ::IXBar::Loc;
    using FieldInfo = ::IXBar::FieldInfo;
    using Use = ::IXBar::Use;
    using HashDistUse = ::IXBar::HashDistUse;

    /** IXBar tracks the use of all the input xbar bytes in a single stage.  Each byte use is set
     * to record the name of the field it will be getting and the bit offset within the field.
     * cstrings here are field names as used in PhvInfo (so PhvInfo::field can be used to find
     * out details about the field)
     * NOTE: Changes here require changes to .gdbinit pretty printer */
    Alloc1D<std::pair<PHV::Container, int>, GATEWAY_BYTES>                      gateway_use;
    // FIXME -- maybe allocate gateway rows as part of memory alloc (as was done for
    // gateway units on tofino1/2/3) rather than here?
    Alloc1D<std::pair<PHV::Container, int>, GATEWAY_ROWS>                       gateway_rows;
    // FIXME -- each exact/ternary can select between 8 sources based on gateway output
    Alloc1D<std::pair<PHV::Container, int>, EXACT_BYTES>                        exact_byte_use;
    Alloc1D<std::pair<PHV::Container, int>, EXACT_WORDS>                        exact_word_use;
    Alloc2D<std::pair<PHV::Container, int>, TERNARY_GROUPS, TERNARY_BYTES_PER_GROUP>
                                                                                ternary_use;
    // FIXME -- action PHV xbar can select between 4? sources based on gateway output
    Alloc1D<std::pair<PHV::Container, int>, ACTION_BYTES>                       action_use;
    /* reverse maps of the above -- for exact, group 0 = bytes, group 1 = words */
    std::multimap<PHV::Container, Loc>          gateway_fields;
    std::multimap<PHV::Container, Loc>          exact_fields;
    std::multimap<PHV::Container, Loc>          ternary_fields;
    std::multimap<PHV::Container, Loc>          action_fields;

    Alloc1D<cstring, EXACT_MATCH_UNITS>         exact_hash_use;    // 1:1 mapping between hash
    unsigned                                    exact_hash_inuse;  // and exact match units

    // FIXME -- figure out some way to refactor these `find_alloc` routines together
    void find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                    safe_vector<IXBar::Use::Byte *> &alloced,
                    std::multimap<PHV::Container, Loc> &fields,
                    Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use);
    bool do_alloc(safe_vector<IXBar::Use::Byte *> &alloced,
                  Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use);
    bool gateway_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                            safe_vector<IXBar::Use::Byte *> &alloced);
    bool exact_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                          safe_vector<IXBar::Use::Byte *> &alloced);
    bool exact_find_hash(IXBar::Use &alloc, const LayoutOption *lo);
    bool ternary_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                            safe_vector<IXBar::Use::Byte *> &alloced);
    bool action_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                           safe_vector<IXBar::Use::Byte *> &alloced);

    bool allocGateway(const IR::MAU::Table *, const PhvInfo &, Use &, const LayoutOption *);
    void setupMatchAlloc(const IR::MAU::Table *, const PhvInfo &, ContByteConversion &, Use &);
    bool allocExact(const IR::MAU::Table *, const PhvInfo &, TableResourceAlloc &,
                    const LayoutOption *, const ActionData::Format::Use *);
    bool allocTernary(const IR::MAU::Table *, const PhvInfo &, TableResourceAlloc &,
                      const LayoutOption *, const ActionData::Format::Use *);
    bool allocSelector(const IR::MAU::Selector *, const IR::MAU::Table *, const PhvInfo &,
                       Use &, cstring);
    bool allocStateful(const IR::MAU::StatefulAlu *, const IR::MAU::Table *, const PhvInfo &,
                       Use &);
    bool allocMeter(const IR::MAU::Meter *, const IR::MAU::Table *, const PhvInfo &, Use &);

    bool allocTable(const IR::MAU::Table *, const PhvInfo &, TableResourceAlloc &,
                    const LayoutOption *, const ActionData::Format::Use *,
                    const attached_entries_t &);
    void update(cstring name, const Use &alloc);
    void update(cstring name, const HashDistUse &hash_dist_alloc);
    void add_collisions();
    void verify_hash_matrix() const;
    void dbprint(std::ostream &) const;
};

}  // namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_INPUT_XBAR_H_ */
