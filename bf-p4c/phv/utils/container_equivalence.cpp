#include "bf-p4c/phv/utils/container_equivalence.h"

namespace PHV {

ContainerEquivalenceTracker::ContainerEquivalenceTracker(const PHV::Allocation& alloc) :
    alloc(alloc),
    isTofino2Or3(Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
                 || Device::currentDevice() == Device::CLOUDBREAK
#endif
    )
{ }

boost::optional<PHV::Container>
ContainerEquivalenceTracker::find_equivalent_tried_container(PHV::Container c) {
    if (!isTofino2Or3) {
        return find_single(c);
    } else {
        // W0 is special on Tofino 2 & 3 (due to a hardware bug) (P4C-4589)
        if (c == PHV::Container({PHV::Kind::normal, PHV::Size::b32}, 0))
            return boost::none;
        if (!c.is(PHV::Size::b8))
            return find_single(c);

        // Parser write mode is shared for the continuous tuple of B containers on Tofino 2/3
        // that share all but last bit of identifier, therefore we can only safely consider
        // the current container c to be equivalent to some other empty container e if the
        // paired container of e is also empty (the paired container of c needs not be empty
        // as that only means that there are more constrains on c, not less). (P4C-3033)
        auto equiv = find_single(c);
        if (!equiv)
            return boost::none;
        unsigned idx = equiv->index() & 1u ? equiv->index() & ~1u : equiv->index() | 1u;
        PHV::Container pair_equiv(equiv->type(), idx);
        auto pair_stat = alloc.getStatus(pair_equiv);
        if (pair_stat && pair_stat->alloc_status == ContainerAllocStatus::EMPTY)
            return equiv;
        return boost::none;
    }
}

void ContainerEquivalenceTracker::invalidate(PHV::Container c) {
    equivalenceClasses.erase(get_class(c));
}

boost::optional<PHV::Container>
ContainerEquivalenceTracker::find_single(PHV::Container c) {
    if (wideArithLow || excluded.count(c))
        return boost::none;

    auto cls = get_class(c);
    if (!cls.is_empty)
        return boost::none;

    auto ins = equivalenceClasses.emplace(cls, c);
    if (!ins.second) {  // not inserted, found
        LOG9("\tField equivalence class for " << c << " ~ " << ins.first->second
             << ": empty = " << cls.is_empty
             << " PHV::Kind = " << PHV::STR_OF_KIND.at(cls.kind)
             << " gress = " << cls.gress
             << " parser_group_gress = " << cls.parser_group_gress
             << " deparser_group_gress = " << cls.deparser_group_gress
             << " parser_extract_group_source = " << cls.parser_extract_group_source
             << " parity = " << int(cls.parity));
        return ins.first->second;
    }
    return boost::none;
}

}  // namespace PHV
