#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "lib/range.h"
#include "base/logging.h"

bool PhvInfo::SetReferenced::preorder(const IR::Expression *e) {
    if (auto *field = self.field(e)) {
        field->referenced = true;
        if (auto *povbit = self.field(field->header() + ".$valid"))
            povbit->referenced = true;
        return false; }
    if (auto *hr = e->to<IR::HeaderRef>()) {
        for (auto id : Range(*self.header(hr)))
            self.field(id)->referenced = true;
        if (auto *povbit = self.field(hr->toString() + ".$valid"))
            povbit->referenced = true;
        return false; }
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
    info->offset = offset;
    info->metadata = meta;
    info->pov = pov;
    by_id.push_back(info);
}

void PhvInfo::add_hdr(cstring name, const IR::Type_StructLike *type, bool meta) {
    if (!type) {
        LOG2("PhvInfo no type for " << name);
        return; }
    LOG2("PhvInfo adding " << (meta ? "metadata" : "header") << " " << name);
    assert(all_headers.count(name) == 0);
    int start = by_id.size();
    int offset = 0;
    for (auto f : *type->fields)
        offset += f->type->width_bits();
    for (auto f : *type->fields) {
        int size = f->type->width_bits();
        add(name + '.' + f->name, size, offset -= size, meta, false); }
    int end = by_id.size() - 1;
    all_headers.emplace(name, std::make_pair(start, end));
}

Visitor::profile_t PhvInfo::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    all_fields.clear();
    by_id.clear();
    all_headers.clear();
    simple_headers.clear();
    alloc_done_ = false;
    return rv;
}

bool PhvInfo::preorder(const IR::Header *h) {
    int start = by_id.size();
    add_hdr(h->name, h->type, false);
    int end = by_id.size() - 1;
    simple_headers.emplace(h->name, std::make_pair(start, end));
    return false;
}

bool PhvInfo::preorder(const IR::HeaderStack *h) {
    if (!h->type) return false;
    char buffer[16];
    int start = by_id.size();
    for (int i = 0; i < h->size; i++) {
        snprintf(buffer, sizeof(buffer), "[%d]", i);
        add_hdr(h->name + buffer, h->type, false); }
    int end = by_id.size() - 1;
    all_headers.emplace(h->name, std::make_pair(start, end));
    return false;
}

bool PhvInfo::preorder(const IR::Metadata *h) {
    add_hdr(h->name, h->type, true);
    return false;
}

bool PhvInfo::preorder(const IR::TempVar *tv) {
    BUG_CHECK(tv->type->is<IR::Type::Bits>(), "Can't create temp of type %s", tv->type);
    add(tv->name, tv->type->width_bits(), 0, true, tv->POV);
    return false;
}

const PhvInfo::Field::alloc_slice &PhvInfo::Field::for_bit(int bit) const {
    for (auto &sl : alloc)
        if (bit >= sl.field_bit && bit < sl.field_bit + sl.width)
            return sl;
    BUG("No allocation for bit %d in %s", bit, name);
}

void PhvInfo::Field::foreach_alloc(int lo, int hi,
                                   std::function<void(const alloc_slice &)> fn) const {
    alloc_slice tmp(PHV::Container(), lo, lo, hi-lo+1);
    if (alloc.empty()) {
        fn(tmp);
        return; }
    auto it = alloc.rbegin();
    while (it != alloc.rend() && (it->container.tagalong() || it->field_hi() < lo)) ++it;
    if (it != alloc.rend() && it->field_bit != lo) {
        assert(it->field_bit < lo);
        tmp = *it;
        tmp.container_bit += it->field_bit - lo;
        tmp.field_bit = lo;
        if (it->field_hi() > hi)
            tmp.width = hi - lo + 1;
        else
            tmp.width -= it->field_bit - lo;
        fn(tmp);
        ++it; }
    while (it != alloc.rend() && it->field_bit <= hi) {
        if (it->container.tagalong()) continue;
        if (it->field_hi() > hi) {
            tmp = *it;
            tmp.width = hi - it->field_bit + 1;
            fn(tmp);
        } else {
            fn(*it); }
        ++it; }
}

