#include <boost/optional.hpp>

#include <iostream>
#include <set>
#include <unordered_map>
#include <vector>

#include "bf-p4c/control-plane/bfruntime.h"
#include "bf-p4c/control-plane/tofino_p4runtime.h"

#include "barefoot/p4info.pb.h"
#include "bf-p4c/bf-p4c-options.h"
#include "control-plane/p4RuntimeArchHandler.h"
#include "control-plane/p4RuntimeSerializer.h"
#include "control-plane/typeSpecConverter.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/externInstance.h"
#include "frontends/p4/methodInstance.h"
#include "frontends/p4/typeMap.h"
#include "lib/nullstream.h"
#include "p4/config/v1/p4info.pb.h"

using P4::ControlPlaneAPI::P4RuntimeSymbolTableIface;
using P4::ControlPlaneAPI::P4RuntimeSymbolType;
using P4::ControlPlaneAPI::p4rt_id_t;
using P4::ControlPlaneAPI::TypeSpecConverter;

using P4::ReferenceMap;
using P4::TypeMap;

namespace p4configv1 = ::p4::config::v1;

namespace BFN {

/// Tofino counter extern type
struct CounterExtern { };
/// Tofino meter extern type
struct MeterExtern { };

}  // namespace BFN

namespace P4 {

namespace ControlPlaneAPI {

namespace Helpers {

/// CounterlikeTraits<> specialization for CounterExtern
template<> struct CounterlikeTraits<::BFN::CounterExtern> {
    static const cstring name() { return "counter"; }
    static const cstring directPropertyName() {
        return "counters";
    }
    static const cstring typeName() {
        return "Counter";
    }
    static const cstring directTypeName() {
        return "DirectCounter";
    }
    static const cstring sizeParamName() {
        return "size";
    }
    static ::barefoot::CounterSpec::Unit mapUnitName(const cstring name) {
        using ::barefoot::CounterSpec;
        if (name == "PACKETS") return CounterSpec::PACKETS;
        else if (name == "BYTES") return CounterSpec::BYTES;
        else if (name == "PACKETS_AND_BYTES") return CounterSpec::PACKETS_AND_BYTES;
        return CounterSpec::UNSPECIFIED;
    }
};

/// CounterlikeTraits<> specialization for MeterExtern
template<> struct CounterlikeTraits<::BFN::MeterExtern> {
    static const cstring name() { return "meter"; }
    static const cstring directPropertyName() {
        return "meters";
    }
    static const cstring typeName() {
        return "Meter";
    }
    static const cstring directTypeName() {
        return "DirectMeter";
    }
    static const cstring sizeParamName() {
        return "size";
    }
    static ::barefoot::MeterSpec::Unit mapUnitName(const cstring name) {
        using ::barefoot::MeterSpec;
        if (name == "PACKETS") return MeterSpec::PACKETS;
        else if (name == "BYTES") return MeterSpec::BYTES;
        return MeterSpec::UNSPECIFIED;
    }
};

}  // namespace Helpers

}  // namespace ControlPlaneAPI

}  // namespace P4

namespace Helpers = P4::ControlPlaneAPI::Helpers;

namespace BFN {

/// Extends P4RuntimeSymbolType for the Tofino extern types.
class SymbolType final : public P4RuntimeSymbolType {
 public:
    SymbolType() = delete;

    static P4RuntimeSymbolType ACTION_PROFILE() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::ACTION_PROFILE);
    }
    static P4RuntimeSymbolType ACTION_SELECTOR() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::ACTION_SELECTOR);
    }
    static P4RuntimeSymbolType COUNTER() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::COUNTER);
    }
    static P4RuntimeSymbolType DIRECT_COUNTER() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::DIRECT_COUNTER);
    }
    static P4RuntimeSymbolType METER() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::METER);
    }
    static P4RuntimeSymbolType DIRECT_METER() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::DIRECT_METER);
    }
    static P4RuntimeSymbolType DIGEST() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::DIGEST);
    }
    static P4RuntimeSymbolType REGISTER() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::REGISTER);
    }
    static P4RuntimeSymbolType PORT_METADATA() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::PORT_METADATA);
    }
    static P4RuntimeSymbolType LPF() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::LPF);
    }
    static P4RuntimeSymbolType DIRECT_LPF() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::DIRECT_LPF);
    }
    static P4RuntimeSymbolType WRED() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::WRED);
    }
    static P4RuntimeSymbolType DIRECT_WRED() {
        return P4RuntimeSymbolType::make(barefoot::P4Ids::DIRECT_WRED);
    }
};

/// The information about an action profile which is necessary to generate its
/// serialized representation.
struct ActionProfile {
    const cstring name;  // The fully qualified external name of this action profile.
    const P4RuntimeSymbolType type;  // ACTION_PROFILE or ACTION_SELECTOR
    const int64_t size;
    const IR::IAnnotated* annotations;  // If non-null, any annotations applied to this action
                                        // profile declaration.

    p4rt_id_t getId(const P4RuntimeSymbolTableIface& symbols) const {
        return symbols.getId(type, name);
    }
};

/// The information about a digest instance which is needed to serialize it.
struct Digest {
    const cstring name;       // The fully qualified external name of the digest
    const p4configv1::P4DataTypeSpec* typeSpec;  // The format of the packed data.
    const IR::IAnnotated* annotations;  // If non-null, any annotations applied to this digest
                                        // declaration.
};

/// The information about a register instance which is needed to serialize it.
struct Register {
    const cstring name;       // The fully qualified external name of the register
    const p4configv1::P4DataTypeSpec* typeSpec;  // The format of the packed data.
    int64_t size;
    const IR::IAnnotated* annotations;  // If non-null, any annotations applied to this register
                                        // declaration.

