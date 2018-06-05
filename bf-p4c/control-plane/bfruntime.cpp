#include "bf-p4c/control-plane/bfruntime.h"

#include <boost/optional.hpp>

#include <algorithm>
#include <iterator>
#include <limits>
#include <ostream>
#include <string>

#include "barefoot/p4info.pb.h"
#include "control-plane/p4RuntimeSerializer.h"
#include "lib/exceptions.h"
#include "lib/gmputil.h"
#include "lib/json.h"
#include "lib/log.h"
#include "lib/null.h"
#include "p4/config/v1/p4info.pb.h"

namespace p4configv1 = ::p4::config::v1;

namespace BFN {

namespace BFRT {

using P4Id = uint32_t;

template <typename T>
static constexpr P4Id makeBfRtId(T base, ::barefoot::P4Ids::Prefix prefix) {
    return static_cast<P4Id>((base & 0xffffff) | (prefix << 24));
}

static constexpr P4Id getIdPrefix(P4Id id) {
    return ((id >> 24) & 0xff);
}

/// This class is in charge of translating the P4Info Protobuf message used in
/// the context of P4Runtime to the BF-RT info JSON used by the BF-RT API. It
/// supports both the "standard" P4Info message (the one used for v1model & PSA)
/// and P4Info with Tofino-specific extensions (the one used for TNA and JNA
/// programs).
/// TODO(antonin): In theory the BF-RT info JSON generated for a PSA program
/// (standard P4Info) and the one generated for the translated version of the
/// program (P4Info with Tofino extensions) should be exactly the same since
/// there is no loss of information and the names should remain the
/// same. Whether this is true in practice remains to be seen. We can change our
/// approach fairly easily if needed.
class BfRtSchemaGenerator {
 public:
    explicit BfRtSchemaGenerator(const p4configv1::P4Info& p4info)
        : p4info(p4info) { }

    /// Generates the schema as a Json object for the provided P4Info instance.
    const Util::JsonObject* genSchema() const;

 private:
    // TODO(antonin): these values may need to be available to the BF-RT
    // implementation as well, if they want to expose them as enums.

    // To avoid potential clashes with P4 names, we prefix the names of "fixed"
    // data field with a '$'. For example, for BF_RT_DATA_ACTION_MEMBER_ID, we
    // use the name $ACTION_MEMBER_ID.
    enum BfRtDataFieldIds : P4Id {
        BF_RT_DATA_START = 100,

        BF_RT_DATA_MATCH_PRIORITY,

        BF_RT_DATA_ACTION,
        BF_RT_DATA_ACTION_MEMBER_ID,
        BF_RT_DATA_SELECTOR_GROUP_ID,
        BF_RT_DATA_ACTION_MEMBER_STATUS,
        BF_RT_DATA_MAX_GROUP_SIZE,

        BF_RT_DATA_ENTRY_TTL,

        BF_RT_DATA_METER_SPEC_CIR_KBPS,
        BF_RT_DATA_METER_SPEC_PIR_KBPS,
        BF_RT_DATA_METER_SPEC_CBS_KBITS,
        BF_RT_DATA_METER_SPEC_PBS_KBITS,

        BF_RT_DATA_METER_SPEC_CIR_PPS,
        BF_RT_DATA_METER_SPEC_PIR_PPS,
        BF_RT_DATA_METER_SPEC_CBS_PKTS,
        BF_RT_DATA_METER_SPEC_PBS_PKTS,

        BF_RT_DATA_COUNTER_SPEC_BYTES,
        BF_RT_DATA_COUNTER_SPEC_PKTS,

        BF_RT_DATA_METER_INDEX,
        BF_RT_DATA_COUNTER_INDEX,
    };

    /// Common counter representation between PSA and Tofino architectures
    struct Counter;
    /// Common meter representation between PSA and Tofino architectures
    struct Meter;
    /// Common action profile / selector representation between PSA and Tofino
    /// architectures
    struct ActionProf;
    /// Common digest representation between PSA and Tofino architectures
    struct Digest;

    void addMatchTables(Util::JsonArray* tablesJson) const;
    void addActionProfs(Util::JsonArray* tablesJson) const;
    void addCounters(Util::JsonArray* tablesJson) const;
    void addMeters(Util::JsonArray* tablesJson) const;
    void addLearnFilters(Util::JsonArray* learnFiltersJson) const;
    void addTofinoExterns(Util::JsonArray* tablesJson,
                          Util::JsonArray* learnFiltersJson) const;

    void addCounterCommon(Util::JsonArray* tablesJson, const Counter& counter) const;
    void addMeterCommon(Util::JsonArray* tablesJson, const Meter& meter) const;
    void addActionProfCommon(Util::JsonArray* tablesJson, const ActionProf& actionProf) const;
    void addLearnFilterCommon(Util::JsonArray* learnFiltersJson, const Digest& digest) const;

    boost::optional<bool> actProfHasSelector(P4Id actProfId) const;
    Util::JsonArray* makeActionSpecs(const p4configv1::Table& table) const;
    boost::optional<Counter> getDirectCounter(P4Id counterId) const;
    boost::optional<Meter> getDirectMeter(P4Id meterId) const;

