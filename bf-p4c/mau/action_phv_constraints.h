#ifndef TOFINO_MAU_ACTION_PHV_CONSTRAINTS_H_
#define TOFINO_MAU_ACTION_PHV_CONSTRAINTS_H_

#include "mau_visitor.h"
#include "tofino/phv/phv_fields.h"

/** This class is meant to gather action information as well as provide information to
 *  PHV analysis through function calls.  This must be run after InstructionSelection, as
 *  it is dependent on ActionAnalysis, but can be used before PHV allocation.
 */
class ActionPhvConstraints : public MauInspector {
    struct FieldRead {
        int unique_action_id;
        enum field_read_flags_t { MOVE = 1,
                                  SINGLE_CONTAINER = (1 << 1),
                                  ANOTHER_OPERAND = (1 << 2)
        };
        unsigned flags = 0;
        bool ad_or_constant = false;
        const PhvInfo::Field *phv_read = nullptr;
    };
    const PhvInfo &phv;

    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::MAU::Action *act) override;

    // Any field within the set will have been written in the same action as the key field
    ordered_map<const PhvInfo::Field *, ordered_set<const PhvInfo::Field *>> shared_writes;
    // Any FieldRead in the vector will use the following as an operand in action where
    // the key is the field written in that action
    ordered_map<const PhvInfo::Field *, vector<FieldRead>> write_to_reads;
    // Any field within the set will have been written by the key field
    ordered_map<const PhvInfo::Field *, ordered_set<const PhvInfo::Field *>> read_to_writes;
    int current_action = 0;

 public:
    explicit ActionPhvConstraints(const PhvInfo &p) : phv(p) {}
    // FIXME: This is where all the APIs to PHV allocation need to be defined

    // GTEST functions
    bool is_in_shared_writes(cstring write, cstring shared_write) const;
    bool is_in_write_to_reads(cstring write, cstring read) const;
    bool is_in_read_to_writes(cstring read, cstring write) const;
};


#endif  /* TOFINO_MAU_ACTION_PHV_CONSTRAINTS_H_ */
