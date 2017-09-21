#ifndef BF_P4C_COMMON_ELIM_UNUSED_H_
#define BF_P4C_COMMON_ELIM_UNUSED_H_

#include "field_defuse.h"

class ElimUnused : public PassManager {
    const PhvInfo       &phv;
    FieldDefUse         &defuse;

    class Instructions;
    class Headers;
 public:
    ElimUnused(const PhvInfo &phv, FieldDefUse &defuse);
};

#endif /* BF_P4C_COMMON_ELIM_UNUSED_H_ */
