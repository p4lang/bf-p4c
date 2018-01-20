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
class AlignedCluster;
}  // end namespace PHV

namespace Test {
template <typename T> class TofinoPHVTrivialAllocators;
class TofinoPHVManualAlloc;
}  // namespace Test

class ActionPhvConstraints;
class AllocSlice;
class Clustering;
struct CollectPhvFields;
struct ComputeFieldAlignments;
class PHV_Field_Operations;
class PhvInfo;
class PHVManualAlloc;
class Phv_Parde_Mau_Use;
class PHVTrivialAlloc;
class PhvUse;
class Slice;
class CoreAllocation;
class FieldInterference;

namespace PHV {
class Field;
}  // namespace PHV

std::ostream &operator<<(std::ostream &out, const Slice &sl);

namespace PHV {

enum class Field_Ops {NONE = 0, R = 1, W = 2, RW = 3};

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

    /// See documentation for `Field::validContainerRange()`.
    /// TODO(cole): Refactor this.
    nw_bitrange validContainerRange_i = ZeroToMax();

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

    /// True if this Field is a validity bit.
    bool            pov;

    // ****************************************************************************************
    // begin phv_assignment (phv_bind) interface
    // ****************************************************************************************
    struct alloc_slice {
        const Field*           field;
        PHV::Container         container;
        int field_bit, container_bit, width;
        alloc_slice(const Field* f, PHV::Container c, int fb, int cb, int w)
            : field(f), container(c), field_bit(fb), container_bit(cb), width(w) {}
        le_bitrange field_bits() const       { return { field_bit, field_bit+width-1 }; }
        le_bitrange container_bits() const   { return { container_bit, container_bit+width-1 }; }
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
    void foreach_byte(le_bitrange r, std::function<void(const alloc_slice &)> fn) const {
        foreach_byte(r.lo, r.hi, fn); }
    void foreach_byte(const le_bitrange *r, std::function<void(const alloc_slice &)> fn) const {
        foreach_byte(r ? r->lo : 0, r ? r->hi : size-1, fn); }
    //
    // alloc_slice bitrange
    void foreach_alloc(
        std::function<void(const alloc_slice &)> fn) const {
        foreach_alloc(0, size-1, fn);
    }
    void foreach_alloc(le_bitrange r, std::function<void(const alloc_slice &)> fn) const {
        foreach_alloc(r.lo, r.hi, fn); }
    void foreach_alloc(const le_bitrange *r, std::function<void(const alloc_slice &)> fn) const {
        foreach_alloc(r ? r->lo : 0, r ? r->hi : size-1, fn); }
            // e.g., foreach_alloc function with le_bitrange to only iterate over part of field
            // le_bitrange  bits;        // local var (on stack)
            // auto *field = phv.field(expr, &bits);  // pointer to bits, phv.field fills it
            // field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
            //     LOG1("Alloc slice of write " << alloc); }
    //
    cstring header() const { return name.before(strrchr(name, '.')); }
    int container_bytes(le_bitrange bits = {0, -1}) const;
    //
    void clear_alloc() { alloc_i.clear(); }

    safe_vector<alloc_slice> alloc_i;  // sorted MSB (field) first

    /// Update the alignment requirement for this field. Reports an error if
    /// conflicting requirements render the alignment unsatisfiable.
    void updateAlignment(const FieldAlignment& newAlignment);

 private:  // class Field
    void foreach_alloc(
        int lo,
        int hi,
        std::function<void(const alloc_slice &)> fn) const;
    void foreach_byte(int lo, int hi, std::function<void(const alloc_slice &)> fn) const;


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
    friend struct ::CollectPhvFields;
    friend struct ::ComputeFieldAlignments;
    friend class ::PHV::ManualAlloc;        // phv/trivial_alloc
    friend class ::PHV::TrivialAlloc;       // phv/trivial_alloc
    friend class ::PHV::ValidateAllocation;  // phv/validate_allocation
    friend class ::PHV::AlignedCluster;
    friend class ::CoreAllocation;
    //
    template <typename T> friend class ::Test::TofinoPHVTrivialAllocators;
    friend class ::Test::TofinoPHVManualAlloc;
    //
    friend std::ostream &::operator<<(std::ostream &out, const ::Slice &sl);
    //
    // ****************************************************************************************
    // end phv_assignment (phv_bind) interface
    // ****************************************************************************************
    //
    // ****************************************************************************************
    // begin phv_analysis interface
    // ****************************************************************************************
    //
    // constraints on this field
    //
    bool            mau_phv_no_pack_i = false;         /// true if op on field not "move based"
                                                       /// set by PHV_Field_Operations
    bool            deparsed_i = false;                /// true if deparsed field
    bool            no_pack_i = false;                 /// prevents field from being placed in a
                                                       /// container with any other field
    bool            deparsed_bottom_bits_i = false;    /// true when learning digest, no shifter
    bool            exact_containers_i = false;        /// place in container exactly (no holes)

