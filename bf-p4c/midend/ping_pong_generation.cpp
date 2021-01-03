/**
 *  Detects registers that are used by ingress and ghost, creates
 *  a duplicate tables and registers if needed and attaches
 *  a ping-pong mechanism onto them.  
 *
 *  This file contains implementation of different methods, refer to the header file
 *  for more abstract overview to determine what each method should do and is used for.
 */
#include "ping_pong_generation.h"

namespace BFN {

// CONSTANTS --------------------------------------------------------------------------------------
const cstring PingPongGeneration::ID_PING_PONG_SUFFIX = "__gen_duplicate_ping_pong";
const cstring PingPongGeneration::GMD_STRUCTURE_NAME = "ghost_intrinsic_metadata_t";
const cstring PingPongGeneration::PING_PONG_FIELD_NAME = "ping_pong";

// HELPER VISITORS --------------------------------------------------------------------------------
// This visitor class is a base for other classes that change declarations
class PingPongGeneration::DeclarationChanger: public Transform {
 public:
    PingPongGeneration &self;
    std::set<cstring> names_to_change;

    // Update StringLiteral
    IR::Node *postorder(IR::StringLiteral* sl) {
        // Check if this is within "name" Annotation
        auto annot = findContext<IR::Annotation>();
        if (!annot || annot->name != "name")
            return sl;
        // Check if this is one of the identifiers that are being worked on
        // (use only the name after the last ".")
        std::string local_name(sl->value);
        size_t pos = 0;
        while ((pos = local_name.find(".")) != std::string::npos)
            local_name.erase(0, pos + 1);
        if (!names_to_change.count(local_name))
            return sl;
        // Update and return new literal
        sl->value = sl->value + PingPongGeneration::ID_PING_PONG_SUFFIX;
        return sl;
    }

    explicit DeclarationChanger(PingPongGeneration &self,
                                std::set<cstring> &names_to_change) :
         self(self), names_to_change(names_to_change) {}
};


// This visitor changes specific references in new cloned register action
class PingPongGeneration::RegActionChanger: public PingPongGeneration::DeclarationChanger {
    // Variables and updating of proper StringLiteral are inherited from DeclarationChanger
    // Update path to register
    IR::Node *postorder(IR::Path* path) {
        // Check if we are in an argument
        auto arg = findContext<IR::Argument>();
        if (!arg)
            return path;
        // Clone and update new path
        return self.appendPingPongSuffix(path, names_to_change);
    }

 public:
    explicit RegActionChanger(PingPongGeneration &self,
                              std::set<cstring> &names_to_change) :
         DeclarationChanger(self, names_to_change) {}
};

// This visitor changes specific references in new cloned P4 action
class PingPongGeneration::P4ActionChanger: public PingPongGeneration::DeclarationChanger {
    // Variables and updating of proper StringLiteral are inherited from DeclarationChanger
    // Update path to register action
    IR::Node *postorder(IR::Path* path) {
        // Check for "execute" member
        auto member = findContext<IR::Member>();
        if (!member || member->member != "execute")
            return path;
        // Clone and update new path
        return self.appendPingPongSuffix(path, names_to_change);
    }

 public:
    explicit P4ActionChanger(PingPongGeneration &self, std::set<cstring> &names_to_change) :
        DeclarationChanger(self, names_to_change) {}
};

// This visitor changes specific references in new cloned P4 table
class PingPongGeneration::P4TableChanger: public PingPongGeneration::DeclarationChanger {
    // Variables and updating of proper StringLiteral are inherited from DeclarationChanger
    // Update path to p4 action
    IR::Node *postorder(IR::Path* path) {
        // Check for "default_action" property
        auto prop = findContext<IR::Property>();
        // Check for ActionListElement
        auto ale = findContext<IR::ActionListElement>();
        // If neither is correct, stop
        if (!prop || prop->name != "default_action")
            if (!ale)
                return path;
        // Clone and update new path
        return self.appendPingPongSuffix(path, names_to_change);
    }

 public:
    explicit P4TableChanger(PingPongGeneration &self, std::set<cstring> &names_to_change) :
         DeclarationChanger(self, names_to_change) {}
};

// This visitor changes P4 table references in cloned MethodCallStatement
class PingPongGeneration::ApplyMCSChanger: public Transform {
    PingPongGeneration &self;
    const cstring orig_table_name;
    const IR::P4Table* dupl_table;
    const cstring orig_action_name;

