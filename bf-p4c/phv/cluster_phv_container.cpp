#include "bf-p4c/phv/cluster_phv_container.h"
#include "bf-p4c/phv/cluster_phv_mau.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"

//***********************************************************************************
//
// PHV_Container::Container_Content::Container_Content constructor
//
//***********************************************************************************

PHV_Container::Container_Content::Container_Content(
    const PHV_Container *c,
    const le_bitrange container_range,
    PHV::Field *f,
    const int field_bit_lo,
    const std::string taint_color,
    Pass pass)
        : container_i(c),
          container_range_i(container_range),
          field_i(f),
          field_bit_lo_i(field_bit_lo),
          taint_color_i(taint_color),
          pass_i(pass) {
    //
    BUG_CHECK(
        field_i,
        "*****PHV_Container::Container_Content constructor called with null field ptr*****");
    //
    // insert phv container in field
    //
    f->phv_containers(const_cast<PHV_Container *>(c));
}

//***********************************************************************************
//
// PHV_Container::PHV_Container
//
//***********************************************************************************

PHV_Container::PHV_Container(
    PHV_MAU_Group *g,
    PHV::Size w,
    unsigned phv_n,
    boost::optional<gress_t> gress)
    : phv_mau_group_i(g),
      width_i(w),
      container_id_i(phv_n),
      gress_i(gress) {
    //
    clear();
    //
}  // PHV_Container::PHV_Container

void
PHV_Container::clear() {
    status_i = Container_status::EMPTY;
    phv_mau_group_i->inc_empty_containers();
    fields_in_container_i.clear();
    taint_color_i = "0";
    bits_i = new char[int(width_i)];
    for (auto i=0; i < int(width_i); i++) {
        bits_i[i] = taint_color_i.back();
    }
    avail_bits_i = int(width_i);
    ranges_i.clear();
    ranges_i[0] = int(width_i) - 1;
}  // clear

void
PHV_Container::clean_ranges() {
    //
    // ranges_i carries some spurious noise despite being cleared earlier
    // e.g., for full container (0..0), packed container filled area (6..0), (7..0) etc.
    // residual noise is taken care of here
    //
    if (status_i == Container_status::FULL) {
        ranges_i.clear();
    }
    ordered_set<int> clear_these;
    for (auto &r : ranges_i) {
        if (r.second < r.first || (r.second == r.first &&  bits_i[r.first] != '0')) {
            clear_these.insert(r.first);
        }
    }
    for (auto &r : clear_these) {
        ranges_i.erase(r);
    }
}

void
PHV_Container::create_ranges() {
    //
    ranges_i.clear();  // status = FULL => ranges remains empty
    if (status_i == PHV_Container::Container_status::EMPTY) {
        ranges_i[0] = int(width_i) - 1;
    } else {
        if (status_i == PHV_Container::Container_status::PARTIAL) {
            for (auto i=0; i < int(width_i) ; i++) {
                if (bits_i[i] == '0') {
                    for (auto j=i; j < int(width_i) ; j++) {
                        if (bits_i[j] != '0') {
                            ranges_i[i] = j - 1;
                            i = j - 1;
                            break;
                        }
                        if (j == int(width_i) - 1) {
                            ranges_i[i] = j;
                            i = j;
                        }
                    }
                }
            }
        }
    }
    const std::string msg = "..PHV_Container::create_ranges";
    sanity_check_container_ranges(msg);
}

int
PHV_Container::taint(
    int start,
    int width,
    PHV::Field *field,
    int field_bit_lo,
    Container_Content::Pass pass,
    bool process_ccgf) {
    //
    BUG_CHECK(width > 0,
        "*****PHV_Container::taint()*****%s start=%d NEGATIVE width=%d width_i=%d, field=%d:%s",
        this->toString(), start, width, int(width_i), field->id, field->name);
    BUG_CHECK((start+width <= int(width_i)),
        "*****PHV_Container::taint()*****%s start=%d width=%d width_i=%d, field=%d:%s",
        this->toString(), start, width, int(width_i), field->id, field->name);
    //
    // ccgf field processing
    //
    if (process_ccgf && !field->allocation_complete()) {
        return taint_ccgf(start, width, field, field_bit_lo, pass);
    }
    //
    // non cluster_overlay fields
    // includes interference based overlay fields
    //
    taint_bits(start, width, field, field_bit_lo, pass);
    //
    // if field has overlay fields after cluster's interference graph computation
    // overlay performed after all phv/tphv allocation as a final pass in cluster_phv_mau.cpp
    //
    // set gress for this container
    // container may be part of MAU group that is Ingress Or Egress
    // however for any stage it is used exclusively for Ingress or for Egress
    // cannot share container with Ingress fields & Egress fields
    // transition behavior for such sharing unclear
    //
    // gress of fields must agree with gress of MAU group
    // "mixed-gress" arithmetic disallowed
    //
    this->gress(field->gress);
    if (!phv_mau_group_i->gress()) {
        phv_mau_group_i->gress(field->gress);
    } else {
        BUG_CHECK(
            phv_mau_group_i->gress() == gress(),
            "*****PHV_Container::taint()*****%s mau_group gress = %c, field = %d:%s, gress = %c",
            this->toString(),
            phv_mau_group_i->gress(),
            field->id,
            field->name,
            gress_i);
    }
    sanity_check_container_ranges("PHV_Container::taint()..");
    return width;  // all bits of this field processed
}

