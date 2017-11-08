#include "bf-p4c/phv/phv_fields.h"
#include <boost/optional.hpp>
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv_analysis_api.h"
#include "bf-p4c/phv/phv_assignment_api.h"
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/stringref.h"

//
//***********************************************************************************
//
// PhvInfo member functions
//
//***********************************************************************************
//

void PhvInfo::clear() {
    all_fields.clear();
    by_id.clear();
    all_structs.clear();
    simple_headers.clear();
    alloc_done_ = false;
    pov_alloc_done = false;
}

void PhvInfo::add(cstring name, gress_t gress, int size, int offset, bool meta, bool pov) {
    LOG3("PhvInfo adding " << (meta ? "metadata" : "header") << " field " << name <<
         " size " << size);
    assert(all_fields.count(name) == 0);
    auto *info = &all_fields[name];
    info->name = name;
    info->id = by_id.size();
    info->gress = gress;
    info->size = size;
    info->phv_use_hi_i = size - 1;  // default phv_use_hi, modifiable by cluster::set_field_range()
    info->offset = offset;
    info->metadata = meta;
    info->pov = pov;
    by_id.push_back(info);
    //
    // create extended objects for phv_analysis_api, phv_assignment_api
    //
    info->phv_analysis_api(new PHV_Analysis_API(info));
    info->phv_assignment_api(new PHV_Assignment_API(info));
}

void PhvInfo::add_hdr(cstring name, const IR::Type_StructLike *type, gress_t gress, bool meta) {
    if (!type) {
        LOG2("PhvInfo no type for " << name);
        return; }
    LOG2("PhvInfo adding " << (meta ? "metadata" : "header") << " " << name);
    BUG_CHECK(all_structs.count(name) == 0, "phv_fields.cpp:add_hdr(): all_structs inconsistent");
    int start = by_id.size();
    int offset = 0;
    for (auto f : type->fields)
        offset += f->type->width_bits();
    for (auto f : type->fields) {
        int size = f->type->width_bits();
        add(name + '.' + f->name, gress, size, offset -= size, meta, false); }
    int end = by_id.size();
    all_structs.emplace(name, StructInfo(meta, gress, start, end - start));
}

void PhvInfo::addTempVar(const IR::TempVar *tv, gress_t gress) {
    BUG_CHECK(tv->type->is<IR::Type::Bits>() || tv->type->is<IR::Type::Boolean>(),
              "Can't create temp of type %s", tv->type);
    if (all_fields.count(tv->name) == 0)
        add(tv->name, gress, tv->type->width_bits(), 0, true, tv->POV);
}

const PhvInfo::StructInfo PhvInfo::struct_info(cstring name_) const {
    StringRef name = name_;
    if (all_structs.find(name) != all_structs.end())
        return all_structs.at(name);
    if (auto *p = name.findstr("::")) {
        name = name.after(p+2); }
    if (all_structs.find(name) != all_structs.end())
        return all_structs.at(name);
    BUG("No PhvInfo::header for header named '%s'", name_);
}

//
//***********************************************************************************
//
// PhvInfo::field functions to extract field
// retrieve field from IR expression, IR member
//
//***********************************************************************************
//

const PHV::Field *PhvInfo::field(const IR::Expression *e, le_bitrange *bits) const {
    BUG_CHECK(!e->is<IR::BFN::ContainerRef>(),
        "Looking for PHV::Fields but found an IR::BFN::ContainerRef: %1%", e);
    if (!e) return nullptr;
    if (auto *fr = e->to<IR::Member>())
        return field(fr, bits);
    if (auto *cast = e->to<IR::Cast>())
        return field(cast->expr, bits);
    if (auto *sl = e->to<IR::Slice>()) {
        auto *rv = field(sl->e0, bits);
        if (rv && bits) {
            bits->lo += sl->getL();
            int width = sl->getH() - sl->getL() + 1;
            if (bits->hi >= bits->lo + width - 1)
                bits->hi = bits->lo + width - 1;
            if (bits->hi < bits->lo) {
                warning("slice %d..%d invalid for field %s of size %d", sl->getL(), sl->getH(),
                        sl->e0, bits->hi);
                return 0; } }
        return rv; }
    if (auto *tv = e->to<IR::TempVar>()) {
        if (auto *rv = getref(all_fields, tv->name)) {
            if (bits) {
                bits->lo = 0;
                bits->hi = rv->size - 1; }
            return rv;
        } else {
            BUG("TempVar %s not in PhvInfo", tv->name); } }
    return 0;
}

const PHV::Field *PhvInfo::field(const IR::Member *fr, le_bitrange *bits) const {
    StringRef name = fr->toString();
    if (bits) {
        bits->lo = 0;
        bits->hi = fr->type->width_bits() - 1; }
    if (auto *p = name.find('[')) {
        if (name.after(p).find(':'))
            name = name.before(p); }
    if (auto *rv = getref(all_fields, name))
        return rv;
    if (auto *p = name.findstr("::")) {
        name = name.after(p+2);
        if (auto *rv = getref(all_fields, name))
            return rv; }

    // XXX(seth): The warning spew from POV bits prior to allocatePOV() being
    // called is just too great. We need to improve how that's handled, but for
    // now, silence those warnings.
    if (!name.toString().endsWith(".$valid"))
        warning("can't find field '%s'", name);

    return nullptr;
}

//
//***********************************************************************************
//
// PhvInfo::allocatePOV
// simple header pov & header stack pov ccgfs
//
//***********************************************************************************
//

