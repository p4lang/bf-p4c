#ifndef BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_

#include <boost/optional.hpp>
#include "ir/ir.h"
#include "bf-p4c/lib/union_find.hpp"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils.h"

/** This class is meant to gather action information as well as provide information to PHV analysis
  * through function calls.  This must be run after InstructionSelection, as it is dependent on
  * ActionAnalysis, but during PHV analysis (before PHV_MAU_Group_Assignments).
  * container_no_pack() and container_pack_cohabit() in PHV_MAU_Group_Assignments then query the
  * information contained in class members here to determine constraints on packing induced by MAU
  * actions. 
 */
class ActionPhvConstraints : public Inspector {
 private:
    /// Defines a struct for returning number of containers
    struct NumContainers {
        size_t num_allocated;
        size_t num_unallocated;

        explicit NumContainers(const size_t numAlloc, const size_t numUnalloc) :
            num_allocated(numAlloc), num_unallocated(numUnalloc) {}

        NumContainers() : num_allocated(0), num_unallocated(0) {}
    };

    /// Defines a struct for a particular field operation: either read or write
    // TODO: Will we ever need a boolean indicating read or write in this
    // struct?
    struct FieldOperation {
        int unique_action_id;
        enum field_read_flags_t { MOVE = 1,
                                  WHOLE_CONTAINER = (1 << 1),
                                  ANOTHER_OPERAND = (1 << 2),
                                  MIXED = (1 << 3),
                                  WHOLE_CONTAINER_SAME_FIELD = (1 << 4) };
        uint8_t flags = 0;
        bool ad = false;
        bool constant = false;
        int64_t const_value = 0;
        const PHV::Field *phv_used;
        cstring action_name;

        bool operator < (FieldOperation other) const {
            return (phv_used->id < other.phv_used->id);
        }

        bool operator == (FieldOperation other) const {
            return (phv_used->id == other.phv_used->id);
        }

        bool operator == (const PHV::Field* field) const {
            return (phv_used->id == field->id);
        }

        explicit FieldOperation(const PHV::Field *field, int id = -1) : unique_action_id(id),
        phv_used(field) {}

        FieldOperation() : phv_used(nullptr) {}
    };

    profile_t init_apply(const IR::Node *root) override;
    /** Builds the data structures to be used in the API function call 
      * Also checks that the actions can be scheduled on Tofino in the same stage
      * without splitting and without considering PHV allocation (yet to happen)
      */
    bool preorder(const IR::MAU::Action *act) override;
    /** Print out all the maps created in ActionPhvConstraints
      */
    void end_apply() override;

    /** Debug function to print the total number of reads and writes across all actions for the
      * fields in the vector of AllocSlices represented by @slices
      */
    void field_ordering(std::vector<PHV::AllocSlice>& slices);

    /// Any action within this set will have written the key field
    ordered_map<const PHV::Field *, ordered_set<const IR::MAU::Action *>>
        field_writes_to_actions;

    /// Any FieldOperation (Field) within the set will have been written in the
    /// key action
    ordered_map<const IR::MAU::Action *, ordered_set<FieldOperation>> action_to_writes;

    /// Any FieldOperation in the std::vector will use the following as an operand in
    /// action where the key is the field written in that action
    ordered_map<const PHV::Field *, ordered_map<const IR::MAU::Action *,
        std::vector<FieldOperation>>> write_to_reads_per_action;
    ordered_map<const PHV::Field *, ordered_map<const IR::MAU::Action *, ordered_set<const
        PHV::Field *>>> read_to_writes_per_action;

    /// Used to generate unique action IDs when creating `struct FieldOperation` objects
    static int current_action;

    /** Given the state of PHV allocation represented by @alloc and @container_state, a vector of
      * slices to be packed together and mutually live in a given container
      * Also populates the UnionFind structure @copacking_constraints, used to report new packing
      * constraints induced by can_pack()
      * @returns the number of container sources used in @action
      */
    NumContainers num_container_sources(const PHV::Allocation& alloc,
            PHV::Allocation::MutuallyLiveSlices container_state, const IR::MAU::Action* action,
            UnionFind<PHV::FieldSlice>& copacking_constraints);

    boost::optional<PHV::AllocSlice> getSourcePHVSlice(const PHV::Allocation& alloc,
            PHV::AllocSlice& slice, const IR::MAU::Action* action, size_t source_num = 0);

