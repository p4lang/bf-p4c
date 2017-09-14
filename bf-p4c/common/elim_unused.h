#ifndef BF_P4C_COMMON_ELIM_UNUSED_H_
#define BF_P4C_COMMON_ELIM_UNUSED_H_

#include "field_defuse.h"

class ElimUnused : public PassManager {
    const PhvInfo       &phv;
    const FieldDefUse   &defuse;

    class ParserMetadata;
    class Headers;
 public:
    ElimUnused(const PhvInfo &phv, const FieldDefUse &defuse);
};

#endif /* BF_P4C_COMMON_ELIM_UNUSED_H_ */
