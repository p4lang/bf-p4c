#ifndef _TOFINO_PHV_PHV_FIELDS_H_
#define _TOFINO_PHV_PHV_FIELDS_H_

#include "phv.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "tofino/common/header_stack.h"

namespace PHV {
class ManualAlloc;
class TrivialAlloc;
class ValidateAllocation;
}  // end namespace PHV

namespace Test {
template <typename T> class TofinoPHVTrivialAllocators;
class TofinoPHVManualAlloc;
}  // namespace Test

class Cluster_PHV;
class PHV_Container;
class PHV_Analysis_API;
class PHV_Bind;
class Slice;

class PhvInfo : public Inspector {
 public:
    //
    class SetReferenced : public Inspector {
        PhvInfo &self;
        bool preorder(const IR::Expression *e) override;
        profile_t init_apply(const IR::Node *root) override {
            for (auto &field : self) field.referenced = false;
            return Inspector::init_apply(root); }
     public:
        explicit SetReferenced(PhvInfo &phv) : self(phv) {}
    };
    //
    class Field {
     public:
        //
        cstring         name;
        int             id;
        gress_t         gress;
        int             size;
        int             offset;           // offset of lsb from lsb (last) bit of containing header
        bool            referenced;
        bool            metadata;
        bool            bridged = false;
        bool            pov;
        //
        // ****************************************************************************************
        // begin phv_assignment (phv_bind) interface
        // ****************************************************************************************
        //
        struct bitrange {
            int lo, hi;                       // range of bits within a container or field
            int size() const                  { return hi - lo + 1; }
            operator std::pair<int, int>()    { return std::make_pair(lo, hi); }
            bool contains(int bit) const      { return bit >= lo && bit <= hi; }
            bool overlaps(bitrange a) const   { return contains(a.lo) || a.contains(lo); }
            bool overlaps(int l, int h) const { return contains(l) || (lo >= l && lo <= h); }
            bitrange intersect(bitrange a) const {
                bitrange rv = { std::min(lo, a.lo), std::max(hi, a.hi) };
                BUG_CHECK(rv.lo <= rv.hi, "invalid bitrange::intersect");
                return rv; }
            bitrange intersect(int l, int h) const {
                bitrange rv = { std::min(lo, l), std::max(hi, h) };
                BUG_CHECK(rv.lo <= rv.hi, "invalid bitrange::intersect");
                return rv; } };
        //
        struct alloc_slice {
            const Field*           field;
            PHV::Container         container;
            int field_bit, container_bit, width;
            alloc_slice(const Field* f, PHV::Container c, int fb, int cb, int w)
                : field(f), container(c), field_bit(fb), container_bit(cb), width(w) {}
            bitrange field_bits() const       { return { field_bit, field_bit+width-1 }; }
            bitrange container_bits() const   { return { container_bit, container_bit+width-1 }; }
            int field_hi() const              { return field_bit + width - 1; }
            int container_hi() const          { return container_bit + width - 1; }
            bool operator==(const alloc_slice& other) const {
                return container == other.container &&
                       field_bit == other.field_bit &&
                       container_bit == other.container_bit &&
                       width == other.width; }
            bool operator!=(const alloc_slice& other) const {
                return !operator==(other); } };
        //
        cstring header() const { return name.before(strrchr(name, '.')); }
        int container_bytes(bitrange bits = {0, -1}) const;
        //
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
        //
     private:  // class Field
        //
        vector<alloc_slice> alloc_i;          // sorted MSB (field) first
        //
        // friends of phv_assignment interface
        //
        friend class SplitPhvUse;             // phv/split_phv_use
        friend class PHV::ManualAlloc;        // phv/trivial_alloc
        friend class PHV::TrivialAlloc;       // phv/trivial_alloc
        friend class PHV::ValidateAllocation; // phv/validate_allocation
        friend class Slice;                   // common/asm_output
        friend class ArgumentAnalyzer;        // mau/action_format
        friend class TableLayout;             // mau/table_layout
        friend class CollectGatewayFields;    // mau/gateway
        friend class MauAsmOutput;            // mau/asm_output
        friend class IXBarRealign;            // mau/ixbar_realign
        friend class InstructionAdjustment;   // mau/instruction_adjustment
        //
        friend void alloc_pov(PhvInfo::Field *i, PhvInfo::Field *pov);
        friend void repack_metadata(PhvInfo &phv);
        //
        template <typename T> friend class ::Test::TofinoPHVTrivialAllocators;
        friend class ::Test::TofinoPHVManualAlloc;
        //
        friend std::ostream &operator<<(std::ostream &out, PHV_Bind &phv_bind);
        friend void emit_phv_field(std::ostream &out, PhvInfo::Field &field);
        friend std::ostream &operator<<(std::ostream &out, const Slice &sl);
        //
        // ****************************************************************************************
        // end phv_assignment (phv_bind) interface
        // ****************************************************************************************
        //
        // ****************************************************************************************
        // begin phv_analysis interface
        // ****************************************************************************************
        //
        enum class Field_Ops {NONE = 0, R = 1, W = 2, RW = 3};
        //
        //
        // constraints on this field
        //
        bool            mau_phv_no_pack_i = false;         // true if op on field not "move based"
                                                           // set by PHV_Field_Operations
        bool            deparser_no_pack_i = false;        // true when egress_port
        bool            deparser_no_holes_i = false;       // true if deparsed field
        bool            exact_containers_i = false;        // place in container exactly (no holes)
        //
        // operations on this field
        //
        bool            mau_write_i = false;               // true when field Write in MAU
        vector<std::tuple<bool, cstring, Field_Ops>> operations_i;
                                                           // all operations performed on field
        //
        // ccgf fields
        //
        bool            header_stack_pov_ccgf_i = false;   // header stack pov owner
                                                           // has members in ccgf_fields
        bool            simple_header_pov_ccgf_i = false;  // simple header ccgf
                                                           // has members in ccgf_fields
        Field *ccgf_i = 0;                 // container contiguous group fields
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
        vector<Field *> ccgf_fields_i;     // member fields of container contiguous groups
                                           // member pov fields of header stk pov
                                           // these members are in same container as header stk pov
        //
        // phv container requirement of field
        //
        int             phv_use_lo_i = 0;   // lowest bit of field used through MAU pipeline
        int             phv_use_hi_i = 0;   // highest bit of field used through MAU pipeline
                                            // for container contiguous groups
                                            // owner phv_use_hi = sum of member sizes
        int             phv_use_rem_i = 0;  // field straddles containers
                                            // used in ccgf: container contiguous group fields
                                            // phv_container allocation phase:
                                            // remembers lowest bit of field use in next container
                                            // phv binding phase:
                                            // remembers bits already allocated
        //
        // clusters, containers and field_slices associated with this field
        //
        std::list<Cluster_PHV *> clusters_i;
                                           // field is in a single cluster before cluster_slicing
                                           // if this list is a singleton then cluster not sliced
                                           // after cluster slicing, field in a list of clusters
                                           // each slice represents same field, slice varies lo..hi
        ordered_set<PHV_Container *> phv_containers_i;
                                           // field in one or more containers
        ordered_map<Cluster_PHV *, std::pair<int, int>> field_slices_i;
                                           // each sliced cluster containing this field represents
                                           // slice of field as pair of bitranges after slicing
        //
        // field overlays
        //
        Field *overlay_substratum_i = 0;   // substratum field on which this field overlayed
        ordered_map<int, ordered_set<Field *> *> field_overlay_map_i;
                                           // liveness / interference graph related
                                           // fields (within cluster) overlay map
                                           // F = <c1,c2> adjacent containers based on F width
                                           // F[0] = c1
                                           // F[1] = c2
                                           // F<c1,c2> -- [0] -- B<c1>, A<c1>
                                           //          -- [1] -- B<c2>, D<c2>, E<c2>
        //
        // API: phv analysis to rest of Compiler
        //
        PHV_Analysis_API *phv_analysis_api_i = 0;
        //
        // cluster ids
        //
        void cl_id(std::string cl_p) const;
        std::string cl_id(Cluster_PHV *cl = 0) const;
        int cl_id_num(Cluster_PHV *cl = 0) const;
        //
        // constraints
        //
        bool mau_phv_no_pack() const                           { return mau_phv_no_pack_i; }
        void set_mau_phv_no_pack(bool b)                       { mau_phv_no_pack_i = b; }
        bool deparser_no_pack() const                          { return deparser_no_pack_i; }
        void set_deparser_no_pack(bool b)                      { deparser_no_pack_i = b; }
        bool deparser_no_holes() const                         { return deparser_no_holes_i; }
        void set_deparser_no_holes(bool b)                     { deparser_no_holes_i = b; }
        bool exact_containers() const                          { return exact_containers_i; }
        void set_exact_containers(bool b)                      { exact_containers_i = b; }
        bool constrained(bool packing_constraint = false) const;
        //
        // operations on this field
        //
        bool mau_write() const                                 { return mau_write_i; }
        void set_mau_write(bool b)                             { mau_write_i = b; }
        vector<std::tuple<bool, cstring, Field_Ops>>&
            operations()                                       { return  operations_i; }
        //
        // ccgf
        //
        bool is_ccgf() const;
        bool simple_header_pov_ccgf() const                    { return simple_header_pov_ccgf_i; }
        void set_simple_header_pov_ccgf(bool b)                { simple_header_pov_ccgf_i = b; }
        bool header_stack_pov_ccgf() const                     { return header_stack_pov_ccgf_i; }
        void set_header_stack_pov_ccgf(bool b)                 { header_stack_pov_ccgf_i = b; }
        Field *ccgf() const                                    { return ccgf_i; }
        void set_ccgf(Field *f)                                { ccgf_i = f; }
        vector<Field *>& ccgf_fields()                         { return ccgf_fields_i; }
        const vector<Field *>& ccgf_fields() const             { return ccgf_fields_i; }
        int ccgf_width() const;                               // phv width = aggregate size of members
        //
        // clusters, phv_containers
        //
        std::list<Cluster_PHV *>& clusters()                   { return clusters_i; }
        void clusters(Cluster_PHV *cluster_p);
        ordered_set<PHV_Container *>& phv_containers()         { return phv_containers_i; }
        const ordered_set<PHV_Container *>&
            phv_containers() const                             { return phv_containers_i; }
        void phv_containers(PHV_Container *c);
        //
        // phv_widths
        //
        int phv_use_width(Cluster_PHV *cl = 0) const;     // width of field needed in phv container
        void set_phv_use_width(bool ccgf, int min_ceil = 0);  // set phv_use_width for ccgf owners
        int phv_use_lo(Cluster_PHV *cl = 0) const;
        void set_phv_use_lo(int value)                         { phv_use_lo_i = value; }
        int phv_use_hi(Cluster_PHV *cl = 0) const;
        void set_phv_use_hi(int value)                         { phv_use_hi_i = value; }
        int phv_use_rem() const                                { return phv_use_rem_i; }
        void set_phv_use_rem(int value)                        { phv_use_rem_i = value; }
        //
        // field slices
        //
        bool sliced() const;
        ordered_map<Cluster_PHV *, std::pair<int, int>>&
            field_slices()                                     { return field_slices_i; }
        const ordered_map<Cluster_PHV *, std::pair<int, int>>&
            field_slices() const                               { return field_slices_i; }
        std::pair<int, int>& field_slices(Cluster_PHV *cl);
        const std::pair<int, int>& field_slices(Cluster_PHV *cl) const;
        void set_field_slices(Cluster_PHV *cl, int lo, int hi);
        //
        // field overlays
        //
        Field *overlay_substratum()                            { return overlay_substratum_i; }
        void overlay_substratum(Field *f);
        ordered_map<int, ordered_set<Field *> *>&
            field_overlay_map()                                { return field_overlay_map_i; }
        const ordered_map<int, ordered_set<Field *> *>&
            field_overlay_map() const                          { return field_overlay_map_i; }
        void field_overlay_map(int r, Field *field);
        void field_overlays(std::list<Field *>& fields_list);
        void field_overlay(Field *overlay);
        //
        // friends of phv_analysis interface
        //
        friend class Cluster;
        friend class PHV_Bind;
        friend class PHV_Container;
        friend class PHV_Interference;
        friend class PHV_MAU_Group;
        friend class PHV_MAU_Group_Assignments;
        friend class PHV_Field_Operations;
        friend class Cluster_PHV_Overlay;
        friend class Cluster_PHV;
        friend class Cluster_PHV_Requirements;
        friend class Cluster_Slicing;
        friend class PHV_Analysis_API;
        friend class PhvInfo;
        //
        friend std::ostream &operator<<(std::ostream &, const PhvInfo::Field::Field_Ops &);
        friend std::ostream &operator<<(std::ostream &out, const PhvInfo::Field &field);
        friend std::ostream &operator<<(std::ostream &out, Cluster_PHV &cp);
        //
     public:  // class Field
        //
        PHV_Analysis_API *phv_analysis_api()         { return phv_analysis_api_i; }
        void phv_analysis_api(PHV_Analysis_API *p)   { phv_analysis_api_i = p; }
        //
        // ****************************************************************************************
        // end phv_analysis interface
        // ****************************************************************************************
        //
    };  // class Field