    bool            no_split_i = false;                /// true if field cannot be split into
                                                       /// multiple PHV containers

    bool            deparsed_to_tm_i = false;          /// true if field is read by TM

    //
    // operations on this field
    //
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
    // operations on this field
    //
    safe_vector<std::tuple<bool, cstring, Field_Ops>>&
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

 public:
    safe_vector<Field *>& ccgf_fields()                    { return ccgf_fields_i; }
    const safe_vector<Field *>& ccgf_fields() const        { return ccgf_fields_i; }

    int ccgf_width() const;  // phv width = aggregate size of members

    bool is_tphv_candidate(const PhvUse& uses) const;

    //
    // constraints
    //
    bool mau_phv_no_pack() const                           { return mau_phv_no_pack_i; }
    void set_mau_phv_no_pack(bool b)                       { mau_phv_no_pack_i = b; }
    bool deparsed() const                                  { return deparsed_i; }
    void set_deparsed(bool b)                              { deparsed_i = b; }
    bool no_pack() const                                   { return no_pack_i; }
    void set_no_pack(bool b)                               { no_pack_i = b; }
    bool deparsed_bottom_bits() const                      { return deparsed_bottom_bits_i; }
    void set_deparsed_bottom_bits(bool b)                  { deparsed_bottom_bits_i = b; }
    bool exact_containers() const                          { return exact_containers_i; }
    void set_exact_containers(bool b)                      { exact_containers_i = b; }

    bool no_split() const                                  { return no_split_i; }
    void set_no_split(bool b)                              { no_split_i = b; }

    bool deparsed_to_tm() const                            { return deparsed_to_tm_i; }
    void set_deparsed_to_tm(bool b)                        { deparsed_to_tm_i = b; }

    bool constrained(bool packing_constraint = false) const;

 private:
    /**
     * Returns alignment constraint (little Endian bit position within
     * container, mod 8) on this field, if any.
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
    // friends of phv_analysis interface
    //
    friend class ::ActionPhvConstraints;
    friend class ::Clustering;
    friend class ::PhvInfo;
    friend class ::Phv_Parde_Mau_Use;
    friend class ::PHV_Field_Operations;
    friend class ::FieldInterference;
    //
    friend std::ostream &operator<<(std::ostream &out, const Field &field);

 public:  // class Field
    /** The range of possible bit positions at which this field can be placed
     * in a container, in network order.  For example, suppose we have an 8-bit
     * field with `validContainerRange = [0, 11]` and a 16-bit container.
     *
     *      0              15  (network order)
     *    | ---------------- | container
     *      ^          ^
     *      X          Y
     *
     * The entire field must be placed between X and Y (inclusive).
     *
     * Note that field-->container assignment is usually in *little Endian*.
     * From that perspective the picture looks like:
     *
     *      15             0   (little Endian order)
     *    | ---------------- | container
     *      ^          ^
     *      X          Y
     *
     * And so the field must be placed in what are considered the "upper" bits
     * of the container.
     *
     * If this field is a CCGF owner, recomputes and returns the valid
     * container range for all CCGF fields (including the owner).
     *
     * XXX(cole): This range always starts at 0, which is an invariant that
     * other parts of the compiler rely on.
     */
    nw_bitrange validContainerRange() {
        if (this->is_ccgf() && !this->pov) {
            auto last_member = ccgf_fields_i.back();
            if (last_member->validContainerRange_i == ZeroToMax())
                return ZeroToMax();
            int extra_valid_bits = last_member->validContainerRange_i.size() - this->size;
            return last_member->validContainerRange_i.resizedToBits(
                this->ccgf_width() + extra_valid_bits);
        }
        return validContainerRange_i;
    }
};

std::ostream &operator<<(std::ostream &out, const Field &);
std::ostream &operator<<(std::ostream &out, const Field *);
std::ostream &operator<<(std::ostream &, const Field::alloc_slice &);
std::ostream &operator<<(std::ostream &, const AllocSlice &);

}  // namespace PHV