    /// @return the information required to serialize an @instance of register
    /// or boost::none in case of error.
    static boost::optional<Register>
    from(const IR::ExternBlock* instance,
         const ReferenceMap* refMap,
         const TypeMap* typeMap,
         p4configv1::P4TypeInfo* p4RtTypeInfo) {
        CHECK_NULL(instance);
        auto declaration = instance->node->to<IR::Declaration_Instance>();

        auto size = instance->getParameterValue("size");

        // retrieve type parameter for the register instance and convert it to P4DataTypeSpec
        BUG_CHECK(declaration->type->is<IR::Type_Specialized>(),
                  "%1%: expected Type_Specialized", declaration->type);
        auto type = declaration->type->to<IR::Type_Specialized>();
        BUG_CHECK(type->arguments->size() == 1,
                  "%1%: expected one type argument", instance);
        auto typeArg = type->arguments->at(0);
        auto typeSpec = TypeSpecConverter::convert(typeMap, refMap, typeArg, p4RtTypeInfo);
        CHECK_NULL(typeSpec);

        return Register{declaration->controlPlaneName(),
                        typeSpec,
                        size->to<IR::Constant>()->asInt(),
                        declaration->to<IR::IAnnotated>()};
    }

    /// @return the information required to serialize an @instance of a direct
    /// register or boost::none in case of error.
    static boost::optional<Register>
    fromDirect(const P4::ExternInstance& instance,
               const IR::P4Table* table,
               // Instantiation::resolve does not declare parameters as const
               /* const */ ReferenceMap* refMap,
               /* const */ TypeMap* typeMap,
               p4configv1::P4TypeInfo* p4RtTypeInfo) {
        CHECK_NULL(table);
        BUG_CHECK(instance.name != boost::none,
                  "Caller should've ensured we have a name");

        auto size = instance.substitution.lookupByName("size")->expression;
        // An extern constructor parameter is a compile-time value as per the P4
        // spec. "size" is therefore a bit<32> conmpile-time value.
        BUG_CHECK(size->is<IR::Constant>(), "Non-constant size");
        if (size->to<IR::Constant>()->asInt() != 0) {
            ::error("Direct register '%1%' has a non-zero size", instance.expression);
            return boost::none;
        }

        // retrieve type parameter for the register instance and convert it to P4DataTypeSpec
        if (!instance.expression->is<IR::PathExpression>()) {
            return boost::none;
        }
        auto path = instance.expression->to<IR::PathExpression>()->path;
        auto decl = refMap->getDeclaration(path, true);
        auto instantiation = P4::Instantiation::resolve(
            decl->to<IR::Declaration_Instance>(), refMap, typeMap);

        BUG_CHECK(instantiation->typeArguments->size() == 1,
                  "%1%: expected one type argument", instance.expression);
        auto typeArg = instantiation->typeArguments->at(0);
        auto typeSpec = TypeSpecConverter::convert(typeMap, refMap, typeArg, p4RtTypeInfo);
        CHECK_NULL(typeSpec);

        return Register{*instance.name, typeSpec, 0, instance.annotations};
    }
};

/// The information about a LPF instance which is needed to serialize it.
struct Lpf {
    const cstring name;       // The fully qualified external name of the filter
    int64_t size;
    /// If not none, the instance is a direct resource associated with @table.
    const boost::optional<cstring> table;
    const IR::IAnnotated* annotations;  // If non-null, any annotations applied to this Lpf
                                        // declaration.

    /// @return the information required to serialize an @instance of Lpf or
    /// boost::none in case of error.
    static boost::optional<Lpf>
    from(const IR::ExternBlock* instance) {
        CHECK_NULL(instance);
        auto declaration = instance->node->to<IR::Declaration_Instance>();

        auto size = instance->getParameterValue("size");

        return Lpf{declaration->controlPlaneName(),
                   size->to<IR::Constant>()->asInt(),
                   boost::none,
                   declaration->to<IR::IAnnotated>()};
    }

    /// @return the information required to serialize an @instance of a direct
    /// Lpf or boost::none in case of error.
    static boost::optional<Lpf>
    fromDirect(const P4::ExternInstance& instance,
               const IR::P4Table* table) {
        CHECK_NULL(table);
        BUG_CHECK(instance.name != boost::none,
                  "Caller should've ensured we have a name");
        return Lpf{*instance.name, 0, table->controlPlaneName(), instance.annotations};
    }
};

/// The information about a Wred instance which is needed to serialize it.
struct Wred {
    const cstring name;       // The fully qualified external name of the filter
    uint8_t dropValue;
    uint8_t noDropValue;
    int64_t size;
    /// If not none, the instance is a direct resource associated with @table.
    const boost::optional<cstring> table;
    const IR::IAnnotated* annotations;  // If non-null, any annotations applied to this wred
                                        // declaration.

    /// @return the information required to serialize an @instance of Wred or
    /// boost::none in case of error.
    static boost::optional<Wred>
    from(const IR::ExternBlock* instance) {
        CHECK_NULL(instance);
        auto declaration = instance->node->to<IR::Declaration_Instance>();

        auto size = instance->getParameterValue("size");
        auto dropValue = instance->getParameterValue("drop_value");
        auto noDropValue = instance->getParameterValue("no_drop_value");

        return Wred{declaration->controlPlaneName(),
                    static_cast<uint8_t>(dropValue->to<IR::Constant>()->asUnsigned()),
                    static_cast<uint8_t>(noDropValue->to<IR::Constant>()->asUnsigned()),
                    size->to<IR::Constant>()->asInt(),
                    boost::none,
                    declaration->to<IR::IAnnotated>()};
    }

