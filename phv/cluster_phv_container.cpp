#include "cluster_phv_container.h"
#include "cluster_phv_mau.h"
#include "cluster_phv_operations.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_Container::Container_Content::Container_Content constructor
//
//***********************************************************************************

PHV_Container::Container_Content::Container_Content(
    const PHV_Container *c,
    const int l,
    const int w,
    const PhvInfo::Field *f,
    const int field_bit_lo,
    const char taint_color)
        : container_i(c),
          lo_i(l),
          hi_i(l+w-1),
          field_i(f),
          field_bit_lo_i(field_bit_lo),
          taint_color_i(taint_color) {
    //
    BUG_CHECK(
        field_i,
        "*****PHV_Container::Container_Content constructor called with null field ptr*****");
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
    taint_color_i = '0';
    bits_i = new char[width_i];
    for (auto i=0; i < width_i; i++) {
        bits_i[i] = taint_color_i;
    }
    avail_bits_i = width_i;
    ranges_i.clear();
    ranges_i[0] = width_i - 1;
    //
    o_fields_in_container_i.clear();
    o_taint_color_i = '0';
    o_bits_i = new char[width_i];
    for (auto i=0; i < width_i; i++) {
        o_bits_i[i] = o_taint_color_i;
    }
    avail_o_bits_i = width_i;
    o_ranges_i.clear();
    o_ranges_i[0] = width_i - 1;
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
    for (auto r : ranges_i) {
        if (r.second < r.first || (r.second == r.first &&  bits_i[r.first] != '0')) {
            clear_these.insert(r.first);
        }
    }
    for (auto r : clear_these) {
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
    const PhvInfo::Field *field,
    int range_start,
    int field_bit_lo,
    bool cluster_phv_overlay) {
    //
    BUG_CHECK((start+width <= width_i),
        "*****PHV_Container::taint()*****PHV-%s start=%d width=%d width_i=%d, field=%d:%s",
        phv_number_i, start, width, width_i, field->id, field->name);
    BUG_CHECK((range_start < width_i),
        "*****PHV_Container::taint()*****PHV-%s range_start=%d width=%d width_i=%d, field=%d:%s",
        phv_number_i, start, width, width_i, field->id, field->name);
    if (!cluster_phv_overlay && ranges_i[range_start]) {
        BUG_CHECK(start+width <= ranges_i[range_start]+1,
            "*****PHV_Container::taint()*****"
            "PHV-%s start=%d width=%d range_start=%d ranges_i[range_start]=%d, field=%d:%s",
            phv_number_i, start, width, range_start, ranges_i[range_start], field->id, field->name);
    }
    if (cluster_phv_overlay && o_ranges_i[range_start]) {
        BUG_CHECK(start+width <= o_ranges_i[range_start]+1,
            "*****PHV_Container::taint()*****"
            "PHV-%s start=%d width=%d range_start=%d o_ranges_i[range_start]=%d, field=%d:%s",
            phv_number_i, start, width, range_start, o_ranges_i[range_start],
            field->id, field->name);
    }
    //
    // ccgf field processing
    //
    if (field->ccgf == field) {
        return taint_ccgf(start, width, field, field_bit_lo);
    }
    //
    // taint() for cluster overlay fields
    //
    if (cluster_phv_overlay) {
        //
        // cluster_overlay fields only
        //
        taint_overflow_bits(start, width, field, range_start, field_bit_lo);
    } else {
        //
        // non cluster_overlay fields
        // includes interference based overlay fields
        //
        taint_bits(start, width, field, field_bit_lo);
        //
        // if field has overlay fields after cluster's interference graph computation
        // add those overlay fields to container's container_contents
        //
        overlay_fields(
            const_cast<PhvInfo::Field *>(field),
            start,
            width,
            field_bit_lo,
            taint_color_i);
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
    }
    sanity_check_container_ranges("PHV_Container::taint()..");
    return width;  // all bits of this field processed
}  // taint()

int
PHV_Container::taint_ccgf(
    int start,
    int width,
    const PhvInfo::Field *field,
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
    for (auto &member : field->ccgf_fields) {
        if (constraint_no_cohabit_exclusive_mau(member)) {
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
                assert(width_i >= member->size);
                int pad = width - member->size;
                start -= pad;                   // taint starts from RHS
            }
        }
        int use_width = member->size;           // always using size to taint container
        if (!member->simple_header_pov_ccgf) {  // ignore simple header ccgf
            use_width -= member->phv_use_rem;
        }
        start -= use_width;
        int member_bit_lo = member->phv_use_lo;
        if (start < 0) {
            //
            // member straddles containers
            // remainder bits processed in subsequent container allocated to owner
            //
            use_width += start;  // start is -ve
            start = 0;
            member_bit_lo = member->size - member->phv_use_rem - use_width;
            member->phv_use_rem += use_width;  // spans several containers, aggregate used bits
        } else {
            member->phv_use_rem = 0;
            processed_members++;
        }
        member->ccgf = 0;        // recursive taint call should skip ccgf
        taint(start, use_width, member, start /*range start*/, member_bit_lo);
        processed_width += constraint_no_cohabit_exclusive_mau(member)? width_i: use_width;
        if (start <= 0) {
            break;
        }
    }  // for ccgf members
    // update ccgf owner record
    PhvInfo::Field *f1 = const_cast<PhvInfo::Field *>(field);
    f1->ccgf_fields.erase(
        f1->ccgf_fields.begin(),
        f1->ccgf_fields.begin() + processed_members);
    f1->phv_use_hi -= processed_width;
    if (field->ccgf_fields.size()) {
        f1->ccgf = f1;
    } else {
        f1->ccgf = 0;
        Cluster::set_field_range(f1);
    }

    if (field->header_stack_pov_ccgf) {
        fields_in_container_i.push_back(
            new Container_Content(this, 0/*start*/, width, field, field_bit_lo, taint_color_i));
    }

    return processed_width;  // all bits of this field may NOT be processed
}  // taint_ccgf

