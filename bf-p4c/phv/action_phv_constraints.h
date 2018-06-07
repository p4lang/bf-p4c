#ifndef BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_

#include <boost/optional.hpp>
#include "ir/ir.h"
#include "bf-p4c/lib/union_find.hpp"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils.h"
#include "bf-p4c/phv/analysis/pack_conflicts.h"

/** This class is meant to gather action information as well as provide information to PHV analysis
  * through function calls. Methods in AllocatePHV query the information contained in class members
  * here to determine constraints on packing induced by MAU actions. 
  * @pre Must be run after InstructionSelection, as it is dependent on ActionAnalysis
  */
class ActionPhvConstraints : public Inspector {
 private:
    const PhvInfo &phv;
    const PackConflicts &conflicts;

    using ClassifiedSources = ordered_map<size_t, ordered_set<PHV::AllocSlice>>;
    /// Defines a struct for returning number of containers.
    struct NumContainers {
        size_t num_allocated;
        size_t num_unallocated;

        explicit NumContainers(const size_t numAlloc, const size_t numUnalloc) :
            num_allocated(numAlloc), num_unallocated(numUnalloc) {}

        NumContainers() : num_allocated(0), num_unallocated(0) {}
    };

    /// Defines a struct for a particular field operation: either read or write.
    // TODO: Will we ever need a boolean indicating read or write in this
    // struct?
    struct OperandInfo {
        int unique_action_id;
        enum field_read_flags_t { MOVE = 1,
                                  WHOLE_CONTAINER = (1 << 1),
                                  ANOTHER_OPERAND = (1 << 2),
                                  MIXED = (1 << 3),
                                  WHOLE_CONTAINER_SAME_FIELD = (1 << 4) };
        uint8_t flags = 0;

        // An operand is either action data (ad), a constant (constant), or
        // drawn from a PHV container (phv_used).
        bool ad = false;
        bool constant = false;
        int64_t const_value = 0;
        boost::optional<PHV::FieldSlice> phv_used = boost::none;
        cstring action_name;

        bool operator < (OperandInfo other) const {
            // XXX(cole): What if ad == other.ad?
            if (ad && !other.ad)
                return true;
            else if (!ad && other.ad)
                return false;
            else if (constant && !other.constant)
                return true;
            else if (!constant && other.constant)
                return false;
            else if (constant && other.constant)
                return const_value < other.const_value;
            else if (phv_used && !other.phv_used)
                return true;
            else if (!phv_used && other.phv_used)
                return false;
            else if (!phv_used && !other.phv_used)
                return false;
            else if (phv_used->field()->id != other.phv_used->field()->id)
                return phv_used->field()->id < other.phv_used->field()->id;
            else if (phv_used->range().lo != other.phv_used->range().lo)
                return phv_used->range().lo < other.phv_used->range().lo;
            else
                return phv_used->range().hi < other.phv_used->range().hi;
        }

        bool operator == (OperandInfo other) const {
            return phv_used == other.phv_used
                && ad == other.ad
                && constant == other.constant
                && const_value == other.const_value;
        }

        bool operator == (const PHV::Field* field) const {
            return phv_used && phv_used->field()->id == field->id;
        }

        explicit OperandInfo(PHV::FieldSlice slice, int id = -1)
        : unique_action_id(id), phv_used(slice) { }

        OperandInfo() { }
    };

    friend std::ostream
    &operator<<(std::ostream &out, const ActionPhvConstraints::OperandInfo& info);

    class ConstraintTracker {
        const PhvInfo& phv;
        ActionPhvConstraints& self;

        /// Maps fields to the actions that write them, keeping track of range
        /// of each write.
        ordered_map<const PHV::Field*,
            ordered_map<le_bitrange,
                ordered_set<const IR::MAU::Action *>>> field_writes_to_actions;

        /// Any OperandInfo (Field) within the set will have been written in the
        /// key action.
        ordered_map<const IR::MAU::Action *, ordered_set<OperandInfo>> action_to_writes;

        /// Any OperandInfo (Field) within the set will have been read in the
        /// key action.
        ordered_map<const IR::MAU::Action *, ordered_set<PHV::FieldSlice>> action_to_reads;

