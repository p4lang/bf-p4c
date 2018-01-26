#ifndef BF_P4C_PHV_UTILS_H_
#define BF_P4C_PHV_UTILS_H_

#include <boost/optional.hpp>
#include "bf-p4c/device.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"

enum class FieldKind : unsigned short {
    header   = 0,   // header fields
    metadata = 1,   // metadata fields
    pov      = 2    // POV fields, eg. $valid
};

namespace PHV {

/** A set of PHV containers of the same size. */
class ContainerGroup {
    /// The type of each container in this group.
    const PHV::Type type_i;

    /// Containers in this group.
    std::vector<PHV::Container> containers_i;

    /// IDs of containers in this group.
    bitvec ids_i;

 public:
    /** Creates a container group from a vector of containers.  Fails
     * catastrophically if @containers has containers not of type @type.
     */
    ContainerGroup(PHV::Type type, const std::vector<PHV::Container> containers);

    /** Creates a container group from a bitvec of container IDs.  Fails
     * catastrophically if @container_group has containers not of type
     * @type.
     */
    ContainerGroup(PHV::Type type, bitvec container_group);

    using const_iterator = std::vector<PHV::Container>::const_iterator;
    const_iterator begin() const { return containers_i.begin(); }
    const_iterator end()   const { return containers_i.end(); }

    /// @returns true if there are no containers in this group.
    bool empty() const { return containers_i.empty(); }

    /// @returns the number of containers in this group.
    size_t size() const { return containers_i.size(); }

    /// @returns the PHV::Type of this group.
    PHV::Type type() const { return type_i; }

    bool is(PHV::Kind k) const { return k == type_i.kind(); }
    bool is(PHV::Size s) const { return s == type_i.size(); }

    /// @returns the ids of containers in this group.
    bitvec ids() const { return ids_i; }
};

class FieldSlice {
    // There is no reason for a FieldSlice to change the field it is representing, so make this
    // const (also used in ActionPhvConstraints)
    const PHV::Field* field_i;
    le_bitrange range_i;
    boost::optional<FieldAlignment> alignment_i = boost::none;
    nw_bitrange validContainerRange_i = ZeroToMax();

 public:
    FieldSlice(const Field* field, le_bitrange range)
    : field_i(field), range_i(range) {
        BUG_CHECK(0 <= range.lo, "Trying to create field slice with negative start");
        BUG_CHECK(range.size() <= field->size, "Trying to create field slice larger than field");

        // Calculate relative alignment for this field slice.
        if (field->alignment) {
            le_bitrange field_range = StartLen(field->alignment->littleEndian, field->size);
            le_bitrange slice_range = field_range.shiftedByBits(range_i.lo)
                                                 .resizedToBits(range_i.size());
            alignment_i = FieldAlignment(slice_range);
            LOG5("Adjusting alignment of field " << field << " to " << *alignment_i <<
                 " for slice " << range); }

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
};

// XXX(cole): This duplicates PHV::Field::alloc_slice.
class AllocSlice {
    PHV::Field* field_i;
    PHV::Container container_i;
    int field_bit_lo_i;
    int container_bit_lo_i;
    int width_i;

 public:
    AllocSlice(PHV::Field* f, PHV::Container c, int f_bit_lo, int container_bit_lo, int width);
    AllocSlice(PHV::Field* f, PHV::Container c, le_bitrange f_slice, le_bitrange container_slice);

    bool operator==(const AllocSlice& other) const;
    bool operator!=(const AllocSlice& other) const;
    bool operator<(const AllocSlice& other) const;

    PHV::Field* field() const               { return field_i; }
    PHV::Container container() const        { return container_i; }
    le_bitrange field_slice() const         { return StartLen(field_bit_lo_i, width_i); }
    le_bitrange container_slice() const     { return StartLen(container_bit_lo_i, width_i); }
    int width() const                       { return width_i; }
};

// XXX(cole): Better way to structure Transactions to avoid this circular
// dependency?
class Transaction;

/** Keep track of the allocation of field slices to container slices, as well
 * as the gress assignment of containers.  Support speculative allocation and
 * rollbacks with the Transaction mechanism.
 */
class Allocation {
 public:
    using GressAssignment = boost::optional<gress_t>;
    using MutuallyLiveSlices = ordered_set<AllocSlice>;
    enum class ContainerAllocStatus { EMPTY, PARTIAL, FULL };
    struct ContainerStatus {
        GressAssignment gress;
        ordered_set<AllocSlice> slices;
        ContainerAllocStatus alloc_status;
    };
    using const_iterator = ordered_map<PHV::Container, ContainerStatus>::const_iterator;

