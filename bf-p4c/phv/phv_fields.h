#ifndef BF_P4C_PHV_PHV_FIELDS_H_
#define BF_P4C_PHV_PHV_FIELDS_H_

#include <boost/optional.hpp>
#include <boost/range/irange.hpp>
#include <limits>

#include "bf-p4c/device.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/phv/field_alignment.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"
#include "lib/safe_vector.h"
#include "lib/symbitmatrix.h"

namespace PHV {

class FieldSlice;

enum class FieldKind : unsigned short {
    header   = 0,   // header fields
    metadata = 1,   // metadata fields
    pov      = 2    // POV fields, eg. $valid
};

enum class FieldAccessType { NONE = 0, R = 1, W = 2, RW = 3 };

struct FieldOperation {
    bool is_bitwise_op;
    bool is_salu_inst;
    const IR::MAU::Instruction *inst;
    FieldAccessType rw_type;
    le_bitrange range;  // If range.size() == this->size, then the operation is
                        // over the whole field.
    FieldOperation(
        bool is_bitwise_op,
        bool is_salu_inst,
        const IR::MAU::Instruction* inst,
        FieldAccessType rw_type,
        le_bitrange range)
        : is_bitwise_op(is_bitwise_op), is_salu_inst(is_salu_inst),
          inst(inst), rw_type(rw_type), range(range) { }
};

class Field {
 public:
    /// This suffix is added to the name of the privatized (TPHV) copy of a field.
    static constexpr char const *TPHV_PRIVATIZE_SUFFIX = "$tphv";
    static constexpr char const *DARK_PRIVATIZE_SUFFIX = "$dark";

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

    /// returns @true if the Field is a ghost field.
    /// XXX(Deep): Right now, ghost fields are marked as ingress fields, so we use string comparison
    /// for this method. Ideally, we should use the gress member directly and not have a separate
    /// ghost field.
    bool isGhostField() const { return name.startsWith("ghost::"); }

    /// Total size of Field in bits.
    int             size;

    /// The alignment requirement of this field. If boost::none, there is no
    /// particular alignment requirement.
    boost::optional<FieldAlignment> alignment;

    /// @see Field::validContainerRange().
    nw_bitrange validContainerRange_i = ZeroToMax();

    /// Offset of lsb from lsb (last) bit of containing header.
    int             offset;

    /// True if this Field is metadata.
    bool            metadata;

    /// True if this Field is metadata bridged from ingress to egress.
    bool            bridged = false;

    /// True if this Field can always be packed with other fields. Used for padding fields for
    /// bridged metadata.
    bool            alwaysPackable = false;

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


    /// Represents an allocation of a field slice to a container slice.
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
            return !operator==(other); }
    };


    /// Sets the valid starting bit positions (little Endian) for this field.
    /// For example, setStartBits(PHV::Size::b8, bitvec(0,1)) means that the least
    /// significant bit of this field must start at bit 0 in 8b containers.
    void setStartBits(PHV::Size size, bitvec startPositions);

    /// @return the bit positions (little Endian) at which the least significant
    /// bit of this field may be placed.
    bitvec getStartBits(PHV::Size size) const;

    /// @returns the header to which this field belongs.
    cstring header() const { return name.before(strrchr(name, '.')); }

 private:
    /// When set, use this name rather than PHV::Field::name when generating
    /// assembly.
    boost::optional<cstring> externalName_i;

    // constraints on this field
    //
    bool            mau_phv_no_pack_i = false;         /// true if op on field not "move based"
                                                       /// set by PHV_Field_Operations
    bool            deparsed_i = false;                /// true if deparsed field
    bool            no_pack_i = false;                 /// prevents field from being placed in a
                                                       /// container with any other field
    bool            deparsed_bottom_bits_i = false;    /// true when learning digest, no shifter
    bool            exact_containers_i = false;        /// place in container exactly (no holes)

    bool            deparsed_to_tm_i = false;          /// true if field is read by TM
    size_t          numNoPack = 0;                     /// Number of fields with which this field
                                                       /// cannot be packed

    bool            privatizable_i = false;            /// true for the PHV version of a
                                                       /// privatized field
    bool            privatized_i = false;              /// true for the TPHV version of a
                                                       /// privatized field
    bool            is_checksummed_i = false;          /// true for fields used in checksum.
    bool            is_digest_i = false;               /// true for fields used in digest.
    bool            mocha_i = false;                   /// true if field is a candidate for mocha
                                                       /// PHV.
    bool            dark_i = false;                    /// true if field is a candidate for dark
                                                       /// PHV.
    bool            deparser_zero_i = false;           /// true if the field is a candidate for the
                                                       /// deparser zero optimization.