        /// Any OperandInfo in the std::vector will use the following as an operand in
        /// action where the key is the field written in that action.
        ordered_map<const PHV::Field*,
            ordered_map<const IR::MAU::Action *,
                ordered_map<le_bitrange,
                    std::vector<OperandInfo>>>> write_to_reads_per_action;

        ordered_map<const PHV::Field*,
            ordered_map<const IR::MAU::Action *,
                ordered_map<le_bitrange,
                    ordered_set<PHV::FieldSlice>>>> read_to_writes_per_action;

        /// Used to generate unique action IDs when creating `struct OperandInfo` objects
        static int current_action;

     public:
        ConstraintTracker(const PhvInfo& phv, ActionPhvConstraints& self)
        : phv(phv), self(self) { }

        /// Clear internal state.
        void clear();

        /// Add constraints induced by @act.
        void add_action(
            const IR::MAU::Action *act,
            const ActionAnalysis::FieldActionsMap field_actions_map);

        /** If @dst is a slice of the destination operand of an instruction
         * in @act, then return one OperandInfo for each corresponding slice
         * of each source, if any.  Returns an empty vector if @dst is not
         * written in @act or if there are no sources.
         */
        std::vector<OperandInfo>
        sources(PHV::FieldSlice dst, const IR::MAU::Action* act) const;

        /// Convenience method that translates @dst to a FieldSlice and passes
        /// it to `sources` above.
        std::vector<OperandInfo>
        sources(PHV::AllocSlice dst, const IR::MAU::Action* act) const {
            return sources(PHV::FieldSlice(dst.field(), dst.field_slice()), act);
        }

        /** If @src is a slice of a source operand of any instructions
         * in @act, then return one OperandInfo for each corresponding slice
         * of each destination, if any.  Returns an empty vector if @src is not
         * read in @act.
         */
        ordered_set<PHV::FieldSlice>
        destinations(PHV::FieldSlice src, const IR::MAU::Action* act) const;

        /// @returns the actions that read @dst.
        ordered_set<const IR::MAU::Action*> read_in(PHV::FieldSlice src) const;

        /// @returns the actions that write @dst.
        ordered_set<const IR::MAU::Action*> written_in(PHV::FieldSlice dst) const;

        /// Convenience method that translates @dst to a FieldSlice and passes
        /// it to `written_in` above.
        ordered_set<const IR::MAU::Action*> written_in(PHV::AllocSlice dst) const {
            return written_in(PHV::FieldSlice(dst.field(), dst.field_slice()));
        }

        /// @returns operation information for fields written in @act.
        const ordered_set<OperandInfo>& writes(const IR::MAU::Action* act) const;

        /// @returns operation information for fields written in @act.
        const ordered_set<PHV::FieldSlice>& reads(const IR::MAU::Action* act) const;

        /// @returns a OperandInfo structure if @slice is written in @act.
        boost::optional<OperandInfo>
        is_written(PHV::FieldSlice slice, const IR::MAU::Action *act) const;

        /// Convenience method that translates @slice to a FieldSlice and passes
        /// it to `is_written` above.
        boost::optional<OperandInfo>
        is_written(PHV::AllocSlice slice, const IR::MAU::Action *act) const {
            return is_written(PHV::FieldSlice(slice.field(), slice.field_slice()), act);
        }

        /** If @dst allocates field slice f[x:y] to container c[a:b], and @src
         * is a field slice g[x':y'] involved in an MAU instruction with
         * f[x:y], then there exists a range of container bits [a':b'] at which
         * g[x':y'] will be aligned with the corresponding bits of f[x:y].
         *
         * For example, suppose we have:
         *
         *      bit<16> f
         *      bit<16> g
         *      f[7:0] = g[15:8]
         *
         * If c[31:24]<--f[7:0], then g[10:9] would need to be placed at
         * [26:25] (starting at bit 25) to be aligned with f.
         *
         * @returns the set of alignments of @dst that cause it to align with
         * @src, or an empty set if @dst and @src are not involved in an MAU
         * operation.  The set will contain multiple alignments if @dst and
         * @src are in different instructions (in different actions) at
         * different alignments.
         */
        ordered_set<int> source_alignment(PHV::AllocSlice dst, PHV::FieldSlice src) const;

        /** Print the state of the maps */
        void printMapStates() const;

        /** Debug function to print the total number of reads and writes across all actions for the
         * fields in the vector of AllocSlices represented by @slices
         */
        void print_field_ordering(std::vector<PHV::AllocSlice>& slices) const;
    };