int
PHV_Container::taint_ccgf(
    int start,
    int width,
    PHV::Field *field,
    int field_bit_lo,
    Container_Content::Pass pass) {
    //
    // container contiguous groups
    // header fields allocation permits no holes in container
    // for each member taint container with appropriate width
    // must consider MSB order
    //
    // header stack pov's allocation is composition of members
    // it is not present as a member in its ccgf
    // as allocation is extra-bit overlaying members
    //
    start += width;  // start allocation from ccgf-segment RHS in container
    int processed_members = 0;
    int processed_width = 0;
    for (auto &member : field->ccgf_fields()) {
        if (constraint_no_cohabit(member)) {
            if (processed_width) {
                //
                // entire phv_use_width to be allocated in stand-alone container
                // e.g., <3:_12_8_8>{4*8}[28]I( phv_0
                // 64:ingress::meta.b[4]{0..11}  meta ccgf=64:ingress::meta.b
                // [ 64:ingress::meta.b[4]
                //   65:ingress::meta.c[4]{0..7} meta mau_phv_no_pack ccgf=64:ingress::meta.b
                // :12]
                //
                break;
            } else {
                //
                // account pad for no_pack constraint
                //
                if (int(width_i) < member->size) {
                    LOG1(
                        "*****cluster_phv_container.cpp:sanity_WARN*****....."
                        << " width_i of container "
                        << width_i
                        << " is less than 'no-pack' ccgf member size "
                        << member->size
                        << std::endl
                        << member);
                } else if (int(width_i) > member->size) {
                    // ccgf member cannot guarantee physical contiguity
                    // cluster.cpp header analysis, checks such cases during CCGF formation
                    // no-pack constraints introduced subsequently by analysis of MAU operations
                    LOG3("*****cluster_phv_container.cpp:*****....."
                        << "CCGF Physical Contiguity violated: "
                        << std::endl
                        << "member = " << member);
                    // ccgf metadata member in ccgf overly parde constrained
                    // metadata need not be part of ccgf
                    // relaxing error generation for metadata
                    if (!member->metadata)
                        ::error("CCGF member %1% not physically contiguous.", member->name);
                    //
                    int pad = width - member->size;
                    start -= pad;                    // start now @end of [0..member_size-1]
                    int lhs = start - member->size;  // lhs now @beginning of [0..member_size-1]
                    const int align_start =
                        member->phv_alignment(false /*ccgf member align*/).get_value_or(lhs);
                    if (align_start % int(PHV::Size::b8) != lhs % int(PHV::Size::b8)) {
                        // shift by alignment
                        start = align_start + member->size - member->phv_use_rem();
                        // start decremented by (member_size - member_phv_use_rem) before taint
                    }
                } else {
                    // width_i == member->size
                    const int align_start =
                        member->phv_alignment(false /*ccgf member align*/).get_value_or(0);
                    if (align_start)
                        ::error("CCGF member in exact width container %1% alignment not at 0.",
                                member->name);
                }  // width_i <=> member->size
            }  // processed_width
        }  // constraint_no_cohabit
        int use_width = member->size;             // always using size to taint container
        if (!member->simple_header_pov_ccgf()) {  // ignore simple header ccgf
            use_width -= member->phv_use_rem();
        }
        start -= use_width;
        int member_bit_lo = member->phv_use_lo();
        if (start < 0) {
            //
            // member straddles containers
            // remainder bits processed in subsequent container allocated to owner
            //
            use_width += start;  // start is -ve
            start = 0;
            member_bit_lo = member->size - member->phv_use_rem() - use_width;
            member->set_phv_use_rem(member->phv_use_rem() + use_width);
                                                // spans several containers, aggregate used bits
        } else {
            member->set_phv_use_rem(0);
            processed_members++;
        }
        // recursive taint call, do not recursively process ccgf
        taint(start, use_width, member, member_bit_lo, pass, false /* process_ccgf */);
        processed_width += constraint_no_cohabit(member) ? int(width_i) : use_width;
        BUG_CHECK(
            processed_width <= int(width_i),
            "*****PHV_Container::taint_ccgf()*****%s, field=%d:%s, processed_width=%s > width_i=%d",
            this->toString(),
            field->id,
            field->name,
            processed_width,
            int(width_i));
        if (start <= 0 || processed_width == int(width_i)) {
            break;
        }
    }  // for ccgf members
    if (field->header_stack_pov_ccgf()) {
        //
        // header stack pov ccgf needs additional bit + overlay its members
        // PHV-64.B0.I.Fp  76543221
        // 1= 63:ingress::data.$valid<1> I off=7 pov /phv_2,PHV-64;/[0..0]=PHV-64.B0<1:7..7>
        // 2= 64:ingress::extra.$push<2:0..1> I off=5 ..... /phv_2,PHV-64;/[0..1]=PHV-64.B0<2:5..6>
        // 3= 65:ingress::extra[0].$valid<1> I off=4 pov /phv_2,PHV-64;/[0..0]=PHV-64.B0<1:4..4>
        // 4= 66:ingress::extra[1].$valid<1> I off=3 pov /phv_2,PHV-64;/[0..0]=PHV-64.B0<1:3..3>
        // 5= 67:ingress::extra[2].$valid<1> I off=2 pov /phv_2,PHV-64;/[0..0]=PHV-64.B0<1:2..2>
        // 6= 68:ingress::extra[3].$valid<1> I off=1 pov /phv_2,PHV-64;/[0..0]=PHV-64.B0<1:1..1>
        // 72^ 70:ingress::extra.$stkvalid<7:0..6> ..... /phv_2,PHV-64;/[0..6]=PHV-64.B0<7:0..6>
        // .....
        // W44: 11111111111111118765444322222222
        // 3= 717:egress::vxlan.$valid<1> E off=8 pov /phv_168,PHV-44;/[0..0]=PHV-44.W44<1:23..23>
        // 4= 718:egress::mpls.$push<3:0..2>  ..... /phv_168,PHV-44;/[0..2]=PHV-44.W44<3:20..22>
        // 5= 719:egress::mpls[0].$valid<1> E off=4 pov /phv_168,PHV-44;/[0..0]=PHV-44.W44<1:19..19>
        // 6= 720:egress::mpls[1].$valid<1> E off=3 pov /phv_168,PHV-44;/[0..0]=PHV-44.W44<1:18..18>
        // 7= 721:egress::mpls[2].$valid<1> E off=2 pov /phv_168,PHV-44;/[0..0]=PHV-44.W44<1:17..17>
        // 84^ 722:egress::mpls.$stkvalid<6:0..5> ..... /phv_168,PHV-44;/[0..6]=PHV-44.W44<7:16..22>
        //
        assert(start >= 1 && start < int(width_i));
        Container_Content *header_stack_cc = taint_bits(start - 1, 1, field, field_bit_lo);
        processed_width++;
        //
        header_stack_cc->pass(Container_Content::Pass::Header_Stack_Pov_Ccgf);
        header_stack_cc->hi(start + field->size - 2);  // start - 1 + field->size - 1
        header_stack_cc->taint_color() += std::string(1, bits()[header_stack_cc->hi()]);
    }
    //
    // update ccgf owner record
    //
    update_ccgf(field, processed_members, processed_width);
    //
    return processed_width;  // all bits of this field may NOT be processed
}  // taint_ccgf