    /// @return the information required to serialize an @instance of a direct
    /// Wred or boost::none in case of error.
    static boost::optional<Wred>
    fromDirect(const P4::ExternInstance& instance,
               const IR::P4Table* table) {
        CHECK_NULL(table);
        BUG_CHECK(instance.name != boost::none,
                  "Caller should've ensured we have a name");

        auto dropValue = instance.substitution.lookupByName("drop_value")->expression;
        BUG_CHECK(dropValue->to<IR::Constant>(), "Non-constant drop_value");
        auto noDropValue = instance.substitution.lookupByName("no_drop_value")->expression;
        BUG_CHECK(noDropValue->to<IR::Constant>(), "Non-constant no_drop_value");

        return Wred{*instance.name,
                    static_cast<uint8_t>(dropValue->to<IR::Constant>()->asUnsigned()),
                    static_cast<uint8_t>(noDropValue->to<IR::Constant>()->asUnsigned()),
                    0,
                    table->controlPlaneName(),
                    instance.annotations};
    }
};

struct PortMetadata {
  const p4configv1::P4DataTypeSpec* typeSpec;  // format of port metadata
  static const cstring name() { return "$PORT_METADATA"; }
  static p4rt_id_t id() {
      return static_cast<p4rt_id_t>(SymbolType::PORT_METADATA()) << 24;
  }
};

/// Implements @ref P4RuntimeArchHandlerIface for the Tofino architecture. The
/// overridden metods will be called by the @P4RuntimeSerializer to collect and
/// serialize Tofino-specific symbols which are exposed to the control-plane.
class P4RuntimeArchHandlerTofino final : public P4::ControlPlaneAPI::P4RuntimeArchHandlerIface {
 public:
    P4RuntimeArchHandlerTofino(ReferenceMap* refMap,
                               TypeMap* typeMap,
                               const IR::ToplevelBlock* evaluatedProgram)
        : refMap(refMap), typeMap(typeMap), evaluatedProgram(evaluatedProgram) { }

    void collectTableProperties(P4RuntimeSymbolTableIface* symbols,
                                const IR::TableBlock* tableBlock) override {
        CHECK_NULL(tableBlock);
        auto table = tableBlock->container;
        bool isConstructedInPlace = false;

        using Helpers::getExternInstanceFromProperty;

        {
            auto instance = getExternInstanceFromProperty(
                table, "implementation", refMap, typeMap, &isConstructedInPlace);
            // Only collect the symbol if the action profile / selector is
            // constructed in place. Otherwise it will be collected by
            // collectExternInstance, which will avoid duplicates.
            if (instance != boost::none) {
                if (instance->type->name != "ActionProfile" &&
                    instance->type->name != "ActionSelector") {
                    ::error("Expected an action profile or action selector: %1%",
                            instance->expression);
                } else if (instance->type->name == "ActionProfile" && isConstructedInPlace) {
                    symbols->add(SymbolType::ACTION_PROFILE(), *instance->name);
                } else if (instance->type->name == "ActionSelector" && isConstructedInPlace) {
                    symbols->add(SymbolType::ACTION_SELECTOR(), *instance->name);
                }
            }
        }
        // In TNA direct counters / meters cannot be constructed in place in the
        // table declaration because the count / execute method has to be
        // called.
    }

    void collectExternInstance(P4RuntimeSymbolTableIface* symbols,
                               const IR::ExternBlock* externBlock) override {
        CHECK_NULL(externBlock);

        auto decl = externBlock->node->to<IR::IDeclaration>();
        // Skip externs instantiated inside table declarations (as properties);
        // that should only apply to action profiles / selectors since direct
        // resources cannot be constructed in place for TNA.
        if (decl == nullptr) return;

        if (externBlock->type->name == "Counter") {
            symbols->add(SymbolType::COUNTER(), decl);
        } else if (externBlock->type->name == "DirectCounter") {
            symbols->add(SymbolType::DIRECT_COUNTER(), decl);
        } else if (externBlock->type->name == "Meter") {
            symbols->add(SymbolType::METER(), decl);
        } else if (externBlock->type->name == "DirectMeter") {
            symbols->add(SymbolType::DIRECT_METER(), decl);
        } else if (externBlock->type->name == "ActionProfile") {
            symbols->add(SymbolType::ACTION_PROFILE(), decl);
        } else if (externBlock->type->name == "ActionSelector") {
            symbols->add(SymbolType::ACTION_SELECTOR(), decl);
        } else if (externBlock->type->name == "Digest") {
            symbols->add(SymbolType::DIGEST(), decl);
        } else if (externBlock->type->name == "Register") {
            symbols->add(SymbolType::REGISTER(), decl);
        } else if (externBlock->type->name == "Lpf") {
            symbols->add(SymbolType::LPF(), decl);
        } else if (externBlock->type->name == "DirectLpf") {
            symbols->add(SymbolType::DIRECT_LPF(), decl);
        } else if (externBlock->type->name == "Wred") {
            symbols->add(SymbolType::WRED(), decl);
        } else if (externBlock->type->name == "DirectWred") {
            symbols->add(SymbolType::DIRECT_WRED(), decl);
        }
    }

    void collectExternFunction(P4RuntimeSymbolTableIface* symbols,
                               const P4::ExternFunction* externFunction) override {
        auto portMetadata = getPortMetadataExtract(externFunction, refMap, typeMap, nullptr);
        if (portMetadata) {
            if (hasUserPortMetadata) {
                // TODO(antonin): improve error message when extern added to TNA
                ::error("Cannot have multiple calls to port_metadata_extract");
                return;
            }
            hasUserPortMetadata = true;
            // It is not strictly required to update the symbol table here, but
            // I think it makes things more consistent.
            symbols->add(SymbolType::PORT_METADATA(), PortMetadata::name(), PortMetadata::id());
        }
    }