    ConstraintTracker constraint_tracker;

    /// Clears any state accumulated in prior invocations of this pass.
    profile_t init_apply(const IR::Node *root) override;

    /** Builds the data structures to be used in the API function call 
      * Also checks that the actions can be scheduled on Tofino in the same stage
      * without splitting and without considering PHV allocation (yet to happen)
      */
    bool preorder(const IR::MAU::Action *act) override;

    /// Print out all the maps created in ActionPhvConstraints.
    void end_apply() override;

    /** Given the state of PHV allocation represented by @alloc and @container_state, a vector of
      * slices to be packed together and mutually live in a given container
      * Also populates the UnionFind structure @copacking_constraints, used to report new packing
      * constraints induced by can_pack()
      * @returns the number of container sources used in @action
      */
    NumContainers num_container_sources(const PHV::Allocation& alloc,
            PHV::Allocation::MutuallyLiveSlices container_state, const IR::MAU::Action* action,
            UnionFind<PHV::FieldSlice>& copacking_constraints);

    /** Return the first allocated (in @alloc) or proposed (in @slices) source
     * of an instruction in @action that writes to @slice, if any.  There may
     * be up to two PHV sources per destination in any action, as each
     * destination may only be written to once.
     */
    boost::optional<PHV::AllocSlice> getSourcePHVSlice(
        const PHV::Allocation& alloc,
        const std::vector<PHV::AllocSlice>& slices,
        PHV::AllocSlice& dst,
        const IR::MAU::Action* action);

    /** @returns true if @slices packed in the same container read from action
     * data or from constant in action @act
     */
    bool has_ad_or_constant_sources(
        const PHV::Allocation::MutuallyLiveSlices& slices,
        const IR::MAU::Action *act) const;

    /** Check if two fields share the same container
      */
    bool fields_share_container(const PHV::Field *, const PHV::Field *);

    /** @returns the number of no unallocated bits in a set of mutually live field slices @slice
      * in container @c
      */
    int unallocated_bits(PHV::Allocation::MutuallyLiveSlices, const PHV::Container) const;

    /** @returns true if all AllocSlices in @state are adjacent FieldSlices of the same field
      */
    bool are_adjacent_field_slices(const PHV::Allocation::MutuallyLiveSlices& state) const;

    /** @returns the number of holes that must be masked out by a given set of AllocSlices
      * @state: candidate list of AllocSlices
      */
    unsigned count_container_holes(const PHV::Allocation::MutuallyLiveSlices& state) const;

    /** @returns the type of operation (OperandInfo::MOVE or OperandInfo::WHOLE_CONTAINER)  
      * if for every action in @actions, the fields in @fields are all written using
      * either MOVE or WHOLE_CONTAINER operations (in case of WHOLE_CONTAINER, no field is @fields
      * may be left unwritten by an action).
      * @returns OperandInfo::MIXED if there is a mix of WHOLE_CONTAINER and MOVE operations in
      * the same action.
      */
    unsigned container_operation_type(
        const ordered_set<const IR::MAU::Action*>&,
        const PHV::Allocation::MutuallyLiveSlices&);

    /** Given a set of MutuallyLiveSlices @container_state and the state of allocation @alloc, this
      * function generates packing constraints induced by instructions in the action @action. These
      * induced packing constraints are added to the UnionFind structure @packing_constraints.
      * Finally, when @pack_unallocated_only is false, all field slices (both allocated and
      * unallocated sources) in @container_state must be packed in the same container. When
      * @pack_unallocated_only is true, only unallocated field slices in @container_state must be
      * packed together.
      */
    void pack_slices_together(
        const PHV::Allocation& alloc,
        PHV::Allocation::MutuallyLiveSlices& container_state,
        UnionFind<PHV::FieldSlice> &packing_constraints,
        const IR::MAU::Action* action,
        bool pack_unallocated_only);

    /** Check that at least one container in a two source PHV instruction is aligned with the
      * destination
      */
    boost::optional<ClassifiedSources> verify_two_container_alignment(
            const PHV::Allocation& alloc,
            const PHV::Allocation::MutuallyLiveSlices& container_state,
            const IR::MAU::Action* action,
            const PHV::Container destination);