void
PHV_Container::overlay_fields(
    PhvInfo::Field *f_overlay,
    const int start,
    const int width,
    const int field_bit_lo,
    const char taint_color) {
    //
    assert(f_overlay);
    //
    if (f_overlay->field_overlay_map().size()) {
        for (auto &entry : f_overlay->field_overlay_map()) {
            if (entry.second) {
                for (auto &f : *(entry.second)) {
                    if (f->ccgf_fields.size()) {
                        int m_start = start;
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
                        // a_1 start = 0, not 4
                        //
                        if (f_overlay->ccgf_fields.size()) {
                            for (auto &m : f_overlay->ccgf_fields) {
                                m_start = std::min(m_start, m->phv_use_lo);
                            }
                        }
                        for (auto &m : f->ccgf_fields) {
                            int m_width = m->size;
                            int m_field_bit_lo = m->phv_use_lo;
                            fields_in_container_i.push_back(
                                new Container_Content(
                                   this,
                                   m_start,
                                   m_width,
                                   m,
                                   m_field_bit_lo,
                                   taint_color));
                            m_start += m_width;
                        }
                    } else {
                        fields_in_container_i.push_back(
                            new Container_Content(
                                this,
                                start,
                                width,
                                f,
                                field_bit_lo,
                                taint_color));
                    }
                    LOG3(".....PHV_Container::overlay_fields.....");
                    LOG3(f_overlay << " == " << f);
                }
            }
        }
    }
}  // overlay_fields()

