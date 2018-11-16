#ifndef EXTENSIONS_BF_P4C_FROMV1_0_FIELD_LIST_H_
#define EXTENSIONS_BF_P4C_FROMV1_0_FIELD_LIST_H_

#include "ir/ir.h"
#include "frontends/p4/fromv1.0/converters.h"
#include "bf-p4c/common/path_linearizer.h"

namespace P4V1 {

class FieldListConverter {
    FieldListConverter();
    static FieldListConverter singleton;
 public:
    static const IR::Node *convertFieldList(const IR::Node *);
};

}  // namespace P4V1

#endif /* EXTENSIONS_BF_P4C_FROMV1_0_FIELD_LIST_H_ */