void PhvInfo::allocatePOV(const BFN::HeaderStackInfo& stacks) {
    if (pov_alloc_done) BUG("trying to reallocate POV");
    pov_alloc_done = true;

    int size[2] = { 0, 0 };
    int stacks_num = 0;
    for (auto &stack : stacks) {
        StructInfo info = struct_info(stack.name);
        BUG_CHECK(!info.metadata, "metadata stack?");
        size[info.gress] += stack.size + stack.maxpush + stack.maxpop;
        stacks_num++;
        /* FIXME all bits for a stack must end up in one container */ }
    for (auto &hdr : simple_headers) {
        auto hdr_info = hdr.second;
            ++size[hdr_info.gress]; }
    for (auto &field : *this)
        if (field.pov && field.metadata)
            size[field.gress] += field.size;
    for (auto gress : { INGRESS, EGRESS }) {
        if (size[gress] == 0) continue;
        for (auto &field : *this)
            if (field.pov && field.metadata && field.gress == gress) {
                size[gress] -= field.size;
                field.offset = size[gress]; }
        PHV::Field *hdr_dd_valid = 0;  // header.$valid
        safe_vector<PHV::Field *> pov_fields_h;  // accumulate member povs of simple headers
        for (auto hdr : simple_headers) {
            auto hdr_info = hdr.second;
            if (hdr_info.gress == gress) {
                add(hdr.first + ".$valid", gress, 1, --size[gress], false, true);
                hdr_dd_valid = &all_fields[hdr.first + ".$valid"];
                pov_fields_h.push_back(hdr_dd_valid); } }

        // Accumulate member povs of simple headers into the same ccgf.
        //
        // e.g.,
        // ingress::udp.$valid[1]{0..4}-r- --> ingress::udp.$valid
        // [      ingress::ethernet.$valid[1]
        //        ingress::ig_intr_md_for_tm.$valid[1]
        //        ingress::ipv4.$valid[1]
        //        ingress::tcp.$valid[1]
        //        ingress::udp.$valid[1]
        // :5]
        //
        //  Use hdr_dd_valid (the last $valid field created in the loop above)
        //  as the owner.

        // TODO: Why only do this when no stacks are present?
        if (!stacks_num && pov_fields_h.size() > 1) {
            for (auto* f : pov_fields_h) {
                hdr_dd_valid->ccgf_fields().push_back(f);
                f->set_ccgf(hdr_dd_valid);
                BUG_CHECK(f->validContainerRange() == nw_bitrange(ZeroToMax()),
                    "POV bit with absolute container offset");
            }
            hdr_dd_valid->set_phv_use_hi(pov_fields_h.size());
                                     // allocate container for ccgf width
            hdr_dd_valid->set_simple_header_pov_ccgf(true);
            pov_fields_h.clear();
        }
        for (auto &stack : stacks) {
            safe_vector<PHV::Field *> pov_fields;  // accumulate member povs of header stk pov
            // TODO: Why just push hdr_dd_valid?  Why not all of pov_fields_h?
            if (hdr_dd_valid) {
                pov_fields.push_back(hdr_dd_valid);
            }
            bool push_exists = false;
            StructInfo info = struct_info(stack.name);
            if (info.gress == gress) {
                if (stack.maxpush) {
                    size[gress] -= stack.maxpush;
                    add(stack.name + ".$push", gress, stack.maxpush, size[gress], true, true);
                    pov_fields.push_back(&all_fields[stack.name + ".$push"]);
                    push_exists = true;
                }
                char buffer[16];
                for (int i = 0; i < stack.size; ++i) {
                    snprintf(buffer, sizeof(buffer), "[%d]", i);
                    add(stack.name + buffer + ".$valid", gress, 1, --size[gress], false, true);
                    pov_fields.push_back(&all_fields[stack.name + buffer + ".$valid"]);
                }
                if (stack.maxpop) {
                    size[gress] -= stack.maxpop;
                    // TODO FIXME should this be stack.maxpop?
                    add(stack.name + ".$pop", gress, stack.maxpush, size[gress], true, true);
                }
                add(stack.name + ".$stkvalid", gress, stack.size + stack.maxpush + stack.maxpop,
                    size[gress], true, true);
                // do not push ".$stkvalid" as a member
                // members are slices of owner ".stkvalid"'s allocation span
                // TODO FIXME: why only push_exists?  What about the $valid and $pop fields?
                if (push_exists) {
                    PHV::Field *pov_stk = &all_fields[stack.name + ".$stkvalid"];
                    for (auto &f : pov_fields) {
                        pov_stk->ccgf_fields().push_back(f);
                        f->set_ccgf(pov_stk);
                        BUG_CHECK(f->validContainerRange() == nw_bitrange(ZeroToMax()),
                            "POV bit with absolute container offset");
                    }
                    pov_stk->set_ccgf(pov_stk);
                    pov_stk->set_header_stack_pov_ccgf(true);
                }
            }
        }
        assert(size[gress] == 0);
    }
}  // allocatePOV

//
//***********************************************************************************
//
// PhvInfo::container_to_fields related functions
//
//***********************************************************************************
//
void PhvInfo::add_container_to_field_entry(const PHV::Container c,
                                           const PHV::Field *f) {
    if (f == nullptr) return;
    container_to_fields[c].insert(f);
}

const ordered_set<const PHV::Field *>&
PhvInfo::fields_in_container(const PHV::Container c) const {
    static const ordered_set<const PHV::Field *> empty_list;
    if (container_to_fields.count(c))
        return container_to_fields.at(c);
    return empty_list;
}

// XXX(deep): Currently, this analysis is conservative, in the sense that this does not take
// overlaying into account
bool PhvInfo::is_only_field_in_container(const PHV::Container c,
                                         const PHV::Field *f) const {
    if (f == nullptr) return false;
    auto& fields = fields_in_container(c);
    return (fields.size() == 1 && fields.count(f));
}

bitvec PhvInfo::bits_allocated(const PHV::Container c) const {
    bitvec ret_bitvec;
    auto& fields = fields_in_container(c);
    if (fields.size() == 0)
        return ret_bitvec;
    for (auto* field : fields) {
        field->foreach_alloc([&](const PHV::Field::alloc_slice &alloc) {
            if (alloc.container != c) return;
            le_bitrange bits = alloc.container_bits();
            ret_bitvec.setrange(bits.lo, bits.size());
        }); }
    return ret_bitvec;
}

//
//***********************************************************************************
//
// PHV::Field le_bitrange interface related member functions
//
//***********************************************************************************
//

// figure out how many disinct container bytes contain info from a le_bitrange of a particular field
//
int PHV::Field::container_bytes(le_bitrange bits) const {
    if (bits.hi < 0) bits.hi = size - 1;
    if (alloc_i.empty())
        return bits.hi/8U + bits.lo/8U + 1;
    int rv = 0, w;
    for (int bit = bits.lo; bit <= bits.hi; bit += w) {
        auto &sl = for_bit(bit);
        w = sl.width - (bit - sl.field_bit);
        if (bit + w > bits.hi)
            w = bits.hi - bit + 1;
        int cbit = bit + sl.container_bit - sl.field_bit;
        rv += (cbit+w-1)/8U - cbit/8U + 1; }
    return rv;
}

//
//***********************************************************************************
//
// PHV::Field Cluster Phv_Bind / alloc_i interface related member functions
//
//***********************************************************************************
//

safe_vector<PHV::Field::alloc_slice> *
PhvInfo::alloc(const IR::Member *member) {
    PHV::Field *info = field(member);
    BUG_CHECK(nullptr != info, "; Cannot find PHV allocation for %s", member->toString());
    return &info->alloc_i;
}

const PHV::Field::alloc_slice &PHV::Field::for_bit(int bit) const {
    for (auto &sl : alloc_i)
        if (bit >= sl.field_bit && bit < sl.field_bit + sl.width)
            return sl;
    ERROR("No allocation for bit " << bit << " in " << name);
    static alloc_slice invalid(nullptr, PHV::Container(), 0, 0, 0);
    return invalid;
}

