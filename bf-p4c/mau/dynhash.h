#ifndef BF_P4C_MAU_DYNHASH_H_
#define BF_P4C_MAU_DYNHASH_H_

#include <boost/range/irange.hpp>
#include <vector>
#include "mau_visitor.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/json.h"
#include "lib/ordered_map.h"
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/phv/phv_fields.h"

namespace BFN {

static const unsigned fieldListHandleBase = (0x21 << 24);
static const unsigned dynHashHandleBase = (0x22 << 24);
static const unsigned algoHandleBase = (0x23 << 24);
extern unsigned fieldListHandle;
extern unsigned dynHashHandle;
extern unsigned algoHandle;
static std::map<cstring, unsigned> algoHandles;
class DynamicHashJson : public MauInspector {
 private:
    const PhvInfo &phv;
    Util::JsonArray *_dynHashNode = nullptr;
    bool preorder(const IR::MAU::Table *tbl) override;
    void gen_ixbar_json(const IXBar::Use &ixbar_use,
        Util::JsonObject *_dhc, int stage, const cstring field_list_name,
        const IR::NameList *algorithms, int hash_width = -1);

    void gen_ixbar_bytes_json(Util::JsonArray *_xbar_cfgs, int stage,
        const std::map<cstring, cstring> &fieldNames, const IXBar::Use &ixbar_use);
    void gen_algo_json(Util::JsonObject *_dhc, const IR::NameList *algorithms);
    void gen_hash_json(Util::JsonArray *_hash_cfgs, int stage, IXBar::Use &ixbar_use,
        int &hash_bit_width);
    void gen_field_list_json(Util::JsonObject *_field_list, cstring field_list_name,
        safe_vector<const IR::Expression *> &field_list_order,
        std::map<cstring, cstring> &fieldNames);

    void gen_hash_dist_json(const IR::MAU::Table *tbl);


    using HashDistToAlloc
        = ordered_map<const IR::MAU::HashDist *, safe_vector<const IXBar::HashDistIRUse *>>;

    using HashFuncToAlloc = std::map<int, safe_vector<const IXBar::HashDistIRUse *>>;

 public:
    explicit DynamicHashJson(const PhvInfo &phv);
    /// output the json hierarchy into the asm file (as Yaml)
    friend std::ostream & operator<<(std::ostream &out, const DynamicHashJson &dyn);
};

}  // namespace BFN

#endif  /* BF_P4C_MAU_DYNHASH_H_ */
