#ifndef _phv_fields_h_
#define _phv_fields_h_

#include "ir/visitor.h"
#include "lib/map.h"

class PhvInfo : public Inspector {
    struct Info {
	cstring		name;
	int		id;
	int		size;
	bool		metadata;
    };
    map<cstring, Info>			all_fields;
    vector<Info *>			by_id;
    map<cstring, std::pair<int, int>>	all_headers;
    void add(cstring, const IR::Type *, bool);
    void add_hdr(cstring, const IR::HeaderType *, bool);
    bool preorder(const IR::Header *h) override;
    bool preorder(const IR::HeaderStack *) override;
    bool preorder(const IR::Metadata *h) override;
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::Table *) override { return false; }
    bool preorder(const IR::Parser *) override { return false; }
public:
    Info *field(cstring name) { return all_fields.count(name) ? &all_fields.at(name) : 0; }
    Info *field(int idx) { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    const Info *field(cstring name) const { return getref(all_fields, name); }
    const Info *field(int idx) const { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    const std::pair<int, int> *header(cstring name) const { return getref(all_headers, name); }
    size_t num_fields() const { return all_fields.size(); }
};

#endif /* _phv_fields_h_ */
