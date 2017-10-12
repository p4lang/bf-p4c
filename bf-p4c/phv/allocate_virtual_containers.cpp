#include "allocate_virtual_containers.h"
#include "check_fitting.h"
#include "cluster_phv_container.h"

const IR::Node * AllocateVirtualContainers::apply_visitor(
    const IR::Node *node,
    const char *name) {
    if (name)
        LOG1(name);

    // Find (partially or fully) unallocated fields.
    ordered_set<PHV::Field *> unallocated =
        CheckFitting::collect_unallocated_fields(phv_i, uses_i);

    // Unallocate allocated pieces of partially allocated fields.
    for (auto &f : unallocated)
        f->clear_alloc();

    trivial_allocate(unallocated);
    return node;
}

void AllocateVirtualContainers::trivial_allocate(ordered_set<PHV::Field *>& fields) {
    //
    // trivially allocating overflow fields
    //
    LOG3("********** Overflow Allocation **********");
    ordered_map<PHV::Size, int> overflow_reg {
        {PHV::Size::b32, 64},
        {PHV::Size::b16, 224},
        {PHV::Size::b8,  128},
    };

    PHV::Size container_width = PHV::Size::b8;
    for (auto &f : fields) {
        // skip members of ccgfs as owners will allocate for them
        if (f->ccgf() && !f->ccgf_fields().size())
            continue;

        // Fields not used mau but used parde can be placed in virtual TPHV containers
        PHV::Kind kind = PHV::Kind::normal;
        if (!uses_i.is_used_mau(f) && uses_i.is_used_parde(f))
            kind = PHV::Kind::tagalong;

        int field_bit = 0;
        int container_bit = 0;
        if (f->phv_use_width() > 16)
            container_width = PHV::Size::b32;
        else if (f->phv_use_width() > 8)
            container_width = PHV::Size::b16;
        else
            container_width = PHV::Size::b8;

        PHV::Container *asm_container = nullptr;
        for (field_bit = 0; field_bit < f->phv_use_width(); /* nil */) {
            int index = overflow_reg[container_width]++;
            asm_container = new PHV::Container(PHV::Type(kind, container_width), index);
            int width_in_container = f->size - f->phv_use_rem();
            if (width_in_container > int(container_width)) {
                width_in_container = int(container_width);
                // spans several containers, aggregate used bits
                // [width 20]= 12..19[8b] 4..11[8b] 0..3[4b]
                f->set_phv_use_rem(f->phv_use_rem() + width_in_container);
            } else {
                f->set_phv_use_rem(0);
            }
            f->alloc_i.emplace_back(
                f, *asm_container, field_bit, container_bit, width_in_container);
            LOG3(f << '[' << field_bit << ".." << f->phv_use_width()-1 << "] ..... "
                << asm_container->toString());
            field_bit += width_in_container;
        }
        // ccgf owners allocate for members
        if (f->is_ccgf()) {
            if (!f->header_stack_pov_ccgf()) {
                //
                // do not remove allocation for owners
                // that are not members of ccgf, e.g., header stack povs
                // egress::mpls.$stkvalid[6]{0..6}-r- --ccgf-> egress::mpls.$stkvalid
                // [       egress::vxlan_gpe_int_header.$valid[1]
                //         egress::mpls.$push[3]
                //         egress::mpls[0].$valid[1]
                //         egress::mpls[1].$valid[1]
                //         egress::mpls[2].$valid[1]
                // :7]
                //
                // when owner is member of ccgf,
                // remove owner's allocation
                // egress::tunnel_metadata.tunnel_src_index[9]{0..31}-r- --ccgf->
                // e.g., [31:0]->[W109]        -- removed
                //       [8:0]->[W109](23..31) -- fresh allocation
                //
                f->alloc_i.clear();
            }
            assert(asm_container);
            container_contiguous_alloc(f,
                                       int(container_width),
                                       asm_container,
                                       int(container_width));
        }
    }
}

void AllocateVirtualContainers::container_contiguous_alloc(
    PHV::Field* f1,
    int container_width,
    PHV::Container *asm_container,
    int width_in_container) {
    //
    // container contiguous allocation
    // header fields allocation permits no holes in container
    // header stack povs allocation permits leading / trailing holes beside ccgf
    //
    if (!f1->header_stack_pov_ccgf()) {
        // contiguous container group allocation
        // cases bypassing MAU PHV allocation PHV_container::taint() recursion
        // consider MSB order
        int processed_members = 0;
        // container_bit start
        int start = container_width;
        for (auto &member : f1->ccgf_fields()) {
            int member_bit_lo = member->phv_use_lo();
            int use_width = member->size - member->phv_use_rem();
            start -= use_width;
            if (start < 0) {
                // member straddles containers
                // remainder bits processed
                // in subsequent container allocated to owner
                use_width += start;
                start = 0;
                member_bit_lo = member->size - member->phv_use_rem() - use_width;
                // spans several containers => aggregate used bits
                // [width 20] = 12..19[8b] 4..11[8b] 0..3[4b]
                member->set_phv_use_rem(member->phv_use_rem() + use_width);
            } else {
                processed_members++;
                member->set_phv_use_rem(0);
            }
            // -- reentrant PHV_Bind, preserve entry state of member
            // member->ccgf = 0;
            member->alloc_i.emplace_back(
                member,
                *asm_container,
                member_bit_lo,
                start,
                use_width);
            if (start <= 0) {
                break;
            }
        }
        // -- reentrant PHV_Bind, preserve entry state of f1
        // f1->ccgf_fields.erase(
            // f1->ccgf_fields.begin(),
            // f1->ccgf_fields.begin() + processed_members);
        // if (f1->ccgf_fields.size()) {
            // f1->ccgf = f1;
        // }
    } else {
        //
        // header stack pov members
        // constituent members of header stack povs must fit header stk pov
        // this condition should be guaranteed by phv_fields.cpp allocatePOV()
        //
        int container_bit = width_in_container + 1;
        for (auto &pov_f : f1->ccgf_fields()) {
            int field_bit = pov_f->phv_use_lo();
            int pov_width = pov_f->size;
            container_bit -= pov_width;
            if (f1->simple_header_pov_ccgf()) {  // simple header ccgf
                container_bit -= 2;
                f1->set_phv_use_hi(f1->size - 1);
            }
            //
            // check constituent members do fit hdr stk pov
            //
            if (container_bit < 0) {
                WARNING("*****PHV_Bind: header stack overrun *****"
                    << " hdr stk pov: "
                    << f1
                    << " pov member: "
                    << pov_f
                    << " container_bit: "
                    << container_bit);
            }
            pov_f->alloc_i.emplace_back(
                pov_f,
                *asm_container,
                field_bit,
                container_bit,
                pov_width);
        }
    }
}