    /** Returns offset (difference between lo bits) by which slice @a differs from slice @b
      * offset = (a.lo - b.lo) % b.container().size()
      * Invariant: Can only be called if @a and @b are assigned to same sized containers
      */
    inline int getOffset(le_bitrange a, le_bitrange b, PHV::Container c) const;

    /** Check that the bitmasks needed to realize a two source PHV instruction are valid
      */
    bool masks_valid(
            ordered_map<size_t, ordered_set<PHV::AllocSlice>>& sources,
            const PHV::Container c) const;

    /** For each set generated in @copacking_constraints, populate map @req_container with the
      * unallocated field slice and the container to which it should be allocated (same as the
      * container used by other allocated sources in that set).
      * @returns false if any mutually unsatisfiable container requirements are found.
      */
    bool assign_containers_to_unallocated_sources(
            const PHV::Allocation& alloc,
            const UnionFind<PHV::FieldSlice>& copacking_constraints,
            ordered_map<PHV::FieldSlice, PHV::Container>& req_container);

    //  (xxx)Deep [Specific Case Alert]: This will probably be subsumed by another function that
    //  handles the general case of producing conditional constraints for n unallocated sources
    //  packed into 2 containers.
    /** For cases where we have exactly two unallocated source PHV slices and no action
      * data/constant source (any number of allocated slices are okay), we need to enforce an
      * alignment for one of the source PHV slices. We choose to enforce the alignment constraint
      * for the source slice with the smaller width (which likely has more wiggle room for placement
      * within a container). This function returns the smaller of two unallocated slices found in
      * @copacking_constraints. It also uses @alloc to check that the two slices present are indeed,
      * unallocated.  @returns boost::none, if there are more than two unallocated source slices in
      * @copacking_constraints.
      */
    boost::optional<PHV::FieldSlice> get_smaller_source_slice(
            const PHV::Allocation& alloc,
            const UnionFind<PHV::FieldSlice>& copacking_constraints,
            const ordered_set<PHV::FieldSlice>& container_state);

    /// (xxx)Deep [Artificial Constraint]: Right now action bus allocation requires any destination
    /// written by meter colors to be allocated to a 8-bit PHV. This set keeps a track of all such
    /// destinations. To be removed when Evan lands his patch relaxing the above requirement.
    ordered_set<const PHV::Field*> meter_color_destinations;

    /// (xxx)Deep [Artificial Constraint]: Right now, table placement requires that any field that
    /// gets its value from METER_ALU, HASH_DIST, RANDOM, or METER_COLOR, then it cannot be packed
    /// with other fields written in the same action
    ordered_map<const PHV::Field*, ordered_set<const IR::MAU::Action*>> special_no_pack;

    /// (xxx)Deep [Artificial Constraint]: @returns false if there is a field in @container_state
    /// written by METER_ALU, HASH_DIST, RANDOM, or METER_COLOR, and another field in
    /// @container_state is written by the same action
    bool checkSpecialityPacking(ordered_set<const PHV::Field*>& fields) const;

 public:
    explicit ActionPhvConstraints(const PhvInfo &p, const PackConflicts& c)
    : phv(p), conflicts(c), constraint_tracker(ConstraintTracker(p, *this)) { }

    /// (xxx)Deep [HACK WARNING]: Right now action bus allocation requires any destination written
    /// by meter colors to be allocated to a 8-bit PHV. This set keeps a track of all such
    /// destinations. To be removed when Evan lands his patch relaxing the above requirement.
    bool is_meter_color_destination(const PHV::Field* f) const {
        return meter_color_destinations.count(f) > 0;
    }

    /// @returns true if the fields @f1 and @f2 have a pack conflict.
    bool hasPackConflict(const PHV::Field* f1, const PHV::Field* f2) const {
        return conflicts.hasPackConflict(f1, f2);
    }

    /// @returns true if the field @f is written using a speciality read (METER_ALU, HASH_DIST,
    /// RANDOM, or METER_COLOR).
    bool hasSpecialityReads(const PHV::Field* f) const {
        ordered_set<const PHV::Field*> fields;
        fields.insert(f);
        return (!checkSpecialityPacking(fields) || is_meter_color_destination(f));
    }

    /// @returns all the fields that are written using meter color fields.
    ordered_set<const PHV::Field*>& meter_color_dests() {
        return meter_color_destinations;
    }

    /// @returns all the fields that are written using meter color fields.
    const ordered_set<const PHV::Field*>& meter_color_dests() const {
        return meter_color_destinations;
    }