/**
 * PhvInfo stores information about the PHV-backed storage in the program -
 * fields of header and metadata instances, header stacks, TempVars, and POV
 * bits. These items are all represented as PHV::Field objects.
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
    /// Pretty-print all fields
    struct DumpPhvFields : public Visitor {
        const PhvInfo &phv;
        const PhvUse &uses;

        explicit DumpPhvFields(
            const PhvInfo& phv,
            const PhvUse &uses)
          : phv(phv), uses(uses) { }

        const IR::Node *apply_visitor(const IR::Node *n, const char *) override;
        /** Prints a histogram of all field sizes (number of fields of a particular size) in a
         * particular gress. Also prints number of fields and total number of bits to be allocated
         */
        void generate_field_histogram(gress_t) const;
    };

    /// PHV-related info about structs, i.e. collections of header or metadata fields.
    struct StructInfo {
        /// True if this is a metadata struct; false for headers.
        bool metadata;

        /// Gress of this struct.
        gress_t gress;

        /// PHV::Field ID (i.e. index into `by_id`) of the first field of
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
    std::map<cstring, PHV::Field>            all_fields;
    /// Maps Field.id to Field.  Also used to generate fresh Field.id values.
    safe_vector<PHV::Field *>                by_id;

    /// Maps names of header or metadata structs to corresponding info objects.
    std::map<cstring, StructInfo>       all_structs;

    /// Tracks the subset of `all_structs` that are only headers, not header stacks.
    // TODO: what about header unions?
    std::map<cstring, StructInfo>       simple_headers;

    /// Mapping from containers to the fields using those containers
    std::map<PHV::Container, ordered_set<const PHV::Field *>> container_to_fields;

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
    const PHV::Field *field(int idx) const {
        return (size_t)idx < by_id.size() ? by_id.at(idx) : 0;
    }
    const PHV::Field *field(cstring name) const {
        return all_fields.count(name) ? &all_fields.at(name) : 0; }
    const PHV::Field *field(const IR::Expression *, le_bitrange *bits = 0) const;
    const PHV::Field *field(const IR::Member *, le_bitrange *bits = 0) const;
    PHV::Field *field(int idx) { return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    PHV::Field *field(cstring name) { return all_fields.count(name) ? &all_fields.at(name) : 0; }
    PHV::Field *field(const IR::Expression *e, le_bitrange *bits = 0) {
        return const_cast<PHV::Field *>(const_cast<const PhvInfo *>(this)->field(e, bits)); }
    PHV::Field *field(const IR::Member *fr, le_bitrange *bits = 0) {
        return const_cast<PHV::Field *>(const_cast<const PhvInfo *>(this)->field(fr, bits)); }
    safe_vector<PHV::Field::alloc_slice> *alloc(const IR::Member *member);
    const StructInfo struct_info(cstring name) const;
    const StructInfo struct_info(const IR::HeaderRef *hr) const {
        return struct_info(hr->toString()); }
    size_t num_fields() const { return all_fields.size(); }
    iterator<safe_vector<PHV::Field *>::iterator> begin() { return by_id.begin(); }
    iterator<safe_vector<PHV::Field *>::iterator> end() { return by_id.end(); }
    iterator<safe_vector<PHV::Field *>::const_iterator> begin() const { return by_id.begin(); }
    iterator<safe_vector<PHV::Field *>::const_iterator> end() const { return by_id.end(); }

    bool alloc_done() const { return alloc_done_; }
    void set_done() { alloc_done_ = true; }

    /// Container_to_fields map related functions
    /// Clear the container_to_fields map
    void clear_container_to_fields() { container_to_fields.clear(); }
    /** Add new field to a container
      * @param f, field stored within container c
      * @param c, container to store field f
      */
    void add_container_to_field_entry(const PHV::Container c, const PHV::Field *f);
    /// @returns the set of fields assigned (partially or entirely) to @c
    const ordered_set<const PHV::Field *>& fields_in_container(const PHV::Container c) const;

    /// @returns true whenever field f is the only field present in container c
    bool is_only_field_in_container(const PHV::Container c, const PHV::Field *f) const;

    /** @returns a bitvec showing the currently allocated bits in a container
      * Note that one common bitvec is used to represent all fields that may be in a container
      * (overlaid or allocated to disjoint parts of the container)
      */
    bitvec bits_allocated(const PHV::Container c) const;
};

/**
 * @brief Create and store a PHV::Field for each header and metadata
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
 * @post This object contains a PHV::Field for each header and metadata
 * field, and a POV field for each header and metadata instance.
 */
struct CollectPhvInfo : public PassManager {
    explicit CollectPhvInfo(PhvInfo& phv);
};

void dump(const PhvInfo *);
void dump(const PHV::Field *);

std::ostream &operator<<(std::ostream &, const safe_vector<PHV::Field::alloc_slice> &);
std::ostream &operator<<(std::ostream &, const ordered_set<PHV::Field *>&);
std::ostream &operator<<(std::ostream &, const ordered_set<const PHV::Field *>&);
std::ostream &operator<<(std::ostream &, const PhvInfo &);
std::ostream &operator<<(std::ostream &, const PHV::Field_Ops &);

// These overloads must be declared directly in `namespace std` to work around
// ADL limitations for lookup of names in sibling namespaces.
namespace std {
ostream &operator<<(ostream &, const list<::PHV::Field *>&);
ostream &operator<<(ostream &, const set<const ::PHV::Field *>&);
}  // namespace std
//
#endif /* BF_P4C_PHV_PHV_FIELDS_H_ */
