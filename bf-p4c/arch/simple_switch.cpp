#include "simple_switch.h"

#include <algorithm>
#include <initializer_list>
#include <set>
#include "bf-p4c/arch/phase0.h"
#include "bf-p4c/device.h"

namespace BFN {

//////////////////////////////////////////////////////////////////////////////////////////////

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

class LoadTargetArchitecture : public Inspector {
    ProgramStructure* structure;

 public:
    explicit LoadTargetArchitecture(ProgramStructure* structure) : structure(structure) {
        setName("LoadTargetArchitecture");
        CHECK_NULL(structure);
    }

    void addMetadata(gress_t gress, cstring ss, cstring sf,
                                    cstring ds, cstring df, unsigned w) {
        auto& nameMap = gress == INGRESS ? structure->ingressMetadataNameMap
                                         : structure->egressMetadataNameMap;
        nameMap.emplace(MetadataField{ss, sf}, MetadataField{ds, df});
        structure->metadataTypeMap.emplace(MetadataField{ds, df}, w);
    }

    void addMetadata(cstring ss, cstring sf, cstring ds, cstring df, unsigned w) {
        addMetadata(INGRESS, ss, sf, ds, df, w);
        addMetadata(EGRESS, ss, sf, ds, df, w);
    }

    void setupMetadataRenameMap() {
        addMetadata(INGRESS, "standard_metadata", "egress_spec",
                             "ig_intr_md_for_tm", "ucast_egress_port", 9);
        addMetadata(EGRESS, "standard_metadata", "egress_spec",
                            "eg_intr_md", "egress_port", 9);

        addMetadata(INGRESS, "standard_metadata", "egress_port",
                             "ig_intr_md_for_tm", "ucast_egress_port", 9);
        addMetadata(EGRESS, "standard_metadata", "egress_port",
                            "eg_intr_md", "egress_port", 9);

        addMetadata("standard_metadata", "ingress_port",
                    "ig_intr_md", "ingress_port", 9);

        addMetadata("standard_metadata", "packet_length", "eg_intr_md", "pkt_length", 16);

        addMetadata(INGRESS, "standard_metadata", "clone_spec",
                             "ig_intr_md_for_mb", "mirror_id", 10);
        addMetadata(EGRESS, "standard_metadata", "clone_spec",
                            "eg_intr_md_for_mb", "mirror_id", 10);

        addMetadata("standard_metadata", "drop", "ig_intr_md_for_tm", "drop_ctl", 3);

        // XXX(hanw): standard_metadata.mcast_grp does not have a mapping tofino.
        // we default to ig_intr_md_for_tm.mcast_grp_a just to pass the translation.
        addMetadata(INGRESS, "standard_metadata", "mcast_grp",
                             "ig_intr_md_for_tm", "mcast_grp_a", 16);
        // XXX(seth): We need to figure out what to map this to.
        // addMetadata("standard_metadata", "instance_type",
        //             "eg_intr_md", "instance_type", 32);
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

    void postorder(const IR::P4Program*) override {
        setupMetadataRenameMap();

        /// append tofino.p4 architecture definition
        structure->include("tofino/stratum.p4", &structure->targetTypes);
        structure->include("tofino/p4_14_types.p4", &structure->targetTypes);
        structure->include("tofino/p4_14_prim.p4", &structure->targetTypes);
        structure->include("tofino/p4_16_prim.p4", &structure->targetTypes);

        analyzeTofinoModel();
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

class IdleTimeoutTranslation : public Transform {
    ordered_map<const IR::P4Table*, IR::Expression*> propertyMap;

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
    const IR::Node* postorder(IR::Property* node) override {
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
            param->push_back(per_flow_enable ? new IR::BoolLiteral(per_flow_enable):
                                 new IR::BoolLiteral(false));
            auto constructorExpr = new IR::ConstructorCallExpression(type, param);
            propertyMap.emplace(table, constructorExpr);
        }
        return node;
    }

    const IR::Node* postorder(IR::P4Table* node) override {
        auto it = propertyMap.find(node);
        if (it == propertyMap.end())
            return node;
        auto impl = node->properties->getProperty("implementation");
        if (impl) {
            auto newProperties = new IR::IndexedVector<IR::Property>();
            IR::ListExpression* newList = nullptr;
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

    const IR::Node* preorder(IR::Type_Header* node) {
        auto it = removeAllOccurences.find(node->name);
        if (it != removeAllOccurences.end())
            return nullptr;
        it = removeDeclarations.find(node->name);
        if (it != removeDeclarations.end())
            return nullptr;
        return node; }

    const IR::Node* preorder(IR::Type_Struct* node) {
        auto it = removeAllOccurences.find(node->name);
        if (it != removeAllOccurences.end())
            return nullptr;
        it = removeDeclarations.find(node->name);
        if (it != removeDeclarations.end())
            return nullptr;
        return node; }

    const IR::Node* preorder(IR::StructField* node) {
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
    const IR::Node* preorder(IR::Member* mem) {
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
        return newMem; }
};

//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////

/// @pre: assume no nested control block or parser block,
///       as a result, all declarations within a control block have different names.
/// @post: all user provided names for metadata are converted to standard names
///       assumed by the translation map in latter pass.
class NormalizeV1modelProgram : public Transform {
    ordered_map<cstring, std::vector<const IR::Node*> *> namescopes;
    ordered_map<cstring, cstring> renameMap;
    ordered_map<cstring, cstring> aliasMap;

 public:
    NormalizeV1modelProgram() {}

    void pushParam(const IR::Node* node, cstring param_type, cstring rename) {
        const IR::ParameterList* list;
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
                auto stack = new std::vector<const IR::Node*>();
                stack->push_back(getOriginal<IR::Node>());
                namescopes.emplace(name, stack);
                renameMap.emplace(name, rename);
            } else {
                auto &stack = it->second;
                stack->push_back(getOriginal<IR::Node>());
            }
        }
    }

    void popParam(const IR::Node* node, cstring param_type) {
        const IR::ParameterList* list = nullptr;
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

    const IR::Node* preorder(IR::P4Control* node) override {
        pushParam(node, "standard_metadata_t", "standard_metadata");
        return node;
    }

    const IR::Node* postorder(IR::P4Control* node) override {
        popParam(node, "standard_metadata_t");
        return node;
    }

    const IR::Node* preorder(IR::P4Parser* node) override {
        pushParam(node, "standard_metadata_t", "standard_metadata");
        return node;
    }

    const IR::Node* postorder(IR::P4Parser* node) override {
        popParam(node, "standard_metadata_t");
        return node;
    }

    const IR::Node* preorder(IR::Declaration_Variable* node) override {
        auto name = node->name.name;
        auto it = namescopes.find(name);
        if (it != namescopes.end()) {
            auto &stack = it->second;
            stack->push_back(node->to<IR::Node>());
        }
        return node;
    }

    const IR::Node* postorder(IR::Declaration_Variable* node) override {
        auto name = node->name.name;
        auto it = namescopes.find(name);
        if (it != namescopes.end()) {
            auto &stack = it->second;
            stack->pop_back();
        }
        return node;
    }

    const IR::Node* postorder(IR::PathExpression* node) override {
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

    const IR::Node* postorder(IR::Parameter* node) override {
        auto it = namescopes.find(node->name);
        if (it != namescopes.end()) {
            auto renameIt = renameMap.find(node->name);
            if (renameIt != renameMap.end()) {
                auto rename = renameIt->second;
                return new IR::Parameter(node->srcInfo, rename, node->annotations,
                                         node->direction, node->type);
            }}
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

    const IR::Node* preorder(IR::Type_Typedef* node) override {
        if (auto name = node->type->to<IR::Type_Name>()) {
            aliasMap.emplace(node->name, name->path->name);    // std_meta_t -> standard_metadata_t
        }
        return node;
    }

    const IR::Node* postorder(IR::Type_Typedef* node) override {
        if (isStandardMetadata(node->name)) {
            return nullptr;
        }
        return node;
    }

    const IR::Node* postorder(IR::Type_Name* node) override {
        if (isStandardMetadata(node->path->name)) {
            return new IR::Type_Name(node->srcInfo, new IR::Path("standard_metadata_t"));
        }
        return node;
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

/// This pass collects all top level p4program declarations.
class AnalyzeV1modelProgram : public Inspector {
    ProgramStructure* structure;

    template<class P4Type, class BlockType>
    void analyzeArchBlock(const IR::ToplevelBlock* blk, cstring name, cstring type) {
        auto main = blk->getMain();
        auto ctrl = main->findParameterValue(name);
        BUG_CHECK(ctrl != nullptr, "%1%: could not find parameter %2%", main, name);
        BUG_CHECK(ctrl->is<BlockType>(), "%1%: main package match the expected model", main);
        auto block = ctrl->to<BlockType>()->container;
        BUG_CHECK(block != nullptr, "Unable to find %1% block in V1Switch", name);
        structure->blockNames.emplace(type, block->name);
    }

 public:
    explicit AnalyzeV1modelProgram(ProgramStructure* structure)
    : structure(structure) { CHECK_NULL(structure); setName("AnalyzeV1modelProgram"); }

    // *** architectural declarations ***
    // matchKindDeclaration
    // constantDeclarations
    // externDeclarations
    // parserDeclarations
    // controlDeclarations
    // *** program & architectural declarations ***
    // actionDeclarations
    void postorder(const IR::Type_Action* node) override
    { structure->action_types.push_back(node); }
    // errorDeclaration
    void postorder(const IR::Type_Error* node) override {
        for (auto m : node->members) {
            structure->errors.emplace(m->name);
        }
    }
    // typeDeclarations
    void postorder(const IR::Type_Struct* node) override
    { structure->struct_types.emplace(node->name, node); }
    void postorder(const IR::Type_Header* node) override
    { structure->header_types.emplace(node->name, node); }
    void postorder(const IR::Type_HeaderUnion* node) override
    { structure->header_union_types.emplace(node->name, node); }
    void postorder(const IR::Type_Typedef* node) override
    { structure->typedef_types.emplace(node->name, node); }
    void postorder(const IR::Type_Enum* node) override
    { structure->enums.emplace(node->name, node); }

    // *** program only declarations ***
    // instantiation - parser
    void postorder(const IR::P4Parser* node) override {
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
    void postorder(const IR::P4Control* node) override {
        structure->controls.emplace(node->name, node);
    }

    // instantiation - extern
    void postorder(const IR::Declaration_Instance* node) override {
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
    void postorder(const IR::P4Program*) override {
        auto params = structure->toplevel->getMain()->getConstructorParameters();
        if (params->parameters.size() != 6) {
            ::error("Expecting 6 parameters instead of %1% in the 'main' instance",
                    params->parameters.size());
            return;
        }
        analyzeArchBlock<IR::P4Parser, IR::ParserBlock>(structure->toplevel, "p", "parser");
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(structure->toplevel, "ig", "ingress");
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(structure->toplevel, "eg", "egress");
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(structure->toplevel, "dep", "deparser");
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(structure->toplevel, "vr",
                                                          "verifyChecksum");
        analyzeArchBlock<IR::P4Control, IR::ControlBlock>(structure->toplevel, "ck",
                                                          "updateChecksum");
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

class ConstructSymbolTable : public Inspector {
    ProgramStructure* structure;
    P4::ReferenceMap* refMap;
    P4::TypeMap*      typeMap;
    unsigned          resubmitIndex;
    unsigned          digestIndex;
    unsigned          igCloneIndex;
    unsigned          egCloneIndex;
    std::set<cstring> globals;

 public:
    ConstructSymbolTable(ProgramStructure* structure,
                         P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
    : structure(structure), refMap(refMap), typeMap(typeMap),
      resubmitIndex(0), digestIndex(0), igCloneIndex(0), egCloneIndex(0)
    { CHECK_NULL(structure); setName("ConstructSymbolTable"); }

    /*
     * following extern methods in v1model.p4 need to be converted to an extern instance
     * and a method call on the instance.
     * random, digest, mark_to_drop, hash, verify_checksum, update_checksum, resubmit
     * recirculate, clone, clone3, truncate
     */
    void cvtDigestFunction(const IR::MethodCallStatement* node) {
        /*
         * translate digest() function in ingress control block to
         *
         * ig_intr_md_for_dprsr.digest_idx = n;
         *
         */
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in digest() function");
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "digest() must be used in a control block");
        BUG_CHECK(control->name == structure->getBlockName("ingress"),
                  "digest() can only be used in %1%", structure->getBlockName("ingress"));
        IR::PathExpression* path = new IR::PathExpression("ig_intr_md_for_deparser");
        auto mem = new IR::Member(path, "learn_idx");
        auto idx = new IR::Constant(IR::Type::Bits::get(3), digestIndex++);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->digestCalls.emplace(node, stmt);

        BUG_CHECK(mce->typeArguments->size() == 1, "Expected 1 type parameter for %1%",
                  mce->method);
        auto* typeArg = mce->typeArguments->at(0);
        auto* typeName = typeArg->to<IR::Type_Name>();
        BUG_CHECK(typeName != nullptr, "Expected type T in digest to be a typeName %1%", typeArg);
        auto fieldList = refMap->getDeclaration(typeName->path);
        auto declAnno = fieldList->getAnnotation("name");

        BUG_CHECK(typeName != nullptr, "Wrong argument type for %1%", typeArg);
        /*
         * In the ingress deparser, add the following code
         * _learning_packet_ () learn_1;
         * if (ig_intr_md_for_dprsr.learn_idx == n)
         *    learning_1.pack({fields});
         *
         */
        auto field_list = mce->arguments->at(1);
        auto args = new IR::Vector<IR::Expression>({ field_list });
        auto expr = new IR::PathExpression(new IR::Path(typeName->path->name));
        auto member = new IR::Member(expr, "pack");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                       new IR::MethodCallExpression(member, typeArgs, args));

        auto condExprPath = new IR::Member(
             new IR::PathExpression(new IR::Path("ig_intr_md_for_deparser")), "learn_idx");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        structure->ingressDeparserStatements.push_back(cond);

        auto declArgs = new IR::Vector<IR::Expression>({ mce->arguments->at(0) });
        auto declType = new IR::Type_Specialized(new IR::Type_Name("_learning_packet_"),
                                                 mce->typeArguments);
        auto decl = new IR::Declaration_Instance(typeName->path->name,
                                                 new IR::Annotations({ declAnno }),
                                                 declType, declArgs);
        structure->ingressDeparserDeclarations.push_back(decl);
    }

    void cvtCloneFunction(const IR::MethodCallStatement* node, bool hasData) {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in clone() function");
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "clone() must be used in a control block");

        const bool isIngress = control->name == structure->getBlockName("ingress");
        auto* deparserMetadataPath =
          new IR::PathExpression(isIngress ? "ig_intr_md_for_deparser"
                                           : "eg_intr_md_for_deparser");
        auto* mirrorBufferMetadataPath =
          new IR::PathExpression(isIngress ? "ig_intr_md_for_mb"
                                           : "eg_intr_md_for_mb");

        // Generate a fresh index for this clone field list. This is used by the
        // hardware to select the correct mirror table entry, and to select the
        // correct parser for this field list.
        auto* idx =
          new IR::Constant(IR::Type::Bits::get(3), isIngress ? igCloneIndex++
                                                             : egCloneIndex++);
        if (idx->asInt() > 7) {
            ::error("Too many clone() calls in %1%",
                    isIngress ? "ingress" : "egress");
            return;
        }

        {
            auto* block = new IR::BlockStatement;

            // Construct a value for `mirror_source`, which is
            // compiler-generated metadata that's prepended to the user field
            // list. Its layout (in network order) is:
            //   [  0    1       2          3         4       5    6   7 ]
            //     [unused] [coalesced?] [gress] [mirrored?] [mirror idx]
            // Here `gress` is 0 for I2E mirroring and 1 for E2E mirroring.
            //
            // This information is used to set intrinsic metadata in the egress
            // parser. The `mirrored?` bit is particularly important; if that
            // bit is zero, the egress parser expects the following bytes to be
            // bridged metadata rather than mirrored fields.
            //
            // XXX(seth): Glass is able to reuse `mirror_idx` for last three
            // bits of this data, which eliminates the need for an extra PHV
            // container. We'll start doing that soon as well, but we need to
            // work out some issues with PHV allocation constraints first.
            auto* mirrorSource = new IR::Member(deparserMetadataPath, "mirror_source");
            const unsigned sourceIdx = idx->asInt();
            const unsigned isMirroredTag = 1 << 3;
            const unsigned gressTag = isIngress ? 0 : 1 << 4;
            auto* source =
              new IR::Constant(IR::Type::Bits::get(8), sourceIdx | isMirroredTag | gressTag);
            block->components.push_back(new IR::AssignmentStatement(mirrorSource, source));

            // Set `mirror_idx`, which is used as the digest selector in the
            // deparser (in other words, it selects the field list to use).
            auto* mirrorIdx = new IR::Member(deparserMetadataPath, "mirror_idx");
            block->components.push_back(new IR::AssignmentStatement(mirrorIdx, idx));

            // Set `mirror_id`, which configures the mirror session id that the
            // hardware uses to route mirrored packets in the TM.
            BUG_CHECK(mce->arguments->size() >= 2,
                      "No mirror session id specified: %1%", mce);
            auto* mirrorId = new IR::Member(mirrorBufferMetadataPath, "mirror_id");
            auto* mirrorIdValue = mce->arguments->at(1);
            block->components.push_back(new IR::AssignmentStatement(mirrorId,
                                                                    mirrorIdValue));

            structure->cloneCalls.emplace(node, block);
        }

        /*
         * generate statement in ingress/egress deparser to prepend mirror metadata
         * if (ig_intr_md_for_dprsr.mirror_idx == N)
         *    mirror.emit({});
         */

        auto* newFieldList = new IR::ListExpression({
            new IR::Member(mirrorBufferMetadataPath, "mirror_id"),
            new IR::Member(deparserMetadataPath, "mirror_source"),
        });
        if (hasData && mce->arguments->size() > 2) {
            auto* clonedData = mce->arguments->at(2);
            if (auto* originalFieldList = clonedData->to<IR::ListExpression>())
                newFieldList->components.pushBackOrAppend(&originalFieldList->components);
            else
                newFieldList->components.push_back(clonedData);
        }
        auto* args = new IR::Vector<IR::Expression>({ newFieldList });

        auto pathExpr = new IR::PathExpression(new IR::Path("mirror"));
        auto member = new IR::Member(pathExpr, "emit");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
             new IR::MethodCallExpression(member, typeArgs, args));
        auto condExprPath = new IR::Member(deparserMetadataPath, "mirror_idx");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        if (isIngress)
            structure->ingressDeparserStatements.push_back(cond);
        else
            structure->egressDeparserStatements.push_back(cond);
    }

    void cvtDropFunction(const IR::MethodCallStatement* node) {
        auto control = findContext<IR::P4Control>();
        if (control->name == structure->getBlockName("ingress")) {
            auto path = new IR::Member(
                            new IR::PathExpression("ig_intr_md_for_tm"), "drop_ctl");
            auto val = new IR::Constant(IR::Type::Bits::get(3), 1);
            auto stmt = new IR::AssignmentStatement(path, val);
            structure->dropCalls.emplace(node, stmt);
        } else if (control->name == structure->getBlockName("egress")) {
            auto path = new IR::Member(
                            new IR::PathExpression("eg_intr_md_for_oport"), "drop_ctl");
            auto val = new IR::Constant(IR::Type::Bits::get(3), 1);
            auto stmt = new IR::AssignmentStatement(path, val);
            structure->dropCalls.emplace(node, stmt);
        } else {
            BUG("mark_to_drop() can only be used in ingress or egress");
        }
    }

    /// execute_meter_with_color is converted to a meter extern
    void cvtExecuteMeterFunctiion(const IR::MethodCallStatement* node) {
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "execute_meter_with_color() must be used in a control block");
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

        auto stmt = new IR::MethodCallStatement(methodCall);
        WARNING("execute_meter_with_color is translated without a return value");
        // auto stmt = new IR::AssignmentStatement(mce->arguments->at(2), methodCall);
        structure->executeMeterCalls.emplace(node, stmt);
    }

    /// hash function is converted to an instance of hash extern in the enclosed control block
    void cvtHashFunction(const IR::MethodCallStatement* node) {
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "hash() must be used in a control block");
        const bool isIngress = control->name == structure->getBlockName("ingress");

        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "Malformed IR: method call expression cannot be nullptr");

        BUG_CHECK(mce->arguments->size() > 3, "hash extern must have at least 4 arguments");
        auto typeArgs = new IR::Vector<IR::Type>({mce->typeArguments->at(2),
                                                  mce->typeArguments->at(1),
                                                  mce->typeArguments->at(3) });

        auto hashType = new IR::Type_Specialized(new IR::Type_Name("hash"), typeArgs);
        auto hashName = cstring::make_unique(structure->unique_names, "hash", '_');
        structure->unique_names.insert(hashName);
        structure->hashNames.emplace(node, hashName);

        auto typeName = mce->arguments->at(1)->clone()->to<IR::Member>();
        CHECK_NULL(typeName);
        structure->typeNamesToDo.emplace(typeName, typeName);
        LOG3("add " << typeName << " to translation map");
        auto hashArgs = new IR::Vector<IR::Expression>({ typeName });
        auto hashInst = new IR::Declaration_Instance(hashName, hashType, hashArgs);

        if (isIngress) {
            structure->ingressDeclarations.push_back(hashInst->to<IR::Declaration>());
        } else {
            structure->egressDeclarations.push_back(hashInst->to<IR::Declaration>());
        }
    }

    /// resubmit function is converted to an assignment on resubmit_idx
    void cvtResubmitFunction(const IR::MethodCallStatement* node) {
        /*
         * translate resubmit() function in ingress control block to
         *
         * ig_intr_md_for_dprsr.resubmit_idx = n;
         *
         */
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in resubmit() function");
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "resubmit() must be used in a control block");
        BUG_CHECK(control->name == structure->getBlockName("ingress"),
                  "resubmit() can only be used in ingress control");
        IR::PathExpression* path = new IR::PathExpression("ig_intr_md_for_deparser");
        auto mem = new IR::Member(path, "resubmit_idx");
        auto idx = new IR::Constant(IR::Type::Bits::get(3), resubmitIndex++);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->resubmitCalls.emplace(node, stmt);

        /*
         * In the ingress deparser, add the following code
         *
         * if (ig_intr_md_for_dprsr.resubmit_idx == n)
         *    resubmit.emit({fields});
         *
         */
        auto fl = mce->arguments->at(0);   // resubmit field list
        /// compiler inserts resubmit_idx as the format id to
        /// identify the resubmit group, it is 3 bits in size, but
        /// will be aligned to byte boundary in backend.
        auto new_fl = new IR::ListExpression({ mem });
        for (auto f : fl->to<IR::ListExpression>()->components)
            new_fl->push_back(f);
        auto args = new IR::Vector<IR::Expression>(new_fl);
        auto expr = new IR::PathExpression(new IR::Path("resubmit"));
        auto member = new IR::Member(expr, "emit");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                       new IR::MethodCallExpression(member, typeArgs, args));

        auto condExprPath = new IR::Member(
                new IR::PathExpression(new IR::Path("ig_intr_md_for_deparser")),
                "resubmit_idx");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        structure->ingressDeparserStatements.push_back(cond);
    }

    void cvtRandomFunction(const IR::MethodCallStatement* node) {
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "random() must be used in a control block");
        const bool isIngress = control->name == structure->getBlockName("ingress");
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "Malformed IR: method call expression cannot be nullptr");

        auto baseType = mce->arguments->at(0);
        auto typeArgs = new IR::Vector<IR::Type>({ baseType->type });
        auto type = new IR::Type_Specialized(new IR::Type_Name("random"), typeArgs);
        auto param = new IR::Vector<IR::Expression>();
        auto randName = cstring::make_unique(structure->unique_names, "random", '_');
        structure->unique_names.insert(randName);
        structure->randomNames.emplace(node, randName);

        auto randInst = new IR::Declaration_Instance(randName, type, param);

        if (isIngress) {
            structure->ingressDeclarations.push_back(randInst->to<IR::Declaration>());
        } else {
            structure->egressDeclarations.push_back(randInst->to<IR::Declaration>());
        }
    }

    const IR::Declaration_Instance* cvtVerifyChecksum(const IR::MethodCallExpression* ) {
        /// XXX(hanw): TBD
        return nullptr;
    }

    boost::optional<ChecksumSourceMap::value_type>
    analyzeComputedChecksumStatement(const IR::MethodCallStatement* statement) {
        auto methodCall = statement->methodCall->to<IR::MethodCallExpression>();
        if (!methodCall) {
            ::warning("Expected a non-empty method call expression: %1%", statement);
            return boost::none;
        }
        auto method = methodCall->method->to<IR::PathExpression>();
        if (!method || method->path->name != "update_checksum")  {
            ::warning("Expected an update_checksum statement in %1%", statement);
            return boost::none;
        }
        if (methodCall->arguments->size() != 4) {
            ::warning("Expected 4 arguments for update_checksum statement: %1%", statement);
            return boost::none;
        }
        auto destField = (*methodCall->arguments)[2]->to<IR::Member>();
        CHECK_NULL(destField);

        return ChecksumSourceMap::value_type(destField, methodCall);
    }

    void cvtUpdateChecksum(const IR::MethodCallStatement* method) {
        auto checksum = analyzeComputedChecksumStatement(method);
        if (checksum) {
            auto csum = *checksum;
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
            structure->ingressDeparserDeclarations.push_back(decl);
            structure->egressDeparserDeclarations.push_back(decl);

            auto fieldlist = csum.second->arguments->at(1);
            auto dest_field = csum.second->arguments->at(2);
            auto ig_csum = new IR::MethodCallStatement(csum.second->srcInfo,
                               new IR::Member(new IR::PathExpression(csum_name), "update"),
                                   {fieldlist, dest_field});
            auto eg_csum = new IR::MethodCallStatement(csum.second->srcInfo,
                               new IR::Member(new IR::PathExpression(csum_name), "update"),
                                   {fieldlist, dest_field});
            structure->ingressDeparserStatements.push_back(ig_csum);
            structure->egressDeparserStatements.push_back(eg_csum);
        }
    }

    /// build up a table for all metadata member that need to be translated.
    void postorder(const IR::Member* node) override {
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
                    if (gress->name == structure->getBlockName("ingress")) {
                        structure->pathsThread.emplace(node, INGRESS);
                        structure->pathsToDo.emplace(node, node);
                    } else if (gress->name == structure->getBlockName("egress")) {
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
            }}
    }

    void process_extern_declaration(const IR::Declaration_Instance* node, cstring name) {
        if (name == "counter") {
            structure->counters.emplace(node, node);
        } else if (name == "direct_counter") {
            structure->direct_counters.emplace(node, node);
        } else if (name == "meter") {
            structure->meters.emplace(node, node);
        } else if (name == "direct_meter") {
            structure->direct_meters.emplace(node, node);
        } else {
            WARNING("TypeName " << node << "is not converted");
        }
    }

    void postorder(const IR::Declaration_Instance* node) override {
        if (auto ts = node->type->to<IR::Type_Specialized>()) {
            if (auto typeName = ts->baseType->to<IR::Type_Name>()) {
                if (typeName->path->name == "V1Switch") {
                    BUG_CHECK(ts->arguments->size() == 2, "expect V1Switch with 2 type arguments");
                    auto type_h = ts->arguments->at(0)->to<IR::Type_Name>();
                    auto type_m = ts->arguments->at(1)->to<IR::Type_Name>();
                    structure->type_h = type_h->path->name;
                    structure->type_m = type_m->path->name;
                } else {
                    process_extern_declaration(node, typeName->path->name); } }
        } else if (auto typeName = node->type->to<IR::Type_Name>()) {
            process_extern_declaration(node, typeName->path->name);
        } else {
            WARNING("Declaration instance " << node << " is not converted");
        }
    }

    void postorder(const IR::MethodCallStatement* node) override {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "Malformed IR:: method call expression cannot be nullptr");
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto em = mi->to<P4::ExternMethod>()) {
            cstring name = em->actualExternType->name;
            if (name == "direct_meter") {
                structure->directMeterCalls.emplace(node, node);
            } else if (name == "meter") {
                structure->meterCalls.emplace(mce, mce);
            } else {
                WARNING("extern method " << name << " not converted");
            }
        } else if (auto ef = mi->to<P4::ExternFunction>()) {
            cstring name = ef->method->name;
            if (name == "hash") {
                cvtHashFunction(node);
                structure->hashCalls.emplace(node, node);
            } else if (name == "resubmit") {
                cvtResubmitFunction(node);
            } else if (name == "mark_to_drop" || name == "drop") {
                cvtDropFunction(node);
            } else if (name == "random") {
                cvtRandomFunction(node);
                structure->randomCalls.emplace(node, node);
            } else if (name == "digest") {
                cvtDigestFunction(node);
            } else if (name == "clone") {
                cvtCloneFunction(node, /* hasData = */ false);
            } else if (name == "clone3") {
                cvtCloneFunction(node, /* hasData = */ true);
            } else if (name == "update_checksum") {
                cvtUpdateChecksum(node);
            } else if (name == "verify_checksum") {
                // cvtVerifyChecksum(node);
                WARNING("verify_checksum is not converted");
            } else if (name == "execute_meter_with_color") {
                cvtExecuteMeterFunctiion(node);
            } else {
                WARNING("Unsupported extern function" << node);
            }
        } else if (mi->is<P4::BuiltInMethod>()) {
            WARNING("built-in method " << node << " is not converted");
        } else {
            WARNING("method call " << node << " not converted");
        }
    }

