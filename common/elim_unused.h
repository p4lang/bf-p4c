#ifndef TOFINO_COMMON_ELIM_UNUSED_H_
#define TOFINO_COMMON_ELIM_UNUSED_H_

#include "field_defuse.h"

class ElimUnused : public PassManager {
    const PhvInfo       &phv;
    const FieldDefUse   &defuse;
    std::set<cstring>   hdr_use;

    class ParserMetadata;
    class FindHeaderUse;
    class Headers;
 public:
    ElimUnused(const PhvInfo &phv, const FieldDefUse &defuse);
};

#endif /* TOFINO_COMMON_ELIM_UNUSED_H_ */
