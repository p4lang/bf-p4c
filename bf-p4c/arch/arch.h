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

enum ArchBlock_t {
    PARSER = 0,
    MAU,
    DEPARSER,
    BLOCK_TYPE
};

struct BlockInfo {
    int index;
    // XXX(amresh); In addition to the index, we need the pipe name to generate
    // a fully qualified name in case of multipipe scenarios.
    cstring pipe;
    gress_t gress;

    // which port to configure using this impl.
    std::vector<int> portmap;

    ArchBlock_t type;

    // arch specified name for the block
    cstring arch;

    BlockInfo(int index, cstring pipe, gress_t gress, ArchBlock_t type, cstring arch = "")
            : index(index), pipe(pipe), gress(gress), type(type), arch(arch) {}
    void dbprint(std::ostream& out) {
        out << "index " << index << " ";
        out << "pipe" << pipe << " ";
        out << "gress " << gress << " ";
        out << "type " << type << " ";
        out << "arch" << arch << std::endl;
    }
};

using ProgramThreads = std::map<std::pair<int, gress_t>, const IR::BFN::P4Thread*>;
using BlockInfoMapping = std::multimap<const IR::Node*, BlockInfo>;
using DefaultPortMap = std::map<int, std::vector<int>>;

class ParseTna : public Inspector {
    const IR::PackageBlock*   mainBlock;
 public:
    ParseTna() { }

    // parse tna pipeline with single parser.
    void parseSingleParserPipeline(const IR::PackageBlock* block, unsigned index);

    // parse tna pipeline with multiple parser.
    void parseMultipleParserInstances(const IR::PackageBlock* block,
            cstring pipe, IR::BFN::P4Thread *thread, gress_t gress);

    void parsePortMapAnnotation(const IR::PackageBlock* block, DefaultPortMap& map);

    bool preorder(const IR::PackageBlock* block) override;

 public:
    ProgramThreads threads;
    BlockInfoMapping toBlockInfo;
    bool hasMultiplePipes = false;
    bool hasMultipleParsers = false;
};

struct DoRewriteControlAndParserBlocks : Transform {
 public:
    explicit DoRewriteControlAndParserBlocks(BlockInfoMapping* block_info) :
            block_info(block_info) {}
    const IR::Node* postorder(IR::P4Parser *node) override;
    const IR::Node* postorder(IR::P4Control *node) override;

 private:
    BlockInfoMapping* block_info;
    bool *hasMultiplePipes = nullptr;
    bool *hasMultipleParsers = nullptr;
};

// This pass rewrites the IR::P4Parser and IR::P4Control node to
// IR::BFN::TnaParser, IR::BFN::TnaControl
// IR::BFN::TnaDeparser.
// The latter three classes are used in the midend till extract_maupipe,
// which is then converted to IR::BFN::Parser, IR::BFN::Pipe and
// IR::BFN::Deparser.
struct RewriteControlAndParserBlocks : public PassManager {
 public:
    RewriteControlAndParserBlocks(P4::ReferenceMap* refMap,
                                  P4::TypeMap* typeMap) {
        auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
        auto* parseTna = new ParseTna();
        passes.push_back(evaluator);
        passes.push_back(new VisitFunctor([evaluator, parseTna]() {
            auto toplevel = evaluator->getToplevelBlock();
            toplevel->getMain()->apply(*parseTna);
        }));
        passes.push_back(
            new DoRewriteControlAndParserBlocks(&parseTna->toBlockInfo));
    }
};

/// Restore all parameters to the controls and parsers as specified by the /
/// architecture.
struct RestoreParams: public Transform {
    explicit RestoreParams(BFN_Options &options) : options(options) { }
    IR::BFN::TnaControl* preorder(IR::BFN::TnaControl* control);
    IR::BFN::TnaParser* preorder(IR::BFN::TnaParser* parser);

    BFN_Options &options;
};

/// XXX(hanw): probably should be done before translation
class LoweringType : public Transform {
    std::map<cstring, unsigned> enum_encoding;

 public:
    LoweringType() {}

    // lower MeterColor_t to bit<2> because it is used
    const IR::Node* postorder(IR::Type_Enum* node) override {
        if (node->name == "MeterColor_t")
            enum_encoding.emplace(node->name, 2);
        return node;
    }

    const IR::Node* postorder(IR::Type_Name* node) override {
        auto name = node->path->name;
        if (enum_encoding.count(name)) {
            auto size = enum_encoding.at(name);
            return new IR::Type_Bits(size, false);
        }
        return node;
    }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_ARCH_H_ */