void
PHV_Container::taint_overflow_bits(
    int start,
    int width,
    const PhvInfo::Field *field,
    int range_start,
    int field_bit_lo) {
    //
    o_taint_color_i += '1' - '0';
    if (o_taint_color_i < '0' || o_taint_color_i > '9') {
        o_taint_color_i = '*';
    }
    for (auto i=start; i < start+width; i++) {
        o_bits_i[i] = o_taint_color_i;
    }
    avail_o_bits_i -= width;  // packing reduces available bits
    BUG_CHECK(
            avail_o_bits_i >= 0,
            "*****PHV_Container::taint_overflow_bits()*****PHV-%s avail_o_bits = %d",
            phv_number_i,
            avail_o_bits_i);
    if (avail_o_bits_i == 0) {
        o_status_i = Container_status::FULL;
        o_ranges_i.clear();
    } else {
        o_status_i = Container_status::PARTIAL;
        if (range_start == start) {
            if (start+width < o_ranges_i[start]+1) {
                o_ranges_i[start+width] = o_ranges_i[start];
            }
            o_ranges_i.erase(start);
        } else {
            o_ranges_i[range_start] = start-1;
        }
    }
    //
    o_fields_in_container_i.push_back(
            new Container_Content(this, start, width, field, field_bit_lo, taint_color_i));
}  // taint_overflow_bits()

void
PHV_Container::taint_bits(
    int start,
    int width,
    const PhvInfo::Field *field,
    int field_bit_lo) {
    //
    if (taint_color_i == '9') {
        taint_color_i = 'a';
    } else {
        taint_color_i += '1' - '0';
    }
    for (auto i=start; i < start+width; i++) {
         bits_i[i] = taint_color_i;
    }
    //
    avail_bits_i -= width;  // packing reduces available bits
    BUG_CHECK(
        avail_bits_i >= 0,
        "*****PHV_Container::taint_bits()*****PHV-%s avail_bits = %d, field = %d:%s ",
        phv_number_i,
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
            // padding char for unoccupied but un-assignable bits
            for (auto i=width_i - avail_bits_i; i < width_i; i++) {
                bits_i[i] = '-';
            }
        }
    } else {
        status_i = Container_status::PARTIAL;
    }
    create_ranges();
    //
    // track fields in this container
    //
    fields_in_container_i.push_back(
        new Container_Content(this, start, width, field, field_bit_lo, taint_color_i));
}  // taint_bits()


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
    if (field_i->size <= width()) {
        if (field_i->phv_use_hi - field_i->phv_use_lo + 1 != width()) {
            LOG1(
                "*****cluster_phv_container.cpp:sanity_FAIL*****.."
                << msg_1
                << " field width does not match container use "
                << field_i->phv_use_lo
                << ".."
                << field_i->phv_use_hi
                << " vs "
                << lo_i
                << ".."
                << hi_i
                << ".."
                << field_i
                << *container);
        }
    }
    //
    // cc lo .. hi must be tainted in c bits
    //
    for (auto i=lo_i; i <= hi_i; i++) {
        if (container->bits()[i] != taint_color_i) {
            LOG1(
                "*****cluster_phv_container.cpp:sanity_FAIL*****.."
                << msg_1
                << " field taint does not match container use "
                << lo_i
                << ".."
                << hi_i
                << " should be tainted "
                << taint_color_i
                << *container);
        }
    }
}

