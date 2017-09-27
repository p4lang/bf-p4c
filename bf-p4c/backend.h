#ifndef BF_P4C_BACKEND_H_
#define BF_P4C_BACKEND_H_

#include "ir/ir.h"
#include "bf-p4c-options.h"

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"

namespace BFN {

class Backend : public PassManager {
    PhvInfo phv;
    PhvUse uses;
    DependencyGraph deps;
    FieldDefUse defuse;

 public:
    explicit Backend(const BFN_Options& options);
};

}  // namespace BFN

#endif /* BF_P4C_BACKEND_H_ */