 protected:
    using FieldStatus = ordered_set<AllocSlice>;

    SymBitMatrix mutex_i;
    ordered_map<PHV::Container, ContainerStatus> container_status_i;
    ordered_map<const PHV::Field*, FieldStatus>  field_status_i;
    ordered_map<PHV::Size, ordered_map<ContainerAllocStatus, int>> count_by_status_i;

 private:
    /// Uniform abstraction for setting container state.  For internal use
    /// only.  @c must exist in this Allocation.
    virtual void addStatus(PHV::Container c, const ContainerStatus& status);

    /// Uniform convenience abstraction for adding one slice.  For internal use
    /// only.  @c must exist in this Allocation.
    virtual void addSlice(PHV::Container c, AllocSlice slice);

    /// Uniform abstraction for setting container state.  For internal use
    /// only.  @c must exist in this Allocation.
    virtual void setGress(PHV::Container c, GressAssignment gress);

    friend class Transaction;

 public:
    /// Iterate through container-->allocation slices.
    virtual const_iterator begin() const = 0;
    virtual const_iterator end() const = 0;

    /// @returns number of containers owned by this allocation.
    virtual size_t size() const = 0;

    /// @returns true if this allocation owns @c.
    virtual bool contains(PHV::Container c) const = 0;

    /// @returns all the slices allocated to @c.
    virtual ordered_set<AllocSlice> slices(PHV::Container c) const = 0;

    /// @returns all the slices allocated to @c that overlap with @range.
    virtual ordered_set<AllocSlice> slices(PHV::Container c, le_bitrange range) const = 0;

    /** The allocation manager keeps a list of combinations of slices that are
     * live in the container at the same time, as well as the thread assignment
     * of the container (if any).  For example, suppose the following slices
     * are allocated to a container c:
     *
     *   c[0:3]<--f1[0:3]
     *   c[4:7]<--f2[0:3]
     *   c[4:7]<--f3[0:3]
     *
     * where f2 and f3 are overlaid.  There are then two sets of slices that
     * are live in the container at the same time:
     *
     *   c[0:3]<--f1[0:3]
     *   c[4:7]<--f2[0:3]
     *
     *   and
     *   
     *   c[0:3]<--f1[0:3]
     *   c[4:7]<--f3[0:3]
     *
     * When analyzing cohabit constraints, it's important to only compare
     * fields that are live.
     *
     * Note that the same slice may appear in more than one list.
     *
     * @returns the sets of slices allocated to @c that can be live at the same time.
     */
    virtual std::vector<MutuallyLiveSlices> slicesByLiveness(PHV::Container c) const;

    /** @returns a set of slices allocated to @c that are all live at the same time as @sl
      * The previous function (slicesByLiveness(c))  constructs a vector of sets of slices
      * that are live in the container at the same time; the same slice may be found in multiple
      * sets in this case. 
      * By contrast, slicesByLiveness(c, sl) uses the mutex_i member to determine all the field
      * slices that are not mutually exclusive with the candidate slice, and returns a set of all
      * such slices.
      * For example, suppose the following slices are allocated to a container c:
      *
      *   c[4:7]<--f2[0:3]
      *   c[4:7]<--f3[0:3]
      *
      * where f2 and f3 are overlaid and hence mutex_i(f2, f3) = true. If slice sl is f1[0:3], such
      * that mutex_i(f1, f2) = false and mutex_i(f1, f3) = false, a call to slicesByLiveness(c,
      * f1[0:3]) would return the set {f2[0:3], f3[0:3]}.
     */
    virtual MutuallyLiveSlices slicesByLiveness(const PHV::Container c, const AllocSlice& sl) const;
    virtual MutuallyLiveSlices slicesByLiveness(const PHV::Container c, std::vector<AllocSlice>&
            slices) const;

    /// @returns all slices allocated for @f that include any part of @range in
    /// the field portion of the allocated slice.  May be empty (if @f is not
    /// allocated) or contain slices that do not fully cover all bits of @f (if
    /// @f is only partially allocated).
    virtual ordered_set<PHV::AllocSlice> slices(const PHV::Field* f, le_bitrange range) const = 0;

    /// @returns the set of slices allocated for the field @f in this
    /// Allocation.  May be empty (if @f is not allocated) or contain slices that
    /// do not fully cover all bits of @f (if @f is only partially allocated).
    ordered_set<PHV::AllocSlice> slices(const PHV::Field* f) const {
        return slices(f, StartLen(0, f->size));
    }