    // Explicit visits to "type" member variables
    IR::Node *preorder(IR::Expression* exp) {
        visit(exp->type, "type");
        return exp;
    }
    IR::Node *preorder(IR::Member* member) {
        visit(member->type, "type");
        return member;
    }
    // Swap p4 table for duplicate table
    IR::Node *preorder(IR::P4Table* tab) {
        // Check if this is the worked on table
        if (tab->name != orig_table_name)
            return tab;
        // Return the duplicate table
        return dupl_table->clone();
    }
    // Update name of p4 table
    IR::Node *postorder(IR::Type_Struct* ts) {
        // Check if this is one of the identifiers that are being worked on
        if (ts->name != orig_table_name)
            return ts;
        // Create a duplicate and update it
        return new IR::Type_Struct(IR::ID(ts->name + ID_PING_PONG_SUFFIX),
                                   ts->annotations, ts->fields);
    }
    // Update path to p4 table
    IR::Node *postorder(IR::Path* path) {
        std::set<cstring> names_to_change = { orig_table_name, orig_action_name };
        // Clone and update new path
        return self.appendPingPongSuffix(path, names_to_change);
    }

 public:
    explicit ApplyMCSChanger(PingPongGeneration &self,
                             const cstring& orig_table_name,
                             const IR::P4Table* dupl_table,
                             const cstring& orig_action_name) :
         self(self), orig_table_name(orig_table_name),
         dupl_table(dupl_table), orig_action_name(orig_action_name) {}
};

// Finds a ghost_metadata.ping_pong field reference in a subtree
class PingPongGeneration::PingPongFieldFinder: public Inspector {
    bool preorder(const IR::Member* member) override {
        // We only care about ping_pong
        if (member->member != PING_PONG_FIELD_NAME)
            return false;
        // Get PathExpression
        auto path_exp = member->expr->to<IR::PathExpression>();
        if (!path_exp)
            return false;
        // Check if this is part of metadata
        if (path_exp->type->is<IR::Type_Header>()
            || path_exp->type->is<IR::Type_Struct>()) {
            found = true;
        }
        return false;
    }

