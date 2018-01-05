#ifndef EXTENSIONS_BF_P4C_ARCH_RESUBMIT_H_
#define EXTENSIONS_BF_P4C_ARCH_RESUBMIT_H_

#include "program_structure.h"
#include "ir/ir.h"

namespace BFN {

namespace PSA {

struct FindResubmitData : public Inspector {
    explicit FindResubmitData(ProgramStructure *structure) : structure(structure) {
        setName("FindResubmitData");
    }
    bool preorder(const IR::P4Parser *parser) override;

 private:
    ProgramStructure *structure;
};

struct RewriteResubmitIfPresent : public Transform {
    explicit RewriteResubmitIfPresent(ProgramStructure *structure)
            : structure(structure) {
        setName("RewriteResubmitIfPresent");
    }
    const IR::Type_StructLike *preorder(IR::Type_StructLike *type) override;
    const IR::BFN::TranslatedP4Parser *preorder(IR::BFN::TranslatedP4Parser *parser) override;
    const IR::ParserState *preorder(IR::ParserState *state) override;
    const IR::Member *preorder(IR::Member *node) override;

 private:
    ProgramStructure *structure;
};

}  // namespace PSA

}  // namespace BFN

#endif  // EXTENSIONS_BF_P4C_ARCH_RESUBMIT_H_
