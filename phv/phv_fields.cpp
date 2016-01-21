#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "lib/range.h"


void PhvInfo::add(cstring name, const IR::Type *type, bool meta) {
    LOG3("PhvInfo adding " << (meta ? "metadata" : "header") << " field " << name);
    assert(all_fields.count(name) == 0);
    auto *info = &all_fields[name];
    info->name = name;
    info->id = by_id.size();
    info->size = type->width_bits();
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
        add(name + '.' + f.first, f.second, meta);
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

const PhvInfo::Info *PhvInfo::field(const IR::FragmentRef *fr, std::pair<int, int> *bits) const {
    auto hdr = header(fr->base->toString());
    int offset = fr->offset_bits();
    for (auto idx : Range(hdr->first, hdr->second)) {
        auto *info = field(idx);
        if (offset < info->size) {
            if (bits) {
                bits->second = offset;
                bits->first = offset + fr->type->width_bits() - 1; }
            return info; }
        offset -= info->size; }
    throw Util::CompilerBug("can't find field at offset %d of %s", fr->offset_bits(),
                            fr->base->toString());
}

const PhvInfo::Info *PhvInfo::field(const IR::FieldRef *fr, std::pair<int, int> *bits) const {
    if (auto *frg = dynamic_cast<const IR::FragmentRef *>(fr))
        return field(frg, bits);
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
