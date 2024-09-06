#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_SOLITARY_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_SOLITARY_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"

class PragmaSolitary : public Inspector {
    PhvInfo& phv_i;

    bool preorder(const IR::BFN::Pipe* pipe) override;
 public:
    explicit PragmaSolitary(PhvInfo& phv) : phv_i(phv) { }

    /// BFN::Pragma interface
    static const char *name;
    static const char *description;
    static const char *help;
};

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_SOLITARY_H_ */
