#ifndef _TOFINO_IR_TOFINO_H_
#define _TOFINO_IR_TOFINO_H_
#include <ostream>

#include "ir/ir.h"

namespace IR {

namespace Tofino {
using Pipe = Tofino_Pipe;

using ParserMatch = Tofino_ParserMatch;
using ParserState = Tofino_ParserState;
using Parser = Tofino_Parser;
using Deparser = Tofino_Deparser;

}  // end namespace Tofino

namespace MAU {
using Table = MAU_Table;
using TableSeq = MAU_TableSeq;
using TernaryIndirect = MAU_TernaryIndirect;
using ActionData = MAU_ActionData;
using Instruction = MAU_Instruction;
}  // end namespace MAU

}  // end namespace IR

#endif /* _TOFINO_IR_TOFINO_H_ */