    void postCollect(const P4RuntimeSymbolTableIface& symbols) override {
        (void)symbols;

        // analyze action profiles / selectors and build a mapping from action
        // profile / selector name to the set of tables referencing them
        Helpers::forAllEvaluatedBlocks(evaluatedProgram, [&](const IR::Block* block) {
            if (!block->is<IR::TableBlock>()) return;
            auto table = block->to<IR::TableBlock>()->container;
            auto implementation = getTableImplementationName(table, refMap);
            if (implementation)
                actionProfilesRefs[*implementation].insert(table->controlPlaneName());
        });

        // Creates a set of color-aware meters by inspecting every call to the
        // execute method on each meter instance: if at least one method call
        // includes a second argument (pre-color), then the meter is
        // color-aware.
        Helpers::forAllEvaluatedBlocks(evaluatedProgram, [&](const IR::Block* block) {
            if (!block->is<IR::ExternBlock>()) return;
            auto externBlock = block->to<IR::ExternBlock>();
            if (externBlock->type->name != "Meter" && externBlock->type->name != "DirectMeter")
                return;
            auto decl = externBlock->node->to<IR::Declaration_Instance>();
            // Should not happen for TNA: direct meters cannot be constructed
            // in-place.
            CHECK_NULL(decl);
            forAllExternMethodCalls(decl, [&](const P4::ExternMethod* method) {
                auto call = method->expr;
                if (call->arguments->size() == 2) {
                    LOG3("Meter " << decl->controlPlaneName() << " is color-aware "
                         << "because of 2-argument call to execute()");
                    colorAwareMeters.insert(decl->controlPlaneName());
                }
            });
        });
    }

    void addTableProperties(const P4RuntimeSymbolTableIface& symbols,
                            p4configv1::P4Info* p4info,
                            p4configv1::Table* table,
                            const IR::TableBlock* tableBlock) override {
        CHECK_NULL(tableBlock);
        auto tableDeclaration = tableBlock->container;

        using P4::ControlPlaneAPI::Helpers::isExternPropertyConstructedInPlace;

        auto p4RtTypeInfo = p4info->mutable_type_info();

        auto implementation = getActionProfile(tableDeclaration, refMap, typeMap);
        auto directCounter = Helpers::getDirectCounterlike<CounterExtern>(
            tableDeclaration, refMap, typeMap);
        auto directMeter = Helpers::getDirectCounterlike<MeterExtern>(
            tableDeclaration, refMap, typeMap);
        auto directRegister = getDirectRegister(
            tableDeclaration, refMap, typeMap, p4RtTypeInfo);
        auto directLpf = getDirectLpf(tableDeclaration, refMap, typeMap);
        auto directWred = getDirectWred(tableDeclaration, refMap, typeMap);
        auto supportsTimeout = getSupportsTimeout(tableDeclaration);

        if (implementation) {
            auto id = implementation->getId(symbols);
            table->set_implementation_id(id);
            if (isExternPropertyConstructedInPlace(tableDeclaration, "implementation")) {
                if (implementation->type == SymbolType::ACTION_PROFILE())
                    addActionProfile(symbols, p4info, *implementation);
                else
                    addActionSelector(symbols, p4info, *implementation);
            }
        }

        // Direct resources are handled here. There is no risk to create
        // duplicates as direct resources cannot be shared across tables. We
        // could also handle those in addExternInstance but it would not be very
        // convenient to get a handle on the parent table (the parent table's id
        // is included in the P4Info message).
        if (directCounter) {
            auto id = symbols.getId(SymbolType::DIRECT_COUNTER(),
                                    directCounter->name);
            table->add_direct_resource_ids(id);
            addCounter(symbols, p4info, *directCounter);
        }

        if (directMeter) {
            auto id = symbols.getId(SymbolType::DIRECT_METER(),
                                    directMeter->name);
            table->add_direct_resource_ids(id);
            addMeter(symbols, p4info, *directMeter);
        }

        if (directRegister) {
            BUG_CHECK(directRegister->size == 0, "Direct register with non-zero size");
            auto id = symbols.getId(SymbolType::REGISTER(), directRegister->name);
            table->add_direct_resource_ids(id);
            addRegister(symbols, p4info, *directRegister);
        }

        if (directLpf) {
            auto id = symbols.getId(SymbolType::DIRECT_LPF(), directLpf->name);
            table->add_direct_resource_ids(id);
            addLpf(symbols, p4info, *directLpf);
        }

        if (directWred) {
            auto id = symbols.getId(SymbolType::DIRECT_WRED(), directWred->name);
            table->add_direct_resource_ids(id);
            addWred(symbols, p4info, *directWred);
        }

        // TODO(antonin): idle timeout will change for TNA in the future and we
        // will need to rely on P4Info table specific extensions.
        if (supportsTimeout) {
            table->set_idle_timeout_behavior(p4configv1::Table::NOTIFY_CONTROL);
        } else {
            table->set_idle_timeout_behavior(p4configv1::Table::NO_TIMEOUT);
        }
    }

    /// @return true if @table's 'idle_timeout' property exists and is
    /// true. This indicates that @table supports entry ageing.
    static bool getSupportsTimeout(const IR::P4Table* table) {
        auto timeout = table->properties->getProperty("idle_timeout");
        if (timeout == nullptr) return false;
        if (!timeout->value->is<IR::ExpressionValue>()) {
            ::error("Unexpected value %1% for idle_timeout on table %2%",
                    timeout, table);
            return false;
        }

        auto expr = timeout->value->to<IR::ExpressionValue>()->expression;
        if (!expr->is<IR::BoolLiteral>()) {
            ::error("Unexpected non-boolean value %1% for idle_timeout "
                    "property on table %2%", timeout, table);
            return false;
        }

        return expr->to<IR::BoolLiteral>()->value;
    }

    /// @return the direct register associated with @table, if it has one, or
    /// boost::none otherwise.
    static boost::optional<Register> getDirectRegister(
        const IR::P4Table* table,
        ReferenceMap* refMap,
        TypeMap* typeMap,
        p4configv1::P4TypeInfo* p4RtTypeInfo) {
        auto directRegisterInstance = Helpers::getExternInstanceFromProperty(
            table, "registers", refMap, typeMap);
        if (!directRegisterInstance) return boost::none;
        return Register::fromDirect(
            *directRegisterInstance, table, refMap, typeMap, p4RtTypeInfo);
    }