#if HAVE_JBAY
    /// XXX(Deep): Until we move to a stage-based allocation that allows us to move fields into and
    /// out of dark containers, the utilization of dark containers in JBay is not significant. To
    /// address this and enable testing, I am introducing a privatizable dark category of fields.
    /// These fields satisfy all the requirements for dark containers, except that they are used in
    /// the parser/deparser. So, we create two versions of such a field--the normal/mocha version
    /// which is involved in the parde operations and the privatized dark version. The
    /// privatizable_dark_i property is set to true for all mocha fields that could be allocated
    /// into dark containers with dark privatization.
    bool            privatizable_dark_i = false;
#endif

    /// Ranges of this field that can not be split.
    /// E.g. in a<32b> = b<32b> + c[0:31]<48b>, [0:31] will be the no_split range for c.
    /// you can create a fieldslice for c as long as it
    /// does not split c[0:31]. E.g. c[32:47] is allowed, but c[15:31] is not.
    std::vector<le_bitrange> no_split_ranges_i;

    /** Marshaled fields are metadata fields serialized between a Tofino deparser and parser.
     *  For example, mirrored field lists can be serialized from ingress deparser (when the mirrored
     *  header is being created) to the ingress parser (when the mirrored header is being processed).
     *
     *  Marshaled fields differ from deparsed fields (i.e. the `deparsed_i` constraint) in that they
     *  are not emitted on the wire.
     *
     *  XXX(yumin): Currently, only mirrored field lists are marked as marshaled, but the same
     *  mechanism can be used for learning, recirculation, and bridged metadata.
     **/
    bool            is_marshaled_i = false;

    /// true if hardware read the container validity bit, e.g. deparser paramerter, digest index
    bool            read_container_valid_bit_i = false;

    /// MAU operations performed on this field.
    safe_vector<FieldOperation> operations_i;

    /// Maps slices of @this field to PHV containers.  Sorted by field MSB
    /// first.
    safe_vector<alloc_slice> alloc_i;

    friend std::ostream &operator<<(std::ostream &out, const Field &field);

 public:
    /// @returns true if this field can be placed in TPHV containers.
    bool is_tphv_candidate(const PhvUse& uses) const;
    bool is_mocha_candidate() const                        { return mocha_i; }
    bool is_dark_candidate() const                         { return dark_i; }
    bool is_deparser_zero_candidate() const                { return deparser_zero_i; }
    void set_mocha_candidate(bool c)                       { mocha_i = c; }
    void set_dark_candidate(bool c)                        { dark_i = c; }
    void set_deparser_zero_candidate(bool c)               { deparser_zero_i = c; }

#if HAVE_JBAY
    bool is_privatizable_dark() const                      { return privatizable_dark_i; }
    void set_privatizable_dark(bool c)                     { privatizable_dark_i = c; }
