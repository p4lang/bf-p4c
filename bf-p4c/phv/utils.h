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
    PHV::Field* field_i;
    le_bitrange range_i;

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

    /// Kind of this field.
    FieldKind kind;

    /// True if this Field is metadata bridged from ingress to egress.
    bool            bridged = false;

 public:
    FieldSlice(Field* field, le_bitrange range) : field_i(field), range_i(range) {
        BUG_CHECK(0 <= range.lo, "Trying to create field slice with negative start");
        BUG_CHECK(range.size() <= field->size, "Trying to create field slice larger than field");

        // TODO(cole): Not yet implemented.  Need to initialize field slice
        // members by interpreting its parent field members/constraints.
        P4C_UNIMPLEMENTED("FieldSlice NYI");
    }
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
    using ContainerStatus = struct { GressAssignment gress; ordered_set<AllocSlice> slices; };
    using const_iterator = ordered_map<PHV::Container, ContainerStatus>::const_iterator;

 protected:
    using FieldStatus = ordered_set<AllocSlice>;

    SymBitMatrix mutex_i;
    ordered_map<PHV::Container, ContainerStatus> container_status_i;
    ordered_map<const PHV::Field*, FieldStatus>  field_status_i;

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
    virtual cstring getSummary() const = 0;

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

    /// @returns a summary of the status of each container by type and gress.
    cstring getSummary() const override;
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
    const Allocation& parent_i;

 public:
    Transaction(SymBitMatrix mutex, const Allocation& parent)
    : parent_i(parent) { this->mutex_i = mutex; }

    /// Iterate through container-->allocation slices.
    /// @warning not yet implemented.
    const_iterator begin() const;

    /// Iterate through container-->allocation slices.
    /// @warning not yet implemented.
    const_iterator end() const;

    /// @returns number of containers owned by this allocation.
    size_t size() const { return parent_i.size(); }

    /// @returns true if this allocation owns @c.
    bool contains(PHV::Container c) const { return parent_i.contains(c); }

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
    GressAssignment gress(PHV::Container c) const;

    /// @returns a summary of the status of each container by type and gress.
    /// @warning not yet implemented.
    cstring getSummary() const;

    /// Returns the outstanding writes in this view.
    const ordered_map<PHV::Container, ContainerStatus>& getTransactionStatus() const {
        return container_status_i;
    }

    /// Clears any allocation added to this transaction.
    void clearTransactionStatus() { container_status_i.clear(); }
};

/// An interface for gathering statistics common across each kind of cluster.
class ClusterStats {
 public:
    /// @returns true if this cluster can be assigned to containers of kind
    /// @kind.
    virtual bool okIn(PHV::Kind kind) const = 0;

    /// @returns the number of fields in this container with the
    /// exact_containers constraint.
    virtual int exact_containers() const = 0;

    /// @returns the width of the widest field in this cluster.
    virtual int max_width() const = 0;

    /// @returns the total number of constraints summed over all fields in this
    /// cluster.
    virtual int num_constraints() const = 0;

    /// @returns the sum of the widths of fields in this cluster.
    virtual size_t aggregate_size() const = 0;

    /// @returns true if this cluster contains @f.
    virtual bool contains(const PHV::Field* f) const = 0;
};

/** An AlignedCluster groups fields that are involved in the same MAU
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
 * XXX(cole): This is currently over-constrained, in that fields that are
 * involved in set operations are required to be at the same alignment when
 * they only need to be rotationally equivalent.  The fix is to introduce a
 * RotationalSupercluster that holds AlignedClusters that must be rotationally
 * aligned; this also requires updating cluster formation to exclude set
 * instructions, and then in a later pass form RotationalClusters as UnionFind
 * over operands of set instructions.
 */
class AlignedCluster : public ClusterStats {
    /// The kind of PHV container representing the minimum requirements for all
    /// fields in this container.
    PHV::Kind kind_i;

    /// Fields in this cluster.
    ordered_set<PHV::Field *> fields_i;

    int id_i;                // this cluster's id
    int exact_containers_i;
    int max_width_i;
    int num_constraints_i;
    size_t aggregate_size_i;

    /// If any field in the cluster needs its alignment adjusted to satisfy a
    /// PARDE constraint, then all fields do.
    boost::optional<unsigned> alignment_i;

    /** Computes the range of valid lo bit positions where fields of this
     * cluster can be placed in containers of size @container_size, or
     * boost::none if no valid start positions exist or if any field is too
     * large to fit in containers of @container_size.
     *
     * If any field in this cluster has the `deparsed_bottom_bits` constraint,
     * then the bitrange will be [0, 0], or `boost::none` if any field cannot
     * be started at container bit 0.
     *
     * @returns the absolute alignment constraint (if any) for all fields
     * in this cluster, or boost::none if no valid alignment exists.
     */
    boost::optional<le_bitrange>
    validContainerStartRange(PHV::Size container_size) const;

    // XXX(cole): This will replace validContainerStartRange() after cluster
    // slicing.  This is simpler, in that it returns false if the field can't
    // fit in the container at a valid offset, i.e. if any field in the cluster
    // is too large for the contianer.
    boost::optional<le_bitrange>
    validContainerStartRangeAfterSlicing(PHV::Size container_size) const;

    /// Helper function to set cluster id
    void set_cluster_id();

    /// Helper function for the constructor that analyzes the fields that make
    /// up this cluster and extracts statistics and constraints.
    void initialize_constraints();

 public:
    template <typename Iterable>
    AlignedCluster(PHV::Kind kind, Iterable fields) : kind_i(kind) {
        set_cluster_id();
        for (auto* f : fields)
            fields_i.insert(f);
        initialize_constraints();
    }