 private:  // class PhvInfo
    //
    map<cstring, Field>                 all_fields;
    vector<Field *>                     by_id;
    map<cstring, std::pair<int, int>>   all_headers;
    map<cstring, std::pair<int, int>>   simple_headers;
    gress_t                             gress;
    bool                                alloc_done_ = false;
    bool                                pov_alloc_done = false;
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

 public:  // class PhvInfo
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
    //
    void allocatePOV(const HeaderStackInfo &);
    bool alloc_done() const { return alloc_done_; }
    void set_done() { alloc_done_ = true; }
    void addTempVar(const IR::TempVar *);
};  // class PhvInfo
//
extern void repack_metadata(PhvInfo &phv);
void dump(const PhvInfo *);
//
std::ostream &operator<<(std::ostream &, const PhvInfo::Field::bitrange &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field::alloc_slice &);
std::ostream &operator<<(std::ostream &, const vector<PhvInfo::Field::alloc_slice> &);
std::ostream &operator<<(std::ostream &, const ordered_map<Cluster_PHV *, std::pair<int, int>>&);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field *);
std::ostream &operator<<(std::ostream &, const ordered_set<PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, const std::list<PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, const PhvInfo &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field::Field_Ops &);
//
#endif /* _TOFINO_PHV_PHV_FIELDS_H_ */