#endif

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

    bool no_split() const;
    void set_no_split(bool b);
    bool no_split_at(int pos) const;
    void set_no_split_at(le_bitrange range);
    std::vector<le_bitrange> no_split_ranges() const       { return no_split_ranges_i; }

    bool deparsed_to_tm() const                            { return deparsed_to_tm_i; }
    void set_deparsed_to_tm(bool b)                        { deparsed_to_tm_i = b; }

    bool read_container_valid_bit() const                  { return read_container_valid_bit_i; }
    void set_read_container_valid_bit(bool b)              { read_container_valid_bit_i = b; }
    bool is_marshaled() const                              { return is_marshaled_i; }
    void set_is_marshaled(bool b)                          { is_marshaled_i = b; }

    bool privatizable() const                              { return privatizable_i; }
    void set_privatizable(bool b)                          { privatizable_i = b; }
    bool privatized() const                                { return privatized_i; }
    void set_privatized(bool b)                            { privatized_i = b; }
    bool is_checksummed() const                            { return is_checksummed_i; }
    void set_is_checksummed(bool b)                        { is_checksummed_i = b; }
    bool is_digest() const                                 { return is_digest_i; }
    void set_is_digest(bool b)                             { is_digest_i = b; }

    // @returns the set of MAU operations on this field.
    const safe_vector<FieldOperation>& operations() const   { return  operations_i; }

    // @returns the set of MAU operations on this field.
    safe_vector<FieldOperation>& operations()               { return  operations_i; }

    void set_num_pack_conflicts(size_t no)                 { numNoPack = no; }

    size_t num_pack_conflicts() const                      { return numNoPack; }

    bool constrained(bool packing_constraint = false) const;

    /// @returns true if this field is a packet field.
    bool isPacketField() const {
        return (!metadata && !pov);
    }

    /// Apply @fn to each byte-sized subslice of the slice @range of @this
    /// field, starting at bit @range.lo.  If @range is not a byte multiple,
    /// then the last slice will be smaller than 8 bits.
    void foreach_byte(le_bitrange range, std::function<void(const FieldSlice &)> fn) const;

    /** Equivalent to `foreach_byte(StartLen(0, this->size), fn)`.
     *
     * @see foreach_byte(le_bitrange, std::function<void(const FieldSlice &)>).
     */
    void foreach_byte(std::function<void(const FieldSlice &)> fn) const {
        foreach_byte(StartLen(0, this->size), fn);
    }

    /// @returns the alloc_slice in which field @bit is allocated.  Fails
    /// catastrophically if @bit is not allocated or not within the range of
    /// @this field's size.
    const alloc_slice &for_bit(int bit) const;

    /** For each byte-aligned container byte of each allocated slice of this
     * field, construct an alloc_slice representing that allocated byte (or
     * fraction thereof) and apply @fn to it, BUT ONLY if the container is NOT
     * a TPHV container.
     *
     *  For example, suppose a 16b field (f) is allocated as follows:
     *
     *  C8 [4:0]     <— f [15:11]
     *  C8 [7:7]     <— f [10:10]
     *  C16 [9:0]    <— f [9:0]
     *
     *  Where C8 is an 8b container and C16 is a 16b container.
     *
     *  Invoking `f->foreach_byte(1, 14, fn)` should invoke fn on the following alloc_slices (in this order):
     *
     *  C16 [7:1]    <— f [7:1]
     *  C16 [9:8]    <— f [9:8]
     *  C8 [7:7]    <— f [10:10]
     *  C8 [3:0]    <— f [14:11]
     */
    void foreach_byte(le_bitrange r, std::function<void(const alloc_slice &)> fn) const;

    /** Equivalent to `foreach_byte(*r, fn)`, or `foreach_byte(StartLen(0,
     * this->size), fn)` when @r is null.
     *
     * @see foreach_byte(le_bitrange, std::function<void(const alloc_slice&)>).
     */
    void foreach_byte(const le_bitrange *r, std::function<void(const alloc_slice &)> fn) const {
        foreach_byte(r ? *r : StartLen(0, this->size), fn);
    }

    /** Equivalent to `foreach_byte(StartLen(0, this->size), fn)`.
     *
     * @see foreach_byte(le_bitrange, std::function<void(const alloc_slice&)>).
     */
    void foreach_byte(std::function<void(const alloc_slice &)> fn) const {
        foreach_byte(StartLen(0, this->size), fn);
    }

    /// Apply @fn to each alloc_slice to which @this has been allocated (if any).
    void foreach_alloc(le_bitrange r, std::function<void(const alloc_slice &)> fn) const;

    /** Equivalent to `foreach_alloc(StartLen(0, this->size), fn)`.
     *
     * @see foreach_alloc(le_bitrange, std::function<void(const alloc_slice &)>).
     */
    void foreach_alloc(std::function<void(const alloc_slice &)> fn) const {
        foreach_alloc(StartLen(0, this->size), fn);
    }

    /** Equivalent to `foreach_alloc(StartLen(0, this->size), fn)`, or to
     * `foreach_alloc(fn)` when @r is null.
     *
     * @see foreach_alloc(le_bitrange, std::function<void(const alloc_slice &)>).
     */
    void foreach_alloc(const le_bitrange *r, std::function<void(const alloc_slice &)> fn) const {
        foreach_alloc(r ? *r : StartLen(0, this->size), fn);
    }

    /// @returns the number of distinct container bytes that contain slices of
    /// the @bits of this field.
    int container_bytes(boost::optional<le_bitrange> bits = boost::none) const;

    /// Clear any PHV allocation for this field.
    void clear_alloc() { alloc_i.clear(); }

    /// Allocate a slice of this field.
    void add_alloc(const Field* f, PHV::Container c, int fb, int cb, int w) {
        alloc_i.emplace_back(f, c, fb, cb, w);
    }

    /// Allocate a slice of this field.
    void add_alloc(const alloc_slice& alloc) {
        alloc_i.push_back(alloc);
    }

    /// Set all allocated slices of this field.
    void set_alloc(const safe_vector<PHV::Field::alloc_slice>& alloc) {
        alloc_i = alloc;
    }

    /// @returns the PHV allocation for this field, if any.
    const safe_vector<PHV::Field::alloc_slice>& get_alloc() const {
        return alloc_i;
    }

    /// @returns the number of allocated slices of this field.
    size_t alloc_size() const { return alloc_i.size(); }

    /// @returns true if there are no allocated slices of this field.
    bool is_unallocated() const { return alloc_i.empty(); }

    /// Sort by field MSB.
    void sort_alloc() {
        std::sort(alloc_i.begin(), alloc_i.end(),
            [](PHV::Field::alloc_slice l, PHV::Field::alloc_slice r) {
                return l.field_bit > r.field_bit; });
    }

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


    /// If a field is privatized (TPHV copy of header field), @returns the name of the PHV field
    /// (name of the privatized field less the PHV::Field::TPHV_PRIVATIZE_SUFFIX).
    /// If field is not privatized, return empty string.
    boost::optional<cstring> getPHVPrivateFieldName() const {
        if (!privatized_i) return boost::none;
        size_t strLength = name.size();
        LOG1("Length of suffix: " << strLength);
        // Ignore PHV::Field::TPHV_PRIVATIZE_SUFFIX
        strLength -= strlen(PHV::Field::TPHV_PRIVATIZE_SUFFIX);
        return name.substr(0, strLength);
    }

    /// @returns the name of the privatized copy (TPHV copy) of the field.
    boost::optional<cstring> getTPHVPrivateFieldName() const {
        if (!privatizable_i) return boost::none;
        cstring tphvName = name + TPHV_PRIVATIZE_SUFFIX;
        return tphvName;
    }

    /// Get the external name of this field.  If PHV::Field::externalName is
    /// not boost::none, use that; otherwise, use PHV::Field::name.
    cstring externalName() const {
        return boost::get_optional_value_or(externalName_i, name);
    }

    /// @returns true if this field as an external name set independently of
    /// its name.
    bool hasExternalName() const {
        return externalName_i != boost::none;
    }

    /// Set the external name of this field, which will be used in place of
    /// PHV::Field::name when generating assembly.
    void setExternalName(cstring name) {
        externalName_i = name;
    }

    /// Clear the external name, if any has been set.
    void clearExternalName() {
        externalName_i = boost::none;
    }

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
     * XXX(cole): This range always starts at 0, which is an invariant that
     * other parts of the compiler rely on.
     */
    nw_bitrange validContainerRange() const {
        return validContainerRange_i;
    }

 private:
    /// Marks the valid starting bit positions (little Endian) for this field.
    /// Valid bit positions may vary depending on container size.

    // TODO(cole): This is currently only used for SALU operands.  However,
    // it's general enough to support bit-in-byte alignment requirements
    // (alignment_i), valid container range requirements, and deparsed_to_tm.
    std::map<PHV::Size, bitvec> startBitsByContainerSize_i;

 public:
    Field() {
        for (auto size : Device::phvSpec().containerSizes())
            startBitsByContainerSize_i[size] = bitvec(0, int(size));
    }
};

