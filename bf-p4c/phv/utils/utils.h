#ifndef BF_P4C_PHV_UTILS_UTILS_H_
#define BF_P4C_PHV_UTILS_UTILS_H_

#include <boost/optional.hpp>
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/bitvec.h"
#include "lib/symbitmatrix.h"

namespace PHV {

using ActionSet = ordered_set<const IR::MAU::Action*>;

/** A set of PHV containers of the same size. */
class ContainerGroup {
    /// Size (bit width) of each container in this group.
    const PHV::Size size_i;

    /// Types of each container in this group.
    std::set<PHV::Type> types_i;

    /// Containers in this group.
    std::vector<PHV::Container> containers_i;

    /// IDs of containers in this group.
    bitvec ids_i;

 public:
    /** Creates a container group from a vector of containers.  Fails catastrophically if
      * @containers has containers not of size @size.
      */
    ContainerGroup(PHV::Size size, const std::vector<PHV::Container> containers);

    /** Creates a container group from a bitvec of container IDs.  Fails catastrophically if
      * @container_group has containers not of size @size.
      */
    ContainerGroup(PHV::Size size, bitvec container_group);

    using const_iterator = std::vector<PHV::Container>::const_iterator;
    const_iterator begin() const { return containers_i.begin(); }
    const_iterator end()   const { return containers_i.end(); }

    /// @returns true if there are no containers in this group.
    bool empty() const { return containers_i.empty(); }

    /// @returns the number of containers in this group.
    size_t size() const { return containers_i.size(); }

    /// @returns the PHV::Size of this group.
    PHV::Size width() const    { return size_i; }

    /// @returns the types of PHVs in this group.
    const std::set<PHV::Type> types() const { return types_i; }

    /// @returns true if the type @t is present in this group.
    bool hasType(PHV::Type t) const { return types_i.count(t); }

    /// @return true if the ContainerGroup has kind k.
    bool is(PHV::Kind k) const {
        for (auto t : types_i)
            if (t.kind() == k) return true;
        return false;
    }

    /// @return true if the ContainerGroup is of size s.
    bool is(PHV::Size s) const { return s == size_i; }

    /// @returns the ids of containers in this group.
    bitvec ids() const { return ids_i; }

    /// @returns true if @c is in this group.
    bool contains(PHV::Container c) const {
        return std::find(containers_i.begin(), containers_i.end(), c) != containers_i.end();
    }

    /// @returns all the dark containers in this MAU group.
    const ordered_set<PHV::Container> getAllContainersOfKind(PHV::Kind kind) const {
        ordered_set<PHV::Container> rs;
        for (auto c : containers_i)
            if (c.is(kind))
                rs.insert(c);
        return rs;
    }
};

class DarkInitPrimitive;

// XXX(cole): This duplicates PHV::Field::alloc_slice.
class AllocSlice {
    PHV::Field* field_i;
    PHV::Container container_i;
    int field_bit_lo_i;
    int container_bit_lo_i;
    int width_i;
    PHV::StageAndAccess min_stage_i;
    PHV::StageAndAccess max_stage_i;
    DarkInitPrimitive* init_i;

 public:
    AllocSlice(PHV::Field* f, PHV::Container c, int f_bit_lo, int container_bit_lo, int width);
    AllocSlice(PHV::Field* f, PHV::Container c, le_bitrange f_slice, le_bitrange container_slice);
    AllocSlice(const AllocSlice& a);

    bool operator==(const AllocSlice& other) const;
    bool operator!=(const AllocSlice& other) const;
    bool operator<(const AllocSlice& other) const;

    PHV::Field* field() const               { return field_i; }
    PHV::Container container() const        { return container_i; }
    le_bitrange field_slice() const         { return StartLen(field_bit_lo_i, width_i); }
    le_bitrange container_slice() const     { return StartLen(container_bit_lo_i, width_i); }
    int width() const                       { return width_i; }
    const DarkInitPrimitive* getInitPrimitive() const { return init_i; }
    DarkInitPrimitive* getInitPrimitive() { return init_i; }
    const PHV::StageAndAccess& getEarliestLiveness() const { return min_stage_i; }
    const PHV::StageAndAccess& getLatestLiveness() const { return max_stage_i; }

    bool hasInitPrimitive() const;

    bool isLiveAt(int stage, unsigned access) const {
        PHV::FieldUse use(access);
        if (stage > min_stage_i.first && stage < max_stage_i.first)
            return true;
        if (stage == min_stage_i.first && use >= min_stage_i.second)
            return true;
        if (stage == max_stage_i.first && use <= max_stage_i.second)
            return true;
        return false;
    }

    bool isLiveRangeDisjoint(const AllocSlice& other) const;
    bool representsSameFieldSlice(const AllocSlice& other) const {
        if (field_i != other.field()) return false;
        if (field_slice() != other.field_slice()) return false;
        if (width_i != other.width()) return false;
        return true;
    }