    static Util::JsonObject* makeCommonDataField(P4Id id, const std::string& name,
                                                 Util::JsonObject* type, bool repeated,
                                                 Util::JsonArray* annotations = nullptr);

    static void addActionDataField(Util::JsonArray* dataJson, P4Id id, const std::string& name,
                                   bool mandatory, Util::JsonObject* type,
                                   Util::JsonArray* annotations = nullptr);

    static void addKeyField(Util::JsonArray* dataJson, P4Id id, const std::string& name,
                            bool mandatory, cstring matchType, Util::JsonObject* type,
                            Util::JsonArray* annotations = nullptr);

    static void addCounterDataFields(Util::JsonArray* dataJson, const Counter& counter);

    static void addMeterDataFields(Util::JsonArray* dataJson, const Meter& meter);

    const p4configv1::P4Info& p4info;
};

static Util::JsonObject* transformAnnotation(const std::string& annotation) {
    auto* annotationJson = new Util::JsonObject();
    // TODO(antonin): annotation string will need to be parsed so we can have it
    // in key/value format here.
    annotationJson->emplace("name", annotation);
    return annotationJson;
}

template <typename It>
static Util::JsonArray* transformAnnotations(const It& first, const It& last) {
    auto* annotations = new Util::JsonArray();
    for (auto it = first; it != last; it++)
        annotations->append(transformAnnotation(*it));
    return annotations;
}

static boost::optional<cstring> transformMatchType(p4configv1::MatchField_MatchType matchType) {
    switch (matchType) {
        case p4configv1::MatchField_MatchType_UNSPECIFIED:
            return boost::none;
        case p4configv1::MatchField_MatchType_EXACT:
            return cstring("Exact");
        case p4configv1::MatchField_MatchType_LPM:
            return cstring("LPM");
        case p4configv1::MatchField_MatchType_TERNARY:
            return cstring("Ternary");
        case p4configv1::MatchField_MatchType_RANGE:
            return cstring("Range");
        default:
            return boost::none;
    }
}

/// @returns true if @id's prefix matches the provided Tofino @prefix value
static bool isOfType(P4Id id, ::barefoot::P4Ids::Prefix prefix) {
    return getIdPrefix(id) == static_cast<P4Id>(prefix);
}

/// @returns true if @id's prefix matches the provided PSA @prefix value
static bool isOfType(P4Id id, p4configv1::P4Ids::Prefix prefix) {
    return getIdPrefix(id) == static_cast<P4Id>(prefix);
}

namespace Standard {

template <typename It>
static auto findP4InfoObject(const It& first, const It& last, P4Id objectId)
    -> const typename std::iterator_traits<It>::value_type* {
    using T = typename std::iterator_traits<It>::value_type;
    auto desiredObject = std::find_if(first, last,
                                      [&](const T& object) {
        return object.preamble().id() == objectId;
    });
    if (desiredObject == last) return nullptr;
    return &*desiredObject;
}

static const p4configv1::Table* findTable(const p4configv1::P4Info& p4info, P4Id tableId) {
    const auto& tables = p4info.tables();
    return findP4InfoObject(tables.begin(), tables.end(), tableId);
}

static const p4configv1::Action* findAction(const p4configv1::P4Info& p4info, P4Id actionId) {
    const auto& actions = p4info.actions();
    return findP4InfoObject(actions.begin(), actions.end(), actionId);
}

static const p4configv1::ActionProfile* findActionProf(const p4configv1::P4Info& p4info,
                                                         P4Id actionProfId) {
    const auto& actionProfs = p4info.action_profiles();
    return findP4InfoObject(actionProfs.begin(), actionProfs.end(), actionProfId);
}

static const p4configv1::DirectCounter* findDirectCounter(const p4configv1::P4Info& p4info,
                                                            P4Id counterId) {
    const auto& counters = p4info.direct_counters();
    return findP4InfoObject(counters.begin(), counters.end(), counterId);
}

static const p4configv1::DirectMeter* findDirectMeter(const p4configv1::P4Info& p4info,
                                                        P4Id meterId) {
    const auto& meters = p4info.direct_meters();
    return findP4InfoObject(meters.begin(), meters.end(), meterId);
}

}  // namespace Standard

namespace Tofino {

static const p4configv1::Extern* findExternType(const p4configv1::P4Info& p4info,
                                                ::barefoot::P4Ids::Prefix externTypeId) {
    for (const auto& externType : p4info.externs()) {
        if (externType.extern_type_id() == static_cast<uint32_t>(externTypeId))
            return &externType;
    }
    return nullptr;
}

static const p4configv1::ExternInstance* findExternInstance(const p4configv1::P4Info& p4info,
                                                            P4Id externId) {
    auto prefix = static_cast<::barefoot::P4Ids::Prefix>(getIdPrefix(externId));
    auto* externType = findExternType(p4info, prefix);
    if (externType == nullptr) return nullptr;
    auto* externInstance = Standard::findP4InfoObject(
        externType->instances().begin(), externType->instances().end(), externId);
    return externInstance;
}

}  // namespace Tofino

static Util::JsonObject* makeTypeInt(cstring type) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", type);
    return typeObj;
}

template <typename T, typename std::enable_if<std::is_integral<T>::value, int>::type = 0>
static Util::JsonObject* makeTypeInt(cstring type, T defaultValue) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", type);
    typeObj->emplace("default_value", defaultValue);
    return typeObj;
}