    /// @return the direct filter instance associated with @table, if it has
    /// one, or boost::none otherwise. Used as a helper for getDirectLpf and
    /// getDirectWred.
    template <typename T>
    static boost::optional<T> getDirectFilter(const IR::P4Table* table,
                                              ReferenceMap* refMap,
                                              TypeMap* typeMap,
                                              cstring filterType) {
        auto directFilterInstance = Helpers::getExternInstanceFromProperty(
            table, "filters", refMap, typeMap);
        if (!directFilterInstance) return boost::none;
        CHECK_NULL(directFilterInstance->type);
        if (directFilterInstance->type->name != filterType) return boost::none;
        return T::fromDirect(*directFilterInstance, table);
    }

    /// @return the direct Lpf instance associated with @table, if it has one,
    /// or boost::none otherwise.
    static boost::optional<Lpf> getDirectLpf(const IR::P4Table* table,
                                             ReferenceMap* refMap,
                                             TypeMap* typeMap) {
        return getDirectFilter<Lpf>(table, refMap, typeMap, "DirectLpf");
    }

    /// @return the direct Wred instance associated with @table, if it has one,
    /// or boost::none otherwise.
    static boost::optional<Wred> getDirectWred(const IR::P4Table* table,
                                               ReferenceMap* refMap,
                                               TypeMap* typeMap) {
        return getDirectFilter<Wred>(table, refMap, typeMap, "DirectWred");
    }

    void addExternInstance(const P4RuntimeSymbolTableIface& symbols,
                           p4configv1::P4Info* p4info,
                           const IR::ExternBlock* externBlock) override {
        auto decl = externBlock->node->to<IR::Declaration_Instance>();
        // Skip externs instantiated inside table declarations (constructed in
        // place as properties).
        if (decl == nullptr) return;

        using Helpers::Counterlike;
        using Helpers::CounterlikeTraits;

        auto p4RtTypeInfo = p4info->mutable_type_info();
        // Direct resources are handled by addTableProperties.
        if (externBlock->type->name == "ActionProfile") {
            auto actionProfile = getActionProfile(externBlock);
            if (actionProfile) addActionProfile(symbols, p4info, *actionProfile);
        } else if (externBlock->type->name == "ActionSelector") {
            auto actionSelector = getActionProfile(externBlock);
            if (actionSelector) addActionSelector(symbols, p4info, *actionSelector);
        } else if (externBlock->type->name == "Counter") {
            auto counter = Counterlike<CounterExtern>::from(externBlock);
            if (counter) addCounter(symbols, p4info, *counter);
        } else if (externBlock->type->name == "Meter") {
            auto meter = Counterlike<MeterExtern>::from(externBlock);
            if (meter) addMeter(symbols, p4info, *meter);
        } else if (externBlock->type->name == "Digest") {
            auto digest = getDigest(decl, p4RtTypeInfo);
            if (digest) addDigest(symbols, p4info, *digest);
        } else if (externBlock->type->name == "Register") {
            auto register_ = Register::from(externBlock, refMap, typeMap, p4RtTypeInfo);
            // skip direct registers
            if (register_ && register_->size != 0) addRegister(symbols, p4info, *register_);
        } else if (externBlock->type->name == "Lpf") {
            auto lpf = Lpf::from(externBlock);
            if (lpf) addLpf(symbols, p4info, *lpf);
        } else if (externBlock->type->name == "Wred") {
            auto wred = Wred::from(externBlock);
            if (wred) addWred(symbols, p4info, *wred);
        }
    }

    void addExternFunction(const P4RuntimeSymbolTableIface& symbols,
                           p4configv1::P4Info* p4info,
                           const P4::ExternFunction* externFunction) override {
        auto p4RtTypeInfo = p4info->mutable_type_info();
        auto portMetadata = getPortMetadataExtract(externFunction, refMap, typeMap, p4RtTypeInfo);
        if (portMetadata) addPortMetadata(symbols, p4info, *portMetadata);
    }

    /// @return serialization information for the digest() call represented by
    /// @call, or boost::none if @call is not a digest() call or is invalid.
    static boost::optional<PortMetadata>
    getPortMetadataExtract(const P4::ExternFunction* function,
                           ReferenceMap* refMap,
                           TypeMap* typeMap,
                           p4configv1::P4TypeInfo* p4RtTypeInfo) {
        (void)refMap; (void)typeMap; (void)p4RtTypeInfo;
        // TODO(antonin)
        if (function->method->name != "port_metadata_extract")
            return boost::none;
        return boost::none;
    }

    boost::optional<Digest> getDigest(const IR::Declaration_Instance* decl,
                                      p4configv1::P4TypeInfo* p4RtTypeInfo) {
        std::vector<const P4::ExternMethod*> packCalls;
        // Check that the pack method is called exactly once on the digest
        // instance. The type of the data being packed used to be a type
        // parameter of the pack method itself, and not a type parameter of the
        // extern, so the we used to require a reference to the P4::ExternMethod
        // for the pack call in order to produce the P4Info type spec. This is
        // no longer the case but we keep this code as a sanity check.
        forAllExternMethodCalls(decl, [&](const P4::ExternMethod* method) {
            packCalls.push_back(method); });
        if (packCalls.size() == 0) return boost::none;
        if (packCalls.size() > 1) {
            ::error("Expected single call to pack for digest instance '%1%'", decl);
            return boost::none;
        }
        LOG4("Found 'pack' method call for digest instance " << decl->controlPlaneName());

        BUG_CHECK(decl->type->is<IR::Type_Specialized>(),
                  "%1%: expected Type_Specialized", decl->type);
        auto type = decl->type->to<IR::Type_Specialized>();
        BUG_CHECK(type->arguments->size() == 1, "%1%: expected one type argument", decl);
        auto typeArg = type->arguments->at(0);
        auto typeSpec = TypeSpecConverter::convert(typeMap, refMap, typeArg, p4RtTypeInfo);
        BUG_CHECK(typeSpec != nullptr,
                  "P4 type %1% could not be converted to P4Info P4DataTypeSpec");

        return Digest{decl->controlPlaneName(), typeSpec, decl->to<IR::IAnnotated>()};
    }