    /// @returns id of this cluster
    int id() const  { return id_i; }

    /// @returns true if this cluster can be assigned to containers of kind
    /// @kind.
    bool okIn(PHV::Kind kind) const;

    /** @returns the (little Endian) byte-relative alignment constraint (if
     * any) for all fields in this cluster.
     */
    boost::optional<unsigned> alignment() const { return alignment_i; }

    /** @returns all the starting (low, little Endian) container bit positions at
     * which the low bit of each field in this cluster can be placed, or
     * an empty bitvec when no such valid position exists for containers
     * of the specified size.
     */


    /** Combines AlignedCluster::alignment() and
     * AlignedCluster::validContainerStartRange(@container_size) to compute the
     * valid lo bit positions where fields of this cluster can be placed in
     * containers of size @container_size, or boost::none if no valid start
     * positions exist or if any field is too large to fit in containers of
     * @container_size.
     *
     * If any field in this cluster has the `deparsed_bottom_bits` constraint,
     * then the bitvec will be [0, 0], or empty if any field cannot be started
     * at container bit 0.
     *
     * @returns the set of bit positions at which all fields in this cluster
     * all fields can be placed, if any.
     */
    bitvec validContainerStart(PHV::Size container_size) const;

    /// @returns the fields in this cluster.
    const ordered_set<PHV::Field *>& fields() const { return fields_i; }

    using const_iterator = ordered_set<PHV::Field *>::const_iterator;
    const_iterator begin() const { return fields_i.begin(); }
    const_iterator end()   const { return fields_i.end(); }

    // XXX(cole): Revisit the following stats/constraints getters.

    /// @returns the number of fields in this container with the
    /// exact_containers constraint.
    int exact_containers() const override  { return exact_containers_i; }

    /// @returns the width of the widest field in this cluster.
    int max_width() const override          { return max_width_i; }

    /// @returns the total number of constraints summed over all fields in this
    /// cluster.
    int num_constraints() const override    { return num_constraints_i; }

    /// @returns the sum of the widths of fields in this cluster.
    size_t aggregate_size() const override  { return aggregate_size_i; }

    /// @returns true if this cluster contains @f.
    bool contains(const PHV::Field* f) const override;
};

/** A rotational cluster holds groups of clusters that must be placed in the
 * same MAU group at rotationally-equivalent alignments. */


/** A group of aligned clusters that must be placed in the same MAU group of
 * PHV containers.
 */
class SuperCluster : public ClusterStats {
 public:
    using FieldList = std::vector<PHV::Field*>;

 private:
    ordered_set<AlignedCluster*> clusters_i;
    ordered_set<FieldList*> field_lists_i;
    ordered_map<const PHV::Field*, AlignedCluster*> fields_to_clusters_i;

    // Statstics gathered from clusters.
    PHV::Kind kind_i;
    int exact_containers_i = 0;
    int max_width_i = 0;
    int num_constraints_i = 0;
    size_t aggregate_size_i = 0;

 public:
    SuperCluster(ordered_set<PHV::AlignedCluster*> clusters, ordered_set<FieldList*> field_lists);

    /// @returns the aligned clusters in this group.
    const ordered_set<AlignedCluster*>& clusters() const { return clusters_i; }

    /// @returns the field lists that induced this grouping.
    const ordered_set<FieldList*>& field_lists() const { return field_lists_i; }

    /// @returns the cluster containing @f.
    /// @warning fails catastrophicaly if @f is not in any cluster in this group; all fields
    ///          in every field list are guaranteed to be present in exactly one cluster.
    const AlignedCluster& cluster(const PHV::Field* f) const {
        auto it = fields_to_clusters_i.find(f);
        BUG_CHECK(it != fields_to_clusters_i.end(), "Field %1% not in cluster group",
                  cstring::to_cstring(f));
        return *it->second;
    }

    /// @returns true if this cluster can be assigned to containers of kind
    /// @kind.
    bool okIn(PHV::Kind kind) const;

    /// @returns the number of clusters in this group with the exact_containers constraint.
    int exact_containers() const override { return exact_containers_i; }

    /// @returns the width of the maximum field in any cluster in this group.
    int max_width() const override { return max_width_i; }

    /// @returns the sum of constraints of all clusters in this group.
    int num_constraints() const override { return num_constraints_i; }

    /// @returns the aggregate size of all fields in all clusters in this group.
    size_t aggregate_size() const override { return aggregate_size_i; }

    /// @returns true if this cluster contains @f.
    bool contains(const PHV::Field* f) const override;
};

}   // namespace PHV

std::ostream &operator<<(std::ostream &out, const PHV::Allocation&);
std::ostream &operator<<(std::ostream &out, const PHV::Allocation*);
std::ostream &operator<<(std::ostream &out, const PHV::AllocSlice&);
std::ostream &operator<<(std::ostream &out, const PHV::AllocSlice*);
std::ostream &operator<<(std::ostream &out, const PHV::ContainerGroup&);
std::ostream &operator<<(std::ostream &out, const PHV::ContainerGroup*);
std::ostream &operator<<(std::ostream &out, const PHV::AlignedCluster&);
std::ostream &operator<<(std::ostream &out, const PHV::AlignedCluster*);
std::ostream &operator<<(std::ostream &out, const PHV::SuperCluster&);
std::ostream &operator<<(std::ostream &out, const PHV::SuperCluster*);

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

#endif  /* BF_P4C_PHV_UTILS_H_ */
