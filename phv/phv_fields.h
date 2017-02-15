#ifndef _TOFINO_PHV_PHV_FIELDS_H_
#define _TOFINO_PHV_PHV_FIELDS_H_

#include "phv.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "tofino/common/header_stack.h"

namespace PHV {
class TrivialAlloc;
}  // end namespace PHV

class PhvInfo : public Inspector {
 public:
    struct Field;
    struct constraint {
        /* FIXME -- example only -- this isn't actually used for anything yet */
        enum kind_t { SAME_GROUP, FULL_UNIT } kind;
        const Field     *with;
        explicit constraint(kind_t k, const Field *w = nullptr) : kind(k), with(w) {}
        bool operator<(const constraint &a) const {
            return kind == a.kind ? (with ? with->id : 0) < (a.with ? a.with->id : 0)
                                  : kind < a.kind; }
    };
    enum class Field_Ops {NONE = 0, R = 1, W = 2, RW = 3};
    struct Field {
        cstring         name;
        int             id;
        gress_t         gress;
        int             size;
        int             phv_use_lo = 0;   // lowest bit of field used through MAU pipeline
        int             phv_use_rem = 0;  // field straddles containers
                                          // used in ccg: container contiguous groups
                                          // phv_container allocation phase:
                                          // remembers lowest bit of field use in next container
                                          // phv binding phase:
                                          // remembers bits already allocated
        int             phv_use_hi = 0;   // highest bit of field used through MAU pipeline
                                          // for container contiguous groups
                                          // owner phv_use_hi = sum of member sizes
        int             offset;           // offset of lsb from lsb (last) bit of containing header
        bool            referenced;
        bool            metadata;
        bool            pov;
        bool            mau_write = false;  // true when field Write in MAU
        bool            header_stack_pov_ccgf = false;  // header stack pov owner
                                                        // has members in ccgf_fields
        bool            simple_header_pov_ccgf = false;  // simple header ccgf
                                                         // has members in ccgf_fields
        Field           *ccgf = 0;         // container contiguous group fields
                                           // used for
                                           // (i) header stack povs: container FULL, no holes
                                           // (ii) sub-byte header fields: container may be PARTIAL
                                           // sub-byte header fields
                                           // owner->ccgf = owner, member->ccgf = owner
                                           // owner->ccgf_fields = (owner, members)
                                           // header stack povs
                                           // only when .$push exists -- see allocatePOV()
                                           // owner ".$stkvalid" ->ccgf = 0, member->ccgf = owner
                                           // owner->ccgf_fields (members)
                                           // e.g.,
                                           // extra.$push: B9(5..6) --> extra.$stkvalid: B9(0..6)
                                           // extra$0.$valid: B9(4) --> extra.$stkvalid: B9(0..6)
        vector<Field *> ccgf_fields;       // member fields of container contiguous groups
                                           // member pov fields of header stk pov
                                           // these members are in same container as header stk pov
        set<constraint> constraints;  // unused -- get rid of it?
        vector<std::tuple<bool, cstring, Field_Ops>> operations;
                                           // all operations performed on the field
        cstring header() const { return name.before(strrchr(name, '.')); }
        PHV::Bit bit(unsigned i) const {
            BUG_CHECK(i < size_t(size), "bit out of range for field");
            if (pov) {
                cstring povname = gress ? "egress::$POV" : "ingress::$POV";
                return PHV::Bit(povname, i+offset); }
            return PHV::Bit(name, i); }
        struct bitrange {
            int         lo, hi;         // range of bits within a container or field
            int size() const { return hi - lo + 1; }
            operator std::pair<int, int>() { return std::make_pair(lo, hi); }
            bool contains(int bit) const { return bit >= lo && bit <= hi; }
            bool overlaps(bitrange a) const { return contains(a.lo) || a.contains(lo); }
            bool overlaps(int l, int h) const { return contains(l) || (lo >= l && lo <= h); }
            bitrange intersect(bitrange a) const {
                bitrange rv = { std::min(lo, a.lo), std::max(hi, a.hi) };
                BUG_CHECK(rv.lo <= rv.hi, "invalid bitrange::intersect");
                return rv; }
            bitrange intersect(int l, int h) const {
                bitrange rv = { std::min(lo, l), std::max(hi, h) };
                BUG_CHECK(rv.lo <= rv.hi, "invalid bitrange::intersect");
                return rv; } };

