#ifndef EXTENSIONS_BF_P4C_COMMON_METADATA_INIT_H_
#define EXTENSIONS_BF_P4C_COMMON_METADATA_INIT_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/mau/table_dependency_graph.h"

struct MetadataInitialization : public PassManager {
    explicit MetadataInitialization(bool always_init_metadata, const PhvInfo& phv,
                                    FieldDefUse& defuse, const DependencyGraph& dg);
};

#endif /* EXTENSIONS_BF_P4C_COMMON_METADATA_INIT_H_ */
