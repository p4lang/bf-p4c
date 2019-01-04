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

namespace BFN {

static const unsigned fieldListHandleBase = (0x21 << 24);
static const unsigned dynHashHandleBase = (0x22 << 24);
static const unsigned algoHandleBase = (0x23 << 24);
static unsigned fieldListHandle = 0x0;
static unsigned dynHashHandle = 0x0;
static unsigned algoHandle = 0x0;
class DynamicHashJson : public MauInspector {
 private:
    Util::JsonArray *_dynHashNode = nullptr;
    bool preorder(const IR::MAU::Table *tbl) override;
    void gen_ixbar_json(const IXBar::Use &ixbar_use, Util::JsonObject *_dhc,
                            int stage, cstring fl_name);
 public:
    DynamicHashJson();
    /// output the json hierarchy into the asm file (as Yaml)
    friend std::ostream & operator<<(std::ostream &out, const DynamicHashJson &dyn);
};

}  // namespace BFN

#endif  /* BF_P4C_MAU_DYNHASH_H_ */
