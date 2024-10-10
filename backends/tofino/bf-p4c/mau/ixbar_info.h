#ifndef EXTENSIONS_BF_P4C_MAU_IXBAR_INFO_H_
#define EXTENSIONS_BF_P4C_MAU_IXBAR_INFO_H_

#include <array>
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "lib/safe_vector.h"

namespace BFN {

using namespace P4;

/**
 * Log IXBar allocation
 */
class CollectIXBarInfo : public MauInspector {
    const PhvInfo &phv;
    std::map<int, safe_vector<IXBar::Use::Byte>> _stage;
    std::map<IXBar::Use::Byte, const IR::MAU::Table*> _byteToTables;

    profile_t init_apply(const IR::Node *) override;

    void end_apply(const IR::Node *) override;

    void postorder(const IR::MAU::Table *) override;

    void sort_ixbar_byte();
    std::string print_ixbar_byte() const;

 public:
    explicit CollectIXBarInfo(const PhvInfo &phv) : phv(phv) {}
};

}  // namespace BFN

#endif  /* EXTENSIONS_BF_P4C_MAU_IXBAR_INFO_H_ */
