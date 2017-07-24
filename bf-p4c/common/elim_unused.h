#ifndef TOFINO_COMMON_ELIM_UNUSED_H_
#define TOFINO_COMMON_ELIM_UNUSED_H_

#include "field_defuse.h"

class ElimUnused : public PassManager {
    const PhvInfo       &phv;
    const FieldDefUse   &defuse;

    class ParserMetadata;
    class Headers;
 public:
    ElimUnused(const PhvInfo &phv, const FieldDefUse &defuse);
};

#endif /* TOFINO_COMMON_ELIM_UNUSED_H_ */
