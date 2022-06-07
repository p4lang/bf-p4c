#ifndef BFN_P4C_NORMALIZEHASHLIST_H
#define BFN_P4C_NORMALIZEHASHLIST_H

#include "ir/ir.h"

namespace P4 {

class TypeChecking;
class TypeMap;
class ReferenceMap;

} /* -- namespace P4 */

/**
 * @brief Normalize field lists in hashing expression (Hash.get primitive)
 *
 * This visitor replaces complex expressions in hashing field lists by
 * temporary variables. The variable is placed in the scope of current
 * control and its initialization is moved just before the statement
 * in the apply block, which invokes the action the hash calculation
 * belongs to (both direct invocation and table application are supported).
 *
 * The temporary variable is needed as the hashing engine takes inputs
 * from the PHV crossbar. There are some exceptions:
 *   - compile-time constants are computed into the hashing seeds
 *   - concatenation operator is ignored as it's equivalent
 *     to listing its operands in the hash field list and it's
 *     processed later in the same way.
 *
 * This pass expects that the local copy propagation has been finished
 * (the P4::LocalCopyPropagation pass) and that all local variables are
 * moved into the control scope (the P4::MoveDeclarations pass).
 * Otherwise, the initialization code placed into the apply block could
 * contain some local variables out of the scope.
 *
 * Example:
 *
 * @code{.p4}
 * control Ingress(...) {
 *   Hash<...>(...) hasher;
 *
 *   action awesomeHashing() {
 *     ... = hasher.get({hdr.field1 & hdr.field2});
 *   }
 *
 *   apply {
 *     ...
 *     awesomeHashing();
 *   }
 * }
 * @endcode
 *
 * is transformed to:
 *
 * @code{.p4}
 * control Ingress(...) {
 *   bits<...> $hash_field_argument0;
 *   Hash<...>(...) hasher;
 *
 *   action awesomeHashing() {
 *     ... = hasher.get({$hash_field_argument0});
 *   }
 *
 *   apply {
 *     ...
 *     $hash_field_argument = hdr.field1 & hdr.field2;
 *     awesomeHashing();
 *   }
 * }
 * @endcode
 */
class NormalizeHashList : public PassManager {
 public:
    explicit NormalizeHashList(
        ::P4::ReferenceMap* ref_map_,
        ::P4::TypeMap* type_map_,
        ::P4::TypeChecking* type_checking_);

    /* -- avoid copying */
    NormalizeHashList& operator=(NormalizeHashList&&) = delete;

    /**
     * @brief Check whether a method call is the hasher call
     */
    static bool isHasher(const IR::MethodCallExpression* mc);
};

#endif  // BFN_P4C_NORMALIZEHASHLIST_H