    // if a path refers to a global declaration, move
    // the global declaration to local control;
    void postorder(const IR::PathExpression* node) override {
        auto path = node->path;
        auto it = structure->global_instances.find(path->name);
        if (it != structure->global_instances.end()) {
            if (globals.find(path->name) != globals.end())
                return;
            auto control = findContext<IR::P4Control>();
            BUG_CHECK(control != nullptr,
                      "unable to reference global instance from non-control block");
            if (control->name == structure->getBlockName("ingress")) {
                structure->ingressDeclarations.push_back(it->second);
                globals.insert(path->name);
            } else if (control->name == structure->getBlockName("egress")) {
                structure->egressDeclarations.push_back(it->second);
                globals.insert(path->name);
            } else {
                BUG("unexpected reference to global instance from %1%", control->name);
            }
        }
    }

    // debug
    void postorder(const IR::P4Program* node) override {
        LOG3("program before translation " << node);
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////

class GenerateTofinoProgram : public Transform {
    ProgramStructure* structure;
 public:
    explicit GenerateTofinoProgram(ProgramStructure* structure)
    : structure(structure) { CHECK_NULL(structure); setName("GenerateTofinoProgram"); }
    //
    const IR::Node* preorder(IR::P4Program* program) override {
        prune();
        auto *rv = structure->create(program);
        return rv;
    }
};

/// The translation pass only renames intrinsic metadata. If the width of the
/// metadata is also changed after the translation, then this pass will insert
/// appropriate cast to the RHS of the assignment.
class CastFixup : public Transform {
    ProgramStructure* structure;

 public:
    explicit CastFixup(ProgramStructure* structure)
    : structure(structure) { CHECK_NULL(structure); setName("CastFixup"); }
    const IR::AssignmentStatement* postorder(IR::AssignmentStatement* node) override {
        auto left = node->left;
        auto right = node->right;

        if (auto mem = left->to<IR::Member>()) {
            if (auto path = mem->expr->to<IR::PathExpression>()) {
                MetadataField field{path->path->name, mem->member.name};
                auto it = structure->metadataTypeMap.find(field);
                if (it != structure->metadataTypeMap.end()) {
                    auto type = IR::Type::Bits::get(it->second);
                    if (type != right->type) {
                        right = new IR::Cast(type, right);
                        return new IR::AssignmentStatement(node->srcInfo, left, right);
                    }
                }
            }
        }
        return node;
    }
};

/// Add parser code to extract the standard TNA intrinsic metadata.
struct AddIntrinsicMetadata : public Transform {
    /// @return a parser state with a name that's distinct from the states in
    /// the P4 program and an `@name` annotation with a '$' prefix. Downstream,
    /// we search for certain '$' states and replace them with more generated
    /// parser code.
    static IR::ParserState*
    createGeneratedParserState(cstring name,
                               IR::IndexedVector<IR::StatOrDecl>&& statements,
                               const IR::Expression* selectExpression) {
        // XXX(seth): It'd be good to actually verify that this name is unique.
        auto newStateName = IR::ID(cstring("__") + name);
        auto* newState = new IR::ParserState(newStateName, statements,
                                             selectExpression);
        newState->annotations = newState->annotations
            ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                 new IR::StringLiteral(cstring("$") + name));
        return newState;
    }

    static IR::ParserState*
    createGeneratedParserState(cstring name,
                               IR::IndexedVector<IR::StatOrDecl>&& statements,
                               cstring nextState) {
        return createGeneratedParserState(name, std::move(statements),
                                          new IR::PathExpression(nextState));
    }

    /// @return a SelectCase that checks for a constant value with some mask
    /// applied.
    static IR::SelectCase*
    createSelectCase(unsigned bitWidth, unsigned value, unsigned mask,
                     const IR::ParserState* nextState) {
        auto* type = IR::Type::Bits::get(bitWidth);
        auto* valueExpr = new IR::Constant(type, value);
        auto* maskExpr = new IR::Constant(type, mask);
        auto* nextStateExpr = new IR::PathExpression(nextState->name);
        return new IR::SelectCase(new IR::Mask(valueExpr, maskExpr), nextStateExpr);
    }

    /// @return an `extract()` call that extracts the given header. The header is
    /// assumed to be one of the standard TNA metadata headers.
    static IR::Statement*
    createExtractCall(const IR::BFN::TranslatedP4Parser* parser, cstring header) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto headerParam = parser->tnaParams.at(header);
        auto* args = new IR::Vector<IR::Expression>({
            new IR::PathExpression(headerParam)
        });
        auto* callExpr = new IR::MethodCallExpression(method, args);
        return new IR::MethodCallStatement(callExpr);
    }

