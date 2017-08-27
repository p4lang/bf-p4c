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

    void filterArchDecls(const IR::Node *node) {
        bool filter = false;
        if (node->is<IR::Type_Error>()) {
            auto userDefinedError = new IR::Type_Error(node->srcInfo, *new IR::ID("error"));
            for (auto err : node->to<IR::Type_Error>()->members) {
                filter = isSystemType<IR::Declaration_ID>(err, "error");
                if (!filter) {
                    userDefinedError->members.push_back(err); } }
            programDeclarations->push_back(userDefinedError);
            return; }
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
            ::error("Unsupported target %1%", target); }
        /// populate reservedNames from arch.p4 and include system headers
        for (auto node : baseArchTypes) {
            processArchTypes(node); }
        // Debug only
        for (auto name : *reservedNames) {
            LOG3("Reserved: " << name); }
        /// filter system type declarations from pre-processed user programs
        for (auto node : program->declarations) {
            filterArchDecls(node); }

        return new IR::P4Program(program->srcInfo, *programDeclarations);
    }
};

// Create P4Program with the new architecture definition
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
                continue; }
            program_declarations.push_back(decl); }
        for (auto decl : program->declarations) {
            if (decl->is<IR::Type_Error>()) {
                allErrors->members.append(decl->to<IR::Type_Error>()->members);
                continue; }
            program_declarations.push_back(decl); }
        return new IR::P4Program(program->srcInfo, program_declarations);
    }
};

IR::Declaration_Instance*
convertDirectCounterOrMeterInstance(IR::Declaration_Instance* node, cstring name) {
    /* counter<_>(counter_type_t.PACKETS) counter_name; OR
     * meter<_>(meter_type_t.PACKETS) meter_name;
     */
    auto typeName = new IR::Type_Name(name);
    auto dontcare = new IR::Type_Dontcare();
    auto args = new IR::Vector<IR::Type>();
    args->push_back(dontcare);
    auto specializedType = new IR::Type_Specialized(typeName, args);
    return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                        specializedType, node->arguments);
}

IR::Declaration_Instance*
convertIndirectCounterOrMeterInstance(IR::Declaration_Instance* node, cstring name) {
    // bit width is from first parameter
    auto typeArgs = node->arguments->at(0);
    BUG_CHECK(typeArgs->is<IR::Constant>(), "Expected Constant in %s argument", name);
    auto constant = typeArgs->to<IR::Constant>();
    auto typeBits = constant->type->to<IR::Type_Bits>();
    CHECK_NULL(typeBits);
    auto typeName = new IR::Type_Name(name);
    auto args = new IR::Vector<IR::Type>();
    args->push_back(typeBits);
    auto specializedType = new IR::Type_Specialized(typeName, args);
    auto instanceArgs = new IR::Vector<IR::Expression>();
    instanceArgs->push_back(node->arguments->at(1));
    instanceArgs->push_back(node->arguments->at(0));
    return new IR::Declaration_Instance(node->srcInfo, node->name, node->annotations,
                                        specializedType, instanceArgs);
}

/// convert counter related IR nodes
class DoCounterTranslation : public Transform {
 public:
    DoCounterTranslation() { setName("DoCounterTranslation"); }

    const IR::Node* postorder(IR::Declaration_Instance* node) override {
        if (auto type = node->getType()->to<IR::Type_Name>()) {
            if (type->path->name == "direct_counter") {
                return convertDirectCounterOrMeterInstance(node, "counter");
            } else if (type->path->name == "counter") {
                return convertIndirectCounterOrMeterInstance(node, "counter"); } }
        return node;
    }

    const IR::Node* postorder(IR::ConstructorCallExpression* node) override {
        auto tn = node->constructedType->to<IR::Type_Name>();
        if (!tn) return node;
        if (tn->path->name == "direct_counter") {
            auto typeName = new IR::Type_Name("counter");
            auto dontcare = new IR::Type_Dontcare();
            auto args = new IR::Vector<IR::Type>();
            args->push_back(dontcare);
            auto specializedType = new IR::Type_Specialized(typeName, args);
            return new IR::ConstructorCallExpression(node->srcInfo, specializedType,
                                                     node->arguments); }
        return node;
    }

    const IR::Node* postorder(IR::Type_Name* node) override {
        if (node->path->name != "CounterType") return node;
        return new IR::Type_Name("counter_type_t");
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
            return new IR::Member(node->srcInfo, node->type, node->expr, *id); }
        return node;
    }
};