void PHV::Field::foreach_byte(int lo, int hi,
                                  std::function<void(const alloc_slice &)> fn) const {
    alloc_slice tmp(this, PHV::Container(), lo, lo, 8 - (lo&7));
    if (alloc_i.empty()) {
        while (lo <= hi) {
            if (lo/8U == hi/8U)
                tmp.width = hi - lo + 1;
            fn(tmp);
            tmp.field_bit = tmp.container_bit = lo = (lo|7) + 1;
            tmp.width = 8; }
        return; }
    auto it = alloc_i.rbegin();
    while (it != alloc_i.rend() && (it->container.is(PHV::Kind::tagalong) ||
           it->field_hi() < lo)) ++it;
    while (it != alloc_i.rend() && it->field_bit <= hi) {
        if (it->container.is(PHV::Kind::tagalong)) continue;
        unsigned clo = it->container_bit, chi = it->container_hi();
        if (lo > it->field_bit)
            clo += lo - it->field_bit;
        if (hi < it->field_hi())
            chi -= it->field_hi() - hi;
        BUG_CHECK(chi >= clo, "Impossible foreach_byte container slice");
        for (unsigned cbyte = clo/8U; cbyte <= chi/8U; ++cbyte) {
            int byte_lo = std::max(cbyte*8, clo);
            int byte_hi = std::min(cbyte*8+7, chi);
            if (it->container != tmp.container || cbyte != tmp.container_bit/8U) {
                if (tmp.container) fn(tmp);
                tmp = *it;
                if (byte_lo > it->container_bit) {
                    tmp.container_bit = byte_lo;
                    tmp.field_bit += byte_lo - it->container_bit;
                    tmp.width -= byte_lo - it->container_bit; }
                if (byte_hi < it->container_hi())
                    tmp.width -= it->container_hi() - byte_hi;
            } else {
                if (byte_hi < tmp.container_hi()) {
                    LOG1("********** phv_fields.cpp:sanity_FAIL **********"
                        << ".....byte_hi <= container_hi....."
                        << " byte_hi = " << byte_hi
                        << " tmp.container_hi = " << tmp.container_hi()
                        << " field_bit = " << it->field_bit
                        << " container_bit = " << it->container_bit
                        << " width = " << it->width
                        << " lo = " << lo
                        << " tmp.container_bit = " << tmp.container_bit
                        << std::endl
                        << " field = " << this
                        << " container = " << it->container);
                    BUG("phv_fields.cpp:foreach_byte(): byte_hi < container_hi");
                }
                if (byte_hi > tmp.container_hi())
                    tmp.width += byte_hi - tmp.container_hi();
                assert(tmp.width <= 8); } }
        ++it; }
    if (tmp.container) fn(tmp);
}  // foreach byte

void PHV::Field::foreach_alloc(
    int lo,
    int hi,
    std::function<void(const alloc_slice &)> fn) const {
    alloc_slice tmp(this, PHV::Container(), lo, lo, hi-lo+1);

    // Find first slice that includes @lo, and process it.
    auto it = alloc_i.rbegin();
    while (it != alloc_i.rend() && it->field_hi() < lo) ++it;
    if (it != alloc_i.rend() && it->field_bit != lo) {
        if (it->field_bit >= lo) {
            LOG1("********** phv_fields.cpp:sanity_FAIL **********"
                << ".....field_bit in alloc_slice not less than lo....."
                << " field_bit = " << it->field_bit
                << " container_bit = " << it->container_bit
                << " width = " << it->width
                << " lo = " << lo
                << std::endl
                << " field = " << this
                << " container = " << it->container);
            BUG("phv_fields.cpp:foreach_alloc(): field_bit in alloc_slice not less than lo");
        }
        tmp = *it;
        tmp.container_bit += abs(it->field_bit - lo);
        if (tmp.container_bit < 0) {
            LOG1("********** phv_fields.cpp:sanity_FAIL **********"
                << ".....container_bit negative in alloc_slice....."
                << " field_bit = " << it->field_bit
                << " container_bit = " << it->container_bit
                << " width = " << it->width
                << " lo = " << lo
                << " tmp.container_bit = " << tmp.container_bit
                << std::endl
                << " field = " << this
                << " container = " << it->container);
            BUG("phv_fields.cpp:foreach_alloc(): container_bit negative in alloc_slice");
        }
        tmp.field_bit = lo;
        if (it->field_hi() > hi)
            tmp.width = hi - lo + 1;
        else
            tmp.width -= abs(it->field_bit - lo);
        fn(tmp);
        ++it; }

    // Process remaining slices until reaching the first slice that does not
    // include any bits less than @hi.
    while (it != alloc_i.rend() && it->field_bit <= hi) {
        if (it->field_hi() > hi) {
            tmp = *it;
            tmp.width = hi - it->field_bit + 1;
            fn(tmp);
        } else {
            fn(*it); }
        ++it; }
}

//
//***********************************************************************************
//
// PHV::Field Cluster based Phv Allocation related member functions
//
//***********************************************************************************
//

//
// cluster ids
//
void
PHV::Field::cl_id(std::string cl_p) const {
    // can only change id of original non-sliced cluster
    if (!sliced() && field_slices_i.size()) {
        Cluster_PHV *cl = field_slices_i.begin()->first;
        cl->id(cl_p);
    }
}

std::string
PHV::Field::cl_id(Cluster_PHV * cl) const {
    // the first cl in list is the non-sliced owner cl
    if (!cl && field_slices_i.size()) {
        Cluster_PHV *cl = field_slices_i.begin()->first;
        return cl->id();
    }
    // cluster cl among field_slices
    if (field_slices_i.count(cl)) {
        return cl->id();
    }
    return "??";
}

int
PHV::Field::cl_id_num(Cluster_PHV *cl) const {
    // the first cl in list is the non-sliced owner cl
    if (!cl && field_slices_i.size()) {
        Cluster_PHV *cl = field_slices_i.begin()->first;
        return cl->id_num();
    }
    // cluster cl among field_slices
    if (field_slices_i.count(cl)) {
        return cl->id_num();
    }
    return -1;
}

//
// constraints, phv_widths
//
bool
PHV::Field::constrained(bool packing_constraint) const {
    bool pack_c = mau_phv_no_pack_i || deparsed_no_pack_i;
    if (packing_constraint) {
        return pack_c;
    }
    return  pack_c || deparsed_bottom_bits_i;
}

bool
PHV::Field::is_ccgf() const {
    if (ccgf_i == this || header_stack_pov_ccgf_i || simple_header_pov_ccgf_i) {
        BUG_CHECK(ccgf_fields_i.size(), "ccgf fields empty");
        return true;
    }
    return false;
}

bool
PHV::Field::allocation_complete() const {
    //
    // after phv container allocation, ccgf fields are removed by update_ccgf()
    //
    return ccgf_fields_i.size() == 0;
}

int
PHV::Field::phv_use_width(Cluster_PHV *cl) const {
    // non-sliced owner not in map
    if (cl && field_slices_i.count(cl)) {
        return phv_use_hi(cl) - phv_use_lo(cl) + 1;
    }
    return phv_use_hi_i - phv_use_lo_i + 1;
}

boost::optional<int>
PHV::Field::phv_alignment(bool get_ccgf_alignment) const {
    // the parameter get_ccgf_alignment distinguishes between requesting alignment
    // of the CCGF as a whole vs the alignment of a ccgf member field
    if (alignment) {
        if (get_ccgf_alignment && is_ccgf()) {
            // return alignment of last field of ccgf as [m1,m2,m3] placed m3.m2.m1 in phv[0..w]
            return ccgf_fields_i.back()->phv_alignment();
        }
        return alignment->littleEndian;
    }
    return boost::none;
}

