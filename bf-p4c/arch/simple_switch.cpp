#include <algorithm>
#include <initializer_list>
#include <set>
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/uselessCasts.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "bf-p4c/arch/phase0.h"
#include "bf-p4c/arch/remove_set_metadata.h"
#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/device.h"
#include "program_structure.h"
#include "remove_set_metadata.h"
#include "simple_switch.h"

namespace BFN {

//////////////////////////////////////////////////////////////////////////////////////////////
namespace V1 {

class LoadTargetArchitecture : public Inspector {
    ProgramStructure *structure;

 public:
    explicit LoadTargetArchitecture(ProgramStructure *structure) : structure(structure) {
        setName("LoadTargetArchitecture");
        CHECK_NULL(structure);
    }

    void setupMetadataRenameMap() {
        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "egress_spec", 9},
                               MetadataField{"ig_intr_md_for_tm", "ucast_egress_port", 9});

        structure->addMetadata(EGRESS,
                               MetadataField{"standard_metadata", "egress_spec", 9},
                               MetadataField{"eg_intr_md", "egress_port", 9});

        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "egress_port", 9},
                               MetadataField{"ig_intr_md_for_tm", "ucast_egress_port", 9});

        structure->addMetadata(EGRESS,
                               MetadataField{"standard_metadata", "egress_port", 9},
                               MetadataField{"eg_intr_md", "egress_port", 9});

        structure->addMetadata(MetadataField{"standard_metadata", "ingress_port", 9},
                               MetadataField{"ig_intr_md", "ingress_port", 9});

        structure->addMetadata(EGRESS,
                               MetadataField{"standard_metadata", "packet_length", 32},
                               MetadataField{"eg_intr_md", "pkt_length", 16});

        structure->addMetadata(MetadataField{"standard_metadata", "clone_spec", 32},
                               MetadataField{"compiler_generated_meta", "mirror_id", 10});

        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "drop", 1},
                               MetadataField{"ig_intr_md_for_dprsr", "drop_ctl", 3});

        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "drop", 1},
                               MetadataField{"eg_intr_md_for_dprsr", "drop_ctl", 3});

        // standard_metadata.mcast_grp does not have a mapping tofino.
        // we default to ig_intr_md_for_tm.mcast_grp_a just to pass the translation.
        structure->addMetadata(INGRESS,
                               MetadataField{"standard_metadata", "mcast_grp", 16},
                               MetadataField{"ig_intr_md_for_tm", "mcast_grp_a", 16});

        structure->addMetadata(
                INGRESS,
                MetadataField{"standard_metadata", "checksum_error", 1},
                MetadataField{"ig_intr_md_from_prsr", "parser_err", 1, 12});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "checksum_error", 1},
                MetadataField{"eg_intr_md_from_prsr", "parser_err", 1, 12});

        // XXX(seth): We need to figure out what to map this to.
        // structure->addMetadata("standard_metadata", "instance_type",
        //             "eg_intr_md", "instance_type", 32);

        // drop_ctl is moved to ingress/egress_metadata_for_deparser_t in tofino architecture.
        structure->addMetadata(INGRESS,
                               MetadataField{"ig_intr_md_for_tm", "drop_ctl", 3},
                               MetadataField{"ig_intr_md_for_dprsr", "drop_ctl", 3});

        structure->addMetadata(EGRESS,
                               MetadataField{"eg_intr_md_for_oport", "drop_ctl", 3},
                               MetadataField{"eg_intr_md_for_dprsr", "drop_ctl", 3});

        structure->addMetadata(
                MetadataField{"ig_intr_md_from_parser_aux", "ingress_global_tstamp", 48},
                MetadataField{"ig_intr_md_from_prsr", "global_tstamp", 48});

        structure->addMetadata(MetadataField{"standard_metadata", "ingress_global_timestamp", 48},
                               MetadataField{"ig_intr_md_from_prsr", "global_tstamp", 48});

        structure->addMetadata(
                EGRESS,
                MetadataField{"eg_intr_md_from_parser_aux", "egress_global_tstamp", 48},
                MetadataField{"eg_intr_md_from_prsr", "global_tstamp", 48});

        structure->addMetadata(
                INGRESS,
                MetadataField{"ig_intr_md_from_parser_aux", "ingress_parser_err", 16},
                MetadataField{"ig_intr_md_from_prsr", "parser_err", 16});

        structure->addMetadata(
                EGRESS,
                MetadataField{"eg_intr_md_from_parser_aux", "egress_parser_err", 16},
                MetadataField{"eg_intr_md_from_prsr", "parser_err", 16});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "egress_global_timestamp", 48},
                MetadataField{"eg_intr_md_from_prsr", "global_tstamp", 48});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "enq_qdepth", 19},
                MetadataField{"eg_intr_md", "enq_qdepth", 19});

        structure->addMetadata(
                EGRESS,
                MetadataField{"standard_metadata", "deq_qdepth", 19},
                MetadataField{"eg_intr_md", "deq_qdepth", 19});

        structure->addMetadata(
                EGRESS,
                MetadataField{"eg_intr_md_from_parser_aux", "clone_src", 4},
                MetadataField{"compiler_generated_meta", "clone_src", 4});

        structure->addMetadata(
                EGRESS,
                MetadataField{"eg_intr_md_from_parser_aux", "clone_digest_id", 4},
                MetadataField{"compiler_generated_meta", "clone_digest_id", 4});
    }

    void analyzeTofinoModel() {
        for (auto decl : structure->targetTypes) {
            if (auto v = decl->to<IR::Type_Enum>()) {
                structure->enums.emplace(v->name, v);
            } else if (auto v = decl->to<IR::Type_Error>()) {
                for (auto mem : v->members) {
                    structure->errors.emplace(mem->name);
                }
            }
        }
    }

    void postorder(const IR::P4Program *) override {
        setupMetadataRenameMap();

        /// append tofino.p4 architecture definition
        structure->include("tofino/stratum.p4", &structure->targetTypes);
        structure->include("tofino/p4_14_prim.p4", &structure->targetTypes);

        analyzeTofinoModel();
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

class IdleTimeoutTranslation : public Transform {
    ordered_map<const IR::P4Table *, IR::Expression *> propertyMap;

 public:
    IdleTimeoutTranslation() {
        setName("IdleTimeoutTranslation");
    }

    /*
     * translate support_timeout = true and idletime pragma to extern in the form of
     * implementation = idle_timeout(6, true, true);
     * where the parameters are:
     * - precision
     * - two_way_notification
     * - per_flow_idletime_enable
     */
    const IR::Node *postorder(IR::Property *node) override {
        if (node->name == "support_timeout") {
            auto table = findContext<IR::P4Table>();
            auto precision = table->getAnnotation("idletime_precision");
            auto two_way_notify = table->getAnnotation("idletime_two_way_notification");
            auto per_flow_enable = table->getAnnotation("idletime_per_flow_idletime");
            auto type = new IR::Type_Name("idle_timeout");
            auto param = new IR::Vector<IR::Expression>();
            /// XXX(hanw): check default value for two_way_notify and per_flow_enable
            param->push_back(precision ? precision->expr.at(0) :
                             new IR::Constant(IR::Type::Bits::get(3), 3));
            param->push_back(two_way_notify ? new IR::BoolLiteral(two_way_notify) :
                             new IR::BoolLiteral(false));
            param->push_back(per_flow_enable ? new IR::BoolLiteral(per_flow_enable) :
                             new IR::BoolLiteral(false));
            auto constructorExpr = new IR::ConstructorCallExpression(type, param);
            propertyMap.emplace(table, constructorExpr);
        }
        return node;
    }

    const IR::Node *postorder(IR::P4Table *node) override {
        auto it = propertyMap.find(node);
        if (it == propertyMap.end())
            return node;
        auto impl = node->properties->getProperty("implementation");
        if (impl) {
            auto newProperties = new IR::IndexedVector<IR::Property>();
            IR::ListExpression *newList = nullptr;
            if (auto list = impl->to<IR::ListExpression>()) {
                // if implementation already has a list of attached tables.
                auto components = new IR::Vector<IR::Expression>(list);
                components->push_back(it->second);
                newList = new IR::ListExpression(*components);
            } else {
                // if implementation has only one attached table
                auto components = new IR::Vector<IR::Expression>();
                components->push_back(it->second);
                newList = new IR::ListExpression(*components);
            }
            for (auto prop : node->properties->properties) {
                if (prop->name == "implementation") {
                    auto pv = new IR::ExpressionValue(newList);
                    newProperties->push_back(new IR::Property("implementation", pv, true));
                } else {
                    newProperties->push_back(prop);
                }
            }
        } else {
            // if there is no attached table yet
            auto newProperties = new IR::IndexedVector<IR::Property>();
            for (auto prop : node->properties->properties) {
                newProperties->push_back(prop);
            }
            auto components = new IR::Vector<IR::Expression>();
            components->push_back(it->second);
            auto newList = new IR::ListExpression(*components);
            auto pv = new IR::ExpressionValue(newList);
            newProperties->push_back(new IR::Property("implementation", pv, true));
        }
        auto allprops = new IR::IndexedVector<IR::Property>(node->properties->properties);
        auto properties = new IR::TableProperties(*allprops);
        auto table = new IR::P4Table(node->srcInfo, node->name, node->annotations, properties);
        return table;
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

class RemoveNodesWithNoMapping : public Transform {
    // following fields are showing up in struct H, because in P4-14
    // these structs are declared as header type.
    // In TNA, most of these metadata are individual parameter to
    // the control block, and shall be removed from struct H.
    std::set<cstring> removeAllOccurences = {
            "generator_metadata_t_0",
            "ingress_parser_control_signals",
            "standard_metadata_t",
            "egress_intrinsic_metadata_t",
            "egress_intrinsic_metadata_for_mirror_buffer_t",
            "egress_intrinsic_metadata_for_output_port_t",
            "egress_intrinsic_metadata_from_parser_aux_t",
            "ingress_intrinsic_metadata_t",
            "ingress_intrinsic_metadata_for_mirror_buffer_t",
            "ingress_intrinsic_metadata_for_tm_t",
            "ingress_intrinsic_metadata_from_parser_aux_t"};

    std::set<cstring> removeDeclarations = {
            "pktgen_generic_header_t",
            "pktgen_port_down_header_t",
            "pktgen_recirc_header_t",
            "pktgen_timer_header_t"};

 public:
    RemoveNodesWithNoMapping() { setName("RemoveNodesWithNoMapping"); }

    const IR::Node *preorder(IR::Type_Header *node) {
        auto it = removeAllOccurences.find(node->name);
        if (it != removeAllOccurences.end())
            return nullptr;
        it = removeDeclarations.find(node->name);
        if (it != removeDeclarations.end())
            return nullptr;
        return node;
    }

    const IR::Node *preorder(IR::Type_Struct *node) {
        auto it = removeAllOccurences.find(node->name);
        if (it != removeAllOccurences.end())
            return nullptr;
        it = removeDeclarations.find(node->name);
        if (it != removeDeclarations.end())
            return nullptr;
        return node;
    }

    const IR::Node *preorder(IR::StructField *node) {
        auto header = findContext<IR::Type_Struct>();
        if (!header) return node;
        if (header->name != "headers") return node;

        auto type = node->type->to<IR::Type_Name>();
        if (!type) return node;

        auto it = removeAllOccurences.find(type->path->name);
        if (it != removeAllOccurences.end())
            return nullptr;
        return node;
    }

    /// Given a IR::Member of the following structure:
    ///
    /// Member member=mcast_grp_b
    ///   type: Type_Bits size=16 isSigned=0
    ///   expr: Member member=ig_intr_md_for_tm
    ///     type: Type_Header name=ingress_intrinsic_metadata_for_tm_t
    ///     expr: PathExpression
    ///       type: Type_Name...
    ///       path: Path name=hdr absolute=0
    ///
    /// transform it to the following:
    ///
    /// Member member=mcast_grp_b
    ///   type: Type_Bits size=16 isSigned=0
    ///   expr: PathExpression
    ///     type: Type_Name...
    ///     path: Path name=ig_intr_md_for_tm
    const IR::Node *preorder(IR::Member *mem) {
        auto submem = mem->expr->to<IR::Member>();
        if (!submem) return mem;
        auto submemType = submem->type->to<IR::Type_Header>();
        if (!submemType) return mem;
        auto it = removeAllOccurences.find(submemType->name);
        if (it == removeAllOccurences.end()) return mem;

        auto newType = new IR::Type_Name(submemType->name);
        auto newName = new IR::Path(submem->member);
        auto newExpr = new IR::PathExpression(newType, newName);
        auto newMem = new IR::Member(mem->srcInfo, mem->type, newExpr, mem->member);
        return newMem;
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////

/// @pre: assume no nested control block or parser block,
///       as a result, all declarations within a control block have different names.
/// @post: all user provided names for metadata are converted to standard names
///       assumed by the translation map in latter pass.
class NormalizeProgram : public Transform {
    ordered_map<cstring, std::vector<const IR::Node *> *> namescopes;
    ordered_map<cstring, cstring> renameMap;
    ordered_map<cstring, cstring> aliasMap;

 public:
    NormalizeProgram() {}

    void pushParam(const IR::Node *node, cstring param_type, cstring rename) {
        const IR::ParameterList *list;
        if (auto ctrl = node->to<IR::P4Control>()) {
            list = ctrl->type->getApplyParameters();
        } else if (auto parser = node->to<IR::P4Parser>()) {
            list = parser->type->getApplyParameters();
        } else {
            BUG("Unknown block type %1%", node);
        }

        for (auto p : list->parameters) {
            if (!p->type->is<IR::Type_Name>())
                continue;
            auto type_name = p->type->to<IR::Type_Name>();
            auto type = type_name->path->name;
            if (type != param_type)
                continue;
            auto name = p->name;
            auto it = namescopes.find(name);
            if (it == namescopes.end()) {
                auto stack = new std::vector<const IR::Node *>();
                stack->push_back(getOriginal<IR::Node>());
                namescopes.emplace(name, stack);
                renameMap.emplace(name, rename);
            } else {
                auto &stack = it->second;
                stack->push_back(getOriginal<IR::Node>());
            }
        }
    }

    void popParam(const IR::Node *node, cstring param_type) {
        const IR::ParameterList *list = nullptr;
        if (auto ctrl = node->to<IR::P4Control>()) {
            list = ctrl->type->getApplyParameters();
        } else if (auto parser = node->to<IR::P4Parser>()) {
            list = parser->type->getApplyParameters();
        }
        CHECK_NULL(list);

        for (auto p : list->parameters) {
            if (!p->type->is<IR::Type_Name>())
                continue;
            auto type_name = p->type->to<IR::Type_Name>();
            auto type = type_name->path->name;
            if (type != param_type)
                continue;
            auto name = p->name;
            auto it = namescopes.find(name);
            if (it != namescopes.end()) {
                auto &stack = it->second;
                BUG_CHECK(stack->size() >= 1, "Cannot pop empty stack");
                stack->pop_back();
            }
        }
    }

    const IR::Node *preorder(IR::P4Control *node) override {
        pushParam(node, "standard_metadata_t", "standard_metadata");
        return node;
    }

    const IR::Node *postorder(IR::P4Control *node) override {
        popParam(node, "standard_metadata_t");
        return node;
    }

    const IR::Node *preorder(IR::P4Parser *node) override {
        pushParam(node, "standard_metadata_t", "standard_metadata");
        return node;
    }

    const IR::Node *postorder(IR::P4Parser *node) override {
        popParam(node, "standard_metadata_t");
        return node;
    }

    const IR::Node *preorder(IR::Declaration_Variable *node) override {
        auto name = node->name.name;
        auto it = namescopes.find(name);
        if (it != namescopes.end()) {
            auto &stack = it->second;
            stack->push_back(node->to<IR::Node>());
        }
        return node;
    }

    const IR::Node *postorder(IR::Declaration_Variable *node) override {
        auto name = node->name.name;
        auto it = namescopes.find(name);
        if (it != namescopes.end()) {
            auto &stack = it->second;
            stack->pop_back();
        }
        return node;
    }

    const IR::Node *postorder(IR::PathExpression *node) override {
        auto path = node->path->name;
        auto it = namescopes.find(path);
        if (it != namescopes.end()) {
            auto renameIt = renameMap.find(path);
            if (renameIt != renameMap.end()) {
                return new IR::PathExpression(node->srcInfo, node->type,
                                              new IR::Path(renameIt->second));
            }
        }
        return node;
    }

    const IR::Node *postorder(IR::Parameter *node) override {
        auto it = namescopes.find(node->name);
        if (it != namescopes.end()) {
            auto renameIt = renameMap.find(node->name);
            if (renameIt != renameMap.end()) {
                auto rename = renameIt->second;
                return new IR::Parameter(node->srcInfo, rename, node->annotations,
                                         node->direction, node->type);
            }
        }
        return node;
    }

    /// recursively check if a fromName is aliased to toName
    bool isStandardMetadata(cstring fromName) {
        auto it = aliasMap.find(fromName);
        if (it != aliasMap.end()) {
            auto toName_ = it->second;
            if (isStandardMetadata(toName_))
                return true;
            else if (toName_ == "standard_metadata_t")
                return true;
            else
                return false;
        } else {
            return false;
        }
    }

    const IR::Node *preorder(IR::Type_Typedef *node) override {
        if (auto name = node->type->to<IR::Type_Name>()) {
            aliasMap.emplace(node->name, name->path->name);    // std_meta_t -> standard_metadata_t
        }
        return node;
    }

    const IR::Node *postorder(IR::Type_Typedef *node) override {
        if (isStandardMetadata(node->name)) {
            return nullptr;
        }
        return node;
    }

    const IR::Node *postorder(IR::Type_Name *node) override {
        if (isStandardMetadata(node->path->name)) {
            return new IR::Type_Name(node->srcInfo, new IR::Path("standard_metadata_t"));
        }
        return node;
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

/// This pass collects all top level p4program declarations.
class AnalyzeProgram : public Inspector {
    ProgramStructure *structure;

    template<class P4Type, class BlockType>
    void analyzeArchBlock(const IR::ToplevelBlock *blk, cstring name, cstring type) {
        auto main = blk->getMain();
        auto ctrl = main->findParameterValue(name);
        BUG_CHECK(ctrl != nullptr, "%1%: could not find parameter %2%", main, name);
        BUG_CHECK(ctrl->is<BlockType>(), "%1%: main package match the expected model", main);
        auto block = ctrl->to<BlockType>()->container;
        BUG_CHECK(block != nullptr, "Unable to find %1% block in V1Switch", name);
        structure->blockNames.emplace(type, block->name);
    }

 public:
    explicit AnalyzeProgram(ProgramStructure *structure)
            : structure(structure) {
        CHECK_NULL(structure);
        setName("AnalyzeProgram");
    }

    // *** architectural declarations ***
    // matchKindDeclaration
    // constantDeclarations
    // externDeclarations
    // parserDeclarations
    // controlDeclarations
    // *** program & architectural declarations ***
    // actionDeclarations
    void postorder(const IR::Type_Action *node) override {
        structure->action_types.push_back(node);
    }

    // errorDeclaration
    void postorder(const IR::Type_Error *node) override {
        for (auto m : node->members) {
            structure->errors.emplace(m->name);
        }
    }

    // typeDeclarations
    void postorder(const IR::Type_StructLike *node) override {
        structure->type_declarations.emplace(node->name, node);
    }

    void postorder(const IR::Type_Typedef *node) override {
        structure->type_declarations.emplace(node->name, node);
    }

    void postorder(const IR::Type_Enum *node) override {
        structure->enums.emplace(node->name, node);
    }

    // *** program only declarations ***
    // instantiation - parser
    void postorder(const IR::P4Parser *node) override {
        structure->parsers.emplace(node->name, node);
        // additional info for translation
        auto params = node->getApplyParameters();
        if (params->parameters.size() >= 2) {
            structure->user_metadata = node->type->applyParams->parameters.at(2);
        } else {
            ::error("Parser in v1model must have at least 2 parameters");
        }
    }

    // instantiation - control
    void postorder(const IR::P4Control *node) override {
        structure->controls.emplace(node->name, node);
    }

    // instantiation - extern
    void postorder(const IR::Declaration_Instance *node) override {
        // look for global instances
        auto control = findContext<IR::P4Control>();
        if (control) return;
        auto parser = findContext<IR::P4Parser>();
        if (parser) return;
        // ignore main()
        if (auto type = node->type->to<IR::Type_Specialized>()) {
            auto typeName = type->baseType->to<IR::Type_Name>();
            if (typeName && typeName->path->name == "V1Switch")
                return;
        }
        structure->global_instances.emplace(node->name, node);
    }

    // instantiation - program
    void postorder(const IR::P4Program *) override {
        auto params = structure->toplevel->getMain()->getConstructorParameters();
        if (params->parameters.size() != 6) {
            ::error("Expecting 6 parameters instead of %1% in the 'main' instance",
                    params->parameters.size());
            return;
        }
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(
                structure->toplevel, "p", ProgramStructure::INGRESS_PARSER);
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(
                structure->toplevel, "p", ProgramStructure::EGRESS_PARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "ig", ProgramStructure::INGRESS);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "eg", ProgramStructure::EGRESS);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "dep", ProgramStructure::INGRESS_DEPARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "dep", ProgramStructure::EGRESS_DEPARSER);
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "vr", "verifyChecksum");
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(
                structure->toplevel, "ck", "updateChecksum");
    }

    void end_apply() override {
        // add 'compiler_generated_metadata_t'
        auto cgm = new IR::Type_Struct("compiler_generated_metadata_t");

        // Inject new fields for mirroring.
        cgm->fields.push_back(
            new IR::StructField("mirror_id", IR::Type::Bits::get(10)));
        cgm->fields.push_back(
            new IR::StructField("mirror_source", IR::Type::Bits::get(8)));
        cgm->fields.push_back(
            new IR::StructField("clone_src", IR::Type::Bits::get(4)));
        cgm->fields.push_back(
            new IR::StructField("clone_digest_id", IR::Type::Bits::get(4)));


        structure->type_declarations.emplace("compiler_generated_metadata_t", cgm);
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

class CollectVerifyChecksums : public Inspector {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    std::vector<const IR::MethodCallStatement*> verifyChecksums;

 public:
    CollectVerifyChecksums(P4::ReferenceMap *refMap, P4::TypeMap *typeMap)
            : refMap(refMap), typeMap(typeMap) {
        setName("CollectVerifyChecksums");
    }

    const std::vector<const IR::MethodCallStatement*>& get() { return verifyChecksums; }

    void postorder(const IR::MethodCallStatement *node) override {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        CHECK_NULL(mce);
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto ef = mi->to<P4::ExternFunction>()) {
            if (ef->method->name == "verify_checksum") {
                verifyChecksums.push_back(node);
            }
        }
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

class ConstructSymbolTable : public Inspector {
    ProgramStructure *structure;
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    unsigned resubmitIndex;
    unsigned digestIndex;
    unsigned igCloneIndex;
    unsigned egCloneIndex;
    std::set<cstring> globals;
    const std::vector<const IR::MethodCallStatement*>& verifyChecksums;

 public:
    ConstructSymbolTable(ProgramStructure *structure,
                         P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                         const std::vector<const IR::MethodCallStatement*>& verifyChecksums)
            : structure(structure), refMap(refMap), typeMap(typeMap),
              resubmitIndex(0), digestIndex(0), igCloneIndex(0), egCloneIndex(0),
              verifyChecksums(verifyChecksums) {
        CHECK_NULL(structure);
        setName("ConstructSymbolTable");
    }

    /*
     * following extern methods in v1model.p4 need to be converted to an extern instance
     * and a method call on the instance.
     * random, digest, mark_to_drop, hash, verify_checksum, update_checksum, resubmit
     * recirculate, clone, clone3, truncate
     */
    void cvtDigestFunction(const IR::MethodCallStatement *node) {
        /*
         * translate digest() function in ingress control block to
         *
         * ig_intr_md_for_dprsr.digest_type = n;
         *
         */
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in digest() function");
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "digest() must be used in a control block");
        BUG_CHECK(control->name == structure->getBlockName(ProgramStructure::INGRESS),
                  "digest() can only be used in %1%",
                  structure->getBlockName(ProgramStructure::INGRESS));
        IR::PathExpression *path = new IR::PathExpression("ig_intr_md_for_dprsr");
        auto mem = new IR::Member(path, "digest_type");
        auto idx = new IR::Constant(IR::Type::Bits::get(3), digestIndex++);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->_map.emplace(node, stmt);

        BUG_CHECK(mce->typeArguments->size() == 1, "Expected 1 type parameter for %1%",
                  mce->method);
        auto *typeArg = mce->typeArguments->at(0);
        auto *typeName = typeArg->to<IR::Type_Name>();
        BUG_CHECK(typeName != nullptr, "Expected type T in digest to be a typeName %1%", typeArg);
        auto fieldList = refMap->getDeclaration(typeName->path);
        auto declAnno = fieldList->getAnnotation("name");

        BUG_CHECK(typeName != nullptr, "Wrong argument type for %1%", typeArg);
        /*
         * In the ingress deparser, add the following code
         * Digest() learn_1;
         * if (ig_intr_md_for_dprsr.digest_type == n)
         *    learn_1.pack({fields});
         *
         */
        auto field_list = mce->arguments->at(1);
        auto args = new IR::Vector<IR::Expression>({field_list});
        auto expr = new IR::PathExpression(new IR::Path(typeName->path->name));
        auto member = new IR::Member(expr, "pack");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                new IR::MethodCallExpression(member, typeArgs, args));

        auto condExprPath = new IR::Member(
                new IR::PathExpression(new IR::Path("ig_intr_md_for_dprsr")), "digest_type");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        structure->ingressDeparserStatements.push_back(cond);

        auto declArgs = new IR::Vector<IR::Expression>({});
        auto declType = new IR::Type_Name("Digest");
        auto decl = new IR::Declaration_Instance(typeName->path->name,
                                                 new IR::Annotations({declAnno}),
                                                 declType, declArgs);
        structure->ingressDeparserDeclarations.push_back(decl);
    }

    void cvtCloneFunction(const IR::MethodCallStatement *node, bool hasData) {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in clone() function");
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "clone() must be used in a control block");

        const bool isIngress =
                (control->name == structure->getBlockName(ProgramStructure::INGRESS));
        auto *deparserMetadataPath =
                new IR::PathExpression(isIngress ? "ig_intr_md_for_dprsr"
                                                 : "eg_intr_md_for_dprsr");
        auto *compilerMetadataPath =
                new IR::PathExpression("compiler_generated_meta");

        // Generate a fresh index for this clone field list. This is used by the
        // hardware to select the correct mirror table entry, and to select the
        // correct parser for this field list.
        auto *idx =
                new IR::Constant(IR::Type::Bits::get(3), isIngress ? igCloneIndex++
                                                                   : egCloneIndex++);
        if ((isIngress ? igCloneIndex : egCloneIndex) > 8) {
            ::error("Too many clone() calls in %1%",
                    isIngress ? ProgramStructure::INGRESS : ProgramStructure::EGRESS);
            return;
        }

        {
            auto *block = new IR::BlockStatement;

            // Construct a value for `mirror_source`, which is
            // compiler-generated metadata that's prepended to the user field
            // list. Its layout (in network order) is:
            //   [  0    1       2          3         4       5    6   7 ]
            //     [unused] [coalesced?] [gress] [mirrored?] [mirror_type]
            // Here `gress` is 0 for I2E mirroring and 1 for E2E mirroring.
            //
            // This information is used to set intrinsic metadata in the egress
            // parser. The `mirrored?` bit is particularly important; if that
            // bit is zero, the egress parser expects the following bytes to be
            // bridged metadata rather than mirrored fields.
            //
            // XXX(seth): Glass is able to reuse `mirror_type` for last three
            // bits of this data, which eliminates the need for an extra PHV
            // container. We'll start doing that soon as well, but we need to
            // work out some issues with PHV allocation constraints first.
            auto *mirrorSource = new IR::Member(compilerMetadataPath, "mirror_source");
            const unsigned sourceIdx = idx->asInt();
            const unsigned isMirroredTag = 1 << 3;
            const unsigned gressTag = isIngress ? 0 : 1 << 4;
            auto *source =
                    new IR::Constant(IR::Type::Bits::get(8), sourceIdx | isMirroredTag | gressTag);
            block->components.push_back(new IR::AssignmentStatement(mirrorSource, source));

            // Set `mirror_type`, which is used as the digest selector in the
            // deparser (in other words, it selects the field list to use).
            auto *mirrorIdx = new IR::Member(deparserMetadataPath, "mirror_type");
            block->components.push_back(new IR::AssignmentStatement(mirrorIdx, idx));

            // Set `mirror_id`, which configures the mirror session id that the
            // hardware uses to route mirrored packets in the TM.
            BUG_CHECK(mce->arguments->size() >= 2,
                      "No mirror session id specified: %1%", mce);
            auto *mirrorId = new IR::Member(compilerMetadataPath, "mirror_id");
            auto *mirrorIdValue = mce->arguments->at(1);
            /// v1model mirror_id is 32bit, cast to bit<10>
            auto *castedMirrorIdValue = new IR::Cast(IR::Type::Bits::get(10), mirrorIdValue);
            block->components.push_back(new IR::AssignmentStatement(mirrorId,
                                                                    castedMirrorIdValue));

            structure->_map.emplace(node, block);
        }

        /*
         * generate statement in ingress/egress deparser to prepend mirror metadata
         *
         * Mirror mirror();
         * if (ig_intr_md_for_dprsr.mirror_type == N)
         *    mirror.emit({});
         */

        // Only instantiate the extern for the first instance of clone()
        if ((isIngress ? igCloneIndex : egCloneIndex) == 1) {
            auto declArgs = new IR::Vector<IR::Expression>({});
            auto declType = new IR::Type_Name("Mirror");
            auto decl = new IR::Declaration_Instance("mirror", declType, declArgs);
            if (isIngress)
                structure->ingressDeparserDeclarations.push_back(decl);
            else
                structure->egressDeparserDeclarations.push_back(decl);
        }

        auto *newFieldList = new IR::ListExpression({
            new IR::Member(compilerMetadataPath, "mirror_source")});

        if (hasData && mce->arguments->size() > 2) {
            auto *clonedData = mce->arguments->at(2);
            if (auto *originalFieldList = clonedData->to<IR::ListExpression>())
                newFieldList->components.pushBackOrAppend(&originalFieldList->components);
            else
                newFieldList->components.push_back(clonedData);
        }

        auto args = new IR::Vector<IR::Expression>();
        args->push_back(new IR::Member(compilerMetadataPath, "mirror_id"));
        args->push_back(newFieldList);

        auto pathExpr = new IR::PathExpression(new IR::Path("mirror"));
        auto member = new IR::Member(pathExpr, "emit");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                new IR::MethodCallExpression(member, typeArgs, args));
        auto condExprPath = new IR::Member(deparserMetadataPath, "mirror_type");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        if (isIngress)
            structure->ingressDeparserStatements.push_back(cond);
        else
            structure->egressDeparserStatements.push_back(cond);
    }

    void cvtDropFunction(const IR::MethodCallStatement *node) {
        auto control = findContext<IR::P4Control>();
        if (control->name == structure->getBlockName(ProgramStructure::INGRESS)) {
            auto path = new IR::Member(
                    new IR::PathExpression("ig_intr_md_for_dprsr"), "drop_ctl");
            auto val = new IR::Constant(IR::Type::Bits::get(3), 1);
            auto stmt = new IR::AssignmentStatement(path, val);
            structure->_map.emplace(node, stmt);
        } else if (control->name == structure->getBlockName(ProgramStructure::EGRESS)) {
            auto path = new IR::Member(
                    new IR::PathExpression("eg_intr_md_for_dprsr"), "drop_ctl");
            auto val = new IR::Constant(IR::Type::Bits::get(3), 1);
            auto stmt = new IR::AssignmentStatement(path, val);
            structure->_map.emplace(node, stmt);
        }
    }

    /// execute_meter_with_color is converted to a meter extern
    void cvtExecuteMeterFunctiion(const IR::MethodCallStatement *node) {
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr,
                  "execute_meter_with_color() must be used in a control block");
        auto mce = node->methodCall->to<IR::MethodCallExpression>();

        auto inst = mce->arguments->at(0)->to<IR::PathExpression>();
        BUG_CHECK(inst != nullptr, "Invalid meter instance %1%", inst);
        auto path = inst->to<IR::PathExpression>()->path;
        auto pathExpr = new IR::PathExpression(path->name);

        auto method = new IR::Member(node->srcInfo, pathExpr, "execute");
        auto args = new IR::Vector<IR::Expression>();
        args->push_back(mce->arguments->at(1));
        args->push_back(new IR::Cast(IR::Type::Bits::get(2), mce->arguments->at(3)));
        auto methodCall = new IR::MethodCallExpression(node->srcInfo, method, args);

        auto meterColor = mce->arguments->at(2);
        auto size = meterColor->type->width_bits();
        IR::AssignmentStatement *assign = nullptr;
        if (size > 8) {
            assign = new IR::AssignmentStatement(
                    meterColor, new IR::Cast(IR::Type::Bits::get(size), methodCall));
        } else if (size < 8) {
            assign = new IR::AssignmentStatement(meterColor,
                                                 new IR::Slice(methodCall, size - 1, 0));
        } else {
            assign = new IR::AssignmentStatement(meterColor, methodCall);
        }
        structure->_map.emplace(node, assign);
    }

    void convertHashPrimitive(const IR::MethodCallStatement *node, cstring hashName) {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce->arguments->size() > 4, "insufficient arguments to hash() function");
        auto pDest = mce->arguments->at(0);
        auto pBase = mce->arguments->at(2);
        auto pMax = mce->arguments->at(4);

        // Check the max value
        auto w = pDest->type->width_bits();
        // Add data unconditionally.
        auto args = new IR::Vector<IR::Expression>({ mce->arguments->at(3) });
        if (pMax->to<IR::Constant>() == nullptr || pBase->to<IR::Constant>() == nullptr)
            BUG("Only compile-time constants are supported for hash base offset and max value");

        if (pMax->to<IR::Constant>()->asLong() < (1LL << w))  {
            if (pBase->type->width_bits() != w)
                pBase = new IR::Cast(IR::Type::Bits::get(w), pBase);
            args->push_back(pBase);

            if (pMax->type->width_bits() != w)
                pMax = new IR::Cast(IR::Type::Bits::get(w), pMax);
            args->push_back(pMax);
        } else {
            BUG_CHECK(pBase->to<IR::Constant>()->asInt() == 0,
                      "The base offset for a hash calculation must be zero");
        }

        auto member = new IR::Member(new IR::PathExpression(hashName), "get");

        auto result = new IR::AssignmentStatement(pDest,
            new IR::MethodCallExpression(node->srcInfo, member, args));

        structure->_map.emplace(node, result);
    }

    /// hash function is converted to an instance of hash extern in the enclosed control block
    void cvtHashFunction(const IR::MethodCallStatement *node) {
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "hash() must be used in a control block");
        const bool isIngress =
                (control->name == structure->getBlockName(ProgramStructure::INGRESS));

        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "Malformed IR: method call expression cannot be nullptr");

        BUG_CHECK(mce->arguments->size() > 3, "hash extern must have at least 4 arguments");
        auto typeArgs = new IR::Vector<IR::Type>({mce->typeArguments->at(0)});

        auto hashType = new IR::Type_Specialized(new IR::Type_Name("Hash"), typeArgs);
        auto hashName = cstring::make_unique(structure->unique_names, "hash", '_');
        structure->unique_names.insert(hashName);
        convertHashPrimitive(node, hashName);

        // create hash instance
        auto algorithm = mce->arguments->at(1)->clone();
        if (auto typeName = algorithm->to<IR::Member>()) {
            structure->typeNamesToDo.emplace(typeName, typeName);
            LOG3("add " << typeName << " to translation map"); }
        auto hashArgs = new IR::Vector<IR::Expression>({algorithm});
        auto hashInst = new IR::Declaration_Instance(hashName, hashType, hashArgs);

        if (isIngress) {
            structure->ingressDeclarations.push_back(hashInst->to<IR::Declaration>());
        } else {
            structure->egressDeclarations.push_back(hashInst->to<IR::Declaration>());
        }
    }

    /// resubmit function is converted to an assignment on resubmit_type
    void cvtResubmitFunction(const IR::MethodCallStatement *node) {
        /*
         * translate resubmit() function in ingress control block to
         *
         * ig_intr_md_for_dprsr.resubmit_type = n;
         *
         */
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in resubmit() function");
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "resubmit() must be used in a control block");
        BUG_CHECK(control->name == structure->getBlockName(ProgramStructure::INGRESS),
                  "resubmit() can only be used in ingress control");
        IR::PathExpression *path = new IR::PathExpression("ig_intr_md_for_dprsr");
        auto mem = new IR::Member(path, "resubmit_type");
        auto idx = new IR::Constant(IR::Type::Bits::get(3), resubmitIndex++);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->_map.emplace(node, stmt);

        /*
         * In the ingress deparser, add the following code
         *
         * Resubmit() resubmit;
         * if (ig_intr_md_for_dprsr.resubmit_type == n)
         *    resubmit.emit({fields});
         *
         */

        if (resubmitIndex > 8) {
            ::error("Too many resubmit() calls in %1%", ProgramStructure::INGRESS);
            return;
        }

        // Only instantiate the extern for the first instance of resubmit()
        if (resubmitIndex == 1) {
            auto declArgs = new IR::Vector<IR::Expression>({});
            auto declType = new IR::Type_Name("Resubmit");
            auto decl = new IR::Declaration_Instance("resubmit",
                                                 declType, declArgs);
            structure->ingressDeparserDeclarations.push_back(decl);
        }

        auto fl = mce->arguments->at(0);   // resubmit field list
        /// compiler inserts resubmit_type as the format id to
        /// identify the resubmit group, it is 3 bits in size, but
        /// will be aligned to byte boundary in backend.
        auto new_fl = new IR::ListExpression({mem});
        for (auto f : fl->to<IR::ListExpression>()->components)
            new_fl->push_back(f);
        auto args = new IR::Vector<IR::Expression>(new_fl);
        auto expr = new IR::PathExpression(new IR::Path("resubmit"));
        auto member = new IR::Member(expr, "emit");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                new IR::MethodCallExpression(member, typeArgs, args));

        auto condExprPath = new IR::Member(
                new IR::PathExpression(new IR::Path("ig_intr_md_for_dprsr")),
                "resubmit_type");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        structure->ingressDeparserStatements.push_back(cond);
    }

    void convertRandomPrimitive(const IR::MethodCallStatement *node, cstring randName) {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();

        auto dest = mce->arguments->at(0);
        // ignore lower bound
        auto hi = mce->arguments->at(2);
        auto args = new IR::Vector<IR::Expression>();
        args->push_back(hi);

        auto method = new IR::PathExpression(randName);
        auto member = new IR::Member(method, "get");
        auto call = new IR::MethodCallExpression(node->srcInfo, member, args);
        auto stmt = new IR::AssignmentStatement(dest, call);
        structure->_map.emplace(node, stmt);
    }

    void cvtRandomFunction(const IR::MethodCallStatement *node) {
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "random() must be used in a control block");
        const bool isIngress =
                (control->name == structure->getBlockName(ProgramStructure::INGRESS));
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "Malformed IR: method call expression cannot be nullptr");

        auto baseType = mce->arguments->at(0);
        auto typeArgs = new IR::Vector<IR::Type>({baseType->type});
        auto type = new IR::Type_Specialized(new IR::Type_Name("random"), typeArgs);
        auto param = new IR::Vector<IR::Expression>();
        auto randName = cstring::make_unique(structure->unique_names, "random", '_');
        structure->unique_names.insert(randName);
        convertRandomPrimitive(node, randName);

        auto randInst = new IR::Declaration_Instance(randName, type, param);

        if (isIngress) {
            structure->ingressDeclarations.push_back(randInst->to<IR::Declaration>());
        } else {
            structure->egressDeclarations.push_back(randInst->to<IR::Declaration>());
        }
    }

    boost::optional<ChecksumSourceMap::value_type>
    analyzeVerifyOrUpdateChecksum(const IR::MethodCallStatement *statement, cstring which) {
        auto methodCall = statement->methodCall->to<IR::MethodCallExpression>();
        if (!methodCall) {
            ::warning("Expected a non-empty method call expression: %1%", statement);
            return boost::none;
        }
        auto method = methodCall->method->to<IR::PathExpression>();
        if (!method || (method->path->name != which)) {
            ::warning("Expected an %1% statement in %2%", statement, which);
            return boost::none;
        }
        if (methodCall->arguments->size() != 4) {
            ::warning("Expected 4 arguments for %1% statement: %2%", statement, which);
            return boost::none;
        }
        auto destField = (*methodCall->arguments)[2]->to<IR::Member>();
        CHECK_NULL(destField);

        return ChecksumSourceMap::value_type(destField, methodCall);
    }

    const IR::Declaration_Instance*
    getVerifyOrUpdateChecksumDeclaration(ChecksumSourceMap::value_type csum) {
        auto typeArgs = new IR::Vector<IR::Type>();
        typeArgs->push_back(csum.second->arguments->at(2)->type);
        auto inst = new IR::Type_Specialized(new IR::Type_Name("checksum"), typeArgs);

        auto csum_name = cstring::make_unique(structure->unique_names, "checksum", '_');
        structure->unique_names.insert(csum_name);
        auto args = new IR::Vector<IR::Expression>();
        auto hashAlgo = new IR::Member(
                new IR::TypeNameExpression("HashAlgorithm_t"), "CRC16");
        args->push_back(hashAlgo);
        auto decl = new IR::Declaration_Instance(csum_name, inst, args);

        return decl;
    }

    void implementUpdateChecksum(ChecksumSourceMap::value_type csum) {
        auto* decl = getVerifyOrUpdateChecksumDeclaration(csum);

        structure->ingressDeparserDeclarations.push_back(decl);
        structure->egressDeparserDeclarations.push_back(decl);

        auto fieldlist = csum.second->arguments->at(1);
        auto dest_field = csum.second->arguments->at(2);

        auto* updateCall = new IR::MethodCallStatement(
                csum.second->srcInfo,
                new IR::Member(new IR::PathExpression(decl->name), "update"),
                {fieldlist, dest_field});

        structure->ingressDeparserStatements.push_back(updateCall);
        structure->egressDeparserStatements.push_back(updateCall);
    }

    void cvtUpdateChecksum(const IR::MethodCallStatement *method) {
        auto checksum = analyzeVerifyOrUpdateChecksum(method, "update_checksum");
        if (checksum)
            implementUpdateChecksum(*checksum);
    }

    /// build up a table for all metadata member that need to be translated.
    void postorder(const IR::Member *node) override {
        /// header/struct names appeared in p4_14_include/tofino/intrinsic_metadata.p4
        ordered_set<cstring> toTranslateInControl = {"standard_metadata",
                                                     "ig_intr_md_for_tm",
                                                     "ig_intr_md",
                                                     "ig_pg_md",
                                                     "ig_intr_md_for_mb",
                                                     "ig_intr_md_from_parser_aux",
                                                     "eg_intr_md",
                                                     "eg_intr_md_for_mb",
                                                     "eg_intr_md_from_parser_aux",
                                                     "eg_intr_md_for_oport"};
        ordered_set<cstring> toTranslateInParser = {"standard_metadata", "ig_prsr_ctrl"};
        auto gress = findOrigCtxt<IR::P4Control>();
        if (gress) {
            if (auto member = node->expr->to<IR::Member>()) {
                auto it = toTranslateInControl.find(member->member.name);
                if (it != toTranslateInControl.end()) {
                    structure->membersToDo.emplace(node, node);
                }
            } else if (auto expr = node->expr->to<IR::PathExpression>()) {
                auto path = expr->path->to<IR::Path>();
                CHECK_NULL(path);
                auto it = toTranslateInControl.find(path->name);
                if (it != toTranslateInControl.end()) {
                    if (gress->name == structure->getBlockName(ProgramStructure::INGRESS)) {
                        structure->pathsThread.emplace(node, INGRESS);
                        structure->pathsToDo.emplace(node, node);
                    } else if (gress->name == structure->getBlockName(ProgramStructure::EGRESS)) {
                        structure->pathsThread.emplace(node, EGRESS);
                        structure->pathsToDo.emplace(node, node);
                    } else {
                        WARNING("path " << node << " in "
                                        << gress->name.name << " is not translated");
                    }
                }
            } else if (auto expr = node->expr->to<IR::TypeNameExpression>()) {
                auto tn = expr->typeName->to<IR::Type_Name>();
                CHECK_NULL(tn);
                structure->typeNamesToDo.emplace(node, node);
            } else {
                WARNING("Unable to translate path " << node);
            }
        }
        auto parser = findOrigCtxt<IR::P4Parser>();
        if (parser) {
            if (auto expr = node->expr->to<IR::PathExpression>()) {
                auto path = expr->path->to<IR::Path>();
                CHECK_NULL(path);
                auto it = toTranslateInParser.find(path->name);
                if (it == toTranslateInParser.end())
                    return;
                if (auto type = expr->type->to<IR::Type_Name>()) {
                    if (type->path->name == "ingress_parser_control_signals") {
                        auto stmt = findContext<IR::AssignmentStatement>();
                        if (stmt && node->member == "priority") {
                            structure->priorityCalls.emplace(stmt, stmt);
                        } else if (stmt && node->member == "parser_counter") {
                            structure->parserCounterCalls.emplace(stmt, stmt);
                        }
                        // handle parser counter in select() expression
                        auto select = findContext<IR::SelectExpression>();
                        if (select) {
                            structure->parserCounterSelects.emplace(node, node);
                        }
                    }
                } else if (expr->type->is<IR::Type_Struct>()) {
                    structure->pathsToDo.emplace(node, node);
                } else {
                    WARNING("metadata " << node << " is not converted");
                }
            } else if (auto expr = node->expr->to<IR::TypeNameExpression>()) {
                auto tn = expr->typeName->to<IR::Type_Name>();
                CHECK_NULL(tn);
                structure->typeNamesToDo.emplace(node, node);
            } else {
                WARNING("Expression " << node << " is not converted");
            }
        }
    }

    void cvtActionProfile(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Name>();
        BUG_CHECK(type->path->name == "action_profile",
                  "action_profile converter cannot be applied to %1%", type->path->name);

        type = new IR::Type_Name("ActionProfile");
        auto result = new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                                   type, node->arguments);
        structure->_map.emplace(node, result);
    }

    void cvtActionSelector(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Name>();
        BUG_CHECK(type->path->name == "action_selector",
                  "action_selector converter cannot be applied to %1%", type->path->name);
        auto declarations = new IR::IndexedVector<IR::Declaration>();

        // Create a new instance of Hash<W>
        auto typeArgs = new IR::Vector<IR::Type>();
        auto w = node->arguments->at(2)->to<IR::Constant>()->asInt();
        typeArgs->push_back(IR::Type::Bits::get(w));

        auto args = new IR::Vector<IR::Expression>();
        args->push_back(node->arguments->at(0));

        auto specializedType = new IR::Type_Specialized(
            new IR::Type_Name("Hash"), typeArgs);
        auto hashName = cstring::make_unique(
            structure->unique_names, node->name + "__hash_", '_');
        structure->unique_names.insert(hashName);
        declarations->push_back(
            new IR::Declaration_Instance(hashName, specializedType, args));

        args = new IR::Vector<IR::Expression>();
        // size
        args->push_back(node->arguments->at(1));
        // hash
        args->push_back(new IR::PathExpression(hashName));
        // selector_mode
        auto sel_mode = new IR::Member(
            new IR::TypeNameExpression("SelectorMode_t"), "FAIR");
        if (auto anno = node->annotations->getSingle("mode")) {
            auto mode = anno->expr.at(0)->to<IR::StringLiteral>();
            if (mode->value == "resilient")
                sel_mode->member = IR::ID("RESILIENT");
            else if (mode->value != "fair" && mode->value != "non_resilient")
                BUG("Selector mode provided for the selector is not supported", node);
        } else {
            WARNING("No mode specified for the selector %s. Assuming fair" << node);
        }
        args->push_back(sel_mode);

        type = new IR::Type_Name("ActionSelector");
        declarations->push_back(new IR::Declaration_Instance(
            node->srcInfo, node->name, node->annotations, type, args));
        structure->_map.emplace(node, declarations);
    }

    void cvtCounterDecl(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Name>();
        if (!type) return;
        auto typeArgs = new IR::Vector<IR::Type>();
        // type<W>
        if (auto anno = node->annotations->getSingle("min_width")) {
            auto min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            typeArgs->push_back(IR::Type::Bits::get(min_width));
        } else {
            auto min_width = IR::Type::Bits::get(32);
            typeArgs->push_back(min_width);
            WARNING("Could not infer min_width for counter %s, using bit<32>" << node);
        }
        // type<S>
        if (auto s = node->arguments->at(0)->to<IR::Constant>()) {
            typeArgs->push_back(s->type->to<IR::Type_Bits>());
        }

        auto specializedType = new IR::Type_Specialized(new IR::Type_Name("Counter"), typeArgs);
        auto decl = new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                                 specializedType, node->arguments);
        structure->_map.emplace(node, decl);
    }

    void cvtMeterDecl(const IR::Declaration_Instance* node) {
        auto type = node->type->to<IR::Type_Name>();
        if (!type) return;
        auto typeArgs = new IR::Vector<IR::Type>();
        if (auto s = node->arguments->at(0)->to<IR::Constant>()) {
            typeArgs->push_back(s->type->to<IR::Type_Bits>());
        }
        auto specializedType = new IR::Type_Specialized(new IR::Type_Name("Meter"), typeArgs);
        auto decl = new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                                 specializedType, node->arguments);
        structure->_map.emplace(node, decl);
    }

    void cvtDirectMeterDecl(const IR::Declaration_Instance* node) {
        auto decl = new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                                 new IR::Type_Name("DirectMeter"), node->arguments);
        structure->_map.emplace(node, decl);
    }

    void cvtDirectCounterDecl(const IR::Declaration_Instance *node) {
        auto typeArgs = new IR::Vector<IR::Type>();
        if (auto anno = node->annotations->getSingle("min_width")) {
            auto min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            typeArgs->push_back(IR::Type::Bits::get(min_width));
        } else {
            auto min_width = IR::Type::Bits::get(32);
            typeArgs->push_back(min_width);
            WARNING("Could not infer min_width for counter %s, using bit<32>" << node);
        }
        auto specializedType = new IR::Type_Specialized(
            new IR::Type_Name("DirectCounter"), typeArgs);
        auto decl = new IR::Declaration_Instance(
            node->srcInfo, node->name, node->annotations, specializedType, node->arguments);
        structure->_map.emplace(node, decl);
    }

    void cvtExternDeclaration(const IR::Declaration_Instance *node, cstring name) {
        if (name == "counter") {
            cvtCounterDecl(node);
        } else if (name == "direct_counter") {
            cvtDirectCounterDecl(node);
        } else if (name == "meter") {
            cvtMeterDecl(node);
        } else if (name == "direct_meter") {
            cvtDirectMeterDecl(node);
        } else if (name == "action_profile") {
            cvtActionProfile(node);
        } else if (name == "action_selector") {
            cvtActionSelector(node);
        }
        // TODO: register
    }

    void postorder(const IR::Declaration_Instance *node) override {
        if (node->type->is<IR::Type_Specialized>()) {
            auto type = node->type->to<IR::Type_Specialized>()->baseType;
            if (type->path->name == "V1Switch") {
                auto type_h = node->type->to<IR::Type_Specialized>()->arguments->at(0);
                auto type_m = node->type->to<IR::Type_Specialized>()->arguments->at(1);
                structure->type_h = type_h->to<IR::Type_Name>()->path->name;
                structure->type_m = type_m->to<IR::Type_Name>()->path->name;
            }
            cvtExternDeclaration(node, type->path->name);
        } else if (auto type = node->type->to<IR::Type_Name>()) {
            cvtExternDeclaration(node, type->path->name);
        }
    }

    void postorder(const IR::MethodCallStatement *node) override {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        CHECK_NULL(mce);
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto em = mi->to<P4::ExternMethod>()) {
            cstring name = em->actualExternType->name;
            if (name == "direct_meter") {
                DirectMeterConverter cvt(structure);
                structure->_map.emplace(node, node->apply(cvt));
            } else if (name == "meter") {
                MeterConverter cvt(structure);
                structure->_map.emplace(node, node->apply(cvt));
            }
            // Counter method needs no translation
            // TODO register
        } else if (auto ef = mi->to<P4::ExternFunction>()) {
            cstring name = ef->method->name;
            if (name == "hash") {
                cvtHashFunction(node);
            } else if (name == "resubmit") {
                cvtResubmitFunction(node);
            } else if (name == "mark_to_drop" || name == "drop") {
                cvtDropFunction(node);
            } else if (name == "random") {
                cvtRandomFunction(node);
            } else if (name == "digest") {
                cvtDigestFunction(node);
            } else if (name == "clone") {
                cvtCloneFunction(node, /* hasData = */ false);
            } else if (name == "clone3") {
                cvtCloneFunction(node, /* hasData = */ true);
            } else if (name == "update_checksum") {
                cvtUpdateChecksum(node);
            } else if (name == "execute_meter_with_color") {
                cvtExecuteMeterFunctiion(node);
            }
        }
    }

    // if a path refers to a global declaration, move
    // the global declaration to local control;
    void postorder(const IR::PathExpression *node) override {
        auto path = node->path;
        auto it = structure->global_instances.find(path->name);
        if (it != structure->global_instances.end()) {
            if (globals.find(path->name) != globals.end())
                return;
            auto control = findContext<IR::P4Control>();
            BUG_CHECK(control != nullptr,
                      "unable to reference global instance from non-control block");
            if (control->name == structure->getBlockName(ProgramStructure::INGRESS)) {
                structure->ingressDeclarations.push_back(it->second);
                globals.insert(path->name);
            } else if (control->name == structure->getBlockName(ProgramStructure::EGRESS)) {
                structure->egressDeclarations.push_back(it->second);
                globals.insert(path->name);
            } else {
                BUG("unexpected reference to global instance from %1%", control->name);
            }
        }
    }

    struct CollectExtractMembers : public Inspector {
        CollectExtractMembers() {}

        std::vector<const IR::Member*> extracts;

        void postorder(const IR::MethodCallStatement* statement) override {
            auto* call = statement->methodCall;
            auto* method = call->method->to<IR::Member>();
            if (method && method->member == "extract") {
                for (auto m : *(call->arguments))
                    extracts.push_back(m->to<IR::Member>());
            }
        }
    };

    // FIXME -- yet another 'deep' comparison for expressions
    static bool equiv(const IR::Expression *a, const IR::Expression *b) {
        if (a == b) return true;
        if (typeid(*a) != typeid(*b)) return false;
        if (auto ma = a->to<IR::Member>()) {
            auto mb = b->to<IR::Member>();
            return ma->member == mb->member && equiv(ma->expr, mb->expr); }
        if (auto pa = a->to<IR::PathExpression>()) {
            auto pb = b->to<IR::PathExpression>();
            return pa->path->name == pb->path->name; }
        return false;
    }

    static bool belongsTo(const IR::Member* a, const IR::Member* b) {
        if (!a || !b) return false;

        // case 1: a is field, b is field
        if (equiv(a, b)) return true;

        // case 2: a is field, b is header
        if (a->type->is<IR::Type::Bits>()) {
            if (equiv(a->expr, b)) return true;
        }

        return false;
    }

    void implementVerifyChecksum(ChecksumSourceMap::value_type csum, cstring stateName,
                                 const std::vector<const IR::Member*>& extracts) {
        auto *decl = getVerifyOrUpdateChecksumDeclaration(csum);

        structure->ingressParserDeclarations.push_back(decl);
        structure->egressParserDeclarations.push_back(decl);

        auto fieldlist = csum.second->arguments->at(1);
        auto dest_field = csum.second->arguments->at(2);

        // check if any of the fields or dest belong to extracts

        std::vector<IR::Statement*> ingressStmts;
        std::vector<IR::Statement*> egressStmts;

        for (auto extract : extracts) {
            for (auto f : fieldlist->to<IR::ListExpression>()->components) {
                if (belongsTo(f->to<IR::Member>(), extract)) {
                    auto addCall = new IR::MethodCallStatement(csum.second->srcInfo,
                        new IR::Member(new IR::PathExpression(decl->name), "add"), {f});
                    structure->ingressParserStatements[stateName].push_back(addCall);
                    structure->egressParserStatements[stateName].push_back(addCall);
                }
            }

            if (belongsTo(dest_field->to<IR::Member>(), extract)) {
                auto methodCall = new IR::Member(new IR::PathExpression(decl->name), "verify");
                auto verifyCall = new IR::MethodCallExpression(csum.second->srcInfo,
                                                               methodCall, {});
                auto rhs = new IR::Cast(IR::Type::Bits::get(1), verifyCall);

                auto ingress_parser_err = new IR::Member(
                    new IR::PathExpression("ig_intr_md_from_prsr"), "parser_err");

                auto lhs = new IR::Slice(ingress_parser_err, 12, 12);

                structure->ingressParserStatements[stateName].push_back(
                    new IR::AssignmentStatement(lhs, rhs));

                auto egress_parser_err = new IR::Member(
                    new IR::PathExpression("eg_intr_md_from_prsr"), "parser_err");

                lhs = new IR::Slice(egress_parser_err, 12, 12);
                structure->egressParserStatements[stateName].push_back(
                    new IR::AssignmentStatement(lhs, rhs));
            }
        }
    }

    void postorder(const IR::ParserState *state) override {
        // see if any of the verify_checksum statement is relavent to this state
        // if so, convert relavent fields in verify_checksum to add/verify

        CollectExtractMembers collectExtractMembers;
        state->apply(collectExtractMembers);

        for (auto* vc : verifyChecksums) {
            auto checksum = analyzeVerifyOrUpdateChecksum(vc, "verify_checksum");
            if (checksum)
                implementVerifyChecksum(*checksum, state->name, collectExtractMembers.extracts);
        }
    }
};

}  // namespace V1

