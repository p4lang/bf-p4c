#ifndef BF_P4C_ARCH_CHECK_EXTERN_INVOCATION_H_
#define BF_P4C_ARCH_CHECK_EXTERN_INVOCATION_H_

#include "lib/bitvec.h"
#include "bf-p4c/arch/arch.h"

namespace BFN {

class CheckExternInvocationCommon : public Inspector {
 public:
    CheckExternInvocationCommon(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        refMap(refMap), typeMap(typeMap) {}

    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    std::map<cstring /* extType */, bitvec> pipe_constraints;

    void set_pipe_constraints(cstring extType, bitvec vec) {
        if (!pipe_constraints.count(extType)) {
            pipe_constraints.emplace(extType, vec);
        } else {
            auto &cons = pipe_constraints.at(extType);
            cons |= vec; }
    }

    bool check_pipe_constraints(cstring extType, bitvec bv,
            const IR::MethodCallExpression *expr, cstring extName, cstring pipe) {
        BUG_CHECK(pipe_constraints.count(extType) != 0,
                "pipe constraints not defined for %1%", extType);
        auto constraint = pipe_constraints.at(extType) & bv;
        if (!bv.empty() && constraint.empty()) {
            ::error("%s %s %s cannot be used in the %s pipeline", expr->srcInfo,
                    extType, extName, pipe); }
        return false;
    }

    static int genIndex(gress_t gress, ArchBlock_t block) {
        return gress * ArchBlock_t::BLOCK_TYPE + block;
    }

    bool preorder(const IR::MethodCallExpression *expr) override;
    void init_common_pipe_constraints();

    virtual void init_pipe_constraints() = 0;
};


class CheckTNAExternInvocation : public CheckExternInvocationCommon {
 public:
    CheckTNAExternInvocation(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
        CheckExternInvocationCommon(refMap, typeMap) {
        init_pipe_constraints();
    }

 private:
    void init_pipe_constraints() override;
};

class CheckT2NAExternInvocation : public CheckExternInvocationCommon {
 public:
    CheckT2NAExternInvocation(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
            CheckExternInvocationCommon(refMap, typeMap) {
        init_pipe_constraints();
    }

 private:
    void init_pipe_constraints() override;
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_CHECK_EXTERN_INVOCATION_H_ */