    /// @returns the container status of @c and fails if @c is not present.
    virtual GressAssignment gress(PHV::Container c) const = 0;

    /// @returns the allocation status of @c and fails if @c is not present.
    virtual ContainerAllocStatus alloc_status(PHV::Container c) const = 0;

    /// @returns the number of empty containers of size @size.
    int empty_containers(PHV::Size size) const;

    /** Assign @slice to @slice.container, updating the gress information of
     * the container and its MAU group if necessary.  Fails if the gress of
     * @slice.field does not match any gress in the MAU group.
     *
     * Note that this adds new slices but does not remove or overwrite existing
     * slices.
     */
    virtual void allocate(const AllocSlice slice);

    /// @returns a pretty-printed representation of this Allocation.
    virtual cstring toString() const;

    /// @returns a summary of the status of each container by type and gress.
    virtual cstring getSummary(const PhvUse& uses) const = 0;

    /// Create a Transaction based on this Allocation.  @see PHV::Transaction for details.
    virtual Transaction makeTransaction() const;

    /// Update this allocation with any new allocation in @view.  Note that
    /// this may add new slices but does not remove or overwrite existing slices.
    void commit(Transaction& view);

    /// Pretty-print a log message summarizing the contents of PHV containers
    /// in this allocation.
    void print_occupancy() const;

    /// Utility function.
    /// @returns true if @f1 and @f2 are mutually exclusive.
    static bool mutually_exclusive(SymBitMatrix mutex, const PHV::Field *f1, const PHV::Field *f2);
};

class ConcreteAllocation : public PHV::Allocation {
    /** Create an allocation from a vector of container IDs.  Physical
     * containers that the Device pins to a particular gress are
     * initialized to that gress.
     */
    ConcreteAllocation(const SymBitMatrix&, bitvec containers);

 public:
    /** @returns an allocation initialized with the containers present in
     * Device::phvSpec, with the gress set for any hard-wired containers, but
     * no slices allocated.
     */
    explicit ConcreteAllocation(const SymBitMatrix&);

    /// Iterate through container-->allocation slices.
    const_iterator begin() const override { return container_status_i.begin(); }
    const_iterator end() const override { return container_status_i.end(); }

    /// @returns number of containers owned by this allocation.
    size_t size() const override { return container_status_i.size(); }

    /// @returns true if this allocation owns @c.
    bool contains(PHV::Container c) const override;

    /// @returns all the slices allocated to @c.
    ordered_set<AllocSlice> slices(PHV::Container c) const override;

    /// @returns all the slices allocated to @c that overlap with @range.
    ordered_set<AllocSlice> slices(PHV::Container c, le_bitrange range) const override;

    /// @returns all slices allocated for @f that include any part of @range in
    /// the field portion of the allocated slice.  May be empty (if @f is not
    /// allocated) or contain slices that do not fully cover all bits of @f (if
    /// @f is only partially allocated).
    ordered_set<PHV::AllocSlice> slices(const PHV::Field* f, le_bitrange range) const override;

    /// @returns the container status of @c and fails if @c is not present.
    GressAssignment gress(PHV::Container c) const override;

    /// @returns the allocation status of @c and fails if @c is not present.
    ContainerAllocStatus alloc_status(PHV::Container c) const override;

    /// @returns a summary of the status of each container by type and gress.
    cstring getSummary(const PhvUse& uses) const override;
};


/** A Transaction allows for speculative allocation that can later be rolled
 * back.  Writes are cached in the Transaction and merged into its parent
 * Allocation with Allocation::commit; until that point, writes are only
 * reflected in the Transaction but not its parent Allocation.
 *
 * Reads on a Transaction read values allocated to the Transaction as well as
 * those of its parent Allocation.
 *
 * Note that "writes" (i.e. calls to `allocation`) do not overwrite existing
 * allocation but rather add to it.
 */
class Transaction : public Allocation {
    const Allocation* parent_i;

 public:
    /// Constructor.  @parent cannot be null.
    Transaction(SymBitMatrix mutex, const Allocation* parent)
    : parent_i(parent) {
        BUG_CHECK(parent != nullptr, "Creating transaction with null parent");
        this->mutex_i = mutex;
        this->count_by_status_i = parent_i->count_by_status_i;
    }

    /// Iterate through container-->allocation slices.
    /// @warning not yet implemented.
    const_iterator begin() const override;

    /// Iterate through container-->allocation slices.
    /// @warning not yet implemented.
    const_iterator end() const override;