static Util::JsonObject* makeTypeBool(boost::optional<bool> defaultValue = boost::none) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", "bool");
    if (defaultValue != boost::none)
        typeObj->emplace("default_value", *defaultValue);
    return typeObj;
}

static Util::JsonObject* makeTypeBytes(int width,
                                       boost::optional<cstring> defaultValue = boost::none) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", "bytes");
    typeObj->emplace("width", width);
    if (defaultValue != boost::none)
        typeObj->emplace("default_value", *defaultValue);
    return typeObj;
}

static void addOneOf(Util::JsonArray* dataJson,
                     Util::JsonArray* choicesJson, bool mandatory, bool readOnly) {
    auto* oneOfJson = new Util::JsonObject();
    oneOfJson->emplace("mandatory", mandatory);
    oneOfJson->emplace("read_only", readOnly);
    oneOfJson->emplace("oneof", choicesJson);
    dataJson->append(oneOfJson);
}

static void addSingleton(Util::JsonArray* dataJson,
                         Util::JsonObject* dataField, bool mandatory, bool readOnly) {
    auto* singletonJson = new Util::JsonObject();
    singletonJson->emplace("mandatory", mandatory);
    singletonJson->emplace("read_only", readOnly);
    singletonJson->emplace("singleton", dataField);
    dataJson->append(singletonJson);
}

/// Common counter representation between PSA and Tofino architectures
struct BfRtSchemaGenerator::Counter {
    enum Unit { UNSPECIFIED = 0, BYTES = 1, PACKETS = 2, BOTH = 3 };
    std::string name;
    P4Id id;
    int64_t size;
    Unit unit;

    static boost::optional<Counter> from(const p4configv1::Counter& counterInstance) {
        const auto& pre = counterInstance.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::COUNTER);
        // TODO(antonin): this works because the enum values are the same for
        // Counter::Unit and for CounterSpec::Unit, but this may not be very
        // future-proof.
        auto unit = static_cast<Counter::Unit>(counterInstance.spec().unit());
        return Counter{pre.name(), id, counterInstance.size(), unit};
    }

    static boost::optional<Counter> fromDirect(const p4configv1::DirectCounter& counterInstance) {
        const auto& pre = counterInstance.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::DIRECT_COUNTER);
        auto unit = static_cast<Counter::Unit>(counterInstance.spec().unit());
        return Counter{pre.name(), id, 0, unit};
    }

    static boost::optional<Counter> fromTofino(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Counter counter;
        if (!externInstance.info().UnpackTo(&counter)) {
            ::error("Extern instance %1% does not pack a Counter object", pre.name());
            return boost::none;
        }
        auto unit = static_cast<Counter::Unit>(counter.spec().unit());
        return Counter{pre.name(), pre.id(), counter.size(), unit};
    }

    static boost::optional<Counter> fromTofinoDirect(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::DirectCounter counter;
        if (!externInstance.info().UnpackTo(&counter)) {
            ::error("Extern instance %1% does not pack a DirectCounter object", pre.name());
            return boost::none;
        }
        auto unit = static_cast<Counter::Unit>(counter.spec().unit());
        return Counter{pre.name(), pre.id(), 0, unit};
    }
};

/// Common meter representation between PSA and Tofino architectures
struct BfRtSchemaGenerator::Meter {
    enum Unit { UNSPECIFIED = 0, BYTES = 1, PACKETS = 2 };
    enum Type { COLOR_UNAWARE = 0, COLOR_AWARE = 1 };
    std::string name;
    P4Id id;
    int64_t size;
    Unit unit;
    Type type;

    static boost::optional<Meter> from(const p4configv1::Meter& meterInstance) {
        const auto& pre = meterInstance.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::METER);
        // TODO(antonin): this works because the enum values are the same for
        // Meter::Unit and for MeterSpec::Unit, but this may not be very
        // future-proof.
        auto unit = static_cast<Meter::Unit>(meterInstance.spec().unit());
        auto type = static_cast<Meter::Type>(meterInstance.spec().type());
        return Meter{pre.name(), id, meterInstance.size(), unit, type};
    }

    static boost::optional<Meter> fromDirect(const p4configv1::DirectMeter& meterInstance) {
        const auto& pre = meterInstance.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::DIRECT_METER);
        auto unit = static_cast<Meter::Unit>(meterInstance.spec().unit());
        auto type = static_cast<Meter::Type>(meterInstance.spec().type());
        return Meter{pre.name(), id, 0, unit, type};
    }

    static boost::optional<Meter> fromTofino(const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Meter meter;
        if (!externInstance.info().UnpackTo(&meter)) {
            ::error("Extern instance %1% does not pack a Meter object", pre.name());
            return boost::none;
        }
        auto unit = static_cast<Meter::Unit>(meter.spec().unit());
        auto type = static_cast<Meter::Type>(meter.spec().type());
        return Meter{pre.name(), pre.id(), meter.size(), unit, type};
    }

    static boost::optional<Meter> fromTofinoDirect(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::DirectMeter meter;
        if (!externInstance.info().UnpackTo(&meter)) {
            ::error("Extern instance %1% does not pack a Meter object", pre.name());
            return boost::none;
        }
        auto unit = static_cast<Meter::Unit>(meter.spec().unit());
        auto type = static_cast<Meter::Type>(meter.spec().type());
        return Meter{pre.name(), pre.id(), 0, unit, type};
    }
};