    /** @returns true if @fields packed in the same container read from action data or from constant
      * in action @act
      */
    bool has_ad_or_constant_sources(std::vector<const PHV::Field *>& fields, const IR::MAU::Action
            *act);

    /** Check if two fields share the same container
      */
    bool fields_share_container(const PHV::Field *, const PHV::Field *);

    /** Returns a FieldOperation structure if field is found to be written within
      * action act
      */
    boost::optional<FieldOperation> is_written(const IR::MAU::Action *, const PHV::Field *);

    /** @returns the number of no unallocated bits in a set of mutually live field slices @slice
      * in container @c
      */
    int unallocated_bits(PHV::Allocation::MutuallyLiveSlices, const PHV::Container) const;

    /** @returns true if all the alloc slices in the set @container_state together make up
      * adjacent slices of the same field
      */
    bool are_successive_field_slices(PHV::Allocation::MutuallyLiveSlices container_state);

    /** @returns the type of operation (FieldOperation::MOVE or FieldOperation::WHOLE_CONTAINER)  
      * if for every action in @actions, the fields in @fields are all written using
      * either MOVE or WHOLE_CONTAINER operations (in case of WHOLE_CONTAINER, no field is @fields
      * may be left unwritten by an action).
      * @returns FieldOperation::MIXED if there is a mix of WHOLE_CONTAINER and MOVE operations in
      * the same action.
      */
    unsigned container_operation_type(ordered_set<const IR::MAU::Action*>&, std::vector<const
            PHV::Field*>&);

    /** Given a set of MutuallyLiveSlices @container_state and the state of allocation @alloc, this
      * function generates packing constraints induced by instructions in the action @action. These
      * induced packing constraints are added to the UnionFind structure @packing_constraints.
      * Finally, when @pack_unallocated_only is false, all field slices (both allocated and
      * unallocated sources) in @container_state must be packed in the same container. When
      * @pack_unallocated_only is true, only unallocated field slices in @container_state must be
      * packed together.
      */
    void pack_slices_together(const PHV::Allocation& alloc, PHV::Allocation::MutuallyLiveSlices&
            container_state, UnionFind<PHV::FieldSlice> &packing_constraints, const
            IR::MAU::Action* action, bool pack_unallocated_only);

    /** Print the state of the maps */
    void printMapStates();

 public:
    explicit ActionPhvConstraints(const PhvInfo &p) : phv(p) {}

    const PhvInfo &phv;

    /** Checks whether packing @fields into a container will violate MAU action constraints.
      * @returns a boost::optional<UnionFind<PHV::FieldSlice>> object, which is interpreted as
      * follows:
      * - When boost::none is returned, @slice cannot be packed in container @c with
      *   mutually live slices specified by @container_state.
      * - The UnionFind object (when it is returned) contains a set of sets of field slices,
      *   requiring that each field slice in the inner set be packed together.
      *
      * Example,
      *   Metadata m {a, b, c, d, ...}  // Metadata header
      *   Header vlan {                 // VLAN header
      *       bit<3> priority;
      *       bit<1> cfi;
      *       bit<12> tag; }
      *   Also, there are other headers m1 and m2 of type metadata m
      *
      *   Action {
      *       m1.a = m2.a;
      *       priority = m.c;
      *       tag = m.d; }
      *
      * In this case, if container_state is {priority, cfi} and the candidate slice (slice) is tag,
      * then the UnionFind structure will return {{m2.a}, {m.c, m.d}}.
      *
      * xxx(deep): Right now, the packing constraints generated by can_pack() have one limitation.
      * Suppose there are n sources related to moves for a container in a particular action, and 2
      * of the sources (s1 and s2) are already allocated. In that case, valid packing requires the
      * remaining n-2 sources to be packed with either s1 or s2. Right now, s1, s2, and all the
      * other sources are put in the same set in the UnionFind. The allocator needs to be aware of
      * this case.
      */
    boost::optional<UnionFind<PHV::FieldSlice>> can_pack(const PHV::Allocation& alloc, const
            PHV::AllocSlice& slice);

    /** In case of SliceLists, we might try to pack multiple AllocSlices together into a container.
      * This function checks whether such a packing is possible by internally calling the above
      * can_pack method
      */
    boost::optional<UnionFind<PHV::FieldSlice>> can_pack(const PHV::Allocation& alloc,
            std::vector<PHV::AllocSlice>& slices);

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

#endif  /* BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_ */
