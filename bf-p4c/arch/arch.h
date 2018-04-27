#ifndef BF_P4C_ARCH_ARCH_H_
#define BF_P4C_ARCH_ARCH_H_

#include <boost/algorithm/string.hpp>
#include <boost/optional.hpp>
#include <set>
#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/path.h"
#include "frontends/common/options.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/sideEffects.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/device.h"
#include "bf-p4c/arch/program_structure.h"

namespace BFN {

/// Find and remove extern method calls that the P4 programmer has requested by
/// excluded from translation using the `@dont_translate_extern_method` pragma.
/// Currently this pragma is only supported on actions; it takes as an argument
/// a list of strings that identify extern method calls to remove from the action
/// body.
struct RemoveExternMethodCallsExcludedByAnnotation : public Transform {
    const IR::MethodCallStatement*
    preorder(IR::MethodCallStatement* call) override {
        auto* action = findContext<IR::P4Action>();
        if (!action) return call;

        auto* callExpr = call->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(callExpr, "Malformed method call IR: %1%", call);

        auto* dontTranslate = action->getAnnotation("dont_translate_extern_method");
        if (!dontTranslate) return call;
        for (auto* excluded : dontTranslate->expr) {
            auto* excludedMethod = excluded->to<IR::StringLiteral>();
            if (!excludedMethod) {
                ::error("Non-string argument to @dont_translate_extern_method: "
                        "%1%", excluded);
                return call;
            }

            if (excludedMethod->value == callExpr->toString()) {
                ::warning("Excluding method call from translation due to "
                          "@dont_translate_extern_method: %1%", call);
                return nullptr;
            }
        }

        return call;
    }
};

class GenerateTofinoProgram : public Transform {
    ProgramStructure* structure;
 public:
    explicit GenerateTofinoProgram(ProgramStructure* structure)
            : structure(structure) { CHECK_NULL(structure); setName("GenerateTofinoProgram"); }
    //
    const IR::Node* preorder(IR::P4Program* program) override {
        auto *rv = structure->create(program);
        return rv;
    }
};

class TranslationFirst : public PassManager {
 public:
    TranslationFirst() { setName("TranslationFirst"); }
};

class TranslationLast : public PassManager {
 public:
    TranslationLast() { setName("TranslationLast"); }
};

class ArchTranslation : public PassManager {
 public:
    ArchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options);
};

enum ArchBlockType {
    PARSER,
    MAU,
    DEPARSER,
};

struct BlockInfo {
    int index;
    gress_t gress;
    ArchBlockType type;
    BlockInfo(int index, gress_t gress, ArchBlockType type)
        : index(index), gress(gress), type(type) {}

    bool operator==(const BlockInfo& rhs) const {
        return rhs.index == this->index && rhs.gress == this->gress &&
               rhs.type == this->type;
    }
};

using ArchBlockMapping = std::map<BlockInfo*, const IR::CompileTimeValue*>;
using BlockInfoMapping = std::map<const IR::Node*, BlockInfo*>;

class ParseTofinoArch : public Inspector {
 public:
    ParseTofinoArch() {}

    bool preorder(const IR::PackageBlock* block) override {
        BlockInfo* binfo = nullptr;
        auto pipe_index = 0;
        auto ingress_parser = block->getParameterValue("ingress_parser");
        binfo = new BlockInfo(pipe_index, INGRESS, PARSER);
        toArchBlock.emplace(binfo, ingress_parser);
        toBlockInfo.emplace(ingress_parser->to<IR::ParserBlock>()->container, binfo);

        auto ingress = block->getParameterValue("ingress");
        binfo = new BlockInfo(pipe_index, INGRESS, MAU);
        toArchBlock.emplace(binfo, ingress);
        toBlockInfo.emplace(ingress->to<IR::ControlBlock>()->container, binfo);

        auto ingress_deparser = block->getParameterValue("ingress_deparser");
        binfo = new BlockInfo(pipe_index, INGRESS, DEPARSER);
        toArchBlock.emplace(binfo, ingress_deparser);
        toBlockInfo.emplace(ingress_deparser->to<IR::ControlBlock>()->container, binfo);

        auto egress_parser = block->getParameterValue("egress_parser");
        binfo = new BlockInfo(pipe_index, EGRESS, PARSER);
        toArchBlock.emplace(binfo, egress_parser);
        toBlockInfo.emplace(egress_parser->to<IR::ParserBlock>()->container, binfo);

        auto egress = block->getParameterValue("egress");
        binfo = new BlockInfo(pipe_index, EGRESS, MAU);
        toArchBlock.emplace(new BlockInfo(pipe_index, EGRESS, MAU), egress);
        toBlockInfo.emplace(egress->to<IR::ControlBlock>()->container, binfo);

        auto egress_deparser = block->getParameterValue("egress_deparser");
        binfo = new BlockInfo(pipe_index, EGRESS, DEPARSER);
        toArchBlock.emplace(new BlockInfo(pipe_index, EGRESS, DEPARSER), egress_deparser);
        toBlockInfo.emplace(egress_deparser->to<IR::ControlBlock>()->container, binfo);
        return false;
    }

