#ifndef BF_P4C_MIDEND_CHECK_HEADER_ALIGNMENT_H_
#define BF_P4C_MIDEND_CHECK_HEADER_ALIGNMENT_H_

#include "ir/ir.h"

namespace P4 {
class TypeMap;
}  // namespace P4

namespace BFN {

/**
 * Check for non-byte-aligned header types and report an error if any are found.
 *
 * On Tofino, we can only parse and deparse byte-aligned headers, so
 * non-byte-aligned headers aren't useful.
 *
 * XXX(seth): We could theoretically allow non-byte-aligned headers if they're
 * only used in the MAU, but for now I've avoided that since it seems less
 * confusing for the P4 programmer to have a simple and clear rule.
 */
class CheckHeaderAlignment final : public Inspector {
    P4::TypeMap* typeMap;

 private:
    bool preorder(const IR::Type_Header* header) override;

 public:
    explicit CheckHeaderAlignment(P4::TypeMap* typeMap) : typeMap(typeMap) {}
};

}  // namespace BFN

#endif  /* BF_P4C_MIDEND_CHECK_HEADER_ALIGNMENT_H_ */
