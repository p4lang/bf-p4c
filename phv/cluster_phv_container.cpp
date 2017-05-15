#include "cluster_phv_container.h"
#include "cluster_phv_mau.h"
#include "cluster_phv_operations.h"
#include "lib/log.h"
#include "lib/stringref.h"

//***********************************************************************************
//
// PHV_Container::Container_Content::Container_Content constructor
//
//***********************************************************************************

PHV_Container::Container_Content::Container_Content(
    const PHV_Container *c,
    const int l,
    const int w,
    PhvInfo::Field *f,
    const int field_bit_lo,
    const std::string taint_color,
    bool overlayed,
    Pass pass)
        : container_i(c),
          lo_i(l),
          hi_i(l+w-1),
          field_i(f),
          field_bit_lo_i(field_bit_lo),
          taint_color_i(taint_color),
          overlayed_field_i(overlayed),
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
    PHV_Word w,
    int phv_n,
    std::string asm_string,
    Ingress_Egress gress)
    : phv_mau_group_i(g),
      width_i(w),
      phv_number_i(phv_n),
      asm_string_i(asm_string),
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
    bits_i = new char[width_i];
    for (auto i=0; i < width_i; i++) {
        bits_i[i] = taint_color_i.back();
    }
    avail_bits_i = width_i;
    ranges_i.clear();
    ranges_i[0] = width_i - 1;
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
        ranges_i[0] = width_i - 1;
    } else {
        if (status_i == PHV_Container::Container_status::PARTIAL) {
            for (auto i=0; i < width_i ; i++) {
                if (bits_i[i] == '0') {
                    for (auto j=i; j < width_i ; j++) {
                        if (bits_i[j] != '0') {
                            ranges_i[i] = j - 1;
                            i = j - 1;
                            break;
                        }
                        if (j == width_i - 1) {
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
    PhvInfo::Field *field,
    int range_start,
    int field_bit_lo) {
    //
    BUG_CHECK((start+width <= width_i),
        "*****PHV_Container::taint()*****%s start=%d width=%d width_i=%d, field=%d:%s",
        phv_number_string(), start, width, width_i, field->id, field->name);
    BUG_CHECK((range_start < width_i),
        "*****PHV_Container::taint()*****%s range_start=%d width=%d width_i=%d, field=%d:%s",
        phv_number_string(), start, width, width_i, field->id, field->name);
    if (ranges_i[range_start]) {
        BUG_CHECK(start+width <= ranges_i[range_start]+1,
            "*****PHV_Container::taint()*****"
            "%s start=%d width=%d range_start=%d ranges_i[range_start]=%d, field=%d:%s",
            phv_number_string(),
            start, width, range_start, ranges_i[range_start], field->id, field->name);
    }
    //
    // ccgf field processing
    //
    if (field->ccgf() == field) {
        return taint_ccgf(start, width, field, field_bit_lo);
    }
    //
    // non cluster_overlay fields
    // includes interference based overlay fields
    //
    taint_bits(start, width, field, field_bit_lo);
    //
    // if field has overlay fields after cluster's interference graph computation
    // add those overlay fields to container's container_contents
    // -- now performed after all phv/tphv allocation as a final pass in cluster_phv_mau.cpp
    //
    // field_overlays(
        // field,
        // start,
        // width,
        // field_bit_lo);
    //
    // set gress for this container
    // container may be part of MAU group that is Ingress Or Egress
    // however for any stage it is used exclusively for Ingress or for Egress
    // cannot share container with Ingress fields & Egress fields
    // transition behavior for such sharing unclear
    //
    // ignore gress of $tmp fields as cluster_phv sets its gress based on non-tmps
    //
    if (strncmp(field->name, "$tmp", strlen("$tmp"))) {
        gress_i = gress(field);
        if (phv_mau_group_i->gress() == Ingress_Egress::Ingress_Or_Egress) {
            phv_mau_group_i->gress(gress_i);
        } else {
            assert(phv_mau_group_i->gress() == gress_i);
        }
    }
    sanity_check_container_ranges("PHV_Container::taint()..");
    return width;  // all bits of this field processed
}  // taint()

int
PHV_Container::taint_ccgf(
    int start,
    int width,
    PhvInfo::Field *field,
    int field_bit_lo) {
    //
    // container contiguous groups
    // header fields allocation permits no holes in container
    // for each member taint container with appropriate width
    // must consider MSB order
    //
    // header stack pov's allocation is composition of members
    // it is not present as a member in its ccgf
    // as no separate allocation required
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
                // if width_i (8) is less than member size (egress_port: 9), No padding
                // such egress_ports may come assigned to 2 Byte containers
                //
                if (width_i < member->size) {
                    LOG1(
                        "*****cluster_phv_container.cpp:sanity_WARN*****....."
                        << " width_i of container "
                        << width_i
                        << " is less than 'no-pack' ccgf member size "
                        << member->size
                        << std::endl
                        << member);
                } else {
                    // width_i >= member->size)
                    int pad = width - member->size;
                    start -= pad;               // taint starts from RHS
                }
            }
        }
        int use_width = member->size;           // always using size to taint container
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
            member->phv_use_rem(member->phv_use_rem() + use_width);
                                                // spans several containers, aggregate used bits
        } else {
            member->phv_use_rem(0);
            processed_members++;
        }
        member->ccgf(0);        // recursive taint call should skip ccgf
        taint(start, use_width, member, start /*range start*/, member_bit_lo);
        processed_width += constraint_no_cohabit(member)? width_i: use_width;
        if (start <= 0) {
            break;
        }
    }  // for ccgf members
    //
    // update ccgf owner record
    //
    update_ccgf(field, processed_members, processed_width);

    if (field->header_stack_pov_ccgf()) {
        fields_in_container(
            field,
            new Container_Content(this, 0/*start*/, width, field, field_bit_lo, taint_color_i));
    }

    return processed_width;  // all bits of this field may NOT be processed
}  // taint_ccgf

void
PHV_Container::update_ccgf(
    PhvInfo::Field *field,
    int processed_members,
    int processed_width) {
    //
    field->ccgf_fields().erase(
        field->ccgf_fields().begin(),
        field->ccgf_fields().begin() + processed_members);
    field->phv_use_hi(field->phv_use_hi() - processed_width);
    if (field->ccgf_fields().size()) {
        field->ccgf(field);
    } else {
        field->ccgf(0);
        // ccgf owners with no-pack constraint, set range to entire container
        Cluster::set_field_range(field, constraint_no_cohabit(field)? width_i: 0);
    }
}  // update_ccgf

void
PHV_Container::overlay_ccgf_field(
    PhvInfo::Field *field,
    int start,
    int width,
    Container_Content::Pass pass) {
    //
    // if two ccgfs are overlayed, start from lowest phv_use bit of substratum
    // e.g.,
    // 25:ingress::hdr_1[0].d_0[4]{0..7}
    // [  25:ingress::hdr_1[0].d_0[4]
    //    26:ingress::hdr_1[0].d_1[4]
    // :8]     [r0] = [13(12,13,);]
    // overlayed with
    // 13:ingress::hdr_0.a_1[4]{0..7}
    // [  12:ingress::hdr_0.a_0[4]
    //    13:ingress::hdr_0.a_1[4]
    // :8]
    // d_1 = 0..3, d_0 = 4..7
    // ccgf d_0(d_0,d_1) = ccgf a_1(a_0,a_1)
    // a_0 start = 0, not owner d_0 start which is 4
    //
    for (auto &member : field->ccgf_fields()) {
        int member_bit_lo = member->phv_use_lo() + member->phv_use_rem();
        int use_width = member->size - member->phv_use_rem();
        if (use_width > width) {
            //
            // member straddles containers
            // remainder bits processed in subsequent container allocated to owner
            //
            use_width = width;
            member->phv_use_rem(member->phv_use_rem() + use_width);
                                                // spans several containers, aggregate used bits
        } else {
            member->phv_use_rem(0);
        }
        fields_in_container(
            member,
            new Container_Content(
               this,
               start,
               use_width,
               member,
               member_bit_lo,
               taint_color(start, start + use_width - 1),
               true /* overlayed field */,
               pass /* pass that performs the overlay */));
        width -= use_width;
        if (width <= 0) {
            break;
        }
        start += use_width;
    }  // for ccgf members
}  // overlay_ccgf_field

void
PHV_Container::single_field_overlay(
    PhvInfo::Field *f,
    const int start,
    const int width,
    const int field_bit_lo,
    Container_Content::Pass pass) {
    //
    assert(f);
    assert(start >= 0);
    assert(width >= 0);
    //
    if (f->ccgf_fields().size()) {
        overlay_ccgf_field(f, start, width, pass);
    } else {
        fields_in_container(
            f,
            new Container_Content(
                this,
                start,
                width,
                f,
                field_bit_lo,
                taint_color(start, start + width - 1),
                true /* overlayed field */,
                pass /* pass that performs the overlay */));
    }
    LOG3("\t==> overlayed'" << static_cast<char>(pass) << "' " << f
        << "[" << field_bit_lo << ".." << field_bit_lo + width - 1 << "]");
}  // single_field_overlay

void
PHV_Container::field_overlays(
    PhvInfo::Field *field,
    int start,
    int width,
    const int field_bit_lo) {
    //
    assert(field);
    //
    if (field->field_overlay_map().size()) {
        LOG3("\t.....PHV_Container::field_overlays.....");
        LOG3("\t" << field);
        for (auto &entry : field->field_overlay_map()) {
            if (entry.second) {
                for (auto &f : *(entry.second)) {
                    single_field_overlay(
                        f,
                        start,
                        width,
                        field_bit_lo,
                        Container_Content::Pass::Field_Interference);
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
            if (lbcw->count(id)) {
                lo = std::min(lo, lbcw->at(id).first);
                width += lbcw->at(id).second;
                //
                // aggregate interference based overlays can overlay on top of each other
                // having the same cluster_id_num
                // double (mutliple) counting their widths can exceed container width
                //
                width = std::min(width, static_cast<int>(width_i));
            }
            (*lbcw)[id] = std::make_pair(lo, width);
        }
    }
    return lbcw;
}  // lowest_bit_and_ccgf_width

void
PHV_Container::taint_bits(
    int start,
    int width,
    PhvInfo::Field *field,
    int field_bit_lo) {
    //
    if (taint_color_i == "9") {
        taint_color_i = "a";
    } else {
        taint_color_i = taint_color_i.back() + '1' - '0';
    }
    for (auto i=start; i < start+width; i++) {
         bits_i[i] = taint_color_i.back();
    }
    //
    avail_bits_i -= width;  // packing reduces available bits
    BUG_CHECK(
        avail_bits_i >= 0,
        "*****PHV_Container::taint_bits()*****%s avail_bits = %d, field = %d:%s ",
        phv_number_string(),
        avail_bits_i,
        field->id,
        field->name);
    //
    if (status_i == Container_status::EMPTY) {
        phv_mau_group_i->dec_empty_containers();
    }
    //
    // first container placement, packing start lo = start + width
    // after packing, non contiguous availability
    // e.g., [15..15], [8..10] => ranges[15] = 15, ranges[8] = 10
    //
    if (avail_bits_i == 0
        || constraint_no_cohabit(field)) {
        //
        status_i = Container_status::FULL;
        if (constraint_no_cohabit(field)) {
            //
            // padding char for unoccupied but un-assignable bits
            // occupation may start at LSb or MSb
            //
            if (bits_i[0] != '0') {
                // LSb occupied
                for (auto i = width_i - avail_bits_i; i < width_i; i++) {
                    bits_i[i] = '-';
                }
            } else {
                // MSb occupied
                for (auto i=0; i < avail_bits_i; i++) {
                    bits_i[i] = '-';
                }
            }
            avail_bits_i = 0;
        }
    } else {
        status_i = Container_status::PARTIAL;
    }
    create_ranges();
    //
    // track fields in this container
    //
    fields_in_container(
        field,
        new Container_Content(this, start, width, field, field_bit_lo, taint_color_i));
}  // taint_bits()

void
PHV_Container::fields_in_container(PhvInfo::Field *f, Container_Content *cc) {
    assert(f);
    assert(cc);
    if (fields_in_container_i.count(f)) {
        for (auto &cc_slice : fields_in_container_i[f]) {
            // ensure ranges do not overlay for field slices
            int s_lo = cc_slice->lo();
            int s_hi = cc_slice->hi();
            BUG_CHECK(((s_lo >= cc->lo() && s_lo <= cc->hi())
               || (s_hi >= cc->lo() && s_hi <= cc->hi())),
                "*****PHV_Container::fields_in_container()*****"
                "<s_lo=%d..s_hi=%d> <cc->lo()=%d..cc->hi()=%d>,"
                "cc_slice->field()=%d:%s, cc->field()=%d:%s",
                s_lo, s_hi, cc->lo(), cc->hi(),
                cc_slice->field()->id, cc_slice->field()->name, cc->field()->id, cc->field()->name);
        }
    }
    fields_in_container_i[f].push_back(cc);
}  // fields_in_container f cc

void
PHV_Container::fields_in_container(int start, int end, ordered_set<PhvInfo::Field *>& fs_set) {
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
PHV_Container::start_bit_and_width(PhvInfo::Field *f) {
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
            << lo_i
            << ".."
            << hi_i
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
    if (overlayed_field_i && taint_color_i == "0") {
        //
        // field_i was overlayed ahead of substratum member field of ccgf thus color was 0
        // update color to substratum field
        //
        LOG1(
            "*****cluster_phv_container.cpp:sanity_WARN*****....."
            << msg_1
            << std::endl
            << " overlayed field ahead of substratum field "
            << lo_i
            << ".."
            << hi_i
            << " taint_color_i "
            << taint_color_i
            << *container);
        if (container->taint_color(hi_i) > container->taint_color(lo_i)) {
            taint_color_i = container->taint_color(lo_i) + container->taint_color(hi_i);
        } else {
            taint_color_i = container->taint_color(lo_i);
        }
    }
    for (auto i=lo_i; i <= hi_i; i++) {
        if (container->bits()[i] != taint_color_i.back()) {
            if (overlayed_field_i) {
                //
                // overlayed fields may not exact match container taint
                // if they straddle substratum fields
                // they should have the concatenation of lowest+highest substratum taint number
                //
                if (taint_color_i !=
                    std::string(1, container->bits()[lo_i]) +
                    std::string(1, container->bits()[hi_i])) {
                    //
                    LOG1(
                        "*****cluster_phv_container.cpp:sanity_FAIL*****....."
                        << msg_1
                        << std::endl
                        << ".....overlayed field taint does not match container use:....."
                        << std::endl
                        << field_i
                        << std::endl
                        << lo_i
                        << ".."
                        << hi_i
                        << " taint_color_i "
                        << taint_color_i
                        << " should be "
                        << container->bits()[lo_i]
                        << container->bits()[hi_i]
                        << *container);
                }
                break;
            } else {
                if (field_i->header_stack_pov_ccgf()) {
                    //
                    // PHV-111.B47.E.Pp(0..0)  05432221
                    // 1= 948:egress::vxlan_gpe_int_header.$valid<1>
                    // .....
                    // 4= 976:egress::mpls[1].$valid<1>
                    // 5= 977:egress::mpls[2].$valid<1>
                    // 5= 978:egress::mpls.$stkvalid<6:0..5>
                    //
                    if (container->bits()[hi_i - field_i->phv_use_width()]
                        == taint_color_i.back()) {
                        // taint color ok
                        break;
                    }
                }
                LOG1(
                    "*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << std::endl
                    << ".....field taint does not match container use:....."
                    << std::endl
                    << field_i
                    << std::endl
                    << lo_i
                    << ".."
                    << hi_i
                    << " taint_color_i "
                    << taint_color_i
                    << " should be "
                    << container->bits()[lo_i]
                    << container->bits()[hi_i]
                    << *container);
                break;
            }
        }
    }
}  // Container_Content::sanity_check_container

void PHV_Container::sanity_check_container(const std::string& msg) {
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_container";
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
                // discount header_stack_pov_ccgf
                if (!cc->field()->header_stack_pov_ccgf()) {
                    occupation_width += cc->width();
                }
            }
            // sanity check constraints on field
            if (constraint_no_cohabit(cc->field())) {
                if (fields_in_container_i.size() != 1) {
                    LOG3("*****cluster_phv_container.cpp:sanity_FAIL*****....."
                    << msg_1
                    << " cohabit fields with 'constraint_no_cohabit' "
                    << cc->field());
                }
                if (cc->overlayed()) {
                    // multiple
                    overlayed_width = std::max(overlayed_width, static_cast<int>(width_i));
                } else {
                    occupation_width = width_i;
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
    if (fill + avail_bits_i != width_i) {
        LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****....."
        << msg_1
        << " fill + available_bits != container_width "
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
               PhvInfo::Field *overlayed = cc->field();
               PhvInfo::Field *substratum = overlayed->overlay_substratum();
               assert(substratum);
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
     || (avail_bits_i == width_i && status_i != Container_status::EMPTY)
     || (fields_in_container_i.size() && status_i == Container_status::EMPTY)) {
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
    out << std::endl << ".....container ranges....." << std::endl;
    for (auto i : ranges) {
        out << '[' << i.first << "] -- " << i.second << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV_Container *c) {
    if (c) {
        out << c->phv_number_string()
            << '.'
            << c->asm_string();
    } else {
        out << "-c-";
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Container *c) {
    //
    // summary output
    //
    if (c) {
        out << std::endl << '\t';
        out << c->phv_number_string()
            << '.' << c->asm_string()
            << '.' << static_cast<char>(c->gress())
            << '.' << static_cast<char>(c->status());
        if (c->fields_in_container().size() > 1) {
            out << "p";
        }
        for (auto r : c->ranges()) {
            // when container FULL, range[0] = -1
            if (r.second != -1) {
                out << '(' << r.first << ".." << r.second << ')';
            }
        }
    } else {
        out << "-c-";
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Container &c) {
    // detailed output
    //
    out << '\t' << &c
        << '\t' << c.bits()
        << c.fields_in_container();
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
    ordered_map<PhvInfo::Field *, std::list<PHV_Container::Container_Content *>>& fields_cc_map) {
    for (auto &cc_s : Values(fields_cc_map)) {
        for (auto &cc : cc_s) {
            out << std::endl
                << cc;
        }
    }
    return out;
}

