#include "simple_switch.h"

#include <set>

namespace BFN {

//////////////////////////////////////////////////////////////////////////////////////////////

/// When compiling a tofino-v1model program, the compiler by default
/// includes tofino/intrinsic_metadata.p4 and v1model.p4 from the
/// system path. Symbols in these system header files are reserved and
/// cannot be used in user programs.
class ReplaceArchitecture : public Inspector {
    ProgramStructure* structure;
    Target            target;

    // reservedNames is used to filter out system defined types.
    std::set<cstring>* reservedNames;
    IR::IndexedVector<IR::Node> localDeclarations;

 public:
    ReplaceArchitecture(ProgramStructure* structure, Target arch)
        : structure(structure) {
        setName("ReplaceArchitecture");
        CHECK_NULL(structure);
        reservedNames = new std::set<cstring>();
        target = arch;
    }

    template<typename T>
    void setReservedName(const IR::Node* node, cstring prefix = cstring()) {
        if (auto type = node->to<T>()) {
            auto name = type->name.name;
            if (prefix)
                name = prefix + "$" + name;
            reservedNames->insert(name); } }

    void processArchTypes(const IR::Node *node) {
        if (node->is<IR::Type_Error>()) {
            for (auto err : node->to<IR::Type_Error>()->members) {
                setReservedName<IR::Declaration_ID>(err, "error"); }
            return; }
        if (node->is<IR::Type_Declaration>())
            setReservedName<IR::Type_Declaration>(node);
        else if (node->is<IR::P4Action>())
            setReservedName<IR::P4Action>(node);
        else if (node->is<IR::Method>())
            setReservedName<IR::Method>(node);
        else if (node->is<IR::Declaration_MatchKind>())
            for (auto member : node->to<IR::Declaration_MatchKind>()->members)
                setReservedName<IR::Declaration_ID>(member);
        else
            ::error("Unhandled declaration type %1%", node);

        /// store metadata defined in system header in program structure,
        /// they are used for control block parameter translation
        if (node->is<IR::Type_Struct>()) {
            cstring name = node->to<IR::Type_Struct>()->name;
            structure->system_metadata.emplace(name, node);
        } else if (node->is<IR::Type_Header>()) {
            cstring name = node->to<IR::Type_Header>()->name;
            structure->system_metadata.emplace(name, node); } }

    /// Helper function to decide if the type of IR::Node is a system defined type.
    template<typename T>
    bool isSystemType(const IR::Node* t, cstring prefix = cstring()) {
        if (auto type = t->to<T>()) {
            auto name = type->name.name;
            if (prefix)
                name = prefix + "$" + name;
            auto it = reservedNames->find(name);
            return it != reservedNames->end(); }
        return false;
    }

    const IR::Node* filterV1modelArch(const IR::Node *node) {
        bool filter = false;
        if (node->is<IR::Type_Error>())
            filter = true;
        else if (node->is<IR::Type_Declaration>())
            filter = isSystemType<IR::Type_Declaration>(node);
        else if (node->is<IR::P4Action>())
            filter = isSystemType<IR::P4Action>(node);
        else if (node->is<IR::Method>())
            filter = isSystemType<IR::Method>(node);
        else if (node->is<IR::Declaration_MatchKind>())
            filter = true;
        if (filter)
            return nullptr;
        return node;
    }

    /**
     * This function populates the mapping table from v1model extern
     * to tofino extern.
     *
     * externs in tofino.p4 that do not exist in v1model
     * idle_timeout
     * parser_counter
     * priority
     * lpf
     * wred
     * stateful_param
     * stateful_alu
     * recirculate_raw
     *
     * externs that are not supported in tofino
     * truncate
     *
     * externs that are not mapped to extern in tofino
     * mark_to_drop
     */
    void populateExternMapping() {
        structure->externNameMap.emplace("action_profile", "action_profile");
        structure->externNameMap.emplace("action_selector", "action_selector");
        structure->externNameMap.emplace("clone", "mirror_packet");
        structure->externNameMap.emplace("clone3", "mirror_packet");
        structure->externNameMap.emplace("counter", "counter");
        structure->externNameMap.emplace("direct_counter", "counter");
        structure->externNameMap.emplace("direct_meter", "meter");
        structure->externNameMap.emplace("digest", "learn_filter_packet");
        structure->externNameMap.emplace("hash", "hash");
        structure->externNameMap.emplace("meter", "meter");
        structure->externNameMap.emplace("random", "random");
        structure->externNameMap.emplace("register", "register");
        structure->externNameMap.emplace("resubmit", "resubmit_packet");
        structure->externNameMap.emplace("update_checksum", "checksum");
        structure->externNameMap.emplace("value_set", "value_set");
        structure->externNameMap.emplace("verify_checksum", "checksum");
    }