boost::optional<int> PHV::Field::phv_alignment_network() const {
    if (alignment)
        return alignment->network;
    return boost::none;
}

void
PHV::Field::set_ccgf_phv_use_width(int min_ceil) {
    // compute ccgf width, need PHV container(s) of this width
    int ccg_width = 0;
    for (auto &f : ccgf_fields_i) {
        // ccgf owner appears as member, phv_use_width = aggregate size of members
        if (f->is_ccgf()) {
            if (PHV_Container::constraint_no_cohabit(f)) {
                ccg_width += PHV_Container::ceil_phv_use_width(f, min_ceil);
            } else {
                ccg_width += f->size;
            }
        } else {
            if (PHV_Container::constraint_no_cohabit(f)) {
                ccg_width += PHV_Container::ceil_phv_use_width(f, min_ceil);
            } else {
                ccg_width += f->phv_use_width();
            }
        }
    }  // for
    if (header_stack_pov_ccgf_i) {
        // e.g.,
        // ingress::data.$stkvalid, egress::mpls.$stkvalid, ingress::extra.$stkvalid
        // width requirement temporarily incremented
        // so that "header stack" owner gets allocated in members' container pointing to tos
        // note: size remains untouched
        //
        ccg_width++;
    }
    phv_use_hi_i = ccg_width - 1;
}  // set_ccgf_phv_use_width()

int
PHV::Field::ccgf_width() const {
    int ccgf_width_l = 0;
    for (auto &f : ccgf_fields_i) {
        if (f->is_ccgf() && !f->header_stack_pov_ccgf()) {
            // ccgf owner appears as member, phv_use_width = aggregate size of members
            ccgf_width_l += f->size;
        } else {
            if (f->id == id) {
                // originally f was ccgf owner but after container assignment
                // ownership got terminated although f remains ccgf member of itself
                ccgf_width_l += f->size;
            } else {
                ccgf_width_l += f->phv_use_width();
            }
        }
    }
    return ccgf_width_l;
}

//
// field slices
//

bool
PHV::Field::sliced() const {
    if (field_slices_i.size() > 1) {
        return true;
    }
    return false;
}

std::pair<int, int>&
PHV::Field::field_slices(Cluster_PHV *cl) {
    assert(cl);
    assert(field_slices_i.count(cl));
    return field_slices_i[cl];
}

const std::pair<int, int>&
PHV::Field::field_slices(const Cluster_PHV *cl) const {
    assert(cl);

    // This const_cast is necessary to look up `cl` in `field_slices_i`.  By
    // using `at()`, we guarantee that `cl` is not *inserted* into
    // `field_slices_i`, and hence cannot be modified, despite the cast.
    assert(field_slices_i.count(const_cast<Cluster_PHV*>(cl)));
    return field_slices_i.at(const_cast<Cluster_PHV*>(cl));
}

void
PHV::Field::set_field_slices(Cluster_PHV *cl, int lo, int hi, Cluster_PHV *parent_cl) {
    assert(cl);
    assert(lo >= 0);
    assert(hi >= lo);
    if (!cl->sliced()) {
        // in cases of cluster id renaming, clear previous incarnation
        assert(!parent_cl);
        field_slices_i.clear();
    }
    field_slices_i.emplace(cl, std::make_pair(lo, hi));
    // cluster map entry for ccgf members
    for (auto &m : ccgf_fields_i) {
        if (m != this) {
            m->field_slices().clear();
            m->set_field_slices(cl, m->phv_use_lo(), m->phv_use_hi());
        }
    }
    if (parent_cl) {
        // remove parent from map
        field_slices_i.erase(parent_cl);
    }
}

int
PHV::Field::phv_use_lo(Cluster_PHV *cl) const {
    if (cl && field_slices_i.size() && field_slices_i.count(cl)) {
        return field_slices(cl).first;
    }
    return phv_use_lo_i;
}

int
PHV::Field::phv_use_hi(Cluster_PHV *cl) const {
    if (cl && field_slices_i.size() && field_slices_i.count(cl)) {
        return field_slices(cl).second;
    }
    return phv_use_hi_i;
}

//
// field overlays
//

void
PHV::Field::phv_containers(PHV_Container *c) {
    assert(c);
    // actual phv container associated with field
    // field can have several phv containers, e.g, 24bF = 3*8bC
    phv_containers_i.insert(c);
    // owner ccgf records container allocation of members
    // used during ccgf overlay on ccgf substratum
    if (ccgf_i && !is_ccgf()) {
        ccgf_i->phv_containers().insert(c);
    }
    if (field_overlay_map_i.size()) {
        //
        // field overlays exist, update field overlay map key with actual container number
        // remove virtual container entry from ordered map
        // add actual phv-container entry
        // alternate solution would be to key as std::pair<int virtual, PHV_Container*>
        //
        int container_number = field_overlay_map_i.begin()->first;
        ordered_set<Field *> *set_of_f = field_overlay_map_i.begin()->second;
        if (container_number < 0) {
            // remove virtual container entry
            field_overlay_map_i.erase(container_number);
        }
        if (set_of_f && set_of_f->size()) {
            // insert phv container entry
            field_overlay_map_i[c->container_id()] = set_of_f;
        }
    }
    // sanity check this field's field_overlay_map
    for (auto overlaid_by_field : field_overlay_map_i) {
        for (auto* f_overlay : *overlaid_by_field.second) {
            // field is never overlaid atop itself
            // ensure this field is not present in field_overlay_map
            BUG_CHECK(f_overlay != this,
                      "field's %1% field_overlay_map contains itself",
                      cstring::to_cstring(f_overlay));
            // ccgf member can never be overlaid atop owner
            // ensure this field's ccgf members are not in field's field_overlay_map
            BUG_CHECK(f_overlay->ccgf() != this,
                      "ccgf owner's %1% field_overlay_map contains ccgf member %2%",
                      cstring::to_cstring(this), cstring::to_cstring(f_overlay));
            // ccgf owner can never be overlaid atop its member
            // ensure member's ccgf owner not in member's field_overlay_map
            BUG_CHECK(this->ccgf() != f_overlay,
                      "ccgf member's %1% field_overlay_map contains ccgf owner %2%",
                      cstring::to_cstring(this), cstring::to_cstring(f_overlay));
        }
    }
}

void
PHV::Field::overlay_substratum(Field *f) {
    assert(f);
    overlay_substratum_i = f;
}