/// Common action profile / selector representation between PSA and Tofino
/// architectures
struct BfRtSchemaGenerator::ActionProf {
    struct Selector {
        std::string name;
        P4Id id;
        int64_t size;
        int64_t max_group_size;
    };

    std::string name;
    P4Id id;
    int64_t size;
    std::vector<P4Id> tableIds;
    boost::optional<Selector> selector;

    static constexpr int selectorHugeGroupSize = 120;

    template <typename It>
    static std::vector<P4Id> collectTableIds(const p4configv1::P4Info& p4info,
                                             const It& first, const It& last) {
        std::vector<P4Id> tableIds;
        for (auto it = first; it != last; it++) {
            auto* table = Standard::findTable(p4info, *it);
            if (table == nullptr) {
                ::error("Invalid table id '%1%'", *it);
                continue;
            }
            tableIds.push_back(*it);
        }
        return tableIds;
    }

    static boost::optional<ActionProf> from(const p4configv1::P4Info& p4info,
                                            const p4configv1::ActionProfile& actionProfile) {
        const auto& pre = actionProfile.preamble();
        auto profileId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_PROFILE);
        boost::optional<Selector> selector = boost::none;
        if (actionProfile.with_selector()) {
            std::string selectorName(pre.name() + "_sel");
            auto selectorId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_SELECTOR);
            selector = Selector{
              selectorName, selectorId, actionProfile.size(), selectorHugeGroupSize};
        }
        auto tableIds = collectTableIds(
            p4info, actionProfile.table_ids().begin(), actionProfile.table_ids().end());
        return ActionProf{pre.name(), profileId, actionProfile.size(), tableIds, selector};
    }

    static boost::optional<ActionProf> fromTofinoActionProfile(
        const p4configv1::P4Info& p4info, const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::ActionProfile actionProfile;
        if (!externInstance.info().UnpackTo(&actionProfile)) {
            ::error("Extern instance %1% does not pack an ActionProfile object", pre.name());
            return boost::none;
        }
        auto tableIds = collectTableIds(
            p4info, actionProfile.table_ids().begin(), actionProfile.table_ids().end());
        return ActionProf{pre.name(), pre.id(), actionProfile.size(), tableIds, boost::none};
    }

    static boost::optional<ActionProf> fromTofinoActionSelector(
        const p4configv1::P4Info& p4info, const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::ActionSelector actionSelector;
        if (!externInstance.info().UnpackTo(&actionSelector)) {
            ::error("Extern instance %1% does not pack an ActionSelector object", pre.name());
            return boost::none;
        }
        auto profileId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_PROFILE);
        std::string selectorName(pre.name() + "_sel");
        auto selectorId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_SELECTOR);
        Selector selector{selectorName, selectorId, actionSelector.size(), selectorHugeGroupSize};
        auto tableIds = collectTableIds(
            p4info, actionSelector.table_ids().begin(), actionSelector.table_ids().end());
        return ActionProf{pre.name(), profileId, actionSelector.size(), tableIds, selector};
    }
};

/// Common digest representation between PSA and Tofino architectures
struct BfRtSchemaGenerator::Digest {
    std::string name;
    P4Id id;
    p4configv1::P4DataTypeSpec typeSpec;

    static boost::optional<Digest> from(const p4configv1::Digest& digest) {
        const auto& pre = digest.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::DIGEST);
        return Digest{pre.name(), id, digest.type_spec()};
    }

    static boost::optional<Digest> fromTofino(const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Digest digest;
        if (!externInstance.info().UnpackTo(&digest)) {
            ::error("Extern instance %1% does not pack a Digest object", pre.name());
            return boost::none;
        }
        return Digest{pre.name(), pre.id(), digest.type_spec()};
    }
};

boost::optional<BfRtSchemaGenerator::Counter>
BfRtSchemaGenerator::getDirectCounter(P4Id counterId) const {
    if (isOfType(counterId, p4configv1::P4Ids::DIRECT_COUNTER)) {
        auto* counter = Standard::findDirectCounter(p4info, counterId);
        if (counter == nullptr) return boost::none;
        return Counter::fromDirect(*counter);
    } else if (isOfType(counterId, ::barefoot::P4Ids::DIRECT_COUNTER)) {
        auto* externInstance = Tofino::findExternInstance(p4info, counterId);
        if (externInstance == nullptr) return boost::none;
        return Counter::fromTofinoDirect(*externInstance);
    }
    return boost::none;
}