    static boost::optional<ActionProfile>
    getActionProfile(cstring name,
                     const IR::Type_Extern* type,
                     int64_t size,
                     const IR::IAnnotated* annotations) {
        auto actionProfileType = SymbolType::ACTION_PROFILE();
        if (type->name == "ActionSelector") {
            actionProfileType = SymbolType::ACTION_SELECTOR();
        } else if (type->name == "ActionProfile") {
            actionProfileType = SymbolType::ACTION_PROFILE();
        } else {
            return boost::none;
        }

        return ActionProfile{name, actionProfileType, size, annotations};
    }

    /// @return the action profile referenced in @table's implementation
    /// property, if it has one, or boost::none otherwise.
    static boost::optional<ActionProfile>
    getActionProfile(const IR::P4Table* table, ReferenceMap* refMap, TypeMap* typeMap) {
        using Helpers::getExternInstanceFromProperty;
        auto instance =
            getExternInstanceFromProperty(table, "implementation", refMap, typeMap);
        if (!instance) return boost::none;
        auto size = instance->substitution.lookupByName("size")->expression;
        // size is a bit<32> compile-time value
        BUG_CHECK(size->is<IR::Constant>(), "Non-constant size");
        return getActionProfile(*instance->name, instance->type,
                                size->to<IR::Constant>()->asInt(),
                                getTableImplementationAnnotations(table, refMap));
    }

    /// @return the action profile corresponding to @instance.
    static boost::optional<ActionProfile>
    getActionProfile(const IR::ExternBlock* instance) {
        auto decl = instance->node->to<IR::IDeclaration>();
        auto size = instance->getParameterValue("size");
        BUG_CHECK(size->is<IR::Constant>(), "Non-constant size");
        return getActionProfile(decl->controlPlaneName(), instance->type,
                                size->to<IR::Constant>()->asInt(),
                                decl->to<IR::IAnnotated>());
    }

    static p4configv1::Extern* getP4InfoExtern(P4RuntimeSymbolType typeId,
                                               cstring typeName,
                                               p4configv1::P4Info* p4info) {
        for (auto& externType : *p4info->mutable_externs()) {
            if (externType.extern_type_id() == static_cast<p4rt_id_t>(typeId))
                return &externType;
        }
        auto* externType = p4info->add_externs();
        externType->set_extern_type_id(static_cast<p4rt_id_t>(typeId));
        externType->set_extern_type_name(typeName);
        return externType;
    }

    static void addP4InfoExternInstance(const P4RuntimeSymbolTableIface& symbols,
                                        P4RuntimeSymbolType typeId, cstring typeName,
                                        cstring name, const IR::IAnnotated* annotations,
                                        const ::google::protobuf::Message& message,
                                        p4configv1::P4Info* p4info) {
        auto* externType = getP4InfoExtern(typeId, typeName, p4info);
        auto* externInstance = externType->add_instances();
        auto* pre = externInstance->mutable_preamble();
        pre->set_id(symbols.getId(typeId, name));
        pre->set_name(name);
        pre->set_alias(symbols.getAlias(name));
        Helpers::addAnnotations(pre, annotations);
        externInstance->mutable_info()->PackFrom(message);
    }

    void addDigest(const P4RuntimeSymbolTableIface& symbols,
                   p4configv1::P4Info* p4Info,
                   const Digest& digestInstance) {
        ::barefoot::Digest digest;
        digest.mutable_type_spec()->CopyFrom(*digestInstance.typeSpec);
        addP4InfoExternInstance(
            symbols, SymbolType::DIGEST(), "Digest",
            digestInstance.name, digestInstance.annotations, digest,
            p4Info);
    }

    void addPortMetadata(const P4RuntimeSymbolTableIface& symbols,
                         p4configv1::P4Info* p4Info,
                         const PortMetadata& portMetadataExtract) {
        ::barefoot::PortMetadata portMetadata;
        portMetadata.mutable_type_spec()->CopyFrom(*portMetadataExtract.typeSpec);
        addP4InfoExternInstance(
            symbols, SymbolType::PORT_METADATA(), "PortMetadata",
            PortMetadata::name(), nullptr, portMetadata, p4Info);
    }

    void addRegister(const P4RuntimeSymbolTableIface& symbols,
                     p4configv1::P4Info* p4Info,
                     const Register& registerInstance) {
        ::barefoot::Register register_;
        register_.set_size(registerInstance.size);
        register_.mutable_type_spec()->CopyFrom(*registerInstance.typeSpec);
        addP4InfoExternInstance(
            symbols, SymbolType::REGISTER(), "Register",
            registerInstance.name, registerInstance.annotations, register_,
            p4Info);
    }

    /// Set common fields between barefoot::Counter and barefoot::DirectCounter.
    template <typename Kind>
    void setCounterCommon(Kind *counter,
                          const Helpers::Counterlike<CounterExtern>& counterInstance) {
        auto counter_spec = counter->mutable_spec();
        using Helpers::CounterlikeTraits;
        counter_spec->set_unit(
            CounterlikeTraits<CounterExtern>::mapUnitName(counterInstance.unit));
    }

