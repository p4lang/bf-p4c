/**
 * \defgroup ArchTranslation BFN::ArchTranslation
 * \ingroup midend
 * \brief Set of passes that normalize variations in the architectures.
 */
#ifndef BF_P4C_ARCH_ARCH_H_
#define BF_P4C_ARCH_ARCH_H_

#include <set>
#include <boost/algorithm/string.hpp>
#include <boost/optional.hpp>
#include "frontends/common/resolveReferences/referenceMap.h"
#include "ir/ir-generated.h"
#include "ir/ir.h"
#include "ir/namemap.h"
#include "ir/pass_manager.h"
#include "ir/visitor.h"
#include "lib/path.h"
#include "frontends/common/options.h"
#include "frontends/p4/typeMap.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/sideEffects.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/arch/program_structure.h"
#include "bf-p4c/midend/type_checker.h"

namespace BFN {

/** \ingroup ArchTranslation */
enum class ARCH { TNA, T2NA, PSA, V1MODEL };

/**
 * \ingroup ArchTranslation
 * Find and remove extern method calls that the P4 programmer has requested by
 * excluded from translation using the `@dont_translate_extern_method` pragma.
 * Currently this pragma is only supported on actions; it takes as an argument
 * a list of strings that identify extern method calls to remove from the action
 * body.
 */
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

/** \ingroup ArchTranslation */
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

/** \ingroup ArchTranslation */
class TranslationFirst : public PassManager {
 public:
    TranslationFirst() { setName("TranslationFirst"); }
};

/** \ingroup ArchTranslation */
class TranslationLast : public PassManager {
 public:
    TranslationLast() { setName("TranslationLast"); }
};

/**
 * \ingroup ArchTranslation
 * \brief PassManager that governs the normalization of variations in the architectures.
 * @sa BFN::SimpleSwitchTranslation
 * @sa BFN::TnaArchTranslation
 * @sa BFN::T2naArchTranslation
 * @sa BFN::T5naArchTranslation
 * @sa BFN::PortableSwitchTranslation
 */
class ArchTranslation : public PassManager {
 public:
    ArchTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap, BFN_Options& options);
};

/** \ingroup ArchTranslation */
enum ArchBlock_t {
    PARSER = 0,
    MAU,
    DEPARSER,
    BLOCK_TYPE
};

static const std::map<cstring, std::map<std::pair<ArchBlock_t, gress_t>, int> > archBlockIndex = {
    { "TNA", {
        { { PARSER, INGRESS }, 0 },
        { { MAU, INGRESS }, 1 },
        { { DEPARSER, INGRESS }, 2 },
        { { PARSER, EGRESS }, 3 },
        { { MAU, EGRESS }, 4 },
        { { DEPARSER, EGRESS }, 5 }
    } },
    { "T2NA", {
        { { PARSER, INGRESS }, 0 },
        { { MAU, INGRESS }, 1 },
        { { DEPARSER, INGRESS }, 2 },
        { { PARSER, EGRESS }, 3 },
        { { MAU, EGRESS }, 4 },
        { { DEPARSER, EGRESS }, 5 },
        { { MAU, GHOST }, 6 }
    } },
    { "T3NA", {
        { { PARSER, INGRESS }, 0 },
        { { MAU, INGRESS }, 1 },
        { { DEPARSER, INGRESS }, 2 },
        { { PARSER, EGRESS }, 3 },
        { { MAU, EGRESS }, 4 },
        { { DEPARSER, EGRESS }, 5 },
        { { MAU, GHOST }, 6 }
    } },
    { "T5NA", {
        { { PARSER, INGRESS }, 0 },
        { { MAU, INGRESS }, 1 },
        { { MAU, EGRESS }, 2 },
        { { DEPARSER, EGRESS }, 3 },
        { { MAU, GHOST }, 4 }
    } } };