    void setLiveness(const StageAndAccess& min, const StageAndAccess& max) {
        min_stage_i = std::make_pair(min.first, min.second);
        max_stage_i = std::make_pair(max.first, max.second);
    }

    void setLatestLiveness(const StageAndAccess& max) {
        max_stage_i = std::make_pair(max.first, max.second);
    }

    void setEarliestLiveness(const StageAndAccess& min) {
        min_stage_i = std::make_pair(min.first, min.second);
    }

    void setInitPrimitive(DarkInitPrimitive* prim) {
        init_i = prim;
    }
};

class DarkInitPrimitive {
 private:
     bool assignZeroToDestination;
     bool nop;
     boost::optional<AllocSlice> sourceSlice;
     bool alwaysInitInLastMAUStage;
     ActionSet actions;

 public:
     DarkInitPrimitive(void)
         : assignZeroToDestination(false), nop(false), sourceSlice(boost::none),
         alwaysInitInLastMAUStage(false) { }

     explicit DarkInitPrimitive(ActionSet initPoints)
         : assignZeroToDestination(true), nop(false), sourceSlice(boost::none),
         alwaysInitInLastMAUStage(false), actions(initPoints) { }

     explicit DarkInitPrimitive(PHV::AllocSlice& src, ActionSet initPoints)
         : assignZeroToDestination(false), nop(false), sourceSlice(src),
         alwaysInitInLastMAUStage(false), actions(initPoints) { }

     explicit DarkInitPrimitive(const DarkInitPrimitive& other)
         : assignZeroToDestination(other.assignZeroToDestination),
         nop(other.nop),
         sourceSlice(other.getSourceSlice()),
         alwaysInitInLastMAUStage(other.alwaysInitInLastMAUStage),
         actions(other.actions) { }

     bool operator==(const DarkInitPrimitive& other) const {
         return assignZeroToDestination == other.assignZeroToDestination &&
                nop == other.nop &&
                sourceSlice == other.sourceSlice &&
                alwaysInitInLastMAUStage == other.alwaysInitInLastMAUStage &&
                actions == other.actions;
     }

     bool isEmpty() const {
         if (!nop && sourceSlice == boost::none && !assignZeroToDestination)
             return true;
         return false;
     }

     void addSource(AllocSlice sl) {
         assignZeroToDestination = false;
         sourceSlice = sl;
     }

     void setNop() {
         nop = true;
         sourceSlice = boost::none;
         assignZeroToDestination = false;
     }

     void setLastStageAlwaysInit() { alwaysInitInLastMAUStage = true; }
     bool isNOP() const { return nop; }
     bool destAssignedToZero() const { return assignZeroToDestination; }
     bool mustInitInLastMAUStage() const { return alwaysInitInLastMAUStage; }
     boost::optional<AllocSlice> getSourceSlice() const { return sourceSlice; }
     const ActionSet& getInitPoints() const { return actions; }
};

class DarkInitEntry {
 private:
     AllocSlice destinationSlice;
     DarkInitPrimitive initInfo;

 public:
     explicit DarkInitEntry(AllocSlice& dest) : destinationSlice(dest) { }
     explicit DarkInitEntry(AllocSlice& dest, ActionSet initPoints)
         : destinationSlice(dest), initInfo(initPoints) { }
     explicit DarkInitEntry(AllocSlice& dest, AllocSlice& src, ActionSet init)
         : destinationSlice(dest), initInfo(src, init) { }

     void addSource(AllocSlice sl) { initInfo.addSource(sl); }
     void setNop() { initInfo.setNop(); }
     void setLastStageAlwaysInit() { initInfo.setLastStageAlwaysInit(); }
     bool isNOP() const { return initInfo.isNOP(); }
     bool destAssignedToZero() const { return initInfo.destAssignedToZero(); }
     bool mustInitInLastMAUStage() const { return initInfo.mustInitInLastMAUStage(); }
     boost::optional<AllocSlice> getSourceSlice() { return initInfo.getSourceSlice(); }
     void setDestinationMaxLiveness(const StageAndAccess& max) {
         destinationSlice.setLatestLiveness(max);
     }
     const ActionSet& getInitPoints() const { return initInfo.getInitPoints(); }
     const AllocSlice getDestinationSlice() const { return destinationSlice; }
     AllocSlice getDestinationSlice() { return destinationSlice; }
     const DarkInitPrimitive& getInitPrimitive() const { return initInfo; }
     DarkInitPrimitive& getInitPrimitive() { return initInfo; }
     void setDestinationLatestLiveness(const PHV::StageAndAccess& max) {
         destinationSlice.setLatestLiveness(max);
     }
     void setDestinationEarliestLiveness(const PHV::StageAndAccess& min) {
         destinationSlice.setEarliestLiveness(min);
     }
};

using DarkInitMap = std::vector<DarkInitEntry>;

// XXX(cole): Better way to structure Transactions to avoid this circular
// dependency?
class Transaction;

/** Keep track of the allocation of field slices to container slices, as well
 * as the gress assignment of containers.  Support speculative allocation and
 * rollbacks with the Transaction mechanism.
 */
class Allocation {
 public:
    friend class AllocationReport;