void PhvInfo::Field::foreach_byte(int lo, int hi,
                                  std::function<void(const alloc_slice &)> fn) const {
    alloc_slice tmp(PHV::Container(), lo, lo, 8 - (lo&7));
    if (alloc.empty()) {
        while (lo <= hi) {
            if (lo/8U == hi/8U)
                tmp.width = hi - lo + 1;
            fn(tmp);
            tmp.field_bit = tmp.container_bit = lo = (lo|7) + 1;
            tmp.width = 8; }
        return; }
    auto it = alloc.rbegin();
    while (it != alloc.rend() && (it->container.tagalong() || it->field_hi() < lo)) ++it;
    while (it != alloc.rend() && it->field_bit <= hi) {
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
                if (byte_hi <= tmp.container_hi()) {
                    LOG1("**********"
                        << " field = " << name
                        << " byte_hi = " << byte_hi
                        << " tmp.container_hi = " << tmp.container_hi());
                }
                assert(byte_hi >= tmp.container_hi());
                if (byte_hi > tmp.container_hi())
                    tmp.width += byte_hi - tmp.container_hi();
                assert(tmp.width <= 8); } }
        ++it; }
    if (tmp.container) fn(tmp);
}

/* figure out how many disinct container bytes contain info from a bitrange of a particular field */
int PhvInfo::Field::container_bytes(PhvInfo::Field::bitrange bits) const {
    if (bits.hi < 0) bits.hi = size - 1;
    if (alloc.empty())
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

const PhvInfo::Field *PhvInfo::field(const IR::Expression *e, Field::bitrange *bits) const {
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
            return rv; } }
    return 0;
}

const PhvInfo::Field *PhvInfo::field(const IR::Member *fr, Field::bitrange *bits) const {
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
    warning("can't find field '%s'", name);
    return nullptr;
}

vector<PhvInfo::Field::alloc_slice> *PhvInfo::alloc(const IR::Member *member) {
    PhvInfo::Field *info = field(member);
    CHECK(nullptr != info) << "; Cannot find PHV allocation for " <<
        member->toString();
    return &info->alloc;
}

const std::pair<int, int> *PhvInfo::header(cstring name_) const {
    StringRef name = name_;
    if (auto *rv = getref(all_headers, name))
        return rv;
    if (auto *p = name.findstr("::")) {
        name = name.after(p+2);
        if (auto *rv = getref(all_headers, name))
            return rv; }
    return nullptr;
}