void
PHV_Container::update_ccgf(
    PHV::Field *field,
    int processed_members,
    int processed_width) {
    //
    field->ccgf_fields().erase(
        field->ccgf_fields().begin(),
        field->ccgf_fields().begin() + processed_members);
    field->set_phv_use_hi(field->phv_use_hi() - processed_width);
    if (field->allocation_complete()) {
        // ccgf owners with no-pack constraint, set range to entire container
        Cluster::set_field_range(field, constraint_no_cohabit(field) ? int(width_i) : 0);
    }
}  // update_ccgf

void
PHV_Container::overlay_ccgf_field(
    PHV::Field *field,
    int start,
    const int width,
    int field_bit_lo,
    Container_Content::Pass pass) {
    //
    // f is a ccgf
    // ccgf can be overlayed on top of another ccgf
    // ccgf overlay can span containers
    //
    // overlay field f, slice starting from field_bit_lo
    // onto this container starting at bit 'start' with width
    //
    //
    // 1. if two ccgfs are overlayed, start from lowest phv_use bit of substratum
    //    honor parde alignment
    // e.g.,
    // 25:ingress::hdr_1[0].d_0[4]{0..7}
    // [  25:ingress::hdr_1[0].d_0[4]   parde_align 4
    //    26:ingress::hdr_1[0].d_1[4]   parde_align 0
    // :8]     [r0] = [13(12,13,);]
    // overlayed with
    // 13:ingress::hdr_0.a_0[4]{0..7}
    // [  12:ingress::hdr_0.a_0[4]      parde_align 4
    //    13:ingress::hdr_0.a_1[4]      parde_align 0
    // :8]
    // d_1 = 0..3, d_0 = 4..7    d1d1d1d1d0d0d0d0
    // ccgf d_0(d_0,d_1) = ccgf a_0(a_0,a_1)
    // a_0 start = 4, d_0 start = 4
    // a_1 = 0..3, a_0 = 4..7    a1a1a1a1a0a0a0a0
    //
    // 2. same ccgf overlayed across containers
    // e.g.,
    // overlaying a cluster to a mau group containing 8b phv containers PHV-96, PHV-97
    // cluster (cluster ID phv_183) comprises ccgf field 45:ingress::vlan_tag_[1].pcp
    // members of this ccgf field are
    // [45:ingress::vlan_tag_[1].pcp, 46:ingress::vlan_tag_[1].cfi, 47:ingress::vlan_tag_[1].vid]
    //          3-bits + 1-bit + 12-bits = 16-bits  in two 8b phvs
    // PHV-96 = vlan_tag_[1].pcp, 46:ingress::vlan_tag_[1].cfi, 47:ingress::vlan_tag_[1].vid[0..3]
    //          3-bits + 1-bit + 4-bits = 8-bits
    // PHV-97 = 47:ingress::vlan_tag_[1].vid[4..11]
    //          8-bits
    //
    // cluster_phv_overlay cl->maug ==> (
    //   PHV-96.B32.I.F;
    //   PHV-97.B33.I.F;)
    //   ==> overlayed'%' 45:ingress::vlan_tag_[1].pcp<3:0..15> /phv_183,PHV-96;/
    //       [       45:ingress::vlan_tag_[1].pcp<3>*
    //               46:ingress::vlan_tag_[1].cfi<1> /phv_183,PHV-96;/
    //               47:ingress::vlan_tag_[1].vid<12:0..11> /phv_183,PHV-96;/
    //       ][0..7]
    //       = 45:ingress::vlan_tag_[1].pcp<3>
    //       + 46:ingress::vlan_tag_[1].cfi<1>
    //       + 47:ingress::vlan_tag_[1].vid<4>[0..3] => PHV-96
    //   ==> overlayed'%' 47:ingress::vlan_tag_[1].vid<12:0..11>  /phv_183,PHV-96;PHV-97;/
    //       ][8..15]
    //       = 47:ingress::vlan_tag_[1].vid [4..11]  => PHV-97
    //
    start += width;  // start allocation from ccgf-segment RHS in container
    int processed_members = 0;
    int processed_width = 0;
    int width_remaining = width;
    int skip_member = 0;
    for (auto &member : field->ccgf_fields()) {
        skip_member += member->size;
        if (field_bit_lo > skip_member) {
            continue;
        }
        int member_bit_lo = member->phv_use_lo() + member->phv_use_rem();
        int use_width = member->size - member->phv_use_rem();
        start -= use_width;
        if (use_width > width_remaining) {
            //
            // member straddles containers
            // remainder bits processed in subsequent container allocated to owner
            //
            use_width = width_remaining;
            member->set_phv_use_rem(member->phv_use_rem() + use_width);
                                                // spans several containers, aggregate used bits
        } else {
            member->set_phv_use_rem(0);
            processed_members++;
        }
        const int align_start
            = member->phv_alignment(false /*need ccgf member alignment*/).get_value_or(start);
        BUG_CHECK(
            align_start % int(PHV::Size::b8) == start % int(PHV::Size::b8),
            "*****PHV_Container::overlay_ccgf_field()*****%s, field=%d:%s, align_start=%s,start=%d",
            this->toString(),
            field->id,
            field->name,
            align_start,
            start);
        fields_in_container(
            member,
            new Container_Content(
               this,
               StartLen(start, use_width),
               member,
               member_bit_lo,
               taint_color(start, start + use_width - 1),
               pass /* pass that performs the overlay */));
        processed_width += use_width;
        width_remaining -= use_width;
        if (width_remaining <= 0) {
            break;
        }
    }  // for ccgf members
    //
    update_ccgf(field, processed_members, processed_width);
}  // overlay_ccgf_field