/// The general work flow of architecture translation consists of the following steps:
/// * analyze original source program to build a programStructure that represent original program.
/// * construct symbol tables of each IR type.
/// * iterate through the symbol tables, and perform transformation on each entry.
/// * update program structure with transform IR node from symbol table.
/// * reprint a valid P16 program to program structure.
SimpleSwitchTranslation::SimpleSwitchTranslation(P4::ReferenceMap* refMap,
                                                 P4::TypeMap* typeMap, BFN_Options& options) {
    setName("Translation");
    addDebugHook(options.getDebugHook());
    auto evaluator = new P4::EvaluatorPass(refMap, typeMap);
    auto structure = new BFN::V1::ProgramStructure;
    auto collectVerifyChecksums = new BFN::V1::CollectVerifyChecksums(refMap, typeMap);
    addPasses({
        new P4::TypeChecking(refMap, typeMap, true),
        new RemoveExternMethodCallsExcludedByAnnotation,
        new BFN::V1::NormalizeProgram(),
        evaluator,
        new VisitFunctor([structure, evaluator]() {
            structure->toplevel = evaluator->getToplevelBlock(); }),
        new TranslationFirst(),
        new BFN::V1::LoadTargetArchitecture(structure),
        new BFN::V1::RemoveNodesWithNoMapping(),
        new BFN::V1::AnalyzeProgram(structure),
        collectVerifyChecksums,
        new BFN::V1::ConstructSymbolTable(structure, refMap, typeMap,
                                          collectVerifyChecksums->get()),
        new BFN::GenerateTofinoProgram(structure),
        new BFN::TranslationLast(),
        new BFN::AddIntrinsicMetadata,
        new P4::ClonePathExpressions,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new BFN::RemoveSetMetadata(refMap, typeMap),
        new BFN::TranslatePhase0(refMap, typeMap),
        new P4::ClonePathExpressions,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new BFN::BridgeMetadata(refMap, typeMap),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