    ArchBlockMapping toArchBlock;
    BlockInfoMapping toBlockInfo;
};

class ParseTofino32QArch : public Inspector {
 public:
    ParseTofino32QArch() {}

    bool preorder(const IR::PackageBlock* block) override {
        if (auto param = block->getParameterValue("pipe0")) {
            if (!param->is<IR::PackageBlock>()) {
                ::error("Unexpected argument type %1%", param);
                return false;
            }
            BlockInfo* binfo = nullptr;
            auto p0 = param->to<IR::PackageBlock>();
            auto pipe_index = 0;

            auto ingress_parser = p0->getParameterValue("ingress_parser");
            binfo = new BlockInfo(pipe_index, INGRESS, PARSER);
            toArchBlock.emplace(binfo, ingress_parser);
            toBlockInfo.emplace(ingress_parser->to<IR::ParserBlock>()->container, binfo);

            auto ingress = p0->getParameterValue("ingress");
            binfo = new BlockInfo(pipe_index, INGRESS, MAU);
            toArchBlock.emplace(binfo, ingress);
            toBlockInfo.emplace(ingress->to<IR::ControlBlock>()->container, binfo);

            auto ingress_deparser = p0->getParameterValue("ingress_deparser");
            binfo = new BlockInfo(pipe_index, INGRESS, DEPARSER);
            toArchBlock.emplace(binfo, ingress_deparser);
            toBlockInfo.emplace(ingress_deparser->to<IR::ControlBlock>()->container, binfo);

            auto egress_parser = p0->getParameterValue("egress_parser");
            binfo = new BlockInfo(pipe_index, EGRESS, PARSER);
            toArchBlock.emplace(binfo, egress_parser);
            toBlockInfo.emplace(egress_parser->to<IR::ParserBlock>()->container, binfo);

            auto egress = p0->getParameterValue("egress");
            binfo = new BlockInfo(pipe_index, EGRESS, MAU);
            toArchBlock.emplace(new BlockInfo(pipe_index, EGRESS, MAU), egress);
            toBlockInfo.emplace(egress->to<IR::ControlBlock>()->container, binfo);

            auto egress_deparser = p0->getParameterValue("egress_deparser");
            binfo = new BlockInfo(pipe_index, EGRESS, DEPARSER);
            toArchBlock.emplace(new BlockInfo(pipe_index, EGRESS, DEPARSER), egress_deparser);
            toBlockInfo.emplace(egress_deparser->to<IR::ControlBlock>()->container, binfo);
        }
        if (auto param = block->getParameterValue("pipe1")) {
            if (!param->is<IR::PackageBlock>()) {
                ::error("Unexpected argument type %1%", param);
                return false;
            }
            BlockInfo* binfo = nullptr;
            auto p1 = param->to<IR::PackageBlock>();
            auto pipe_index = 1;

            auto ingress_parser = p1->getParameterValue("ingress_parser");
            binfo = new BlockInfo(pipe_index, INGRESS, PARSER);
            toArchBlock.emplace(binfo, ingress_parser);
            toBlockInfo.emplace(ingress_parser->to<IR::ParserBlock>()->container, binfo);

            auto ingress = p1->getParameterValue("ingress");
            binfo = new BlockInfo(pipe_index, INGRESS, MAU);
            toArchBlock.emplace(binfo, ingress);
            toBlockInfo.emplace(ingress->to<IR::ControlBlock>()->container, binfo);

            auto ingress_deparser = p1->getParameterValue("ingress_deparser");
            binfo = new BlockInfo(pipe_index, INGRESS, DEPARSER);
            toArchBlock.emplace(binfo, ingress_deparser);
            toBlockInfo.emplace(ingress_deparser->to<IR::ControlBlock>()->container, binfo);

            auto egress_parser = p1->getParameterValue("egress_parser");
            binfo = new BlockInfo(pipe_index, EGRESS, PARSER);
            toArchBlock.emplace(binfo, egress_parser);
            toBlockInfo.emplace(egress_parser->to<IR::ParserBlock>()->container, binfo);

            auto egress = p1->getParameterValue("egress");
            binfo = new BlockInfo(pipe_index, EGRESS, MAU);
            toArchBlock.emplace(new BlockInfo(pipe_index, EGRESS, MAU), egress);
            toBlockInfo.emplace(egress->to<IR::ControlBlock>()->container, binfo);

            auto egress_deparser = p1->getParameterValue("egress_deparser");
            binfo = new BlockInfo(pipe_index, EGRESS, DEPARSER);
            toArchBlock.emplace(new BlockInfo(pipe_index, EGRESS, DEPARSER), egress_deparser);
            toBlockInfo.emplace(egress_deparser->to<IR::ControlBlock>()->container, binfo);
        }
        return false;
    }

    ArchBlockMapping toArchBlock;
    BlockInfoMapping toBlockInfo;
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_ARCH_H_ */