void
PHV_Container::single_field_overlay(
    PHV::Field *f,
    const int start,
    int width,
    const int field_bit_lo,
    Container_Content::Pass pass) {
    //
    // overlay field f, slice starting from field_bit_lo
    // onto this container starting at bit 'start' with width
    //
    assert(f);
    assert(start >= 0);
    assert(width >= 0);
    //
    // if field width is less that substratum width, reduce width required
    //
    width = std::min(f->phv_use_width(), width);
    //
    // if substratum area is not yet associated with a field, taint color will be 0
    // need to go through steps for container area allocation, updating its avail bits
    //
    if (taint_color(start, start + width - 1) == "0") {
        taint(start, width, f, field_bit_lo, pass);
    } else {
        if (f->ccgf_fields().size()) {
            overlay_ccgf_field(f, start, width, field_bit_lo, pass);
        } else {
            int align_start = start;
            if (field_bit_lo == 0)  // alignment @ start of field
                align_start = f->phv_alignment().get_value_or(start);
            else
                if (f->sliced() && f->phv_alignment())
                    // offset start by alignment + field_slice leading bits, e.g., f^0=f1^0,f2^8
                    align_start += field_bit_lo;
            fields_in_container(
                f,
                new Container_Content(
                    this,
                    StartLen(align_start, width),
                    f,
                    field_bit_lo,
                    taint_color(start, start + width - 1),
                    pass /* pass that performs the overlay */));
        }
    }
    LOG3("\t==> overlayed'" << static_cast<char>(pass) << "' " << f
        << "[" << field_bit_lo << ".." << field_bit_lo + width - 1 << "]");
    if (pass == Container_Content::Cluster_Overlay) {
        //
        // for all fields f_s overlapped by f in container
        // update field_overlay_map info in f_s' owner field
        //
        ordered_set<PHV::Field *> f_set;
        fields_in_container(start, start + width - 1, f_set);
        for (auto &f_s : f_set) {
            // f_s can be the same as f
            // f_s can be ccgf member of f
            // in these cases avoid inserting f in f_s field_overlay_map
            // validate_allocation checks field_overlay_map
            // to report "overlaid but not mutually exclusive"
            if (f_s == f || f_s->ccgf() == f)
                continue;
            f_s->field_overlay(f, container_id_i);
        }
    }
}  // single_field_overlay

void
PHV_Container::field_overlays(
    PHV::Field *field,
    int start,
    int width,
    const int field_bit_lo) {
    //
    assert(field);
    //
    // field can have overlays spanning containers
    // e.g., 24b field mapped to 3*8b containers
    // field->field_overlay_map is [3]={f_ov,...}, [4]={f_ov,...}, [5]={f_ov,...}
    // where overlayed field f_ov also spans same 3 containers as substratum
    // this container should only overlay the first slice
    // other containers should overlay remaining slices
    // f_ov's slice-width mimics substratum width in each container
    //
    if (field->field_overlay_map().size()) {
        LOG3("..........PHV_Container::field_overlays.....for container " << this->toString());
        LOG3("\t" << field);
        // consider overlayed fields, if any, for this container only
        ordered_set<PHV::Field *> *set_of_f = field->field_overlay_map(container_id_i);
        if (set_of_f) {
            for (auto &f : *set_of_f) {
                //
                // overlay ccgf on substratum ccgf
                // substratum ccgf owner in single container but its members span several containers
                // overlay ccgf spans these containers
                //
                if (f->is_ccgf() && f->phv_use_width() > int(width_i)) {
                    for (auto &c : field->phv_containers()) {
                        c->single_field_overlay(
                            f,
                            start,
                            width,
                            field_bit_lo,
                            Container_Content::Pass::Field_Interference);
                    }
                } else {
                    single_field_overlay(
                        f,
                        start,
                        width,
                        field_bit_lo,
                        Container_Content::Pass::Field_Interference);
                }
                if (!f->allocation_complete()) {
                    LOG1("*****cluster_phv_container.cpp: sanity_FAIL field_overlays*****"
                        << "..........ccgf member(s) INCOMPLETE ALLOCATION");
                    LOG1("..........overlay_field = ");
                    LOG1(f);
                    LOG1("..........substratum_field = ");
                    LOG1(field);
                    LOG1("..........substratum phv containers = "
                        << &(field->phv_containers())
                        << ".....");
                }
            }
        }
    }
}  // field_overlays

void
PHV_Container::field_overlays() {
    //
    // for all fields in container
    // if substratum field has overlay fields after cluster's interference graph computation
    // add those overlay fields to container's container_contents
    //
    // before overlay:
    // two fields can't have same cluster id in same container unless they are part of ccgf
    // after overlay:
    // Aggregate interference based overlay fields in container can retain same Agg cluster id
    //
    // get lowest allocation bit for ccgf field
    // overlay starts from this bit
    // e.g., ccgf f1 [f1,f2] may be allocation 22211111
    // lowest bit in container is 0 which is not the lowest bit of owner = 3
    //
    ordered_map<int, std::pair<int, int>> *lbcw = lowest_bit_and_ccgf_width();
    for (auto &cc_s : Values(fields_in_container_i)) {
        //
        // if field has overlay fields after cluster's interference graph computation
        // add those overlay fields to container's container_contents
        //
        for (auto &cc : cc_s) {
            int cluster_id = cc->field()->cl_id_num();
            field_overlays(
                cc->field(),
                (*lbcw)[cluster_id].first,  // not necessarily cc->lo() for ccgf field
                (*lbcw)[cluster_id].second,
                cc->field_bit_lo());
        }
    }
}  // field_overlays()

ordered_map<int, std::pair<int, int>>*
PHV_Container::lowest_bit_and_ccgf_width(bool by_cluster_id) {
    //
    // if by_cluster_id then map using cluster_id, to obtain all ccgf members in same container
    // else use field_id
    // lowest bit position of field's member in container
    // total size of all ccgf members in container
    //
    ordered_map<int, std::pair<int, int>> *lbcw = new ordered_map<int, std::pair<int, int>>;
    lbcw->clear();
    for (auto &cc_s : Values(fields_in_container_i)) {
        for (auto &cc : cc_s) {
            int id = by_cluster_id? cc->field()->cl_id_num(): cc->field()->id;
            int lo = cc->lo();
            int width = cc->width();
            if (PHV_Container::constraint_no_cohabit(cc->field())) {
                // entire container can be considered for overlay
                width = int(width_i);
            }
            if (lbcw->count(id)) {
                lo = std::min(lo, lbcw->at(id).first);
                width += lbcw->at(id).second;
                //
                // aggregate interference based overlays can overlay on top of each other
                // having the same cluster_id_num
                // double (multiple) counting their widths can exceed container width
                //
                width = std::min(width, int(width_i));
            }
            (*lbcw)[id] = std::make_pair(lo, width);
        }
    }
    return lbcw;
}  // lowest_bit_and_ccgf_width