    /// @returns the set of all the actions which write field @f.
    ordered_set<const IR::MAU::Action*> actions_writing_fields(const PHV::Field* f) const {
        return constraint_tracker.written_in(PHV::FieldSlice(f, StartLen(0, f->size)));
    }

    /// @returns the set of all actions which read field @f.
    ordered_set<const IR::MAU::Action*> actions_reading_fields(const PHV::Field* f) const {
        return constraint_tracker.read_in(PHV::FieldSlice(f, StartLen(0, f->size)));
    }

    /// @returns the set of fields which are sources for field @f across all actions.
    ordered_set<const PHV::Field*> field_sources(const PHV::Field* f) const;

    /// @returns the set of fields which use field @f as sources, across all actions.
    ordered_set<const PHV::Field*> field_destinations(const PHV::Field* f) const;

    /// @returns true if the field @f is only ever written by move operations.
    bool move_only_operations(const PHV::Field* f) const;

    /// @returns true if: for every slice s in @container_state, if an action a in @set_of_actions
    /// writes that slice, then all other slices in @container_state are also written by a; and
    /// if an action b in @set_of_actions does not write slice s, then all other slices in
    /// @container_state are also not written by action b.
    bool all_field_slices_written_together(
            const PHV::Allocation::MutuallyLiveSlices& container_state,
            const ordered_set<const IR::MAU::Action*>& set_of_actions) const;

    /** Checks whether packing @slices into a container will violate MAU action
     * constraints.
     *
     * @returns bit positions at which unallocated slices must be allocated for
     * the proposed packing to be valid, or boost::none if no packing is
     * possible.  An empty map indicates the proposed packing is
     * unconditionally valid.
     *
     * XXX(deep): Right now, the packing constraints generated by can_pack()
     * have one limitation.  Suppose there are n sources related to moves for a
     * container in a particular action, and 2 of the sources (s1 and s2) are
     * already allocated. In that case, valid packing requires the remaining
     * n-2 sources to be packed with either s1 or s2. Right now, s1, s2, and
     * all the other sources are put in the same set in the UnionFind. The
     * allocator needs to be aware of this case.
     */
    boost::optional<PHV::Allocation::ConditionalConstraints>
    can_pack(const PHV::Allocation& alloc, std::vector<PHV::AllocSlice>& slices);

    /// Convenience method that transforms @slice into a singleton slice list,
    /// which is passed to `can_pack` above.
    boost::optional<PHV::Allocation::ConditionalConstraints>
    can_pack(const PHV::Allocation& alloc, const PHV::AllocSlice& slice);

    /** Approximates a topographical sorting of field lists such that all source-only slice lists
      * are considered for allocation before destination-only slice lists.
      * Sorts a given list of slice list such that the slice lists used the least times as sources
      * are first allocated containers. If the number of times fields in a slice list is used as
      * sources is the same as another slice list, the slice list which is written to in more
      * actions ranks earlier in the sorting.
      */
    void sort(std::list<const PHV::SuperCluster::SliceList*>& slice_list);

    /** Approximates a topographical sorting of FieldSlices such that all FieldSlices used only as
      * sources are considered for allocation before destination-only FieldSlices
      */
    void sort(std::vector<PHV::FieldSlice>& slice_list);

    /** @returns the set of fields that are read in action @act
      */
    ordered_set<const PHV::Field*> actionReads(const IR::MAU::Action* act) const;

    /** @returns the set of fields that are written in action @act
      */
    ordered_set<const PHV::Field*> actionWrites(const IR::MAU::Action* act) const;

    /** For GTest function.
      * Checks if the field_writes_to_actions ordered_map entry is valid or not
      */
    bool is_in_field_writes_to_actions(cstring, const IR::MAU::Action *) const;
    /** For GTest function.
      * Checks if the action_to_writes ordered_map entry is valid or not
      */
    bool is_in_action_to_writes(const IR::MAU::Action *, cstring) const;
    /** For GTest function.
      * Checks if the write_to_reads_per_action ordered_map entry is valid or not
      */
    bool is_in_write_to_reads(cstring, const IR::MAU::Action *, cstring) const;
};

std::ostream &operator<<(std::ostream &out, const ActionPhvConstraints::OperandInfo& info);

#endif  /* BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_ */
