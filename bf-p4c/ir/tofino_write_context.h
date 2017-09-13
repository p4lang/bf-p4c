#ifndef EXTENSIONS_TOFINO_IR_TOFINO_WRITE_CONTEXT_H_
#define EXTENSIONS_TOFINO_IR_TOFINO_WRITE_CONTEXT_H_

#include "ir/ir.h"

class TofinoWriteContext : public P4WriteContext {
 public:
    /** Extend P4WriteContext::isWrite() with knowledge that the following are
     *  writes:
     *    - SaluAction.outtput_dst is a write
     *    - The first argument to an Instruction is a write
     *    - Extern args marked Out or InOut are writes
     */
    bool isWrite(bool root_value = false);

    /** Extend P4WriteContext::isRead() with knowledge that the following are
     *  reads:
     *    - ParserMatch statements
     *    - ParserState selects
     *    - Deparser emits
     *    - Any arguments to a Primitive after the first (which is written)
     *    - Extern args marked In or InOut
     */
    bool isRead(bool root_value = false);};

#endif /* EXTENSIONS_TOFINO_IR_TOFINO_WRITE_CONTEXT_H_ */