PHV_Container::Container_Content* PHV_Container::taint_bits(
        int start,
        int width,
        PHV::Field *field,
        int field_bit_lo,
        Container_Content::Pass pass) {
    // XXX(cole)? Where is this encoding documented?
    if (taint_color_i == "9")
        taint_color_i = "a";
    else
        taint_color_i = taint_color_i.back() + '1' - '0';

    for (auto i=start; i < start+width; i++)
         bits_i[i] = taint_color_i.back();

    avail_bits_i -= width;  // packing reduces available bits
    BUG_CHECK(
        avail_bits_i >= 0,
        "*****PHV_Container::taint_bits()*****%s avail_bits = %d, field = %d:%s",
        this->toString(),
        avail_bits_i,
        field->id,
        field->name);

    if (status_i == Container_status::EMPTY)
        phv_mau_group_i->dec_empty_containers();

    //
    // first container placement, packing start lo = start + width
    // after packing, non contiguous availability
    // e.g., [15..15], [8..10] => ranges[15] = 15, ranges[8] = 10
    //
    if (avail_bits_i == 0 || constraint_no_cohabit(field)) {
        status_i = Container_status::FULL;
        if (constraint_no_cohabit(field)) {
            //
            // padding char for unoccupied but un-assignable bits
            //
            for (int i=0; i < int(width_i); i++)
                if (bits_i[i] == '0')
                    bits_i[i] = '-';
            avail_bits_i = 0;
        }
    } else {
        status_i = Container_status::PARTIAL;
    }
    create_ranges();

    // Update container gress, if unset
    if (!this->gress())
        this->gress(field->gress);
    BUG_CHECK(this->gress() && *this->gress() == field->gress,
        "Assigning field to container of wrong gress");

    // track fields in this container
    Container_Content *cc =
        new Container_Content(this, StartLen(start, width), field,
                              field_bit_lo, taint_color_i, pass);
    fields_in_container(field, cc);

    return cc;
}

void
PHV_Container::fields_in_container(std::list<Container_Content *>& cc_list) {
    // sorted in bit-wise order in container
    cc_list.clear();
    for (auto &cc_s : Values(fields_in_container_i)) {
        for (auto &cc : cc_s) {
            cc_list.push_back(cc);
        }
    }
    cc_list.sort([](Container_Content *l, Container_Content *r) {
        return l->lo() < r->lo();
    });
}

void
PHV_Container::fields_in_container(PHV::Field *f, Container_Content *cc) {
    assert(f);
    assert(cc);
    if (fields_in_container_i.count(f)) {
        for (auto &cc_slice : fields_in_container_i[f]) {
            //
            // ensure ranges do not overlay for field slices
            // e.g., a sliced field |phv_185_lo,0..3||phv_185_hi,4..8|[4..8]=
            // PHV-44.W44<5:17..21>, [0..3]=PHV-44.W44<5:25..28>
            //
            BUG_CHECK((cc_slice->hi() >= cc_slice->lo() && cc->hi() >= cc->lo())
                && (cc_slice->lo() > cc->hi() || cc_slice->hi() < cc->lo()),
                "*****PHV_Container::fields_in_container()*****"
                ".....field slices overlap.....\n"
                "<cc_slice_lo=%d..cc_slice_hi=%d> <cc->lo()=%d..cc->hi()=%d>\n"
                "cc_slice->field()=%d:%s, cc->field()=%d:%s\t%s",
                cc_slice->lo(), cc_slice->hi(), cc->lo(), cc->hi(),
                cc_slice->field()->id, cc_slice->field()->name,
                cc->field()->id, cc->field()->name,
                this->toString());
            // TODO
            // if two field slices are part of the same substratum then it is ok to have same color
            // introduce a substratum_field in cc to enable this check
            //
            // BUG_CHECK(cc_slice->taint_color() != cc->taint_color(),
                // "*****PHV_Container::fields_in_container()*****"
                // ".....field slices taint colors should not be same.....\n"
                // "<cc_slice_lo=%d..cc_slice_hi=%d> <cc->lo()=%d..cc->hi()=%d>\n"
                // "cc_slice->field()=%d:%s, cc->field()=%d:%s\n"
                // "cc_slice taint_color=%s ==  cc taint_color = %s\tin %s",
                // cc_slice->lo(), cc_slice->hi(), cc->lo(), cc->hi(),
                // cc_slice->field()->id, cc_slice->field()->name,
                // cc->field()->id, cc->field()->name,
                // cc_slice->taint_color(), cc->taint_color(),
                // this->toString());
        }
    }
    fields_in_container_i[f].push_back(cc);
    if (f->deparsed()) {
        set_deparsed(true);
    }
}  // fields_in_container f cc

void
PHV_Container::fields_in_container(int start, int end, ordered_set<PHV::Field *>& fs_set) {
    //
    // fields that overlap start .. end in container
    //
    // Substratum     |xxxxxx|
    // Overlay     xxx|x     |
    // Overlay        | xxxx |
    // Overlay      xx|xxxxxx|xx
    // Overlay        |     x|xxx
    //                ^      ^
    //                |      |
    //                start  end
    //
    for (auto &cc_slices : Values(fields_in_container_i)) {
        for (auto &cc : cc_slices) {
            if ((cc->lo() < start && cc->hi() >= start)
                || (cc->lo() >= start && cc->lo() <= end)) {
                //
                fs_set.insert(cc->field());
            }
        }
    }  // for
}  // fields_in_container fs_set

std::pair<int, int>
PHV_Container::start_bit_and_width(PHV::Field *f) {
    //
    assert(f);
    assert(fields_in_container_i.count(f));
    //
    int lo = 0;
    int w = 0;
    //
    if (fields_in_container_i[f].size() == 1) {
        Container_Content *cc = fields_in_container_i[f].front();
        lo = cc->lo();
        w = cc->width();
    } else {
        //
        // slices may be contiguous .. get contiguous width
        // or disjoint .. get max slice width
        //
        lo = -1;
        int hi = 0;
        for (auto &cc_s : fields_in_container_i[f]) {
            if (lo == -1) {
                lo = cc_s->lo();
                hi = cc_s->hi();
                w = cc_s->width();
            } else {
                if (hi + 1 == cc_s->lo()) {
                    // contiguous
                    // retain lo
                    w += cc_s->width();
                } else {
                    // disjoint
                    if (cc_s->width() > w) {
                        // select this slice as contender for max width
                        lo = cc_s->lo();
                        hi = cc_s->hi();
                        w = cc_s->width();
                    }
                }
            }
        }  // for
    }
    return std::make_pair(lo, w);
}  // start_bit_and_width