    void addCounter(const P4RuntimeSymbolTableIface& symbols,
                    p4configv1::P4Info* p4Info,
                    const Helpers::Counterlike<CounterExtern>& counterInstance) {
        if (counterInstance.table) {
            ::barefoot::DirectCounter counter;
            setCounterCommon(&counter, counterInstance);
            auto tableId = symbols.getId(P4RuntimeSymbolType::TABLE(), *counterInstance.table);
            counter.set_direct_table_id(tableId);
            addP4InfoExternInstance(
                symbols, SymbolType::DIRECT_COUNTER(),
                Helpers::CounterlikeTraits<CounterExtern>::directTypeName(),
                counterInstance.name, counterInstance.annotations, counter,
                p4Info);
        } else {
            ::barefoot::Counter counter;
            setCounterCommon(&counter, counterInstance);
            counter.set_size(counterInstance.size);
            addP4InfoExternInstance(
                symbols, SymbolType::COUNTER(),
                Helpers::CounterlikeTraits<CounterExtern>::typeName(),
                counterInstance.name, counterInstance.annotations, counter,
                p4Info);
        }
    }

    /// Set common fields between barefoot::Meter and barefoot::DirectMeter.
    template <typename Kind>
    void setMeterCommon(Kind *meter,
                        const Helpers::Counterlike<MeterExtern>& meterInstance) {
        using ::barefoot::MeterSpec;
        using Helpers::CounterlikeTraits;
        auto meter_spec = meter->mutable_spec();
        if (colorAwareMeters.find(meterInstance.name) != colorAwareMeters.end()) {
            meter_spec->set_type(MeterSpec::COLOR_AWARE);
        } else {
            meter_spec->set_type(MeterSpec::COLOR_UNAWARE);
        }
        meter_spec->set_unit(CounterlikeTraits<MeterExtern>::mapUnitName(meterInstance.unit));
    }

    void addMeter(const P4RuntimeSymbolTableIface& symbols,
                  p4configv1::P4Info* p4Info,
                  const Helpers::Counterlike<MeterExtern>& meterInstance) {
        if (meterInstance.table) {
            ::barefoot::DirectMeter meter;
            setMeterCommon(&meter, meterInstance);
            auto tableId = symbols.getId(P4RuntimeSymbolType::TABLE(), *meterInstance.table);
            meter.set_direct_table_id(tableId);
            addP4InfoExternInstance(
                symbols, SymbolType::DIRECT_METER(),
                Helpers::CounterlikeTraits<MeterExtern>::directTypeName(),
                meterInstance.name, meterInstance.annotations, meter,
                p4Info);
        } else {
            ::barefoot::Meter meter;
            setMeterCommon(&meter, meterInstance);
            meter.set_size(meterInstance.size);
            addP4InfoExternInstance(
                symbols, SymbolType::METER(),
                Helpers::CounterlikeTraits<MeterExtern>::typeName(),
                meterInstance.name, meterInstance.annotations, meter,
                p4Info);
        }
    }

    void addLpf(const P4RuntimeSymbolTableIface& symbols,
                p4configv1::P4Info* p4Info,
                const Lpf& lpfInstance) {
        if (lpfInstance.table) {
            ::barefoot::DirectLpf lpf;
            auto tableId = symbols.getId(P4RuntimeSymbolType::TABLE(), *lpfInstance.table);
            lpf.set_direct_table_id(tableId);
            addP4InfoExternInstance(
                symbols, SymbolType::DIRECT_LPF(), "DirectLpf",
                lpfInstance.name, lpfInstance.annotations, lpf,
                p4Info);
        } else {
            ::barefoot::Lpf lpf;
            lpf.set_size(lpfInstance.size);
            addP4InfoExternInstance(
                symbols, SymbolType::LPF(), "Lpf",
                lpfInstance.name, lpfInstance.annotations, lpf,
                p4Info);
        }
    }

    /// Set common fields between barefoot::Wred and barefoot::DirectWred.
    template <typename Kind>
    void setWredCommon(Kind *wred, const Wred& wredInstance) {
        using ::barefoot::WredSpec;
        auto wred_spec = wred->mutable_spec();
        wred_spec->set_drop_value(wredInstance.dropValue);
        wred_spec->set_no_drop_value(wredInstance.noDropValue);
    }

    void addWred(const P4RuntimeSymbolTableIface& symbols,
                 p4configv1::P4Info* p4Info,
                 const Wred& wredInstance) {
        if (wredInstance.table) {
            ::barefoot::DirectWred wred;
            setWredCommon(&wred, wredInstance);
            auto tableId = symbols.getId(P4RuntimeSymbolType::TABLE(), *wredInstance.table);
            wred.set_direct_table_id(tableId);
            addP4InfoExternInstance(
                symbols, SymbolType::DIRECT_WRED(), "DirectWred",
                wredInstance.name, wredInstance.annotations, wred,
                p4Info);
        } else {
            ::barefoot::Wred wred;
            setWredCommon(&wred, wredInstance);
            wred.set_size(wredInstance.size);
            addP4InfoExternInstance(
                symbols, SymbolType::WRED(), "Wred",
                wredInstance.name, wredInstance.annotations, wred,
                p4Info);
        }
    }

    void addActionProfile(const P4RuntimeSymbolTableIface& symbols,
                          p4configv1::P4Info* p4Info,
                          const ActionProfile& actionProfile) {
        ::barefoot::ActionProfile profile;
        profile.set_size(actionProfile.size);
        auto tablesIt = actionProfilesRefs.find(actionProfile.name);
        if (tablesIt != actionProfilesRefs.end()) {
            for (const auto& table : tablesIt->second)
                profile.add_table_ids(symbols.getId(P4RuntimeSymbolType::TABLE(), table));
        }
        addP4InfoExternInstance(symbols, SymbolType::ACTION_PROFILE(), "ActionProfile",
                                actionProfile.name, actionProfile.annotations, profile,
                                p4Info);
    }

    void addActionSelector(const P4RuntimeSymbolTableIface& symbols,
                          p4configv1::P4Info* p4Info,
                          const ActionProfile& actionSelector) {
        ::barefoot::ActionSelector selector;
        selector.set_size(actionSelector.size);
        auto tablesIt = actionProfilesRefs.find(actionSelector.name);
        if (tablesIt != actionProfilesRefs.end()) {
            for (const auto& table : tablesIt->second)
                selector.add_table_ids(symbols.getId(P4RuntimeSymbolType::TABLE(), table));
        }
        addP4InfoExternInstance(symbols, SymbolType::ACTION_SELECTOR(), "ActionSelector",
                                actionSelector.name, actionSelector.annotations, selector,
                                p4Info);
    }