    using GressAssignment = boost::optional<gress_t>;
    using MutuallyLiveSlices = ordered_set<AllocSlice>;
    using ActionSet = ordered_set<const IR::MAU::Action*>;
    using LiveRangeShrinkingMap = ordered_map<const PHV::Field*, ActionSet>;
    enum class ContainerAllocStatus { EMPTY, PARTIAL, FULL };

    /// This struct tracks PHV container state that can change during the
    /// course of allocation, such as the thread to which this container must be
    /// assigned, or the field slices that have been allocated to it.  Because
    /// PHV allocation queries container status many, many times, this struct
    /// also contains a derived `alloc_status`, which summarizes the state of
    /// the container.
    struct ContainerStatus {
        GressAssignment gress;
        GressAssignment parserGroupGress;
        GressAssignment deparserGroupGress;
        ordered_set<AllocSlice> slices;
        ContainerAllocStatus alloc_status;
    };

    using const_iterator = ordered_map<PHV::Container, ContainerStatus>::const_iterator;

    /// This struct represents the conditional constraint information generated by
    /// ActionPhvConstraints for a single unallocated PHV::FieldSlice.
    struct ConditionalConstraintData {
        /// Bit position to which the FieldSlice must be aligned.
        int bitPosition;
        /// Boolean set to true if AllocatePHV can use rotationally equivalent bitPosition.
        bool rotationAllowed;
        /// Specific container to which the slice must be allocated.
        boost::optional<PHV::Container> container;

        explicit ConditionalConstraintData(int bit, PHV::Container c, bool rotate = false) :
            bitPosition(bit), rotationAllowed(rotate), container(c) { }

        explicit ConditionalConstraintData(int bit, bool rotate = false) :
            bitPosition(bit), rotationAllowed(rotate), container(boost::none) { }

        ConditionalConstraintData() :
            bitPosition(-1), rotationAllowed(false), container(boost::none) { }

        bool operator == (ConditionalConstraintData& other) const {
            return bitPosition == other.bitPosition &&
                   rotationAllowed == other.rotationAllowed &&
                   container == other.container;
        }
    };

    using ConditionalConstraint = ordered_map<PHV::FieldSlice, ConditionalConstraintData>;
    using ConditionalConstraints = ordered_map<int, ConditionalConstraint>;

    using FieldStatus = ordered_set<AllocSlice>;

 protected:
    // These are copied from parent to child on creating a transaction, and
    // from child to parent on committing.
    const SymBitMatrix* mutex_i;
    const PhvUse* uses_i;
    ordered_map<PHV::Size, ordered_map<ContainerAllocStatus, int>> count_by_status_i;

    // For efficiency, these are NOT copied from parent to child.  Changes in
    // the child are copied back to the parent on commit.  However, parent info
    // is copied to the child when queried, as a caching optimization.
    mutable ordered_map<PHV::Container, ContainerStatus> container_status_i;
    mutable ordered_map<const PHV::Field*, FieldStatus>  field_status_i;
    /// Structure that remembers the actions at which metadata fields need to be initialized for a
    /// particular allocation object.
    mutable ordered_map<AllocSlice, ordered_set<const IR::MAU::Action*>> meta_init_points_i;
    /// Structure that remembers actions at which metadata initialization for various fields has
    /// been added.
    mutable ordered_map<const IR::MAU::Action*, ordered_set<const PHV::Field*>> init_writes_i;
    /// parser state to containers
    mutable ordered_map<const IR::BFN::ParserState*,
                        std::set<PHV::Container>> state_to_containers_i;
    /** Dark containers allocated in this allocation mapped to the stages that they are allocated
     *  to. The read map captures the allocation from the perspective of a read of that container
     *  while the write map captures the allocation from the perspective of a write to that
     *  container.
     */
    mutable ordered_map<PHV::Container, bitvec> dark_containers_write_allocated_i;
    mutable ordered_map<PHV::Container, bitvec> dark_containers_read_allocated_i;
    /// Initialization information about allocating to dark containers during certain stages.
    mutable DarkInitMap init_map_i;

    Allocation(const SymBitMatrix& mutex, const PhvUse& uses) : mutex_i(&mutex), uses_i(&uses) { }

    /// @returns the meta_init_points_i map for the current allocation object.
    ordered_map<AllocSlice, ordered_set<const IR::MAU::Action*>>& get_meta_init_points() const {
        return meta_init_points_i;
    }