    /// @returns number of containers owned by this allocation.
    size_t size() const override { return parent_i->size(); }

    /// @returns true if this allocation owns @c.
    bool contains(PHV::Container c) const override { return parent_i->contains(c); }

    /// @returns all the slices allocated to @c.
    ordered_set<AllocSlice> slices(PHV::Container c) const override;

    /// @returns all the slices allocated to @c that overlap with @range.
    ordered_set<AllocSlice> slices(PHV::Container c, le_bitrange range) const override;

    /// @returns all slices allocated for @f that include any part of @range in
    /// the field portion of the allocated slice.  May be empty (if @f is not
    /// allocated) or contain slices that do not fully cover all bits of @f (if
    /// @f is only partially allocated).
    ordered_set<PHV::AllocSlice> slices(const PHV::Field* f, le_bitrange range) const override;

    /// @returns the container status of @c and fails if @c is not present.
    GressAssignment gress(PHV::Container c) const override;

    /// @returns the allocation status of @c and fails if @c is not present.
    ContainerAllocStatus alloc_status(PHV::Container c) const override;

    /// @returns a summary of the status of each container by type and gress.
    /// @warning not yet implemented.
    cstring getSummary(const PhvUse& uses) const override;

    /// @returns a summary of status of each container allocated in this transaction.
    cstring getTransactionSummary() const;

    /// Returns the outstanding writes in this view.
    const ordered_map<PHV::Container, ContainerStatus>& getTransactionStatus() const {
        return container_status_i;
    }

    /// Clears any allocation added to this transaction.
    void clearTransactionStatus() {
        container_status_i.clear();
        count_by_status_i = parent_i->count_by_status_i;
    }

    /// Returns the allocation that this transaction is based on.
    const Allocation* getParent() const { return parent_i; }
};

/// An interface for gathering statistics common across each kind of cluster.
class ClusterStats {
 public:
    /// @returns true if this cluster can be assigned to containers of kind
    /// @kind.
    virtual bool okIn(PHV::Kind kind) const = 0;

    /// @returns the number of slices in this container with the
    /// exact_containers constraint.
    virtual int exact_containers() const = 0;

    /// @returns the width of the widest slice in this cluster.
    virtual int max_width() const = 0;

    /// @returns the total number of constraints summed over all slices in this
    /// cluster.
    virtual int num_constraints() const = 0;

    /// @returns the sum of the widths of slices in this cluster.
    virtual size_t aggregate_size() const = 0;

    /// @returns true if this cluster contains @f.
    virtual bool contains(const PHV::Field* f) const = 0;

    /// @returns true if this cluster contains @slice.
    virtual bool contains(const PHV::FieldSlice& slice) const = 0;
};

/// The result of slicing a cluster.
template<typename Cluster>
struct SliceResult {
    using OptFieldSlice = boost::optional<PHV::FieldSlice>;
    /// Associate original field slices with new field slices.  Fields that
    /// are smaller than the slice point do not generate a hi slice.
    ordered_map<PHV::FieldSlice, std::pair<PHV::FieldSlice, OptFieldSlice>> slice_map;
    /// A new cluster containing the lower field slices.
    Cluster* lo;
    /// A new cluster containing the higher field slices.
    Cluster* hi;
};

/** An AlignedCluster groups slices that are involved in the same MAU
 * operations and, therefore, must be placed at the same alignment in
 * containers in the same MAU container group.
 *
 * For example, suppose a P4 program includes the following operations:
 *
 *      a = b + c;
 *      d = e + a;
 *
 * Fields a, b, c, d, and e must start at the same bit position and be placed
 * in the same MAU container group.
 *
 * Note that the `set` instruction (which translates to the `deposit_field` ALU
 * operation) is a special case, because `deposit_field` can optionally rotate
 * its source operand; hence, the operands do not need to be aligned.
 */
class AlignedCluster : public ClusterStats {
    /// The kind of PHV container representing the minimum requirements for all
    /// slices in this container.
    PHV::Kind kind_i;

    /// Field slices in this cluster.
    ordered_set<PHV::FieldSlice> slices_i;

    int id_i;                // this cluster's id
    int exact_containers_i;
    int max_width_i;
    int num_constraints_i;
    size_t aggregate_size_i;

    /// If any slice in the cluster needs its alignment adjusted to satisfy a
    /// PARDE constraint, then all slices do.
    boost::optional<FieldAlignment> alignment_i;