 private:
    /// calls @function on every extern method applied to the extern @object
    // TODO(Antonin): for some reason we sometimes get multiple calls on the
    // same extern method (but different IR node), and I haven't found out why
    // or when this happens.
    template <typename Func>
    void forAllExternMethodCalls(const IR::IDeclaration* object, Func function) {
        forAllMatching<IR::MethodCallExpression>(evaluatedProgram->getProgram(),
                                                 [&](const IR::MethodCallExpression* call) {
            auto instance = P4::MethodInstance::resolve(call, refMap, typeMap);
            if (instance->is<P4::ExternMethod>() && instance->object == object) {
                function(instance->to<P4::ExternMethod>());
            }
        });
    }

    /// @return the table implementation property, or nullptr if the table has
    /// no such property.
    static const IR::Property* getTableImplementationProperty(const IR::P4Table* table) {
        return table->properties->getProperty("implementation");
    }

    static const IR::IAnnotated* getTableImplementationAnnotations(
        const IR::P4Table* table, ReferenceMap* refMap) {
        auto impl = getTableImplementationProperty(table);
        if (impl == nullptr) return nullptr;
        if (!impl->value->is<IR::ExpressionValue>()) return nullptr;
        auto expr = impl->value->to<IR::ExpressionValue>()->expression;
        if (expr->is<IR::ConstructorCallExpression>()) return impl->to<IR::IAnnotated>();
        if (expr->is<IR::PathExpression>()) {
            auto decl = refMap->getDeclaration(expr->to<IR::PathExpression>()->path, true);
            return decl->to<IR::IAnnotated>();
        }
        return nullptr;
    }

    static boost::optional<cstring> getTableImplementationName(
        const IR::P4Table* table, ReferenceMap* refMap) {
        auto impl = getTableImplementationProperty(table);
        if (impl == nullptr) return boost::none;
        if (!impl->value->is<IR::ExpressionValue>()) {
            ::error("Expected implementation property value for table %1% to be an expression: %2%",
                    table->controlPlaneName(), impl);
            return boost::none;
        }
        auto expr = impl->value->to<IR::ExpressionValue>()->expression;
        if (expr->is<IR::ConstructorCallExpression>()) return impl->controlPlaneName();
        if (expr->is<IR::PathExpression>()) {
            auto decl = refMap->getDeclaration(expr->to<IR::PathExpression>()->path, true);
            return decl->controlPlaneName();
        }
        return boost::none;
    }

    ReferenceMap* refMap;
    TypeMap* typeMap;
    const IR::ToplevelBlock* evaluatedProgram;

    /// Maps each action profile / selector to the set of tables referencing it.
    std::unordered_map<cstring, std::set<cstring> > actionProfilesRefs;
    /// The set of color-aware meters in the program.
    std::unordered_set<cstring> colorAwareMeters;

    /// True if the TNA P4 program explicitly extracts phase0 metadata to a
    /// programmer-defined struct.
    bool hasUserPortMetadata{false};
};

/// The architecture handler builder implementation for Tofino.
struct TofinoArchHandlerBuilder : public P4::ControlPlaneAPI::P4RuntimeArchHandlerBuilderIface {
    P4::ControlPlaneAPI::P4RuntimeArchHandlerIface* operator()(
        ReferenceMap* refMap,
        TypeMap* typeMap,
        const IR::ToplevelBlock* evaluatedProgram) const override {
        return new P4RuntimeArchHandlerTofino(refMap, typeMap, evaluatedProgram);
    }
};

void generateP4Runtime(const IR::P4Program* program,
                       const BFN_Options& options) {
    // If the user didn't ask for us to generate P4Runtime, skip the analysis.
    if (options.p4RuntimeFile.isNullOrEmpty() &&
        options.p4RuntimeEntriesFile.isNullOrEmpty() &&
        options.bfRtSchema.isNullOrEmpty())
        return;

    auto arch = P4::P4RuntimeSerializer::resolveArch(options);

    if (Log::verbose())
        std::cout << "Generating P4Runtime output for architecture " << arch << std::endl;

    auto p4RuntimeSerializer = P4::P4RuntimeSerializer::get();
    // By design we can use the same architecture handler implementation for
    // both TNA and JNA.
    p4RuntimeSerializer->registerArch("tna", new TofinoArchHandlerBuilder());
    p4RuntimeSerializer->registerArch("t2na", new TofinoArchHandlerBuilder());

    auto p4Runtime = p4RuntimeSerializer->generateP4Runtime(program, arch);

    if (!options.p4RuntimeFile.isNullOrEmpty()) {
        std::ostream* out = openFile(options.p4RuntimeFile, false);
        if (!out) {
            ::error("Couldn't open P4Runtime API file: %1%", options.p4RuntimeFile);
            return;
        }

        p4Runtime.serializeP4InfoTo(out, options.p4RuntimeFormat);
    }

    if (!options.p4RuntimeEntriesFile.isNullOrEmpty()) {
        std::ostream* out = openFile(options.p4RuntimeEntriesFile, false);
        if (!out) {
            ::error("Couldn't open P4Runtime static entries file: %1%",
                    options.p4RuntimeEntriesFile);
            return;
        }

        p4Runtime.serializeEntriesTo(out, options.p4RuntimeFormat);
    }

    if (!options.bfRtSchema.isNullOrEmpty()) {
        std::ostream* out = openFile(options.bfRtSchema, false);
        if (!out) {
            ::error("Couldn't open BF-RT schema file: %1%", options.bfRtSchema);
            return;
        }

        BFRT::serializeBfRtSchema(out, p4Runtime);
    }
}

}  // namespace BFN