boost::optional<BfRtSchemaGenerator::Meter>
BfRtSchemaGenerator::getDirectMeter(P4Id meterId) const {
    if (isOfType(meterId, p4configv1::P4Ids::DIRECT_METER)) {
        auto* meter = Standard::findDirectMeter(p4info, meterId);
        if (meter == nullptr) return boost::none;
        return Meter::fromDirect(*meter);
    } else if (isOfType(meterId, ::barefoot::P4Ids::DIRECT_METER)) {
        auto* externInstance = Tofino::findExternInstance(p4info, meterId);
        if (externInstance == nullptr) return boost::none;
        return Meter::fromTofinoDirect(*externInstance);
    }
    return boost::none;
}

Util::JsonObject*
BfRtSchemaGenerator::makeCommonDataField(P4Id id, const std::string& name,
                                         Util::JsonObject* type, bool repeated,
                                         Util::JsonArray* annotations) {
    auto* dataField = new Util::JsonObject();
    dataField->emplace("id", id);
    dataField->emplace("name", name);
    dataField->emplace("repeated", repeated);
    if (annotations != nullptr)
        dataField->emplace("annotations", annotations);
    else
        dataField->emplace("annotations", new Util::JsonArray());
    dataField->emplace("type", type);
    return dataField;
}

void
BfRtSchemaGenerator::addActionDataField(Util::JsonArray* dataJson, P4Id id, const std::string& name,
                                        bool mandatory, Util::JsonObject* type,
                                        Util::JsonArray* annotations) {
    auto* dataField = new Util::JsonObject();
    dataField->emplace("id", id);
    dataField->emplace("name", name);
    dataField->emplace("repeated", false);
    dataField->emplace("mandatory", mandatory);
    if (annotations != nullptr)
        dataField->emplace("annotations", annotations);
    else
        dataField->emplace("annotations", new Util::JsonArray());
    dataField->emplace("type", type);
    dataJson->append(dataField);
}

void
BfRtSchemaGenerator::addKeyField(Util::JsonArray* dataJson, P4Id id, const std::string& name,
                                 bool mandatory, cstring matchType, Util::JsonObject* type,
                                 Util::JsonArray* annotations) {
    auto* dataField = new Util::JsonObject();
    dataField->emplace("id", id);
    dataField->emplace("name", name);
    dataField->emplace("repeated", false);
    if (annotations != nullptr)
        dataField->emplace("annotations", annotations);
    else
        dataField->emplace("annotations", new Util::JsonArray());
    dataField->emplace("mandatory", mandatory);
    dataField->emplace("match_type", matchType);
    dataField->emplace("type", type);
    dataJson->append(dataField);
}