class DoMeterTranslation : public Transform {
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;

 public:
    DoMeterTranslation(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
    : refMap(refMap), typeMap(typeMap) {
        CHECK_NULL(refMap); CHECK_NULL(typeMap);
        setName("DoMeterTranslation"); }

    const IR::Node* postorder(IR::Declaration_Instance* node) override {
        const IR::Type_Name* typeName = nullptr;
        if (auto type = node->getType()->to<IR::Type_Specialized>())
            typeName = type->baseType->to<IR::Type_Name>();
        else
            typeName = node->getType()->to<IR::Type_Name>();

        if (!typeName)
            return node;

        if (typeName->path->name == Tofino::P4_14::DirectMeter)
            return convertDirectCounterOrMeterInstance(node, Tofino::P4_16::Meter);
        else if (typeName->path->name == Tofino::P4_14::Meter)
            return convertIndirectCounterOrMeterInstance(node, Tofino::P4_16::Meter);

        return node;
    }

    const IR::Node* postorder(IR::ConstructorCallExpression* node) override {
        auto tn = node->constructedType->to<IR::Type_Name>();
        if (!tn) return node;
        if (tn->path->name == Tofino::P4_14::DirectMeter) {
            auto typeName = new IR::Type_Name(Tofino::P4_16::Meter);
            auto dontcare = new IR::Type_Dontcare();
            auto args = new IR::Vector<IR::Type>( { dontcare } );
            auto specializedType = new IR::Type_Specialized(typeName, args);
            return new IR::ConstructorCallExpression(node->srcInfo, specializedType,
                                                     node->arguments); }
        return node;
    }

    const IR::Node* postorder(IR::Type_Name* node) override {
        if (node->path->name != Tofino::P4_14::MeterType)
            return node;
        return new IR::Type_Name(Tofino::P4_16::MeterType);
    }

    const IR::Node* postorder(IR::Member* node) override {
        if (auto tnp = node->expr->to<IR::TypeNameExpression>()) {
            if (auto tn = tnp->typeName->to<IR::Type_Name>())
                if (tn->path->name != Tofino::P4_16::MeterType)
                    return node;
            if (node->member.name == Tofino::P4_14::PACKETS)
                return new IR::Member(node->srcInfo, node->type, node->expr,
                                      Tofino::P4_16::PACKETS);
            else if (node->member.name == Tofino::P4_14::BYTES)
                return new IR::Member(node->srcInfo, node->type, node->expr,
                                      Tofino::P4_16::BYTES);
        } else if (auto pe = node->expr->to<IR::PathExpression>()) {
            if (node->member.name == "execute_meter")
                return new IR::Member(node->srcInfo, node->type, node->expr, "execute");
            else if (node->member.name == "read")
                return new IR::Member(node->srcInfo, node->type, node->expr, "execute"); }
        return node;
    }

    // prune() all except meter->execute_meter()
    const IR::Node* preorder(IR::MethodCallExpression* node) override {
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap, true);
        if (auto em = mi->to<P4::ExternMethod>()) {
            if (em->originalExternType->name != Tofino::P4_14::Meter &&
                em->originalExternType->name != Tofino::P4_14::DirectMeter) {
                LOG1("skip " << em->originalExternType->name);
                prune(); }}
        return node;
    }

    // use bit_of_color() action to stop-gap lack of enum-to-bit<n> cast in P4-16
    const IR::Node* postorder(IR::MethodCallExpression* node) override {
        auto member = node->method->to<IR::Member>();
        if (!member)
            return node;

        if (member->member == "execute") {
            if (node->arguments->size() == 1) {
                // auto dest = node->arguments->at(0);
                auto args = new IR::Vector<IR::Expression>();
                auto exec = new IR::MethodCallExpression(node->srcInfo, node->method,
                                                         new IR::Vector<IR::Type>(), args);
                return exec;
            } else if (node->arguments->size() == 2) {
                auto size = node->arguments->at(0);
                // auto dest = node->arguments->at(1);
                auto args = new IR::Vector<IR::Expression>();
                args->push_back(size);
                auto exec = new IR::MethodCallExpression(node->srcInfo, node->method,
                                                         new IR::Vector<IR::Type>(), args);
                return exec;
            }
        }
        return node;
    }
};

using RandomUseMap = std::map<cstring, const IR::Declaration_Instance*>;
using ActionUseMap = std::map<cstring, cstring>;

