#include "simple_switch.h"

#include <set>

namespace BFN {

/// helpers
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

const IR::P4Control* SimpleSwitchTranslation::getIngress(const IR::ToplevelBlock* blk) {
    return getBlock<IR::P4Control, IR::ControlBlock>(blk, "ig");
}

const IR::P4Control* SimpleSwitchTranslation::getEgress(const IR::ToplevelBlock* blk) {
    return getBlock<IR::P4Control, IR::ControlBlock>(blk, "eg");
}

const IR::P4Control* SimpleSwitchTranslation::getDeparser(const IR::ToplevelBlock* blk) {
    return getBlock<IR::P4Control, IR::ControlBlock>(blk, "dep");
}

const IR::P4Parser* SimpleSwitchTranslation::getParser(const IR::ToplevelBlock* blk) {
    return getBlock<IR::P4Parser, IR::ParserBlock>(blk, "p");
}

static cstring toString(BlockType block) {
    switch (block) {
        case BlockType::Unknown: return "unknown";
        case BlockType::Parser: return "parser";
        case BlockType::Ingress: return "ingress";
        case BlockType::Egress: return "egress";
        case BlockType::Deparser: return "deparser";
    }
    BUG("Unexpected *block value");
}

std::ostream& operator<<(std::ostream& out, BlockType block) {
    return out << toString(block);
}

bool operator>>(cstring s, BlockType& blockType) {
    if (s == "ingress")
        blockType = BlockType::Ingress;
    else if (s == "egress")
        blockType = BlockType::Egress;
    else if (s == "parser")
        blockType = BlockType::Parser;
    else if (s == "deparser")
        blockType = BlockType::Deparser;
    else
        return false;
    return true;
}

/// When compiling a tofino-v1model program, the compiler by default
/// includes tofino/intrinsic_metadata.p4 and v1model.p4 from the
/// system path. Symbols in these system header files are reserved and
/// cannot be used in user programs.
/// @input: User P4 program with source architecture type declarations.
/// @output: User P4 program w/o source architecture type declarations.
class RemoveUserArchitecture : public Transform {
    ProgramStructure* structure;
    Target    target;
    // reservedNames is used to filter out system defined types.
    std::set<cstring>* reservedNames;
    IR::IndexedVector<IR::Node>* programDeclarations;

