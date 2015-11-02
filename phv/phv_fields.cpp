#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/log.h"


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
	sprintf(buffer, "[%d]", i);
	add_hdr(h->name + buffer, h->type, false); }
    int end = by_id.size() - 1;
    all_headers.emplace(h->name, std::make_pair(start, end));
    return false;
}

bool PhvInfo::preorder(const IR::Metadata *h) {
    add_hdr(h->name, h->type, true);
    return false;
}

