#ifndef _TOFINO_PHV_PHV_FIELDS_H_
#define _TOFINO_PHV_PHV_FIELDS_H_

#include "phv.h"
#include "ir/ir.h"
#include "lib/map.h"

class PhvInfo : public Inspector {
 public:
    struct Info;
    struct constraint {
        enum kind_t { SAME_GROUP, FULL_UNIT } kind;
        const Info    *with;
        explicit constraint(kind_t k, const Info *w = nullptr) : kind(k), with(w) {}
        bool operator<(const constraint &a) const {
            return kind == a.kind ? (with ? with->id : 0) < (a.with ? a.with->id : 0)
                                  : kind < a.kind; }
    };
    struct Info {
        cstring         name;
        int             id;
        int             size;
        bool            metadata;
        set<constraint> constraints;
        struct alloc_slice {
            PHV::Container         container;
            int         field_bit, container_bit, width;
            alloc_slice(PHV::Container c, int fb, int cb, int w) : container(c), field_bit(fb),
                container_bit(cb), width(w) {} };
        vector<alloc_slice>     alloc[2]; };

 private:
    map<cstring, Info>                  all_fields;
    vector<Info *>                      by_id;
    map<cstring, std::pair<int, int>>   all_headers;
    void add(cstring, int, bool);
    void add_hdr(cstring, const IR::HeaderType *, bool);
    bool preorder(const IR::Header *h) override;
    bool preorder(const IR::HeaderStack *) override;
    bool preorder(const IR::Metadata *h) override;
    template<typename Iter>
    class iterator {
        Iter    it;
     public:
        iterator(Iter i) : it(i) {}     // NOLINT(runtime/explicit)
        bool operator==(iterator a) { return it == a.it; }
        bool operator!=(iterator a) { return it != a.it; }
        iterator &operator++() { ++it; return *this; }
        iterator &operator--() { --it; return *this; }
        decltype(**it) operator*() { return **it; }
        decltype(*it) operator->() { return *it; } };

 public:
    const Info *field(int idx) const { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    const Info *field(const IR::Expression *, std::pair<int, int> *bits = 0) const;
    const Info *field(const IR::FieldRef *, std::pair<int, int> *bits = 0) const;
    const Info *field(const IR::HeaderSliceRef *, std::pair<int, int> *bits = 0) const;
    Info *field(int idx) { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    Info *field(const IR::Expression *e, std::pair<int, int> *bits = 0) {
        return const_cast<Info *>(const_cast<const PhvInfo *>(this)->field(e, bits)); }
    Info *field(const IR::FieldRef *fr, std::pair<int, int> *bits = 0) {
        return const_cast<Info *>(const_cast<const PhvInfo *>(this)->field(fr, bits)); }
    Info *field(const IR::HeaderSliceRef *hsr, std::pair<int, int> *bits = 0) {
        return const_cast<Info *>(const_cast<const PhvInfo *>(this)->field(hsr, bits)); }
    const std::pair<int, int> *header(cstring name) const;
    const std::pair<int, int> *header(const IR::HeaderRef *hr) const {
        return header(hr->toString()); }
    size_t num_fields() const { return all_fields.size(); }
    iterator<vector<Info *>::iterator> begin() { return by_id.begin(); }
    iterator<vector<Info *>::iterator> end() { return by_id.end(); }
    iterator<vector<Info *>::const_iterator> begin() const { return by_id.begin(); }
    iterator<vector<Info *>::const_iterator> end() const { return by_id.end(); }
    void allocatePOV();
};

std::ostream &operator<<(std::ostream &, const PhvInfo::Info::alloc_slice &);

#endif /* _TOFINO_PHV_PHV_FIELDS_H_ */