void
PHV::Field::field_overlay_map(Field *field, int r, bool actual_register) {
    assert(field);
    //
    // r, as virtual container, made -ve when map entry created (by phv_interference)
    // after phv container association w/ field, virtual entry replaced by actual container
    // r becomes actual phv container number and used when associating overlayed fields
    // see PHV::Field::phv_containers(PHV_Container *c) above
    // -ve virtual containers will never clash with actual phv containers {0,+ve}
    //
    if (!actual_register) {
        assert(r > 0);
        r = -r;
    }
    if (!field_overlay_map_i[r]) {
        field_overlay_map_i[r] = new ordered_set<Field *>;
    }
    field_overlay_map_i[r]->insert(field);
    //
    // overlayed field points to substratum
    //
    field->overlay_substratum(this);
    for (auto &m : field->ccgf_fields()) {
        m->overlay_substratum(this);
    }
}


ordered_set<PHV::Field *> *
PHV::Field::field_overlay_map(int r) {
    if (!field_overlay_map_i.size() || !field_overlay_map_i.count(r)) {
        return 0;
    }
    return field_overlay_map_i[r];
}

void
PHV::Field::field_overlays(std::list<Field *>& fields_list) {
    // fields_list accumulates all overlay fields of this field, including this field
    fields_list.clear();
    fields_list.push_back(this);
    if (field_overlay_map_i.size()) {
        for (auto *f_set : Values(field_overlay_map_i)) {
            fields_list.insert(fields_list.end(), f_set->begin(), f_set->end());
        }
    }
}

void
PHV::Field::field_overlay(Field *overlay, int phv_number) {
    // add overlay to substratum's owner field map of overlays
    // to make phv_interference->mutually_exclusive() computation updated & accurate
    assert(overlay);
    overlay->overlay_substratum(overlay_substratum_i? overlay_substratum_i: this);
    overlay->overlay_substratum()->field_overlay_map(overlay, phv_number);
}

bool PHV::Field::is_overlay(const Field *field) const {
    // return true if field and this are overlays
    if (!field) {
        return false;
    }
    if (overlay_substratum_i == field->overlay_substratum()) {
        return true;
    }
    for (auto &entry : field->field_overlay_map()) {
        if (entry.second) {
            for (Field *f : *(entry.second)) {
                if (f->id == id) {
                    return true;
                }
                for (Field *m : f->ccgf_fields()) {
                    if (m->is_overlay(this)) {
                        return true;
                    }
                }  // for
            }  // for
        }
    }
    for (auto &entry : field_overlay_map_i) {
        if (entry.second) {
            for (auto &f : *(entry.second)) {
                if (f->id == field->id) {
                    return true;
                }
                if (f->ccgf_fields().size()) {
                    for (auto &m : f->ccgf_fields()) {
                        if (m->is_overlay(field)) {
                            return true;
                        }
                    }  // for
                }
            }  // for
        }
    }
    return false;
}

void PHV::Field::updateAlignment(const FieldAlignment& newAlignment) {
    LOG2("Inferred alignment " << newAlignment << " for field " << name);

    // If there's no existing alignment for this field, just take this one.
    if (!alignment) {
        alignment = newAlignment;
        return;
    }

    // If there is an existing alignment, it must agree with this new one.
    // Otherwise the program is inconsistent and we can't compile it.
    // XXX(seth): We actually could, in theory, handle such a situation by
    // creating two different versions of the field with different alignments
    // and copying between them as needed in the MAU. Not cheap, though.
    ERROR_CHECK(*alignment == newAlignment,
                "Inferred incompatible alignments for field %1%: %2% != %3%",
                name, cstring::to_cstring(newAlignment),
                cstring::to_cstring(*alignment));
}

void PHV::Field::updateValidContainerRange(nw_bitrange newValidRange) {
    LOG2("Inferred valid container range " << newValidRange <<
         " for field " << name);

    const auto intersection = validContainerRange_i.intersectWith(newValidRange);
    if (intersection.empty() || intersection.size() < size) {
        ::error("Inferred valid container ranges %1% and %2% for field %3% "
                "which cannot both be satisfied for a field of size %4%b",
                cstring::to_cstring(validContainerRange_i),
                cstring::to_cstring(newValidRange), name, size);
        return;
    }

    validContainerRange_i = *toClosedRange(intersection);
}


//***********************************************************************************
//
// CollectPhvInfo implementation.
//
//***********************************************************************************

/**
 * Populates a PhvInfo object with Fields for each PHV-backed object in the
 * program (header instances, TempVars, etc.).
 *
 * Some Field metadata can't be collected in a single pass; that information is
 * collected by other CollectPhvInfo passes.
 *
 * XXX(seth): There's some other stuff mixed in here for historical reasons, but
 * we should think about whether it belongs in separate passes.
 */
struct CollectPhvFields : public Inspector, public TofinoWriteContext {
    explicit CollectPhvFields(PhvInfo& phv) : phv(phv) { }

 private:
    Visitor::profile_t init_apply(const IR::Node* root) override {
        auto rv = Inspector::init_apply(root);
        phv.clear();
        return rv;
    }

    bool preorder(const IR::Header* h) override {
        auto gress = VisitingThread(this);
        int start = phv.by_id.size();
        phv.add_hdr(h->name, h->type, gress, false);
        int end = phv.by_id.size();
        phv.simple_headers.emplace(h->name,
                                   PhvInfo::StructInfo(false, gress, start, end - start));
        return false;
    }

    bool preorder(const IR::HeaderStack* h) override {
        if (!h->type) return false;
        auto gress = VisitingThread(this);
        char buffer[16];
        int start = phv.by_id.size();
        for (int i = 0; i < h->size; i++) {
            snprintf(buffer, sizeof(buffer), "[%d]", i);
            phv.add_hdr(h->name + buffer, h->type, gress, false); }
        int end = phv.by_id.size();
        phv.all_structs.emplace(h->name, PhvInfo::StructInfo(false, gress, start, end - start));
        return false;
    }

    bool preorder(const IR::Metadata* h) override {
        auto gress = VisitingThread(this);
        phv.add_hdr(h->name, h->type, gress, true);
        return false;
    }

    bool preorder(const IR::TempVar* tv) override {
        auto gress = VisitingThread(this);
        phv.addTempVar(tv, gress);
        return false;
    }

