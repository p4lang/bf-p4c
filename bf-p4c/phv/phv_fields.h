#ifndef BF_P4C_PHV_PHV_FIELDS_H_
#define BF_P4C_PHV_PHV_FIELDS_H_

#include <boost/optional.hpp>
#include <boost/range/irange.hpp>
#include <limits>

#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/phv/field_alignment.h"
#include "bf-p4c/phv/phv.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"
#include "lib/safe_vector.h"

namespace PHV {
class ManualAlloc;
class TrivialAlloc;
class ValidateAllocation;
}  // end namespace PHV

namespace Test {
template <typename T> class TofinoPHVTrivialAllocators;
class TofinoPHVManualAlloc;
}  // namespace Test

class AllocateVirtualContainers;
class Build_PHV_Analysis_APIs;
class CheckFitting;
class Cluster_PHV;
class PHV_Container;
class PHV_Analysis_API;
class PHV_Assignment_API;
class PHV_Bind;
class PhvUse;
class Slice;

/**
 * PhvInfo stores information about the PHV-backed storage in the program -
 * fields of header and metadata instances, header stacks, TempVars, and POV
 * bits. These items are all represented as PhvInfo::Field objects.
 *
 * Prior to PHV allocation, PhvInfo provides a central place to discover
 * information about Fields; this includes their name, size and
 * alignment, the ways in which they're used in the program and the PHV
 * allocation constraints that apply to them.
 *
 * After PHV allocation, PhvInfo additionally stores the allocation results for
 * each Field.
 *
 * PhvInfo is read throughout the backend, but it should be written to only by
 * CollectPhvInfo and the PHV analysis and PHV bind passes. If you need to store
 * new information in PhvInfo, add a pass that collects it from the IR in
 * CollectPhvInfo. @see CollectPhvInfo for more information.
 */
class PhvInfo {
 public:
    class Field {
     public:
        /** Field name, following this scheme:
         *   - "header.field"
         *   - "header.field[i]" where "i" is a positive integer
         *   - "header.$valid"
         */
        cstring         name;
        /// Unique field ID.
        int             id;
        /// Whether the Field is ingress or egress.
        gress_t         gress;
        /// Total size of Field in bits.
        int             size;
        /// The alignment requirement of this field. If boost::none, there is no
        /// particular alignment requirement.
        boost::optional<FieldAlignment> alignment;
        /// The range of possible bit positions at which this field can be
        /// placed in a container, in network order. In other words, the low bit
        /// index of the field's container range must be
        /// `>= validContainerRange.lo`, and the high bit index must be
        /// `<= validContainerRange.hi`.
        nw_bitrange validContainerRange = ZeroToMax();
        /// Offset of lsb from lsb (last) bit of containing header.
        int             offset;
        /// True if this Field is metadata.
        bool            metadata;
        /// True if this Field is metadata bridged from ingress to egress.
        bool            bridged = false;
        /// A mirror field points to its field list (one of eight)
        struct mirror_field_list_t {
            Field *member_field;
            int   field_list;
            bool operator==(const mirror_field_list_t& rhs) const {
                return rhs.member_field == this->member_field && rhs.field_list == this->field_list;
            }
            bool operator!=(const mirror_field_list_t& rhs) const {
                return !(*this == rhs);
            }
        } mirror_field_list = {nullptr, -1};

        /// True if this Field is a validity bit.  Implies metadata.
        bool            pov;