    /** Computes the range of valid lo bit positions where slices of this
     * cluster can be placed in containers of size @container_size, or
     * boost::none if no valid start positions exist or if any slice is too
     * large to fit in containers of @container_size.
     *
     * If any slice in this cluster has the `deparsed_bottom_bits` constraint,
     * then the bitrange will be [0, 0], or `boost::none` if any slice cannot
     * be started at container bit 0.
     *
     * @returns the absolute alignment constraint (if any) for all slices
     * in this cluster, or boost::none if no valid alignment exists.
     */
    boost::optional<le_bitrange> validContainerStartRange(PHV::Size container_size) const;

    /// Find valid container start range for @slice in @container_size containers.
    static boost::optional<le_bitrange> validContainerStartRange(
        PHV::FieldSlice slice,
        PHV::Size container_size);

    /// Helper function to set cluster id
    void set_cluster_id();

    /// Helper function for the constructor that analyzes the slices that make
    /// up this cluster and extracts statistics and constraints.
    void initialize_constraints();

 public:
    template <typename Iterable>
    AlignedCluster(PHV::Kind kind, Iterable slices) : kind_i(kind) {
        set_cluster_id();
        for (auto& slice : slices)
            slices_i.insert(slice);
        initialize_constraints();
    }

    /// Two aligned clusters are equivalent if they contain the same slices and
    /// can be assigned to the same kind of PHV containers.
    bool operator==(const AlignedCluster& other) const;

    /// @returns id of this cluster
    int id() const  { return id_i; }

    /// @returns true if this cluster can be assigned to containers of kind
    /// @kind.
    bool okIn(PHV::Kind kind) const override;

    /** @returns the (little Endian) byte-relative alignment constraint (if
     * any) for all slices in this cluster.
     */
    boost::optional<unsigned> alignment() const {
        if (alignment_i)
            return alignment_i->littleEndian;
        return boost::none;
    }

    /** Combines AlignedCluster::alignment() and
     * AlignedCluster::validContainerStartRange(@container_size) to compute the
     * valid lo bit positions where slices of this cluster can be placed in
     * containers of size @container_size, or boost::none if no valid start
     * positions exist or if any slice is too large to fit in containers of
     * @container_size.
     *
     * If any slice in this cluster has the `deparsed_bottom_bits` constraint,
     * then the bitvec will be [0, 0], or empty if any slice cannot be started
     * at container bit 0.
     *
     * @returns the set of bit positions at which all slices in this cluster
     * all slices can be placed, if any.
     */
    bitvec validContainerStart(PHV::Size container_size) const;

    /// Valid start positions for @slice in @container_size sized containers.
    static bitvec validContainerStart(PHV::FieldSlice slice, PHV::Size container_size);

    /// @returns the slices in this cluster.
    const ordered_set<PHV::FieldSlice>& slices() const { return slices_i; }

    using const_iterator = ordered_set<PHV::FieldSlice>::const_iterator;
    const_iterator begin() const { return slices_i.begin(); }
    const_iterator end()   const { return slices_i.end(); }

    // XXX(cole): Revisit the following stats/constraints getters.

    /// @returns the number of slices in this container with the
    /// exact_containers constraint.
    int exact_containers() const override  { return exact_containers_i; }

    /// @returns the width of the widest slice in this cluster.
    int max_width() const override          { return max_width_i; }

    /// @returns the total number of constraints summed over all slices in this
    /// cluster.
    int num_constraints() const override    { return num_constraints_i; }

    /// @returns the sum of the widths of slices in this cluster.
    size_t aggregate_size() const override  { return aggregate_size_i; }

    /// @returns true if this cluster contains @f.
    bool contains(const PHV::Field* f) const override;

    /// @returns true if this cluster contains @slice.
    bool contains(const PHV::FieldSlice& slice) const override;

    /** Slices this cluster at the relative field bit @pos.  For example, if a
     * cluster contains a field slice [3..7] and pos == 2, then `slice` will
     * produce two clusters, one with [3..4] and the other with [5..7].
     *
     * If @pos is larger than the size of a field slice in this cluster, then
     * the slice is placed entirely in the lo cluster.  If @pos is larger than
     * all field sizes, then the hi cluster will not contain any fields.
     *
     * @param pos the position to split, i.e. the first bit of the upper slice.
                  pos must be non-negative.
     * @returns a pair of (lo, hi) clusters if the cluster can be split at @pos
     *          or boost::none otherwise.
     */
    boost::optional<SliceResult<AlignedCluster>> slice(int pos) const;
};

/** A rotational cluster holds groups of clusters that must be placed in the
 * same MAU group at rotationally-equivalent alignments.
 */
class RotationalCluster : public ClusterStats {
    /// AlignedClusters that make up this RotationalCluster.
    ordered_set<AlignedCluster*> clusters_i;

