/*
  Copyright 2013-present Barefoot Networks, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

#include "simple_switch.h"
#include <boost/optional.hpp>
#include "lib/path.h"
#include "ir/ir.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/common/options.h"
#include "frontends/p4/createBuiltins.h"
#include "p4/typeChecking/typeChecker.h"

namespace Tofino {

/// When compiling a tofino-v1model program, the compiler by default
/// includes tofino/intrinsic_metadata.p4 and v1model.p4 from the
/// system path. Symbols in these system header files are reserved and
/// cannot be used in user programs.
/// @input: User P4 program with source architecture type declarations.
/// @output: User P4 program w/o source architecture type declarations.
class RemoveUserArchitecture : public Transform {
    cstring target;
    ProgramStructure* structure;
    // reservedNames is used to filter out system defined types.
    std::set<cstring>* reservedNames;
    IR::IndexedVector<IR::Node>* programDeclarations;

 public:
    explicit RemoveUserArchitecture(ProgramStructure* structure, const Tofino_Options* options)
        : structure(structure) {
        setName("RemoveUserArchitecture");
        CHECK_NULL(structure); CHECK_NULL(options);
        target = options->target;
        reservedNames = new std::set<cstring>();
        programDeclarations = new IR::IndexedVector<IR::Node>();
    }

    template<typename T>
    void setReservedName(const IR::Node* node) {
        if (auto type = node->to<T>()) {
            reservedNames->insert(type->name);
        }
    }

    void processArchTypes(const IR::Node *node) {
        if (node->is<IR::Type_Declaration>())
            setReservedName<IR::Type_Declaration>(node);
        else if (node->is<IR::P4Action>())
            setReservedName<IR::Type_Declaration>(node);
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
            structure->system_metadata.emplace(name, node);
        }
    }

    /// Helper function to decide if the type of IR::Node is a system defined type.
    template<typename T>
    bool isSystemType(const IR::Node* t) {
        if (auto type = t->to<T>()) {
            cstring name = type->name;
            auto it = reservedNames->find(name);
            return it != reservedNames->end();
        }
        return false;
    }

    void filterArchDecls(const IR::Node *node) {
        bool filter = false;
        if (node->is<IR::Type_Declaration>())
            filter = isSystemType<IR::Type_Declaration>(node);
        else if (node->is<IR::P4Action>())
            filter = isSystemType<IR::P4Action>(node);
        else if (node->is<IR::Method>())
            filter = isSystemType<IR::Method>(node);
        else if (node->is<IR::Declaration_MatchKind>())
            filter = true;
        if (!filter)
            programDeclarations->push_back(node);
    }

    const IR::Node* postorder(IR::P4Program* program) override {
        IR::IndexedVector<IR::Node> baseArchTypes;
        IR::IndexedVector<IR::Node> libArchTypes;

        if (target == "tofino-v1model-barefoot") {
            structure->include("v1model.p4", &baseArchTypes);
            structure->include14("tofino/intrinsic_metadata.p4", &libArchTypes);
        } else {
            ::error("Unsupported target %1%", target);
        }
        /// populate reservedNames from arch.p4 and include system headers
        for (auto node : baseArchTypes) {
            processArchTypes(node);
        }
        for (auto node : libArchTypes) {
            processArchTypes(node);
        }
        // Debug only
        for (auto name : *reservedNames) {
            LOG3("Reserved: " << name);
        }
        /// filter system type declarations from pre-processed user programs
        for (auto node : program->declarations) {
            filterArchDecls(node);
        }
        return new IR::P4Program(program->srcInfo, *programDeclarations);
    }
};

// remap standard metadata to tofino-specific intrinsic metadata
class RemapStandardMetadata : public Modifier {
    std::map<std::pair<cstring, cstring>, std::pair<cstring, cstring>> remap;

 public:
    RemapStandardMetadata() {
        setName("RemapStandardMetadata");
        remap = {
            { { "standard_metadata", "ingress_port" }, { "ig_intr_md", "ingress_port" } },
            { { "standard_metadata", "resubmit_flag" }, { "ig_intr_md", "resubmit_flag" } },
            { { "standard_metadata", "egress_spec" },
                { "ig_intr_md_for_tm", "ucast_egress_port" } },
            { { "standard_metadata", "egress_port" }, { "eg_intr_md", "egress_port" } },
            // remap more standard_metadata
        };
    }

    bool preorder(IR::Member* mem) {
        auto submem = mem->expr->to<IR::Member>();
        std::pair<cstring, cstring> mname(submem ? submem->member.name : mem->expr->toString(),
                mem->member);
        if (remap.count(mname) == 0) return false;

        auto& to = remap.at(mname);
        LOG3("remap " << mname.first << '.' << mname.second << " -> " <<
                to.first << '.' << to.second);
        mem->member = to.second;
        if (submem)
            mem->expr = new IR::Member(submem->srcInfo, submem->expr, to.first);
        else
            mem->expr = new IR::PathExpression(to.first);
        LOG5("not remapping " << mname.first << '.' << mname.second);
        return false;
    }
};

class RemoveIntrinsicMetadata : public Transform {
    // following fields are showing up in struct H, because in P4-14
    // these structs are declared as header type.
    // In TNA, most of these metadata are individual parameter to
    // the control block, and shall be removed from struct H.
    std::set<cstring> structToRemove = {
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

 public:
    RemoveIntrinsicMetadata() { setName("RemoveIntrinsicMetadata"); }
    const IR::Node* preorder(IR::StructField* node) {
        auto header = findContext<IR::Type_Struct>();
        if (!header) return node;

        if (header->name == "headers") {
            auto type = node->type->to<IR::Type_Name>();
            if (!type) return node;

            auto it = structToRemove.find(type->path->name);
            if (it != structToRemove.end())
                return nullptr;
        }
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
        return newMem;
    }
};

class DiscoverProgramStructure : public Inspector {
    ProgramStructure* structure;
 public:
    explicit DiscoverProgramStructure(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); setName("DiscoverProgramStructure"); }

    void postorder(const IR::P4Control* node) override
    { structure->controls.push_back(node); }
    void postorder(const IR::P4Parser* node) override
    { structure->parsers.push_back(node); }
    void postorder(const IR::Type_Header* node) override
    { structure->headers.push_back(node); }
    void postorder(const IR::Type_Struct* node) override
    { structure->structs.push_back(node); }
    void postorder(const IR::Declaration_Instance* node) override
    { structure->declaration_instances.push_back(node); }
    // XXX(hanw): no user-defined extern type?
    void postorder(const IR::Type_Extern* node) override
    { structure->externs.push_back(node); }
    // XXX(hanw): may need more?
};

class TranslateSimpleSwitch : public Transform {
    ProgramStructure* structure;
 public:
    explicit TranslateSimpleSwitch(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); setName("TranslateSimpleSwitch"); }

    const IR::Node* postorder(IR::P4Program* program) override {
        auto rv = structure->translate(program->srcInfo);
        if (LOGGING(4)) {
            LOG4("### Generated P4-16 Tofino Program");
            dump(rv);
        }
        return rv;
    }
};

class AppendSystemArchitecture : public Transform {
    ProgramStructure* structure;
    std::set<IR::Type*> insertedType;

 public:
    explicit AppendSystemArchitecture(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); setName("AppendSystemArchitecture"); }

    const IR::Node* postorder(IR::P4Program* program) override {
        structure->include("tofino.p4", structure->tofinoArchTypes);
        IR::IndexedVector<IR::Node> program_declarations;
        program_declarations.append(*structure->tofinoArchTypes);
        program_declarations.append(program->declarations);
        return new IR::P4Program(program->srcInfo, program_declarations);
    }
};

class TranslationLast : public PassManager {
 public:
    TranslationLast() { setName("TranslationLast"); }
};

// simple switch to tofino converter
SimpleSwitchTranslator::SimpleSwitchTranslator(const Tofino_Options* options) {
    setName("SimpleSwitchTranslator");
    passes.emplace_back(new RemoveUserArchitecture(structure, options));
    passes.emplace_back(new RemapStandardMetadata);
    passes.emplace_back(new RemoveIntrinsicMetadata);
    passes.emplace_back(new DiscoverProgramStructure(structure));
    passes.emplace_back(new TranslateSimpleSwitch(structure));
    passes.emplace_back(new AppendSystemArchitecture(structure));
    passes.emplace_back(new TranslationLast());
}

const IR::P4Program*
translateSimpleSwitch(const IR::P4Program* program, const Tofino_Options* options,
                      boost::optional<DebugHook> debugHook = boost::none) {
    SimpleSwitchTranslator translator(options);
    if (debugHook) translator.addDebugHook(*debugHook);
    CHECK_NULL(program);
    return program->apply(translator);
}

void
ConvertControl::translateParam(const IR::Parameter* param, cstring name,
                               IR::ParameterList* apply_params) {
    auto param_name = param->type->to<IR::Type_Name>()->path->name;
    if (name == "ingress") {
        // XXX(hanw): this should be implemented as an generic mechanism from source parameter list
        // to target parameter list, based on mapping provided by the compiler backend.
        // for now, we does the mapping manually.
        if (param_name == "standard_metadata_t") {
            // add ingress_intrinsic_metadata_t
            auto metapath = new IR::Path("ingress_intrinsic_metadata_t");
            auto metatype = new IR::Type_Name(metapath);
            auto meta = new IR::Parameter("ig_intr_md", IR::Direction::In, metatype);
            apply_params->parameters.push_back(meta);

            auto parserMetapath = new IR::Path("ingress_intrinsic_metadata_from_parser_aux_t");
            auto parserMetatype = new IR::Type_Name(parserMetapath);
            auto parserMetadata = new IR::Parameter("ig_intr_md_from_parser",
                                                    IR::Direction::In, parserMetatype);
            apply_params->parameters.push_back(parserMetadata);

            auto tm_metapath = new IR::Path("ingress_intrinsic_metadata_for_tm_t");
            auto tm_metatype = new IR::Type_Name(tm_metapath);
            auto tm_meta = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::Out, tm_metatype);
            apply_params->parameters.push_back(tm_meta);
        }
    } else if (name == "egress") {
        if (param_name == "standard_metadata_t") {
            // add egress_intrinsic_metadata_t
            auto metapath = new IR::Path("egress_intrinsic_metadata_t");
            auto metatype = new IR::Type_Name(metapath);
            auto meta = new IR::Parameter("eg_intr_md", IR::Direction::In, metatype);
            apply_params->parameters.push_back(meta);

            // XXX(hanw): map parameter instance name to user instance
            auto parserMetapath = new IR::Path("egress_intrinsic_metadata_from_parser_aux_t");
            auto parserMetatype = new IR::Type_Name(parserMetapath);
            auto parserMetadata = new IR::Parameter("eg_intr_md_from_parser",
                                                    IR::Direction::In, parserMetatype);
            apply_params->parameters.push_back(parserMetadata);

            // XXX(hanw): choose to generate mirror metadata if used
            // XXX(hanw): metadata for output port
        }
    }
}

const IR::Node*
ConvertControl::postorder(IR::P4Control* node) {
    StatementConverter cvt(structure);

    auto name = node->name;
    auto type = node->type;
    auto decl = node->controlLocals;
    auto body = node->body;

    // only handles ingress and egress control block
    if (name != "ingress" && name != "egress")
        return nullptr;

    auto paramList = new IR::ParameterList();
    for (auto p : node->type->applyParams->parameters) {
        auto type_name = p->type->to<IR::Type_Name>();
        if (structure->isOldSystemMetadata(type_name->path->name)) {
            translateParam(p, name, paramList);
        } else {
            paramList->push_back(p);
        }
    }
    // XXX(hanw): handle typeParameters
    type = new IR::Type_Control(name, paramList);

    auto stmts = new IR::IndexedVector<IR::StatOrDecl>();
    for (auto p : body->components) {
        if (auto stmt = p->apply(cvt)->to<IR::StatOrDecl>()) {
            stmts->push_back(stmt);
        }
    }
    auto block = new IR::BlockStatement(*stmts);
    return new IR::P4Control(name, type, decl, block);
}

const IR::Node*
ConvertControl::postorder(IR::P4Action* action) {
    StatementConverter cvt(structure);
    auto paramList = new IR::ParameterList();
    for (auto p : *action->parameters) {
        // XXX(hanw): TBD
        paramList->push_back(p);
    }
    auto stmts = new IR::IndexedVector<IR::StatOrDecl>();
    for (auto p : action->body->components) {
        if (auto stmt = p->apply(cvt)->to<IR::StatOrDecl>()) {
            stmts->push_back(stmt);
        }
    }
    auto body = new IR::BlockStatement(action->body->srcInfo, *stmts);
    return new IR::P4Action(action->srcInfo, action->name, paramList, body);
}

const IR::Node* ConvertParser::postorder(IR::P4Parser* node) {
    auto type = node->type;
    // XXX(hanw): TBD translate constructorParam
    // parserLocals and states are already translated.
    auto decls = node->parserLocals;
    auto states = node->states;
    auto name = node->type->name;  // use new name from Type_Parser
    return new IR::P4Parser(name, type, decls, states);
}

const IR::Node* ConvertParser::postorder(IR::Type_Parser* node) {
    // XXX(hanw): assume simple switch parser parameters
    auto pkt_in = node->applyParams->parameters[0];
    auto header = node->applyParams->parameters[1];
    auto metadata = node->applyParams->parameters[2];

    auto paramList = new IR::ParameterList;
    paramList->push_back(pkt_in);
    auto parserHeaderOut = new IR::Parameter(header->name, IR::Direction::Out, header->type);
    paramList->push_back(parserHeaderOut);
    auto metaOut = new IR::Parameter(metadata->name, IR::Direction::Out, metadata->type);
    paramList->push_back(metaOut);

    cstring parserName;
    if (gress == gress_t::INGRESS) {
        auto intr_md_typepath = new IR::Path("ingress_intrinsic_metadata_t");
        auto intr_md_type = new IR::Type_Name(intr_md_typepath);
        auto ig_intr_md = new IR::Parameter("ig_intr_md", IR::Direction::Out, intr_md_type);
        paramList->push_back(ig_intr_md);
        parserName = "IngressParserImpl";
    } else {
        auto intr_md_typepath = new IR::Path("egress_intrinsic_metadata_t");
        auto intr_md_type = new IR::Type_Name(intr_md_typepath);
        auto eg_intr_md = new IR::Parameter("eg_intr_md", IR::Direction::Out, intr_md_type);
        paramList->push_back(eg_intr_md);
        parserName = "EgressParserImpl";
    }
    return new IR::Type_Parser(parserName, new IR::TypeParameters(), paramList);
}

const IR::Node* ConvertParser::postorder(IR::Declaration* decl) {
    // XXX(hanw): TBD
    return decl;
}

const IR::Node* ConvertParser::postorder(IR::ParserState* state) {
    StatementConverter cvt_stmt(structure);
    ExpressionConverter cvt_expr(structure);
    auto block = new IR::IndexedVector<IR::StatOrDecl>();
    for (auto decl : state->components) {
        if (auto stat = decl->apply(cvt_stmt)->to<IR::StatOrDecl>()) {
            block->push_back(stat);
        }
    }
    auto selectExpr = state->selectExpression->apply(cvt_expr);
    return new IR::ParserState(state->srcInfo, state->name, *block, selectExpr);
}

const IR::Node* ConvertDeparser::postorder(IR::P4Control* node) {
    auto type = node->type;
    // XXX(hanw): TBD translate constructor params
    // controlLocals and body are already translated.
    auto decls = node->controlLocals;
    auto body = node->body;
    auto name = node->type->name;
    return new IR::P4Control(name, type, decls, body);
}

const IR::Node* ConvertDeparser::postorder(IR::Type_Control* node) {
    auto pkt_out = node->applyParams->parameters[0];
    auto header = node->applyParams->parameters[1];

    auto paramList = new IR::ParameterList();
    paramList->push_back(pkt_out);
    paramList->push_back(header);

    cstring deparserName;
    if (gress == gress_t::INGRESS) {
        deparserName = "IngressDeparserImpl";
    } else {
        deparserName = "EgressDeparserImpl";
    }
    return new IR::Type_Control(deparserName, new IR::TypeParameters(), paramList);
}

// XXX(hanw): intrinsic metadata is in headers
const IR::Node* ConvertMetadata::preorder(IR::Member* mem) {
    auto submem = mem->expr->to<IR::Member>();
    std::pair<cstring, cstring> mname(submem ? submem->member.name : mem->expr->toString(),
            mem->member);
    if (remap.count(mname) == 0) return mem;

    auto& to = remap.at(mname);
    LOG3("remap " << mname.first << '.' << mname.second << " -> " <<
            to.first << '.' << to.second);
    mem->member = to.second;
    if (submem) {
        auto expr = new IR::Member(submem->srcInfo, submem->expr, to.first);
        auto result = new IR::Member(mem->srcInfo, expr, mem->member);
        return result;
    } else {
        auto expr = new IR::PathExpression(to.first);
        auto result = new IR::Member(mem->srcInfo, expr, mem->member);
        return result;
    }
    LOG5("not remapping " << mname.first << '.' << mname.second);
}

const IR::Node* ConvertMetadata::preorder(IR::StructField* node) {
    return node;
}

const IR::Node* ConvertMetadata::postorder(IR::AssignmentStatement* node) {
    // XXX(hanw): TBD
    return node;
}

}  // namespace Tofino
