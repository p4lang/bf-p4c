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
void addMirroredFieldParser(IR::BFN::Pipe* pipe,
                            const IR::P4Control* ingressDeparser,
                            const IR::P4Control* egressDeparser,
                            P4::ReferenceMap* refMap,
                            P4::TypeMap* typeMap);

class AddMirrorFieldParser : public PassManager {
 public:
    AddMirrorFieldParser(IR::BFN::Pipe* pipe, P4::ReferenceMap *refMap, P4::TypeMap *typeMap);
};

}  // namespace BFN

#endif /* BF_P4C_PARDE_MIRROR_H_ */
