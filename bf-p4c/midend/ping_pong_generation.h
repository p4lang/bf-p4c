#ifndef EXTENSIONS_BF_P4C_MIDEND_PING_PONG_GENERATION_H_
#define EXTENSIONS_BF_P4C_MIDEND_PING_PONG_GENERATION_H_

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/methodInstance.h"
#include "ir/ir.h"
#include "ir/gress.h"
#include "bf-p4c/midend/type_checker.h"
#include "midend/detect_multiple_pipelines.h"

namespace BFN {

/**
 * \class PingPongGeneration
 * \ingroup midend
 * \brief PassManager that adds the ping pong mechanism for ghost thread.
 * 
 * Detects registers that are used by ingress and ghost, creates
 * a duplicate tables and registers if needed and attaches
 * a ping-pong mechanism onto them.  
 *
 * There are some helpful visitors (that find/modify something specific
 * within a given sub-tree of the IR) and functions.
 * 
 * Passes work with member variables of the main PassManager (PingPongGeneration) - these
 * variables serve as a storage for saving registers/actions/tables identified for duplication.
 */
class PingPongGeneration : public PassManager {
    // CONSTANTS ----------------------------------------------------------------------------------
    /**
     * Constant suffix added to identifiers.
     */
    static const cstring ID_PING_PONG_SUFFIX;
    /**
     * Constant name of the ghost metadata structure.
     */
    static const cstring GMD_STRUCTURE_NAME;
    /**
     * Constant name of the ping_pong field.
     */
    static const cstring PING_PONG_FIELD_NAME;

    // VARIABLES ----------------------------------------------------------------------------------
    // These variables serve as a state/storage between different passes
    /**
     * Array of ghost metadata names for different gresses
     */
    cstring ghost_meta_name[GRESS_T_COUNT] = { "", "", "" };
    /**
     * Declaration of ghost_intrinsic_metadata struct
     */
    const IR::Type_Header* ghost_meta_struct = nullptr;

    // Basic maps
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;

    // Local maps for storing information
    typedef std::unordered_map<const IR::Declaration_Instance *,
        const IR::Declaration_Instance *> RegisterToRegisterActionMap;
    typedef std::unordered_map<const IR::Declaration_Instance *,
        const IR::P4Action *> RegisterToP4ActionMap;
    typedef std::unordered_map<const IR::P4Action *,
        const IR::Declaration_Instance *> P4ActionToRegisterMap;
    typedef std::unordered_map<const IR::P4Action *,
         const IR::P4Table *> P4ActionToP4TableMap;
    typedef std::unordered_map<const IR::P4Table *,
        const IR::Declaration_Instance *> P4TableToRegisterMap;
    typedef std::unordered_map<const IR::Declaration_Instance *,
        bool> RegisterToValidMap;
    typedef std::unordered_map<const IR::P4Table *,
        const IR::P4Table *> P4TableToP4TableMap;
    // Mappings for different parts and for different Gress
    RegisterToRegisterActionMap registerToRegisterAction[GRESS_T_COUNT];
    RegisterToP4ActionMap registerToP4Action[GRESS_T_COUNT];
    P4ActionToRegisterMap p4ActionToRegister[GRESS_T_COUNT];
    P4ActionToP4TableMap p4ActionToP4Table[GRESS_T_COUNT];
    P4TableToRegisterMap p4TableToRegister[GRESS_T_COUNT];
    RegisterToValidMap registerToValid;
    P4TableToP4TableMap p4TableToDuplicateTable;

    // Detector of multiple pipelines
    DetectMultiplePipelines *detectMultiplePipelines = new DetectMultiplePipelines();

    // HELPER FUNCTIONS ---------------------------------------------------------------------------
    inline IR::Path* appendPingPongSuffix(IR::Path*, std::set<cstring>&);
    inline void duplicateNodeDeclaration(
                                const IR::Declaration*,
                                IR::BFN::TnaControl*,
                                std::set<cstring>&);