class FindRandomUsage : public Inspector {
    RandomUseMap* randUseMap;
    ActionUseMap* actionUseMap;
    set<cstring> unique_names;

 public:
    FindRandomUsage(RandomUseMap* map, ActionUseMap* actionMap)
    : randUseMap(map), actionUseMap(actionMap) {
        CHECK_NULL(map);
        CHECK_NULL(actionMap);
        unique_names.insert("random");  // exclude 'random' as instance name
        setName("FindRandomUsage"); }

    bool preorder(const IR::MethodCallExpression* node) override {
        auto expr = node->method->to<IR::PathExpression>();
        if (!expr)
            return node;
        if (expr->path->name == Tofino::P4_14::Random) {
            auto control = findContext<IR::P4Control>();

            // T at index 0
            auto baseType = node->arguments->at(0);
            auto typeArgs = new IR::Vector<IR::Type>();
            typeArgs->push_back(baseType->type);
            auto randType = new IR::Type_Specialized(new IR::Type_Name(Tofino::P4_16::Random),
                                                     typeArgs);
            cstring randName;
            if (!randUseMap->count(control->name)) {
                randName = cstring::make_unique(unique_names, "random", '_');
                unique_names.insert(randName);
            } else {
                randName = randUseMap->at(control->name)->name;
            }

            auto randInst = new IR::Declaration_Instance(randName, randType,
                                                         new IR::Vector<IR::Expression>());
            randUseMap->emplace(control->name, randInst);

            auto action = findContext<IR::P4Action>();
            if (action)
                actionUseMap->emplace(action->name, randName);
            else
                actionUseMap->emplace(control->name, randName);
        }
        return false;
    }
};

class DoRandomTranslation : public Transform {
    RandomUseMap* randUseMap;
    ActionUseMap* actionUseMap;

 public:
    DoRandomTranslation(RandomUseMap* map, ActionUseMap* actionMap)
    : randUseMap(map), actionUseMap(actionMap) {
        CHECK_NULL(map);
        CHECK_NULL(actionMap);
        setName("DoRandomTranslation"); }

    const IR::Node* postorder(IR::MethodCallStatement* node) override {
        auto mc = node->methodCall->to<IR::MethodCallExpression>();
        if (!mc)
            return node;

        auto expr = mc->method->to<IR::PathExpression>();
        if (!expr)
            return node;

        if (expr->path->name == Tofino::P4_14::Random) {
            auto dest = mc->arguments->at(0);
            // ignore lower bound
            auto hi = mc->arguments->at(2);
            auto args = new IR::Vector<IR::Expression>();
            args->push_back(hi);

            cstring randName;
            auto control = findContext<IR::P4Control>();
            auto action = findContext<IR::P4Action>();
            if (action)
                randName = actionUseMap->at(action->name);
            else
                randName = actionUseMap->at(control->name);

            auto method = new IR::PathExpression(randName);
            auto member = new IR::Member(method, Tofino::P4_16::RandomExec);
            auto call = new IR::MethodCallExpression(node->srcInfo, member,
                                                     new IR::Vector<IR::Type>(), args);
            auto assign = new IR::AssignmentStatement(dest, call);
            return assign;
        }
        return node;
    }

    const IR::Node* preorder(IR::P4Control* control) override {
        if (!randUseMap->count(control->name))
            return control;
        auto decl = randUseMap->at(control->name);
        auto controlLocals = new IR::IndexedVector<IR::Declaration>();
        controlLocals->push_back(decl);
        controlLocals->append(control->controlLocals);
        auto result = new IR::P4Control(control->srcInfo, control->name, control->type,
                                        control->constructorParams, *controlLocals, control->body);
        return result;
    }
};

class RandomTranslation : public PassManager {
    RandomUseMap map;
    ActionUseMap actionMap;

 public:
    RandomTranslation() {
        addPasses({
            new FindRandomUsage(&map, &actionMap),
            new DoRandomTranslation(&map, &actionMap),
        });
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
        new P4::TypeChecking(&refMap, &typeMap, true),
        new RemoveUserArchitecture(&structure, &options),
        new DoCounterTranslation(),
        new DoMeterTranslation(&refMap, &typeMap),
        new RandomTranslation(),
        new AppendSystemArchitecture(&structure),
        new TranslationLast(),
        new P4::ClearTypeMap(&typeMap),
        new P4::ResolveReferences(&refMap),
        new P4::TypeInference(&refMap, &typeMap, false),  // insert casts
    });
}

}  // namespace Tofino
