#ifndef EXTENSIONS_BF_P4C_MAU_HANDLE_ASSIGN_H_
#define EXTENSIONS_BF_P4C_MAU_HANDLE_ASSIGN_H_

#include "bf-p4c/mau/mau_visitor.h"

/**
 * The purpose of this pass is to assign the action handle for the context JSON node
 * in the compiler. This is required because the actions are no longer associated with the
 * action data table in the assembler, but with the match table instead.
 *
 * This will also validate some constraints currently imposed by Brig's allocation of
 * actions on action profiles, mainly that the actions for each action profile must be the
 * same action, (at least the same action name and parameters)  
 */
class AssignActionHandle : public PassManager {
    class ActionProfileImposedConstraints : public MauInspector {
        ordered_map<const IR::MAU::ActionData *, std::set<cstring>> profile_actions;
        bool preorder(const IR::MAU::ActionData *) override;

     public:
        ActionProfileImposedConstraints() {}
    };

    typedef ordered_map<const IR::MAU::Action *, unsigned> HandleAssignments;
    HandleAssignments handle_assignments;

    class DetermineHandle : public MauInspector {
        static constexpr unsigned INIT_ACTION_HANDLE = (0x20 << 24) + 2;
        unsigned handle_position = 0;

        AssignActionHandle &self;
        typedef ordered_map<cstring, unsigned> ProfileAssignment;
        ordered_map<const IR::MAU::ActionData *, ProfileAssignment> profile_assignments;
        bool preorder(const IR::MAU::Action *) override;
        profile_t init_apply(const IR::Node *root) override;
        unsigned next_handle() {
            unsigned rv = INIT_ACTION_HANDLE + handle_position;
            handle_position++;
            return rv;
        }

     public:
        explicit DetermineHandle(AssignActionHandle &aah) : self(aah) { }
    };

    class AssignHandle : public MauModifier {
        const AssignActionHandle &self;
        bool preorder(IR::MAU::Action *) override;

     public:
        explicit AssignHandle(const AssignActionHandle &aah) : self(aah) { }
    };

 public:
    AssignActionHandle() {
        addPasses({
            new ActionProfileImposedConstraints,
            new DetermineHandle(*this),
            new AssignHandle(*this)
        });
    }
};

#endif  /* EXTENSIONS_BF_P4C_MAU_HANDLE_ASSIGN_H_ */