/** Represents a slice (range of bits) of a PHV::Field.  Constraints on the
 * field that are related to position, like alignment, are tailored for
 * each slice.
 */
class FieldSlice {
    // There is no reason for a FieldSlice to change the field it is representing, so make this
    // const (also used in ActionPhvConstraints)
    const PHV::Field* field_i;
    le_bitrange range_i;
    boost::optional<FieldAlignment> alignment_i = boost::none;
    nw_bitrange validContainerRange_i = ZeroToMax();

    /// Marks the valid starting bit positions (little Endian) for this field.
    /// Valid bit positions may vary depending on container size.

    // TODO(cole): This is currently only used for SALU operands.  However,
    // it's general enough to support bit-in-byte alignment requirements
    // (alignment_i), valid container range requirements, and deparsed_to_tm.
    std::map<PHV::Size, bitvec> startBitsByContainerSize_i;

 public:
    FieldSlice(const Field* field, le_bitrange range) : field_i(field), range_i(range) {
        BUG_CHECK(0 <= range.lo, "Trying to create field slice with negative start");
        BUG_CHECK(range.size() <= field->size,
                  "Trying to create field slice larger than field");

        // Calculate relative alignment for this field slice.
        if (field->alignment) {
            le_bitrange field_range = StartLen(field->alignment->littleEndian, field->size);
            le_bitrange slice_range = field_range.shiftedByBits(range_i.lo)
                                                 .resizedToBits(range_i.size());
            alignment_i = FieldAlignment(slice_range);
            LOG5("Adjusting alignment of field " << field << " to " << *alignment_i <<
                 " for slice " << range); }

        // The valid starting bits (by container size C) for a slice s[Y:X]
        // equal the valid bits for the field shifted by X mod C.  For example,
        // if a 12b field f can start at bits 0 and 8 in a 16b container, then
        // f[11:8] can start at bits 0 and 8.
        for (auto size : Device::phvSpec().containerSizes())
            for (auto idx : field->getStartBits(size))
                startBitsByContainerSize_i[size].setbit((idx + range.lo) % int(size));

        // Calculate valid container range for this slice by shrinking
        // the valid range of the field by the size of the "tail"
        // (i.e. the least significant bits) not in this slice.
        if (field_i->validContainerRange_i == ZeroToMax()) {
            validContainerRange_i = ZeroToMax();
        } else {
            int new_size = field_i->validContainerRange_i.size() - range.lo;
            validContainerRange_i = field_i->validContainerRange_i.resizedToBits(new_size); }
    }