    void populateMetadataMapping() {
        structure->metadataMap.emplace(std::make_pair("standard_metadata", "egress_spec"),
                                       std::make_pair("ig_intr_md_for_tm", "ucast_egress_port"));
        structure->metadataMap.emplace(std::make_pair("standard_metadata", "ingress_port"),
                                       std::make_pair("ig_intr_md", "ingress_port"));
        structure->metadataMap.emplace(std::make_pair("standard_metadata", "egress_port"),
                                       std::make_pair("eg_intr_md", "egress_port"));
        LOG3("populate metadata map with size " << structure->metadataMap.size());
    }

    void analyzeErrors(const IR::P4Program* program) {
        for (auto decl : structure->tofinoArchTypes) {
            if (auto err = decl->to<IR::Type_Error>()) {
                for (auto m : err->members)
                    structure->errors.emplace(m->name); }}
        /// append error defined in user program
        for (auto decl : program->declarations) {
            if (auto err = decl->to<IR::Type_Error>()) {
                for (auto m : err->members)
                    structure->errors.emplace(m->name); }}
    }

    void analyzeTofinoModel() {
        for (auto decl : structure->tofinoArchTypes) {
            if (auto v = decl->to<IR::Type_Extern>()) {
                structure->extern_types.emplace(v->name, v);
            } else if (decl->is<IR::P4Action>()) {
            } else if (auto v = decl->to<IR::Type_MatchKind>()) {
            } else if (auto v = decl->to<IR::Type_Typedef>()) {
                structure->typedefs.emplace(v->name, v);
            } else if (auto v = decl->to<IR::Type_Enum>()) {
                structure->enums.emplace(v->name, v);
            } else if (auto v = decl->to<IR::Type_Struct>()) {
            } else if (auto v = decl->to<IR::Type_Control>()) {
            } else if (auto v = decl->to<IR::Type_Parser>()) {
            } else if (auto v = decl->to<IR::Type_Package>()) {
            } else {
                WARNING("Cannot recognize architecture definition " << decl);
            }
        }
    }

    void postorder(const IR::P4Program* program) override {
        IR::IndexedVector<IR::Node> baseArchTypes;
        IR::IndexedVector<IR::Node> libArchTypes;

        if (target == Target::Simple) {
            structure->include("v1model.p4", &baseArchTypes);
            structure->include("tofino/stateful_alu.p4", &libArchTypes);
            structure->include14("tofino/intrinsic_metadata.p4", &libArchTypes);
            structure->include14("tofino/pktgen_headers.p4", &libArchTypes);
        }
        /// populate reservedNames from arch.p4 and include system headers
        for (auto node : baseArchTypes) {
            processArchTypes(node); }
        for (auto node : libArchTypes) {
            processArchTypes(node); }
        // Debug only
        for (auto name : *reservedNames) {
            LOG3("Reserved: " << name); }
        populateExternMapping();
        populateMetadataMapping();

        /// append tofino.p4 architecture definition
        structure->include("tofino/v1model.p4", &structure->tofinoArchTypes);
        structure->include("tofino/p4_14_prim.p4", &structure->tofinoArchTypes);
        analyzeErrors(program);
        analyzeTofinoModel();
        /// append program without v1model declarations
        for (auto node : program->declarations) {
            if (auto decl = filterV1modelArch(node)) {
                structure->user_program.push_back(decl);
            }
        }
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
                                 new IR::Constant(new IR::Type_Bits(3, false), 3));
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

// clean up p14 v1model
class CleanP14V1model : public Transform {
    // following fields are showing up in struct H, because in P4-14
    // these structs are declared as header type.
    // In TNA, most of these metadata are individual parameter to
    // the control block, and shall be removed from struct H.
    // XXX(hanw): these hard-coded name should be auto-generated from include files.
    std::set<cstring> structToRemove = {
            "generator_metadata_t_0",
            "ingress_parser_control_signals",
            "pktgen_generic_header_t",
            "pktgen_port_down_header_t",
            "pktgen_recirc_header_t",
            "pktgen_timer_header_t",
            "standard_metadata_t",
            "egress_intrinsic_metadata_t",
            "egress_intrinsic_metadata_for_mirror_buffer_t",
            "egress_intrinsic_metadata_for_output_port_t",
            "egress_intrinsic_metadata_from_parser_aux_t",
            "ingress_intrinsic_metadata_t",
            "ingress_intrinsic_metadata_for_mirror_buffer_t",
            "ingress_intrinsic_metadata_for_tm_t",
            "ingress_intrinsic_metadata_from_parser_aux_t"};