        //
        // ****************************************************************************************
        // ****************************************************************************************
        // TODO goal to move Analysis API related members here into field->phv_analysis_api object
        // similarly move Assignment API related members here into field->phv_assignment_api object
        // alternately, use abstract base classes
        // define both APIs as abstract classes that PhvInfo::Field implements
        // more efficient than creating new API objects for every field
        // ****************************************************************************************
        // ****************************************************************************************
        //
        //
        // ****************************************************************************************
        // begin phv_assignment (phv_bind) interface
        // ****************************************************************************************
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
        // alloc_slice bit
        const alloc_slice &for_bit(int bit) const;
        //
        // alloc_slice byte
        void foreach_byte(std::function<void(const alloc_slice &)> fn) const {
            foreach_byte(0, size-1, fn); }
        void foreach_byte(bitrange r, std::function<void(const alloc_slice &)> fn) const {
            foreach_byte(r.lo, r.hi, fn); }
        void foreach_byte(const bitrange *r, std::function<void(const alloc_slice &)> fn) const {
            foreach_byte(r ? r->lo : 0, r ? r->hi : size-1, fn); }
        //
        // alloc_slice bitrange
        void foreach_alloc(
            std::function<void(const alloc_slice &)> fn) const {
            foreach_alloc(0, size-1, fn);
        }
        void foreach_alloc(bitrange r, std::function<void(const alloc_slice &)> fn) const {
            foreach_alloc(r.lo, r.hi, fn); }
        void foreach_alloc(const bitrange *r, std::function<void(const alloc_slice &)> fn) const {
            foreach_alloc(r ? r->lo : 0, r ? r->hi : size-1, fn); }
                // e.g., foreach_alloc function with bitrange to only iterate over part of field
                // bitrange  bits;        // local var (on stack)
                // auto *field = phv.field(expr, &bits);  // pointer to bits, phv.field fills it
                // field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &alloc) {
                //     LOG1("Alloc slice of write " << alloc); }
        //
        cstring header() const { return name.before(strrchr(name, '.')); }
        int container_bytes(bitrange bits = {0, -1}) const;
        //
        PHV_Assignment_API *phv_assignment_api()        { return phv_assignment_api_i; }
        void phv_assignment_api(PHV_Assignment_API *p)  { phv_assignment_api_i = p; }

        void clear_alloc() { alloc_i.clear(); }

     private:  // class Field
        //
        safe_vector<alloc_slice> alloc_i;  // sorted MSB (field) first
        //
        // API: phv assignment to rest of Compiler
        //
        PHV_Assignment_API *phv_assignment_api_i = nullptr;
        //
        void foreach_alloc(
            int lo,
            int hi,
            std::function<void(const alloc_slice &)> fn) const;
        void foreach_byte(int lo, int hi, std::function<void(const alloc_slice &)> fn) const;

        /// Update the alignment requirement for this field. Reports an error if
        /// conflicting requirements render the alignment unsatisfiable.
        void updateAlignment(const FieldAlignment& newAlignment);

        /**
         * Update the valid range of container positions for this field.
         * Reports an error if conflicting requirements render the constraint
         * unsatisfiable.
         *
         * @param newValidRange  A new valid range constraint. This is
         *                       intersected with any existing valid range
         *                       constraint to produce a new overall valid
         *                       container range for this field.
         */
        void updateValidContainerRange(nw_bitrange newValidRange);

