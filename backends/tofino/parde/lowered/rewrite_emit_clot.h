#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_REWRITE_EMIT_CLOT_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_REWRITE_EMIT_CLOT_H_

#include "backends/tofino/parde/clot/clot_info.h"
#include "backends/tofino/parde/parde_visitor.h"

namespace Parde::Lowered {

/**
 * \ingroup LowerDeparserIR
 *
 * \brief Replace Emits covered in a CLOT with EmitClot
 *
 * This pass visits the deparsers, and for each deparser, it walks through the emits and identifies
 * checksums/fields that are covered as part of a CLOT. Elements that are covered by a CLOT are
 * removed from the emit list and are replace by EmitClot objects.
 */
struct RewriteEmitClot : public DeparserModifier {
    RewriteEmitClot(const PhvInfo& phv, ClotInfo& clotInfo) : phv(phv), clotInfo(clotInfo) {}

 private:
    bool preorder(IR::BFN::Deparser* deparser) override;

    const PhvInfo& phv;
    ClotInfo& clotInfo;
};

}  // namespace Parde::Lowered

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_REWRITE_EMIT_CLOT_H_ */