 public:
    CleanP14V1model() { setName("CleanP14V1model"); }

    const IR::Node* preorder(IR::Type_Header* node) {
        auto it = structToRemove.find(node->name);
        if (it != structToRemove.end()) {
            return nullptr; }
        return node; }

    const IR::Node* preorder(IR::StructField* node) {
        auto header = findContext<IR::Type_Struct>();
        if (!header) return node;
        if (header->name != "headers") return node;

        auto type = node->type->to<IR::Type_Name>();
        if (!type) return node;

        auto it = structToRemove.find(type->path->name);
        if (it != structToRemove.end())
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
        auto it = structToRemove.find(submemType->name);
        if (it == structToRemove.end()) return mem;

        auto newType = new IR::Type_Name(submemType->name);
        auto newName = new IR::Path(submem->member);
        auto newExpr = new IR::PathExpression(newType, newName);
        auto newMem = new IR::Member(mem->srcInfo, mem->type, newExpr, mem->member);
        return newMem; }
};

//////////////////////////////////////////////////////////////////////////////////////////////


/// This pass collects all top level p4program declarations.
class AnalyzeV1modelProgram : public Inspector {
    ProgramStructure* structure;

    template<class P4Type, class BlockType>
    const P4Type* getBlock(const IR::ToplevelBlock* blk, cstring name) {
        auto main = blk->getMain();
        auto ctrl = main->findParameterValue(name);
        if (ctrl == nullptr)
            return nullptr;
        if (!ctrl->is<BlockType>()) {
            ::error("%1%: main package  match the expected model", main);
            return nullptr;
        }
        return ctrl->to<BlockType>()->container;
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
    // typeDeclarations
    void postorder(const IR::Type_Struct* node) override
    { structure->struct_types.emplace(node->name, node); }
    void postorder(const IR::Type_Header* node) override
    { structure->header_types.emplace(node->name, node); }
    void postorder(const IR::Type_Enum* node) override
    { structure->enums.emplace(node->name, node); }

    // *** program only declarations ***
    // instantiation - parser
    void postorder(const IR::P4Parser* node) override {
        structure->parsers.emplace(node->name, node);
        // additional info for translation
        structure->user_metadata = node->type->applyParams->parameters.at(2);
    }
    // instantiation - control
    void postorder(const IR::P4Control* node) override
    { structure->controls.emplace(node->name, node); }
    // instantiation - extern
    // instantiation - package

    void postorder(const IR::P4Program*) override {
        auto ingress = getBlock<IR::P4Control, IR::ControlBlock>(structure->toplevel, "ig");
        CHECK_NULL(ingress);
        structure->ingress_name = ingress->name;
        auto egress = getBlock<IR::P4Control, IR::ControlBlock>(structure->toplevel, "eg");
        CHECK_NULL(egress);
        structure->egress_name = egress->name;
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
    P4::ClonePathExpressions cloner;

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
        BUG_CHECK(control->name == structure->ingress_name,
                  "digest() can only be used in %1%", structure->ingress_name);
        IR::PathExpression* path = new IR::PathExpression("ig_intr_md_for_deparser");
        auto mem = new IR::Member(path, "learn_idx");
        auto idx = new IR::Constant(new IR::Type_Bits(3, false), digestIndex++);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->resubmitCalls.emplace(node, stmt);

        /*
         * In the ingress deparser, add the following code
         *
         * if (ig_intr_md_for_dprsr.digest_idx == n)
         *    learn.add_metadata({fields});
         *
         */
        auto field_list = mce->arguments->at(0);
        auto cloned_field_list = field_list->apply(cloner);
        auto args = new IR::Vector<IR::Expression>({ cloned_field_list });
        auto expr = new IR::PathExpression(new IR::Path("resubmit"));
        auto member = new IR::Member(expr, "add_metadata");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
                       new IR::MethodCallExpression(member, typeArgs, args));

        auto condExprPath = new IR::Member(
             new IR::PathExpression(new IR::Path("ig_intr_md_for_deparser")), "learn_idx");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        structure->ingressDeparserStatements.push_back(cond);
    }

