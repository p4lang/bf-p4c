#include "remap_intrin.h"
#include <map>

static std::map<std::pair<cstring, cstring>, std::pair<cstring, cstring>> remap = {
    { { "ig_intr_md", "ingress_port" }, { "standard_metadata", "ingress_port" } },
    { { "ig_intr_md", "resubmit_flag" }, { "standard_metadata", "resubmit_flag" } },
    { { "ig_intr_md_for_tm", "ucast_egress_port" }, { "standard_metadata", "egress_spec" } },
    { { "eg_intr_md", "egress_port" }, { "standard_metadata", "egress_port" } },
#if 0
    // Can't safely remap to intrinsic_metadata or queueing_metadata as the frontend may
    // have dead-code eliminated them.  Really need to do this remapping BEFORE converting
    // P4_14 -> P4_16, so we need to figure out how to get this pass into the P4_14 frontend
    { { "ig_intr_md_for_tm", "mcast_grb_b" }, { "intrinsic_metadata", "mcast_grp" } },
    { { "eg_intr_md", "egress_rid" }, { "intrinsic_metadata", "egress_rid" } },
    { { "eg_intr_md", "enq_tstamp" }, { "queueing_metadata", "enq_timestamp" } },
    { { "eg_intr_md", "enq_qdepth" }, { "queueing_metadata", "enq_qdepth" } },
    { { "eg_intr_md", "deq_timedelta" }, { "queueing_metadata", "deq_timedelta" } },
    { { "eg_intr_md", "deq_qdepth" }, { "queueing_metadata", "deq_qdepth" } },
#endif
};

bool RemapIntrinsics::preorder(IR::Member *mem) {
    auto submem = mem->expr->to<IR::Member>();
    std::pair<cstring, cstring> mname(submem ? submem->member.name : mem->expr->toString(),
                                      mem->member);
    if (remap.count(mname)) {
        auto &to = remap.at(mname);
        LOG3("remap " << mname.first << '.' << mname.second << " -> " <<
             to.first << '.' << to.second);
        mem->member = to.second;
        if (submem && to.first != "standard_metadata")
            mem->expr = new IR::Member(submem->srcInfo, submem->expr, to.first);
        else
            mem->expr = new IR::PathExpression(to.first);
        return false; }
    LOG5("not remapping " << mname.first << '.' << mname.second);
    return false;
}
