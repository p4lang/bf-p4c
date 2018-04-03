#include "bf-p4c/control-plane/bfruntime.h"

#include <boost/optional.hpp>

#include <algorithm>
#include <iterator>
#include <limits>
#include <ostream>

#include "control-plane/p4RuntimeSerializer.h"
#include "lib/exceptions.h"
#include "lib/gmputil.h"
#include "lib/json.h"
#include "lib/log.h"
#include "p4/config/p4info.pb.h"

namespace BFN {

namespace BFRT {

using P4Id = uint32_t;

class BfRtSchemaGenerator {
 public:
    explicit BfRtSchemaGenerator(const p4::config::P4Info& p4info)
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

        BF_RT_DATA_ACTION,
        BF_RT_DATA_ACTION_MEMBER_ID,
        BF_RT_DATA_SELECTOR_GROUP_ID,
        BF_RT_DATA_ACTION_MEMBER_STATUS,

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

    void addMatchTables(Util::JsonArray* tablesJson) const;
    void addActionProfs(Util::JsonArray* tablesJson) const;
    void addCounters(Util::JsonArray* tablesJson) const;
    void addMeters(Util::JsonArray* tablesJson) const;

    Util::JsonArray* makeActionSpecs(const p4::config::Table& table) const;

    static Util::JsonObject* makeCommonDataField(P4Id id, const std::string& name,
                                                 Util::JsonObject* type, bool repeated,
                                                 Util::JsonArray* annotations = nullptr);

    static void addActionDataField(Util::JsonArray* dataJson, P4Id id, const std::string& name,
                                   bool mandatory, Util::JsonObject* type,
                                   Util::JsonArray* annotations = nullptr);

    static void addKeyField(Util::JsonArray* dataJson, P4Id id, const std::string& name,
                            bool mandatory, cstring matchType, Util::JsonObject* type,
                            Util::JsonArray* annotations = nullptr);

    static void addCounterDataFields(Util::JsonArray* dataJson,
                                     const p4::config::CounterSpec& counterSpec);
    static void addMeterDataFields(Util::JsonArray* dataJson,
                                   const p4::config::MeterSpec& meterSpec);

