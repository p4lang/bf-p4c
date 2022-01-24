#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_ALLOCATE_CLOT_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_ALLOCATE_CLOT_H_

#include "clot_info.h"

class AllocateClot : public PassManager {
    ClotInfo clotInfo;

 public:
    explicit AllocateClot(ClotInfo &clotInfo, const PhvInfo &phv, PhvUse &uses, bool log = true);
};

/**
 * Adjusts allocated CLOTs to avoid PHV containers that straddle the CLOT boundary. See
 * \ref clot_alloc_adjust "CLOT allocation adjustment" (README.md).
 */
class ClotAdjuster : public Visitor {
    ClotInfo& clotInfo;
    const PhvInfo& phv;
    Logging::FileLog* log = nullptr;

 public:
    ClotAdjuster(ClotInfo& clotInfo, const PhvInfo& phv) : clotInfo(clotInfo), phv(phv) { }

    Visitor::profile_t init_apply(const IR::Node* root) override;
    const IR::Node *apply_visitor(const IR::Node* root, const char*) override;
    void end_apply(const IR::Node* root) override;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_ALLOCATE_CLOT_H_ */
