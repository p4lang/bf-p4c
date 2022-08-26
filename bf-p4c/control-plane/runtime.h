#ifndef EXTENSIONS_BF_P4C_CONTROL_PLANE_RUNTIME_H_
#define EXTENSIONS_BF_P4C_CONTROL_PLANE_RUNTIME_H_

#include "ir/ir.h"

namespace IR {
class P4Program;
}  // namespace IR

class BFN_Options;

namespace BFN {

/*
 * P4C-3520 : Certain names are reserved for BF-RT and cannot be used on
 * controls. Pass checks for control names overlapping restricted ones, append
 * to the list as required.
 */
class CheckReservedNames : public Inspector {
    std::set<cstring> reservedNames = { "snapshot" };
    bool preorder(const IR::Type_ArchBlock* b) override;

 public:
    CheckReservedNames() {}
};

/**
 * \ingroup midend
 * \brief Pass that sets default table size to 512 entries.
 *
 * P4C-3177
 * If no 'size' parameter is set on the table, p4info picks a default value of 1024.
 * p4c/frontends/p4/fromv1.0/v1model.h: const unsigned defaultTableSize = 1024;
 * This pass is run again in the MidEnd to modify IR and set this value.
 * BF-RT does not modify program IR used by Midend.
 */
class SetDefaultSize : public Modifier {
    bool warn = false;
    bool preorder(IR::P4Table *table) override;

 public:
     explicit SetDefaultSize(bool warn) : warn(warn) {}
};

/// A convenience wrapper for P4::generateP4Runtime(). This must be called
/// before the translation pass and will generate the correct P4Info message
/// based on the original architecture (v1model, PSA, TNA or JNA).
void generateRuntime(const IR::P4Program* program,
                       const BFN_Options& options);

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_CONTROL_PLANE_RUNTIME_H_ */