void
PHV_Container::holes(
    std::vector<char>& bits,
    char empty,
    std::list<std::pair<int, int>>& holes_list) {
    //
    int width = bits.size();
    int lo = -1;
    for (auto i=0; i < width; i++) {
        if (lo == -1 && bits[i] == empty) {
            lo = i;
        }
        if (lo != -1 && bits[i] != empty) {
            holes_list.push_back(std::make_pair(lo, i - 1));
            lo = -1;
        }
    }  // for
    if (lo != -1) {
        holes_list.push_back(std::make_pair(lo, width - 1));
    }
}  // holes vector bits

void PHV_Container::holes(std::list<std::pair<int, int>>& holes_list) const {
    //
    // identify holes in container
    //
    holes_list.clear();
    int width = int(width_i);
    std::vector<char> bits_v(bits_i, bits_i + width);  // 2nd arg "ptr to ch after end" not last ch
    if (status_i == Container_status::EMPTY) {
        holes_list.push_back(std::make_pair(0, width - 1));
    } else if (status_i == Container_status::PARTIAL) {
        holes(bits_v, '0', holes_list);
    } else {
        assert(status_i == Container_status::FULL);
        // "Full" container w/ pack-constrained fields can yield unoccupied, unassignable holes
        // however, if there are overlayed fields then no holes
        if (fields_in_container_i.size() == 1) {
            holes(bits_v, '-', holes_list);
        }
    }
}  // holes holes_list

//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************


void PHV_Container::Container_Content::sanity_check_container(
    PHV_Container *container,
    const std::string& msg) {
    const std::string msg_1 = msg + "..PHV_Container::Container_Content::sanity_check_container";
    //
    // fields can span containers
    //
    if (!constraint_no_cohabit(field_i) && field_i->phv_use_width() < width()) {
        LOG1(
            "*****cluster_phv_container.cpp:sanity_WARN*****....."
            << msg_1
            << std::endl
            << " field width less than width allocated in container: "
            << field_i->phv_use_width()
            << " vs "
            << container_range_i
            << std::endl
            << field_i
            << *container);
    }
    if (taint_color_i.front() == '-') {
        LOG1(
            "*****cluster_phv_container.cpp:sanity_WARN*****....."
            << msg_1
            << std::endl
            << " illegal field taint color: '"
            << taint_color_i
            << "'"
            << std::endl
            << field_i
            << *container);
    }
    //
    // cc lo .. hi must be tainted in c bits
    //
    if (overlayed() && taint_color_i == "0") {
        //
        // field_i was overlayed ahead of substratum member field of ccgf thus color was 0
        // update color to substratum field
        //
        LOG1(
            "*****cluster_phv_container.cpp:sanity_WARN*****....."
            << msg_1
            << std::endl
            << " overlayed field ahead of substratum field "
            << container_range_i
            << " taint_color_i "
            << taint_color_i
            << *container);
        if (container->taint_color(hi()) > container->taint_color(lo())) {
            taint_color_i = container->taint_color(lo()) + container->taint_color(hi());
        } else {
            taint_color_i = container->taint_color(lo());
        }
    }
    for (auto i=lo(); i <= hi(); i++) {
        if (container->bits()[i] != taint_color_i.back()) {
            if (overlayed() || header_stack_overlayed()) {
                //
                // overlayed fields may not exact match container taint
                // if they straddle substratum fields
                // they should have the concatenation of lowest+highest substratum taint number
                //
                if (taint_color_i !=
                    std::string(1, container->bits()[lo()]) +
                    std::string(1, container->bits()[hi()])) {
                    //
                    LOG1(
                        "*****cluster_phv_container.cpp:sanity_FAIL*****....."
                        << msg_1
                        << std::endl
                        << ".....overlayed field taint does not match container use:....."
                        << std::endl
                        << field_i
                        << std::endl
                        << container_range_i
                        << " taint_color_i "
                        << taint_color_i
                        << " should be "
                        << container->bits()[lo()]
                        << container->bits()[hi()]
                        << *container);
                }
                break;
            } else {
                // taint color NOT ok
                LOG1(
                    "*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << std::endl
                    << ".....field taint does not match container use:....."
                    << std::endl
                    << field_i
                    << std::endl
                    << container_range_i
                    << " taint_color_i "
                    << taint_color_i
                    << " should be "
                    << container->bits()[lo()]
                    << container->bits()[hi()]
                    << *container);
                break;
            }
        }
    }
}  // Container_Content::sanity_check_container

bool PHV_Container::sanity_check_deparsed_container_violation(
    const PHV::Field *&deparsed_header,
    const PHV::Field *&non_deparsed_field) const {
    // must not have deparsed header with non-deparsed field in container
    deparsed_header = nullptr;
    non_deparsed_field = nullptr;
    for (auto &entry : fields_in_container_i) {
        PHV::Field *cf = entry.first;
        if (!cf->deparsed()) {
            non_deparsed_field = cf;
        }
        if (!cf->metadata && cf->deparsed()) {
            deparsed_header = cf;
        }
    }  // for
    // ok if interference graph reduction overlays deparsed_header with non_deparsed_field
    if (deparsed_header && non_deparsed_field) {
        return !deparsed_header->is_overlay(non_deparsed_field);
    }
    return false;
}

