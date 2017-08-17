#include "phv_fields.h"
#include "phv_analysis_api.h"
#include "phv_assignment_api.h"
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "lib/range.h"

//
//***********************************************************************************
//
// PhvInfo::SetReferenced preorder
//
//***********************************************************************************
//

bool PhvInfo::SetReferenced::preorder(const IR::Expression *e) {
    if (auto *field = self.field(e)) {
        field->referenced = true;
        if (auto *povbit = self.field(field->header() + ".$valid"))
            povbit->referenced = true;
        return false;
    } else if (e->is<IR::Member>()) {  // prevent descent into IR::Member objects
        return false;
    }
    // IR::HeaderRef objects
    if (auto *hr = e->to<IR::HeaderRef>()) {
        for (auto id : self.struct_info(hr).field_ids())
            self.field(id)->referenced = true;
        if (auto *povbit = self.field(hr->toString() + ".$valid"))
            povbit->referenced = true;
        return false; }
    return true;
}

//
//***********************************************************************************
//
// PhvInfo member functions
//
//***********************************************************************************
//

Visitor::profile_t PhvInfo::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    all_fields.clear();
    by_id.clear();
    all_structs.clear();
    simple_headers.clear();
    alloc_done_ = false;
    return rv;
}

bool PhvInfo::preorder(const IR::Header *h) {
    int start = by_id.size();
    add_hdr(h->name, h->type, false);
    int end = by_id.size();
    simple_headers.emplace(h->name, StructInfo(false, gress, start, end - start));
    return false;
}

bool PhvInfo::preorder(const IR::HeaderStack *h) {
    if (!h->type) return false;
    char buffer[16];
    int start = by_id.size();
    for (int i = 0; i < h->size; i++) {
        snprintf(buffer, sizeof(buffer), "[%d]", i);
        add_hdr(h->name + buffer, h->type, false); }
    int end = by_id.size();
    all_structs.emplace(h->name, StructInfo(false, gress, start, end - start));
    return false;
}

bool PhvInfo::preorder(const IR::Metadata *h) {
    add_hdr(h->name, h->type, true);
    return false;
}

bool PhvInfo::preorder(const IR::TempVar *tv) {
    addTempVar(tv);
    return false;
}

void PhvInfo::postorder(const IR::Tofino::Deparser *d) {
    // extract deparser constraints from Deparser & Digest IR nodes ref: bf-p4c/ir/parde.def
    // set deparser constaints on field
    if (d->egress_port) {
        // IR::Tofino::Deparser has a field egress_port which points to
        // egress port in the egress pipeline and
        // egress spec in the ingress pipeline
        Field *f = field(d->egress_port);
        BUG_CHECK(f != nullptr, "Field not created in PhvInfo");
        f->set_deparsed_no_pack(true);
        LOG1(".....Deparser Constraint 'egress port' on field..... " << f); }

    // TODO:
    // IR futures: distinguish each digest as an enumeration: learning, mirror, resubmit
    // as they have differing constraints -- bottom-bits, bridge-metadata mirror packing
    // learning, mirror field list in bottom bits of container, e.g.,
    // 301:ingress::$learning<3:0..2>
    // 590:egress::$mirror<3:0..2> specifies 1 of 8 field lists
    // currently, IR::Tofino::Digest node has a string field to distinguish them by name
    for (auto &entry : Values(d->digests)) {
        if (entry->name != "learning" && entry->name != "mirror")
            continue;

        Field *f = field(entry->select);
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
                    auto l_f = field(l);
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
                Field *mirror = field(m);
                if (mirror) {
                    mirror->mirror_field_list = {f, fl};
                    LOG1("\t\t" << mirror);
                } else {
                    LOG1("\t\t" << "-f?"); }
                fl++; } } }
}

void PhvInfo::postorder(const IR::Expression *e) {
    Field *f = field(e);
    if (f && isWrite()) {
        f->set_mau_write(true);  // note: this can be a parser write only
        LOG4(".....MAU_write....." << f); }
}


bool PhvInfo::preorder(const IR::Tofino::ParserState* state) {
    if (state->name != "$bridged_metadata_extract") return true;
    for (auto* match : state->match) {
        forAllMatching<IR::Tofino::Extract>(&match->stmts,
                      [&](const IR::Tofino::Extract* extract) {
            auto* fieldInfo = field(extract->dest);
            if (!fieldInfo) return;
            fieldInfo->bridged = true;
        });
    }
    return true;
}

void PhvInfo::add(cstring name, int size, int offset, bool meta, bool pov) {
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

void PhvInfo::add_hdr(cstring name, const IR::Type_StructLike *type, bool meta) {
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
        add(name + '.' + f->name, size, offset -= size, meta, false); }
    int end = by_id.size();
    all_structs.emplace(name, StructInfo(meta, gress, start, end - start));
}

