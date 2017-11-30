#ifndef BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_

#include <boost/optional.hpp>
#include "ir/ir.h"
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
 public:
    using CohabitSet = ordered_set<const PHV::Field*>;

 private:
    /// Defines a struct for a particular field operation: either read or write
    // TODO: Will we ever need a boolean indicating read or write in this
    // struct?
    struct FieldOperation {
        int unique_action_id;
        enum field_read_flags_t { MOVE = 1,
                                  WHOLE_CONTAINER = (1 << 1),
                                  ANOTHER_OPERAND = (1 << 2),
                                  MIXED = (1 << 3)
        };
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

    const PhvInfo &phv;

    profile_t init_apply(const IR::Node *root) override;
    /** Builds the data structures to be used in the API function call 
      * Also checks that the actions can be scheduled on Tofino in the same stage
      * without splitting and without considering PHV allocation (yet to happen)
      */
    bool preorder(const IR::MAU::Action *act) override;
    /** Print out all the maps created in ActionPhvConstraints
      */
    void end_apply() override;

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
      * @returns the number of container sources used in @action
      */
    size_t num_container_sources(const PHV::Allocation& alloc, PHV::Allocation::MutuallyLiveSlices
            container_state, const IR::MAU::Action* action);

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

    /** @returns the type of operation (FieldOperation::MOVE or FieldOperation::WHOLE_CONTAINER)  
      * if for every action in @actions, the fields in @fields are all written using
      * either MOVE or WHOLE_CONTAINER operations (in case of WHOLE_CONTAINER, no field is @fields
      * may be left unwritten by an action).
      * @returns FieldOperation::MIXED if there is a mix of WHOLE_CONTAINER and MOVE operations in
      * the same action.
      */
    unsigned container_operation_type(ordered_set<const IR::MAU::Action*>&, std::vector<const
            PHV::Field*>&);

    /** Print the state of the maps */
    void printMapStates();

 public:
    explicit ActionPhvConstraints(const PhvInfo &p) : phv(p) {}

    /** Checks whether packing @fields into a container will violate MAU action constraints.
      */
    boost::optional<std::vector<CohabitSet>> can_pack(const PHV::Allocation& alloc, const
            PHV::AllocSlice& slice, PHV::Allocation::MutuallyLiveSlices container_state, const
            PHV::Container c);

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
