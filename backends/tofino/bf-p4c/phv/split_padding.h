#ifndef BF_P4C_PHV_SPLIT_PADDING_H_
#define BF_P4C_PHV_SPLIT_PADDING_H_

#include <ir/ir.h>

#include "ir/visitor.h"

class PhvInfo;

/**
 * @brief Splits padding after PHV allocation to prevent extracted padding spanning multiple
 * containers.
 *
 * Prevent padding from spanning multiple containers to help passes like UpdateParserWriteMode that
 * unifies the write modes for all fields in a container.
 */
class SplitPadding : public Transform {
 protected:
    const PhvInfo& phv;

    const IR::Node* preorder(IR::BFN::ParserState* state) override;

 public:
    explicit SplitPadding(const PhvInfo& phv) : phv(phv) { }
};

#endif  /* BF_P4C_PHV_SPLIT_PADDING_H_ */