    void postorder(const IR::BFN::Deparser* d) override {
        // extract deparser constraints from Deparser & Digest IR nodes ref: bf-p4c/ir/parde.def
        // set deparser constaints on field
        for (auto* param : d->params) {
            PHV::Field* f = phv.field(param->source->field);
            BUG_CHECK(f != nullptr, "Field not created in PhvInfo");

            // On Tofino, we need to be careful with fields which are used to
            // set intrinsic deparser parameters. This is because the hidden
            // validity bit for the container the field is placed in will
            // control whether the parameter is actually "set" or the value is
            // just ignored. Since we don't explicitly track those container
            // validity bits, and any write to a container will mark it valid,
            // we currently can't safely pack other fields into the same
            // container.
            // XXX(seth): JBay does away with this constraint, because it has
            // explicit POV bits for deparser parameters.
            f->set_deparsed_no_pack(true);

            LOG1(".....Deparser Constraint '" << param->name
                  << "' on field..... " << f); }

        // TODO:
        // IR futures: distinguish each digest as an enumeration: learning, mirror, resubmit
        // as they have differing constraints -- bottom-bits, bridge-metadata mirror packing
        // learning, mirror field list in bottom bits of container, e.g.,
        // 301:ingress::$learning<3:0..2>
        // 590:egress::$mirror<3:0..2> specifies 1 of 8 field lists
        // currently, IR::BFN::Digest node has a string field to distinguish them by name
        for (auto &entry : Values(d->digests)) {
            if (entry->name != "learning" && entry->name != "mirror")
                continue;

            PHV::Field* f = phv.field(entry->select);
            BUG_CHECK(f != nullptr, "Field not created in PhvInfo");
            f->set_deparsed_bottom_bits(true);
            LOG1(".....Deparser Constraint "
                << entry->name
                << " 'digest' on field..... "
                << f);

            if (entry->name ==  "learning") {
                for (auto s : entry->sets) {
                    LOG1("\t.....learning field list..... ");
                    for (auto l : *s) {
                        auto l_f = phv.field(l);
                        if (l_f)
                            LOG1("\t\t" << l_f);
                        else
                            LOG1("\t\t" <<"-f?"); } }
                continue; }

            // associating a mirror field with its field list
            // used during constraint checks for bridge-metadata phv allocation
            LOG1(".....mirror fields in field list " << f->id << ":" << f->name);
            int fl = 0;
            for (auto s : entry->sets) {
                LOG1("\t.....field list....." << fl);
                for (auto m : *s) {
                    PHV::Field* mirror = phv.field(m);
                    if (mirror) {
                        mirror->mirror_field_list = {f, fl};
                        LOG1("\t\t" << mirror);
                    } else {
                        LOG1("\t\t" << "-f?"); }
                    fl++; } } }
    }

    void postorder(const IR::Expression* e) override {
        PHV::Field* f = phv.field(e);
        if (f && isWrite()) {
            f->set_mau_write(true);  // note: this can be a parser write only
            LOG4(".....MAU_write....." << f);
        }
    }

    void postorder(const IR::BFN::LoweredParser*) override {
        BUG("Running CollectPhvInfo after the parser IR has been lowered; "
            "this will produce invalid results.");
    }

    PhvInfo& phv;
};

/**
 * Determine which fields are bridged and set a flag in their PHV::Field
 * metadata to indicate that.
 *
 * We consider fields to be bridged if they're written to in the special
 * `$bridged_metadata_extract` state that we generate in AddBridgedMetadata.
 * Using this approach ensures that fields are marked as bridged even if we
 * rebuild the PhvInfo data structure after AddBridgedMetadata has run.
 */
struct MarkBridgedMetadataFields : public Inspector {
    explicit MarkBridgedMetadataFields(PhvInfo& phv) : phv(phv) { }

 private:
    bool preorder(const IR::BFN::ParserState* state) override {
        if (!state->name.endsWith("$bridge_metadata_extract")) return true;

        forAllMatching<IR::BFN::Extract>(&state->statements,
                      [&](const IR::BFN::Extract* extract) {
            auto* fieldInfo = phv.field(extract->dest->field);
            if (!fieldInfo) return;

            // Prior to CreateThreadLocalInstances, a P4 field is represented by
            // the same PHV::Field object in both ingress and egress. After
            // that pass runs, there are two PHV::Field objects. The extract
            // will write to the *egress* version, but the one we actually want
            // to mark as bridged is the *ingress* version.
            if (!fieldInfo->name.startsWith("egress::")) {
                fieldInfo->bridged = true;
                return;
            }

            // XXX(seth): Yuck.
            cstring ingressFieldName = cstring("ingress::")
                                     + fieldInfo->name.substr(strlen("egress::"));
            auto* ingressFieldInfo = phv.field(ingressFieldName);
            BUG_CHECK(ingressFieldInfo != nullptr,
                      "No ingress version of egress bridged metadata field?");
            ingressFieldInfo->bridged = true;
        });

        return true;
    }

    PhvInfo& phv;
};

/// Allocate POV bits for each header instance, metadata instance, or header
/// stack that we visited in CollectPhvFields.
struct AllocatePOVBits : public Inspector {
    explicit AllocatePOVBits(PhvInfo& phv) : phv(phv) { }

 private:
    bool preorder(const IR::BFN::Pipe* pipe) override {
        BUG_CHECK(pipe->headerStackInfo != nullptr,
                  "Running AllocatePOVBits without running "
                  "CollectHeaderStackInfo first?");
        phv.allocatePOV(*pipe->headerStackInfo);
        return false;
    }

    PhvInfo& phv;
};

/// Examine how fields are used in the parser and deparser to compute their
/// alignment requirements.
struct ComputeFieldAlignments : public Inspector {
    explicit ComputeFieldAlignments(PhvInfo& phv) : phv(phv) { }

 private:
    bool preorder(const IR::BFN::Extract* extract) override {
        // Only extracts from the input buffer introduce alignment constraints.
        auto* bufferSource = extract->source->to<IR::BFN::BufferlikeRVal>();
        if (!bufferSource) return false;

        auto* fieldInfo = phv.field(extract->dest->field);
        if (!fieldInfo) {
            ::warning("No allocation for field %1%", extract->dest);
            return false;
        }

        // The alignment required for a parsed field is determined by the
        // position from which it's read from the wire.
        const auto extractedBits = bufferSource->extractedBits();
        const auto alignment = FieldAlignment(extractedBits);
        fieldInfo->updateAlignment(alignment);

        // If a parsed field starts at a container bit index larger than the bit
        // index at which it's located in the input buffer, we won't be able to
        // extract it, because we'd have to read past the beginning of the input
        // buffer. For example (all indices are in network order):
        //
        //   Container: [ 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 ]
        //                                      [       field      ]
        //   Input buffer:                      [ 0  1  2  3  4  5 ]
        //
        // This field begins at position 0 in the input buffer, but because the
        // parser has to write to the entire container, to place the field at
        // position 8 in the container would require that bits [0, 7] of the
        // container came from a negative position in the input buffer.
        //
        // To avoid this, we generate a constraint that prevents PHV allocation
        // from placing the field in a problematic position in the container.
        //
        // In simple terms, what we want to avoid is placing the field too far
        // to the right in the container. For fields which come from the mapped
        // input buffer region (which has a fixed coordinate system that cannot
        // be shifted) or from the end of the headers in the input packet (where
        // we'll end up treating some of the packet payload as header if we
        // introduce an extra shift), a symmetric issue exists where we need to
        // avoid placing the field too far to the *left* in the container. Both
        // of these limitations need to be converted into constraints for PHV
        // allocation.
        // XXX(seth): Unfortunately we can't capture the "too far to the left"
        // case with our current representation of valid container ranges.
        const nw_bitrange validContainerRange = FromTo(0, extractedBits.hi);
        fieldInfo->updateValidContainerRange(validContainerRange);

        // XXX(seth): This is a hack: if this field was bridged from ingress, we
        // apply the same alignment constraint to the ingress version of the
        // field. This ensures that the two allocations are compatible until
        // we're ready to handle bridged metadata more intelligently. (Note that
        // we don't even need to do this before CreateThreadLocalInstances has
        // run, since before that there is just one version of the field; that's
        // why we check for "egress::" below.)
        auto* state = findContext<IR::BFN::ParserState>();
        if (state->name.endsWith("$bridge_metadata_extract") &&
                fieldInfo->name.startsWith("egress::")) {
            cstring ingressFieldName = cstring("ingress::")
                                     + fieldInfo->name.substr(strlen("egress::"));
            auto* ingressFieldInfo = phv.field(ingressFieldName);
            BUG_CHECK(ingressFieldInfo != nullptr,
                      "No ingress version of egress bridged metadata field?");
            ingressFieldInfo->updateAlignment(alignment);
            ingressFieldInfo->updateValidContainerRange(validContainerRange);
        }

        return false;
    }