void PhvInfo::addTempVar(const IR::TempVar *tv) {
    BUG_CHECK(tv->type->is<IR::Type::Bits>() || tv->type->is<IR::Type::Boolean>(),
              "Can't create temp of type %s", tv->type);
    if (all_fields.count(tv->name) == 0)
        add(tv->name, tv->type->width_bits(), 0, true, tv->POV);
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

const PhvInfo::Field *PhvInfo::field(const IR::Expression *e, bitrange *bits) const {
    if (!e) return nullptr;
    if (auto *fr = e->to<IR::Member>())
        return field(fr, bits);
    if (auto *cast = e->to<IR::Cast>()) {
        auto *rv = field(cast->expr, bits);
        if (rv && bits && bits->size() > cast->type->width_bits())
            bits->hi = bits->lo + cast->type->width_bits() - 1;
        return rv; }
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

const PhvInfo::Field *PhvInfo::field(const IR::Member *fr, bitrange *bits) const {
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

void PhvInfo::allocatePOV(const HeaderStackInfo &stacks) {
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
    for (auto gress : Range(INGRESS, EGRESS)) {
        if (size[gress] == 0) continue;
        this->gress = gress;
        for (auto &field : *this)
            if (field.pov && field.metadata && field.gress == gress) {
                size[gress] -= field.size;
                field.offset = size[gress]; }
        Field *hdr_dd_valid = 0;  // header.$valid
        vector<Field *> pov_fields_h;  // accumulate member povs of simple headers
        for (auto hdr : simple_headers) {
            auto hdr_info = hdr.second;
            if (hdr_info.gress == gress) {
                add(hdr.first + ".$valid", 1, --size[gress], false, true);
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
            for (auto &f : pov_fields_h) {
                hdr_dd_valid->ccgf_fields().push_back(f);
                f->set_ccgf(hdr_dd_valid);
            }
            hdr_dd_valid->set_phv_use_hi(pov_fields_h.size());
                                     // allocate container for ccgf width
            hdr_dd_valid->set_simple_header_pov_ccgf(true);
            pov_fields_h.clear();
        }
        for (auto &stack : stacks) {
            vector<Field *> pov_fields;  // accumulate member povs of header stk pov
            // TODO: Why just push hdr_dd_valid?  Why not all of pov_fields_h?
            if (hdr_dd_valid) {
                pov_fields.push_back(hdr_dd_valid);
            }
            bool push_exists = false;
            StructInfo info = struct_info(stack.name);
            if (info.gress == gress) {
                if (stack.maxpush) {
                    size[gress] -= stack.maxpush;
                    add(stack.name + ".$push", stack.maxpush, size[gress], true, true);
                    pov_fields.push_back(&all_fields[stack.name + ".$push"]);
                    push_exists = true;
                }
                char buffer[16];
                for (int i = 0; i < stack.size; ++i) {
                    snprintf(buffer, sizeof(buffer), "[%d]", i);
                    add(stack.name + buffer + ".$valid", 1, --size[gress], false, true);
                    pov_fields.push_back(&all_fields[stack.name + buffer + ".$valid"]);
                }
                if (stack.maxpop) {
                    size[gress] -= stack.maxpop;
                    // TODO FIXME should this be stack.maxpop?
                    add(stack.name + ".$pop", stack.maxpush, size[gress], true, true);
                }
                add(stack.name + ".$stkvalid", stack.size + stack.maxpush + stack.maxpop,
                    size[gress], true, true);
                // do not push ".$stkvalid" as a member
                // members are slices of owner ".stkvalid"'s allocation span
                // TODO FIXME: why only push_exists?  What about the $valid and $pop fields?
                if (push_exists) {
                    Field *pov_stk = &all_fields[stack.name + ".$stkvalid"];
                    for (auto &f : pov_fields) {
                        pov_stk->ccgf_fields().push_back(f);
                        f->set_ccgf(pov_stk);
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
// PhvInfo::Field bitrange interface related member functions
//
//***********************************************************************************
//

// figure out how many disinct container bytes contain info from a bitrange of a particular field
//
int PhvInfo::Field::container_bytes(bitrange bits) const {
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
// PhvInfo::Field Cluster Phv_Bind / alloc_i interface related member functions
//
//***********************************************************************************
//

vector<PhvInfo::Field::alloc_slice> *PhvInfo::alloc(const IR::Member *member) {
    PhvInfo::Field *info = field(member);
    BUG_CHECK(nullptr != info, "; Cannot find PHV allocation for %s", member->toString());
    return &info->alloc_i;
}

const PhvInfo::Field::alloc_slice &PhvInfo::Field::for_bit(int bit) const {
    for (auto &sl : alloc_i)
        if (bit >= sl.field_bit && bit < sl.field_bit + sl.width)
            return sl;
    ERROR("No allocation for bit " << bit << " in " << name);
    static alloc_slice invalid(nullptr, PHV::Container(), 0, 0, 0);
    return invalid;
}

void PhvInfo::Field::foreach_byte(int lo, int hi,
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
    while (it != alloc_i.rend() && (it->container.tagalong() || it->field_hi() < lo)) ++it;
    while (it != alloc_i.rend() && it->field_bit <= hi) {
        if (it->container.tagalong()) continue;
        unsigned clo = it->container_bit, chi = it->container_hi();
        for (unsigned cbyte = clo/8U; cbyte <= chi/8U; ++cbyte) {
            if (it->container != tmp.container || cbyte != tmp.container_bit/8U) {
                if (tmp.container) fn(tmp);
                tmp = *it;
                if (cbyte*8 > clo) {
                    tmp.container_bit = cbyte*8;
                    tmp.field_bit += cbyte*8 - clo;
                    tmp.width -= cbyte*8 - clo; }
                if (cbyte*8+7 < chi)
                    tmp.width -= chi - (cbyte*8+7);
            } else {
                int byte_hi = std::min(chi, cbyte*8+7);
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
                        << " container = " << it->container.kind() << it->container.index());
                    BUG("phv_fields.cpp:foreach_byte(): byte_hi < container_hi");
                }
                if (byte_hi > tmp.container_hi())
                    tmp.width += byte_hi - tmp.container_hi();
                assert(tmp.width <= 8); } }
        ++it; }
    if (tmp.container) fn(tmp);
}  // foreach byte

void PhvInfo::Field::foreach_alloc(
    int lo,
    int hi,
    std::function<void(const alloc_slice &)> fn) const {
    //
    alloc_slice tmp(this, PHV::Container(), lo, lo, hi-lo+1);
    if (alloc_i.empty()) {
        fn(tmp);
        return; }
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
                << " container = " << it->container.kind() << it->container.index());
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
                << " container = " << it->container.kind() << it->container.index());
            BUG("phv_fields.cpp:foreach_alloc(): container_bit negative in alloc_slice");
        }
        tmp.field_bit = lo;
        if (it->field_hi() > hi)
            tmp.width = hi - lo + 1;
        else
            tmp.width -= abs(it->field_bit - lo);
        fn(tmp);
        ++it; }
    while (it != alloc_i.rend() && it->field_bit <= hi) {
        if (it->field_hi() > hi) {
            tmp = *it;
            tmp.width = hi - it->field_bit + 1;
            fn(tmp);
        } else {
            fn(*it); }
        ++it; }
}  // foreach alloc

//
//***********************************************************************************
//
// PhvInfo::Field Cluster based Phv Allocation related member functions
//
//***********************************************************************************
//

//
// cluster ids
//
void
PhvInfo::Field::cl_id(std::string cl_p) const {
    // can only change id of original non-sliced cluster
    if (!sliced() && field_slices_i.size()) {
        Cluster_PHV *cl = field_slices_i.begin()->first;
        cl->id(cl_p);
    }
}

std::string
PhvInfo::Field::cl_id(Cluster_PHV * cl) const {
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
PhvInfo::Field::cl_id_num(Cluster_PHV *cl) const {
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
PhvInfo::Field::constrained(bool packing_constraint) const {
    bool pack_c = mau_phv_no_pack_i || deparsed_no_pack_i;
    if (packing_constraint) {
        return pack_c;
    }
    return  pack_c || deparsed_bottom_bits_i;
}

bool
PhvInfo::Field::is_ccgf() const {
    if (ccgf_i == this || header_stack_pov_ccgf_i || simple_header_pov_ccgf_i) {
        assert(ccgf_fields_i.size());
        return true;
    }
    return false;
}

bool
PhvInfo::Field::allocation_complete() const {
    //
    // after phv container allocation, ccgf fields are removed by update_ccgf()
    //
    return ccgf_fields_i.size() == 0;
}

int
PhvInfo::Field::phv_use_width(Cluster_PHV *cl) const {
    // non-sliced owner not in map
    if (cl && field_slices_i.count(cl)) {
        return phv_use_hi(cl) - phv_use_lo(cl) + 1;
    }
    return phv_use_hi_i - phv_use_lo_i + 1;
}

void
PhvInfo::Field::set_ccgf_phv_use_width(int min_ceil) {
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
PhvInfo::Field::ccgf_width() const {
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
PhvInfo::Field::sliced() const {
    if (field_slices_i.size() > 1) {
        return true;
    }
    return false;
}

std::pair<int, int>&
PhvInfo::Field::field_slices(Cluster_PHV *cl) {
    assert(cl);
    assert(field_slices_i.count(cl));
    return field_slices_i[cl];
}

const std::pair<int, int>&
PhvInfo::Field::field_slices(Cluster_PHV *cl) const {
    assert(cl);
    assert(field_slices_i.count(cl));
    return field_slices_i.at(cl);
}

void
PhvInfo::Field::set_field_slices(Cluster_PHV *cl, int lo, int hi, Cluster_PHV *parent_cl) {
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
PhvInfo::Field::phv_use_lo(Cluster_PHV *cl) const {
    if (cl && field_slices_i.size() && field_slices_i.count(cl)) {
        return field_slices(cl).first;
    }
    return phv_use_lo_i;
}

int
PhvInfo::Field::phv_use_hi(Cluster_PHV *cl) const {
    if (cl && field_slices_i.size() && field_slices_i.count(cl)) {
        return field_slices(cl).second;
    }
    return phv_use_hi_i;
}

//
// field overlays
//

void
PhvInfo::Field::phv_containers(PHV_Container *c) {
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
            field_overlay_map_i[c->phv_number()] = set_of_f;
        }
    }
}

void
PhvInfo::Field::overlay_substratum(Field *f) {
    assert(f);
    overlay_substratum_i = f;
}

void
PhvInfo::Field::field_overlay_map(Field *field, int r, bool actual_register) {
    assert(field);
    //
    // r, as virtual container, made -ve when map entry created (by phv_interference)
    // after phv container association w/ field, virtual entry replaced by actual container
    // r becomes actual phv container number and used when associating overlayed fields
    // see PhvInfo::Field::phv_containers(PHV_Container *c) above
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


ordered_set<PhvInfo::Field *> *
PhvInfo::Field::field_overlay_map(int r) {
    if (!field_overlay_map_i.size() || !field_overlay_map_i.count(r)) {
        return 0;
    }
    return field_overlay_map_i[r];
}

void
PhvInfo::Field::field_overlays(std::list<Field *>& fields_list) {
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
PhvInfo::Field::field_overlay(Field *overlay, int phv_number) {
    // add overlay to substratum's owner field map of overlays
    // to make phv_interference->mutually_exclusive() computation updated & accurate
    assert(overlay);
    overlay->overlay_substratum(overlay_substratum_i? overlay_substratum_i: this);
    overlay->overlay_substratum()->field_overlay_map(overlay, phv_number);
}

//
//
//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field::alloc_slice &sl) {
    out << '[' << (sl.field_bit+sl.width-1) << ':' << sl.field_bit << "]->[" << sl.container << ']';
    if (sl.container_bit || size_t(sl.width) != sl.container.size()) {
        out << '(' << sl.container_bit;
        if (sl.width != 1)
            out << ".." << (sl.container_bit + sl.width - 1);
        out << ')'; }
    return out;
}

std::ostream &operator<<(std::ostream &out, const vector<PhvInfo::Field::alloc_slice> &sl_vec) {
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

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field &field) {
    out << field.id << ':' << field.name << '<' << field.size;
    if (field.phv_use_lo() || field.phv_use_hi())
        out << ':' << field.phv_use_lo() << ".." << field.phv_use_hi();
    out << '>';
    out << (field.gress ? " E" : " I") << " off=" << field.offset;
    if (field.referenced) out << " ref";
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
        out << c->phv_number_string() << ";";  // phv number
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

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field *fld) {
    if (fld) return out << *fld;
    return out << "(nullptr)";
}

// ordered_set Field*
std::ostream &operator<<(std::ostream &out, const ordered_set<PhvInfo::Field *>& field_set) {
    for (auto &f : field_set) {
        out << f << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const std::list<PhvInfo::Field *>& field_list) {
    for (auto &f : field_list) {
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

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field::Field_Ops &op) {
    switch (op) {
        case PhvInfo::Field::Field_Ops::NONE: out << "None"; break;
        case PhvInfo::Field::Field_Ops::R: out << 'R'; break;
        case PhvInfo::Field::Field_Ops::W: out << 'W'; break;
        case PhvInfo::Field::Field_Ops::RW: out << "RW"; break;
        default: out << "<Field_Ops " << static_cast<int>(op) << ">"; }
    return out;
}

// for calling from the debugger
void dump(const PhvInfo *phv) { std::cout << *phv; }
void dump(const PhvInfo::Field *f) { std::cout << *f; }