 private:
    /// Uniform abstraction for setting container state.  For internal use
    /// only.  @c must exist in this Allocation.
    virtual bool addStatus(PHV::Container c, const ContainerStatus& status);

    /// Add the actions in @actions to the metadata initialization points for @slice.
    virtual void addMetaInitPoints(
            AllocSlice slice,
            ordered_set<const IR::MAU::Action*> actions);

    /// Uniform convenience abstraction for adding one slice.  For internal use
    /// only.  @c must exist in this Allocation.
    virtual void addSlice(PHV::Container c, AllocSlice slice);

    /// Uniform abstraction for setting container state.  For internal use
    /// only.  @c must exist in this Allocation.
    virtual void setGress(PHV::Container c, GressAssignment gress);

    /// Uniform abstraction for setting container state.  For internal use
    /// only.  @c must exist in this Allocation.
    virtual void setParserGroupGress(PHV::Container c, GressAssignment gress);

    /// Uniform abstraction for setting container state.  For internal use
    /// only.  @c must exist in this Allocation.
    virtual void setDeparserGroupGress(PHV::Container c, GressAssignment gress);

 public:
    /// Uniform abstraction for accessing a container state.
    /// @returns the ContainerStatus of this allocation, if present.  Failing
    ///          that, check its ancestors.  If @c has no status yet, return boost::none.
    virtual boost::optional<ContainerStatus> getStatus(PHV::Container c) const = 0;

    /// Uniform abstraction for accessing field state.
    /// @returns the FieldStatus of this allocation, if present.  Failing
    ///          that, check its ancestors.  If @f has no status yet, return an empty FieldStatus.
    virtual FieldStatus getStatus(const PHV::Field* f) const = 0;

    friend class Transaction;

    /// Iterate through container-->allocation slices.
    virtual const_iterator begin() const = 0;
    virtual const_iterator end() const = 0;

    /// @returns the set of actions where @slice must be initialized for overlay enabled by live
    /// range shrinking.
    boost::optional<ordered_set<const IR::MAU::Action*>>
        getInitPoints(const AllocSlice& slice) const;

    /// @returns number of containers owned by this allocation.
    virtual size_t size() const = 0;

    /// @returns true if this allocation owns @c.
    virtual bool contains(PHV::Container c) const = 0;

    /// @returns all the fields that must be initialized in action @act.
    virtual const ordered_set<const PHV::Field*> getMetadataInits(const IR::MAU::Action* act) const;

    /// @returns the set of initialization actions for the field @f.
    virtual const ordered_set<const IR::MAU::Action*> getInitPointsForField(const PHV::Field* f)
        const;

    /// @returns all tagalong collection IDs used
    const ordered_set<unsigned> getTagalongCollectionsUsed() const;

    /// @returns map from parser state to containers
    const ordered_map<const IR::BFN::ParserState*, std::set<PHV::Container>>&
    getParserStateToContainers(const PhvInfo& phv,
                               const MapFieldToParserStates& field_to_parser_states) const;

    /// @returns all the slices allocated to @c.
    ordered_set<AllocSlice> slices(PHV::Container c) const;

    /// @returns all the slices allocated to @c and valid in the stage @stage.
    ordered_set<AllocSlice> slices(PHV::Container c, int stage, PHV::FieldUse access) const;

    /// Add @slice allocated to a dark container to the current Allocation object.
    /// @returns true if the addition was successful.
    bool addDarkAllocation(const AllocSlice& slice);

    /// @returns false if a dark container is used for the read half cycle in between stages
    /// minStage and maxStage.
    bool isDarkReadAvailable(PHV::Container c, unsigned minStage, unsigned maxStage) const {
        if (!dark_containers_write_allocated_i.count(c)) return true;
        for (unsigned i = minStage; i <= maxStage; i++)
            if (dark_containers_write_allocated_i.at(c)[i])
                return false;
        return true;
    }

    /// @returns false if a dark container is used for the write half cycle in between stages
    /// minStage and maxStage.
    bool isDarkWriteAvailable(PHV::Container c, unsigned minStage, unsigned maxStage) const {
        if (!dark_containers_read_allocated_i.count(c)) return true;
        for (unsigned i = minStage; i <= maxStage; i++)
            if (dark_containers_read_allocated_i.at(c)[i])
                return false;
        return true;
    }

    /// @returns all the slices allocated to @c that overlap with @range.
    virtual ordered_set<AllocSlice> slices(PHV::Container c, le_bitrange range) const;
    virtual ordered_set<AllocSlice>
        slices(PHV::Container c, le_bitrange range, int stage, PHV::FieldUse access) const;

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
    virtual MutuallyLiveSlices slicesByLiveness(const PHV::Container c,
                                                const AllocSlice& sl) const;
    virtual MutuallyLiveSlices slicesByLiveness(const PHV::Container c,
                                                std::vector<AllocSlice>& slices) const;