    /// Map of slices to aligned clusters.
    ordered_map<const PHV::FieldSlice, AlignedCluster*> slices_to_clusters_i;

    // Statstics gathered from clusters.
    PHV::Kind kind_i;
    int exact_containers_i = 0;
    int max_width_i = 0;
    int num_constraints_i = 0;
    size_t aggregate_size_i = 0;

 public:
    explicit RotationalCluster(ordered_set<PHV::AlignedCluster*> clusters);

    /// Semantic equality.
    bool operator==(const RotationalCluster& other) const;

    /// @returns the aligned clusters in this group.
    const ordered_set<AlignedCluster*>& clusters() const { return clusters_i; }

    /// @returns the cluster containing @slice.
    /// @warning fails catastrophicaly if @slice is not in any cluster in this group.
    const AlignedCluster& cluster(const PHV::FieldSlice& slice) const {
        auto it = slices_to_clusters_i.find(slice);
        BUG_CHECK(it != slices_to_clusters_i.end(), "Field %1% not in cluster group",
                  cstring::to_cstring(slice));
        return *it->second;
    }

    /// @returns true if this cluster can be assigned to containers of kind
    /// @kind.
    bool okIn(PHV::Kind kind) const override;

    /// @returns the number of clusters in this group with the exact_containers constraint.
    int exact_containers() const override { return exact_containers_i; }

    /// @returns the width of the maximum slice in any cluster in this group.
    int max_width() const override { return max_width_i; }

    /// @returns the sum of constraints of all clusters in this group.
    int num_constraints() const override { return num_constraints_i; }

    /// @returns the aggregate size of all slices in all clusters in this group.
    size_t aggregate_size() const override { return aggregate_size_i; }

    /// @returns true if this cluster contains @f.
    bool contains(const PHV::Field* f) const override;

    /// @returns true if this cluster contains @slice.
    bool contains(const PHV::FieldSlice& slice) const override;

    /** Slices all AlignedClusters in this cluster at the relative field bit
     * @pos.  For example, if a cluster contains a field slice [3..7] and pos
     * == 2, then `slice` will produce two clusters, one with [3..4] and the
     * other with [5..7].
     *
     * If @pos is larger than the size of a field slice in this cluster, then
     * the slice is placed entirely in the lo cluster.  If @pos is larger than
     * all field sizes, then the hi cluster will not contain any fields.
     *
     * @param pos the position to split, i.e. the first bit of the upper slice.
     *            pos must be non-negative.
     * @returns a pair of (lo, hi) clusters if the cluster can be split at @pos
     *          or boost::none otherwise.
     */
    boost::optional<SliceResult<RotationalCluster>> slice(int pos) const;
};


/** A group of rotational clusters that must be placed in the same MAU group of
 * PHV containers.
 *
 * Invariants on membership:
 *  - every field slice in each slice list exists in exactly one aligned
 *    cluster, although the same slice may appear in multiple slice lists.
 *  - every aligned cluster exists in exactly one rotational cluster.
 *  - every rotational cluster exists in exactly one super cluster.
 *
 * Any attempt to place a SuperCluster into a container group will fail if:
 *  - any slice is wider than the container size.
 *  - the aggregate width of any slice list is wider than the container size.
 *
 * Slicing a SuperCluster can fail if:
 *  - a field slice would be split but has the `no_split` property.
 *  - two adjacent slices of the same field in a slice list would be split
 *    into different slice lists, but the field has the `no_split` property.
 *
 * Note that slice lists are formed from lists of header fields (among other
 * things).  In this case, the order of slices in the slice list is in little
 * Endian, but headers are often written in big Endian order, and so the order
 * in the slice list will appear reversed.  @see PHV::MakeSuperClusters in
 * make_clusters.h for more details.
 */
class SuperCluster : public ClusterStats {
 public:
    using SliceList = std::list<PHV::FieldSlice>;

 private:
    ordered_set<const RotationalCluster*> clusters_i;
    ordered_set<SliceList*> slice_lists_i;
    ordered_map<const PHV::FieldSlice, const RotationalCluster*> slices_to_clusters_i;

    // Statstics gathered from clusters.
    PHV::Kind kind_i;
    int exact_containers_i = 0;
    int max_width_i = 0;
    int num_constraints_i = 0;
    size_t aggregate_size_i = 0;

