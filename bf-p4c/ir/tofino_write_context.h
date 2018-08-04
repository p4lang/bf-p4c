#ifndef EXTENSIONS_BF_P4C_IR_TOFINO_WRITE_CONTEXT_H_
#define EXTENSIONS_BF_P4C_IR_TOFINO_WRITE_CONTEXT_H_

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
    bool isRead(bool root_value = false);

    bool isIxbarRead(bool root_value = false);

    /** Find pattern that matches to a reduction Or
     *    - Field or'n with SaluAction.out_dst is a reduction or
     */
    bool isReductionOr(bool root_value = false);
};

#endif /* EXTENSIONS_BF_P4C_IR_TOFINO_WRITE_CONTEXT_H_ */
