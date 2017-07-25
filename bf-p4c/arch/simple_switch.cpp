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
#include "frontends/p4/coreLibrary.h"
#include "frontends/common/options.h"
#include "p4/typeChecking/typeChecker.h"

namespace P4 {

/// remove user architecture declarations, keep user program declarations
class RemoveUserArchitecture : public Transform {
    ProgramStructure* structure;

 public:
    explicit RemoveUserArchitecture(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); setName("RemoveUserArchitecture"); }

    // XXX(hanw): Use srcInfo to tell if a type declaration is defined by system or user.
    // This is necessary because the tofino-specific metadata are defined in P4-14 in
    // 'p4-14include/tofino/tofino_intrinsic_metadata.p4'. After the 14-to-16 translation,
    // these type declarations are part of program declarations, and can only be distinguished
    // from user types by checking the original srcInfo.
    // TODO: avoid relying on file path to find out system file.
    bool isSystemFile(cstring file) {
        char p4includePath_canonicalized[PATH_MAX];
        char p4_14includePath_canonicalized[PATH_MAX];
        realpath(p4includePath, p4includePath_canonicalized);
        realpath(p4_14includePath, p4_14includePath_canonicalized);
        return (file.startsWith(p4includePath) ||
                file.startsWith(p4includePath_canonicalized) ||
                file.startsWith(p4_14includePath) ||
                file.startsWith(p4_14includePath_canonicalized));
    }

    cstring ifSystemFile(const IR::Node* node) {
        if (!node->srcInfo.isValid()) return nullptr;
        unsigned line = node->srcInfo.getStart().getLineNumber();
        auto sfl = Util::InputSources::instance->getSourceLine(line);
        cstring sourceFile = sfl.fileName;
        if (isSystemFile(sourceFile))
            return sourceFile;
        return nullptr;
    }

    bool isSystemType(cstring name, std::set<cstring>* type_names) {
        auto it = type_names->find(name);
        return (it != type_names->end());
    }

    void process_arch_types(const IR::Node* node, std::set<cstring>* type_names) {
        cstring name;
        if (node->is<IR::Type_Declaration>()) {
            name = node->to<IR::Type_Declaration>()->name;
            type_names->insert(name);
            // add metadata defined in v1model.p4 to system_metadata
            if (node->is<IR::Type_Struct>() || node->is<IR::Type_Header>()) {
                structure->system_metadata.emplace(name, node);
            }
        } else if (node->is<IR::P4Action>()) {
            name = node->to<IR::P4Action>()->name;
            type_names->insert(name);
        } else if (node->is<IR::Method>()) {
            name = node->to<IR::Method>()->name;
            type_names->insert(name);
        } else if (node->is<IR::Declaration_MatchKind>()) {
            for (auto member : node->to<IR::Declaration_MatchKind>()->members) {
                name = member->name;
                type_names->insert(name);
            }
        } else {
            ::error("Unhandled declaration type %1%", node);
        }
    }

    void add_system_defined_structs(const IR::Node* node, std::set<cstring>* type_names) {
        cstring name;
        if (node->is<IR::Type_Struct>()) {
            name = node->to<IR::Type_Struct>()->name;
        } else if (node->is<IR::Type_Header>()) {
            name = node->to<IR::Type_Header>()->name;
        }
        if (isSystemType(name, type_names)) {
            type_names->insert(name);
            structure->system_metadata.emplace(name, node);
        }
    }

    void filter_arch_decls(const IR::Node* node, std::set<cstring>* type_names,
                           IR::IndexedVector<IR::Node>* program_declarations) {
        bool keep = true;
        if (node->is<IR::Type_Declaration>()) {
            auto name = node->to<IR::Type_Declaration>()->name;
            keep = !isSystemType(name, type_names);
        } else if (node->is<IR::P4Action>()) {
            auto name = node->to<IR::P4Action>()->name;
            keep = !isSystemType(name, type_names);
        } else if (node->is<IR::Method>()) {
            auto name = node->to<IR::Method>()->name;
            keep = !isSystemType(name, type_names);
        } else if (node->is<IR::Declaration_MatchKind>()) {
            keep = false;
        }
        // XXX(hanw): sourceFile == nullptr if node is from user-defined program.
        // ideally, we would like to not rely on srcInfo to decide the origin
        // of a declaration, but for tofino_intrinsic_metadata from p4-14,
        // there is no better way than comparing the srcInfo with nullptr.
        cstring sourceFile = ifSystemFile(node);
        keep = keep && (sourceFile == nullptr);
        if (keep)
            program_declarations->push_back(node);
    }

    const IR::Node* postorder(IR::P4Program* program) override {
        // type_names is used to filter out types defined in arch.p4
        std::set<cstring> type_names;
        IR::IndexedVector<IR::Node> user_arch_types;
        IR::IndexedVector<IR::Node> program_declarations;
        structure->include("v1model.p4", &user_arch_types);
        for (auto node : user_arch_types) {
            process_arch_types(node, &type_names);
        }
        for (auto node : program->declarations) {
            filter_arch_decls(node, &type_names, &program_declarations);
        }
        for (auto node : program_declarations) {
            add_system_defined_structs(node, &type_names);
        }
        return new IR::P4Program(program->srcInfo, program_declarations);
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

// simple switch to tofino converter
SimpleSwitchTranslator::SimpleSwitchTranslator() {
    setName("SimpleSwitchTranslator");
    passes.emplace_back(new RemoveUserArchitecture(&structure));
    passes.emplace_back(new RemapStandardMetadata());
    passes.emplace_back(new DiscoverProgramStructure(&structure));
    passes.emplace_back(new TranslateSimpleSwitch(&structure));
    passes.emplace_back(new AppendSystemArchitecture(&structure));
}

const IR::P4Program*
translateSimpleSwitch(const IR::P4Program* program,
                      boost::optional<DebugHook> debugHook = boost::none) {
    SimpleSwitchTranslator translator;
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
        if (structure->is_old_system_metadata(type_name->path->name)) {
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

const IR::Node* ConvertMetadata::postorder(IR::Member* node) {
    // XXX(hanw): TBD
    return node;
}

const IR::Node* ConvertMetadata::preorder(IR::StructField* node) {
    if (node->type->is<IR::Type_Name>()) {
        auto type = node->type->to<IR::Type_Name>();
        auto name = type->path->name;
        // XXX(hanw): convert following metadata
        if (name == "generator_metadata_t_0" ||
            name == "ingress_parser_control_signals" ||
            name == "standard_metadata_t")
            return nullptr;
    }
    return new IR::StructField(node->srcInfo, node->name, node->annotations, node->type);
}

const IR::Node* ConvertMetadata::preorder(IR::Type_Header* node) {
    LOG1("header " << node);
    return node;
}

const IR::Node* ConvertMetadata::preorder(IR::Type_Struct* node) {
    return node;
}

const IR::Node* ConvertMetadata::postorder(IR::AssignmentStatement* node) {
    // XXX(hanw): TBD
    return node;
}

}  // namespace P4
