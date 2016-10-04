#ifndef _TOFINO_PHV_PHV_FIELDS_H_
#define _TOFINO_PHV_PHV_FIELDS_H_

#include "phv.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"

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
    struct Field {
        cstring         name;
        int             id;
        gress_t         gress;
        int             size;
        int		phv_use_lo;	// lowest bit of field used through MAU pipeline
        int		phv_use_hi;	// highest bit of field used through MAU pipeline
        int             offset;  // offset of lsb from lsb (last) bit of containing header
        bool            referenced;
        bool            metadata;
        bool            pov;
        set<constraint> constraints;
        cstring header() const { return name.before(strrchr(name, '.')); }
        PHV::Bit bit(unsigned i) const {
            BUG_CHECK(i < size_t(size), "bit out of range for field");
            if (pov) {
                assert(i == 0 || offset == 0);
                cstring povname = gress ? "egress::$POV" : "ingress::$POV";
                return PHV::Bit(povname, i+offset); }
            return PHV::Bit(name, i); }
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
            operator std::pair<int, int>() { return std::make_pair(lo, hi); }
        };
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
    gress_t                             gress;
    bool                                alloc_done_ = false;
    bool                                need_bridge_meta_pov = false;
    int                                 tmp_alloc_uid = 0;
    void add(cstring, int, int, bool, bool);
    void add_hdr(cstring, const IR::Type_StructLike *, bool);
    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::Tofino::Parser *) override {
        gress = VisitingThread(this); return true; }
    bool preorder(const IR::Header *h) override;
    bool preorder(const IR::HeaderStack *) override;
    bool preorder(const IR::Metadata *h) override;
    bool preorder(const IR::NamedRef *h) override;
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
    const IR::Expression *createTempField(const IR::Type *type, const char *extname = 0);
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
    void allocatePOV();
    bool alloc_done() const { return alloc_done_; }
};

std::ostream &operator<<(std::ostream &, const PhvInfo::Field::alloc_slice &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field *);
std::ostream &operator<<(std::ostream &, const PhvInfo &);
extern void repack_metadata(PhvInfo &phv);

#endif /* _TOFINO_PHV_PHV_FIELDS_H_ */