    /// Create a slice that holds the entirety of @field.
    explicit FieldSlice(const Field* field)
    : FieldSlice(field, le_bitrange(StartLen(0, field->size))) { }

    /// Creates a subslice of @slice from @range.lo to @range.hi.
    FieldSlice(FieldSlice slice, le_bitrange range) : FieldSlice(slice.field(), range) {
        BUG_CHECK(slice.range().contains(range),
                  "Trying to create field sub-slice larger than the original slice");
    }

    bool operator==(const FieldSlice& other) const {
        return field_i == other.field() && range_i == other.range();
    }

    bool operator!=(const FieldSlice& other) const {
        return !(*this == other);
    }

    bool operator<(const FieldSlice& other) const {
        if (field_i != other.field())
            return field_i < other.field();
        if (range_i.lo != other.range().lo)
            return range_i.lo < other.range().lo;
        return range_i.hi < other.range().hi;
    }

    /// Whether the Field is ingress or egress.
    gress_t gress() const { return field_i->gress; }

    /// Total size of FieldSlice in bits.
    int size() const { return range_i.size(); }

    /// The alignment requirement of this field slice. If boost::none, there is
    /// no particular alignment requirement.
    boost::optional<FieldAlignment> alignment() const { return alignment_i; }

    /// See documentation for `Field::validContainerRange()`.
    /// TODO(cole): Refactor this.
    nw_bitrange validContainerRange() const { return validContainerRange_i; }

    /// Kind of field of this slice.
    FieldKind kind() const {
        // XXX(cole): PHV::Field::metadata and PHV::Field::pov should be
        // replaced by FieldKind.
        if (field_i->pov)
            return FieldKind::pov;
        else if (field_i->metadata)
            return FieldKind::metadata;
        else
            return FieldKind::header;
    }

    /// @returns the field this is a slice of.
    const PHV::Field* field() const   { return field_i; }

    /// @returns the bits of the field included in this field slice.
    le_bitrange range() const   { return range_i; }

    /// Sets the valid starting bit positions (little Endian) for this field.
    /// For example, setStartBits(PHV::Size::b8, bitvec(0,1)) means that the least
    /// significant bit of this field must start at bit 0 in 8b containers.
    void setStartBits(PHV::Size size, bitvec startPositions);

    /// @returns the bit positions (little Endian) at which the least significant
    /// bit of this field may be placed.
    bitvec getStartBits(PHV::Size size) const;
};