    void cvtCloneFunction(const IR::MethodCallStatement* node, bool hasData) {
        auto mce = node->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(mce != nullptr, "malformed IR in clone() function");
        auto control = findContext<IR::P4Control>();
        BUG_CHECK(control != nullptr, "clone() must be used in a control block");
        auto path = new IR::PathExpression((control->name == "ingress") ?
             "ig_intr_md_for_deparser" : "eg_intr_md_for_deparser");
        auto mem = new IR::Member(path, "mirror_idx");
        auto idx = new IR::Constant(new IR::Type_Bits(3, false),
             (control->name == "ingress") ? igCloneIndex++ : egCloneIndex++);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->cloneCalls.emplace(node, stmt);

        /*
         * generate statement in ingress/egress deparser to prepend mirror metadata
         * if (ig_intr_md_for_dprsr.mirror_idx == N)
         *    mirror.add_metadata({});
         */

        auto pathExpr = new IR::PathExpression(new IR::Path("mirror"));
        auto args = new IR::Vector<IR::Expression>();
        if (hasData) {
            auto nargs = mce->arguments->size();
            if (nargs > 2) {
                auto field_list = mce->arguments->at(2);
                auto cloned_field_list = field_list->apply(cloner);
                args->push_back(cloned_field_list);
            }
        } else {
            args->push_back(new IR::ListExpression({}));
        }
        auto member = new IR::Member(pathExpr, "add_metadata");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mcs = new IR::MethodCallStatement(
             new IR::MethodCallExpression(member, typeArgs, args));
        auto condExprPath = new IR::Member(
                new IR::PathExpression(control->name == "ingress" ?
                    "ig_intr_md_for_deparser" : "eg_intr_md_for_deparser"),
                "mirror_idx");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        if (control->name == "ingress")
            structure->ingressDeparserStatements.push_back(cond);
        else
            structure->egressDeparserStatements.push_back(cond);
    }

    void cvtDropFunction(const IR::MethodCallStatement* node) {
        auto control = findContext<IR::P4Control>();
        if (control->name == "ingress") {
            auto path = new IR::Member(
                            new IR::PathExpression("ig_intr_md_for_tm"), "drop_ctl");
            auto val = new IR::Constant(new IR::Type_Bits(3, false), 1);
            auto stmt = new IR::AssignmentStatement(path, val);
            structure->dropCalls.emplace(node, stmt);
        } else if (control->name == "egress") {
            auto path = new IR::Member(
                            new IR::PathExpression("eg_intr_md_for_oport"), "drop_ctl");
            auto val = new IR::Constant(new IR::Type_Bits(3, false), 1);
            auto stmt = new IR::AssignmentStatement(path, val);
            structure->dropCalls.emplace(node, stmt);
        } else {
            BUG("mark_to_drop() can only be used in ingress or egress");
        }
    }

