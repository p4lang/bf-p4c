#ifndef _phv_fields_h_
#define _phv_fields_h_

#include "ir/visitor.h"
#include "lib/map.h"

class PhvInfo : public Inspector {
public:
    struct constraint {
	enum kind_t { SAME_GROUP, FULL_UNIT } kind;
	cstring		with;
	explicit constraint(kind_t k, cstring w = 0) : kind(k), with(w) {}
	bool operator<(const constraint &a) const {
	    return kind == a.kind ? with < a.with : kind < a.kind; }
    };
    struct Info {
	cstring		name;
	int		id;
	int		size;
	bool		metadata;
	set<constraint>	constraints;
	struct alloc_slice {
	    int		container;
	    int		field_bit, container_bit, width;
	    alloc_slice(int c, int fb, int cb, int w) : container(c), field_bit(fb),
		container_bit(cb), width(w) {} };
	vector<alloc_slice>	alloc;
    };
private:
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
    class iterator {
	vector<Info *>::iterator	it;
    public:
	iterator(vector<Info *>::iterator i) : it(i) {}
	bool operator==(iterator a) { return it == a.it; }
	bool operator!=(iterator a) { return it != a.it; }
	iterator &operator++() { ++it; return *this; }
	iterator &operator--() { --it; return *this; }
	Info &operator*() { return **it; }
	Info *operator->() { return *it; }
    };
public:
    Info *field(cstring name) { return all_fields.count(name) ? &all_fields.at(name) : 0; }
    Info *field(int idx) { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    const Info *field(cstring name) const { return getref(all_fields, name); }
    const Info *field(int idx) const { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    const std::pair<int, int> *header(cstring name) const { return getref(all_headers, name); }
    size_t num_fields() const { return all_fields.size(); }
    iterator begin() { return by_id.begin(); }
    iterator end() { return by_id.end(); }
};

#endif /* _phv_fields_h_ */