    bool preorder(const IR::BFN::Deparser* deparser) override {
        unsigned currentBit = 0;

        for (auto* emitPrimitive : deparser->emits) {
            // XXX(seth): Right now we treat EmitChecksum as not inducing any
            // particular alignment, but we will need to revisit that.
            auto* emit = emitPrimitive->to<IR::BFN::Emit>();
            if (!emit) continue;

            auto* fieldInfo = phv.field(emit->source);
            if (!fieldInfo) {
                ::warning("No allocation for field %1%", emit->source);
                currentBit = 0;
                continue;
            }

            // XXX(seth): We don't need to infer any constraints from the
            // deparser for bridged metadata fields; they get their alignment
            // from the hack in `preorder(Extract)`. (We just duplicate the
            // egress alignment constraints, which are inferred from the
            // parser, for the ingress versions of the fields.) For now, we just
            // skip to the next byte-aligned position.
            if (fieldInfo->bridged) {
                currentBit += fieldInfo->size;
                if (currentBit % 8 != 0)
                    currentBit += 8 - currentBit % 8;
                continue;
            }

            // For other deparsed fields, the alignment requirement is induced
            // by the position at which the field will be written on the wire.
            // We can behave as if every field will be deparsed (i.e., all POV
            // bits are set) because any sequential group of deparsed fields
            // with the same POV bits must be byte-aligned in a valid Tofino P4
            // program. (If not, you'd end up with garbage bits on the wire.)
            nw_bitrange emittedBits(currentBit, currentBit + fieldInfo->size - 1);
            fieldInfo->updateAlignment(FieldAlignment(emittedBits));
            currentBit += fieldInfo->size;
        }

        return false;
    }

    PhvInfo& phv;
};

CollectPhvInfo::CollectPhvInfo(PhvInfo& phv) {
    addPasses({
        new CollectPhvFields(phv),
        new AllocatePOVBits(phv),
        new MarkBridgedMetadataFields(phv),
        new ComputeFieldAlignments(phv)
    });
}

//
//
//***********************************************************************************
//
// logging functions
//
//***********************************************************************************
//
void PhvInfo::print_phv_group_occupancy() const {
    if (!LOGGING(2)) return;
    std::set<PHV::Container> containers_used;
    std::map<bitvec, size_t> groups_usage;
    std::map<bitvec, size_t> groups_containers;
    std::map<bitvec, int> groups_to_ids;

    // Extract MAU group specific information from phvSpec
    std::pair<int, int> numBytes = Device::phvSpec().mauGroupNumAndSize(PHV::Type::B);
    std::pair<int, int> numHalfs = Device::phvSpec().mauGroupNumAndSize(PHV::Type::H);
    std::pair<int, int> numWords = Device::phvSpec().mauGroupNumAndSize(PHV::Type::W);

    for (auto *field : by_id) {
        for (auto phv_c : field->phv_containers()) {
            PHV::Container c = Device::phvSpec().idToContainer(phv_c->container_id());
            if (containers_used.count(c)) continue;
            containers_used.insert(c);
            int bitsUsed = static_cast<int>(phv_c->width()) - phv_c->avail_bits();
            if (boost::optional<bitvec> mau_group =
                    Device::phvSpec().mauGroup(phv_c->container_id())) {
                groups_containers[mau_group.get()] += 1;
                groups_usage[mau_group.get()] += bitsUsed;
                // Group numbers go from Words -> Bytes -> Halfwords
                // In Tofino, this is (0-3) -> (4-7) -> (8-13)
                if (c.type() == PHV::Type::B)
                    groups_to_ids[mau_group.get()] = (c.index() / numBytes.second) + numWords.first;
                else if (c.type() == PHV::Type::H)
                    groups_to_ids[mau_group.get()] = (c.index() / numHalfs.second) + (numWords.first
                            + numBytes.first);
                else if (c.type() == PHV::Type::W)
                    groups_to_ids[mau_group.get()] = (c.index() / numWords.second); } } }

    LOG2("\nPHV Groups Allocation State:\n");
    LOG2("-----------------------------------------------------");
    LOG2("|     PHV Group     |   Containers   |   Bits Used  |");
    LOG2("|  (container bits) |      Used      |              |");
    LOG2("-----------------------------------------------------");

    // Print PHV groups
    for (auto container_type : Device::phvSpec().containerTypes()) {
        for (auto mau_group : Device::phvSpec().mauGroups(container_type)) {
            LOG2("|\t\t" << groups_to_ids[mau_group] << " (" << container_type << ")\t\t|\t\t" <<
                    groups_containers[mau_group] << "\t\t|\t\t" << groups_usage[mau_group] <<
                    "\t\t|"); }
        // Ensure that the line appears only for B, H, and W; not for TB, TH, TW
        if (Device::phvSpec().mauGroups(container_type).size() != 0)
            LOG2("-----------------------------------------------------"); }
}
//
//
//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//

std::ostream &PHV::operator<<(std::ostream &out, const PHV::Field::alloc_slice &sl) {
    out << '[' << (sl.field_bit+sl.width-1) << ':' << sl.field_bit << "]->[" << sl.container << ']';
    if (sl.container_bit || size_t(sl.width) != sl.container.size()) {
        out << '(' << sl.container_bit;
        if (sl.width != 1)
            out << ".." << (sl.container_bit + sl.width - 1);
        out << ')'; }
    return out;
}

std::ostream &operator<<(std::ostream &out,
                         const safe_vector<PHV::Field::alloc_slice> &sl_vec) {
    for (auto &sl : sl_vec) {
        out << sl << ';';
    }
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    const ordered_map<Cluster_PHV *, std::pair<int, int>>& field_slices) {
    for (auto &entry : field_slices) {
        out << '|';
        out << entry.first->id() << ',';
        out << entry.second.first << ".." << entry.second.second;
        out << '|';
    }
    return out;
}