 public:
    bool found;
    PingPongFieldFinder() :
         found(false) {}
};

// HELPER FUNCTIONS -------------------------------------------------------------------------------
// Creates and updates duplicate of a Path
inline IR::Path* PingPongGeneration::appendPingPongSuffix(IR::Path* path,
                                                          std::set<cstring>& names_to_change) {
    // Check if this is one of the identifiers that are being worked on
    if (!names_to_change.count(path->name))
        return path;
    // Create a duplicate and update it
    path->name = IR::ID(path->name + ID_PING_PONG_SUFFIX);
    return path;
}

// Creates and updates a duplicate of given declaration (reg action,
// p4 action or p4 table) and then places it into gress objects
inline void PingPongGeneration::duplicateNodeDeclaration(
                                        const IR::Declaration* node,
                                        IR::BFN::TnaControl* gress,
                                        std::set<cstring>& names_to_change) {
    // Create new duplicate node and apply changes via visitors
    const IR::Node* changed_new_node = node;
    auto new_name = IR::ID(node->name + ID_PING_PONG_SUFFIX);
    if (node->is<IR::Declaration_Instance>()) {
        auto DI_node = node->to<IR::Declaration_Instance>();
        auto new_node = new IR::Declaration_Instance(
                                new_name,
                                DI_node->annotations,
                                DI_node->type,
                                DI_node->arguments,
                                DI_node->initializer);
        changed_new_node = new_node->apply(RegActionChanger(*this, names_to_change));
    } else if (node->is<IR::P4Action>()) {
        auto P4A_node = node->to<IR::P4Action>();
        auto new_node = new IR::P4Action(
                                new_name,
                                P4A_node->annotations,
                                P4A_node->parameters,
                                P4A_node->body);
        changed_new_node = new_node->apply(P4ActionChanger(*this, names_to_change));
    } else if (node->is<IR::P4Table>()) {
        auto P4T_node = node->to<IR::P4Table>();
        auto new_node = new IR::P4Table(
                                new_name,
                                P4T_node->annotations,
                                P4T_node->properties);
        changed_new_node = new_node->apply(P4TableChanger(*this, names_to_change));
        // Also save the duplicate table for later use
        p4TableToDuplicateTable[node->to<IR::P4Table>()] = changed_new_node->to<IR::P4Table>();
    } else {
        return;
    }
    // Add it into gress declarations (right next to the original one)
    gress->controlLocals.insert(
        std::find(gress->controlLocals.begin(), gress->controlLocals.end(), node),
        changed_new_node->to<IR::Declaration>());
    return;
}

// MAIN VISITORS ----------------------------------------------------------------------------------
// Gets all of the registers used and their actions
bool PingPongGeneration::GetAllRegisters::preorder(const IR::MethodCallExpression* mce) {
    // Find the instance method of RegisterAction
    auto mi = P4::MethodInstance::resolve(mce, self.refMap, self.typeMap);
    if (!mi)
        return false;
    auto em = mi->to<P4::ExternMethod>();
    if (!em || em->originalExternType->name != "RegisterAction")
        return false;
    auto ra_decl = mi->object->to<IR::Declaration_Instance>();
    if (!ra_decl || ra_decl->arguments->size() < 1 ||
        !ra_decl->arguments->at(0)->expression->is<IR::PathExpression>())
        return false;
    // Get the register out of the register action
    auto r_path = ra_decl->arguments->at(0)->expression->to<IR::PathExpression>()->path;
    if (!r_path)
        return false;
    auto r_decl = self.refMap->getDeclaration(r_path)->to<IR::Declaration_Instance>();
    if (!r_decl)
        return false;
    // Get gress and P4Action
    auto gress = findContext<IR::BFN::TnaControl>();
    if (!gress)
        return false;
    auto gress_index = gress->thread;
    auto p4_action = findContext<IR::P4Action>();
    if (!p4_action)
        return false;

    // Check if it already exists
    if (self.registerToRegisterAction[gress_index].count(r_decl)) {
        // There should only be one to one mapping, this is not ping-pong
        self.registerToRegisterAction[gress_index][r_decl] = nullptr;
        self.registerToP4Action[gress_index][r_decl] = nullptr;
        self.p4ActionToRegister[gress_index][p4_action] = nullptr;
        // Will never be valid
        self.registerToValid[r_decl] = false;
    } else {
        self.registerToRegisterAction[gress_index][r_decl] = ra_decl;
        self.registerToP4Action[gress_index][r_decl] = p4_action;
        self.p4ActionToRegister[gress_index][p4_action] = r_decl;
        // Not yet valid
        self.registerToValid[r_decl] = false;
    }
    return false;
}

// Finds and adds all of the corresponding tables
// Works on call expression of the P4 action within a P4 table's
// action list
bool PingPongGeneration::AddAllTables::preorder(const IR::ActionListElement* ale) {
    // If we are not within a Table we can ignore this
    auto p4_table = findContext<IR::P4Table>();
    if (!p4_table)
        return false;

    // Check if this has MethodCallExpression
    auto mce = ale->expression->to<IR::MethodCallExpression>();
    if (!mce)
        return false;

    // Resolve the method
    auto mi = P4::MethodInstance::resolve(mce, self.refMap, self.typeMap);
    if (!mi)
        return false;
    auto ac = mi->to<P4::ActionCall>();
    if (!ac)
        return false;
    auto p4_action = ac->action;
    if (!p4_action)
        return false;

    // Find gress
    auto gress = findContext<IR::BFN::TnaControl>();
    if (!gress)
        return false;
    auto gress_index = gress->thread;

    // Check if it works with register
    if (!self.p4ActionToRegister[gress_index].count(p4_action))
        return false;

    // Get the register
    auto reg = self.p4ActionToRegister[gress_index][p4_action];
    if (!reg)
        return false;

    // Check if we already have a table for it
    if (self.p4ActionToP4Table[gress_index].count(p4_action)) {
        // There should only be one to one mapping, this is not ping-pong
        // Invalidate it
        self.registerToRegisterAction[gress_index][reg] = nullptr;
        self.registerToP4Action[gress_index][reg] = nullptr;
        self.p4ActionToRegister[gress_index][p4_action] = nullptr;
        self.p4ActionToP4Table[gress_index][p4_action] = nullptr;
        self.p4TableToRegister[gress_index][p4_table] = nullptr;
        self.registerToValid[reg] = false;
    } else {
        self.p4ActionToP4Table[gress_index][p4_action] = p4_table;
        self.p4TableToRegister[gress_index][p4_table] = reg;
        // Invalidate it if it is used in egress (reg is the only
        // thing shared by the gresses)
        if (self.registerToP4Action[EGRESS].count(reg))
            self.registerToValid[reg] = false;
        // Validate the register if we already have ingress, ghost and no egress
        else if (self.registerToP4Action[INGRESS].count(reg)
                 && self.registerToP4Action[INGRESS][reg] != nullptr
                 && self.registerToP4Action[GHOST].count(reg)
                 && self.registerToP4Action[GHOST][reg] != nullptr)
            self.registerToValid[reg] = true;
    }

    return false;
}

// Gets the identifier of ghost metadata
// This visits the parameter and checks if it is an identifier for ghost metadata
bool PingPongGeneration::CheckPingPongTables::preorder(const IR::Parameter* param) {
    // We are interested in ghost metadata paths only
    if (!param->type->is<IR::Type_Name>() ||
        param->type->to<IR::Type_Name>()->path->name != GMD_STRUCTURE_NAME)
        return false;
    // We also have to be in a gress
    auto gress = findContext<IR::BFN::TnaControl>();
    if (!gress)
        return false;
    // Parameter name is the name of ghost metadata
    self.ghost_meta_name[gress->thread] = param->name;
    return false;
}
// Find if fhost metadata is used
bool PingPongGeneration::CheckPingPongTables::preorder(const IR::Type_Header* th) {
    // We are interested in ghost metadata only
    if (th->name != GMD_STRUCTURE_NAME)
        return false;
    // Store them
    self.ghost_meta_struct = th;
    return false;
}

// Checks for tables that are already applied under ping_pong condition
// We are working on table.apply() and looking at the context it is called
// from - more specifically if it is called from within IF statement
// that looks something like "if (ghost_meta.ping_pong == ...)"
bool PingPongGeneration::CheckPingPongTables::preorder(const IR::PathExpression* path_exp) {
    // We are looking for Type_Table
    if (!path_exp->type->is<IR::Type_Table>())
        return false;

    // Check if we are inside apply
    auto member = findContext<IR::Member>();
    if (!member || member->member != "apply")
        return false;

    // Get Table declaration
    auto p4_table = self.refMap->getDeclaration(path_exp->path)->to<IR::P4Table>();
    if (!p4_table)
        return false;

    // Get gress info
    auto gress = findContext<IR::BFN::TnaControl>();
    if (!gress)
        return false;
    auto gress_index = gress->thread;

    // Get the approriate register
    if (!self.p4TableToRegister[gress_index].count(p4_table))
        return false;
    auto reg = self.p4TableToRegister[gress_index][p4_table];

    // Check if this is still valid ping-pong candidate
    if (!reg || !self.registerToValid.count(reg) || !self.registerToValid[reg])
        return false;

    // Check if there is already ping-pong mechanism attached
    // If it is we can invalidate this candidate
    // Get the IfStatement
    auto if_stmt = findContext<IR::IfStatement>();
    if (!if_stmt || !if_stmt->condition )
        return false;

    // Find the ping_pong field
    PingPongFieldFinder findPingPongField;
    if_stmt->condition->apply(findPingPongField);
    // If it was found invalidate this for ping pong generation
    if (findPingPongField.found) {
        self.registerToValid[reg] = false;
    }

    return false;
}

// Duplicates all of the required tables, registers, actions
IR::Node *PingPongGeneration::GeneratePingPongMechanismDeclarations::preorder(IR::P4Program* prog) {
    // For every register
    for (auto const & r : self.registerToValid) {
        auto reg = r.first;
        bool valid = r.second;
        // That was found to be valid for ping pong duplication
        if (valid && reg) {
            // Create duplicate register
            auto new_reg = new IR::Declaration_Instance(
                                IR::ID(reg->name + PingPongGeneration::ID_PING_PONG_SUFFIX),
                                reg->annotations,
                                reg->type,
                                reg->arguments,
                                reg->initializer);
            // Place it into the P4Program's objects
            prog->objects.insert(std::find(prog->objects.begin(), prog->objects.end(), reg),
                                 new_reg);
        }
    }

    return prog;
}
IR::Node *PingPongGeneration::GeneratePingPongMechanismDeclarations::preorder(
                                                        IR::BFN::TnaControl* gress) {
    auto gress_index = gress->thread;
    // We dont care about egress
    if (gress_index == EGRESS)
        return gress;

    for (auto const & r : self.registerToValid) {
        auto reg = r.first;
        bool valid = r.second;
        if (valid && reg) {
            auto reg_action = self.registerToRegisterAction[gress_index][reg];
            auto p4_action = self.registerToP4Action[gress_index][reg];
            auto p4_table = self.p4ActionToP4Table[gress_index][p4_action];
            if (!reg_action || !p4_action || !p4_table)
                continue;
            // Create a vector of names that are worked on
            std::set<cstring> names_to_change = { reg->name, reg_action->name, p4_action->name,
                                                  p4_table->name, reg->name.originalName,
                                                  reg_action->name.originalName,
                                                  p4_action->name.originalName,
                                                  p4_table->name.originalName };
            // Create duplicate register action
            self.duplicateNodeDeclaration(reg_action, gress, names_to_change);
            // Create duplicate P4 Action
            self.duplicateNodeDeclaration(p4_action, gress, names_to_change);
            // Create duplicate P4 Table
            self.duplicateNodeDeclaration(p4_table, gress, names_to_change);
        }
    }

    return gress;
}

// Adds PingPong mechanism/if statement
IR::Node *PingPongGeneration::GeneratePingPongMechanism::postorder(IR::MethodCallStatement* mcs) {
    // Check gress
    auto gress = findContext<IR::BFN::TnaControl>();
    if (!gress)
        return mcs;
    auto gress_index = gress->thread;
    // We dont care about egress
    if (gress_index == EGRESS)
        return mcs;

    // Check if this has apply call of a table
    auto mi = P4::MethodInstance::resolve(mcs, self.refMap, self.typeMap);
    if (!mi)
        return mcs;
    auto am = mi->to<P4::ApplyMethod>();
    if (!am || !am->isTableApply())
        return mcs;
    auto p4_table = mi->object->to<IR::P4Table>();
    if (!p4_table)
        return mcs;
    // Get the approriate register
    if (!self.p4TableToRegister[gress_index].count(p4_table))
        return mcs;
    auto reg = self.p4TableToRegister[gress_index][p4_table];
    // Check if this is valid ping-pong candidate
    if (!reg || !self.registerToValid.count(reg) || !self.registerToValid[reg])
        return mcs;
    // Get the duplicate of this table
    if (!self.p4TableToDuplicateTable.count(p4_table))
        return mcs;
    auto duplicate_table = self.p4TableToDuplicateTable[p4_table];
    if (!duplicate_table)
        return mcs;
    // Get the action for this table
    if (!self.registerToP4Action[gress_index].count(reg))
        return mcs;
    auto p4_action = self.registerToP4Action[gress_index][reg];
    if (!p4_action)
        return mcs;

    // Update the mcs
    auto new_mcs = mcs->apply(
                        ApplyMCSChanger(self, p4_table->name, duplicate_table, p4_action->name))
                   ->to<IR::MethodCallStatement>();

    // Check existence of ghost metadata
    if (!self.ghost_meta_struct)
        return mcs;
    if (self.ghost_meta_name[INGRESS] == "" || self.ghost_meta_name[GHOST] == "")
        return mcs;
    // Left expression (ghost_metadata.ping_pong)
    auto left = new IR::Member(IR::Type::Bits::get(1),
                               new IR::PathExpression(self.ghost_meta_struct,
                                                      new IR::Path(
                                                        IR::ID(self.ghost_meta_name[gress_index]),
                                                      false)),
                               IR::ID(PING_PONG_FIELD_NAME));
    // Right expression - 0 or 1 based on if this is ingress or ghost
    auto right = new IR::Constant(IR::Type::Bits::get(1), (gress_index == INGRESS) ? 0 : 1);
    // Return new if statement
    return new IR::IfStatement(new IR::Equ(IR::Type_Boolean::get(), left, right), mcs, new_mcs);
}

}   // namespace BFN
