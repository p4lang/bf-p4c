#ifndef _TOFINO_PARDE_MATCH_KEYS_H_
#define _TOFINO_PARDE_MATCH_KEYS_H_

#include "parde_visitor.h"
#include "tofino/phv/phv_fields.h"

class LoadMatchKeys : public PardeModifier {
    const PhvInfo     &phv;
    bool preorder(IR::Tofino::ParserState *st) override;
 public:
    explicit LoadMatchKeys(const PhvInfo &phv) : phv(phv) {}
};

#endif /* _TOFINO_PARDE_MATCH_KEYS_H_ */