void PHV_Container::sanity_check_container(const std::string& msg, bool check_deparsed) {
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_container";
    //
    // if container is deparsed then
    // (i) cannot have a mix of metadata & non-metadata fields
    // (ii) should not have unused bits
    // a deparsed container can have unused bits, but unused bits will be deparsed as well
    // arises in bridged metadata, where unused bits are padding on the wire
    //
    if (deparsed_i) {
        const PHV::Field *deparsed_header = nullptr;
        const PHV::Field *non_deparsed_field = nullptr;
        if (sanity_check_deparsed_container_violation(deparsed_header, non_deparsed_field)) {
            LOG3("*****cluster_phv_container.cpp:sanity_FAIL*****....."
            << msg_1
            << " non_deparsed_field with deparsed header in deparsed container "
            << this
            << std::endl
            << "deparsed_header = " << deparsed_header
            << std::endl
            << "non_deparsed_field = " << non_deparsed_field);
            BUG("cluster_phv_container.cpp:*****non_deparsed_field w/ deparsed header*****");
        }
        if (check_deparsed && avail_bits_i != 0) {
            LOG3("*****cluster_phv_container.cpp:sanity_WARN*****....."
            << msg_1
            << " deparsed container has avail_bits = "
            << avail_bits_i
            << this);
        }
    }
    //
    // for fields binned in this container check bits occupied
    //
    // check total occupation width against available bits
    //
    int occupation_width = 0;
    int overlayed_width = 0;
    for (auto &cc_s : Values(fields_in_container_i)) {
        for (auto &cc : cc_s) {
            cc->sanity_check_container(this, msg_1);
            sanity_check_container_avail(cc->lo(), cc->hi(), msg_1);
            if (cc->overlayed()) {
                // can have multiple overlays
                overlayed_width = std::max(overlayed_width, cc->width());
            } else {
                if (cc->field()->header_stack_pov_ccgf()) {
                    // header_stack_pov_ccgf counted as 1 bit occupation
                    occupation_width++;
                } else {
                    occupation_width += cc->width();
                }
            }
            // sanity check constraints on field
            if (constraint_no_cohabit(cc->field())) {
                // consider ccs that are not overlayed()
                int num_non_overlayed_cc = 0;
                for (auto &x : Values(fields_in_container_i)) {
                    for (auto &y : x) {
                        if (!y->overlayed()) {
                           num_non_overlayed_cc++;
                        }
                    }
                }
                if (num_non_overlayed_cc != 1) {
                    LOG3("*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << " cohabit fields with 'constraint_no_cohabit' "
                    << std::endl
                    << cc->field());
                }
                if (cc->overlayed()) {
                    // multiple
                    overlayed_width = std::max(overlayed_width, int(width_i));
                } else {
                    occupation_width = int(width_i);
                }
            }
            if (constraint_no_holes(cc->field())) {
                if (avail_bits_i) {
                    LOG4("*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << " container has holes with field 'constraint_no_holes' "
                    << std::endl
                    << cc);
                }
            }
        }  // for
    }  // for
    int fill = std::max(occupation_width, overlayed_width);
    if (fill + avail_bits_i != int(width_i)) {
        LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****....."
        << msg_1
        << " max(occupation_width, overlayed_width) + available_bits != container_width "
        << " occupation_width = " << occupation_width
        << " overlayed_width = " << overlayed_width
        << " available_bits = " << avail_bits_i
        << " container_width = " << width_i
        << *this);
    }
    //
    sanity_check_overlayed_fields(msg_1);
}  // sanity_check_container

void PHV_Container::sanity_check_overlayed_fields(const std::string& msg) {
    //
    // ensure overlayed field has span within its substratum field
    //
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_overlayed_fields";
    ordered_map<int, std::pair<int, int>> *cluster_lbcw = lowest_bit_and_ccgf_width(/*by_cluster*/);
    ordered_map<int, std::pair<int, int>> *field_lbcw = lowest_bit_and_ccgf_width(false/*byfield*/);
    for (auto &cc_s : Values(fields_in_container_i)) {
        for (auto &cc : cc_s) {
            if (cc->overlayed()) {
               PHV::Field *overlayed = cc->field();
               PHV::Field *substratum = overlayed->overlay_substratum();
               if (!substratum && overlayed->ccgf()) {
                   substratum = overlayed->ccgf()->overlay_substratum();
               }
               BUG_CHECK(substratum,
                    "*****cluster_phv_container.cpp:sanity_FAIL sanity_check_overlayed_fields*****"
                    ".....substratum is nil.....\nphv_container=%s[%d..%d]= overlayed_field=%d:%s",
                    this->toString(), cc->lo(), cc->hi(), cc->field()->id, cc->field()->name);
               // field lo's may disagree but cluster's low for ccgf fields can agree
               // PHV-123.B59.I.Fp        22222211
               // e.g.,
               // overlay lo = 1,2,3,4,5 vs substratum lo = 6 but substratum ccgf lo is 1
               // similarly for overlay range check
               //
               if ((*field_lbcw)[overlayed->id].first < (*field_lbcw)[substratum->id].first
                   && (*cluster_lbcw)[overlayed->cl_id_num()].first
                       < (*cluster_lbcw)[substratum->cl_id_num()].first) {
                    LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << std::endl
                    << ".....overlayed field has 'lo' < substratum....."
                    << std::endl
                    << "overlayed = " <<  overlayed
                    << " ..... lo = " <<  (*field_lbcw)[overlayed->id].first
                    << std::endl
                    << "substratum = " << substratum
                    << " ..... lo = " <<  (*field_lbcw)[substratum->id].first
                    << *this);
               }
               if ((*field_lbcw)[overlayed->id].second > (*field_lbcw)[substratum->id].second
                    && (*cluster_lbcw)[overlayed->cl_id_num()].second
                        > (*cluster_lbcw)[substratum->cl_id_num()].second) {
                    LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << std::endl
                    << ".....overlayed field has range > substratum....."
                    << std::endl
                    << "overlayed = " <<  overlayed
                    << " ..... width = " <<  (*field_lbcw)[overlayed->id].second
                    << std::endl
                    << "substratum = " << substratum
                    << " ..... width = " <<  (*field_lbcw)[substratum->id].second
                    << *this);
               }
               if (cc->taint_color().front() == '-') {
                    LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << std::endl
                    << ".....incorrectly overlayed on constrained substratum extension bits....."
                    << std::endl
                    << "overlayed = " <<  overlayed
                    << std::endl
                    << "substratum = " << substratum
                    << *this);
               }
            }
        }  // for
    }  // for
}  // sanity_check_overlayed_fields