        //
        // friends of phv_assignment interface
        //
        friend struct CollectPhvFields;
        friend struct ComputeFieldAlignments;
        friend CheckFitting;
        friend class SplitPhvUse;             // phv/split_phv_use
        friend class PHV::ManualAlloc;        // phv/trivial_alloc
        friend class PHV::TrivialAlloc;       // phv/trivial_alloc
        friend class PHV::ValidateAllocation;  // phv/validate_allocation
        friend class Slice;                   // common/asm_output
        friend class ArgumentAnalyzer;        // mau/action_format
        friend class TableLayout;             // mau/table_layout
        friend class CollectGatewayFields;    // mau/gateway
        friend class MauAsmOutput;            // mau/asm_output
        friend class IXBarRealign;            // mau/ixbar_realign
        friend class ActionAnalysis;          // mau/action_analysis
        friend class MergeInstructions;       // mau/instruction_adjustment
        friend class PHV_Assignment_API;
        friend Build_PHV_Analysis_APIs;
        friend class PHV_Assignment_Validate;
        friend AllocateVirtualContainers;
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
        bool            mau_phv_no_pack_i = false;         /// true if op on field not "move based"
                                                           /// set by PHV_Field_Operations
        bool            deparsed_i = false;                /// true if deparsed field
        bool            deparsed_no_pack_i = false;        /// true when egress_port/spec, no pack
        bool            deparsed_bottom_bits_i = false;    /// true when learning digest, no shifter
        bool            exact_containers_i = false;        /// place in container exactly (no holes)
        //
        // operations on this field
        //
        bool            mau_write_i = false;               /// true when field Write in MAU
        safe_vector<std::tuple<bool, cstring, Field_Ops>> operations_i;
                                                           /// all operations performed on field
        //
        // ccgf fields
        //
        bool            header_stack_pov_ccgf_i = false;   /// header stack pov owner
        bool            simple_header_pov_ccgf_i = false;  /// simple header ccgf
        Field *ccgf_i = nullptr;           /// container contiguous group fields (ccgf)
                                           // (i) header stack povs: container FULL, no holes
                                           //     only when .$push exists -- see allocatePOV()
                                           //     owner".$stkvalid"->ccgf = 0, member->ccgf = owner
                                           //     owner->ccgf_fields (members)
                                           //     owner is not in ccgf_fields
                                           //     it "overlaps" members in phv container
                                           //     e.g.,
                                           //     PHV-64.B0.I.Fp  76543221
                                           //     1= 63:ingress::data.$valid<1>           B0<1:7..7>
                                           //     2= 64:ingress::extra.$push<2:0..1>      B0<2:5..6>
                                           //     3= 65:ingress::extra[0].$valid<1>       B0<1:4..4>
                                           //     4= 66:ingress::extra[1].$valid<1>       B0<1:3..3>
                                           //     5= 67:ingress::extra[2].$valid<1>       B0<1:2..2>
                                           //     6= 68:ingress::extra[3].$valid<1>       B0<1:1..1>
                                           //     72^ 70:ingress::extra.$stkvalid<7:0..6> B0<7:0..6>
                                           //     extra.$push.ccgf_i --> extra.$stkvalid
                                           //     extra[0].$valid.ccgf_i --> extra.$stkvalid
                                           //     extra.$stkvalid.ccgf_i --> 0
                                           //
                                           // (ii) simple header povs: container may be PARTIAL
                                           //      owner->ccgf = owner, member->ccgf = owner
                                           //      owner->ccgf_fields = (owner + members)
                                           //
                                           // (iii) sub-byte & byte boundary accumulation
                                           //                                 -- deparser constraint
                                           //      owner->ccgf = owner, member->ccgf = owner
                                           //      owner->ccgf_fields = (owner + members)
        safe_vector<Field *> ccgf_fields_i;  // member fields of ccgfs
                                             // members are in same container as owner
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
        ordered_map<Cluster_PHV *, std::pair<int, int>> field_slices_i;
                                           // map has singleton entry when cluster/field not sliced
                                           // field slice = lo .. hi represents slice of same field
        ordered_set<PHV_Container *> phv_containers_i;
                                           // field in one or more containers
        //
        // field overlays
        //
        Field *overlay_substratum_i = nullptr;  // substratum field on which this field overlayed
        ordered_map<int, ordered_set<Field *> *> field_overlay_map_i;
                                           // liveness / interference graph related
                                           // fields (within cluster) overlay map
                                           // F = <c1,c2> adjacent containers based on F width
                                           // F[0] = c1
                                           // F[1] = c2
                                           // F<c1,c2> -- [0] -- B<c1>, A<c1>
                                           //          -- [1] -- B<c2>, D<c2>, E<c2>
                                           // after phv container association with field
                                           // virtual container number keys replaced by phv-numbers
        //
        // API: phv analysis to rest of Compiler
        //
        PHV_Analysis_API *phv_analysis_api_i = nullptr;
        //
        // cluster ids
        //
        // cluster IDs strings for tracking and differentiating purposes
        // e.g., PHV_Interference::virtual_container_overlay() updates cluster id
        // tracks chain of "interference reduced" overlay fields to substratum field
        //
        void cl_id(std::string cl_p) const;
        std::string cl_id(Cluster_PHV *cl = nullptr) const;
        int cl_id_num(Cluster_PHV *cl = nullptr) const;
        //
        // constraints
        //
        bool mau_phv_no_pack() const                           { return mau_phv_no_pack_i; }
        void set_mau_phv_no_pack(bool b)                       { mau_phv_no_pack_i = b; }
        bool deparsed() const                                  { return deparsed_i; }
        void set_deparsed(bool b)                              { deparsed_i = b; }
        bool deparsed_no_pack() const                          { return deparsed_no_pack_i; }
        void set_deparsed_no_pack(bool b)                      { deparsed_no_pack_i = b; }
        bool deparsed_bottom_bits() const                      { return deparsed_bottom_bits_i; }
        void set_deparsed_bottom_bits(bool b)                  { deparsed_bottom_bits_i = b; }
        bool exact_containers() const                          { return exact_containers_i; }
        void set_exact_containers(bool b)                      { exact_containers_i = b; }
        bool constrained(bool packing_constraint = false) const;
        //
        // operations on this field
        //
        bool mau_write() const                                 { return mau_write_i; }
        void set_mau_write(bool b)                             { mau_write_i = b; }
        safe_vector<std::tuple<bool, cstring, Field_Ops>>&
            operations()                                       { return  operations_i; }
        //
        // ccgf
        //
        bool is_ccgf() const;
        bool allocation_complete() const;
        bool simple_header_pov_ccgf() const                    { return simple_header_pov_ccgf_i; }
        void set_simple_header_pov_ccgf(bool b)                { simple_header_pov_ccgf_i = b; }
        bool header_stack_pov_ccgf() const                     { return header_stack_pov_ccgf_i; }
        void set_header_stack_pov_ccgf(bool b)                 { header_stack_pov_ccgf_i = b; }
        Field *ccgf() const                                    { return ccgf_i; }
        void set_ccgf(Field *f)                                { ccgf_i = f; }
        safe_vector<Field *>& ccgf_fields()                    { return ccgf_fields_i; }
        const safe_vector<Field *>& ccgf_fields() const        { return ccgf_fields_i; }

