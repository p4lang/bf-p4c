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
#include "bf-p4c/arch/program_structure.h"

namespace BFN {

enum class ARCH { TNA, T2NA, PSA, V1MODEL };

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
    PARSER = 0,
    MAU,
    DEPARSER,
    BLOCK_TYPE
};

struct BlockInfo {
    int index;
    gress_t gress;
    ArchBlockType type;
    BlockInfo(int index, gress_t gress, ArchBlockType type)
        : index(index), gress(gress), type(type) {}

    bool operator<(const BlockInfo& other) const {
        return std::tie(index, gress, type)
               < std::tie(other.index, other.gress, other.type);
    }

    bool operator==(const BlockInfo& rhs) const {
        return rhs.index == this->index && rhs.gress == this->gress &&
               rhs.type == this->type;
    }

    void dbprint(std::ostream& out) {
        out << "index " << index << " ";
        out << "gress " << gress << " ";
        out << "type " << type << std::endl;
    }
};

using ProgramThreads = std::map<std::pair<int, gress_t>, const IR::BFN::P4Thread*>;
using BlockInfoMapping = std::map<const IR::Node*, BlockInfo>;

class ParseTna : public Inspector {
 public:
    explicit ParseTna(ProgramThreads *threads) : threads(threads) {
        CHECK_NULL(threads);
    }

    void parsePipeline(const IR::PackageBlock* block, unsigned index) {
        auto thread_i = new IR::BFN::P4Thread();
        auto ingress_parser = block->getParameterValue("ingress_parser");
        BlockInfo ip(index, INGRESS, PARSER);
        thread_i->parser = ingress_parser->to<IR::ParserBlock>()->container;
        toBlockInfo.emplace(ingress_parser->to<IR::ParserBlock>()->container, ip);

        auto ingress = block->getParameterValue("ingress");
        BlockInfo ig(index, INGRESS, MAU);
        thread_i->mau = ingress->to<IR::ControlBlock>()->container;
        toBlockInfo.emplace(ingress->to<IR::ControlBlock>()->container, ig);

        auto ingress_deparser = block->getParameterValue("ingress_deparser");
        BlockInfo id(index, INGRESS, DEPARSER);
        thread_i->deparser = ingress_deparser->to<IR::ControlBlock>()->container;
        toBlockInfo.emplace(ingress_deparser->to<IR::ControlBlock>()->container, id);

        threads->emplace(std::make_pair(index, INGRESS), thread_i);

        auto thread_e = new IR::BFN::P4Thread();
        auto egress_parser = block->getParameterValue("egress_parser");
        BlockInfo ep(index, EGRESS, PARSER);
        thread_e->parser = egress_parser->to<IR::ParserBlock>()->container;
        toBlockInfo.emplace(egress_parser->to<IR::ParserBlock>()->container, ep);

        auto egress = block->getParameterValue("egress");
        thread_e->mau = egress->to<IR::ControlBlock>()->container;
        BlockInfo eg(index, EGRESS, MAU);
        toBlockInfo.emplace(egress->to<IR::ControlBlock>()->container, eg);

        auto egress_deparser = block->getParameterValue("egress_deparser");
        thread_e->deparser = egress_deparser->to<IR::ControlBlock>()->container;
        BlockInfo ed(index, EGRESS, DEPARSER);
        toBlockInfo.emplace(egress_deparser->to<IR::ControlBlock>()->container, ed);

        threads->emplace(std::make_pair(index, EGRESS), thread_e);

        if (auto ghost = block->findParameterValue("ghost")) {
            auto ghost_cb = ghost->to<IR::ControlBlock>()->container;
            auto thread_g = new IR::BFN::P4Thread();
            thread_g->mau = ghost_cb;
            threads->emplace(std::make_pair(index, GHOST), thread_g);
            toBlockInfo.emplace(ghost_cb, BlockInfo(index, GHOST, MAU));
        }
    }

    bool preorder(const IR::PackageBlock* block) override {
        auto pos = 0;
        for (auto param : block->constantValue) {
            if (!param.second) continue;
            if (!param.second->is<IR::PackageBlock>()) continue;
            parsePipeline(param.second->to<IR::PackageBlock>(), pos++);
        }
        return false;
    }

    ProgramThreads* threads;
    BlockInfoMapping toBlockInfo;
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_ARCH_H_ */
