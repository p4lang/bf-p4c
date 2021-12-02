#ifndef BF_P4C_ARCH_CHECK_EXTERN_INVOCATION_H_
#define BF_P4C_ARCH_CHECK_EXTERN_INVOCATION_H_

#include "ir/ir.h"
#include "ir/visitor.h"
#include "bf-p4c/arch/arch.h"
#include "frontends/p4/methodInstance.h"
#include "midend/checkExternInvocationCommon.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}

namespace BFN {

class CheckExternInvocationCommon : public P4::CheckExternInvocationCommon {
 protected:
    int genIndex(gress_t gress, ArchBlock_t block) {
        return gress * ArchBlock_t::BLOCK_TYPE + block;
    }
    cstring getBlockName(int bit) override {
        static const char* lookup[] = {"parser", "control (MAU)", "deparser"};
        BUG_CHECK(sizeof(lookup)/sizeof(lookup[0]) == ArchBlock_t::BLOCK_TYPE, "Bad lookup table");
        return lookup[bit % ArchBlock_t::BLOCK_TYPE];
    }
    void initCommonPipeConstraints();
    void checkExtern(const P4::ExternMethod *extMethod,
            const IR::MethodCallExpression *expr) override;
    CheckExternInvocationCommon(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        P4::CheckExternInvocationCommon(refMap, typeMap) {}
};

class CheckTNAExternInvocation : public CheckExternInvocationCommon {
    void initPipeConstraints() override;
 public:
    CheckTNAExternInvocation(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        CheckExternInvocationCommon(refMap, typeMap) { initPipeConstraints(); }
};

class CheckT2NAExternInvocation : public CheckExternInvocationCommon {
    void initPipeConstraints() override;
 public:
    CheckT2NAExternInvocation(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        CheckExternInvocationCommon(refMap, typeMap) { initPipeConstraints(); }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_CHECK_EXTERN_INVOCATION_H_ */