 public:
    RemoveUserArchitecture(ProgramStructure* structure, Target arch)
        : structure(structure) {
        setName("RemoveUserArchitecture");
        CHECK_NULL(structure);
        reservedNames = new std::set<cstring>();
        target = arch;
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

        if (target == Target::Simple) {
            structure->include("v1model.p4", &baseArchTypes);
            structure->include("tofino/stateful_alu.p4", &libArchTypes);
        }
        /// populate reservedNames from arch.p4 and include system headers
        for (auto node : baseArchTypes) {
            processArchTypes(node); }
        for (auto node : libArchTypes) {
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

        if (typeName->path->name == BFN::P4_14::DirectMeter)
            return convertDirectCounterOrMeterInstance(node, BFN::P4_16::Meter);
        else if (typeName->path->name == BFN::P4_14::Meter)
            return convertIndirectCounterOrMeterInstance(node, BFN::P4_16::Meter);

        return node;
    }

    const IR::Node* postorder(IR::ConstructorCallExpression* node) override {
        auto tn = node->constructedType->to<IR::Type_Name>();
        if (!tn) return node;
        if (tn->path->name == BFN::P4_14::DirectMeter) {
            auto typeName = new IR::Type_Name(BFN::P4_16::Meter);
            auto dontcare = new IR::Type_Dontcare();
            auto args = new IR::Vector<IR::Type>( { dontcare } );
            auto specializedType = new IR::Type_Specialized(typeName, args);
            return new IR::ConstructorCallExpression(node->srcInfo, specializedType,
                                                     node->arguments); }
        return node;
    }

    const IR::Node* postorder(IR::Type_Name* node) override {
        if (node->path->name != BFN::P4_14::MeterType)
            return node;
        return new IR::Type_Name(BFN::P4_16::MeterType);
    }

    const IR::Node* postorder(IR::Member* node) override {
        if (auto tnp = node->expr->to<IR::TypeNameExpression>()) {
            if (auto tn = tnp->typeName->to<IR::Type_Name>())
                if (tn->path->name != BFN::P4_16::MeterType)
                    return node;
            if (node->member.name == BFN::P4_14::PACKETS)
                return new IR::Member(node->srcInfo, node->type, node->expr,
                                      BFN::P4_16::PACKETS);
            else if (node->member.name == BFN::P4_14::BYTES)
                return new IR::Member(node->srcInfo, node->type, node->expr,
                                      BFN::P4_16::BYTES);
        } else if (node->expr->to<IR::PathExpression>()) {
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
            if (em->originalExternType->name != BFN::P4_14::Meter &&
                em->originalExternType->name != BFN::P4_14::DirectMeter) {
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
    std::set<cstring> unique_names;

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
        if (expr->path->name == BFN::P4_14::Random) {
            auto control = findContext<IR::P4Control>();

            // T at index 0
            auto baseType = node->arguments->at(0);
            auto typeArgs = new IR::Vector<IR::Type>();
            typeArgs->push_back(baseType->type);
            auto randType = new IR::Type_Specialized(new IR::Type_Name(BFN::P4_16::Random),
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

        if (expr->path->name == BFN::P4_14::Random) {
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
            auto member = new IR::Member(method, BFN::P4_16::RandomExec);
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

using HashUseMap = ordered_map<cstring, std::set<const IR::Declaration_Instance*>>;
using HashNameMap = ordered_map<const IR::Node*, cstring>;

class FindHashUsage : public Inspector {
    HashUseMap* hashUseMap;
    HashNameMap* hashNameMap;
    std::set<cstring> unique_names;

 public:
    FindHashUsage(HashUseMap* map, HashNameMap* nameMap)
    : hashUseMap(map), hashNameMap(nameMap) {
        CHECK_NULL(map);
        CHECK_NULL(hashNameMap);
        unique_names.insert("hash");
        setName("FindHashUsage"); }

    bool preorder(const IR::MethodCallExpression* node) override {
        auto expr = node->method->to<IR::PathExpression>();
        if (!expr)
            return false;

        if (expr->path->name == BFN::P4_14::Hash) {
            auto pAlgo = node->arguments->at(1);
            auto control = findContext<IR::P4Control>();
            auto hashArgs = new IR::Vector<IR::Expression>();
            hashArgs->push_back(pAlgo);

            auto typeArgs = new IR::Vector<IR::Type>({
                node->typeArguments->at(2),
                node->typeArguments->at(1),
                node->typeArguments->at(3) });

            auto hashType = new IR::Type_Specialized(new IR::Type_Name("hash"), typeArgs);
            auto hashName = cstring::make_unique(unique_names, "hash", '_');
            unique_names.insert(hashName);

            auto hashInst = new IR::Declaration_Instance(hashName, hashType, hashArgs);
            hashNameMap->emplace(node, hashName);

            if (hashUseMap->find(control->name) == hashUseMap->end()) {
                std::set<const IR::Declaration_Instance *> set = {hashInst};
                hashUseMap->emplace(control->name, set);
            } else {
                hashUseMap->at(control->name).insert(hashInst);
            }
        }
        return false;
    }
};

class DoHashTranslation : public Transform {
    HashUseMap* hashUseMap;
    HashNameMap* hashNameMap;

 public:
    DoHashTranslation(HashUseMap* map, HashNameMap* nameMap)
    : hashUseMap(map), hashNameMap(nameMap) {
        CHECK_NULL(map);
        CHECK_NULL(nameMap);
        setName("DoHashTranslation"); }

    const IR::Node* preorder(IR::Type_Name* node) override {
        if (node->path->name != BFN::P4_14::HashAlgorithm) {
            prune();
            return node; }
        return new IR::Type_Name(BFN::P4_16::HashAlgorithm);
    }

    const IR::Node* postorder(IR::Member* node) override {
        if (auto tnp = node->expr->to<IR::TypeNameExpression>())
        if (auto tn = tnp->typeName->to<IR::Type_Name>())
        if (tn->path->name != BFN::P4_16::HashAlgorithm)
            return node;

        cstring name = node->member.name;
        if (name == BFN::P4_14::CRC16) {
            name = BFN::P4_16::CRC16;
        } else if (name == BFN::P4_14::CRC32) {
            name = BFN::P4_16::CRC32;
        } else if (name == BFN::P4_14::RANDOM) {
            name = BFN::P4_16::RANDOM;
        } else if (name == BFN::P4_14::IDENTITY) {
            name = BFN::P4_16::IDENTITY;
        }
        return new IR::Member(node->srcInfo, node->type, node->expr, name);
    }

    const IR::Node* preorder(IR::MethodCallStatement* node) override {
        auto mc = node->methodCall->to<IR::MethodCallExpression>();
        if (!mc)
            return node;

        auto expr = mc->method->to<IR::PathExpression>();
        if (!expr)
            return node;

        if (expr->path->name == BFN::P4_14::Hash) {
            auto pDest = mc->arguments->at(0);
            auto pBase = mc->arguments->at(2);
            auto pData = mc->arguments->at(3);
            auto pMax = mc->arguments->at(4);
            auto args = new IR::Vector<IR::Expression>( { pData, pBase, pMax });

            auto control = findContext<IR::P4Control>();
            BUG_CHECK(control, "Method call %1% not in any control block", expr->path->name);

            cstring hashName;
            auto it = hashNameMap->find(mc);
            if (it != hashNameMap->end()) {
                hashName = it->second; }

            auto method = new IR::PathExpression(hashName);
            auto member = new IR::Member(method, BFN::P4_16::Hash);
            auto call = new IR::MethodCallExpression(node->srcInfo, member, args);
            auto assign = new IR::AssignmentStatement(pDest, call);
            return assign;
        }
        return node;
    }

    const IR::Node* preorder(IR::P4Control* control) override {
        if (!hashUseMap->count(control->name))
            return control;

        auto controlLocals = new IR::IndexedVector<IR::Declaration>();
        for (auto decl : hashUseMap->at(control->name))
            controlLocals->push_back(decl);
        controlLocals->append(control->controlLocals);

        auto result = new IR::P4Control(control->srcInfo, control->name, control->type,
                                        control->constructorParams, *controlLocals,
                                        control->body);
        return result;
    }
};

class HashTranslation : public PassManager {
    HashUseMap useMap;
    HashNameMap nameMap;
 public:
    HashTranslation() {
        addPasses({
            new FindHashUsage(&useMap, &nameMap),
            new DoHashTranslation(&useMap, &nameMap),
        });
    }
};

class ChecksumTranslation : public Transform {
    bool allowUnimplemented;

 public:
    explicit ChecksumTranslation(bool allowUnimplemented = false)
    : allowUnimplemented(allowUnimplemented) {
        setName("ChecksumTranslation");
    }
    const IR::Node* postorder(IR::Declaration_Instance* node) override {
        if (auto type = node->getType()->to<IR::Type_Name>()) {
            if (type->path->name == P4_14::Checksum) {
                if (allowUnimplemented)
                    ::warning("Checksum translation is not yet supported.");
                else
                    P4C_UNIMPLEMENTED("Checksum translation is not yet supported.");
            }
        }
        return node;
    }
};

class ParserCounterTranslation : public Transform {
    bool allowUnimplemented;

 public:
    explicit ParserCounterTranslation(bool allowUnimplemented = false)
    : allowUnimplemented(allowUnimplemented) {
        setName("ParserCounterTranslation");
    }
    const IR::Node* postorder(IR::Member* node) override {
        if (node->member == "packet_counter") {
            if (allowUnimplemented)
                ::warning("Parser counter translation is not yet supported.");
            else
                P4C_UNIMPLEMENTED("Parser counter translation is not yet supported.");
        }
        return node;
    }
};

class PacketPriorityTranslation : public Transform {
    bool allowUnimplemented;

 public:
    explicit PacketPriorityTranslation(bool allowUnimplemented = false)
    : allowUnimplemented(allowUnimplemented) {
        setName("PacketPriorityTranslation");
    }
    const IR::Node* postorder(IR::Member* node) override {
        if (node->member == "priority") {
            if (allowUnimplemented)
                ::warning("Packet priority translation is not yet supported.");
            else
                P4C_UNIMPLEMENTED("Packet priority translation is not yet supported.");
        }
        return node;
    }
};

// There is no syntactically valid p4 program for parser_value_set.
class ValueSetTranslation : public Transform {
 public:
    ValueSetTranslation() {
        setName("ValueSetTranslation");
    }
};


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
            param->push_back(precision->expr.at(0));
            param->push_back(new IR::BoolLiteral(two_way_notify));
            param->push_back(new IR::BoolLiteral(per_flow_enable));
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

// map index to resubmit field list
using DigestFieldMap = std::map<IR::Constant*, const IR::Expression*>;

class CollectDigestFieldLists : public Transform {
    /// map digest field list to digest table index
    DigestFieldMap* map;
    /// mirror_tbl, resub_tbl, learn_tbl indices
    /// valid between 0 and 7.
    unsigned int digestTableIndex;
    /// digest name in P14. Using a vector because we need to map
    /// multiple P14 primitives to the same P16 primitive (clone and clone3).
    std::vector<cstring> digestName;
    /// current thread (ingress / egress).
    gress_t gress;
    /// metadata name for table index in P16
    cstring metadata;
    /// argument index for field lists in P14.
    unsigned int fieldListIndex;
    P4::ClonePathExpressions cloner;

 public:
    CollectDigestFieldLists(DigestFieldMap* map,
                            std::initializer_list<cstring> name,
                            gress_t gress,
                            cstring metadata,
                            int fl_idx)
    : map(map), digestTableIndex(0), digestName(name),
      gress(gress), metadata(metadata), fieldListIndex(fl_idx) {
        CHECK_NULL(map);
        setName("CollectDigestFieldLists");
    }

    const IR::Node* postorder(IR::MethodCallStatement* node) override {
        auto mc = node->methodCall->to<IR::MethodCallExpression>();
        if (!mc) return node;

        auto expr = mc->method->to<IR::PathExpression>();
        if (!expr) return node;

        auto it = find(digestName.begin(), digestName.end(), expr->path->name);
        if (it != digestName.end()) {
            auto path = (gress == gress_t::INGRESS) ?
                        new IR::PathExpression("ig_intr_md_for_deparser") :
                        new IR::PathExpression("eg_intr_md_for_deparser");
            auto member = new IR::Member(path, metadata);
            auto value = new IR::Constant(new IR::Type_Bits(3, false), digestTableIndex++);
            auto stmt = new IR::AssignmentStatement(member, value);
            if (mc->arguments->size() > fieldListIndex) {
                auto fieldList = mc->arguments->at(fieldListIndex);
                auto clonedFieldList = fieldList->apply(cloner);
                map->emplace(value, clonedFieldList);
            } else {
                map->emplace(value, mc);
            }
            return stmt;
        }
        return node;
    }
};

class DoMirrorTranslation : public Transform {
    DigestFieldMap* map;
    gress_t gress;

 public:
    DoMirrorTranslation(DigestFieldMap* map, gress_t gress)
            : map(map), gress(gress) {
        setName("DoMirrorTranslation");
    }

    /*
     * generate statement in ingress/egress deparser to prepend mirror metadata
     * if (ig_intr_md_for_dprsr.mirror_idx == N)
     *    mirror.add_metadata({});
     */
    const IR::StatOrDecl* genMirrorStatement(cstring metaName, const IR::Constant* idx,
                                             const IR::Expression* expr) {
        auto path = new IR::Path("mirror");
        auto pathExpr = new IR::PathExpression(path);
        auto args = new IR::Vector<IR::Expression>();
        if (auto fieldList = expr->to<IR::ListExpression>())
            args->push_back(fieldList);
        auto member = new IR::Member(pathExpr, "add_metadata");
        auto typeArgs = new IR::Vector<IR::Type>();
        auto mce = new IR::MethodCallExpression(member, typeArgs, args);
        auto mcs = new IR::MethodCallStatement(mce);

        auto condExprPath = new IR::Member(
                new IR::PathExpression(new IR::Path(metaName)),
                "mirror_idx");
        auto condExpr = new IR::Equ(condExprPath, idx);
        auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
        return cond;
    }

    const IR::P4Control* genP4Control(const IR::P4Control* control, gress_t gress) {
        auto stmts = new IR::IndexedVector<IR::StatOrDecl>();
        if (gress == gress_t::INGRESS) {
            for (auto it : *map) {
                auto stmt = genMirrorStatement("ig_intr_md_for_dprsr", it.first, it.second);
                stmts->push_back(stmt);
            }
        } else if (gress == gress_t::EGRESS) {
            for (auto it : *map) {
                auto stmt = genMirrorStatement("eg_intr_md_for_dprsr", it.first, it.second);
                stmts->push_back(stmt);
            }
        }
        // append other statements
        for (auto st : control->body->components) {
            stmts->push_back(st);
        }
        auto body = new IR::BlockStatement(control->body->srcInfo, *stmts);
        return new IR::P4Control(control->srcInfo, control->name,
                                 control->type, control->constructorParams,
                                 control->controlLocals, body);
    }

    const IR::Node* postorder(IR::P4Control* control) override {
        if (control->name == "IngressDeparserImpl" && gress == gress_t::INGRESS) {
            return genP4Control(control, gress_t::INGRESS);
        } else if (control->name == "DeparserImpl" && gress == gress_t::EGRESS) {
            return genP4Control(control, gress_t::EGRESS);
        }
        return control;
    }
};

class MirrorTranslation : public PassManager {
    DigestFieldMap mirrorFieldLists;

 public:
    MirrorTranslation() {
        addPasses({
            new CollectDigestFieldLists(&mirrorFieldLists, {"clone", "clone3"},
                                        gress_t::INGRESS, "mirror_idx",
                                        /* fieldListIndex = */ 2),
            new DoMirrorTranslation(&mirrorFieldLists, gress_t::INGRESS),
            new CollectDigestFieldLists(&mirrorFieldLists, {"clone", "clone3"},
                                        gress_t::EGRESS, "mirror_idx",
                                        /* fieldListIndex = */ 2),
            new DoMirrorTranslation(&mirrorFieldLists, gress_t::EGRESS),
        });
        setName("MirrorTranslation");
    }
};

class DoResubmitTranslation : public Transform {
    DigestFieldMap* map;

 public:
    explicit DoResubmitTranslation(DigestFieldMap* map) : map(map) {
        setName("DoResubmitTranslation");
    }

    const IR::Node* postorder(IR::P4Control* control) override {
        if (control->name != "IngressDeparserImpl")
            return control;

        auto stmts = new IR::IndexedVector<IR::StatOrDecl>();

        /*
         * translate resubmit() in ingress pipeline to the following code
         *
         * if (ig_intr_md_for_dprsr.resubmit_idx == n)
         *    resubmit.add_metadata({fields});
         *
         * in ingress deparser.
         */
        for (auto it : *map) {
            auto path = new IR::Path("resubmit");
            auto expr = new IR::PathExpression(path);
            auto args = new IR::Vector<IR::Expression>();
            if (auto fieldList = it.second->to<IR::ListExpression>())
                args->push_back(fieldList);
            auto member = new IR::Member(expr, "add_metadata");
            auto typeArgs = new IR::Vector<IR::Type>();
            auto mce = new IR::MethodCallExpression(member, typeArgs, args);
            auto mcs = new IR::MethodCallStatement(mce);

            auto condExprPath = new IR::Member(
                    new IR::PathExpression(new IR::Path("ig_intr_md_for_dprsr")),
                    "resubmit_idx");
            auto condExpr = new IR::Equ(condExprPath, it.first);
            auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
            stmts->push_back(cond);
        }
        // append other statements
        for (auto st : control->body->components) {
            stmts->push_back(st);
        }
        auto body = new IR::BlockStatement(control->body->srcInfo, *stmts);
        auto result = new IR::P4Control(control->srcInfo, control->name,
                                        control->type, control->constructorParams,
                                        control->controlLocals, body);
        return result;
    }
};

class ResubmitTranslation : public PassManager {
    DigestFieldMap resubmitFieldLists;

 public:
    ResubmitTranslation() {
        addPasses({
            new CollectDigestFieldLists(&resubmitFieldLists, {"resubmit"},
                                        gress_t::INGRESS, "resubmit_idx",
                                        /* fieldListIndex = */ 0),
            new DoResubmitTranslation(&resubmitFieldLists),
        });
        setName("ResubmitTranslation");
    }
};

class DoDigestTranslation : public Transform {
    DigestFieldMap* map;

 public:
    explicit DoDigestTranslation(DigestFieldMap* map) : map(map) {
        setName("DoDigestTranslation");
    }
    const IR::Node* postorder(IR::P4Control* control) override {
        if (control->name != "IngressDeparserImpl")
            return control;
        auto stmts = new IR::IndexedVector<IR::StatOrDecl>();
        /*
         * translate digest() in ingress pipeline to the following code
         *
         * if (ig_intr_md_for_dprsr.learn_idx == n)
         *    learn.add_metadata({fields});
         *
         * in ingress deparser.
         */
        for (auto it : *map) {
            auto path = new IR::Path("learn");
            auto expr = new IR::PathExpression(path);
            auto args = new IR::Vector<IR::Expression>();
            if (auto fieldList = it.second->to<IR::ListExpression>())
                args->push_back(fieldList);
            auto member = new IR::Member(expr, "add_metadata");
            auto typeArgs = new IR::Vector<IR::Type>();
            auto mce = new IR::MethodCallExpression(member, typeArgs, args);
            auto mcs = new IR::MethodCallStatement(mce);

            auto condExprPath = new IR::Member(
                    new IR::PathExpression(new IR::Path("ig_intr_md_for_dprsr")),
                    "learn_idx");
            auto condExpr = new IR::Equ(condExprPath, it.first);
            auto cond = new IR::IfStatement(condExpr, mcs, nullptr);
            stmts->push_back(cond);
        }
        // append other statements
        for (auto st : control->body->components) {
            stmts->push_back(st);
        }
        auto body = new IR::BlockStatement(control->body->srcInfo, *stmts);
        auto result = new IR::P4Control(control->srcInfo, control->name,
                                        control->type, control->constructorParams,
                                        control->controlLocals, body);
        return result;
    }
};

class DigestTranslation : public PassManager {
    DigestFieldMap resubmitFieldLists;
 public:
    DigestTranslation() {
        addPasses({
            new CollectDigestFieldLists(&resubmitFieldLists, {"digest"},
                                        gress_t::INGRESS, "learn_idx",
                                        /* fieldListIndex = */ 1),
            new DoResubmitTranslation(&resubmitFieldLists),
        });
        setName("DigestTranslation");
    }
};

class TranslationLast : public PassManager {
 public:
    TranslationLast() { setName("TranslationLast"); }
};

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

using MetadataMap = ordered_map<cstring, IR::MetadataInfo*>;
class SetupMetadataMap : public Inspector {
    MetadataMap* translationMap;

 public:
    explicit SetupMetadataMap(MetadataMap* map)
        : translationMap(map) { setName("SetupMetadataMap"); }

    void remap_ingress_intrinsic_metadata(cstring key, cstring inst, cstring name) {
        auto metainfo = new IR::MetadataInfo(false, gress_t::INGRESS,
                                             P4_16::IngressIntrinsics, inst, name);
        translationMap->emplace(key, metainfo);
    }

    void remap_egress_intrinsic_metadata(cstring key, cstring inst, cstring name) {
        auto metainfo = new IR::MetadataInfo(false, gress_t::EGRESS,
                                             P4_16::EgressIntrinsics, inst, name);
        translationMap->emplace(key, metainfo);
    }

    void remap_ingress_parser_metadata(cstring key, cstring inst, cstring name) {
        auto metainfo = new IR::MetadataInfo(false, gress_t::INGRESS,
                                             P4_16::IngressIntrinsicsFromParser, inst, name);
        translationMap->emplace(key, metainfo);
    }

    void remap_egress_parser_metadata(cstring key, cstring inst, cstring name) {
        auto metainfo = new IR::MetadataInfo(false, gress_t::EGRESS,
                                             P4_16::EgressIntrinsicsFromParser, inst, name);
        translationMap->emplace(key, metainfo);
    }

    // XXX(hanw): split to two maps: ingress and egress
    profile_t init_apply(const IR::Node* root) {
        // ingress
        remap_ingress_intrinsic_metadata("ingress::ingress_port", "ig_intr_md", "ingress_port");
        remap_ingress_intrinsic_metadata("ingress::resubmit_flag", "ig_intr_md", "resubmit_flag");
        remap_ingress_intrinsic_metadata("ingress::egress_spec", "ig_intr_md_for_tm",
                                         "ucast_egress_port");
        remap_ingress_parser_metadata("ingress::ingress_parser_err",
                                      "ig_intr_md_from_parser", "ingress_parser_err");
        remap_ingress_intrinsic_metadata("ingress::instance_type", "ig_intr_md", "instance_type");
        remap_ingress_parser_metadata("ingress::ingress_global_tstamp",
                                      "ig_intr_md_from_parser", "ingress_global_tstamp");

        // egress
        remap_egress_intrinsic_metadata("egress::egress_port", "eg_intr_md", "egress_port");
        remap_egress_parser_metadata("egress::egress_parser_err",
                                     "eg_intr_md_from_parser", "egress_parser_err");
        remap_egress_intrinsic_metadata("egress::instance_type", "eg_intr_md", "instance_type");
        remap_egress_intrinsic_metadata("egress::clone_src", "eg_intr_md", "clone_src");

        // parser metadata
        remap_ingress_intrinsic_metadata("parser::ingress_port", "ig_intr_md", "ingress_port");
        remap_ingress_intrinsic_metadata("parser::packet_length", "ig_intr_md", "packet_legnth");

        auto rv = Inspector::init_apply(root);
        return rv;
    }
};

class DoMetadataTranslation : public Transform {
    SimpleSwitchTranslation* translator;
    MetadataMap* translationMap;

 public:
    DoMetadataTranslation(SimpleSwitchTranslation* translator, MetadataMap* map)
    : translator(translator), translationMap(map) { setName("DoMetadataTranslation"); }

    BlockType getInstantiatedBlockType() {
        auto blk = translator->getToplevelBlock();
        auto control = findOrigCtxt<IR::P4Control>();
        if (control) {
            auto ingress = translator->getIngress(blk);
            if (*ingress == *control) {
                return BlockType::Ingress;
            }
            auto egress = translator->getEgress(blk);
            if (*egress == *control) {
                return BlockType::Egress;
            }
        }
        auto p4parser = findOrigCtxt<IR::P4Parser>();
        if (p4parser) {
            auto parser = translator->getParser(blk);
            if (*p4parser == *parser) {
                return BlockType::Parser;
            }
        }
        return BlockType::Unknown;
    }

    const IR::Member* translate(const IR::Member* mem) {
        auto blockType = getInstantiatedBlockType();
        auto metadata = cstring::to_cstring(blockType) + "::" + mem->member;
        if (translationMap->count(metadata) == 0) return mem;
        auto &to = translationMap->at(metadata);
        auto expr = new IR::PathExpression(to->instance_name);
        auto result = new IR::Member(mem->srcInfo, expr, to->field_name);
        LOG3("map " << mem << " to " << result);
        return result;
    }

    const IR::Node* postorder(IR::Member* mem) override {
        auto submem = mem->expr->to<IR::Member>();
        if (submem) {
            auto name = submem->member.name;
            if (name == P4_14::StandardMetadata) {
               return translate(mem);
            } else if (name == P4_14::IntrinsicMetadataForTM) {
                return translate(mem);
            } else if (name == P4_14::IngressIntrinsicMetadataFromParser) {
                return translate(mem);
            } else if (name == P4_14::EgressIntrinsicMetadataFromParser) {
                return translate(mem);
            }
        }
        auto expr = mem->expr->to<IR::PathExpression>();
        if (expr) {
            auto path = expr->path->to<IR::Path>();
            if (!path)
                return mem;
            if (path->name == P4_14::StandardMetadata) {
                return translate(mem);
            } else if (path->name == P4_14::IntrinsicMetadataForTM) {
                return translate(mem);
            }
            return mem;
        }
        return mem;
    }

    const IR::Node* preorder(IR::P4Control* node) override {
        auto blk = translator->getToplevelBlock();
        auto ingress = translator->getIngress(blk);
        auto params = node->type->getApplyParameters();

        if (*ingress == *node) {
            BUG_CHECK(params->size() == 3, "%1% Expected 3 parameters for ingress", ingress);
            auto paramList = new IR::ParameterList({node->type->applyParams->parameters.at(0),
                                                    node->type->applyParams->parameters.at(1)});
            // add ig_intr_md
            auto path = new IR::Path(P4_16::IngressIntrinsics);
            auto type = new IR::Type_Name(path);
            auto param = new IR::Parameter("ig_intr_md", IR::Direction::In, type);
            paramList->push_back(param);

            // add ig_intr_md_from_prsr
            path = new IR::Path(P4_16::IngressIntrinsicsFromParser);
            type = new IR::Type_Name(path);
            param = new IR::Parameter("ig_intr_md_from_parser", IR::Direction::In, type);
            paramList->push_back(param);

            // add ig_intr_md_for_tm
            path = new IR::Path(P4_16::IngressIntrinsicsForTM);
            type = new IR::Type_Name(path);
            param = new IR::Parameter("ig_intr_md_for_tm", IR::Direction::Out, type);
            paramList->push_back(param);

            // add ig_intr_md_for_mb
            path = new IR::Path(P4_16::IngressIntrinsicsForMirror);
            type = new IR::Type_Name(path);
            param = new IR::Parameter("ig_intr_md_for_mb", IR::Direction::Out, type);
            paramList->push_back(param);

            // add ig_intr_md_for_dprsr
            path = new IR::Path(P4_16::IngressIntrinsicsForDeparser);
            type = new IR::Type_Name(path);
            param = new IR::Parameter("ig_intr_md_for_deparser", IR::Direction::Out, type);
            paramList->push_back(param);

            auto control_type = new IR::Type_Control(node->name, paramList);

            auto result = new IR::P4Control(node->srcInfo, node->name, control_type,
                                            node->constructorParams, node->controlLocals,
                                            node->body);
            return result;
        }

        auto egress = translator->getEgress(blk);
        if (*egress == *node) {
            BUG_CHECK(params->size() == 3, "%1% Expected 3 parameters for egress", egress);
            auto paramList = new IR::ParameterList({node->type->applyParams->parameters.at(0),
                                                    node->type->applyParams->parameters.at(1)});
            // add eg_intr_md
            auto path = new IR::Path(P4_16::EgressIntrinsics);
            auto type = new IR::Type_Name(path);
            auto param = new IR::Parameter("eg_intr_md", IR::Direction::In, type);
            paramList->push_back(param);

            // add eg_intr_md_from_prsr
            path = new IR::Path(P4_16::EgressIntrinsicsFromParser);
            type = new IR::Type_Name(path);
            param = new IR::Parameter("eg_intr_md_from_parser", IR::Direction::In, type);
            paramList->push_back(param);

            // add eg_intr_md_for_mb
            path = new IR::Path(P4_16::EgressIntrinsicsForMirror);
            type = new IR::Type_Name(path);
            param = new IR::Parameter("eg_intr_md_for_mb", IR::Direction::Out, type);
            paramList->push_back(param);

            // add eg_intr_md_for_oport
            path = new IR::Path(P4_16::EgressIntrinsicsForOutputPort);
            type = new IR::Type_Name(path);
            param = new IR::Parameter("eg_intr_md_for_oport", IR::Direction::Out, type);
            paramList->push_back(param);

            auto control_type = new IR::Type_Control(node->name, paramList);

            auto result = new IR::P4Control(node->srcInfo, node->name, control_type,
                                            node->constructorParams, node->controlLocals,
                                            node->body);
            return result;
        }
        return node;
    }

    const IR::Node* preorder(IR::P4Parser* node) override {
        auto blk = translator->getToplevelBlock();
        auto parser = translator->getParser(blk);
        auto params = node->type->getApplyParameters();
        if (*parser == *node) {
            BUG_CHECK(params->size() == 4, "%1%: Expected 4 parameters for parser", parser);
            auto paramList = new IR::ParameterList({node->type->applyParams->parameters.at(0),
                                                    node->type->applyParams->parameters.at(1),
                                                    node->type->applyParams->parameters.at(2)});
            // add ig_intr_md
            auto path = new IR::Path(P4_16::IngressIntrinsics);
            auto type = new IR::Type_Name(path);
            auto param = new IR::Parameter("ig_intr_md", IR::Direction::Out, type);
            paramList->push_back(param);

            auto parser_type = new IR::Type_Parser(node->name, paramList);

            auto result = new IR::P4Parser(node->srcInfo, node->name, parser_type,
                                           node->constructorParams, node->parserLocals,
                                           node->states);
            return result;
        } else {
            /// assume we are dealing with egress parser
            BUG_CHECK(params->size() == 4, "%1%: Expected 4 parameters for parser", parser);
            auto paramList = new IR::ParameterList({node->type->applyParams->parameters.at(0),
                                                    node->type->applyParams->parameters.at(1),
                                                    node->type->applyParams->parameters.at(2)});
            // add ig_intr_md
            auto path = new IR::Path(P4_16::EgressIntrinsics);
            auto type = new IR::Type_Name(path);
            auto param = new IR::Parameter("eg_intr_md", IR::Direction::Out, type);
            paramList->push_back(param);
            auto parser_type = new IR::Type_Parser(node->name, paramList);
            auto result = new IR::P4Parser(node->srcInfo, node->name, parser_type,
                                           node->constructorParams, node->parserLocals,
                                           node->states);
            return result;
        }
        return node;
    }
};

/**
 * This pass translates standard_metadata_t to [ingress/egress]_intrinsic_metadata_t.
 * It also translates the path to member of standard_metadata_t to the corresponding
 * member in intrinsic metadata.
 *
 * @pre: assume no Transform pass between the most recent EvaluatorPass and this pass.
 *      i.e., no modification is applied to the IR tree, and pointer equality is
 *      sufficient to check equality.
 * @post: standard_metadata_t in control block parameters and reference to
 *      standard_metadata fields are translated to tofino intrinsic metadata.
 */
class MetadataTranslation : public PassManager {
    MetadataMap translationMap;

 public:
    explicit MetadataTranslation(SimpleSwitchTranslation* translator) {
        addPasses({
            new SetupMetadataMap(&translationMap),
            new DoMetadataTranslation(translator, &translationMap),
        });
    }
};

/// package translation creates ingress deparser and egress parser
/// XXX(hanw): do we add bridge metadata in this pass?

class PackageTranslation : public Transform {
    SimpleSwitchTranslation* translator;
    IR::P4Control* ingressDeparser;
    IR::P4Parser*  egressParser;

 public:
    explicit PackageTranslation(SimpleSwitchTranslation* translator)
    : translator(translator) { CHECK_NULL(translator); setName("PackageTranslation"); }

    const IR::Node* preorder(IR::P4Control* node) override {
        auto blk = translator->getToplevelBlock();
        auto deparser = translator->getDeparser(blk);
        auto parser = translator->getParser(blk);
        if (*deparser == *node) {
            ingressDeparser = deparser->clone();
            ingressDeparser->name = "IngressDeparserImpl";
            auto controlType = ingressDeparser->type->to<IR::Type_Control>();
            CHECK_NULL(controlType);
            auto paramList = new IR::ParameterList({node->type->applyParams->parameters.at(0),
                                                    node->type->applyParams->parameters.at(1)});
            // add metadata
            auto meta = parser->type->applyParams->parameters.at(2);
            auto param = new IR::Parameter(meta->name, meta->annotations,
                                           IR::Direction::In, meta->type);
            paramList->push_back(param);

            // add deparser intrinsic metadata
            auto path = new IR::Path("ingress_intrinsic_metadata_for_deparser_t");
            auto type = new IR::Type_Name(path);
            param = new IR::Parameter("ig_intr_md_for_dprsr", IR::Direction::In, type);
            paramList->push_back(param);

            // add mirror
            path = new IR::Path("mirror_packet");
            type = new IR::Type_Name(path);
            param = new IR::Parameter("mirror", IR::Direction::None, type);
            paramList->push_back(param);

            // add resubmit
            path = new IR::Path("resubmit_packet");
            type = new IR::Type_Name(path);
            param = new IR::Parameter("resubmit", IR::Direction::None, type);
            paramList->push_back(param);

            auto typeControl = new IR::Type_Control(controlType->srcInfo, ingressDeparser->name,
                                             controlType->annotations, controlType->typeParameters,
                                             paramList);
            ingressDeparser->type = typeControl;
        }
        return node;
    }

    const IR::Node* preorder(IR::P4Parser* node) override {
        auto blk = translator->getToplevelBlock();
        auto parser = translator->getParser(blk);
        if (*parser == *node) {
            egressParser = parser->clone();
            egressParser->name = "EgressParserImpl";
            auto parserType = egressParser->type->to<IR::Type_Parser>();
            CHECK_NULL(parserType);
            auto type = new IR::Type_Parser(parserType->srcInfo, egressParser->name,
                                            parserType->annotations, parserType->typeParameters,
                                            parserType->applyParams);
            egressParser->type = type;
        }
        return node;
    }

    const IR::Node* postorder(IR::Declaration_Instance* node) override {
        if (node->name != "main")
            return node;

        // Switch<H, M, H, M>
        auto mainBaseType = new IR::Type_Name("Switch");
        auto mainArgsType = node->type->to<IR::Type_Specialized>();
        BUG_CHECK(mainArgsType != nullptr, "Unexpected type for main");
        auto mainArgs = new IR::Vector<IR::Type>({mainArgsType->arguments->at(0),
                                                  mainArgsType->arguments->at(1),
                                                  mainArgsType->arguments->at(0),
                                                  mainArgsType->arguments->at(1)});
        auto mainType = new IR::Type_Specialized(mainBaseType, mainArgs);

        CHECK_NULL(ingressDeparser);
        CHECK_NULL(egressParser);
        auto igDepConstructorType = new IR::Type_Name(ingressDeparser->type->name);
        auto igDep = new IR::ConstructorCallExpression(igDepConstructorType,
                                                       new IR::Vector<IR::Expression>());
        auto egParConstructorType = new IR::Type_Name(egressParser->type->name);
        auto egPar = new IR::ConstructorCallExpression(egParConstructorType,
                                                       new IR::Vector<IR::Expression>());
        // Switch<H, M, H, M>(parser, gress, deparser, ...)
        auto arguments = new IR::Vector<IR::Expression>({ node->arguments->at(0),
                                                          node->arguments->at(2),
                                                          igDep,
                                                          egPar,
                                                          node->arguments->at(3),
                                                          node->arguments->at(5)});
        auto result = new IR::Declaration_Instance(node->srcInfo, node->name,
                                                   node->annotations, mainType,
                                                   arguments);
        return result;
    }

    const IR::Node* postorder(IR::P4Program* program) override {
        // add new parser.
        // add new deparser.
        CHECK_NULL(ingressDeparser);
        CHECK_NULL(egressParser);

        IR::IndexedVector<IR::Node> program_declarations;
        for (auto decl : program->declarations) {
            if (auto inst = decl->to<IR::Declaration_Instance>()) {
                if (inst->name == "main") {
                    program_declarations.push_back(ingressDeparser);
                    program_declarations.push_back(egressParser);
                }
            }
            program_declarations.push_back(decl);
        }
        return new IR::P4Program(program->srcInfo, program_declarations);
    }
};

SimpleSwitchTranslation::SimpleSwitchTranslation(P4::ReferenceMap* refMap,
                                                 P4::TypeMap* typeMap, BFN_Options& options) {
    setName("Translation");
    BFN::Target target = BFN::Target::Unknown;
    if (options.target == "tofino-v1model-barefoot")
        target = BFN::Target::Simple;
    else if (options.target == "tofino-native-barefoot")
        target = BFN::Target::Tofino;
    addDebugHook(options.getDebugHook());
    auto evaluator = new P4::EvaluatorPass(refMap, typeMap);
    addPasses({
        new P4::TypeChecking(refMap, typeMap, true),
        evaluator,
        new VisitFunctor([this, evaluator]() { toplevel = evaluator->getToplevelBlock(); }),
        new PackageTranslation(this),
        new VisitFunctor([this, evaluator]() { toplevel = evaluator->getToplevelBlock(); }),
        new MetadataTranslation(this),
        new RemoveUserArchitecture(&structure, target),
        new CleanP14V1model(),
        new DoCounterTranslation(),
        new DoMeterTranslation(refMap, typeMap),
        new RandomTranslation(),
        new HashTranslation(),
        new ChecksumTranslation(options.allowUnimplemented),
        new ParserCounterTranslation(options.allowUnimplemented),
        new PacketPriorityTranslation(options.allowUnimplemented),
        new ValueSetTranslation(),
        new IdleTimeoutTranslation(),
        new MirrorTranslation(),
        new DigestTranslation(),
        new ResubmitTranslation(),
        new AppendSystemArchitecture(&structure),
        new TranslationLast(),
        new P4::ClearTypeMap(typeMap),
        new P4::TypeChecking(refMap, typeMap, false),
    });
}

}  // namespace BFN