void PHV_Container::sanity_check_container(const std::string& msg) {
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_container";
    //
    // for fields binned in this container check bits occupied
    //
    // check total occupation width against available bits
    //
    int occupation_width = 0;
    for (auto &cc : fields_in_container_i) {
        cc->sanity_check_container(this, msg_1);
        sanity_check_container_avail(cc->lo(), cc->hi(), msg_1);
        occupation_width += cc->width();
        // sanity check constraints on field
        if (constraint_no_cohabit(cc->field())) {
            if (fields_in_container_i.size() != 1) {
                LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.."
                << msg_1
                << " cohabit fields with 'constraint_no_cohabit' "
                << cc->field());
            }
        }
        if (constraint_no_holes(cc->field())) {
            if (avail_bits_i) {
                LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.."
                << msg_1
                << " container has holes with field 'constraint_no_holes' "
                << cc->field());
            }
        }
    }
    if (occupation_width + avail_bits_i != width_i) {
        LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.."
        << msg_1
        << " occupation_width + available_bits != container_width "
        << " occupation_width = " << occupation_width
        << " available_bits = " << avail_bits_i
        << " container_width = " << width_i
        << *this);
    }
}

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
        LOG1("*****cluster_phv_container.cpp:sanity_FAIL*****.."
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
    if (ranges_i[lo] && ranges_i[lo] != hi) {
        LOG1(
            "*****cluster_phv_container.cpp:sanity_FAIL*****.."
            << msg_1
            << std::endl
            << "container ranges "
            << '['
            << lo
            << ".."
            << hi
            << ']'
            << ranges_i
            << *this);
    }
    sanity_check_container_ranges(msg_1);
    //
    // check available bits in container
    //
    if (status_i == Container_status::EMPTY && avail_bits_i < hi - lo) {
        LOG1(
            "*****cluster_phv_container.cpp:sanity_FAIL*****.."
            << msg_1
            << " container avail bits inconsistent "
            << lo
            << ".."
            << hi
            << " vs "
            << avail_bits_i);
    }
    if (status_i == Container_status::FULL && avail_bits_i > 0) {
        LOG1(
            "*****cluster_phv_container.cpp:sanity_FAIL*****.."
            << msg_1
            << " container avail bits should be 0 "
            << lo
            << ".."
            << hi
            << " vs "
            << avail_bits_i);
    }
    //
    // check bits in range lo .. hi
    //
    for (auto i = lo; i <= hi; i++) {
        if (status_i == Container_status::EMPTY && bits_i[i] != '0') {
            LOG1(
                "*****cluster_phv_container.cpp:sanity_FAIL*****.."
                << msg_1
                << " container bits should be '0' "
                << i
                << ": "
                << lo
                << ".."
                << hi
                << " vs "
                << *this);
        } else {
            if (status_i == Container_status::FULL && bits_i[i] == '0') {
                LOG1(
                    "*****cluster_phv_container.cpp:sanity_FAIL*****.."
                    << msg_1
                    << " container bits should be tainted non-0 "
                    << i
                    << ": "
                    << lo
                    << ".."
                    << hi
                    << " vs "
                    << *this);
            }
        }
    }
}  // sanity_check_container_avail

void PHV_Container::sanity_check_container_ranges(const std::string& msg) {
    //
    const std::string msg_1 = msg + "..PHV_Container::sanity_check_container_ranges";
    //
    clean_ranges();
    bool warning = false;
    for (auto r : ranges_i) {
        if (r.second < r.first) {
            warning = true;
            LOG1(
                "*****cluster_phv_container.cpp:sanity_FAIL*****.."
                << msg_1
                << " range absurdity ["
                << r.first
                << "]="
                << r.second);
        }
    }
    if (warning) {
        LOG1(this->ranges());
        LOG1(*this);
    }
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
        out << std::endl << "\t\t\t\t";
        out << "  "
            << cc->taint_color()
            << "= "
            << cc->field()
            << " |"
            << cc->container()
            << " <"
            << cc->width()
            << ':'
            << cc->lo()
            << ".."
            << cc->hi()
            << '>'
            << '|';
    } else {
        out << "-cc-";
    }
    return out;
}


std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container::Container_Content *>& vc) {
    for (auto &cc : vc) {
        out << cc << std::endl;
    }
    return out;
}

// ordered_set
std::ostream &operator<<(std::ostream &out, ordered_set<PHV_Container::Container_Content *>& vc) {
    for (auto &cc : vc) {
        out << cc << std::endl;
    }
    return out;
}

//
// phv_container output
//

std::ostream &operator<<(std::ostream &out, ordered_map<int, int>& ranges) {
    out << ".....container ranges....." << std::endl;
    for (auto i : ranges) {
        out << '[' << i.first << "] -- " << i.second << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV_Container *c) {
    if (c) {
        PHV_Container *c1 = const_cast<PHV_Container *>(c);
        out << "PHV-" << c1->phv_number()
            << '.' << c1->asm_string();
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
        out << "PHV-" << c->phv_number()
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

    // only print overlay bits if used.
    if (c.avail_o_bits() != c.width()) {
        out << "\t... OPHV ...\t" << c.o_bits()
            << c.o_fields_in_container();
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container *> &phv_containers) {
    for (auto c : phv_containers) {
        out << *c;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<PHV_Container *> &phv_containers) {
    for (auto c : phv_containers) {
        out << c;
    }
    return out;
}

