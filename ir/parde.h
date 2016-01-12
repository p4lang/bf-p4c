#ifndef _TOFINO_IR_PARDE_H_
#define _TOFINO_IR_PARDE_H_

#include "lib/match.h"

namespace IR {

class Tofino_ParserState;

#include "bkparde.h"

namespace Tofino {
using ParserMatch = Tofino_ParserMatch;
using ParserState = Tofino_ParserState;
using Parser = Tofino_Parser;
using Deparser = Tofino_Deparser;
}  // end namespace Tofino

}  // end namespace IR

#endif /* _TOFINO_IR_PARDE_H_ */