        struct alloc_slice {
            PHV::Container         container;
            int         field_bit, container_bit, width;
            alloc_slice(PHV::Container c, int fb, int cb, int w) : container(c), field_bit(fb),
                container_bit(cb), width(w) {}
            bitrange field_bits() const { return { field_bit, field_bit+width-1 }; }
            bitrange container_bits() const { return { container_bit, container_bit+width-1 }; }
            int field_hi() const { return field_bit + width - 1; }
            int container_hi() const { return container_bit + width - 1; } };
        vector<alloc_slice>     alloc;   // sorted MSB (field) first
        int container_bytes(bitrange bits = {0, -1}) const;
        int phv_use_width() const { return phv_use_hi - phv_use_lo + 1; }
                                                      // width of field needed in phv container
        const alloc_slice &for_bit(int bit) const;
        void foreach_alloc(int lo, int hi, std::function<void(const alloc_slice &)> fn) const;
        void foreach_alloc(std::function<void(const alloc_slice &)> fn) const {
            foreach_alloc(0, size-1, fn); }
        void foreach_alloc(bitrange r, std::function<void(const alloc_slice &)> fn) const {
            foreach_alloc(r.lo, r.hi, fn); }
        void foreach_alloc(const bitrange *r, std::function<void(const alloc_slice &)> fn) const {
            foreach_alloc(r ? r->lo : 0, r ? r->hi : size-1, fn); }
        void foreach_byte(int lo, int hi, std::function<void(const alloc_slice &)> fn) const;
        void foreach_byte(std::function<void(const alloc_slice &)> fn) const {
            foreach_byte(0, size-1, fn); }
        void foreach_byte(bitrange r, std::function<void(const alloc_slice &)> fn) const {
            foreach_byte(r.lo, r.hi, fn); }
        void foreach_byte(const bitrange *r, std::function<void(const alloc_slice &)> fn) const {
            foreach_byte(r ? r->lo : 0, r ? r->hi : size-1, fn); }
    };
    class SetReferenced : public Inspector {
        PhvInfo &self;
        bool preorder(const IR::Expression *e) override;
        profile_t init_apply(const IR::Node *root) override {
            for (auto &field : self) field.referenced = false;
            return Inspector::init_apply(root); }
     public:
        explicit SetReferenced(PhvInfo &phv) : self(phv) {}
    };

 private:
    map<cstring, Field>                 all_fields;
    vector<Field *>                     by_id;
    map<cstring, std::pair<int, int>>   all_headers;
    map<cstring, std::pair<int, int>>   simple_headers;
    gress_t                             gress;
    bool                                alloc_done_ = false;
    void add(cstring, int, int, bool, bool);
    void add_hdr(cstring, const IR::Type_StructLike *, bool);
    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::Tofino::Parser *) override {
        gress = VisitingThread(this); return true; }
    bool preorder(const IR::Header *h) override;
    bool preorder(const IR::HeaderStack *) override;
    bool preorder(const IR::Metadata *h) override;
    bool preorder(const IR::TempVar *h) override;
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
    friend class PhvAllocator;
    friend class PHV::TrivialAlloc;

 public:
    const Field *field(int idx) const { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    const Field *field(cstring name) const {
        return all_fields.count(name) ? &all_fields.at(name) : 0; }
    const Field *field(const IR::Expression *, Field::bitrange *bits = 0) const;
    const Field *field(const IR::Member *, Field::bitrange *bits = 0) const;
    Field *field(int idx) { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    Field *field(cstring name) { return all_fields.count(name) ? &all_fields.at(name) : 0; }
    Field *field(const IR::Expression *e, Field::bitrange *bits = 0) {
        return const_cast<Field *>(const_cast<const PhvInfo *>(this)->field(e, bits)); }
    Field *field(const IR::Member *fr, Field::bitrange *bits = 0) {
        return const_cast<Field *>(const_cast<const PhvInfo *>(this)->field(fr, bits)); }
    vector<Field::alloc_slice> *alloc(const IR::Member *member);
    const std::pair<int, int> *header(cstring name) const;
    const std::pair<int, int> *header(const IR::HeaderRef *hr) const {
        return header(hr->toString()); }
    size_t num_fields() const { return all_fields.size(); }
    iterator<vector<Field *>::iterator> begin() { return by_id.begin(); }
    iterator<vector<Field *>::iterator> end() { return by_id.end(); }
    iterator<vector<Field *>::const_iterator> begin() const { return by_id.begin(); }
    iterator<vector<Field *>::const_iterator> end() const { return by_id.end(); }
    void allocatePOV(const HeaderStackInfo &);
    bool alloc_done() const { return alloc_done_; }
};

std::ostream &operator<<(std::ostream &, const PhvInfo::Field::alloc_slice &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field *);
std::ostream &operator<<(std::ostream &, std::set<const PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, std::list<const PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, const PhvInfo &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field_Ops &);
extern void repack_metadata(PhvInfo &phv);

void dump(const PhvInfo *);
extern void repack_metadata(PhvInfo &phv);

std::ostream &operator<<(std::ostream &out, const PhvInfo::Field::bitrange &br);

#endif /* _TOFINO_PHV_PHV_FIELDS_H_ */