std::ostream &operator<<(std::ostream &out, const Field &);
std::ostream &operator<<(std::ostream &out, const Field *);
std::ostream &operator<<(std::ostream &, const Field::alloc_slice &);
std::ostream &operator<<(std::ostream &, const std::vector<Field::alloc_slice> &);

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

    /// Stores the mutual exclusion relationships between different PHV fields
    SymBitMatrix&                            field_mutex;

    const SymBitMatrix& mutex() const { return field_mutex; }

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

    /// Mapping from containers to the fields using those containers.
    std::map<PHV::Container, ordered_set<const PHV::Field *>> container_to_fields;

    /// the dummy padding field names.
    ordered_set<cstring> dummyPaddingNames;

    /// Mapping of alias source to alias destination. Used for building the correct table dependency
    /// graph.
    ordered_map<const PHV::Field*, const PHV::Field*> aliasMap;

    /// Mapping of external name to Field pointers, for fields that have a different external
    /// name.
    ordered_map<cstring, PHV::Field*> externalNameMap;

    bool                                alloc_done_ = false;
    bool                                pov_alloc_done = false;

    /// Set of containers that must be set to 0 (and their container validity bit set
    /// unconditionally to 1) for the deparsed zero optimization.
    std::set<PHV::Container>    zeroContainers;

    void clear();
    void add(cstring fieldName, gress_t gress, int size, int offset,
             bool isMetadata, bool isPOV, bool bridged = false, bool isPad = false);
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

    friend class ClearPhvInfo;
    friend class CollectPhvFields;
    friend struct AllocatePOVBits;
    friend struct MarkBridgedMetadataFields;

    /** Add a 1-bit "hdr.$valid" field for each simple header.  For each header stack, add:
     *  - A "stack[x].$valid" field for each stack element.
     *  - A "stack.$push" field if the push_front primitive is used.
     *  - A "stack.$pop" field if the pop_front primitive is used.
     *  - A "stack.$stkvalid" field.
     *
     * @pre CollectHeaderStackInfo and CollectPhvFields.
     * @post POV fields for all headers added to PhvInfo.
     */
    void allocatePOV(const BFN::HeaderStackInfo&);

 public:  // class PhvInfo
    explicit PhvInfo(SymBitMatrix& m) : field_mutex(m) {}

    const PHV::Field *field(int idx) const {
        return size_t(idx) < by_id.size() ? by_id.at(idx) : 0; }
    const PHV::Field *field(const cstring&) const;
    const PHV::Field *field(const IR::Expression *, le_bitrange *bits = 0) const;
    const PHV::Field *field(const IR::Member *, le_bitrange *bits = 0) const;
    PHV::Field *field(int idx) {
        return (size_t)idx < by_id.size() ? by_id.at(idx) : 0; }
    PHV::Field *field(const cstring& name) {
        return const_cast<PHV::Field *>(const_cast<const PhvInfo *>(this)->field(name)); }
    PHV::Field *field(const IR::Expression *e, le_bitrange *bits = 0) {
        return const_cast<PHV::Field *>(const_cast<const PhvInfo *>(this)->field(e, bits)); }
    PHV::Field *field(const IR::Member *fr, le_bitrange *bits = 0) {
        return const_cast<PHV::Field *>(const_cast<const PhvInfo *>(this)->field(fr, bits)); }
    const StructInfo struct_info(cstring name) const;
    const StructInfo struct_info(const IR::HeaderRef *hr) const {
        return struct_info(hr->toString()); }
    const std::map<cstring, PHV::Field>& get_all_fields() const { return all_fields; }
    size_t num_fields() const { return all_fields.size(); }

    PHV::Field* create_dummy_padding(size_t sz, gress_t gress) {
        cstring name = cstring::make_unique(dummyPaddingNames, "__phv_dummy_padding__");
        dummyPaddingNames.insert(name);
        add(name, gress, sz, 0, false, false, false, /* isPad = */ true);
        return field(name);
    }

    std::vector<PHV::Field::alloc_slice> get_alloc(const IR::Expression* f) const {
        CHECK_NULL(f);
        auto* phv_field = field(f);
        BUG_CHECK(phv_field, "No PHV field for expression %1%", f);
        return get_alloc(phv_field);
    }

    std::vector<PHV::Field::alloc_slice> get_alloc(const PHV::Field* phv_field) const {
        std::vector<PHV::Field::alloc_slice> slices;

        phv_field->foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            slices.push_back(alloc);
        });

        return slices;
    }

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

    /** @returns a bitvec showing all potentially allocated bits within a container
     */
    bitvec bits_allocated(const PHV::Container) const;

    /** @returns a bitvec showing the currently allocated bits in a container corresponding to
      * fields simultaneously live with the fields passed in the argument set.
      * Note that one common bitvec is used to represent all fields that may be in a container
      */
    bitvec bits_allocated(const PHV::Container, const ordered_set<const PHV::Field*>&) const;

    /** @returns the alias source name, if the given expression is either a IR::BFN::AliasMember type
      * or is a slice with a IR::BFN::AliasMember object as the underlying base expression.
      * @returns boost::none otherwise.
      */
    boost::optional<cstring> get_alias_name(const IR::Expression* expr) const;

    /// Adds an entry to the aliasMap.
    void addAliasMapEntry(const PHV::Field* f1, const PHV::Field* f2) {
        if (aliasMap.count(f1))
            BUG_CHECK(aliasMap[f1] == f2, "Multiple aliases with the same field found");
        aliasMap[f1] = f2;
    }

    /// Adds an entry to the externalNameMap.
    void addExternalNameMapEntry(PHV::Field* f, cstring externalName) {
        externalNameMap[externalName] = f;
    }

    /// @returns the aliasMap.
    const ordered_map<const PHV::Field*, const PHV::Field*>& getAliasMap() const {
        return aliasMap;
    }

    /// @returns the set of deparsed zero containers.
    const std::set<PHV::Container>& getZeroContainers() const {
        return zeroContainers;
    }

    /// adds container @c to the set of deparsed zero containers.
    void addZeroContainer(PHV::Container c) {
        zeroContainers.insert(c);
        BUG_CHECK(zeroContainers.size() <= 2,
                  "Only two zero containers allowed: one for each gress");
    }
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