    const p4::config::P4Info& p4info;
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

static boost::optional<cstring> transformMatchType(p4::config::MatchField_MatchType matchType) {
    switch (matchType) {
        case p4::config::MatchField_MatchType_UNSPECIFIED:
            return boost::none;
        case p4::config::MatchField_MatchType_EXACT:
            return cstring("Exact");
        case p4::config::MatchField_MatchType_LPM:
            return cstring("LPM");
        case p4::config::MatchField_MatchType_TERNARY:
            return cstring("Ternary");
        case p4::config::MatchField_MatchType_RANGE:
            return cstring("Range");
        default:
            return boost::none;
    }
}

template <typename It>
auto findP4InfoObject(const It& first, const It& last, P4Id objectId)
    -> const typename std::iterator_traits<It>::value_type* {
    using T = typename std::iterator_traits<It>::value_type;
    auto desiredObject = std::find_if(first, last,
                                      [&](const T& object) {
        return object.preamble().id() == objectId;
    });
    if (desiredObject == last) return nullptr;
    return &*desiredObject;
}


const ::p4::config::Table* findTable(const p4::config::P4Info& p4info, P4Id tableId) {
    const auto& tables = p4info.tables();
    return findP4InfoObject(tables.begin(), tables.end(), tableId);
}

const ::p4::config::Action* findAction(const p4::config::P4Info& p4info, P4Id actionId) {
    const auto& actions = p4info.actions();
    return findP4InfoObject(actions.begin(), actions.end(), actionId);
}

const ::p4::config::ActionProfile* findActionProf(const p4::config::P4Info& p4info,
                                                  P4Id actionProfId) {
    const auto& actionProfs = p4info.action_profiles();
    return findP4InfoObject(actionProfs.begin(), actionProfs.end(), actionProfId);
}

const ::p4::config::DirectCounter* findDirectCounter(const p4::config::P4Info& p4info,
                                                     P4Id counterId) {
    const auto& counters = p4info.direct_counters();
    return findP4InfoObject(counters.begin(), counters.end(), counterId);
}

const ::p4::config::DirectMeter* findDirectMeter(const p4::config::P4Info& p4info,
                                                 P4Id meterId) {
    const auto& meters = p4info.direct_meters();
    return findP4InfoObject(meters.begin(), meters.end(), meterId);
}

static boost::optional<bool> actProfHasSelector(const p4::config::P4Info& p4info, P4Id actProfId) {
    auto* actionProf = findActionProf(p4info, actProfId);
    if (actionProf == nullptr) return boost::none;
    return actionProf->with_selector();
}

static Util::JsonObject* makeTypeInt(cstring type,
                                     boost::optional<mpz_class> defaultValue = boost::none) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", type);
    if (defaultValue != boost::none)
        typeObj->emplace("default_value", *defaultValue);
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
BfRtSchemaGenerator::addCounterDataFields(Util::JsonArray* dataJson,
                                          const p4::config::CounterSpec& counterSpec) {
    static const mpz_class defaultCounterValue = 0u;
    if (counterSpec.unit() == p4::config::CounterSpec_Unit_BYTES ||
        counterSpec.unit() == p4::config::CounterSpec_Unit_BOTH) {
        auto* f = makeCommonDataField(
            BF_RT_DATA_COUNTER_SPEC_BYTES, "$COUNTER_SPEC_BYTES",
            makeTypeInt("uint64", defaultCounterValue), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
    if (counterSpec.unit() == p4::config::CounterSpec_Unit_PACKETS ||
        counterSpec.unit() == p4::config::CounterSpec_Unit_BOTH) {
        auto* f = makeCommonDataField(
            BF_RT_DATA_COUNTER_SPEC_PKTS, "$COUNTER_SPEC_PKTS",
            makeTypeInt("uint64", defaultCounterValue), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
}

void
BfRtSchemaGenerator::addMeterDataFields(Util::JsonArray* dataJson,
                                        const p4::config::MeterSpec& meterSpec) {
    // default value for rates and bursts (all GREEN)
    static const mpz_class maxUint64 = std::numeric_limits<uint64_t>::max();
    if (meterSpec.unit() == p4::config::MeterSpec_Unit_BYTES) {
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
    } else if (meterSpec.unit() == p4::config::MeterSpec_Unit_PACKETS) {
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

Util::JsonArray*
BfRtSchemaGenerator::makeActionSpecs(const p4::config::Table& table) const {
    auto* specs = new Util::JsonArray();
    for (const auto& action_ref : table.action_refs()) {
        auto* action = findAction(p4info, action_ref.id());
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
        const auto& name = pre.name();

        auto* tableJson = new Util::JsonObject();
        tableJson->emplace("name", pre.name());
        tableJson->emplace("id", pre.id());

        cstring tableType = "MatchAction_Direct";
        auto actProfId = table.implementation_id();
        if (actProfId > 0) {
            auto hasSelector = actProfHasSelector(p4info, actProfId);
            if (hasSelector == boost::none) {
                ::error("Invalid implementation id in p4info: %1%", actProfId);
                continue;
            }
            tableType = *hasSelector ? "MatchAction_Indirect_Selector" : "MatchAction_Indirect";
        }

        tableJson->emplace("table_type", tableType);
        tableJson->emplace("size", table.size());

        auto* keyJson = new Util::JsonArray();
        for (const auto& mf : table.match_fields()) {
            auto matchType = transformMatchType(mf.match_type());
            if (matchType == boost::none) {
                ::error("Unsupported match type for BF-RT: %1%", mf.match_type());
                continue;
            }
            auto* annotations = transformAnnotations(
                mf.annotations().begin(), mf.annotations().end());
            addKeyField(keyJson, mf.id(), mf.name(),
                        true /* mandatory */, *matchType,
                        makeTypeBytes(mf.bitwidth(), boost::none),
                        annotations);
        }
        tableJson->emplace("key", keyJson);

        auto* dataJson = new Util::JsonArray();

        if (tableType == "MatchAction_Direct") {
            tableJson->emplace("action_specs", makeActionSpecs(table));
        } else if (tableType == "MatchAction_Indirect") {
            auto* f = makeCommonDataField(
                BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                makeTypeInt("uint64"), false /* repeated */);
            addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
        } else if (tableType == "MatchAction_Indirect_Selector") {
            // action member id and selector group id are mutually-exclusive, so
            // we use a "oneof" here.
            auto* choicesDataJson = new Util::JsonArray();
            choicesDataJson->append(makeCommonDataField(
                BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                makeTypeInt("uint64"), false /* repeated */));
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
            if (auto* counter = findDirectCounter(p4info, directResId)) {
                addCounterDataFields(dataJson, counter->spec());
                operationsJson->append("SyncCounters");
            } else if (auto* meter = findDirectMeter(p4info, directResId)) {
                addMeterDataFields(dataJson, meter->spec());
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
        const auto& pre = actionProf.preamble();
        const auto& name = pre.name();

        auto* tableJson = new Util::JsonObject();
        tableJson->emplace("name", name);
        tableJson->emplace("id", pre.id());
        tableJson->emplace("table_type", "Action");
        tableJson->emplace("size", actionProf.size());

        auto* keyJson = new Util::JsonArray();
        addKeyField(keyJson, BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                    true /* mandatory */, "Exact", makeTypeInt("uint32"));
        tableJson->emplace("key", keyJson);

        if (actionProf.table_ids_size() == 0) {
            ::error("Action profile '%1%' is not used by any table", name);
            continue;
        }
        auto oneTableId = actionProf.table_ids(0);
        auto* oneTable = findTable(p4info, oneTableId);
        if (!oneTable) {
            ::error("Invalid table id '%1%'", oneTableId);
            continue;
        }
        tableJson->emplace("action_specs", makeActionSpecs(*oneTable));

        tableJson->emplace("data", new Util::JsonArray());

        tableJson->emplace("supported_operations", new Util::JsonArray());
        tableJson->emplace("attributes", new Util::JsonArray());

        tablesJson->append(tableJson);

        if (actionProf.with_selector()) {
            auto* tableJson = new Util::JsonObject();

            // TODO(antonin): formalize ID allocation for selector tables
            tableJson->emplace("name", name + "_sel");
            auto id = static_cast<P4Id>((pre.id() & 0xffffff) | 0x8b000000);
            tableJson->emplace("id", id);
            tableJson->emplace("table_type", "Selector");
            tableJson->emplace("size", actionProf.size());

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
            tableJson->emplace("data", dataJson);

            tableJson->emplace("supported_operations", new Util::JsonArray());
            tableJson->emplace("attributes", new Util::JsonArray());

            tablesJson->append(tableJson);
        }
    }
}

void
BfRtSchemaGenerator::addCounters(Util::JsonArray* tablesJson) const {
    for (const auto& counter : p4info.counters()) {
        const auto& pre = counter.preamble();
        const auto& name = pre.name();

        auto* tableJson = new Util::JsonObject();

        tableJson->emplace("name", name);
        tableJson->emplace("id", pre.id());
        tableJson->emplace("table_type", "Counter");
        tableJson->emplace("size", counter.size());

        auto* keyJson = new Util::JsonArray();
        addKeyField(keyJson, BF_RT_DATA_COUNTER_INDEX, "$COUNTER_INDEX",
                    true /* mandatory */, "Exact", makeTypeInt("uint32"));
        tableJson->emplace("key", keyJson);

        auto* dataJson = new Util::JsonArray();
        addCounterDataFields(dataJson, counter.spec());
        tableJson->emplace("data", dataJson);

        auto* operationsJson = new Util::JsonArray();
        operationsJson->append("Sync");
        tableJson->emplace("supported_operations", operationsJson);

        tableJson->emplace("attributes", new Util::JsonArray());

        tablesJson->append(tableJson);
    }
}

void
BfRtSchemaGenerator::addMeters(Util::JsonArray* tablesJson) const {
    for (const auto& meter : p4info.meters()) {
        const auto& pre = meter.preamble();
        const auto& name = pre.name();

        auto* tableJson = new Util::JsonObject();

        tableJson->emplace("name", name);
        tableJson->emplace("id", pre.id());
        tableJson->emplace("table_type", "Meter");
        tableJson->emplace("size", meter.size());

        auto* keyJson = new Util::JsonArray();
        addKeyField(keyJson, BF_RT_DATA_METER_INDEX, "$METER_INDEX",
                    true /* mandatory */, "Exact", makeTypeInt("uint32"));
        tableJson->emplace("key", keyJson);

        auto* dataJson = new Util::JsonArray();
        addMeterDataFields(dataJson, meter.spec());
        tableJson->emplace("data", dataJson);

        tableJson->emplace("supported_operations", new Util::JsonArray());
        tableJson->emplace("attributes", new Util::JsonArray());

        tablesJson->append(tableJson);
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
