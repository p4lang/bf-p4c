#include "bf-p4c/phv/v2/tx_score.h"
#include <sstream>
#include "lib/exceptions.h"

namespace PHV {
namespace v2 {

TxScore* MinPackTxScoreMaker::make(const Transaction& tx) const {
    int n_packed = 0;
    using ContainerAllocStatus = PHV::Allocation::ContainerAllocStatus;
    const auto* parent = tx.getParent();
    for (const auto& kv : tx.getTransactionStatus()) {
        const auto& container = kv.first;
        auto parent_status = parent->alloc_status(container);
        if (parent_status != ContainerAllocStatus::EMPTY && !kv.second.slices.empty()) {
            n_packed++;
        }
    }
    return new MinPackTxScore(n_packed);
}

bool MinPackTxScore::better_than(const TxScore* other_score) const {
    if (other_score == nullptr) return true;
    const MinPackTxScore* other = dynamic_cast<const MinPackTxScore*>(other_score);
    BUG_CHECK(other, "comparing MinPackTxScore with score of different type: %1%",
              other_score->str());
    return n_packed < other->n_packed;
}

std::string MinPackTxScore::str() const {
    std::stringstream ss;
    ss << "minpack{ n_packed:" << n_packed << " }";
    return ss.str();
}

}  // namespace v2
}  // namespace PHV