    /// @returns all slices allocated for @f that include any part of @range in
    /// the field portion of the allocated slice.  May be empty (if @f is not
    /// allocated) or contain slices that do not fully cover all bits of @f (if
    /// @f is only partially allocated).
    virtual ordered_set<PHV::AllocSlice> slices(const PHV::Field* f, le_bitrange range) const;
    virtual ordered_set<PHV::AllocSlice>
        slices(const PHV::Field* f, le_bitrange range, int stage, PHV::FieldUse access) const;

    /// @returns the set of slices allocated for the field @f in this
    /// Allocation.  May be empty (if @f is not allocated) or contain slices that
    /// do not fully cover all bits of @f (if @f is only partially allocated).
    ordered_set<PHV::AllocSlice> slices(const PHV::Field* f) const {
        return slices(f, StartLen(0, f->size));
    }

    ordered_set<PHV::AllocSlice> slices(
            const PHV::Field* f,
            int stage,
            PHV::FieldUse access) const {
        return slices(f, StartLen(0, f->size), stage, access);
    }

    /// @returns the container status of @c and fails if @c is not present.
    virtual GressAssignment gress(PHV::Container c) const;

    /// @returns the gress of @c's parser group, if any.  If a container
    /// holds extracted fields, then its gress must match that of its parser
    /// group.
    virtual GressAssignment parserGroupGress(PHV::Container c) const;

    /// @returns the gress of @c's deparser group, if any.  If a container
    /// holds deparsed fields, then its gress must match that of its deparser
    /// group.
    virtual GressAssignment deparserGroupGress(PHV::Container c) const;

    /// @returns the allocation status of @c and fails if @c is not present.
    virtual ContainerAllocStatus alloc_status(PHV::Container c) const;

    /// @returns the number of empty containers of size @size.
    int empty_containers(PHV::Size size) const;

    /** Assign @slice to @slice.container, updating the gress information of
     * the container and its MAU group if necessary.  Fails if the gress of
     * @slice.field does not match any gress in the MAU group.
     *
     * Note that this adds new slices but does not remove or overwrite existing
     * slices.
     */
    virtual void allocate(
            const AllocSlice slice,
            boost::optional<LiveRangeShrinkingMap> initNodes = boost::none);

    virtual void removeAllocatedSlice(const ordered_set<PHV::AllocSlice>& slices);

    /// Uniform convenience abstraction for adding a metadata initialization node to the allocation
    /// object.
    virtual void addMetadataInitialization(AllocSlice slice, LiveRangeShrinkingMap initNodes);

    /// @returns a pretty-printed representation of this Allocation.
    virtual cstring toString() const;

    /// Create a Transaction based on this Allocation.  @see PHV::Transaction for details.
    virtual Transaction makeTransaction() const;

    /// Update this allocation with any new allocation in @view.  Note that
    /// this may add new slices but does not remove or overwrite existing slices.
    cstring commit(Transaction& view);

    /// Utility function.
    /// @returns true if @f1 and @f2 are mutually exclusive.
    static bool mutually_exclusive(
            const SymBitMatrix& mutex,
            const PHV::Field *f1,
            const PHV::Field *f2);

    /// Available bits of this allocation
    struct AvailableSpot {
        PHV::Container container;
        GressAssignment gress;
        GressAssignment parserGroupGress;
        GressAssignment deparserGroupGress;
        int n_bits;
        AvailableSpot(const PHV::Container& c,
                      const GressAssignment& gress,
                      const GressAssignment& parserGroupGress,
                      const GressAssignment& deparserGroupGress,
                      int n_bits)
            : container(c), gress(gress), parserGroupGress(parserGroupGress),
              deparserGroupGress(deparserGroupGress), n_bits(n_bits)
            { }
        bool operator<(const AvailableSpot& other) const {
            return n_bits < other.n_bits; }
    };

    /// Return a set of available spots of this allocation.
    std::set<AvailableSpot> available_spots() const;
};

class ConcreteAllocation : public Allocation {
    /** Create an allocation from a vector of container IDs.  Physical
     * containers that the Device pins to a particular gress are
     * initialized to that gress.
     */
    ConcreteAllocation(const SymBitMatrix&, const PhvUse&, bitvec containers);

 public:
    /// Uniform abstraction for accessing a container state.
    /// @returns the ContainerStatus of this allocation, if present.  Failing
    ///          that, check its ancestors.  If @c has no status yet, return boost::none.
    boost::optional<ContainerStatus> getStatus(PHV::Container c) const override;

    /// Uniform abstraction for accessing field state.
    /// @returns the FieldStatus of this allocation, if present.  Failing
    ///          that, check its ancestors.  If @f has no status yet, return an empty FieldStatus.
    FieldStatus getStatus(const PHV::Field* f) const override;

    /** @returns an allocation initialized with the containers present in
     * Device::phvSpec, with the gress set for any hard-wired containers, but
     * no slices allocated.
     */
    explicit ConcreteAllocation(const SymBitMatrix&, const PhvUse&);

