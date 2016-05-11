#ifndef _TOFINO_PHV_PHV_FIELDS_H_
#define _TOFINO_PHV_PHV_FIELDS_H_

#include "phv.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "tofino/ir/thread_visitor.h"

class PhvInfo : public Inspector {
 public:
    struct Info;
    struct constraint {
        /* FIXME -- example only -- this isn't actually used for anything yet */
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
        gress_t         gress;
        int             size;
        int             offset;  // offset lsb from lsb (last) bit of container
        bool            metadata;
        bool            pov;
        set<constraint> constraints;
        cstring header() const { return name.before(strrchr(name, '.')); }
        cstring bitgroup() const {
            if (pov) return gress ? "egress::$POV" : "ingress::$POV";
            return header(); }
        struct alloc_slice {
            PHV::Container         container;
            int         field_bit, container_bit, width;
            alloc_slice(PHV::Container c, int fb, int cb, int w) : container(c), field_bit(fb),
                container_bit(cb), width(w) {}
            int field_hi() const { return field_bit + width - 1; }
            int container_hi() const { return container_bit + width - 1; } };
        vector<alloc_slice>     alloc;   // sorted MSB (field) first
        const alloc_slice &for_bit(int bit) const {
            for (auto &sl : alloc)
                if (bit >= sl.field_bit && bit < sl.field_bit + sl.width)
                    return sl;
            BUG("No allocation for bit %d in %s", bit, name); }
        struct bitrange {
            int         lo, hi;         // range of bits within a container or field
            int size() const { return hi - lo + 1; }
        };
    };

 private:
    map<cstring, Info>                  all_fields;
    vector<Info *>                      by_id;
    map<cstring, std::pair<int, int>>   all_headers;
    gress_t                             gress;
    void add(cstring, int, int, bool, bool);
    void add_hdr(cstring, const IR::Type_StructLike *, bool);
    bool preorder(const IR::Tofino::Parser *) override {
        gress = VisitingThread(this); return true; }
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
    const Info *field(cstring name) const {
        return all_fields.count(name) ? &all_fields.at(name) : 0; }
    const Info *field(const IR::Expression *, Info::bitrange *bits = 0) const;
    const Info *field(const IR::Member *, Info::bitrange *bits = 0) const;
    const Info *field(const IR::HeaderSliceRef *, Info::bitrange *bits = 0) const;
    Info *field(int idx) { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    Info *field(const IR::Expression *e, Info::bitrange *bits = 0) {
        return const_cast<Info *>(const_cast<const PhvInfo *>(this)->field(e, bits)); }
    Info *field(const IR::Member *fr, Info::bitrange *bits = 0) {
        return const_cast<Info *>(const_cast<const PhvInfo *>(this)->field(fr, bits)); }
    Info *field(const IR::HeaderSliceRef *hsr, Info::bitrange *bits = 0) {
        return const_cast<Info *>(const_cast<const PhvInfo *>(this)->field(hsr, bits)); }
    vector<Info::alloc_slice> *alloc(const IR::Member *member);
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