    /// @return a lookahead expression for the given size of `bit<>` type.
    static IR::Expression*
    createLookaheadExpr(const IR::BFN::TranslatedP4Parser* parser, int bits) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("lookahead"));
        auto* typeArgs = new IR::Vector<IR::Type>({
            IR::Type::Bits::get(bits)
        });
        auto* lookaheadExpr =
          new IR::MethodCallExpression(method, typeArgs,
                                       new IR::Vector<IR::Expression>);
        return lookaheadExpr;
    }

    /// @return an `advance()` call that advances by the given number of bits.
    static IR::Statement*
    createAdvanceCall(const IR::BFN::TranslatedP4Parser* parser, int bits) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto* method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("advance"));
        auto* args = new IR::Vector<IR::Expression>({
            new IR::Constant(IR::Type::Bits::get(32), bits)
        });
        auto* callExpr = new IR::MethodCallExpression(method, args);
        return new IR::MethodCallStatement(callExpr);
    }

    /// @return an assignment statement of the form `header.field = constant`.
    static IR::Statement*
    createSetMetadata(const IR::BFN::TranslatedP4Parser* parser, cstring header,
                      cstring field, int bitWidth, int constant) {
        auto headerParam = parser->tnaParams.at(header);
        auto* member = new IR::Member(new IR::PathExpression(headerParam),
                                      IR::ID(field));
        auto* value = new IR::Constant(IR::Type::Bits::get(bitWidth), constant);
        return new IR::AssignmentStatement(member, value);
    }

    /// Rename the start state of the given parser and return it. This will
    /// leave the parser without a start state, so the caller must create a new
    /// one.
    static const IR::ParserState*
    convertStartStateToNormalState(IR::P4Parser* parser, cstring newName) {
        auto* origStartState = parser->getDeclByName(IR::ParserState::start);
        auto origStartStateIt = std::find(parser->states.begin(),
                                          parser->states.end(),
                                          origStartState);
        BUG_CHECK(origStartStateIt != parser->states.end(),
                  "Couldn't find the original start state?");
        parser->states.erase(origStartStateIt);

        auto* newState = origStartState->to<IR::ParserState>()->clone();
        newState->name = IR::ID(cstring("__") + newName);
        newState->annotations = newState->annotations
            ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                 new IR::StringLiteral(IR::ParserState::start));
        parser->states.push_back(newState);

        return newState;
    }

    /// Add a new start state to the given parser, with a potentially
    /// non-'start' name applied via an `@name` annotation.
    static void addNewStartState(IR::P4Parser* parser, cstring name,
                                 cstring nextState) {
        auto* startState =
          new IR::ParserState(IR::ParserState::start,
                              new IR::PathExpression(nextState));
        startState->annotations = startState->annotations
            ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                 new IR::StringLiteral(cstring("$") + name));
        parser->states.push_back(startState);
    }

    /// Add the standard TNA ingress metadata to the given parser. The original
    /// start state will remain in the program, but with a new name.
    static void addIngressMetadata(IR::BFN::TranslatedP4Parser* parser) {
        auto* p4EntryPointState =
          convertStartStateToNormalState(parser, "ingress_p4_entry_point");

        // Add a state that skips over any padding between the phase 0 data and the
        // beginning of the packet.
        // XXX(seth): This "padding" is new in JBay, and it may contain actual data
        // rather than just padding. Once we have a chance to investigate what it
        // does, we'll want to revisit this.
        const auto bitSkip = Device::pardeSpec().bitIngressPrePacketPaddingSize();
        auto* skipToPacketState =
          createGeneratedParserState("skip_to_packet", {
              createAdvanceCall(parser, bitSkip)
          }, p4EntryPointState->name);
        parser->states.push_back(skipToPacketState);


        // Add a state that parses the phase 0 data. This is a placeholder that
        // just skips it; if we find a phase 0 table, it'll be replaced later.
        const auto bitPhase0Size = Device::pardeSpec().bitPhase0Size();
        auto* phase0State =
          createGeneratedParserState("phase0", {
              createAdvanceCall(parser, bitPhase0Size)
          }, skipToPacketState->name);
        parser->states.push_back(phase0State);

        // This state parses resubmit data. Just like phase 0, the version we're
        // generating here is a placeholder that just skips the data; we'll replace
        // it later with an actual implementation.
        const auto bitResubmitSize = Device::pardeSpec().bitResubmitSize();
        auto* resubmitState =
          createGeneratedParserState("resubmit", {
              createAdvanceCall(parser, bitResubmitSize)
          }, skipToPacketState->name);
        parser->states.push_back(resubmitState);

        // If this is a resubmitted packet, the initial intrinsic metadata will be
        // followed by the resubmit data; otherwise, it's followed by the phase 0
        // data. This state checks the resubmit flag and branches accordingly.
        auto igIntrMd = parser->tnaParams.at("ig_intr_md");
        IR::Vector<IR::Expression> selectOn = {
            new IR::Cast(IR::Type::Bits::get(8),
                         new IR::Member(new IR::PathExpression(igIntrMd),
                                        "resubmit_flag"))
        };
        auto* checkResubmitState =
          createGeneratedParserState("check_resubmit", { },
            new IR::SelectExpression(new IR::ListExpression(selectOn), {
              createSelectCase(8, 0, 0x80, phase0State),
              createSelectCase(8, 0x80, 0x80, resubmitState)
            }));
        parser->states.push_back(checkResubmitState);

        // This state handles the extraction of ingress intrinsic metadata.
        auto* igMetadataState =
          createGeneratedParserState("ingress_metadata", {
              createSetMetadata(parser, "ig_intr_md_from_prsr", "ingress_parser_err", 16, 0),
              createExtractCall(parser, "ig_intr_md")
          }, checkResubmitState->name);
        parser->states.push_back(igMetadataState);

        addNewStartState(parser, "ingress_tna_entry_point", igMetadataState->name);
    }

    /// Add the standard TNA egress metadata to the given parser. The original
    /// start state will remain in the program, but with a new name.
    static void addEgressMetadata(IR::BFN::TranslatedP4Parser* parser) {
        auto* p4EntryPointState =
          convertStartStateToNormalState(parser, "egress_p4_entry_point");

        // Add a state that parses bridged metadata. This is just a placeholder;
        // we'll replace it once we know which metadata need to be bridged.
        auto* bridgedMetadataState =
          createGeneratedParserState("bridged_metadata", { }, p4EntryPointState->name);
        parser->states.push_back(bridgedMetadataState);

        // Similarly, this state is a placeholder which will eventually hold the
        // parser for mirrored data.
        auto* mirroredState =
          createGeneratedParserState("mirrored", { }, p4EntryPointState->name);
        parser->states.push_back(mirroredState);

        // If this is a mirrored packet, the hardware will have prepended the
        // contents of the mirror buffer to the actual packet data. To detect this
        // data, we add a byte to the beginning of the mirror buffer that contains a
        // flag indicating that it's a mirrored packet. We can use this flag to
        // distinguish a mirrored packet from a normal packet because we always
        // begin the bridged metadata we attach to normal packet with an extra byte
        // which has the mirror indicator flag set to zero.
        IR::Vector<IR::Expression> selectOn = { createLookaheadExpr(parser, 8) };
        auto* checkMirroredState =
          createGeneratedParserState("check_mirrored", { },
            new IR::SelectExpression(new IR::ListExpression(selectOn), {
              createSelectCase(8, 0, 1 << 3, bridgedMetadataState),
              createSelectCase(8, 1 << 3, 1 << 3, mirroredState)
            }));
        parser->states.push_back(checkMirroredState);

        // This state handles the extraction of egress intrinsic metadata.
        // XXX(seth): We can't easily do it without making
        // `packet_in.lookahead()` a little more flexible, but a correct
        // implementation should take the EPB configuration into account. It
        // should look more like this:
#if 0
        const auto epbConfig = Device::pardeSpec().defaultEPBConfig();
        const auto egMetadataPacking =
          Device::pardeSpec().egressMetadataLayout(epbConfig, egMeta);
        auto* egMetadataState =
          egMetadataPacking.createP4ExtractionState("$egress_metadata",
                                                    checkMirroredState);
#endif

        auto* egMetadataState =
          createGeneratedParserState("egress_metadata", {
              createSetMetadata(parser, "eg_intr_md_from_prsr", "egress_parser_err", 16, 0),
              createSetMetadata(parser, "eg_intr_md_from_prsr", "coalesce_sample_count", 8, 0),
              createExtractCall(parser, "eg_intr_md")
          }, checkMirroredState->name);
        parser->states.push_back(egMetadataState);

        addNewStartState(parser, "egress_tna_entry_point", egMetadataState->name);
    }

    IR::BFN::TranslatedP4Parser* preorder(IR::BFN::TranslatedP4Parser* parser) override {
        prune();

        if (parser->thread == INGRESS)
            addIngressMetadata(parser);
        else
            addEgressMetadata(parser);

        return parser;
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
    auto structure = new BFN::ProgramStructure;
    addPasses({
        new RemoveExternMethodCallsExcludedByAnnotation,
        new NormalizeV1modelProgram(),
        evaluator,
        new VisitFunctor([structure, evaluator]() {
            structure->toplevel = evaluator->getToplevelBlock(); }),
        new TranslationFirst(),
        new LoadTargetArchitecture(structure),
        new RemoveNodesWithNoMapping(),
        new AnalyzeV1modelProgram(structure),
        new ConstructSymbolTable(structure, refMap, typeMap),
        new GenerateTofinoProgram(structure),
        new CastFixup(structure),
        new AddIntrinsicMetadata,
        new P4::ClonePathExpressions,
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
        new BFN::RemoveSetMetadata(refMap, typeMap),
        new BFN::TranslatePhase0(refMap, typeMap),
        new P4::ClonePathExpressions,
        new TranslationLast(),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