        int ccgf_width() const;  // phv width = aggregate size of members
        //
        // phv_containers
     public:
        //
        ordered_set<PHV_Container *>& phv_containers()         { return phv_containers_i; }
        const ordered_set<PHV_Container *>&
            phv_containers() const                             { return phv_containers_i; }
        void phv_containers(PHV_Container *c);

     private:
        //
        // phv_widths
        //
        int phv_use_width(Cluster_PHV *cl = nullptr) const;   // field width needed in phv container
        void set_ccgf_phv_use_width(int min_ceil = 0);        // set phv_use_width for ccgf owners
        int phv_use_lo(Cluster_PHV *cl = nullptr) const;
        void set_phv_use_lo(int value)                         { phv_use_lo_i = value; }
        int phv_use_hi(Cluster_PHV *cl = nullptr) const;
        void set_phv_use_hi(int value)                         { phv_use_hi_i = value; }
        int phv_use_rem() const                                { return phv_use_rem_i; }
        void set_phv_use_rem(int value)                        { phv_use_rem_i = value; }
        //
        // phv_alignment
        //

        /**
         * Returns alignment constraint (bit position within container, mod 8)
         * on this field, if any.
         *
         * @param get_ccgf_alignment  When `true`, returns the alignment
         *                            constraint of the whole CCGF; otherwise,
         *                            returns the alignment constraint of the
         *                            member field within the CCGF. Has no
         *                            effect for non-CCGF fields.
         */
        boost::optional<int> phv_alignment(bool get_ccgf_alignment = true) const;
                                                              // alignment in phv container
                                                              // ccgf as a whole vs ccgf member
        boost::optional<int> phv_alignment_network() const;   // alignment in network order
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
        void set_field_slices(Cluster_PHV *cl, int lo, int hi, Cluster_PHV *parent = nullptr);
        //
        // field overlays
        //
        Field *overlay_substratum() const                      { return overlay_substratum_i; }
        void overlay_substratum(Field *f);
        ordered_map<int, ordered_set<Field *> *>&
            field_overlay_map()                                { return field_overlay_map_i; }
        const ordered_map<int, ordered_set<Field *> *>&
            field_overlay_map() const                          { return field_overlay_map_i; }
        void field_overlay_map(Field *field, int r, bool actual_register = true);
        ordered_set<Field *> *field_overlay_map(int r);
        void field_overlays(std::list<Field *>& fields_list);
        void field_overlay(Field *overlay, int phv_number);
        bool is_overlay(const Field *field) const;
        //
        // friends of phv_analysis interface
        //
        friend class PhvInfo;
        friend class Phv_Parde_Mau_Use;
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
        friend class PHV_Analysis_Validate;
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

