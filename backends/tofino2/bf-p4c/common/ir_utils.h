#ifndef EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_

#include "ir/ir.h"

using namespace P4;

IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field);

const IR::HeaderOrMetadata*
getMetadataType(const IR::BFN::Pipe* pipe, cstring typeName);

bool isSigned(const IR::Type *);

// probably belongs in ir/ir.h or ir/node.h...
template <class T> inline T *clone_update(const T* &ptr) {
    T *rv = ptr->clone();
    ptr = rv;
    return rv; }

uint64_t bitMask(unsigned size);
big_int bigBitMask(int size);

// FIXME -- move to open source code (ir/pass_manager.h probably)
template<class BT>
class CatchBacktrack : public Backtrack {
    std::function<void(BT *)> fn;
    bool backtrack(trigger &trig) override {
        if (auto t = dynamic_cast<BT *>(&trig)) {
            fn(t);
            return true;
        } else {
            return false;
        }
    }
    // pass does nothing
    const IR::Node *apply_visitor(const IR::Node *n, const char * = 0) override { return n; }

 public:
    explicit CatchBacktrack(std::function<void(BT *)> f) : fn(f) {}
    explicit CatchBacktrack(std::function<void()> f) : fn([f](BT *){ f(); }) {}
};

#endif /* EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_ */