void PhvInfo::allocatePOV(const HeaderStackInfo &stacks) {
    if (all_fields.count("ingress::$POV") || all_fields.count("egress::$POV"))
        BUG("trying to reallocate POV");
    int size[2] = { 0, 0 };
    int stacks_num = 0;
    for (auto &stack : stacks) {
        auto *ff = field(all_headers.at(stack.name).first);
        BUG_CHECK(!ff->metadata, "metadata stack?");
        size[ff->gress] += stack.size + stack.maxpush + stack.maxpop;
        stacks_num++;
        /* FIXME all bits for a stack must end up in one container */ }
    for (auto &hdr : simple_headers) {
        auto *ff = field(hdr.second.first);
        if (!ff->metadata)
            ++size[ff->gress]; }
    for (auto &field : *this)
        if (field.pov && field.metadata)
            size[field.gress] += field.size;
    for (auto gress : Range(INGRESS, EGRESS)) {
        if (size[gress] == 0) continue;
        this->gress = gress;
        add(gress ? "egress::$POV" : "ingress::$POV", size[gress], 0, false, true);
        for (auto &field : *this)
            if (field.pov && field.metadata && field.gress == gress) {
                size[gress] -= field.size;
                field.offset = size[gress]; }
        Field *hdr_dd_valid = 0;  // header.$valid
        vector<Field *> pov_fields_h;  // accumulate member povs of simple headers
        for (auto &hdr : simple_headers) {
            auto *ff = field(hdr.second.first);
            if (!ff->metadata && ff->gress == gress) {
                add(hdr.first + ".$valid", 1, --size[gress], false, true);
                hdr_dd_valid = &all_fields[hdr.first + ".$valid"];
                pov_fields_h.push_back(hdr_dd_valid);
            }
        }
        // accumulate member povs of simple headers
        // all pov bits must be in single container
        // e.g.,
        // ingress::udp.$valid[1]{0..4}-r- --> ingress::udp.$valid
        // [      ingress::ethernet.$valid[1]
        //        ingress::ig_intr_md_for_tm.$valid[1]
        //        ingress::ipv4.$valid[1]
        //        ingress::tcp.$valid[1]
        //        ingress::udp.$valid[1]
        // :5]
        //
        if (!stacks_num && pov_fields_h.size() > 1) {
            for (auto &f : pov_fields_h) {
                hdr_dd_valid->ccgf_fields.push_back(f);
                f->ccgf = hdr_dd_valid;
            }
            hdr_dd_valid->phv_use_hi = pov_fields_h.size();
                                     // allocate container for ccgf width
            hdr_dd_valid->simple_header_pov_ccgf = true;
            pov_fields_h.clear();
        }
        for (auto &stack : stacks) {
            vector<Field *> pov_fields;  // accumulate member povs of header stk pov
            if (hdr_dd_valid) {
                pov_fields.push_back(hdr_dd_valid);
            }
            bool push_exists = false;
            auto *ff = field(all_headers.at(stack.name).first);
            if (ff->gress == gress) {
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
                    add(stack.name + ".$pop", stack.maxpush, size[gress], true, true);
                }
                add(stack.name + ".$stkvalid", stack.size + stack.maxpush + stack.maxpop,
                    size[gress], true, true);
                // do not push ".$stkvalid" as a member
                // members are slices of owner ".stkvalid"'s allocation span
                if (push_exists) {
                    Field *pov_stk = &all_fields[stack.name + ".$stkvalid"];
                    for (auto &f : pov_fields) {
                        pov_stk->ccgf_fields.push_back(f);
                        f->ccgf = pov_stk;
                    }
                    pov_stk->ccgf = pov_stk;
                    pov_stk->header_stack_pov_ccgf = true;
                }
            }
        }
        assert(size[gress] == 0);
    }
}

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field::alloc_slice &sl) {
    out << '[' << (sl.field_bit+sl.width-1) << ':' << sl.field_bit << "]->[" << sl.container << ']';
    if (sl.container_bit || size_t(sl.width) != sl.container.size()) {
        out << '(' << sl.container_bit;
        if (sl.width != 1)
            out << ".." << (sl.container_bit + sl.width - 1);
        out << ')'; }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field *fld) {
    if (fld) {
        out << fld->name
            << '['
            << fld->size
            << ']'
            << '{'
            << fld->phv_use_lo
            << ".."
            << fld->phv_use_hi
            << '}';
        if (fld->mau_write) {
            out << "-w-";
        } else {
            out << "-r-";
        }
        // member of header stk pov
        // in phv container group accumulation (sub-byte, contiguous, complete)
        // fx -> fx, fy -> fx, fz -> fx; fx: {fx, fy, fz)}
        //
        if (fld->ccgf) {
            out << " --ccgf-> " << fld->ccgf->name;
        }
        // header stk povs
        if (fld->ccgf_fields.size()) {
            // count bits in "container contiguous group fields"
            out << std::endl << '[';
            int ccg_width = 0;
            for (auto pov_f : fld->ccgf_fields) {
                out << '\t';
                out << pov_f->name << '[' << pov_f->size << ']';
                out << std::endl;
                ccg_width += pov_f->size;
            }
            out << ':' << ccg_width << ']';
        }
    } else {
        out << "-f-";  // fld is nil
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field &field) {
    out << field.id << ':' << field.name << '[' << field.size << ']'
        << (field.gress ? " E" : " I") << " off=" << field.offset;
    if (field.referenced) out << " ref";
    if (field.metadata) out << " meta";
    if (field.pov) out << " pov";
    if (field.mau_write) out << " mau_write";
    if (!field.alloc.empty())
        out << " " << field.alloc;
    return out;
}

std::ostream &operator<<(std::ostream &out, std::set<const PhvInfo::Field *>& field_set) {
    for (auto &f : field_set) {
        out << f << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<const PhvInfo::Field *>& field_list) {
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

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field_Ops &op) {
    switch(op) {
        case PhvInfo::Field_Ops::NONE: out << "None"; break;
        case PhvInfo::Field_Ops::R: out << 'R'; break;
        case PhvInfo::Field_Ops::W: out << 'W'; break;
        case PhvInfo::Field_Ops::RW: out << "RW"; break;
        default: out << "<Field_Ops " << static_cast<int>(op) << ">"; }
    return out;
}

void dump(PhvInfo *phv) {
    std::cout << *phv;
}

