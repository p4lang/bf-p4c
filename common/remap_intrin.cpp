#include "remap_intrin.h"
#include <map>

static std::map<std::pair<cstring, cstring>, std::pair<cstring, cstring>> remap = {
    { { "ig_intr_md_for_tm", "ucast_egress_port" }, { "standard_metadata", "egress_spec" } },
};

bool RemapIntrinsics::preorder(IR::Member *mem) {
    std::pair<cstring, cstring> mname(mem->expr->toString(), mem->member);
    if (remap.count(mname)) {
        auto &to = remap.at(mname);
        mem->member = to.second;
        mem->expr = new IR::NamedRef(to.first); }
    return false;
}