void
BfRtSchemaGenerator::addCounterCommon(Util::JsonArray* tablesJson, const Counter& counter) const {
    auto* tableJson = new Util::JsonObject();

    tableJson->emplace("name", counter.name);
    tableJson->emplace("id", counter.id);
    tableJson->emplace("table_type", "Counter");
    tableJson->emplace("size", counter.size);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_COUNTER_INDEX, "$COUNTER_INDEX",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    addCounterDataFields(dataJson, counter);
    tableJson->emplace("data", dataJson);

    auto* operationsJson = new Util::JsonArray();
    operationsJson->append("Sync");
    tableJson->emplace("supported_operations", operationsJson);

    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addCounterDataFields(Util::JsonArray* dataJson, const Counter& counter) {
    static const uint64_t defaultCounterValue = 0u;
    if (counter.unit == Counter::Unit::BYTES || counter.unit == Counter::Unit::BOTH) {
        auto* f = makeCommonDataField(
            BF_RT_DATA_COUNTER_SPEC_BYTES, "$COUNTER_SPEC_BYTES",
            makeTypeInt("uint64", defaultCounterValue), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
    if (counter.unit == Counter::Unit::PACKETS || counter.unit == Counter::Unit::BOTH) {
        auto* f = makeCommonDataField(
            BF_RT_DATA_COUNTER_SPEC_PKTS, "$COUNTER_SPEC_PKTS",
            makeTypeInt("uint64", defaultCounterValue), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
}

void
BfRtSchemaGenerator::addMeterCommon(Util::JsonArray* tablesJson, const Meter& meter) const {
    auto* tableJson = new Util::JsonObject();

    tableJson->emplace("name", meter.name);
    tableJson->emplace("id", meter.id);
    tableJson->emplace("table_type", "Meter");
    tableJson->emplace("size", meter.size);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_METER_INDEX, "$METER_INDEX",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    addMeterDataFields(dataJson, meter);
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addMeterDataFields(Util::JsonArray* dataJson, const Meter& meter) {
    // default value for rates and bursts (all GREEN)
    static const uint64_t maxUint64 = std::numeric_limits<uint64_t>::max();
    if (meter.unit == Meter::Unit::BYTES) {
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_METER_SPEC_CIR_KBPS, "$METER_SPEC_CIR_KBPS",
                makeTypeInt("uint64", maxUint64), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_METER_SPEC_PIR_KBPS, "$METER_SPEC_PIR_KBPS",
                makeTypeInt("uint64", maxUint64), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_METER_SPEC_CBS_KBITS, "$METER_SPEC_CBS_KBITS",
                makeTypeInt("uint64", maxUint64), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_METER_SPEC_PBS_KBITS, "$METER_SPEC_PBS_KBITS",
                makeTypeInt("uint64", maxUint64), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
    } else if (meter.unit == Meter::Unit::PACKETS) {
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_METER_SPEC_CIR_PPS, "$METER_SPEC_CIR_PPS",
                makeTypeInt("uint64", maxUint64), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_METER_SPEC_PIR_PPS, "$METER_SPEC_PIR_PPS",
                makeTypeInt("uint64", maxUint64), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_METER_SPEC_CBS_PKTS, "$METER_SPEC_CBS_PKTS",
                makeTypeInt("uint64", maxUint64), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_METER_SPEC_PBS_PKTS, "$METER_SPEC_PBS_PKTS",
                makeTypeInt("uint64", maxUint64), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
    } else {
        BUG("Unknown meter unit");
    }
}

void
BfRtSchemaGenerator::addActionProfCommon(Util::JsonArray* tablesJson,
                                         const ActionProf& actionProf) const {
    auto* tableJson = new Util::JsonObject();
    tableJson->emplace("name", actionProf.name);
    tableJson->emplace("id", actionProf.id);
    tableJson->emplace("table_type", "Action");
    tableJson->emplace("size", actionProf.size);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    if (actionProf.tableIds.empty()) {
        ::warning("Action profile '%1%' is not used by any table, skiping it", actionProf.name);
        return;
    }
    auto oneTableId = actionProf.tableIds.at(0);
    auto* oneTable = Standard::findTable(p4info, oneTableId);
    CHECK_NULL(oneTable);
    tableJson->emplace("action_specs", makeActionSpecs(*oneTable));

    tableJson->emplace("data", new Util::JsonArray());

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);

    if (actionProf.selector != boost::none) {
        auto* tableJson = new Util::JsonObject();

        // TODO(antonin): formalize ID allocation for selector tables
        tableJson->emplace("name", actionProf.selector->name);
        tableJson->emplace("id", actionProf.selector->id);
        tableJson->emplace("table_type", "Selector");
        tableJson->emplace("size", actionProf.selector->size);

        auto* keyJson = new Util::JsonArray();
        addKeyField(keyJson, BF_RT_DATA_SELECTOR_GROUP_ID, "$SELECTOR_GROUP_ID",
                    true /* mandatory */, "Exact", makeTypeInt("uint32"));
        tableJson->emplace("key", keyJson);

        auto* dataJson = new Util::JsonArray();
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                makeTypeInt("uint32"), true /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_ACTION_MEMBER_STATUS, "$ACTION_MEMBER_STATUS",
                makeTypeBool(), true /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_MAX_GROUP_SIZE, "$MAX_GROUP_SIZE",
                makeTypeInt("uint32", 120), false /* repeated */);
            addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
        }
        tableJson->emplace("data", dataJson);

        tableJson->emplace("supported_operations", new Util::JsonArray());
        tableJson->emplace("attributes", new Util::JsonArray());

        tablesJson->append(tableJson);
    }
}

void
BfRtSchemaGenerator::addLearnFilterCommon(Util::JsonArray* learnFiltersJson,
                                          const Digest& digest) const {
    auto* learnFilterJson = new Util::JsonObject();
    learnFilterJson->emplace("name", digest.name);
    learnFilterJson->emplace("id", digest.id);

    auto* fieldsJson = new Util::JsonArray();
    const auto& typeInfo = p4info.type_info();
    const auto& typeSpec = digest.typeSpec;

    auto addField = [fieldsJson, &digest](P4Id id, const std::string& name,
                                          const p4configv1::P4DataTypeSpec& fSpec) {
        if (!fSpec.has_bitstring() || !fSpec.bitstring().has_bit()) {
            ::error("Error when generating BF-RT info for Digest '%1%': "
                    "packed type is too complex",
                    digest.name);
            return;
        }
        auto* f = makeCommonDataField(
            id, name, makeTypeBytes(fSpec.bitstring().bit().bitwidth()), false /* repeated */);
        fieldsJson->append(f);
    };

    if (typeSpec.has_struct_()) {
        auto structName = typeSpec.struct_().name();
        for (auto& p : typeInfo.structs()) {
            if (p.first != structName) continue;
            P4Id id = 1;
            for (const auto& member : p.second.members())
                addField(id++, member.name(), member.type_spec());
        }
    } else if (typeSpec.has_tuple()) {
        P4Id id = 1;
        for (const auto& member : typeSpec.tuple().members()) {
            // TODO(antonin): we do not really have better names for now, do we
            // need to add support for annotations of tuple members in P4Info?
            std::string fName("f" + std::to_string(id));
            addField(id++, fName, member);
        }
    } else {
        ::error("Error when generating BF-RT info for Digest '%1%': "
                "only structs and tuples are currently supported for packed type",
                digest.name);
    }
    learnFilterJson->emplace("fields", fieldsJson);

    learnFiltersJson->append(learnFilterJson);
}

boost::optional<bool>
BfRtSchemaGenerator::actProfHasSelector(P4Id actProfId) const {
    if (isOfType(actProfId, p4configv1::P4Ids::ACTION_PROFILE)) {
        auto* actionProf = Standard::findActionProf(p4info, actProfId);
        if (actionProf == nullptr) return boost::none;
        return actionProf->with_selector();
    } else if (isOfType(actProfId, ::barefoot::P4Ids::ACTION_PROFILE)) {
        return false;
    } else if (isOfType(actProfId, ::barefoot::P4Ids::ACTION_SELECTOR)) {
        return true;
    }
    return boost::none;
}

Util::JsonArray*
BfRtSchemaGenerator::makeActionSpecs(const p4configv1::Table& table) const {
    auto* specs = new Util::JsonArray();
    for (const auto& action_ref : table.action_refs()) {
        auto* action = Standard::findAction(p4info, action_ref.id());
        if (action == nullptr) {
            ::error("Invalid action id '%1%'", action_ref.id());
            continue;
        }
        auto* spec = new Util::JsonObject();
        const auto& pre = action->preamble();
        spec->emplace("id", pre.id());
        spec->emplace("name", pre.name());
        auto* dataJson = new Util::JsonArray();
        for (const auto& param : action->params()) {
            auto* annotations = transformAnnotations(
                param.annotations().begin(), param.annotations().end());
            addActionDataField(
                dataJson, param.id(), param.name(), true /* mandatory */,
                makeTypeBytes(param.bitwidth()), annotations);
        }
        spec->emplace("data", dataJson);
        specs->append(spec);
    }
    return specs;
}

void
BfRtSchemaGenerator::addMatchTables(Util::JsonArray* tablesJson) const {
    for (const auto& table : p4info.tables()) {
        const auto& pre = table.preamble();

        auto* tableJson = new Util::JsonObject();
        tableJson->emplace("name", pre.name());
        tableJson->emplace("id", pre.id());

        cstring tableType = "MatchAction_Direct";
        auto actProfId = table.implementation_id();
        if (actProfId > 0) {
            auto hasSelector = actProfHasSelector(actProfId);
            if (hasSelector == boost::none) {
                ::error("Invalid implementation id in p4info: %1%", actProfId);
                continue;
            }
            tableType = *hasSelector ? "MatchAction_Indirect_Selector" : "MatchAction_Indirect";
        }

        tableJson->emplace("table_type", tableType);
        tableJson->emplace("size", table.size());

        // will be set to true by the for loop if the match key includes a
        // ternary or range match
        bool needsPriority = false;
        auto* keyJson = new Util::JsonArray();
        for (const auto& mf : table.match_fields()) {
            auto matchType = transformMatchType(mf.match_type());
            if (matchType == boost::none) {
                ::error("Unsupported match type for BF-RT: %1%", mf.match_type());
                continue;
            }
            if (*matchType == "Ternary" || *matchType == "Range") needsPriority = true;
            auto* annotations = transformAnnotations(
                mf.annotations().begin(), mf.annotations().end());
            addKeyField(keyJson, mf.id(), mf.name(),
                        true /* mandatory */, *matchType,
                        makeTypeBytes(mf.bitwidth(), boost::none),
                        annotations);
        }
        if (needsPriority) {
            addKeyField(keyJson, BF_RT_DATA_MATCH_PRIORITY, "$MATCH_PRIORITY",
                        true /* mandatory */, "Exact", makeTypeInt("uint32"));
        }
        tableJson->emplace("key", keyJson);

        auto* dataJson = new Util::JsonArray();

        if (tableType == "MatchAction_Direct") {
            tableJson->emplace("action_specs", makeActionSpecs(table));
        } else if (tableType == "MatchAction_Indirect") {
            auto* f = makeCommonDataField(
                BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                makeTypeInt("uint32"), false /* repeated */);
            addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
        } else if (tableType == "MatchAction_Indirect_Selector") {
            // action member id and selector group id are mutually-exclusive, so
            // we use a "oneof" here.
            auto* choicesDataJson = new Util::JsonArray();
            choicesDataJson->append(makeCommonDataField(
                BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                makeTypeInt("uint32"), false /* repeated */));
            choicesDataJson->append(makeCommonDataField(
                BF_RT_DATA_SELECTOR_GROUP_ID, "$SELECTOR_GROUP_ID",
                makeTypeInt("uint32"), false /* repeated */));
            addOneOf(dataJson, choicesDataJson, true /* mandatory */, false /* read-only */);
        } else {
            BUG("Invalid table type '%1%'", tableType);
        }

        auto* operationsJson = new Util::JsonArray();

        // direct resources
        for (auto directResId : table.direct_resource_ids()) {
            if (auto counter = getDirectCounter(directResId)) {
                addCounterDataFields(dataJson, *counter);
                operationsJson->append("SyncCounters");
            } else if (auto meter = getDirectMeter(directResId)) {
                addMeterDataFields(dataJson, *meter);
            } else {
                ::error("Unknown direct resource id '%1%'", directResId);
                continue;
            }
        }

        tableJson->emplace("data", dataJson);

        tableJson->emplace("supported_operations", operationsJson);

        // TODO(antonin): idle-timeout support

        auto* attributesJson = new Util::JsonArray();
        attributesJson->append("EntryScope");
        if (table.is_const_table()) attributesJson->append("ConstTable");
        tableJson->emplace("attributes", attributesJson);

        tablesJson->append(tableJson);
    }
}

void
BfRtSchemaGenerator::addActionProfs(Util::JsonArray* tablesJson) const {
    for (const auto& actionProf : p4info.action_profiles()) {
        auto actionProfInstance = ActionProf::from(p4info, actionProf);
        if (actionProfInstance == boost::none) continue;
        addActionProfCommon(tablesJson, *actionProfInstance);
    }
}

void
BfRtSchemaGenerator::addCounters(Util::JsonArray* tablesJson) const {
    for (const auto& counter : p4info.counters()) {
        auto counterInstance = Counter::from(counter);
        if (counterInstance == boost::none) continue;
        addCounterCommon(tablesJson, *counterInstance);
    }
}

void
BfRtSchemaGenerator::addMeters(Util::JsonArray* tablesJson) const {
    for (const auto& meter : p4info.meters()) {
        auto meterInstance = Meter::from(meter);
        if (meterInstance == boost::none) continue;
        addMeterCommon(tablesJson, *meterInstance);
    }
}

void
BfRtSchemaGenerator::addLearnFilters(Util::JsonArray* learnFiltersJson) const {
    for (const auto& digest : p4info.digests()) {
        auto digestInstance = Digest::from(digest);
        if (digestInstance == boost::none) continue;
        addLearnFilterCommon(learnFiltersJson, *digestInstance);
    }
}

void
BfRtSchemaGenerator::addTofinoExterns(Util::JsonArray* tablesJson,
                                      Util::JsonArray* learnFiltersJson) const {
    for (const auto& externType : p4info.externs()) {
        auto externTypeId = static_cast<::barefoot::P4Ids::Prefix>(externType.extern_type_id());
        if (externTypeId == ::barefoot::P4Ids::ACTION_PROFILE) {
            for (const auto& externInstance : externType.instances()) {
                auto actionProf = ActionProf::fromTofinoActionProfile(p4info, externInstance);
                if (actionProf != boost::none) addActionProfCommon(tablesJson, *actionProf);
            }
        } else if (externTypeId == ::barefoot::P4Ids::ACTION_SELECTOR) {
            for (const auto& externInstance : externType.instances()) {
                auto actionProf = ActionProf::fromTofinoActionSelector(p4info, externInstance);
                if (actionProf != boost::none) addActionProfCommon(tablesJson, *actionProf);
            }
        } else if (externTypeId == ::barefoot::P4Ids::COUNTER) {
            for (const auto& externInstance : externType.instances()) {
                auto counter = Counter::fromTofino(externInstance);
                if (counter != boost::none) addCounterCommon(tablesJson, *counter);
            }
        } else if (externTypeId == ::barefoot::P4Ids::METER) {
            for (const auto& externInstance : externType.instances()) {
                auto meter = Meter::fromTofino(externInstance);
                if (meter != boost::none) addMeterCommon(tablesJson, *meter);
            }
        } else if (externTypeId == ::barefoot::P4Ids::DIGEST) {
            for (const auto& externInstance : externType.instances()) {
                auto digest = Digest::fromTofino(externInstance);
                if (digest != boost::none) addLearnFilterCommon(learnFiltersJson, *digest);
            }
        }
    }
}

const Util::JsonObject*
BfRtSchemaGenerator::genSchema() const {
    auto* json = new Util::JsonObject();
    auto* tablesJson = new Util::JsonArray();
    json->emplace("tables", tablesJson);

    addMatchTables(tablesJson);
    addActionProfs(tablesJson);
    addCounters(tablesJson);
    addMeters(tablesJson);

    auto* learnFiltersJson = new Util::JsonArray();
    json->emplace("learn_filters", learnFiltersJson);
    addLearnFilters(learnFiltersJson);

    addTofinoExterns(tablesJson, learnFiltersJson);

    return json;
}

void serializeBfRtSchema(std::ostream* destination, const P4::P4RuntimeAPI& p4Runtime) {
    auto* p4info = p4Runtime.p4Info;
    BfRtSchemaGenerator generator(*p4info);
    auto* json = generator.genSchema();
    json->serialize(*destination);
    destination->flush();
}

}  // namespace BFRT

}  // namespace BFN