/** \ingroup ArchTranslation */
struct BlockInfo {
    /// Index in the Pipeline invocation.
    int              pipe_index;
    /// The pipe name to generate a fully qualified name in case of multipipe scenarios.
    cstring          pipe_name;
    gress_t          gress;
    /// which port to configure using this impl.
    std::vector<int> portmap;
    /// A block could be a parser, deparser or a mau.
    ArchBlock_t      type;
    /// arch specified name for the block
    cstring          arch;
    /// used by multi-parser support
    cstring          parser_instance_name;
    int              block_index;

    BlockInfo(int pi, cstring pn, gress_t gress, ArchBlock_t type, cstring arch,
              cstring parser_inst = "")
        : pipe_index(pi),
          pipe_name(pn),
          gress(gress),
          type(type),
          arch(arch),
          parser_instance_name(parser_inst) {
        BUG_CHECK(archBlockIndex.count(arch) != 0,
                    "Unknown architecture %1%", arch);
        BUG_CHECK(archBlockIndex.at(arch).find({type, gress}) != archBlockIndex.at(arch).end(),
                    "Unknown block type %1% for architecture %2%", type, arch);
        block_index = archBlockIndex.at(arch).at({type, gress});
    }
    void dbprint(std::ostream& out) {
        out << "pipe_index " << pipe_index << " ";
        out << "pipe_name" << pipe_name << " ";
        out << "gress " << gress << " ";
        out << "block_index" << block_index << " ";
        out << "type " << type << " ";
        out << "arch" << arch << std::endl;
    }
    bool operator==(const BlockInfo& other) const {
        return pipe_index == other.pipe_index && pipe_name == other.pipe_name &&
               gress == other.gress && block_index == other.block_index &&
               type == other.type && arch == other.arch;
    }
    bool operator<(const BlockInfo& other) const {
        return std::tie(pipe_index, pipe_name, gress, block_index, type, arch) <
               std::tie(other.pipe_index, other.pipe_name, other.gress,
                        other.block_index, other.type, other.arch);
    }
};

/** \ingroup ArchTranslation */
using ProgramThreads = std::map<std::pair<int, gress_t>, const IR::BFN::P4Thread*>;
/** \ingroup ArchTranslation */
using BlockInfoMapping = std::multimap<const IR::Node*, BlockInfo>;
/** \ingroup ArchTranslation */
using DefaultPortMap = std::map<int, std::vector<int>>;

// An Inspector pass to extract @pkginfo annotation from the P4 program
class GetPkgInfo : public Inspector {
    inline static cstring arch = "UNKNOWN";
    inline static cstring version = "UNKNOWN";

 public:
    bool found = false;
    GetPkgInfo() { setName("GetPkgInfo"); }
    profile_t init_apply(const IR::Node* node) override {
        found = false;
        return Inspector::init_apply(node); }
    void end_apply() override {
        BUG_CHECK(found != false, "No @pkginfo annotation found in the program"); }
    bool preorder(const IR::PackageBlock* pkg) override;

    static cstring getArch() { return arch; }
    static cstring getVersion() { return version; }
};

struct CollectPkgInfo : public PassManager {
    CollectPkgInfo(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
        passes.emplace_back(evaluator);
        passes.emplace_back(new VisitFunctor([evaluator]() {
            auto toplevel = evaluator->getToplevelBlock();
            auto main = toplevel->getMain();
            ERROR_CHECK(main != nullptr, ErrorType::ERR_INVALID,
                        "program: does not instantiate `main`");
            main->apply(*new GetPkgInfo());
        }));
        setName("CollectPkgInfo");
    }
};

/** \ingroup ArchTranslation */
class ParseTna : public Inspector {
    const IR::PackageBlock*   mainBlock = nullptr;

 public:
    ParseTna() { setName("ParseTna"); }

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
/** \ingroup ArchTranslation */
struct DoRewriteControlAndParserBlocks : Transform {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    BlockInfoMapping* block_info;
    // mapping from tuple(pipeline_name, block_index) to the block name.
    ordered_map<std::tuple<cstring, int>, cstring> block_name_map;

