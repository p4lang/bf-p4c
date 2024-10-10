#ifndef _MIDEND_SIMPLIFY_REFERENCES_H_
#define _MIDEND_SIMPLIFY_REFERENCES_H_

#include <vector>
#include "ir/ir.h"
#include "ir/pass_manager.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

class ParamBinding;

/**
 * Simplify complex references to headers, header stacks, structs, and structs.
 *
 * This pass simplifies references so that the backend doesn't have to deal with
 * complicated cases. The simplifications include:
 *   - References to variables and package parameters are bound to concrete
 *     objects.
 *   - Member expressions are flattened to a single level.
 *   - Operations on structs and header stacks are split so that they only
 *     operate on a single header at a time. (This is mainly meant for the
 *     `extract()` and `emit()` methods.
 *   - Calls to the `isValid()` header method are replaced with references to
 *     the header's `$valid` POV bit field.
 */
struct SimplifyReferences : public PassManager {
    /**
     * Create a SimplifyReferences instance.
     *
     * @param bindings  Known bindings to package parameters and declarations.
     *                  References to these entities (i.e., via member or path
     *                  expressions) will be bound to concrete objects (i.e.,
     *                  HeaderRefs or HeaderStackItemRefs). Any additional
     *                  declarations encountered during the simplification
     *                  process will be added to be bindings for us by future
     *                  passes; this is an in-out parameter.
     * @param refMap    Resolved references for the P4 program.
     * @param typeMap   Resolved types for the P4 program.
     */
    SimplifyReferences(ParamBinding* bindings, P4::ReferenceMap* refMap,
                       P4::TypeMap* typeMap);
};

#endif /* _MIDEND_SIMPLIFY_REFERENCES_H_ */
