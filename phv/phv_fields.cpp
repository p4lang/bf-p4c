#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "lib/range.h"
#include "base/logging.h"


void PhvInfo::add(cstring name, int offset, int size, bool meta, bool pov) {
    LOG3("PhvInfo adding " << (meta ? "metadata" : "header") << " field " << name <<
         " size " << size);
    assert(all_fields.count(name) == 0);
    auto *info = &all_fields[name];
    info->name = name;
    info->id = by_id.size();
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
    int start = by_id.size();
    int offset = 0;
    for (auto f : *type->getEnumerator()) {
        add(name + '.' + f->name, offset, f->type->width_bits(), meta, false);
        offset += f->type->width_bits(); }
    int end = by_id.size() - 1;
    all_headers.emplace(name, std::make_pair(start, end));
}

bool PhvInfo::preorder(const IR::Header *h) {
    add_hdr(h->name, h->type, false);
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

const PhvInfo::Info *PhvInfo::field(const IR::Expression *e, Info::bitrange *bits) const {
    if (auto *hsr = e->to<IR::HeaderSliceRef>())
        return field(hsr, bits);
    if (auto *fr = e->to<IR::Member>())
        return field(fr, bits);
    if (auto *sl = e->to<IR::Slice>()) {
        auto *rv = field(sl->e0, bits);
        if (rv && bits) {
            bits->lo += sl->getL();
            int width = sl->getH() - sl->getL() + 1;
            assert(bits->hi >= bits->lo + width - 1);
            bits->hi = bits->lo + width - 1; }
        return rv; }
    return 0;
}

const PhvInfo::Info *PhvInfo::field(const IR::HeaderSliceRef *hsr, Info::bitrange *bits) const {
    auto hdr = header(hsr->header_ref()->toString());
    int offset = hsr->offset_bits();
    for (auto idx : Range(hdr->second, hdr->first)) {
        auto *info = field(idx);
        if (offset < info->size) {
            if (bits) {
                bits->lo = offset;
                bits->hi = offset + hsr->type->width_bits() - 1; }
            return info; }
        offset -= info->size; }
    BUG("can't find field at offset %d of %s", hsr->offset_bits(), hsr->header_ref()->toString());
}

const PhvInfo::Info *PhvInfo::field(const IR::Member *fr, Info::bitrange *bits) const {
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

vector<PhvInfo::Info::alloc_slice> *PhvInfo::alloc(const IR::Member *member) {
    PhvInfo::Info *info = field(member);
    CHECK(nullptr != info) << "; Cannot find PHV allocation for " <<
        member->toString();
    gress_t gress = info->name.startsWith("egress::") ? EGRESS : INGRESS;
    return &(info->alloc[gress]);
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

void PhvInfo::allocatePOV() {
    if (all_fields.count("$POV") || all_fields.count("ingress::$POV"))
        BUG("trying to reallocate POV");
    int ingress_size = 0, egress_size = 0, generic_size = 0;
    for (auto &hdr : all_headers)
        if (!field(hdr.second.first)->metadata) {
            if (hdr.first.startsWith("ingress::"))
                ++ingress_size;
            else if (hdr.first.startsWith("egress::"))
                ++egress_size;
            else
                ++generic_size; }
    assert(generic_size == 0 || ingress_size+egress_size == 0);
    if (generic_size > 0) {
        add("$POV", 0, generic_size, false, true);
        int offset = 0;
        for (auto &hdr : all_headers)
            if (!field(hdr.second.first)->metadata)
                add(hdr.first + ".$valid", offset++, 1, false, true); }
    if (ingress_size > 0) {
        add("ingress::$POV", 0, ingress_size, false, true);
        int offset = 0;
        for (auto &hdr : all_headers)
            if (!field(hdr.second.first)->metadata && hdr.first.startsWith("ingress::"))
                add(hdr.first + ".$valid", offset++, 1, false, true); }
    if (egress_size > 0) {
        add("egress::$POV", 0, egress_size, false, true);
        int offset = 0;
        for (auto &hdr : all_headers)
            if (!field(hdr.second.first)->metadata && hdr.first.startsWith("egress::"))
                add(hdr.first + ".$valid", offset++, 1, false, true); }
}

std::ostream &operator<<(std::ostream &out, const PhvInfo::Info::alloc_slice &sl) {
    out << (sl.field_bit+sl.width-1) << ':' << sl.field_bit << "->" << sl.container;
    if (sl.container_bit || size_t(sl.width) != sl.container.size()) {
        out << '(' << sl.container_bit;
        if (sl.width != 1)
            out << ".." << (sl.container_bit + sl.width - 1);
        out << ')'; }
    return out;
}