    explicit DoRewriteControlAndParserBlocks(P4::ReferenceMap *refMap, P4::TypeMap* typeMap,
        BlockInfoMapping* block_info) :
            refMap(refMap), typeMap(typeMap), block_info(block_info) {}
    const IR::Node* postorder(IR::P4Parser *node) override;
    const IR::Node* postorder(IR::P4Control *node) override;
    const IR::Node* postorder(IR::Declaration_Instance* node) override;
    Visitor::profile_t init_apply(const IR::Node* node) override {
        block_name_map.clear();
        return Transform::init_apply(node);
    }
};

/**
 * \ingroup ArchTranslation
 * This pass rewrites the IR::P4Parser and IR::P4Control node to
 * IR::BFN::TnaParser, IR::BFN::TnaControl
 * IR::BFN::TnaDeparser.
 * The latter three classes are used in the midend till extract_maupipe,
 * which is then converted to IR::BFN::Parser, IR::BFN::Pipe and
 * IR::BFN::Deparser.
 */
struct RewriteControlAndParserBlocks : public PassManager {
    RewriteControlAndParserBlocks(P4::ReferenceMap* refMap,
                                  P4::TypeMap* typeMap) {
        auto* evaluator = new P4::EvaluatorPass(refMap, typeMap);
        auto* parseTna = new ParseTna();

        passes.emplace_back(evaluator);
        passes.emplace_back(new VisitFunctor([evaluator, parseTna]() {
            auto toplevel = evaluator->getToplevelBlock();
            auto main = toplevel->getMain();
            ERROR_CHECK(main != nullptr, ErrorType::ERR_INVALID,
                        "program: does not instantiate `main`");
            main->apply(*parseTna);
        }));
        passes.emplace_back(new P4::TypeChecking(refMap, typeMap));
        passes.emplace_back(
            new DoRewriteControlAndParserBlocks(refMap, typeMap,
            &parseTna->toBlockInfo));
    }
};

/**
 * \ingroup ArchTranslation
 * Restore all parameters to the controls and parsers as specified by the /
 * architecture.
 */
struct RestoreParams: public Transform {
    explicit RestoreParams(BFN_Options& options, P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
        : options(options), refMap(refMap), typeMap(typeMap) {}
    const IR::Node* postorder(IR::BFN::TnaControl* control) override;
    const IR::Node* postorder(IR::BFN::TnaParser* parser) override;
    const IR::Node* postorder(IR::BFN::TnaDeparser* deparser) override;
    BFN_Options &options;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
    cstring arch;
    cstring version;
};

/**
 * \ingroup ArchTranslation
 * XXX(hanw): probably should be done before translation
 */
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

/** \ingroup ArchTranslation */
class ApplyEvaluator : public PassManager {
 public:
    P4::ReferenceMap        *refMap;
    P4::TypeMap             *typeMap;
    const IR::ToplevelBlock *toplevel = nullptr;

    ApplyEvaluator() {
        refMap = new P4::ReferenceMap;
        typeMap = new P4::TypeMap;
        refMap->setIsV1(true);
        auto evaluator = new BFN::EvaluatorPass(refMap, typeMap);
        addPasses({
            new BFN::TypeChecking(refMap, typeMap, true),
            evaluator,
            new VisitFunctor([this, evaluator]() { toplevel = evaluator->getToplevelBlock(); }),
        });
    }

    ApplyEvaluator(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
        refMap(refMap), typeMap(typeMap) {
        CHECK_NULL(refMap);
        CHECK_NULL(typeMap);
        refMap->setIsV1(true);
        auto evaluator = new BFN::EvaluatorPass(refMap, typeMap);
        addPasses({
            new BFN::TypeChecking(refMap, typeMap, true),
            evaluator,
            new VisitFunctor([this, evaluator]() { toplevel = evaluator->getToplevelBlock(); }),
        });
    }

    const IR::ToplevelBlock* getToplevelBlock() { return toplevel; }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_ARCH_H_ */