void PHV_Container::sanity_check_container_avail(int lo, int hi, const std::string& msg) {
    //
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_container_avail";
    //
    // check container status
    //
    if ((avail_bits_i > 0 && status_i == Container_status::FULL)
     || (avail_bits_i == 0 && status_i != Container_status::FULL)
     || (avail_bits_i == int(width_i) && status_i != Container_status::EMPTY)
     || (fields_in_container_i.size() && status_i == Container_status::EMPTY)
     || (fields_in_container_i.size() == 0 && status_i != Container_status::EMPTY)) {
        //
        LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****....."
        << msg_1
        << " container status inconsisent w/ available bits or fields_in_container size "
        << static_cast<char>(status_i)
        << "..avail_bits="
        << avail_bits_i
        << "..fields in container="
        << fields_in_container_i
        << *this);
    }
    // check range map in container
    //
    sanity_check_container_ranges(msg_1, lo, hi);
    //
    // check available bits in container
    //
    if (status_i == Container_status::EMPTY && avail_bits_i < hi - lo) {
        LOG1(
            "*****cluster_phv_container.cpp:sanity_FAIL*****....."
            << msg_1
            << " container avail bits inconsistent "
            << lo
            << ".."
            << hi
            << " vs "
            << avail_bits_i
            << *this);
    }
    if (status_i == Container_status::FULL && avail_bits_i > 0) {
        LOG1(
            "*****cluster_phv_container.cpp:sanity_FAIL*****....."
            << msg_1
            << " container avail bits should be 0 "
            << lo
            << ".."
            << hi
            << " vs "
            << avail_bits_i
            << *this);
    }
    //
    // check bits in range lo .. hi
    //
    for (auto i = lo; i <= hi; i++) {
        if (status_i == Container_status::EMPTY && bits_i[i] != '0') {
            LOG1(
                "*****cluster_phv_container.cpp:sanity_FAIL*****....."
                << msg_1
                << " container bits should be '0' "
                << i
                << ": "
                << lo
                << ".."
                << hi
                << " vs "
                << *this);
            break;
        } else {
            if (status_i == Container_status::FULL && bits_i[i] == '0') {
                LOG1(
                    "*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << " container bits should be tainted non-0 "
                    << i
                    << ": "
                    << lo
                    << ".."
                    << hi
                    << " vs "
                    << *this);
                break;
            }
        }
    }
}  // sanity_check_container_avail

void PHV_Container::sanity_check_container_ranges(const std::string& msg, int lo, int hi) {
    //
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_container_ranges";
    //
    clean_ranges();
    bool range_absurd = false;
    for (auto r : ranges_i) {
        if (r.second < r.first) {
            range_absurd = true;
            LOG1(
                "*****cluster_phv_container.cpp:sanity_FAIL*****....."
                << msg_1
                << " range absurdity ["
                << r.first
                << "]="
                << r.second);
        }
    }
    if (range_absurd) {
        LOG1(ranges_i);
        LOG1(*this);
    }
    if (lo >= 0 && hi >= 0) {
        // check either all lo .. hi occupied or not occupied
        bool occupied = false;
        for (auto i = lo; i <= hi; i ++) {
            if (bits_i[i] != '0') {
                occupied = true;
                break;
            }
        }
        std::string error_message = "";
        if (occupied) {
            if (ranges_i[lo]) {
                error_message = ".....container ranges should not be available.....";
            }
        } else {
            bool available = false;
            for (auto &r : ranges_i) {
                // ranges_i[1] = 7 ok for slice 3..5
                if (r.first <= lo && r.second >= hi) {
                    available = true;
                    break;
                }
            }
            if (!available) {
                error_message = ".....container ranges not available.....";
            }
        }
        if (error_message != "") {
            LOG1(
                "*****cluster_phv_container.cpp:sanity_FAIL*****....."
                << msg_1
                << std::endl
                << error_message
                << '['
                << lo
                << ".."
                << hi
                << ']'
                << ranges_i
                << *this);
        }
    }
    clean_ranges();
}  // sanity_check_container_ranges

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
// Container_Content output
//
std::ostream &operator<<(std::ostream &out, PHV_Container::Container_Content *cc) {
    if (cc) {
        out << "\t\t\t\t";
        out << "  "
            << cc->taint_color()
            << static_cast<char>(cc->pass())                   // indicates Pass that overlayed
            << ' '
            << cc->field()
            << "["
            << cc->field_bit_lo()
            << ".."
            << cc->field_bit_hi()
            << "]"
            << "="
            << cc->container()
            << "<"
            << cc->width()
            << ':'
            << cc->lo()
            << ".."
            << cc->hi()
            << '>';
    } else {
        out << "-cc-";
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<PHV_Container::Container_Content *>& x_cc) {
    if (x_cc.size()) {
        out << std::endl;
    }
    for (auto &cc : x_cc) {
        out << cc << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container::Container_Content *>& x_cc) {
    if (x_cc.size()) {
        out << std::endl;
    }
    for (auto &cc : x_cc) {
        out << cc << std::endl;
    }
    return out;
}

// ordered_set
std::ostream &operator<<(std::ostream &out, ordered_set<PHV_Container::Container_Content *>& x_cc) {
    if (x_cc.size()) {
        out << std::endl;
    }
    for (auto &cc : x_cc) {
        out << cc << std::endl;
    }
    return out;
}

//
// phv_container output
//

std::ostream &operator<<(std::ostream &out, ordered_map<int, int>& ranges) {
    out << std::endl << ".....container ranges are.....";
    for (auto i : ranges) {
        out << " [" << i.first << "]=" << i.second;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Container *c) {
    //
    // summary output
    //
    if (c) {
        out << std::endl << '\t';
        out << c->toString() << '.' << c->gress() << '.' << static_cast<char>(c->status());
        if (c->deparsed())
            out << "d";
        if (c->fields_in_container().size() > 1)
            out << "p";
        for (auto r : c->ranges()) {
            // when container FULL, range[0] = -1
            if (r.second != -1)
                out << '(' << r.first << ".." << r.second << ')'; }
        // print bits in container, fields placed
        out << '\t' << c->bits()
            << c->fields_in_container();
    } else {
        out << "-c-";
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV_Container *c) {
    if (c) {
        out << c->toString();
    } else {
        out << "-c-";
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Container &c) {
    // detailed output
    //
    out << '\t' << &c;
    return out;
}

std::ostream &operator<<(std::ostream &out, ordered_set<PHV_Container *> &phv_containers) {
    // detailed output for phv containers
    for (auto &c : phv_containers) {
        out << *c;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, ordered_set<PHV_Container *> *phv_containers) {
    // terse output for phv containers
    assert(phv_containers);
    out << "[";
    for (auto &c : *phv_containers) {
        out << c->toString() << ';';
    }
    out << "]";
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container *> &phv_containers) {
    for (auto &c : phv_containers) {
        out << *c;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<PHV_Container *> &phv_containers) {
    for (auto &c : phv_containers) {
        out << c;
    }
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PHV::Field *, std::list<PHV_Container::Container_Content *>>& fields_cc_map) {
    for (auto &cc_s : Values(fields_cc_map)) {
        for (auto &cc : cc_s) {
            out << std::endl
                << cc;
        }
    }
    return out;
}