    /// Iterate through container-->allocation slices.
    const_iterator begin() const override { return container_status_i.begin(); }
    const_iterator end() const override { return container_status_i.end(); }

    /// @returns number of containers owned by this allocation.
    size_t size() const override { return container_status_i.size(); }

    /// @returns true if this allocation owns @c.
    bool contains(PHV::Container c) const override;

    /// @returns a set of actions where the slice @slice must be initialized. @returns an empty set
    /// of actions if initialization is not required.
    boost::optional<ordered_set<const IR::MAU::Action*>>
        getInitPoints(const AllocSlice slice) const;
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
    /// Uniform abstraction for accessing a container state.
    /// @returns the ContainerStatus of this allocation, if present.  Failing
    ///          that, check its ancestors.  If @c has no status yet, return boost::none.
    boost::optional<ContainerStatus> getStatus(PHV::Container c) const override;

    /// Uniform abstraction for accessing field state.
    /// @returns the FieldStatus of this allocation, if present.  Failing
    ///          that, check its ancestors.  If @f has no status yet, return an empty FieldStatus.
    FieldStatus getStatus(const PHV::Field* f) const override;

 public:
    /// Constructor.
    explicit Transaction(const Allocation& parent)
    : Allocation(*parent.mutex_i, *parent.uses_i), parent_i(&parent) {
        BUG_CHECK(&parent != this, "Creating transaction with self as parent");
    }

    /// Pretty print all the metadata initialization actions for the current transaction (including
    /// all the parent transactions). Not used anywhere explicitly, but do not remove because calls
    /// to this function make debugging easy.
    void printMetaInitPoints() const;

    /// Destructor declaration. Does nothing but quiets warnings
    virtual ~Transaction() {}

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

    /// @returns a summary of status of each container allocated in this transaction.
    cstring getTransactionSummary() const;

    /// @returns the set of actions in which @slice must be initialized for live range shrinking.
    boost::optional<ordered_set<const IR::MAU::Action*>>
        getInitPoints(const AllocSlice& slice) const;

    /// Returns the outstanding writes in this view.
    const ordered_map<PHV::Container, ContainerStatus>& getTransactionStatus() const {
        return container_status_i;
    }

    const ordered_map<const PHV::Field*, FieldStatus>& getFieldStatus() const {
        return field_status_i;
    }

    /// @returns a map of all the AllocSlices and the various actions where these slices must be
    /// initialized, for the PHV allocation represented by the current transaction.
    const ordered_map<AllocSlice, ordered_set<const IR::MAU::Action*>>& getMetaInitPoints() const {
        return meta_init_points_i;
    }

    /// @returns a map of actions to the fields that must be initialized in that action for the
    /// allocation to be valid.
    const ordered_map<const IR::MAU::Action*, ordered_set<const PHV::Field*>>&
    getInitWrites() const {
        return init_writes_i;
    }

    /// @returns the set of fields that must be initialized in action @act.
    const ordered_set<const PHV::Field*>
    getMetadataInits(const IR::MAU::Action* act) const override {
        const ordered_set<const PHV::Field*> parentInits = parent_i->getMetadataInits(act);
        if (!init_writes_i.count(act)) return parentInits;
        ordered_set<const PHV::Field*> rv;
        rv.insert(parentInits.begin(), parentInits.end());
        auto inits = init_writes_i.at(act);
        rv.insert(inits.begin(), inits.end());
        return rv;
    }

    /// @returns the set of actions in which field @f is initialized to enable live range shrinking.
    const ordered_set<const IR::MAU::Action*> getInitPointsForField(const PHV::Field* f) const
        override {
        const auto parentInitPoints = parent_i->getInitPointsForField(f);
        ordered_set<const IR::MAU::Action*> rs;
        rs.insert(parentInitPoints.begin(), parentInitPoints.end());
        for (auto kv : meta_init_points_i) {
            if (kv.first.field() != f) continue;
            rs.insert(kv.second.begin(), kv.second.end());
        }
        return rs;
    }

    /// @returns false if a dark container is used for the read half cycle in between stages
    /// minStage and maxStage for either this transaction or its parent.
    bool isDarkReadAvailable(PHV::Container c, unsigned minStage, unsigned maxStage) const {
        return (Allocation::isDarkReadAvailable(c, minStage, maxStage) ||
                parent_i->isDarkReadAvailable(c, minStage, maxStage));
    }

    /// @returns false if a dark container is used for the write half cycle in between stages
    /// minStage and maxStage for either this transaction or its parent.
    bool isDarkWriteAvailable(PHV::Container c, unsigned minStage, unsigned maxStage) const {
        return (Allocation::isDarkWriteAvailable(c, minStage, maxStage) ||
                parent_i->isDarkWriteAvailable(c, minStage, maxStage));
    }

