#ifndef _TOFINO_PARDE_ADD_PARDE_METADATA_H_
#define _TOFINO_PARDE_ADD_PARDE_METADATA_H_

#include "parde_visitor.h"

class AddMetadataShims : public PardeModifier {
    bool preorder(IR::Tofino::Parser *) override;
    bool preorder(IR::Tofino::Deparser *) override;
};

#endif /* _TOFINO_PARDE_ADD_PARDE_METADATA_H_ */