 public:
    SuperCluster(
        ordered_set<const PHV::RotationalCluster*> clusters,
        ordered_set<SliceList*> slice_lists);

    /// Semantic equality.
    bool operator==(const SuperCluster& other) const;

    /// @returns the aligned clusters in this group.
    const ordered_set<const RotationalCluster*>& clusters() const { return clusters_i; }

    /// @returns the slice lists that induced this grouping.
    const ordered_set<SliceList*>& slice_lists() const { return slice_lists_i; }

    /// @returns the rotational cluster containing @slice.
    /// @warning fails catastrophicaly if @slice is not in any cluster in this group; all slices
    ///          in every slice list are guaranteed to be present in exactly one cluster.
    const RotationalCluster& cluster(const PHV::FieldSlice& slice) const {
        auto it = slices_to_clusters_i.find(slice);
        BUG_CHECK(it != slices_to_clusters_i.end(), "Field %1% not in cluster group %2%",
                  cstring::to_cstring(slice), cstring::to_cstring(this));
        return *it->second;
    }

    /// @returns the aligned cluster containing @slice.
    /// @warning fails catastrophicaly if @slice is not in any cluster in this group; all slices
    ///          in every slice list are guaranteed to be present in exactly one cluster.
    const AlignedCluster& aligned_cluster(const PHV::FieldSlice& slice) const {
        BUG_CHECK(slices_to_clusters_i.find(slice) != slices_to_clusters_i.end(),
                  "Field %1% not in cluster group", cstring::to_cstring(slice));
        return slices_to_clusters_i.at(slice)->cluster(slice);
    }

    /// @returns true if this cluster can be assigned to containers of kind
    /// @kind.
    bool okIn(PHV::Kind kind) const override;

    /// @returns the number of clusters in this group with the exact_containers constraint.
    int exact_containers() const override { return exact_containers_i; }

    /// @returns the width of the maximum slice in any cluster in this group.
    int max_width() const override { return max_width_i; }

    /// @returns the sum of constraints of all clusters in this group.
    int num_constraints() const override { return num_constraints_i; }

    /// @returns the aggregate size of all slices in all clusters in this group.
    size_t aggregate_size() const override { return aggregate_size_i; }

    /// @returns true if this cluster contains @f.
    bool contains(const PHV::Field* f) const override;

    /// @returns true if this cluster contains @slice.
    bool contains(const PHV::FieldSlice& slice) const override;

    /// @returns true if no structural constraints prevent this super cluster
    /// from fitting.
    static bool is_well_formed(const SuperCluster* sc);
};

/** Increment @bv as if it were an unsigned integer of unbounded size. */
void inc(bitvec& bv);

/** Consider a bitvec where each bit indicates whether a field list should be
 * sliced at a corresponding 8b boundary.  Eg.
 *
 *          bv[0]    bv[1]    bv[2]
 *   |--------|--------|--------|--------|
 *
 * The following bit patterns correspond to slicing stragegies:
 *  - 000:  32b
 *  - 001:  24b /  8b               <-- invalid
 *  - 010:  16b / 16b
 *  - 011:  16b /  8b / 8b
 *  - 100:   8b / 24b               <-- invalid
 *  - 110:   8b /  8b / 16b
 *  - 111:   8b /  8b /  8b /  8b
 *
 * Adjacent 0s indicate how wide a slice will be; container-sized slices
 * correspond to no 0s, one 0, or three 0s.
 *
 * To limit the search space, this method checks the number of contiguous
 * trailing zeroes when it sets a bit; if there are two 0s, or more than three,
 * then the least signicant zeroes will be replaced with 1s, effectively
 * skipping the intervening slicings, which are destined to fail.
 *
 * For example, suppose we're incrementing 1111111:
 *
 *   after inc:                       10000000
 *   after enforce_container_sizes:   10001000
 *
 * This is the smallest number with groups of zero, one, or three zeroes.
 *
 * @param bv the bitvec of slice positions.
 *
 * @param sentinel is the size of the entire bitvec, including leading zeroes.
 * It corresponds to the bit position of a "sentinel" bit that is set to 1 when
 * all permutations of previous bit positions have been explored.
 *
 * @param boundaries marks the boundaries between slice lists.  Sequences of
 * zeroes need to be counted within (not across) boundaries.
 *
 * @param required marks required slices, i.e. bits that cannot be zero.
 *
 * @warning this mutates @bv by reference.
 */
void enforce_container_sizes(
    bitvec& bv,
    int sentinel,
    const bitvec& boundaries,
    const bitvec& required);

/** A custom forward iterator that walks through all possible slicings of a
 * SuperCluster.
 */
class SlicingIterator {
    const SuperCluster* sc_i;
    bool has_slice_lists_i;
    bitvec compressed_schemas_i;
    bitvec boundaries_i;
    bitvec required_slices_i;
    ordered_map<PHV::SuperCluster::SliceList*, le_bitrange> ranges_i;
    int sentinel_idx_i;
    std::list<PHV::SuperCluster*> cached_i;

