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
    void setReservedName(const IR::Node* node, cstring prefix = cstring()) {
        if (auto type = node->to<T>()) {
            auto name = type->name.name;
            if (prefix)
                name = prefix + "$" + name;
            reservedNames->insert(name);
        }
    }

    void processArchTypes(const IR::Node *node) {
        if (node->is<IR::Type_Error>()) {
            for (auto err : node->to<IR::Type_Error>()->members) {
                setReservedName<IR::Declaration_ID>(err, "error");
            }
            return;
        }
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
            structure->system_metadata.emplace(name, node);
        }
    }

    /// Helper function to decide if the type of IR::Node is a system defined type.
    template<typename T>
    bool isSystemType(const IR::Node* t, cstring prefix = cstring()) {
        if (auto type = t->to<T>()) {
            auto name = type->name.name;
            if (prefix)
                name = prefix + "$" + name;
            auto it = reservedNames->find(name);
            return it != reservedNames->end();
        }
        return false;
    }

    void filterArchDecls(const IR::Node *node) {
        bool filter = false;
        if (node->is<IR::Type_Error>()) {
            auto userDefinedError = new IR::Type_Error(node->srcInfo, *new IR::ID("error"));
            for (auto err : node->to<IR::Type_Error>()->members) {
                filter = isSystemType<IR::Declaration_ID>(err, "error");
                if (!filter) {
                    userDefinedError->members.push_back(err);
                }
            }
            programDeclarations->push_back(userDefinedError);
            return;
        }
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
        } else {
            ::error("Unsupported target %1%", target);
        }
        /// populate reservedNames from arch.p4 and include system headers
        for (auto node : baseArchTypes) {
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

class AppendSystemArchitecture : public Transform {
    ProgramStructure* structure;
    std::set<IR::Type*> insertedType;

 public:
    explicit AppendSystemArchitecture(ProgramStructure* structure)
        : structure(structure) { CHECK_NULL(structure); setName("AppendSystemArchitecture"); }

    const IR::Node* postorder(IR::P4Program* program) override {
        structure->include("tofino/v1model.p4", structure->tofinoArchTypes);
        IR::IndexedVector<IR::Node> program_declarations;
        IR::Type_Error* allErrors = nullptr;
        for (auto decl : *structure->tofinoArchTypes) {
            if (auto err = decl->to<IR::Type_Error>()) {
                allErrors = new IR::Type_Error(err->srcInfo, *new IR::ID("error"), err->members);
                program_declarations.push_back(allErrors);
                continue;
            }
            program_declarations.push_back(decl);
        }
        for (auto decl : program->declarations) {
            if (decl->is<IR::Type_Error>()) {
                allErrors->members.append(decl->to<IR::Type_Error>()->members);
                continue;
            }
            program_declarations.push_back(decl);
        }
        return new IR::P4Program(program->srcInfo, program_declarations);
    }
};

/// convert counter related IR nodes
class DoCounterTranslation : public Transform {
 public:
    DoCounterTranslation() { setName("DoCounterTranslation"); }

    const IR::Node* postorder(IR::Declaration_Instance* node) override {
        if (auto type = node->getType()->to<IR::Type_Name>()) {
            if (type->path->name == "direct_counter") {
                LOG1("convert decl " << node);
                /* counter<_>(counter_type_t.PACKETS) counter_name; */
                auto path = new IR::Path("counter");
                auto typeName = new IR::Type_Name(path);
                auto dontcare = new IR::Type_Dontcare();
                auto args = new IR::Vector<IR::Type>();
                args->push_back(dontcare);
                auto specializedType = new IR::Type_Specialized(typeName, args);
                auto instance = new IR::Declaration_Instance(node->srcInfo, node->name,
                                                             node->annotations,
                                                             specializedType,
                                                             node->arguments);
                LOG1("converted " << instance);
                return instance;
            } else if (type->path->name == "counter") {
                // bit width is from first parameter
                auto typeArgs = node->arguments->at(0);
                BUG_CHECK(typeArgs->is<IR::Constant>(), "Expected constant in counter argument");
                auto constant = typeArgs->to<IR::Constant>();
                auto typeBits = constant->type->to<IR::Type_Bits>();
                CHECK_NULL(typeBits);
                auto path = new IR::Path("counter");
                auto typeName = new IR::Type_Name(path);
                auto args = new IR::Vector<IR::Type>();
                args->push_back(typeBits);
                auto specializedType = new IR::Type_Specialized(typeName, args);
                auto instanceArgs = new IR::Vector<IR::Expression>();
                instanceArgs->push_back(node->arguments->at(1));
                instanceArgs->push_back(node->arguments->at(0));
                auto instance = new IR::Declaration_Instance(node->srcInfo, node->name,
                                                             node->annotations,
                                                             specializedType,
                                                             instanceArgs);
                return instance;
            }
        }
        return node;
    }

    const IR::Node* postorder(IR::ConstructorCallExpression* node) override {
        auto tn = node->constructedType->to<IR::Type_Name>();
        if (!tn) return node;
        if (tn->path->name == "direct_counter") {
            auto path = new IR::Path("counter");
            auto typeName = new IR::Type_Name(path);
            auto dontcare = new IR::Type_Dontcare();
            auto args = new IR::Vector<IR::Type>();
            args->push_back(dontcare);
            auto specializedType = new IR::Type_Specialized(typeName, args);
            auto cce = new IR::ConstructorCallExpression(node->srcInfo, specializedType,
                                                         node->arguments);
            return cce;
        }
        return node;
    }

    const IR::Node* postorder(IR::Type_Name* node) override {
        if (node->path->name != "CounterType")
            return node;
        auto path = new IR::Path("counter_type_t");
        return new IR::Type_Name(path);
    }

    const IR::Node* postorder(IR::Member* node) override {
        if (auto tnp = node->expr->to<IR::TypeNameExpression>())
        if (auto tn = tnp->typeName->to<IR::Type_Name>())
        if (tn->path->name != "counter_type_t")
            return node;
        if (node->member.name == "packets" ||
            node->member.name == "bytes" ||
            node->member.name == "packets_and_bytes") {
            std::string name = node->member.name.c_str();
            boost::to_upper(name);
            auto id = new IR::ID(name);
            return new IR::Member(node->srcInfo, node->type, node->expr, *id);
        }
        return node;
    }

    const IR::Node* postorder(IR::Property* node) override {
        return node;
    }

    const IR::Node* postorder(IR::MethodCallStatement* node) override {
        return node;
    }
};

class TranslationLast : public PassManager {
 public:
    TranslationLast() { setName("TranslationLast"); }
};

SimpleSwitchTranslation::SimpleSwitchTranslation(Tofino_Options& options) {
    setName("Translation");
    refMap.setIsV1(true);
    addPasses({
        new P4::TypeChecking(&refMap, &typeMap),
        // check architecture, must be v1model
        new RemoveUserArchitecture(&structure, &options),
        new DoCounterTranslation(),
        new AppendSystemArchitecture(&structure),
        new TranslationLast(),
    });
}

}  // namespace Tofino