    // HELPER VISITORS ----------------------------------------------------------------------------
    // Finds a ghost_metadata.ping_pong field reference in a subtree
    class PingPongFieldFinder;
    // Base class for chaning declarations
    class DeclarationChanger;
    // This visitor changes specific references in new cloned register action
    class RegActionChanger;
    // This visitor changes specific references in new cloned P4 action
    class P4ActionChanger;
    // This visitor changes specific references in new cloned P4 table
    class P4TableChanger;
    // This visitor changes P4 table references in cloned MethodCallStatement
    class ApplyMCSChanger;

    // MAIN VISITORS ------------------------------------------------------------------------------
    /**
     * \class GetAllRegisters
     * \brief Gets all of the registers used and their actions.
     */
    class GetAllRegisters: public Inspector {
        PingPongGeneration &self;

        bool preorder(const IR::MethodCallExpression*) override;
     public:
        explicit GetAllRegisters(PingPongGeneration &self) :
             self(self) {}
    };

    /**
     * \class AddAllTables
     * \brief Finds and adds all of the corresponding tables.
     */
    class AddAllTables: public Inspector {
        PingPongGeneration &self;

        bool preorder(const IR::ActionListElement*) override;
     public:
        explicit AddAllTables(PingPongGeneration &self) :
             self(self) {}
    };

    /**
     * \class CheckPingPongTables
     * \brief Checks for tables that are already applied under ping_pong condition.
     * 
     * Also checks if ghost_metadata are even present or if there are multiple pipelines
     */
    class CheckPingPongTables: public Inspector {
        PingPongGeneration &self;
        unsigned pipes = 0;

        // Finds ghost_metadata structure presence
        bool preorder(const IR::Type_Header*) override;
        // Finds tables applied under ping_pong
        bool preorder(const IR::PathExpression*) override;
        // Gets the identifier of ghost metadata
        bool preorder(const IR::Parameter*) override;
     public:
        explicit CheckPingPongTables(PingPongGeneration &self) :
             self(self) {}
    };

    /**
     * \class GeneratePingPongMechanismDeclarations
     * \brief Duplicates all of the required tables, registers, actions.
     */
    class GeneratePingPongMechanismDeclarations: public Transform {
        PingPongGeneration &self;

        IR::Node *preorder(IR::P4Program*);
        IR::Node *preorder(IR::BFN::TnaControl*);
     public:
        explicit GeneratePingPongMechanismDeclarations(PingPongGeneration &self) :
             self(self) {}
    };

    /**
     * \class GeneratePingPongMechanism.
     * \brief Adds PingPong mechanism/if statement.
     */
    class GeneratePingPongMechanism: public Transform {
        PingPongGeneration &self;

        IR::Node *postorder(IR::MethodCallStatement*);
     public:
        explicit GeneratePingPongMechanism(PingPongGeneration &self) :
             self(self) {}
    };

 public:
    /**
     * Constructor that adds all of the passes.
     */
    PingPongGeneration(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
         refMap(refMap), typeMap(typeMap) {
        setName("Automatic ping-pong generation");
        addPasses({
            // Detect multiple pipelines (which is not supported currently)
            detectMultiplePipelines,
            // Run the ping-pong generation for single pipeline programs
            new PassIf([this]() { return !detectMultiplePipelines->hasMultiplePipelines(); }, {
                new TypeChecking(refMap, typeMap, true),
                new GetAllRegisters(*this),
                new AddAllTables(*this),
                new CheckPingPongTables(*this),
                new GeneratePingPongMechanismDeclarations(*this),
                // Update ref and type map, bacause the IR might have changed
                new TypeChecking(refMap, typeMap, true),
                new GeneratePingPongMechanism(*this)
            })
        });
    }
};

}  // namespace BFN

#endif  // EXTENSIONS_BF_P4C_MIDEND_PING_PONG_GENERATION_H_
