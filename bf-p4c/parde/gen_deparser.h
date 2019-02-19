#ifndef BF_P4C_PARDE_GEN_DEPARSER_H_
#define BF_P4C_PARDE_GEN_DEPARSER_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/parde/parde_visitor.h"

namespace IR {

namespace BFN {
class Pipe;
}  // namespace BFN

class P4Control;

}  // namespace IR

namespace BFN {

class ExtractDeparser : public DeparserInspector {
 public:
    explicit ExtractDeparser(IR::BFN::Pipe *rv) : rv(rv) { setName("ExtractDeparser"); }
    void postorder(const IR::BFN::TnaDeparser* parser);

    IR::BFN::Pipe *rv;
};

}  // namespace BFN

#endif /* BF_P4C_PARDE_GEN_DEPARSER_H_ */
