#ifndef EXTENSIONS_BF_P4C_PARDE_COALESCE_LEARNING_H_
#define EXTENSIONS_BF_P4C_PARDE_COALESCE_LEARNING_H_

#include "ir/ir.h"
#include "parde_visitor.h"

/* Digests cannot extract from the same 16 or 32 bit PHV consecutively, but for learning
 * digests, since we control the layout completely, we can set it up to just extract the
 * container once, and use the data from that container more than once.
 *
 * This pass detects consectuive extracts of the same container and replaces them with 
 * a single extract, rewriting the control-plane info to match.  In theory we could combine
 * any extracts from the same container (not just adjacent ones) to reduce the number of
 * digest bytes needed
 */
class CoalesceLearning : public DeparserModifier {
    bool preorder(IR::BFN::LearningTableEntry *) override;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_COALESCE_LEARNING_H_ */


