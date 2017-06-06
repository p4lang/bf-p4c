#ifndef _TOFINO_PARDE_SPLIT_HEADER_H_
#define _TOFINO_PARDE_SPLIT_HEADER_H_

#include "parde_visitor.h"

class SplitExtractEmit : public PardeTransform {
    IR::Node *preorder(IR::Primitive *p) override;
};

#endif /* _TOFINO_PARDE_SPLIT_HEADER_H_ */