/**
  * @brief Create allocation objects (PHV::Field::alloc_slice) for alias source fields in
  * preparation for assembly output
  * @pre PhvAnalysis_Pass has been run so that allocation objects are available.
  */
class AddAliasAllocation : public Inspector {
    PhvInfo& phv;
    ordered_set<const PHV::Field*> seen;

    /// Set @source allocation to that of the @range of @dest.  The size of
    /// @range must match the size of @source.
    void addAllocation(PHV::Field* source, const PHV::Field* dest, le_bitrange range);

    profile_t init_apply(const IR::Node* root) override {
        seen.clear();
        return Inspector::init_apply(root);
    }
    bool preorder(const IR::BFN::AliasMember*) override;
    bool preorder(const IR::BFN::AliasSlice*) override;
    void end_apply() override;

 public:
    explicit AddAliasAllocation(PhvInfo& p) : phv(p) { }
};

/** For bridged metadata fields, the field's external name is different from the name of the field.
  * We populate the externalNameMap in PhvInfo for such entries to enable lookup of Field objects
  * using the external name. This is mandatory for supporting pragmas, as pragmas on bridged fields
  * are specified on the external name (and not the bridged name internally used in the backend).
  */
class GatherExternalNames : public Inspector {
    PhvInfo& phv_i;

    void end_apply() {
        for (auto& f : phv_i) {
            if (!f.hasExternalName()) continue;
            phv_i.addExternalNameMapEntry(&f, f.externalName());
            LOG3("Setting externalNameMap for " << f.name << " to " << f.externalName());
        }
    }

 public:
    explicit GatherExternalNames(PhvInfo& phv) : phv_i(phv) { }
};

void dump(const PhvInfo *);
void dump(const PHV::Field *);

std::ostream &operator<<(std::ostream &, const safe_vector<PHV::Field::alloc_slice> &);
std::ostream &operator<<(std::ostream &, const ordered_set<PHV::Field *>&);
std::ostream &operator<<(std::ostream &, const ordered_set<const PHV::Field *>&);
std::ostream &operator<<(std::ostream &, const PhvInfo &);
std::ostream &operator<<(std::ostream &, const PHV::FieldAccessType &);

namespace PHV {

std::ostream &operator<<(std::ostream &, const PHV::FieldSlice &sl);
std::ostream &operator<<(std::ostream &, const PHV::FieldSlice *sl);

}   // namespace PHV

// These overloads must be declared directly in `namespace std` to work around
// ADL limitations for lookup of names in sibling namespaces.
namespace std {
ostream &operator<<(ostream &, const list<::PHV::Field *>&);
ostream &operator<<(ostream &, const set<const ::PHV::Field *>&);
}  // namespace std
//
#endif /* BF_P4C_PHV_PHV_FIELDS_H_ */