    /// hash function is converted to an instance of hash extern in the enclosed control block
    void cvtHashFunction(const IR::MethodCallStatement* node) {
        auto control = findContext<IR::P4Control>();
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

        if (control->name == "ingress") {
            structure->ingressDeclarations.push_back(hashInst->to<IR::Declaration>());
        } else if (control->name == "egress") {
            structure->egressDeclarations.push_back(hashInst->to<IR::Declaration>());
        } else {
            BUG("hash must be used in either ingress or egress pipeline");
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
        BUG_CHECK(control->name == "ingress",
                  "resubmit() can only be used in ingress control");
        IR::PathExpression* path = new IR::PathExpression("ig_intr_md_for_deparser");
        auto mem = new IR::Member(path, "resubmit_idx");
        auto idx = new IR::Constant(new IR::Type_Bits(3, false), resubmitIndex++);
        auto stmt = new IR::AssignmentStatement(mem, idx);
        structure->resubmitCalls.emplace(node, stmt);

        /*
         * In the ingress deparser, add the following code
         *
         * if (ig_intr_md_for_dprsr.resubmit_idx == n)
         *    resubmit.add_metadata({fields});
         *
         */
        auto field_list = mce->arguments->at(0);
        auto cloned_field_list = field_list->apply(cloner);
        auto args = new IR::Vector<IR::Expression>({ cloned_field_list });
        auto expr = new IR::PathExpression(new IR::Path("resubmit"));
        auto member = new IR::Member(expr, "add_metadata");
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

        if (control->name == "ingress") {
            structure->ingressDeclarations.push_back(randInst->to<IR::Declaration>());
        } else if (control->name == "egress") {
            structure->egressDeclarations.push_back(randInst->to<IR::Declaration>());
        } else {
            BUG("random() must be used in either ingress or egress pipeline");
        }
    }

    const IR::Declaration_Instance* cvtVerifyChecksum(const IR::MethodCallExpression* ) {
        /// XXX(hanw): TBD
        return nullptr;
    }

    boost::optional<ChecksumSourceMap::value_type>
    analyzeComputedChecksumStatement(const IR::MethodCallStatement* statement) {
        auto methodCall = statement->methodCall->to<IR::MethodCallExpression>();
        methodCall = methodCall->apply(cloner)->to<IR::MethodCallExpression>();
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
            auto ig_fieldlist = fieldlist->apply(cloner);
            auto eg_fieldlist = fieldlist->apply(cloner);
            auto dest_field = csum.second->arguments->at(2);
            auto ig_dest_field = dest_field->apply(cloner);
            auto eg_dest_field = dest_field->apply(cloner);
            auto ig_csum = new IR::MethodCallStatement(csum.second->srcInfo,
                               new IR::Member(new IR::PathExpression(csum_name), "update"),
                                   {ig_fieldlist, ig_dest_field});
            auto eg_csum = new IR::MethodCallStatement(csum.second->srcInfo,
                               new IR::Member(new IR::PathExpression(csum_name), "update"),
                                   {eg_fieldlist, eg_dest_field});
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
                    gress_t thread;
                    // print ingress/egress name on non-ingress/egress block return false
                    // see gress.cpp
                    auto isIngressEgress = (gress->name >> thread);
                    if (!isIngressEgress) {
                        WARNING("path " << node << " in " << thread << " is not translated");
                        return;
                    }
                    structure->pathsToDo.emplace(node, node);
                    structure->pathsThread.emplace(node, thread);
                }
            } else if (auto expr = node->expr->to<IR::TypeNameExpression>()) {
                auto tn = expr->typeName->to<IR::Type_Name>();
                CHECK_NULL(tn);
                structure->typeNamesToDo.emplace(node, node);
            } else {
                WARNING("Unable to translate path " << node);
            }
        }
        auto parser = findContext<IR::P4Parser>();
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
                } else {
                    WARNING("metadata " << expr << " is not converted");
                }}}
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
            } else if (name == "mark_to_drop") {
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
            } else {
                // need to handle verify_checksum
                WARNING("extern function " << node << " is not converted");
            }
        } else if (auto bi = mi->to<P4::BuiltInMethod>()) {
            WARNING("built-in method " << node << " is not converted");
        } else {
            WARNING("method call " << node << " not converted");
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
    BFN::Target target = BFN::Target::Unknown;
    if (options.arch == "v1model")
        target = BFN::Target::Simple;
    else if (options.arch == "native")
        target = BFN::Target::Tofino;  // XXX(zma) : assuming tofino & jbay have same arch for now
    addDebugHook(options.getDebugHook());
    auto evaluator = new P4::EvaluatorPass(refMap, typeMap);
    auto structure = new BFN::ProgramStructure;
    addPasses({
        evaluator,
        new VisitFunctor([structure, evaluator]() {
            structure->toplevel = evaluator->getToplevelBlock(); }),
        new ReplaceArchitecture(structure, target),
        new CleanP14V1model(),
        new AnalyzeV1modelProgram(structure),
        new ConstructSymbolTable(structure, refMap, typeMap),
        new GenerateTofinoProgram(structure),
        new TranslationLast(),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, true),
    });
}

}  // namespace BFN
