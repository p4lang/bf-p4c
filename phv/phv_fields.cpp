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
    alloc_done_ = false;
    return rv;
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

bool PhvInfo::preorder(const IR::NamedRef *n) {
    if (n->name == "$bridge-metadata") {
        /* FIXME -- nasty hack -- we recognize this name specially as the single fixed 1 bit we
         * need in the POV to make bridged metadata work.  Should have a more general mechanism
         * for managing POV bits (need a way to shift them properly for header stack operations) */
        need_bridge_meta_pov = true; }
    return false;
}

const PhvInfo::Field *PhvInfo::field(const IR::Expression *e, Field::bitrange *bits) const {
    if (!e) return nullptr;
    if (auto *fr = e->to<IR::Member>())
        return field(fr, bits);
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
    if (auto *n = e->to<IR::NamedRef>()) {
        if (auto *rv = getref(all_fields, n->name)) {
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

void PhvInfo::allocatePOV() {
    if (all_fields.count("ingress::$POV") || all_fields.count("egress::$POV"))
        BUG("trying to reallocate POV");
    int ingress_size = 0, egress_size = 0;
    for (auto &hdr : all_headers)
        if (!field(hdr.second.first)->metadata) {
            if (hdr.first.startsWith("ingress::"))
                ++ingress_size;
            else if (hdr.first.startsWith("egress::"))
                ++egress_size;
            else
                BUG("Header %s neither ingress or egress", hdr.first); }
    if (need_bridge_meta_pov)
        ++ingress_size;
    if (ingress_size > 0) {
        gress = INGRESS;
        add("ingress::$POV", ingress_size, 0, false, true);
        for (auto &hdr : all_headers)
            if (!field(hdr.second.first)->metadata && hdr.first.startsWith("ingress::"))
                add(hdr.first + ".$valid", 1, --ingress_size, false, true);
        if (need_bridge_meta_pov)
            add("$bridge-metadata", 1, --ingress_size, false, true);
        assert(ingress_size == 0); }
    if (egress_size > 0) {
        gress = EGRESS;
        add("egress::$POV", egress_size, 0, false, true);
        for (auto &hdr : all_headers)
            if (!field(hdr.second.first)->metadata && hdr.first.startsWith("egress::"))
                add(hdr.first + ".$valid", 1, --egress_size, false, true);
        assert(egress_size == 0); }
}

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field::alloc_slice &sl) {
    out << (sl.field_bit+sl.width-1) << ':' << sl.field_bit << "->" << sl.container;
    if (sl.container_bit || size_t(sl.width) != sl.container.size()) {
        out << '(' << sl.container_bit;
        if (sl.width != 1)
            out << ".." << (sl.container_bit + sl.width - 1);
        out << ')'; }
    return out;
}
