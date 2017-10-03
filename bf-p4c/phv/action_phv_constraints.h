#ifndef BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_ACTION_PHV_CONSTRAINTS_H_

#include <boost/optional.hpp>
#include "ir/ir.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/cluster_phv_container.h"

/** This class is meant to gather action information as well as provide information to PHV analysis
  * through function calls.  This must be run after InstructionSelection, as it is dependent on
  * ActionAnalysis, but during PHV analysis (before PHV_MAU_Group_Assignments).
  * container_no_pack() and container_pack_cohabit() in PHV_MAU_Group_Assignments then query the
  * information contained in class members here to determine constraints on packing induced by MAU
  * actions. 
 */
class ActionPhvConstraints : public Inspector {
    /// Defines a struct for a particular field operation: either read or write
    // TODO: Will we ever need a boolean indicating read or write in this
    // struct?
    struct FieldOperation {
        int unique_action_id;
        enum field_read_flags_t { MOVE = 1,
                                  WHOLE_CONTAINER = (1 << 1),
                                  ANOTHER_OPERAND = (1 << 2)
        };
        uint8_t flags = 0;
        bool ad = false;
        bool constant = false;
        const PhvInfo::Field *phv_used;

        bool operator < (FieldOperation other) const {
            return (phv_used->id < other.phv_used->id);
        }

        bool operator == (FieldOperation other) const {
            return (phv_used->id == other.phv_used->id);
        }

        bool operator == (const PhvInfo::Field* field) const {
            return (strcmp(phv_used->name, field->name) == 0);
        }

        explicit FieldOperation(const PhvInfo::Field *field, int id = -1) : unique_action_id(id),
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
    ordered_map<const PhvInfo::Field *, ordered_set<const IR::MAU::Action *>>
        field_writes_to_actions;

    /// Any FieldOperation (Field) within the set will have been written in the
    /// key action
    ordered_map<const IR::MAU::Action *, ordered_set<FieldOperation>> action_to_writes;

    /// Any FieldOperation in the std::vector will use the following as an operand in
    /// action where the key is the field written in that action
    ordered_map<const PhvInfo::Field *, ordered_map<const IR::MAU::Action *,
        std::vector<FieldOperation>>> write_to_reads_per_action;
    ordered_map<const PhvInfo::Field *, ordered_map<const IR::MAU::Action *, ordered_set<const
        PhvInfo::Field *>>> read_to_writes_per_action;

    /// Used to generate unique action IDs when creating `struct FieldOperation` objects
    static int current_action;

    /** If PHV allocation has already been done for some fields, this function
      * returns the number of unique containers used as sources
      * @param
      *     std::vector<PhvInfo::Field*>: that are candidates for sharing a container
      *     IR::MAU::Action *: action for which number of sources must be determined
      */
    uint32_t num_sources(std::vector<const PhvInfo::Field *>, const IR::MAU::Action *);

    /** Check if two fields share the same container
      */
    bool fields_share_container(const PhvInfo::Field *, const PhvInfo::Field *);

    /** Returns a FieldOperation structure if field is found to be written within
      * action act
      */
    boost::optional<FieldOperation> is_written(const IR::MAU::Action *, const PhvInfo::Field *);

 public:
    explicit ActionPhvConstraints(const PhvInfo &p) : phv(p) {}


    /** Print the state of the maps */
    void printMapStates();

    /** Checks whether packing @fields into a container will violate MAU action constraints.
      * 
      * For each action that writes to any field in @fields, calculate the number of sources
      * (containers/action data/constants) read by all instructions that write to @fields. If the
      * number of sources exceeds 2, packing is not possible.
      *
      * Further, all instructions that write to any field in @fields in the same action must be the
      * same kind of instruction---e.g. all "set" instructions, or all "and" instructions, etc.
      *
      * Also, any action writing to only part of a container may only do so for "set" operations
      * using a bitmask, deposit-field, or load-const instruction. 
      *
      * @returns `ActionAnalysis::ContainerAction::NO_PROBLEM` if the proposed packing satisfied
      * action constraints.
      *
      * @warning This method reads data structures that are internal to PHV allocation and hold
      * intermediate results (via the `PhvInfo` object). It may only be safely invoked *during* PHV
      * allocation.
      */
    // TODO: Distinguish between non-move operations
    unsigned can_cohabit(std::vector<const PhvInfo::Field *>& fields);

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
