#ifndef BF_P4C_PARDE_MIRROR_H_
#define BF_P4C_PARDE_MIRROR_H_

#include "ir/ir.h"

namespace IR {
namespace BFN {
class Pipe;
}  // namespace BFN
class P4Control;
}  // namespace IR

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

namespace BFN {

using FieldListId = std::pair<gress_t, unsigned>;
using MirroredFieldList = IR::Vector<IR::Expression>;
using MirroredFieldLists = std::map<FieldListId, const MirroredFieldList*>;
using MirroredFieldListPacking = std::map<FieldListId, const FieldPacking*>;

/**
 * Searches for invocations of the `mirror_packet.add_metadata()` extern in
 * deparser controls and generates a parser program that will extract the
 * mirrored fields.
 *
 * `mirror_packet.emit()` (which is used by `tofino.p4`) is accepted as a
 * synonym for `mirror_packet.add_metadata()`.
 *
 * @param pipe  The Tofino pipe for this P4 program. The generated parser IR
 *              will be attached to this pipe's egress parser.
 * @param ingressDeparser  The ingress deparser to check for mirror field lists.
 * @param egressDeparser  The egress deparser to check for mirror field lists.
 * @param refMap  An up-to-date reference map for this P4 program.
 * @param typeMap  An up-to-date type map for this P4 program.
 */
class ExtractMirrorFieldPackings : public PassManager {
 public:
    ExtractMirrorFieldPackings(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                               MirroredFieldListPacking* fieldPackings);

    MirroredFieldListPacking* fieldPackings;
};

/** Insert $mirror_field_list_* states in egress to parse mirrored data.
 */
class PopulateMirrorStateWithFieldPackings : public PassManager {
 public:
    PopulateMirrorStateWithFieldPackings(IR::BFN::Pipe* pipe,
                                         const MirroredFieldListPacking* fieldPackings);
};

}  // namespace BFN

#endif /* BF_P4C_PARDE_MIRROR_H_ */