    /// true when all possible slicings have been exhausted.  Two iterators
    /// with `done_i` set are always equal.
    bool done_i;

    /// @return a slicing based on the current value of compressed_schemas_i.
    boost::optional<std::list<PHV::SuperCluster*>> get_slices() const;

 public:
    explicit SlicingIterator(const SuperCluster* sc);

    /// @returns a list of possible slices of @sc.
    std::list<PHV::SuperCluster*> operator*() const;

    /// Increments this iterator to point to the next possible slicing of @sc.
    SlicingIterator operator++();

    /// @returns true if both iterators are over the same SuperCluster, both
    /// are done, or both have the same compressed schema value.
    bool operator==(const SlicingIterator& other) const;

    bool done() const { return done_i; }

    /// Split a SuperCluster with slice lists according to @split_schema.
    static boost::optional<std::list<PHV::SuperCluster*>> split_super_cluster(
        const PHV::SuperCluster* sc,
        ordered_map<PHV::SuperCluster::SliceList*, bitvec> split_schemas);

    /// Split the RotationalCluster in a SuperCluster without a slice list
    /// according to @split_schema.
    static boost::optional<std::list<PHV::SuperCluster*>> split_super_cluster(
        const PHV::SuperCluster* sc,
        bitvec split_schema);
};

std::ostream &operator<<(std::ostream &out, const Allocation&);
std::ostream &operator<<(std::ostream &out, const Allocation*);
std::ostream &operator<<(std::ostream &out, const FieldSlice&);
std::ostream &operator<<(std::ostream &out, const FieldSlice*);
std::ostream &operator<<(std::ostream &out, const AllocSlice&);
std::ostream &operator<<(std::ostream &out, const AllocSlice*);
std::ostream &operator<<(std::ostream &out, const ContainerGroup&);
std::ostream &operator<<(std::ostream &out, const ContainerGroup*);
std::ostream &operator<<(std::ostream &out, const AlignedCluster&);
std::ostream &operator<<(std::ostream &out, const AlignedCluster*);
std::ostream &operator<<(std::ostream &out, const RotationalCluster&);
std::ostream &operator<<(std::ostream &out, const RotationalCluster*);
std::ostream &operator<<(std::ostream &out, const SuperCluster&);
std::ostream &operator<<(std::ostream &out, const SuperCluster*);
std::ostream &operator<<(std::ostream &out, const SuperCluster::SliceList&);
std::ostream &operator<<(std::ostream &out, const SuperCluster::SliceList*);
std::ostream &operator<<(std::ostream &out, const FieldSlice&);
std::ostream &operator<<(std::ostream &out, const FieldSlice*);

}   // namespace PHV

// XXX(cole): This should go in the public repo, in `p4c/lib/ordered_set.h`.
template <typename T>
std::ostream &operator<<(std::ostream &out, const ordered_set<T>& set) {
    out << "{ ";
    unsigned count = 0U;
    for (const auto& elt : set) {
        out << elt;
        count++;
        if (count < set.size())
            out << ", "; }
    out << " }";
    return out;
}

template <typename T>
bool operator==(const ordered_set<T>& left, const ordered_set<T>& right) {
    if (left.size() != right.size())
        return false;

    for (auto& elt : left)
        if (right.find(elt) == right.end())
            return false;

    return true;
}

template <typename T>
bool operator!=(const ordered_set<T>& left, const ordered_set<T>& right) {
    return !(left == right);
}

/// Partial order for allocation status.
bool operator<(PHV::Allocation::ContainerAllocStatus, PHV::Allocation::ContainerAllocStatus);
bool operator<=(PHV::Allocation::ContainerAllocStatus, PHV::Allocation::ContainerAllocStatus);
bool operator>(PHV::Allocation::ContainerAllocStatus, PHV::Allocation::ContainerAllocStatus);
bool operator>=(PHV::Allocation::ContainerAllocStatus, PHV::Allocation::ContainerAllocStatus);

#endif  /* BF_P4C_PHV_UTILS_H_ */
