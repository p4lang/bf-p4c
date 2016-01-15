#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "lib/range.h"


void PhvInfo::add(cstring name, int size, bool meta) {
    LOG3("PhvInfo adding " << (meta ? "metadata" : "header") << " field " << name <<
         " size " << size);
    assert(all_fields.count(name) == 0);
    auto *info = &all_fields[name];
    info->name = name;
    info->id = by_id.size();
    info->size = size;
    info->metadata = meta;
    by_id.push_back(info);
}

void PhvInfo::add_hdr(cstring name, const IR::HeaderType *type, bool meta) {
    if (!type) {
        LOG2("PhvInfo no type for " << name);
        return; }
    LOG2("PhvInfo adding " << (meta ? "metadata" : "header") << " " << name);
    int start = by_id.size();
    for (auto &f : type->fields)
        add(name + '.' + f.first, f.second->width_bits(), meta);
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

const PhvInfo::Info *PhvInfo::field(const IR::HeaderSliceRef *hsr,
                                    std::pair<int, int> *bits) const {
    auto hdr = header(hsr->header_ref()->toString());
    int offset = hsr->offset_bits();
    for (auto idx : Range(hdr->first, hdr->second)) {
        auto *info = field(idx);
        if (offset < info->size) {
            if (bits) {
                bits->second = offset;
                bits->first = offset + hsr->type->width_bits() - 1; }
            return info; }
        offset -= info->size; }
    throw Util::CompilerBug("can't find field at offset %d of %s",
                            hsr->offset_bits(), hsr->header_ref()->toString());
}

const PhvInfo::Info *PhvInfo::field(const IR::FieldRef *fr, std::pair<int, int> *bits) const {
    StringRef name = fr->toString();
    if (bits) {
        bits->second = 0;
        bits->first = fr->type->width_bits() - 1; }
    if (auto *p = name.findstr("::"))
        name = name.after(p+2);
    if (auto *p = name.find('[')) {
        if (name.after(p).find(':'))
            name = name.before(p); }
    if (auto *rv = getref(all_fields, name))
        return rv;
    warning("can't find field '%s'", name);
    return nullptr;
}

const std::pair<int, int> *PhvInfo::header(cstring name_) const {
    StringRef name = name_;
    if (auto *p = name.findstr("::"))
        name = name.after(p+2);
    if (auto *rv = getref(all_headers, name))
        return rv;
    return nullptr;
}

void PhvInfo::allocatePOV() {
    if (all_fields.count("$POV"))
        throw Util::CompilerBug("trying to reallocate POV");
    int size = 0;
    for (auto &hdr : all_headers)
        if (!field(hdr.second.first)->metadata)
            ++size;
    add("$POV", size, false);
    for (auto &hdr : all_headers)
        if (!field(hdr.second.first)->metadata)
            add(hdr.first + ".$valid", 1, false);
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