    /// Clears any allocation added to this transaction.
    void clearTransactionStatus() {
        container_status_i.clear();
        meta_init_points_i.clear();
        init_writes_i.clear();
        field_status_i.clear();
        dark_containers_write_allocated_i.clear();
        dark_containers_read_allocated_i.clear();
        init_map_i.clear();
        state_to_containers_i.clear();
        count_by_status_i = parent_i->count_by_status_i;
    }

    /// Returns the allocation that this transaction is based on.
    const Allocation* getParent() const { return parent_i; }
};

/// An interface for gathering statistics common across each kind of cluster.
class ClusterStats {
 private:
    static int nextId;

 public:
    int uid = nextId++;
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

    /// @returns true if any slice in the cluster is deparsed (either to the
    /// wire or the TM).
    virtual bool deparsed() const = 0;

    /// @returns true if this cluster contains @f.
    virtual bool contains(const PHV::Field* f) const = 0;

    /// @returns true if this cluster contains @slice.
    virtual bool contains(const PHV::FieldSlice& slice) const = 0;

    /// @returns the gress requiremnt of this cluster.
    virtual gress_t gress() const = 0;
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
    gress_t gress_i;

    /// Field slices in this cluster.
    ordered_set<PHV::FieldSlice> slices_i;

    int id_i;                // this cluster's id
    int exact_containers_i;
    int max_width_i;
    int num_constraints_i;
    size_t aggregate_size_i;
    bool hasDeparsedFields_i;

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
            return alignment_i->align;
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

    /// @returns true if any slice in the cluster is deparsed (either to the
    /// wire or the TM).
    bool deparsed() const override { return hasDeparsedFields_i; }

    /// @returns true if this cluster contains @f.
    bool contains(const PHV::Field* f) const override;

    /// @returns true if this cluster contains @slice.
    bool contains(const PHV::FieldSlice& slice) const override;

    /// @returns the gress requirement of this cluster.
    gress_t gress() const override          { return gress_i; }

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
    /// Slices that make up the AlignedClusters in this RotationalCluster.
    ordered_set<PHV::FieldSlice> slices_i;

    /// AlignedClusters that make up this RotationalCluster.
    ordered_set<AlignedCluster*> clusters_i;

    /// Map of slices to aligned clusters.
    ordered_map<const PHV::FieldSlice, AlignedCluster*> slices_to_clusters_i;

    // Statstics gathered from clusters.
    PHV::Kind kind_i;
    gress_t gress_i;
    int exact_containers_i = 0;
    int max_width_i = 0;
    int num_constraints_i = 0;
    size_t aggregate_size_i = 0;
    bool hasDeparsedFields_i = false;

 public:
    explicit RotationalCluster(ordered_set<PHV::AlignedCluster*> clusters);

    /// Semantic equality.
    bool operator==(const RotationalCluster& other) const;

    /// @returns the slices in the aligned clusters in this group.
    const ordered_set<PHV::FieldSlice>& slices() const { return slices_i; }

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

    /// @returns true if any slice in the cluster is deparsed (either to the
    /// wire or the TM).
    bool deparsed() const override { return hasDeparsedFields_i; }

    /// @returns true if this cluster contains @f.
    bool contains(const PHV::Field* f) const override;

    /// @returns true if this cluster contains @slice.
    bool contains(const PHV::FieldSlice& slice) const override;

    /// @returns the gress requirement of this cluster.
    gress_t gress() const override          { return gress_i; }

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

    /// Map each slice to the rotational cluster that contains it.  Each slice
    /// is in exactly one rotational cluster.
    ordered_map<const PHV::FieldSlice, const RotationalCluster*> slices_to_clusters_i;

    /// Map a slice to the slice lists that contain it.  Each slice is in at
    /// least one slice list.
    ordered_map<const PHV::FieldSlice, ordered_set<const SliceList*>> slices_to_slice_lists_i;

    // Statstics gathered from clusters.
    PHV::Kind kind_i;
    gress_t gress_i;
    int exact_containers_i = 0;
    int max_width_i = 0;
    int num_constraints_i = 0;
    size_t aggregate_size_i = 0;
    size_t num_pack_conflicts_i = 0;
    bool hasDeparsedFields_i = false;
    bool needsStridedAlloc_i = false;

 public:
    SuperCluster(
        ordered_set<const PHV::RotationalCluster*> clusters,
        ordered_set<SliceList*> slice_lists);

    /// Semantic equality.
    bool operator==(const SuperCluster& other) const;

    /// @returns true if the supercluster can be sliced further.
    bool isSliceable() const;

    /// @returns the aligned clusters in this group.
    const ordered_set<const RotationalCluster*>& clusters() const { return clusters_i; }

    /// @returns the slice lists that induced this grouping.
    const ordered_set<SliceList*>& slice_lists() const { return slice_lists_i; }