std::ostream &PHV::operator<<(std::ostream &out, const PHV::Field &field) {
    out << field.id << ':' << field.name << '<' << field.size;
    if (field.phv_use_lo() || field.phv_use_hi())
        out << ':' << field.phv_use_lo() << ".." << field.phv_use_hi();
    out << '>';
    out << (field.gress ? " E" : " I") << " off=" << field.offset;
    if (field.alignment)
        out << " ^" << field.alignment->littleEndian;
    else
        out << " ^x";
    if (field.bridged) out << " bridge";
    if (field.metadata) out << " meta";
    if (field.mirror_field_list.member_field)
        out << " mirror%{"
            << field.mirror_field_list.member_field->id
            << ":" << field.mirror_field_list.member_field->name
            << "#" << field.mirror_field_list.field_list
            << "}%";
    if (field.pov) out << " pov";
    if (field.mau_write()) out << " mau_write";
    if (field.deparsed()) out << " deparsed";
    if (field.mau_phv_no_pack()) out << " mau_phv_no_pack";
    if (field.deparsed_no_pack()) out << " deparsed_no_pack";
    if (field.deparsed_bottom_bits()) out << " deparsed_bottom_bits";
    if (field.exact_containers()) out << " exact_containers";
    if (field.header_stack_pov_ccgf()) out << " header_stack_pov_ccgf";
    if (field.simple_header_pov_ccgf()) out << " simple_header_pov_ccgf";
    if (field.ccgf()) out << " ccgf=" << field.ccgf()->id << ':' << field.ccgf()->name;
    out << " /" << field.cl_id() << ",";    // cluster id
    for (auto &c : field.phv_containers()) {
        out << c->toString() << ";";  // phv number
    }
    out << "/";
    out << field.field_slices();
    if (field.ccgf_fields().size()) {
        // aggregate widths of members in "container contiguous group fields"
        out << std::endl << '[';
        for (auto &f : field.ccgf_fields()) {
            out << '\t';
            if (f->is_ccgf() && !f->header_stack_pov_ccgf()) {
                // ccgf owner appears as member, phv_use_width = aggregate size of members
                out << f->id << ':' << f->name << '<' << f->size << ">*";
            } else {
                if (f->id == field.id) {
                    // originally f was ccgf owner but after container assignment
                    // ownership got terminated although f remains ccgf member of itself
                    out << f->id << ':' << f->name << '<' << f->size << ">#";
                } else {
                    out << f;
                }
            }
            out << std::endl;
        }
        out << ':' << field.phv_use_width();
        int ccgf_width_l = field.ccgf_width();
        if (field.phv_use_width() != ccgf_width_l) {
            out << '(' << ccgf_width_l << ')';
        }
        out << ']';
    }
    if (field.field_overlay_map().size()) {
        for (auto &entry : field.field_overlay_map()) {
            out << "\t"
                << "[r" << entry.first << "] = [";
            if (entry.second) {
                for (auto &f : *(entry.second)) {
                    out << f->id;
                    if (f->ccgf_fields().size()) {
                        out << '(';
                        for (auto &m : f->ccgf_fields()) {
                            out << m->id << ',';
                        }
                        out << ')';
                    }
                    out << ";";
                }
            }
            out << ']';
        }
    }
    if (!field.alloc_i.empty())
        out << field.alloc_i;
    return out;
}

std::ostream &PHV::operator<<(std::ostream &out, const PHV::Field *fld) {
    if (fld) return out << *fld;
    return out << "(nullptr)";
}

// ordered_set Field*
std::ostream &operator<<(std::ostream &out, const ordered_set<PHV::Field *>& field_set) {
    for (auto &f : field_set) {
        out << f << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PhvInfo &phv) {
    out << "++++++++++ All Fields name[size]{range} (" << phv.num_fields() << ") ++++++++++"
        << std::endl
        << std::endl;
    //
    for (auto field : phv) {
         out << &field << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PHV::Field_Ops &op) {
    switch (op) {
        case PHV::Field_Ops::NONE: out << "None"; break;
        case PHV::Field_Ops::R: out << 'R'; break;
        case PHV::Field_Ops::W: out << 'W'; break;
        case PHV::Field_Ops::RW: out << "RW"; break;
        default: out << "<Field_Ops " << static_cast<int>(op) << ">"; }
    return out;
}

namespace std {

ostream &operator<<(ostream &out, const list<::PHV::Field *>& field_list) {
    for (auto &f : field_list) {
        out << f << std::endl;
    }
    return out;
}

ostream &operator<<(ostream &out, const set<const ::PHV::Field *>& field_list) {
    for (auto &f : field_list) {
        out << f << std::endl;
    }
    return out;
}

}  // namespace std

// for calling from the debugger
void dump(const PhvInfo *phv) { std::cout << *phv; }
void dump(const PHV::Field *f) { std::cout << *f; }

const IR::Node* PhvInfo::DumpPhvFields::apply_visitor(const IR::Node *n, const char *) {
    LOG1("");
    LOG1("--- PHV FIELDS -------------------------------------------");
    LOG1("");
    LOG1("P: used in parser/deparser");
    LOG1("M: used in MAU");
    LOG1("R: referenced anywhere");
    LOG1("D: is deparsed");
    for (auto f : phv) {
        LOG1("(" <<
              (uses.is_used_parde(&f) ? "P" : " ") <<
              (uses.is_used_mau(&f) ? "M" : " ") <<
              (uses.is_referenced(&f) ? "R" : " ") <<
              (uses.is_deparsed(&f) ? "D" : " ") << ") " << f);

        for (auto vreg : f.field_overlay_map_i) {
            for (auto child : *vreg.second) {
                LOG1("  -overlay-(" <<
                      (uses.is_used_parde(child) ? "P" : " ") <<
                      (uses.is_used_mau(child) ? "M" : " ") <<
                      (uses.is_referenced(child) ? "R" : " ") <<
                      (uses.is_deparsed(child) ? "D" : " ") << ") " << *child); } } }
    LOG1("");

    LOG1("--- PHV FIELDS WIDTH HISTOGRAM----------------------------");
    LOG1("\nINGRESS:");
    generate_field_histogram(INGRESS);
    LOG1("\nEGRESS:");
    generate_field_histogram(EGRESS);
    LOG1("\n");
    return n;
}

void PhvInfo::DumpPhvFields::generate_field_histogram(gress_t gress) const {
    if (!LOGGING(2)) return;
    std::map<int, size_t> size_distribution;
    size_t total_bits = 0;
    size_t total_fields = 0;
    for (auto field : phv) {
        if (field.gress == gress) {
            // Only report histogram for fields that aren't dead code eliminated
            if (uses.is_referenced(&field) || uses.is_deparsed(&field) || uses.is_used_mau(&field)
                    || uses.is_used_parde(&field)) {
                size_distribution[field.size] += 1;
                total_bits += field.size;
                total_fields++; } } }
    // Print histogram
    LOG1("Fields to be allocated: " << total_fields);
    LOG1("Bits to be allocated: " << total_bits);
    for (auto entry : size_distribution) {
        std::stringstream row;
        row << entry.first << "\t";
        for (size_t i = 0; i < entry.second; i++)
            row << "x";
        row << " (" << entry.second << ")";
        LOG1(row); }
}