    /// Pretty-print all fields
    struct DumpPhvFields : public Visitor {
        const PhvInfo &phv;
        const PhvUse &uses;

        explicit DumpPhvFields(
            const PhvInfo& phv,
            const PhvUse &uses)
          : phv(phv), uses(uses) { }

        const IR::Node *apply_visitor(const IR::Node *n, const char *) override;
    };

    /// PHV-related info about structs, i.e. collections of header or metadata fields.
    struct StructInfo {
        /// True if this is a metadata struct; false for headers.
        bool metadata;

        /// Gress of this struct.
        gress_t gress;

        /// PhvInfo::Field ID (i.e. index into `by_id`) of the first field of
        /// this struct.  Struct fields are assigned contiguous IDs.  This field
        /// is not valid when `size == 0`.
        int first_field_id;

        /// Number of fields in this struct. May be `0` for structs with no
        /// fields.
        int size;

        StructInfo(bool metadata, gress_t gress)
        : metadata(metadata), gress(gress), first_field_id(0), size(0) { }
        StructInfo(bool metadata, gress_t gress, int first_field_id, int size)
        : metadata(metadata), gress(gress), first_field_id(first_field_id), size(size) {
            BUG_CHECK(0 <= size, "PhvInfo::StructInfo with negative size");
            BUG_CHECK(size == 0 || 0 <= first_field_id,
                "PhvInfo::StructInfo with negative first field offset");
        }

        /// Returns the half-open range of field IDs for this struct.
        boost::integer_range<int> field_ids() const {
            return boost::irange(first_field_id, first_field_id + size);
        }
    };

 private:  // class PhvInfo
    //
    std::map<cstring, Field>            all_fields;
    /// Maps Field.id to Field.  Also used to generate fresh Field.id values.
    safe_vector<Field *>                by_id;

    /// Maps names of header or metadata structs to corresponding info objects.
    std::map<cstring, StructInfo>       all_structs;

    /// Tracks the subset of `all_structs` that are only headers, not header stacks.
    // TODO: what about header unions?
    std::map<cstring, StructInfo>       simple_headers;

    /// Mapping from containers to the fields using those containers
    std::map<PHV::Container, ordered_set<const Field *>> container_to_fields;

    bool                                alloc_done_ = false;
    bool                                pov_alloc_done = false;

    void clear();
    void add(cstring fieldName, gress_t gress, int size, int offset,
             bool isMetadata, bool isPOV);
    void add_hdr(cstring headerName, const IR::Type_StructLike* type,
                 gress_t gress, bool isMetadata);
    void addTempVar(const IR::TempVar* tempVar, gress_t gress);

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

    friend struct CollectPhvFields;
    friend struct AllocatePOVBits;
    friend struct MarkBridgedMetadataFields;

    /** Add a 1-bit "hdr.$valid" field for each simple header.  For each header stack, add:
     *  - A "stack[x].$valid" field for each stack element.
     *  - A "stack.$push" field if the push_front primitive is used.
     *  - A "stack.$pop" field if the pop_front primitive is used.
     *  - A "stack.$stkvalid" field.
     *
     * POV fields are grouped into container contiguous group fields (CCGFs) as follows:
     *
     * @pre CollectHeaderStackInfo and CollectPhvFields.
     * @post POV fields for all headers added to PhvInfo.
     */
    void allocatePOV(const BFN::HeaderStackInfo&);