    /// @returns the slice lists holding @slice.
    const ordered_set<const SliceList*>& slice_list(const PHV::FieldSlice& slice) const;

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

    /// @returns a new SuperCluster object that is the union of the provided
    /// SuperCluster inputs.
    SuperCluster* merge(const SuperCluster *sc1) {
        ordered_set<const RotationalCluster*> new_clusters_i;
        ordered_set<SliceList*> new_slice_lists;
        for (auto *c1 : clusters_i) { new_clusters_i.insert(c1); }
        for (auto *c2 : sc1->clusters_i) { new_clusters_i.insert(c2); }
        for (auto *sl1 : slice_lists_i) { new_slice_lists.insert(sl1); }
        for (auto *sl2 : sc1->slice_lists_i) { new_slice_lists.insert(sl2); }
        return new SuperCluster(new_clusters_i, new_slice_lists);
    }

    /// Merge this SuperCluster with the input SuperCluster, and
    /// return a new SuperCluster.
    /// This function is only intended to be called when the two
    /// SuperClusters are linked by wide arithmetic allocation requirements.
    /// This function merges the slice lists such that slice lists
    /// that are paired by wide arithmetic requirements are adjacent in
    /// the list, and the slice list destined for an even container (the lo slice)
    /// appears before the slice list destined for an odd container (the hi slice).
    SuperCluster* mergeAndSortBasedOnWideArith(const SuperCluster *sc1);

    /// @returns true if two SuperClusters need to be merged, because
    /// they container hi/lo field slices that participate in a wide
    /// arithmetic operation.
    bool needToMergeForWideArith(const SuperCluster *sc) const;

    /// Given a SliceList within a SuperCluster, find its linked
    /// wide arithmetic SliceList.
    SuperCluster::SliceList* findLinkedWideArithSliceList(const SuperCluster::SliceList* sl) const;

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

    /// @returns the number of pack conflicts of all slices in all clusters in this group. A pack
    /// conflict indicates that the field of a given slice cannot be packed with some other field
    /// referenced in the program.
    size_t num_pack_conflicts() const { return num_pack_conflicts_i; }

    /// calculates the value of num_pack_conflicts_i (to be performed after PackConflicts analysis)
    void calc_pack_conflicts();

    /// @returns true if any slice in the cluster is deparsed (either to the
    /// wire or the TM).
    bool deparsed() const override { return hasDeparsedFields_i; }

    /// @returns true if this super cluster needs strided allocation
    bool needsStridedAlloc() const { return needsStridedAlloc_i; }

    void needsStridedAlloc(bool val) { needsStridedAlloc_i = val; }

    /// @returns true if this cluster contains @f.
    bool contains(const PHV::Field* f) const override;

    /// @returns true if this cluster contains @slice.
    bool contains(const PHV::FieldSlice& slice) const override;

    /// @returns all field slices in this cluster
    ordered_set<PHV::FieldSlice> slices() const;

    /// @returns the gress requirement of this cluster.
    gress_t gress() const override { return gress_i; }

    /// Apply @p func on all field slices in this super cluster.
    void forall_fieldslices(const std::function<void(const PHV::FieldSlice&)> func) const {
        for (const auto& kv : slices_to_clusters_i) {
            func(kv.first); }
    }

    /// @returns true if any_of @p func is true on a fieldslice.
    bool any_of_fieldslices(const std::function<bool(const PHV::FieldSlice&)> func) const {
        for (const auto& kv : slices_to_clusters_i) {
            if (func(kv.first)) return true; }
        return false;
    }

    /// Apply @p func on all field slices in this super cluster.
    bool all_of_fieldslices(const std::function<bool(const PHV::FieldSlice&)> func) const {
        for (const auto& kv : slices_to_clusters_i) {
            if (!func(kv.first)) return false; }
        return true;
    }

    /// @returns true if no structural constraints prevent this super cluster
    /// from fitting.
    static bool is_well_formed(const SuperCluster* sc);
};

std::ostream &operator<<(std::ostream &out, const Allocation&);
std::ostream &operator<<(std::ostream &out, const Allocation*);
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
std::ostream &operator<<(std::ostream &out, const DarkInitEntry&);
std::ostream &operator<<(std::ostream &out, const DarkInitPrimitive&);

/// Partial order for allocation status.
bool operator<(PHV::Allocation::ContainerAllocStatus, PHV::Allocation::ContainerAllocStatus);
bool operator<=(PHV::Allocation::ContainerAllocStatus, PHV::Allocation::ContainerAllocStatus);
bool operator>(PHV::Allocation::ContainerAllocStatus, PHV::Allocation::ContainerAllocStatus);
bool operator>=(PHV::Allocation::ContainerAllocStatus, PHV::Allocation::ContainerAllocStatus);

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

#endif  /* BF_P4C_PHV_UTILS_UTILS_H_ */
