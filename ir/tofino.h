#ifndef _TOFINO_IR_TOFINO_H_
#define _TOFINO_IR_TOFINO_H_
#include <ostream>
enum gress_t { INGRESS, EGRESS };

inline std::ostream &operator<<(std::ostream &out, gress_t gress) {
    return out << (gress ? "egress" : "ingress"); }

#include "parde.h"
#include "mau.h"
#include "thread_visitor.h"

namespace IR {

#include "bktofino.h"

namespace Tofino {
using Pipe = Tofino_Pipe;
}  // end namespace Tofino
}  // end namespace IR

#endif /* _TOFINO_IR_TOFINO_H_ */
