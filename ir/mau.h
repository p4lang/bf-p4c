#ifndef _TOFINO_IR_MAU_H_
#define _TOFINO_IR_MAU_H_

#include "lib/ltbitmatrix.h"

struct TableResourceAlloc;

namespace IR {

class MAU_TableSeq;

#include "bkmau.h"

namespace MAU {
using Table = MAU_Table;
using TableSeq = MAU_TableSeq;
using TernaryIndirect = MAU_TernaryIndirect;
using ActionData = MAU_ActionData;
using Instruction = MAU_Instruction;
}  // end namespace MAU

}  // end namespace IR

#endif /* _TOFINO_IR_MAU_H_ */
