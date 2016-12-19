#include "remap_intrin.h"
#include <map>

static std::map<std::pair<cstring, cstring>, std::pair<cstring, cstring>> remap = {
    { { "ig_intr_md_for_tm", "ucast_egress_port" }, { "standard_metadata", "egress_spec" } },
    { { "eg_intr_md", "egress_port" }, { "standard_metadata", "egress_port" } },
    { { "ig_intr_md_for_tm", "mcast_grb_b" }, { "intrinsic_metadata", "mcast_grp" } },
    { { "eg_intr_md", "egress_rid" }, { "intrinsic_metadata", "egress_rid" } },
    { { "eg_intr_md", "enq_tstamp" }, { "queueing_metadata", "enq_timestamp" } },
    { { "eg_intr_md", "enq_qdepth" }, { "queueing_metadata", "enq_qdepth" } },
    { { "eg_intr_md", "deq_timedelta" }, { "queueing_metadata", "deq_timedelta" } },
    { { "eg_intr_md", "deq_qdepth" }, { "queueing_metadata", "deq_qdepth" } },
};

bool RemapIntrinsics::preorder(IR::Member *mem) {
    std::pair<cstring, cstring> mname(mem->expr->toString(), mem->member);
    if (remap.count(mname)) {
        auto &to = remap.at(mname);
        mem->member = to.second;
        mem->expr = new IR::PathExpression(to.first); }
    return false;
}