 public:  // class PhvInfo
    const Field *field(int idx) const { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    const Field *field(cstring name) const {
        return all_fields.count(name) ? &all_fields.at(name) : 0; }
    const Field *field(const IR::Expression *, bitrange *bits = 0) const;
    const Field *field(const IR::Member *, bitrange *bits = 0) const;
    Field *field(int idx) { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    Field *field(cstring name) { return all_fields.count(name) ? &all_fields.at(name) : 0; }
    Field *field(const IR::Expression *e, bitrange *bits = 0) {
        return const_cast<Field *>(const_cast<const PhvInfo *>(this)->field(e, bits)); }
    Field *field(const IR::Member *fr, bitrange *bits = 0) {
        return const_cast<Field *>(const_cast<const PhvInfo *>(this)->field(fr, bits)); }
    safe_vector<Field::alloc_slice> *alloc(const IR::Member *member);
    const StructInfo struct_info(cstring name) const;
    const StructInfo struct_info(const IR::HeaderRef *hr) const {
        return struct_info(hr->toString()); }
    size_t num_fields() const { return all_fields.size(); }
    iterator<safe_vector<Field *>::iterator> begin() { return by_id.begin(); }
    iterator<safe_vector<Field *>::iterator> end() { return by_id.end(); }
    iterator<safe_vector<Field *>::const_iterator> begin() const { return by_id.begin(); }
    iterator<safe_vector<Field *>::const_iterator> end() const { return by_id.end(); }

    bool alloc_done() const { return alloc_done_; }
    void set_done() { alloc_done_ = true; }

    /// Container_to_fields map related functions
    /// Clear the container_to_fields map
    void clear_container_to_fields() { container_to_fields.clear(); }
    /** Add new field to a container
      * @param f, field stored within container c
      * @param c, container to store field f
      */
    void add_container_to_field_entry(const PHV::Container c, const Field *f);
    /// @returns the set of fields assigned (partially or entirely) to @c
    const ordered_set<const Field *>& fields_in_container(const PHV::Container c) const;

    /// @returns true whenever field f is the only field present in container c
    bool is_only_field_in_container(const PHV::Container c, const Field *f) const;

    /** @returns a bitvec showing the currently allocated bits in a container
      * Note that one common bitvec is used to represent all fields that may be in a container
      * (overlaid or allocated to disjoint parts of the container)
      */
    bitvec bits_allocated(const PHV::Container c) const;
};  // class PhvInfo

/**
 * @brief Create and store a PhvInfo::Field for each header and metadata
 * field, and for TempVars. Allocate POV fields for header and metadata
 * instances.
 *
 * We want the information in PhvInfo to be reconstructible at any time in the
 * backend prior to PHV binding. CollectPhvInfo inspects not only the variables
 * and types used in the program, but also e.g. the parser states (to infer
 * which metadata fields are bridged), the digest field lists (to discover PHV
 * allocation constraints for fields which are used there), and general
 * expression (to discover which fields are written). When adding new
 * information to PhvInfo, it's important to *collect that information in
 * CollectPhvInfo rather than adding it manually*; otherwise, it will be lost
 * when CollectPhvInfo is rerun.
 *
 * @pre HeaderStackInfo has been run, so that `BFN::Pipe::headerStackInfo` is
 * available.
 *
 * @post This object contains a PhvInfo::Field for each header and metadata
 * field, and a POV field for each header and metadata instance.
 */
struct CollectPhvInfo : public PassManager {
    explicit CollectPhvInfo(PhvInfo& phv);
};

extern void repack_metadata(PhvInfo &phv);
void dump(const PhvInfo *);
void dump(const PhvInfo::Field *);
//
std::ostream &operator<<(std::ostream &, const PhvInfo::Field::alloc_slice &);
std::ostream &operator<<(std::ostream &, const safe_vector<PhvInfo::Field::alloc_slice> &);
std::ostream &operator<<(std::ostream &, const ordered_map<Cluster_PHV *, std::pair<int, int>>&);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field *);
std::ostream &operator<<(std::ostream &, const ordered_set<PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, const std::list<PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, const PhvInfo &);
std::ostream &operator<<(std::ostream &, const PhvInfo::Field::Field_Ops &);
//
#endif /* BF_P4C_PHV_PHV_FIELDS_H_ */
