#include "bf-p4c/control-plane/bfruntime.h"

#include <algorithm>
#include <iomanip>
#include <iterator>
#include <limits>
#include <ostream>
#include <regex>
#include <sstream>
#include <string>

#include <boost/optional.hpp>

#include "barefoot/p4info.pb.h"
#include "bf-p4c/device.h"
#include "dynamic_hash/bfn_hash_algorithm.h"
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
        // ids for fixed data fields must not collide with the auto-generated
        // ids for P4 fields (e.g. match key fields). Snapshot tables include
        // ALL the fields defined in the P4 program so we need to ensure that
        // this BF_RT_DATA_START offset is quite large.
        BF_RT_DATA_START = (1 << 16),

        BF_RT_DATA_MATCH_PRIORITY,

        BF_RT_DATA_ACTION,
        BF_RT_DATA_ACTION_MEMBER_ID,
        BF_RT_DATA_SELECTOR_GROUP_ID,
        BF_RT_DATA_ACTION_MEMBER_STATUS,
        BF_RT_DATA_MAX_GROUP_SIZE,

        BF_RT_DATA_ENTRY_TTL,
        BF_RT_DATA_ENTRY_HIT_STATE,

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

        BF_RT_DATA_LPF_SPEC_TYPE,
        BF_RT_DATA_LPF_SPEC_GAIN_TIME_CONSTANT_NS,
        BF_RT_DATA_LPF_SPEC_DECAY_TIME_CONSTANT_NS,
        BF_RT_DATA_LPF_SPEC_OUT_SCALE_DOWN_FACTOR,

        BF_RT_DATA_WRED_SPEC_TIME_CONSTANT_NS,
        BF_RT_DATA_WRED_SPEC_MIN_THRESH_CELLS,
        BF_RT_DATA_WRED_SPEC_MAX_THRESH_CELLS,
        BF_RT_DATA_WRED_SPEC_MAX_PROBABILITY,

        BF_RT_DATA_METER_INDEX,
        BF_RT_DATA_COUNTER_INDEX,
        BF_RT_DATA_REGISTER_INDEX,
        BF_RT_DATA_LPF_INDEX,
        BF_RT_DATA_WRED_INDEX,

        BF_RT_DATA_PORT_METADATA_PORT,
        BF_RT_DATA_PORT_METADATA_DEFAULT_FIELD,

        BF_RT_DATA_HASH_ALGORITHM_SEED,
        BF_RT_DATA_HASH_ALGORITHM_MSB,
        BF_RT_DATA_HASH_ALGORITHM_EXTEND,
        BF_RT_DATA_HASH_ALGORITHM_PRE_DEFINED,
        BF_RT_DATA_HASH_ALGORITHM_USER_DEFINED,
        BF_RT_DATA_HASH_VALUE,
        BF_RT_DATA_HASH_CONFIGURE_START_BIT,
        BF_RT_DATA_HASH_CONFIGURE_LENGTH,
        BF_RT_DATA_HASH_CONFIGURE_ORDER,

        BF_RT_DATA_SNAPSHOT_START_STAGE,
        BF_RT_DATA_SNAPSHOT_END_STAGE,
        BF_RT_DATA_SNAPSHOT_ENABLE,
        BF_RT_DATA_SNAPSHOT_TRIGGER_STATE,
        BF_RT_DATA_SNAPSHOT_TIMER_ENABLE,
        BF_RT_DATA_SNAPSHOT_TIMER_TRIGGER,
        BF_RT_DATA_SNAPSHOT_TIMER_VALUE_USECS,
        BF_RT_DATA_SNAPSHOT_FIELD_INFO,
        BF_RT_DATA_SNAPSHOT_CONTROL_INFO,
        BF_RT_DATA_SNAPSHOT_TABLE_INFO,
        BF_RT_DATA_SNAPSHOT_METER_ALU_INFO,
        BF_RT_DATA_SNAPSHOT_STAGE_ID,
        BF_RT_DATA_SNAPSHOT_PREV_STAGE_TRIGGER,
        BF_RT_DATA_SNAPSHOT_INGRESS_TRIGGER_MODE,
        BF_RT_DATA_SNAPSHOT_LOCAL_STAGE_TRIGGER,
        BF_RT_DATA_SNAPSHOT_NEXT_TABLE_ID,
        BF_RT_DATA_SNAPSHOT_NEXT_TABLE_NAME,
        BF_RT_DATA_SNAPSHOT_ENABLED_NEXT_TABLES,
        BF_RT_DATA_SNAPSHOT_GLOBAL_EXECUTE_TABLES,
        BF_RT_DATA_SNAPSHOT_ENABLED_GLOBAL_EXECUTE_TABLES,
        BF_RT_DATA_SNAPSHOT_LONG_BRANCH_TABLES,
        BF_RT_DATA_SNAPSHOT_ENABLED_LONG_BRANCH_TABLES,
        BF_RT_DATA_SNAPSHOT_DEPARSER_ERROR,
        BF_RT_DATA_SNAPSHOT_TABLE_ID,
        BF_RT_DATA_SNAPSHOT_TABLE_NAME,
        BF_RT_DATA_SNAPSHOT_METER_TABLE_NAME,
        BF_RT_DATA_SNAPSHOT_METER_ALU_OPERATION_TYPE,
        BF_RT_DATA_SNAPSHOT_MATCH_HIT_HANDLE,
        BF_RT_DATA_SNAPSHOT_TABLE_HIT,
        BF_RT_DATA_SNAPSHOT_TABLE_INHIBITED,
        BF_RT_DATA_SNAPSHOT_TABLE_EXECUTED,
        BF_RT_DATA_SNAPSHOT_LIVENESS_FIELD_NAME,
        BF_RT_DATA_SNAPSHOT_LIVENESS_VALID_STAGES,
        BF_RT_DATA_SNAPSHOT_THREAD,
        BF_RT_DATA_SNAPSHOT_INGRESS_CAPTURE,
        BF_RT_DATA_SNAPSHOT_EGRESS_CAPTURE,
        BF_RT_DATA_SNAPSHOT_GHOST_CAPTURE,

        BF_RT_DATA_PARSER_INSTANCE,
        BF_RT_DATA_PARSER_NAME,

        BF_RT_DATA_DEBUG_CNT_TABLE_NAME,
        BF_RT_DATA_DEBUG_CNT_TYPE,
        BF_RT_DATA_DEBUG_CNT_VALUE,
    };

    /// Common counter representation between PSA and Tofino architectures
    struct Counter;
    /// Common meter representation between PSA and Tofino architectures
    struct Meter;
    /// Common action profile / selector representation between PSA and Tofino
    /// architectures
    struct ActionProf;
    struct ActionSelector;
    /// Common digest representation between PSA and Tofino architectures
    struct Digest;
    /// Common register representation between PSA and Tofino architectures
    struct Register;

    /// Common register representation between PSA and Tofino architectures.
    /// ValueSet is only supported for TNA programs at the moment.
    struct ValueSet;

    // only for Tofino architectures
    struct Lpf;
    struct Wred;

    struct PortMetadata;

    struct Snapshot;

    struct DynHash;

    struct ParserChoices;

    struct RegisterParam;

    void addMatchTables(Util::JsonArray* tablesJson) const;
    void addActionProfs(Util::JsonArray* tablesJson) const;
    void addCounters(Util::JsonArray* tablesJson) const;
    void addMeters(Util::JsonArray* tablesJson) const;
    void addLearnFilters(Util::JsonArray* learnFiltersJson) const;
    void addTofinoExterns(Util::JsonArray* tablesJson,
                          Util::JsonArray* learnFiltersJson) const;
    void addPortMetadataExtern(Util::JsonArray* tablesJson) const;

    void addValueSet(Util::JsonArray* tablesJson, const ValueSet& wred) const;

    void addCounterCommon(Util::JsonArray* tablesJson, const Counter& counter) const;
    void addMeterCommon(Util::JsonArray* tablesJson, const Meter& meter) const;
    void addRegisterCommon(Util::JsonArray* tablesJson, const Register& meter) const;
    void addRegisterParam(Util::JsonArray* tablesJson, const RegisterParam&) const;
    void addActionProfCommon(Util::JsonArray* tablesJson, const ActionProf& actionProf) const;
    void addActionSelectorCommon(Util::JsonArray* tablesJson,
                                 const ActionSelector& actionProf) const;
    void addActionSelectorGetMemberCommon(Util::JsonArray* tablesJson,
                                          const ActionSelector& actionProf) const;
    void addLearnFilterCommon(Util::JsonArray* learnFiltersJson, const Digest& digest) const;
    void addPortMetadata(Util::JsonArray* tablesJson, const PortMetadata& portMetadata) const;
    void addDynHash(Util::JsonArray* tablesJson, const DynHash& dynHash) const;
    void addDynHashConfig(Util::JsonArray* tablesJson, const DynHash& dynHash) const;
    void addDynHashAlgorithm(Util::JsonArray* tablesJson, const DynHash& dynHash) const;
    void addDynHashCompute(Util::JsonArray* tablesJson, const DynHash& dynHash) const;
    void addPortMetadataDefault(Util::JsonArray* tablesJson) const;
    void addLpf(Util::JsonArray* tablesJson, const Lpf& lpf) const;
    void addWred(Util::JsonArray* tablesJson, const Wred& wred) const;
    void addSnapshot(Util::JsonArray* tablesJson, const Snapshot& snapshot) const;
    void addSnapshotLiveness(Util::JsonArray* tablesJson, const Snapshot& snapshot) const;
    void addParserChoices(Util::JsonArray* tablesJson, const ParserChoices& parserChoices) const;
    void addDebugCounterTable(Util::JsonArray* tablesJson) const;

    boost::optional<bool> actProfHasSelector(P4Id actProfId) const;
    /// Generates the JSON array for table action specs. When the function
    /// returns normally and @maxActionParamId is not NULL, @maxActionParamId is
    /// set to the maximum assigned id for an action parameter across all
    /// actions. This is useful if other table data fields (e.g. direct register
    /// fields) need to receive a distinct id in the same space.
    Util::JsonArray* makeActionSpecs(const p4configv1::Table& table,
                                     P4Id* maxActionParamId = nullptr) const;
    boost::optional<Counter> getDirectCounter(P4Id counterId) const;
    boost::optional<Meter> getDirectMeter(P4Id meterId) const;
    boost::optional<Register> getDirectRegister(P4Id registerId) const;
    boost::optional<Lpf> getDirectLpf(P4Id lpfId) const;
    boost::optional<Wred> getDirectWred(P4Id wredId) const;

    /// Transforms a P4Info @typeSpec to a list of JSON objects matching the
    /// BF-RT format. @instanceType and @instanceName are used for logging error
    /// messages. This method currenty only supports fixed-width bitstrings as
    /// well as non-nested structs and tuples. All field names are prefixed with
    /// @prefix and suffixed with @suffix. Field ids are assigned incrementally
    /// starting at @idOffset. Field names are taken from the P4 program
    /// when possible; for tuples they are autogenerated (f1, f2, ...) unless
    /// supplied through @fieldNames.
    void transformTypeSpecToDataFields(Util::JsonArray* fieldsJson,
                                       const p4configv1::P4DataTypeSpec& typeSpec,
                                       cstring instanceType,
                                       cstring instanceName,
                                       const std::vector<cstring> *fieldNames = nullptr,
                                       cstring prefix = "",
                                       cstring suffix = "",
                                       P4Id idOffset = 1) const;

    static Util::JsonObject* makeCommonDataField(P4Id id, cstring name,
                                                 Util::JsonObject* type, bool repeated,
                                                 Util::JsonArray* annotations = nullptr);

    static Util::JsonObject* makeContainerDataField(P4Id id, cstring name,
                                                    Util::JsonArray* items, bool repeated,
                                                    Util::JsonArray* annotations = nullptr);

    static void addActionDataField(Util::JsonArray* dataJson, P4Id id, const std::string& name,
                                   bool mandatory, bool read_only, Util::JsonObject* type,
                                   Util::JsonArray* annotations = nullptr);

    static void addKeyField(Util::JsonArray* dataJson, P4Id id, cstring name,
                            bool mandatory, cstring matchType, Util::JsonObject* type,
                            Util::JsonArray* annotations = nullptr);

    static void addCounterDataFields(Util::JsonArray* dataJson, const Counter& counter);

    static void addMeterDataFields(Util::JsonArray* dataJson, const Meter& meter);
    static void addLpfDataFields(Util::JsonArray* dataJson);
    static void addWredDataFields(Util::JsonArray* dataJson);

    static Util::JsonObject* initTableJson(const std::string& name, P4Id id, cstring tableType,
                                           int64_t size, Util::JsonArray* annotations = nullptr);


    static void addToDependsOn(Util::JsonObject* tableJson, P4Id id);

    /// Add register data fields to the JSON data array for a BFRT table. Field
    /// ids are assigned incrementally starting at @idOffset, which is 1 by
    /// default.
    void addRegisterDataFields(Util::JsonArray* dataJson,
                               const Register& register_,
                               P4Id idOffset = 1) const;

    /// Add register parameter data fields to the JSON data array for a BFRT table. Field
    /// ids are assigned incrementally starting at @idOffset, which is 1 by
    /// default.
    void addRegisterParamDataFields(Util::JsonArray* dataJson,
                                    const RegisterParam& register_param_,
                                    P4Id idOffset = 1) const;

    const p4configv1::P4Info& p4info;
};

// See https://stackoverflow.com/a/33799784/4538702
static std::string escapeJson(const std::string& s) {
    std::ostringstream o;
    for (char c : s) {
        switch (c) {
            case '"': o << "\\\""; break;
            case '\\': o << "\\\\"; break;
            case '\b': o << "\\b"; break;
            case '\f': o << "\\f"; break;
            case '\n': o << "\\n"; break;
            case '\r': o << "\\r"; break;
            case '\t': o << "\\t"; break;
            default: {
                if ('\x00' <= c && c <= '\x1f') {
                    o << "\\u"
                      << std::hex << std::setw(4) << std::setfill('0') << static_cast<int>(c);
                } else {
                    o << c;
                }
            }
        }
    }
    return o.str();
}

static Util::JsonObject* transformAnnotation(const std::string& annotation) {
    auto* annotationJson = new Util::JsonObject();
    // TODO(antonin): annotation string will need to be parsed so we can have it
    // in key/value format here.
    annotationJson->emplace("name", escapeJson(annotation));
    return annotationJson;
}

template <typename It>
static Util::JsonArray* transformAnnotations(const It& first, const It& last) {
    auto* annotations = new Util::JsonArray();
    for (auto it = first; it != last; it++)
        annotations->append(transformAnnotation(*it));
    return annotations;
}

static Util::JsonArray* transformAnnotations(const p4configv1::Preamble& pre) {
    return transformAnnotations(pre.annotations().begin(), pre.annotations().end());
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
        case p4configv1::MatchField_MatchType_OPTIONAL:
            return cstring("Optional");
        default:
            return boost::none;
    }
}

static boost::optional<cstring> transformOtherMatchType(std::string matchType) {
    if (matchType == "atcam_partition_index")
        return cstring("ATCAM");
    else if (matchType == "dleft_hash")
        return cstring("DLEFT_HASH");
    else
        return boost::none;
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
                                       boost::optional<int64_t> defaultValue = boost::none) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", "bytes");
    typeObj->emplace("width", width);
    if (defaultValue != boost::none)
        typeObj->emplace("default_value", *defaultValue);
    return typeObj;
}

static Util::JsonObject* makeTypeFloat(cstring type) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", type);
    return typeObj;
}

static Util::JsonObject* makeTypeEnum(const std::vector<cstring>& choices,
                                      boost::optional<cstring> defaultValue = boost::none) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", "string");
    auto* choicesArray = new Util::JsonArray();
    for (auto choice : choices)
        choicesArray->append(choice);
    typeObj->emplace("choices", choicesArray);
    if (defaultValue != boost::none)
        typeObj->emplace("default_value", *defaultValue);
    return typeObj;
}

static Util::JsonObject* makeTypeString(boost::optional<cstring> defaultValue = boost::none) {
    auto* typeObj = new Util::JsonObject();
    typeObj->emplace("type", "string");
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

static void addROSingleton(Util::JsonArray* dataJson, Util::JsonObject* dataField) {
    addSingleton(dataJson, dataField, false, true);
}

/// Takes a simple P4Info P4DataTypeSpec message in its factory method and
/// flattens it into a vector of BF-RT "fields" which can be used as key fields
/// or data fields. The class provides iterators.
class TypeSpecParser {
 public:
    struct Field {
        cstring name;
        P4Id id;
        Util::JsonObject* type;
    };

    using Fields = std::vector<Field>;
    using iterator = Fields::iterator;
    using const_iterator = Fields::const_iterator;

    static TypeSpecParser make(const p4configv1::P4Info& p4info,
                               const p4configv1::P4DataTypeSpec& typeSpec,
                               cstring instanceType,
                               cstring instanceName,
                               const std::vector<cstring> *fieldNames = nullptr,
                               cstring prefix = "",
                               cstring suffix = "",
                               P4Id idOffset = 1) {
        Fields fields;
        const auto& typeInfo = p4info.type_info();

        auto addField = [&](P4Id id, const std::string& name,
                            const p4configv1::P4DataTypeSpec& fSpec) {
            Util::JsonObject* type = nullptr;
            // Add support for required P4DataTypeSpec types here to generate
            // the correct field width
            if (fSpec.has_serializable_enum()) {
                auto enums = typeInfo.serializable_enums();
                auto e = fSpec.serializable_enum().name();
                auto typeEnum = enums.find(e);
                if (typeEnum == enums.end()) {
                    ::error("Enum type '%1%' not found in typeInfo for '%2%' '%3%'",
                            e, instanceType, instanceName);
                    return;
                }
                type = makeTypeBytes(typeEnum->second.underlying_type().bitwidth());
            } else if (fSpec.has_bitstring()) {
                if (fSpec.bitstring().has_bit())
                    type = makeTypeBytes(fSpec.bitstring().bit().bitwidth());
                else if (fSpec.bitstring().has_int_())
                    type = makeTypeBytes(fSpec.bitstring().int_().bitwidth());
                else if (fSpec.bitstring().has_varbit())
                    type = makeTypeBytes(fSpec.bitstring().varbit().max_bitwidth());
            } else if (fSpec.has_bool_()) {
                type = makeTypeBool(1);
            }

            if (!type) {
                ::error("Error when generating BF-RT info for '%1%' '%2%': "
                        "packed type is too complex",
                        instanceType, instanceName);
                return;
            }

            fields.push_back({prefix + name + suffix, id, type});
        };

        if (typeSpec.has_struct_()) {
            auto structName = typeSpec.struct_().name();
            auto p_it = typeInfo.structs().find(structName);
            BUG_CHECK(p_it != typeInfo.structs().end(),
                      "Struct name '%1%' not found in P4Info map", structName);
            P4Id id = idOffset;
            for (const auto& member : p_it->second.members())
                addField(id++, member.name(), member.type_spec());
        } else if (typeSpec.has_tuple()) {
            P4Id id = idOffset;
            int fNameIdx = 0;
            for (const auto& member : typeSpec.tuple().members()) {
                std::string fName;
                if (fieldNames && int(fieldNames->size()) > fNameIdx) {
                    fName = (*fieldNames)[fNameIdx++];
                } else {
                    // TODO(antonin): we do not really have better names for now, do
                    // we need to add support for annotations of tuple members in
                    // P4Info?
                    fName = "f" + std::to_string(id);
                }
                addField(id++, fName, member);
            }
        } else if (typeSpec.has_bitstring()) {
            // TODO(antonin): same as above, we need a way to pass name
            // annotations
            std::string fName;
            if (fieldNames && fieldNames->size() > 0) {
                fName = (*fieldNames)[0];
            } else {
                // TODO(antonin): we do not really have better names for now, do
                // we need to add support for annotations of tuple members in
                // P4Info?
                fName = "f1";
            }
            addField(idOffset, fName, typeSpec);
        } else if (typeSpec.has_header()) {
            auto headerName = typeSpec.header().name();
            auto p_it = typeInfo.headers().find(headerName);
            BUG_CHECK(p_it != typeInfo.headers().end(),
                      "Header name '%1%' not found in P4Info map", headerName);
            P4Id id = idOffset;
            for (const auto& member : p_it->second.members()) {
                auto* type = makeTypeBytes(member.type_spec().bit().bitwidth());
                fields.push_back({prefix + member.name() + suffix, id++, type});
            }
        } else if (typeSpec.has_serializable_enum()) {
            auto enumName = typeSpec.serializable_enum().name();
            auto p_it = typeInfo.serializable_enums().find(enumName);
            BUG_CHECK(p_it != typeInfo.serializable_enums().end(),
                      "Serializable name '%1%' not found in P4Info map", enumName);
            P4Id id = idOffset;
            for (const auto& member : p_it->second.members()) {
                auto* type = makeTypeBytes(p_it->second.underlying_type().bitwidth());
                fields.push_back({prefix + member.name() + suffix, id++, type});
            }
        } else {
            ::error("Error when generating BF-RT info for '%1%' '%2%': "
                    "only structs, headers, tuples, bitstrings and "
                    "serializable enums are currently supported types",
                    instanceType, instanceName);
        }

        return TypeSpecParser(std::move(fields));
    }

    iterator begin() { return fields.begin(); }
    const_iterator cbegin() { return fields.cbegin(); }
    iterator end() { return fields.end(); }
    const_iterator cend() { return fields.cend(); }

 private:
    explicit TypeSpecParser(Fields&& fields)
        : fields(std::move(fields)) { }

    Fields fields;
};

/// Common counter representation between PSA and Tofino architectures
struct BfRtSchemaGenerator::Counter {
    enum Unit { UNSPECIFIED = 0, BYTES = 1, PACKETS = 2, BOTH = 3 };
    std::string name;
    P4Id id;
    int64_t size;
    Unit unit;
    Util::JsonArray* annotations;

    static boost::optional<Counter> from(const p4configv1::Counter& counterInstance) {
        const auto& pre = counterInstance.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::COUNTER);
        // TODO(antonin): this works because the enum values are the same for
        // Counter::Unit and for CounterSpec::Unit, but this may not be very
        // future-proof.
        auto unit = static_cast<Counter::Unit>(counterInstance.spec().unit());
        return Counter{pre.name(), id, counterInstance.size(), unit, transformAnnotations(pre)};
    }

    static boost::optional<Counter> fromDirect(const p4configv1::DirectCounter& counterInstance) {
        const auto& pre = counterInstance.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::DIRECT_COUNTER);
        auto unit = static_cast<Counter::Unit>(counterInstance.spec().unit());
        return Counter{pre.name(), id, 0, unit, transformAnnotations(pre)};
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
        return Counter{pre.name(), pre.id(), counter.size(), unit, transformAnnotations(pre)};
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
        return Counter{pre.name(), pre.id(), 0, unit, transformAnnotations(pre)};
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
    Util::JsonArray* annotations;

    static boost::optional<Meter> from(const p4configv1::Meter& meterInstance) {
        const auto& pre = meterInstance.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::METER);
        // TODO(antonin): this works because the enum values are the same for
        // Meter::Unit and for MeterSpec::Unit, but this may not be very
        // future-proof.
        auto unit = static_cast<Meter::Unit>(meterInstance.spec().unit());
        // TODO(antonin): the standard Meter message in P4Info doesn't have the
        // notion of color-awareness any more since according to PSA it is a
        // property of the "execute" method and not of the extern instance
        // itself. This means it may be tricky to support color-aware meters for
        // PSA programs on Tofino. However, we don't have this issue for TNA
        // programs, since the TNA Meter message does include color-awareness
        // information.
        auto type = Type::COLOR_UNAWARE;
        return Meter{pre.name(), id, meterInstance.size(), unit, type, transformAnnotations(pre)};
    }

    static boost::optional<Meter> fromDirect(const p4configv1::DirectMeter& meterInstance) {
        const auto& pre = meterInstance.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::DIRECT_METER);
        auto unit = static_cast<Meter::Unit>(meterInstance.spec().unit());
        auto type = Type::COLOR_UNAWARE;
        return Meter{pre.name(), id, 0, unit, type, transformAnnotations(pre)};
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
        return Meter{pre.name(), pre.id(), meter.size(), unit, type, transformAnnotations(pre)};
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
        return Meter{pre.name(), pre.id(), 0, unit, type, transformAnnotations(pre)};
    }
};

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

struct BfRtSchemaGenerator::ActionSelector {
    std::string name;
    std::string get_mem_name;
    P4Id id;
    P4Id get_mem_id;
    int64_t max_group_size;
    int64_t num_groups;  // aka size of selector
    std::vector<P4Id> tableIds;
    Util::JsonArray* annotations;

    static boost::optional<ActionSelector> from(const p4configv1::P4Info& p4info,
                                            const p4configv1::ActionProfile& actionProfile) {
        const auto& pre = actionProfile.preamble();
        if (!actionProfile.with_selector())
            return boost::none;
        auto selectorId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_SELECTOR);
        auto selectorGetMemId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_SELECTOR_GET_MEMBER);
        auto tableIds = collectTableIds(
            p4info, actionProfile.table_ids().begin(), actionProfile.table_ids().end());
        return ActionSelector{pre.name(), pre.name() + "_get_member",
                              selectorId, selectorGetMemId,
                              actionProfile.max_group_size(), actionProfile.size(),
                              tableIds, transformAnnotations(pre)};
    }

    static boost::optional<ActionSelector> fromTofinoActionSelector(
        const p4configv1::P4Info& p4info, const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::ActionSelector actionSelector;
        if (!externInstance.info().UnpackTo(&actionSelector)) {
            ::error("Extern instance %1% does not pack an ActionSelector object", pre.name());
            return boost::none;
        }
        auto selectorId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_SELECTOR);
        auto selectorGetMemId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_SELECTOR_GET_MEMBER);
        auto tableIds = collectTableIds(
            p4info, actionSelector.table_ids().begin(), actionSelector.table_ids().end());
        return ActionSelector{pre.name(), pre.name() + "_get_member",
                              selectorId, selectorGetMemId,
                              actionSelector.max_group_size(), actionSelector.num_groups(),
                              tableIds, transformAnnotations(pre)};
    }
};

/// Common action profile / selector representation between PSA and Tofino
/// architectures
struct BfRtSchemaGenerator::ActionProf {
    std::string name;
    P4Id id;
    int64_t size;
    std::vector<P4Id> tableIds;
    Util::JsonArray* annotations;

    static P4Id makeActProfId(P4Id implementationId) {
      return makeBfRtId(implementationId, ::barefoot::P4Ids::ACTION_PROFILE);
    }

    static P4Id makeActSelectorId(P4Id implementationId) {
      return makeBfRtId(implementationId, ::barefoot::P4Ids::ACTION_SELECTOR);
    }

    static boost::optional<ActionProf> from(const p4configv1::P4Info& p4info,
                                            const p4configv1::ActionProfile& actionProfile) {
        const auto& pre = actionProfile.preamble();
        auto profileId = makeBfRtId(pre.id(), ::barefoot::P4Ids::ACTION_PROFILE);
        auto tableIds = collectTableIds(
            p4info, actionProfile.table_ids().begin(), actionProfile.table_ids().end());
        return ActionProf{pre.name(), profileId, actionProfile.size(), tableIds,
                          transformAnnotations(pre)};
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
        return ActionProf{pre.name(), pre.id(), actionProfile.size(), tableIds,
                          transformAnnotations(pre)};
    }
};

/// Common digest representation between PSA and Tofino architectures
struct BfRtSchemaGenerator::Digest {
    std::string name;
    P4Id id;
    p4configv1::P4DataTypeSpec typeSpec;
    Util::JsonArray* annotations;

    static boost::optional<Digest> from(const p4configv1::Digest& digest) {
        const auto& pre = digest.preamble();
        auto id = makeBfRtId(pre.id(), ::barefoot::P4Ids::DIGEST);
        return Digest{pre.name(), id, digest.type_spec(), transformAnnotations(pre)};
    }

    static boost::optional<Digest> fromTofino(const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Digest digest;
        if (!externInstance.info().UnpackTo(&digest)) {
            ::error("Extern instance %1% does not pack a Digest object", pre.name());
            return boost::none;
        }
        return Digest{pre.name(), pre.id(), digest.type_spec(), transformAnnotations(pre)};
    }
};

struct BfRtSchemaGenerator::Register {
    std::string name;
    std::string dataFieldName;
    P4Id id;
    int64_t size;
    p4configv1::P4DataTypeSpec typeSpec;
    Util::JsonArray* annotations;

    static boost::optional<Register> fromTofino(const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Register register_;
        if (!externInstance.info().UnpackTo(&register_)) {
            ::error("Extern instance %1% does not pack a Register object", pre.name());
            return boost::none;
        }
        return Register{pre.name(), register_.data_field_name(), pre.id(),
                register_.size(), register_.type_spec(), transformAnnotations(pre)};
    }

    static boost::optional<Register> fromTofinoDirect(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::DirectRegister register_;
        if (!externInstance.info().UnpackTo(&register_)) {
            ::error("Extern instance %1% does not pack a Register object", pre.name());
            return boost::none;
        }
        return Register{pre.name(), register_.data_field_name(), pre.id(), 0,
                register_.type_spec(), transformAnnotations(pre)};
    }
};

struct BfRtSchemaGenerator::RegisterParam {
    std::string name;
    std::string dataFieldName;
    P4Id id;
    P4Id tableId;
    int64_t initial_value;
    p4configv1::P4DataTypeSpec typeSpec;
    Util::JsonArray* annotations;

    static boost::optional<RegisterParam>
    fromTofino(const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::RegisterParam register_param_;
        if (!externInstance.info().UnpackTo(&register_param_)) {
            ::error("Extern instance %1% does not pack a RegisterParam object", pre.name());
            return boost::none;
        }
        return RegisterParam{pre.name(),
                             register_param_.data_field_name(),
                             pre.id(),
                             register_param_.table_id(),
                             register_param_.initial_value(),
                             register_param_.type_spec(),
                             transformAnnotations(pre)};
    }
};

struct BfRtSchemaGenerator::PortMetadata {
    P4Id id;
    std::string name;
    std::string key_name;
    p4configv1::P4DataTypeSpec typeSpec;
    Util::JsonArray* annotations;

    static boost::optional<PortMetadata> fromTofino(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::PortMetadata portMetadata;
        if (!externInstance.info().UnpackTo(&portMetadata)) {
            ::error("Extern instance %1% does not pack a PortMetadata object", pre.name());
            return boost::none;
        }
        return PortMetadata{pre.id(), pre.name(),
                            portMetadata.key_name(), portMetadata.type_spec(),
                            transformAnnotations(pre)};
    }
};

struct BfRtSchemaGenerator::DynHash {
    const std::string getAlgorithmTableName() const {
        return name + ".algorithm"; }
    const std::string getConfigTableName() const {
        return name + ".configure"; }
    const std::string getComputeTableName() const {
        return name + ".compute"; }

    const cstring name;
    const P4Id cfgId;
    const P4Id cmpId;
    const P4Id algId;
    const p4configv1::P4DataTypeSpec typeSpec;
    struct hashField {
        cstring hashFieldName;        // Field Name
        bool isConstant;              // true if field is a constant
    };
    const std::vector<hashField> hashFieldInfo;
    const int hashWidth;
    Util::JsonArray* annotations;

    std::vector<cstring> getHashFieldNames() const {
        std::vector<cstring> hashFieldNames;
        for (auto &f : hashFieldInfo) {
            hashFieldNames.push_back(f.hashFieldName);
        }
        return hashFieldNames;
    }

    bool is_constant(cstring name) const {
        for (auto &f : hashFieldInfo)
            if (f.hashFieldName == name) return f.isConstant;
        return false;
    }

    static boost::optional<DynHash> fromTofino(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::DynHash dynHash;
        if (!externInstance.info().UnpackTo(&dynHash)) {
            ::error("Extern instance %1% does not pack a PortMetadata object", pre.name());
            return boost::none;
        }
        std::vector<hashField> hfInfo;
        for (auto f : dynHash.field_infos()) {
            hfInfo.push_back({f.field_name(), f.is_constant()});
        }
        auto cfgId = makeBfRtId(pre.id(), ::barefoot::P4Ids::HASH_CONFIGURE);
        auto cmpId = makeBfRtId(pre.id(), ::barefoot::P4Ids::HASH_COMPUTE);
        auto algId = makeBfRtId(pre.id(), ::barefoot::P4Ids::HASH_ALGORITHM);
        return DynHash{pre.name(), cfgId, cmpId, algId, dynHash.type_spec(),
                       hfInfo, dynHash.hash_width(), transformAnnotations(pre)};
    }
};

struct BfRtSchemaGenerator::Snapshot {
    std::string name;
    std::string gress;
    P4Id id;
    struct Field {
        P4Id id;
        std::string name;
        int32_t bitwidth;
    };
    std::vector<Field> fields;

    std::string getCfgTblName() const { return name + ".cfg"; }

    std::string getTrigTblName() const { return name + "." + gress + "_trigger"; }

    std::string getDataTblName() const { return name + "." + gress + "_data"; }

    std::string getLivTblName() const { return name + "." + gress + "_liveness"; }

    static boost::optional<Snapshot> fromTofino(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Snapshot snapshot;
        if (!externInstance.info().UnpackTo(&snapshot)) {
            ::error("Extern instance %1% does not pack a Snapshot object", pre.name());
            return boost::none;
        }
        std::string name = snapshot.pipe() + ".snapshot";
        std::string gress;
        if (snapshot.direction() == ::barefoot::DIRECTION_INGRESS)
          gress = "ingress";
        else if (snapshot.direction() == ::barefoot::DIRECTION_EGRESS)
          gress = "egress";
        else
          BUG("Unknown direction");
        std::vector<Field> fields;
        for (const auto& f : snapshot.fields())
          fields.push_back({f.id(), f.name(), f.bitwidth()});
        return Snapshot{name, gress, pre.id(), std::move(fields)};
    }
};

struct BfRtSchemaGenerator::ParserChoices {
    std::string name;
    P4Id id;
    std::vector<cstring> choices;

    static boost::optional<ParserChoices> fromTofino(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::ParserChoices parserChoices;
        if (!externInstance.info().UnpackTo(&parserChoices)) {
            ::error("Extern instance %1% does not pack a ParserChoices object", pre.name());
            return boost::none;
        }
        std::string name;
        // The name is "<pipe>.<gress>.$PARSER_CONFIGURE".
        if (parserChoices.direction() == ::barefoot::DIRECTION_INGRESS)
          name = parserChoices.pipe() + "." + "ingress_parser" + "." + "$PARSER_CONFIGURE";
        else if (parserChoices.direction() == ::barefoot::DIRECTION_EGRESS)
          name = parserChoices.pipe() + "." + "egress_parser" + "." + "$PARSER_CONFIGURE";
        else
          BUG("Unknown direction");
        std::vector<cstring> choices;
        // For each possible parser, we have to use the "architecture name" as
        // the name exposed to the control plane, because this is the only name
        // which is guaranteed to exist ane be unique.
        for (const auto& choice : parserChoices.choices())
          choices.push_back(choice.arch_name());
        return ParserChoices{name, pre.id(), std::move(choices)};
    }
};

// It is tempting to unify the code for Lpf & Wred (using CRTP?) but the
// resulting code doesn't look too good and is not really less verbose. In
// particular aggregate initialization is not possible when a class has a base.
struct BfRtSchemaGenerator::Lpf {
    std::string name;
    P4Id id;
    int64_t size;
    Util::JsonArray* annotations;

    static boost::optional<Lpf> fromTofino(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Lpf lpf;
        if (!externInstance.info().UnpackTo(&lpf)) {
            ::error("Extern instance %1% does not pack a Lpf object", pre.name());
            return boost::none;
        }
        return Lpf{pre.name(), pre.id(), lpf.size(), transformAnnotations(pre)};
    }

    static boost::optional<Lpf> fromTofinoDirect(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::DirectLpf lpf;
        if (!externInstance.info().UnpackTo(&lpf)) {
            ::error("Extern instance %1% does not pack a Lpf object", pre.name());
            return boost::none;
        }
        return Lpf{pre.name(), pre.id(), 0, transformAnnotations(pre)};
    }
};

struct BfRtSchemaGenerator::Wred {
    std::string name;
    P4Id id;
    int64_t size;
    Util::JsonArray* annotations;

    static boost::optional<Wred> fromTofino(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Wred wred;
        if (!externInstance.info().UnpackTo(&wred)) {
            ::error("Extern instance %1% does not pack a Wred object", pre.name());
            return boost::none;
        }
        return Wred{pre.name(), pre.id(), wred.size(), transformAnnotations(pre)};
    }

    static boost::optional<Wred> fromTofinoDirect(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::DirectWred wred;
        if (!externInstance.info().UnpackTo(&wred)) {
            ::error("Extern instance %1% does not pack a Wred object", pre.name());
            return boost::none;
        }
        return Wred{pre.name(), pre.id(), 0, transformAnnotations(pre)};
    }
};

/// This struct is meant to be used as a common representation of ValueSet
/// objects for both PSA & TNA programs. However, at the moment we only support
/// TNA ValueSet objects.
struct BfRtSchemaGenerator::ValueSet {
    std::string name;
    P4Id id;
    p4configv1::P4DataTypeSpec typeSpec;
    const int64_t size;
    Util::JsonArray* annotations;

    static boost::optional<ValueSet> fromTofino(const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::ValueSet valueSet;
        if (!externInstance.info().UnpackTo(&valueSet)) {
            ::error("Extern instance %1% does not pack a value set object", pre.name());
            return boost::none;
        }
        return ValueSet{pre.name(), pre.id(), valueSet.type_spec(), valueSet.size(),
                        transformAnnotations(pre)};
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

boost::optional<BfRtSchemaGenerator::Register>
BfRtSchemaGenerator::getDirectRegister(P4Id registerId) const {
    if (!isOfType(registerId, ::barefoot::P4Ids::DIRECT_REGISTER)) return boost::none;
    auto* externInstance = Tofino::findExternInstance(p4info, registerId);
    if (externInstance == nullptr) return boost::none;
    return Register::fromTofinoDirect(*externInstance);
}

boost::optional<BfRtSchemaGenerator::Lpf>
BfRtSchemaGenerator::getDirectLpf(P4Id lpfId) const {
    if (isOfType(lpfId, ::barefoot::P4Ids::DIRECT_LPF)) {
        auto* externInstance = Tofino::findExternInstance(p4info, lpfId);
        if (externInstance == nullptr) return boost::none;
        return Lpf::fromTofinoDirect(*externInstance);
    }
    return boost::none;
}

boost::optional<BfRtSchemaGenerator::Wred>
BfRtSchemaGenerator::getDirectWred(P4Id wredId) const {
    if (isOfType(wredId, ::barefoot::P4Ids::DIRECT_WRED)) {
        auto* externInstance = Tofino::findExternInstance(p4info, wredId);
        if (externInstance == nullptr) return boost::none;
        return Wred::fromTofinoDirect(*externInstance);
    }
    return boost::none;
}

Util::JsonObject*
BfRtSchemaGenerator::makeCommonDataField(P4Id id, cstring name,
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

Util::JsonObject*
BfRtSchemaGenerator::makeContainerDataField(P4Id id, cstring name,
                                            Util::JsonArray* items, bool repeated,
                                            Util::JsonArray* annotations) {
    auto* dataField = new Util::JsonObject();
    dataField->emplace("id", id);
    dataField->emplace("name", name);
    dataField->emplace("repeated", repeated);
    if (annotations != nullptr)
        dataField->emplace("annotations", annotations);
    else
        dataField->emplace("annotations", new Util::JsonArray());
    dataField->emplace("container", items);
    return dataField;
}

void
BfRtSchemaGenerator::addActionDataField(Util::JsonArray* dataJson, P4Id id, const std::string& name,
                                        bool mandatory, bool read_only, Util::JsonObject* type,
                                        Util::JsonArray* annotations) {
    auto* dataField = new Util::JsonObject();
    dataField->emplace("id", id);
    dataField->emplace("name", name);
    dataField->emplace("repeated", false);
    dataField->emplace("mandatory", mandatory);
    dataField->emplace("read_only", read_only);
    if (annotations != nullptr)
        dataField->emplace("annotations", annotations);
    else
        dataField->emplace("annotations", new Util::JsonArray());
    dataField->emplace("type", type);
    dataJson->append(dataField);
}

void
BfRtSchemaGenerator::addKeyField(Util::JsonArray* dataJson, P4Id id, cstring name,
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

/* static */ Util::JsonObject*
BfRtSchemaGenerator::initTableJson(const std::string& name,
                                   P4Id id,
                                   cstring tableType,
                                   int64_t size,
                                   Util::JsonArray* annotations) {
    auto* tableJson = new Util::JsonObject();
    tableJson->emplace("name", name);
    tableJson->emplace("id", id);
    tableJson->emplace("table_type", tableType);
    tableJson->emplace("size", size);
    if (annotations != nullptr) tableJson->emplace("annotations", annotations);
    tableJson->emplace("depends_on", new Util::JsonArray());
    return tableJson;
}

/* static */ void
BfRtSchemaGenerator::addToDependsOn(Util::JsonObject* tableJson, P4Id id) {
    auto* dependsOnJson = tableJson->get("depends_on")->to<Util::JsonArray>();
    CHECK_NULL(dependsOnJson);
    dependsOnJson->append(id);
}

void
BfRtSchemaGenerator::addValueSet(Util::JsonArray* tablesJson,
                                 const ValueSet& valueSet) const {
    auto* tableJson = initTableJson(
        valueSet.name, valueSet.id, "ParserValueSet", valueSet.size, valueSet.annotations);

    auto* keyJson = new Util::JsonArray();
    auto parser = TypeSpecParser::make(p4info, valueSet.typeSpec, "ValueSet", valueSet.name);
    for (const auto &f : parser) {
        // DRV-3112 - Make key fields not mandatory, this allows user to use a
        // driver initialized default value (0).
        addKeyField(keyJson, f.id, f.name, false /* mandatory */, "Ternary", f.type);
    }
    tableJson->emplace("key", keyJson);

    tableJson->emplace("data", new Util::JsonArray());
    tableJson->emplace("supported_operations", new Util::JsonArray());
    auto* attributesJson =  new Util::JsonArray();
    attributesJson->append("EntryScope");
    tableJson->emplace("attributes", attributesJson);

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addCounterCommon(Util::JsonArray* tablesJson, const Counter& counter) const {
    auto* tableJson = initTableJson(
        counter.name, counter.id, "Counter", counter.size, counter.annotations);

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
    auto* tableJson = initTableJson(meter.name, meter.id, "Meter", meter.size);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_METER_INDEX, "$METER_INDEX",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    addMeterDataFields(dataJson, meter);
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());

    auto* attributesJson = new Util::JsonArray();
    attributesJson->append("MeterByteCountAdjust");
    tableJson->emplace("attributes", attributesJson);

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::transformTypeSpecToDataFields(Util::JsonArray* fieldsJson,
                                                   const p4configv1::P4DataTypeSpec& typeSpec,
                                                   cstring instanceType,
                                                   cstring instanceName,
                                                   const std::vector<cstring> *fieldNames,
                                                   cstring prefix,
                                                   cstring suffix,
                                                   P4Id idOffset) const {
    auto parser = TypeSpecParser::make(
        p4info, typeSpec, instanceType, instanceName, fieldNames, prefix, suffix, idOffset);
    for (const auto &f : parser) {
        auto* fJson = makeCommonDataField(f.id, f.name, f.type, false /* repeated */);
        fieldsJson->append(fJson);
    }
}

void
BfRtSchemaGenerator::addRegisterDataFields(Util::JsonArray* dataJson,
                                           const Register& register_,
                                           P4Id idOffset) const {
    auto* fieldsJson = new Util::JsonArray();
    transformTypeSpecToDataFields(
        fieldsJson, register_.typeSpec, "Register", register_.name,
        nullptr, register_.dataFieldName + ".", "", idOffset);
    for (auto* f : *fieldsJson) {
        auto* fObj = f->to<Util::JsonObject>();
        CHECK_NULL(fObj);
        auto* fAnnotations = fObj->get("annotations")->to<Util::JsonArray>();
        CHECK_NULL(fAnnotations);
        // Add BF-RT "native" annotation to indicate to the BF-RT implementation
        // - and potentially applications - that this data field is stateful
        // data. The specific string for this annotation may be changed in the
        // future if we start introducing more BF-RT annotations, in order to
        // keep the syntax consistent.
        {
            auto* classAnnotation = new Util::JsonObject();
            classAnnotation->emplace("name", "$bfrt_field_class");
            classAnnotation->emplace("value", "register_data");
            fAnnotations->append(classAnnotation);
        }
        addSingleton(dataJson, fObj, true /* mandatory */, false /* read-only */);
    }
}

void
BfRtSchemaGenerator::addRegisterCommon(Util::JsonArray* tablesJson,
                                       const Register& register_) const {
    auto* tableJson = initTableJson(register_.name, register_.id, "Register", register_.size);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_REGISTER_INDEX, "$REGISTER_INDEX",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    addRegisterDataFields(dataJson, register_);
    tableJson->emplace("data", dataJson);

    auto* operationsJson = new Util::JsonArray();
    operationsJson->append("Sync");
    tableJson->emplace("supported_operations", operationsJson);

    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addRegisterParamDataFields(Util::JsonArray* dataJson,
                                                const RegisterParam& register_param_,
                                                P4Id idOffset) const {
    auto typeSpec = register_param_.typeSpec;
    Util::JsonObject *type = nullptr;
    if (typeSpec.has_bitstring()) {
        if (typeSpec.bitstring().has_bit()) {
            type = makeTypeBytes(typeSpec.bitstring().bit().bitwidth(),
                register_param_.initial_value);
        } else if (typeSpec.bitstring().has_int_()) {
            type = makeTypeBytes(typeSpec.bitstring().int_().bitwidth(),
                register_param_.initial_value);
        }
    }
    if (type == nullptr) return;
    auto *f = makeCommonDataField(idOffset, "value", type, false /* repeated */);
    addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
}

void
BfRtSchemaGenerator::addRegisterParam(Util::JsonArray* tablesJson,
                                      const RegisterParam& register_param_) const {
    auto* tableJson = initTableJson(register_param_.name, register_param_.id,
        "RegisterParam", 1 /* size */, register_param_.annotations);

    // The register or M/A table the register parameter is attached to
    // The zero value means it is not used anywhere and hasn't been optimized out.
    if (register_param_.tableId != 0)
        addToDependsOn(tableJson, register_param_.tableId);

    tableJson->emplace("key", new Util::JsonArray());

    auto* dataJson = new Util::JsonArray();
    addRegisterParamDataFields(dataJson, register_param_);
    tableJson->emplace("data", dataJson);

    tableJson->emplace("attributes", new Util::JsonArray());
    tableJson->emplace("supported_operations", new Util::JsonArray());

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
    auto* tableJson = initTableJson(
        actionProf.name, actionProf.id, "Action", actionProf.size, actionProf.annotations);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    if (actionProf.tableIds.empty()) {
        ::warning("Action profile '%1%' is not used by any table, skipping it", actionProf.name);
        return;
    }
    auto oneTableId = actionProf.tableIds.at(0);
    auto* oneTable = Standard::findTable(p4info, oneTableId);
    CHECK_NULL(oneTable);
    tableJson->emplace("action_specs", makeActionSpecs(*oneTable));

    tableJson->emplace("data", new Util::JsonArray());

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());
    addToDependsOn(tableJson, actionProf.id);

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addActionSelectorCommon(Util::JsonArray* tablesJson,
                                             const ActionSelector& actionSelector) const {
    // TODO(antonin): formalize ID allocation for selector tables
    // repeat same annotations as for action table
    // the maximum number of groups is the table size for the selector table
    auto* tableJson = initTableJson(
        actionSelector.name, actionSelector.id, "Selector",
        actionSelector.num_groups, actionSelector.annotations);

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
                makeTypeInt("uint32", actionSelector.max_group_size), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addActionSelectorGetMemberCommon(Util::JsonArray* tablesJson,
                                             const ActionSelector& actionSelector) const {
    auto* tableJson = initTableJson(
        actionSelector.get_mem_name, actionSelector.get_mem_id, "SelectorGetMember",
        1 /* size */, actionSelector.annotations);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_SELECTOR_GROUP_ID, "$SELECTOR_GROUP_ID",
            true /* mandatory */, "Exact", makeTypeInt("uint64"));
    addKeyField(keyJson, BF_RT_DATA_HASH_VALUE, "hash_value",
            true /* mandatory */, "Exact", makeTypeInt("uint64"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    {
        auto* f = makeCommonDataField(
                BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
                makeTypeInt("uint64"), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());
    addToDependsOn(tableJson, actionSelector.id);

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addLearnFilterCommon(Util::JsonArray* learnFiltersJson,
                                          const Digest& digest) const {
    auto* learnFilterJson = new Util::JsonObject();
    learnFilterJson->emplace("name", digest.name);
    learnFilterJson->emplace("id", digest.id);
    learnFilterJson->emplace("annotations", digest.annotations);

    auto* fieldsJson = new Util::JsonArray();
    transformTypeSpecToDataFields(fieldsJson, digest.typeSpec, "Digest", digest.name);
    learnFilterJson->emplace("fields", fieldsJson);

    learnFiltersJson->append(learnFilterJson);
}

void
BfRtSchemaGenerator::addPortMetadata(Util::JsonArray* tablesJson,
                                     const PortMetadata& portMetadata) const {
    auto* tableJson = initTableJson(
        portMetadata.name, portMetadata.id, "PortMetadata", Device::numMaxChannels(),
        portMetadata.annotations);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_PORT_METADATA_PORT, portMetadata.key_name + ".ingress_port",
                true /* mandatory */, "Exact", makeTypeBytes(Device::portBitWidth()));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    if (portMetadata.typeSpec.type_spec_case() !=
        ::p4::config::v1::P4DataTypeSpec::TYPE_SPEC_NOT_SET) {
        auto* fieldsJson = new Util::JsonArray();
        transformTypeSpecToDataFields(
            fieldsJson, portMetadata.typeSpec, "PortMetadata",
            portMetadata.name);
        for (auto* f : *fieldsJson) {
            addSingleton(dataJson, f->to<Util::JsonObject>(),
                         true /* mandatory */, false /* read-only */);
      }
    } else {
        auto* f = makeCommonDataField(
            BF_RT_DATA_PORT_METADATA_DEFAULT_FIELD, "$DEFAULT_FIELD",
            makeTypeBytes(Device::pardeSpec().bitPhase0Size()), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addDynHash(Util::JsonArray* tablesJson,
                                     const DynHash& dynHash) const {
    addDynHashAlgorithm(tablesJson, dynHash);
    addDynHashConfig(tablesJson, dynHash);
    addDynHashCompute(tablesJson, dynHash);
}

void
BfRtSchemaGenerator::addDynHashConfig(Util::JsonArray* tablesJson,
                                     const DynHash& dynHash) const {
    // Add <hash>.configure Table
    auto* tableJson = initTableJson(dynHash.getConfigTableName(), dynHash.cfgId,
            "DynHashConfigure", 1 /* size */, dynHash.annotations);

    tableJson->emplace("key", new Util::JsonArray());  // empty key for configure table

    auto* dataJson = new Util::JsonArray();
    auto hashFieldNames = dynHash.getHashFieldNames();
    auto parser = TypeSpecParser::make(
        p4info, dynHash.typeSpec, "DynHash", dynHash.name, &hashFieldNames, "", "");
    int numConstants = 0;
    for (const auto &field : parser) {
        auto* containerItemsJson = new Util::JsonArray();
        auto fLength = field.type->get("width")->to<Util::JsonValue>()->getInt();
        {
            auto* f = makeCommonDataField(BF_RT_DATA_HASH_CONFIGURE_START_BIT, "start_bit",
                makeTypeInt("uint64", 0), false /* repeated */);
            addSingleton(containerItemsJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(BF_RT_DATA_HASH_CONFIGURE_LENGTH, "length",
                makeTypeInt("uint64", fLength), false /* repeated */);
            addSingleton(containerItemsJson, f, false /* mandatory */, false /* read-only */);
        }
        {
            auto* f = makeCommonDataField(BF_RT_DATA_HASH_CONFIGURE_ORDER, "order",
                makeTypeInt("uint64"), false /* repeated */);
            addSingleton(containerItemsJson, f, true /* mandatory */, false /* read-only */);
        }
        cstring field_prefix = "";
        Util::JsonArray *annotations = nullptr;
        if (dynHash.is_constant(field.name)) {
            // Constant fields have unique field names with the format
            // constant<id>_<size>_<value>
            // id increments by 1 for every constant field.
            // Should match names generated in context.json (mau/dynhash.cpp)
            field_prefix = "constant" + std::to_string(numConstants++)
                            + "_" + std::to_string(fLength) + "_";
            auto *constantAnnot = new Util::JsonObject();
            constantAnnot->emplace("name", "bfrt_p4_constant");
            annotations = new Util::JsonArray();
            annotations->append(constantAnnot);
        }
        auto* fJson = makeContainerDataField(field.id, field_prefix + field.name,
                containerItemsJson, true /* repeated */, annotations);
        addSingleton(dataJson, fJson, false /* mandatory */, false /* read-only */);
    }
    tableJson->emplace("data", dataJson);
    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addDynHashAlgorithm(Util::JsonArray* tablesJson,
                                     const DynHash& dynHash) const {
    auto* tableJson = initTableJson(
        dynHash.getAlgorithmTableName(), dynHash.algId, "DynHashAlgorithm",
        1 /* size */, dynHash.annotations);

    tableJson->emplace("key", new Util::JsonArray());  // empty key

    auto* dataJson = new Util::JsonArray();
    // Add seed key field
    auto* seedJson = makeCommonDataField(BF_RT_DATA_HASH_ALGORITHM_SEED, "seed",
                makeTypeInt("uint32", 0 /* default */), false /* repeated */);
    addSingleton(dataJson, seedJson, false /* mandatory */, false /* read-only */);

    // Add msb key field
    auto* msbJson = makeCommonDataField(BF_RT_DATA_HASH_ALGORITHM_MSB, "msb",
            makeTypeBool(false /* default */), false /* repeated */);
    addSingleton(dataJson, msbJson, false /* mandatory */, false /* read-only */);

    // Add extend key field
    auto* extendJson = makeCommonDataField(BF_RT_DATA_HASH_ALGORITHM_EXTEND, "extend",
            makeTypeBool(false /* default */), false /* repeated */);
    addSingleton(dataJson, extendJson, false /* mandatory */, false /* read-only */);

    tableJson->emplace("data", dataJson);

    auto* actionSpecsJson = new Util::JsonArray();

    // Add pre-defined action spec
    auto* preDefinedJson = new Util::JsonObject();
    preDefinedJson->emplace("id", BF_RT_DATA_HASH_ALGORITHM_PRE_DEFINED);
    preDefinedJson->emplace("name", "pre_defined");
    preDefinedJson->emplace("action_scope", "TableAndDefault");
    preDefinedJson->emplace("annotations", new Util::JsonArray());

    P4Id dataId = 1;
    auto* preDefinedDataJson = new Util::JsonArray();
    // Add algorithm_name field
    std::vector<cstring> algos;
    // Create a list of all supported algos from bf-utils repo
    for (int i = 0; i < static_cast<int>(INVALID_DYN); i++) {
        char alg_name[BF_UTILS_ALGO_NAME_LEN];
        bfn_hash_alg_type_t alg_t = static_cast<bfn_hash_alg_type_t>(i);
        if (alg_t == CRC_DYN) continue;  // skip CRC as we include its sub types later
        hash_alg_type_to_str(alg_t, alg_name);
        algos.emplace_back(alg_name);
    }
    // Include all CRC Sub Types
    for (int i = 0; i < static_cast<int>(CRC_INVALID); i++) {
        char crc_name[BF_UTILS_ALGO_NAME_LEN];
        bfn_crc_alg_t alg_t = static_cast<bfn_crc_alg_t>(i);
        crc_alg_type_to_str(alg_t, crc_name);
        algos.emplace_back(crc_name);
    }
    auto* algoType = makeTypeEnum(algos, cstring("RANDOM") /* default */);
    addActionDataField(preDefinedDataJson, dataId, "algorithm_name",
            false /* mandatory */, false /* read_only */,
            algoType, nullptr /* annotations */);
    preDefinedJson->emplace("data", preDefinedDataJson);

    actionSpecsJson->append(preDefinedJson);

    // Add user_defined action spec
    auto* userDefinedJson = new Util::JsonObject();
    userDefinedJson->emplace("id", BF_RT_DATA_HASH_ALGORITHM_USER_DEFINED);
    userDefinedJson->emplace("name", "user_defined");
    userDefinedJson->emplace("action_scope", "TableAndDefault");
    userDefinedJson->emplace("annotations", new Util::JsonArray());

    auto* userDefinedDataJson = new Util::JsonArray();
    dataId = 1;
    // Add reverse data field
    auto* revType = makeTypeBool(false /* default */);
    addActionDataField(userDefinedDataJson, dataId++, "reverse",
            false /* mandatory */, false /* read_only */,
            revType, nullptr /* annotations */);

    // Add polynomial data field
    auto* polyType = makeTypeInt("uint64");
    addActionDataField(userDefinedDataJson, dataId++, "polynomial",
            true /* mandatory */, false /* read_only */,
            polyType, nullptr /* annotations */);

    // Add init data field
    auto* initType = makeTypeInt("uint64", 0 /* default_value */);
    addActionDataField(userDefinedDataJson, dataId++, "init",
            false /* mandatory */, false /* read_only */,
            initType, nullptr /* annotations */);

    // Add final_xor data field
    auto* finalXorType = makeTypeInt("uint64", 0 /* default_value */);
    addActionDataField(userDefinedDataJson, dataId++, "final_xor",
            false /* mandatory */, false /* read_only */,
            finalXorType, nullptr /* annotations */);

    // Add hash_bit_width data field
    auto* hashBitWidthType = makeTypeInt("uint64");
    addActionDataField(userDefinedDataJson, dataId++, "hash_bit_width",
            false /* mandatory */, false /* read_only */,
            hashBitWidthType, nullptr /* annotations */);
    userDefinedJson->emplace("data", userDefinedDataJson);

    actionSpecsJson->append(userDefinedJson);
    addToDependsOn(tableJson, dynHash.cfgId);

    tableJson->emplace("action_specs", actionSpecsJson);
    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addDynHashCompute(Util::JsonArray* tablesJson,
                                     const DynHash& dynHash) const {
    // Add <hash>.compute Table
    auto* tableJson = initTableJson(
        dynHash.getComputeTableName(), dynHash.cmpId, "DynHashCompute",
        1 /* size */, dynHash.annotations);

    P4Id id = 1;
    auto* keyJson = new Util::JsonArray();
    auto hashFieldNames = dynHash.getHashFieldNames();
    auto parser = TypeSpecParser::make(
        p4info, dynHash.typeSpec, "DynHash", dynHash.name, &hashFieldNames, "", "");
    for (const auto &field : parser) {
        if (dynHash.is_constant(field.name)) {
          // If this is a constant field, then skip adding a field
          // in compute table
          continue;
        }
        auto* type = makeTypeBytes(field.type->get("width")->to<Util::JsonValue>()->getInt());
        addKeyField(keyJson, id++, field.name, false /* mandatory */, "Exact", type);
    }
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    auto* f = makeCommonDataField(
        BF_RT_DATA_HASH_VALUE, "hash_value",
        makeTypeBytes(dynHash.hashWidth), false /* repeated */);
    addSingleton(dataJson, f, false /* mandatory */, true /* read-only */);
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());
    tableJson->emplace("read_only", true);
    addToDependsOn(tableJson, dynHash.cfgId);

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addLpfDataFields(Util::JsonArray* dataJson) {
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_LPF_SPEC_TYPE, "$LPF_SPEC_TYPE",
            makeTypeEnum({"RATE", "SAMPLE"}), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_LPF_SPEC_GAIN_TIME_CONSTANT_NS, "$LPF_SPEC_GAIN_TIME_CONSTANT_NS",
            makeTypeFloat("float"), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_LPF_SPEC_DECAY_TIME_CONSTANT_NS, "$LPF_SPEC_DECAY_TIME_CONSTANT_NS",
            makeTypeFloat("float"), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_LPF_SPEC_OUT_SCALE_DOWN_FACTOR, "$LPF_SPEC_OUT_SCALE_DOWN_FACTOR",
            makeTypeInt("uint32"), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
}

void
BfRtSchemaGenerator::addLpf(Util::JsonArray* tablesJson, const Lpf& lpf) const {
    auto* tableJson = initTableJson(lpf.name, lpf.id, "Lpf", lpf.size, lpf.annotations);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_LPF_INDEX, "$LPF_INDEX",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    addLpfDataFields(dataJson);
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BfRtSchemaGenerator::addWredDataFields(Util::JsonArray* dataJson) {
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_WRED_SPEC_TIME_CONSTANT_NS, "$WRED_SPEC_TIME_CONSTANT_NS",
            makeTypeFloat("float"), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_WRED_SPEC_MIN_THRESH_CELLS, "$WRED_SPEC_MIN_THRESH_CELLS",
            makeTypeInt("uint32"), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_WRED_SPEC_MAX_THRESH_CELLS, "$WRED_SPEC_MAX_THRESH_CELLS",
            makeTypeInt("uint32"), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_WRED_SPEC_MAX_PROBABILITY, "$WRED_SPEC_MAX_PROBABILITY",
            makeTypeFloat("float"), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
}

void
BfRtSchemaGenerator::addWred(Util::JsonArray* tablesJson, const Wred& wred) const {
    auto* tableJson = initTableJson(wred.name, wred.id, "Wred", wred.size, wred.annotations);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_WRED_INDEX, "$WRED_INDEX",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    addWredDataFields(dataJson);
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

static Util::JsonObject* findJsonTable(Util::JsonArray* tablesJson, cstring tblName) {
    for (auto *t : *tablesJson) {
        auto *tblObj = t->to<Util::JsonObject>();
        auto tName = tblObj->get("name")->to<Util::JsonValue>()->getString();
        if (tName == tblName) {
            return tblObj;
        }
    }
    return nullptr;
}

void
BfRtSchemaGenerator::addSnapshot(Util::JsonArray* tablesJson, const Snapshot& snapshot) const {
    auto size = Device::numStages();

    // Snapshot Config Table
    {
        auto tblName = snapshot.getCfgTblName();
        Util::JsonObject *tableJson = findJsonTable(tablesJson, tblName);
        if (!tableJson) {
            auto* tableJson = initTableJson(tblName,
                    makeBfRtId(snapshot.id, ::barefoot::P4Ids::SNAPSHOT),
                    "SnapshotCfg", size);

            auto* keyJson = new Util::JsonArray();
            addKeyField(keyJson, BF_RT_DATA_SNAPSHOT_START_STAGE, "start_stage",
                        false /* mandatory */, "Exact", makeTypeInt("uint32", 0));
            addKeyField(keyJson, BF_RT_DATA_SNAPSHOT_END_STAGE, "end_stage",
                        false /* mandatory */, "Exact", makeTypeInt("uint32", size - 1));
            tableJson->emplace("key", keyJson);

            auto* dataJson = new Util::JsonArray();
            {
                auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_TIMER_ENABLE, "timer_enable",
                        makeTypeBool(false), false /* repeated */);
                addSingleton(dataJson, f, false, false);
            }
            {
                auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_TIMER_VALUE_USECS,
                        "timer_value_usecs", makeTypeInt("uint32"), false /* repeated */);
                addSingleton(dataJson, f, false, false);
            }
            {
                std::vector<cstring> choices =  {"INGRESS", "GHOST", "INGRESS_GHOST", "ANY"};
                cstring defaultChoice = "INGRESS";
                auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_INGRESS_TRIGGER_MODE,
                        "ingress_trigger_mode", makeTypeEnum(choices, defaultChoice),
                        false /* repeated */);
                addSingleton(dataJson, f, false, false);
            }
            {
                auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_THREAD, "thread",
                        makeTypeEnum({"INGRESS", "EGRESS", "ALL"}), false /* repeated */);
                addSingleton(dataJson, f, true, false);
            }
            {
                auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_INGRESS_CAPTURE,
                        "ingress_capture", makeTypeInt("uint32"), true /* repeated */);
                addROSingleton(dataJson, f);
            }
            {
                auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_EGRESS_CAPTURE,
                        "egress_capture", makeTypeInt("uint32"), true /* repeated */);
                addROSingleton(dataJson, f);
            }
            {
                auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_GHOST_CAPTURE,
                        "ghost_capture", makeTypeInt("uint32"), true /* repeated */);
                addROSingleton(dataJson, f);
            }
            tableJson->emplace("data", dataJson);

            tableJson->emplace("supported_operations", new Util::JsonArray());
            tableJson->emplace("attributes", new Util::JsonArray());

            tablesJson->append(tableJson);
        }
    }

    // Snapshot Trigger Table (ingress / egress)
    {
        auto tblName = snapshot.getTrigTblName();
        auto tableId = makeBfRtId(snapshot.id, ::barefoot::P4Ids::SNAPSHOT_TRIGGER);
        auto* tableJson = initTableJson(tblName, tableId, "SnapshotTrigger", size);

        auto* keyJson = new Util::JsonArray();
        addKeyField(keyJson, BF_RT_DATA_SNAPSHOT_START_STAGE, "stage",
                    true /* mandatory */, "Exact", makeTypeInt("uint32", 0));
        tableJson->emplace("key", keyJson);

        auto* dataJson = new Util::JsonArray();
        {
            auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_ENABLE, "enable",
                    makeTypeBool(false), false /* repeated */);
            addSingleton(dataJson, f, false, false);
        }
        {
            auto* f = makeCommonDataField(BF_RT_DATA_SNAPSHOT_TRIGGER_STATE, "trigger_state",
                makeTypeEnum({"PASSIVE", "ARMED", "FULL"}, boost::none), true /* repeated */);
            addROSingleton(dataJson, f);
        }
        for (const auto& sF : snapshot.fields) {
            {
                auto* f = makeCommonDataField(sF.id, "trig." + sF.name,
                    makeTypeBytes(sF.bitwidth, boost::none), false /* repeated */);
                addSingleton(dataJson, f, false, false);
            }
            {
                auto *f = makeCommonDataField(sF.id + 0x8000, "trig." + sF.name + "_mask",
                    makeTypeBytes(sF.bitwidth, boost::none), false /* repeated */);
                addSingleton(dataJson, f, false, false);
            }
        }
        tableJson->emplace("data", dataJson);

        tableJson->emplace("supported_operations", new Util::JsonArray());
        tableJson->emplace("attributes", new Util::JsonArray());

        tablesJson->append(tableJson);

        // Add trigger table id to config table
        if (auto *snapCfgTable = findJsonTable(tablesJson, snapshot.getCfgTblName())) {
            addToDependsOn(snapCfgTable, tableId);
        }
    }

    // Snapshot Data Table
    {
        auto tblName = snapshot.getDataTblName();
        Util::JsonArray* dataJson = nullptr;
        auto *tableJson = initTableJson(tblName,
            makeBfRtId(snapshot.id, ::barefoot::P4Ids::SNAPSHOT_DATA),
            "SnapshotData", size);

        auto* keyJson = new Util::JsonArray();
        addKeyField(keyJson, BF_RT_DATA_SNAPSHOT_START_STAGE, "stage",
                    true /* mandatory */, "Exact", makeTypeInt("uint32", 0));
        tableJson->emplace("key", keyJson);

        dataJson = new Util::JsonArray();
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_SNAPSHOT_PREV_STAGE_TRIGGER, "prev_stage_trigger",
                makeTypeBool(false), false /* repeated */);
            addROSingleton(dataJson, f);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_SNAPSHOT_TIMER_TRIGGER, "timer_trigger",
                makeTypeBool(false), false /* repeated */);
            addROSingleton(dataJson, f);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_SNAPSHOT_LOCAL_STAGE_TRIGGER, "local_stage_trigger",
                makeTypeBool(false), false /* repeated */);
            addROSingleton(dataJson, f);
        }
        {
            auto* f = makeCommonDataField(
                BF_RT_DATA_SNAPSHOT_NEXT_TABLE_NAME, "next_table_name",
                makeTypeString(), false /* repeated */);
            addROSingleton(dataJson, f);
        }

        {  // table ALU information
            auto* tableContainerItemsJson = new Util::JsonArray();
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_TABLE_NAME, "table_name",
                    makeTypeString(), false /* repeated */);
                addROSingleton(tableContainerItemsJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_MATCH_HIT_HANDLE, "match_hit_handle",
                    makeTypeInt("uint32"), false /* repeated */);
                addROSingleton(tableContainerItemsJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_TABLE_HIT, "table_hit",
                    makeTypeBool(), false /* repeated */);
                addROSingleton(tableContainerItemsJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_TABLE_INHIBITED, "table_inhibited",
                    makeTypeBool(), false /* repeated */);
                addROSingleton(tableContainerItemsJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_TABLE_EXECUTED, "table_executed",
                    makeTypeBool(), false /* repeated */);
                addROSingleton(tableContainerItemsJson, f);
            }
            auto* tableContainerJson = makeContainerDataField(
                BF_RT_DATA_SNAPSHOT_TABLE_INFO, "table_info",
                tableContainerItemsJson, true /* repeated */);

            addROSingleton(dataJson, tableContainerJson);
        }
        if (Device::currentDevice() == Device::JBAY) {
            // TODO(antonin): This is likely not appropriate / sufficient for
            // MPR. Maybe this should be a repeated field of table ids / names
            // instead...
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_ENABLED_NEXT_TABLES, "enabled_next_tables",
                    makeTypeString(), true /* repeated */);
                addROSingleton(dataJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_GLOBAL_EXECUTE_TABLES, "global_execute_tables",
                    makeTypeString(), true /* repeated */);
                addROSingleton(dataJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_ENABLED_GLOBAL_EXECUTE_TABLES,
                    "enabled_global_execute_tables",
                    makeTypeString(), true /* repeated */);
                addROSingleton(dataJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_LONG_BRANCH_TABLES, "long_branch_tables",
                    makeTypeString(), true /* repeated */);
                addROSingleton(dataJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_ENABLED_LONG_BRANCH_TABLES, "enabled_long_branch_tables",
                    makeTypeString(), true /* repeated */);
                addROSingleton(dataJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_DEPARSER_ERROR, "deparser_error",
                    makeTypeBool(), false /* repeated */);
                addROSingleton(dataJson, f);
            }
            // meter ALU information
            auto* meterContainerItemsJson = new Util::JsonArray();
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_METER_TABLE_NAME, "table_name",
                    makeTypeString(), false /* repeated */);
                addROSingleton(meterContainerItemsJson, f);
            }
            {
                auto* f = makeCommonDataField(
                    BF_RT_DATA_SNAPSHOT_METER_ALU_OPERATION_TYPE,
                    "meter_alu_operation_type",
                    makeTypeString(), false /* repeated */);
                addROSingleton(meterContainerItemsJson, f);
            }
            auto* meterContainerJson = makeContainerDataField(
                BF_RT_DATA_SNAPSHOT_METER_ALU_INFO, "meter_alu_info",
                meterContainerItemsJson, true /* repeated */);
            addROSingleton(dataJson, meterContainerJson);
        }

        for (const auto& sF : snapshot.fields) {
            auto* f = makeCommonDataField(
                sF.id, sF.name, makeTypeBytes(sF.bitwidth, boost::none),
                false /* repeated */);
            addROSingleton(dataJson, f);
        }

        tableJson->emplace("data", dataJson);

        tableJson->emplace("supported_operations", new Util::JsonArray());
        tableJson->emplace("attributes", new Util::JsonArray());

        tablesJson->append(tableJson);
    }
}

void
BfRtSchemaGenerator::addSnapshotLiveness(Util::JsonArray* tablesJson,
    const Snapshot& snapshot) const {
  auto tblName = snapshot.getLivTblName();
  Util::JsonObject *tableJson = findJsonTable(tablesJson, tblName);
  if (!tableJson) {
    auto tableId = makeBfRtId(snapshot.id, ::barefoot::P4Ids::SNAPSHOT_LIVENESS);
    auto* tableJson = initTableJson(tblName, tableId,
        "SnapshotLiveness", 0 /* size, read-only table */);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_SNAPSHOT_LIVENESS_FIELD_NAME, "field_name",
        true /* mandatory */, "Exact", makeTypeString());
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    {
      auto* f = makeCommonDataField(
          BF_RT_DATA_SNAPSHOT_LIVENESS_VALID_STAGES, "valid_stages",
          makeTypeInt("uint32"), true /* repeated */);
      addROSingleton(dataJson, f);
    }
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
  }
}

void
BfRtSchemaGenerator::addParserChoices(Util::JsonArray* tablesJson,
                                      const ParserChoices& parserChoices) const {
    auto* tableJson = initTableJson(
        parserChoices.name, parserChoices.id, "ParserInstanceConfigure",
        Device::numParsersPerPipe() /* size */);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_PARSER_INSTANCE, "$PARSER_INSTANCE",
                true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    {
        auto* f = makeCommonDataField(
            BF_RT_DATA_PARSER_NAME, "$PARSER_NAME",
            makeTypeEnum(parserChoices.choices), false /* repeated */);
        addSingleton(dataJson, f, true /* mandatory */, false /* read-only */);
    }
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

// Debug counter table is functionally dependent on P4 program and should
// be placed in the root of P4 program node, even if it doesn't use any
// p4info data directly.
void
BfRtSchemaGenerator::addDebugCounterTable(Util::JsonArray* tablesJson) const {
    P4Id id = makeBfRtId(0, barefoot::P4Ids::DEBUG_COUNTER);
    auto* tableJson = initTableJson("tbl_dbg_counter", id, "TblDbgCnt",
        Device::numStages() * Device::numLogTablesPerStage() /* size */);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, BF_RT_DATA_DEBUG_CNT_TABLE_NAME, "tbl_name",
                true /* mandatory */, "Exact", makeTypeString());
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    {
        std::vector<cstring> choices = { "DISABLED", "TBL_MISS", "TBL_HIT",
            "GW_TBL_MISS", "GW_TBL_HIT", "GW_TBL_INHIBIT" };
        auto* f = makeCommonDataField(
            BF_RT_DATA_DEBUG_CNT_TYPE, "type",
            makeTypeEnum(choices, choices[2]), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
    {
        auto* f = makeCommonDataField(
          BF_RT_DATA_DEBUG_CNT_VALUE, "value",
          makeTypeInt("uint64", 0), false /* repeated */);
        addSingleton(dataJson, f, false /* mandatory */, false /* read-only */);
    }
    tableJson->emplace("data", dataJson);

    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
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
BfRtSchemaGenerator::makeActionSpecs(const p4configv1::Table& table, P4Id* maxActionParamId) const {
    auto* specs = new Util::JsonArray();
    P4Id maxId = 0;
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
        switch (action_ref.scope()) {
            case p4configv1::ActionRef::TABLE_AND_DEFAULT:
                spec->emplace("action_scope", "TableAndDefault");
                break;
            case p4configv1::ActionRef::TABLE_ONLY:
                spec->emplace("action_scope", "TableOnly");
                break;
            case p4configv1::ActionRef::DEFAULT_ONLY:
                spec->emplace("action_scope", "DefaultOnly");
                break;
            default:
                ::error("Invalid action ref scope '%1%' in P4Info", int(action_ref.scope()));
                break;
        }
        auto* annotations = transformAnnotations(
            action_ref.annotations().begin(), action_ref.annotations().end());
        spec->emplace("annotations", annotations);

        auto* dataJson = new Util::JsonArray();
        for (const auto& param : action->params()) {
            auto* annotations = transformAnnotations(
                param.annotations().begin(), param.annotations().end());
            addActionDataField(
                dataJson, param.id(), param.name(), true /* mandatory */,
                false /* read_only */, makeTypeBytes(param.bitwidth()), annotations);
            if (param.id() > maxId) maxId = param.id();
        }
        spec->emplace("data", dataJson);
        specs->append(spec);
    }
    if (maxActionParamId != nullptr) *maxActionParamId = maxId;
    return specs;
}

void
BfRtSchemaGenerator::addMatchTables(Util::JsonArray* tablesJson) const {
    for (const auto& table : p4info.tables()) {
        const auto& pre = table.preamble();
        std::set<std::string> dupKey;

        auto* annotations = transformAnnotations(
            pre.annotations().begin(), pre.annotations().end());

        cstring tableType = "MatchAction_Direct";
        auto implementationId = table.implementation_id();
        auto actProfId = static_cast<P4Id>(0);
        auto actSelectorId = static_cast<P4Id>(0);
        if (implementationId > 0) {
            auto hasSelector = actProfHasSelector(implementationId);
            if (hasSelector == boost::none) {
                ::error("Invalid implementation id in p4info: %1%", implementationId);
                continue;
            }
            tableType = *hasSelector ? "MatchAction_Indirect_Selector" : "MatchAction_Indirect";
            actProfId = ActionProf::makeActProfId(implementationId);
            if (*hasSelector) actSelectorId = ActionProf::makeActSelectorId(implementationId);
        }

        auto* tableJson = initTableJson(
            pre.name(), pre.id(), tableType, table.size(), annotations);

        if (actProfId > 0) addToDependsOn(tableJson, actProfId);
        if (actSelectorId > 0) addToDependsOn(tableJson, actSelectorId);

        tableJson->emplace("has_const_default_action", table.const_default_action_id() != 0);

        // will be set to true by the for loop if the match key includes a
        // ternary, range or optional match
        bool needsPriority = false;
        auto* keyJson = new Util::JsonArray();
        for (const auto& mf : table.match_fields()) {
            boost::optional<cstring> matchType = boost::none;
            switch (mf.match_case()) {
                case p4configv1::MatchField::kMatchType:
                    matchType = transformMatchType(mf.match_type());
                    break;
                case p4configv1::MatchField::kOtherMatchType:
                    matchType = transformOtherMatchType(mf.other_match_type());
                    break;
                default:
                    BUG("Invalid oneof case for the match type of table '%1%'", pre.name());
                    break;
            }
            if (matchType == boost::none) {
                ::error("Unsupported match type for BF-RT: %1%", int(mf.match_type()));
                continue;
            }
            if (*matchType == "Ternary" || *matchType == "Range" || *matchType == "Optional")
                needsPriority = true;
            auto* annotations = transformAnnotations(
                mf.annotations().begin(), mf.annotations().end());

            CHECK_NULL(annotations);
            // Add isFieldSlice annotation if the match key is a field slice
            // e.g. hdr[23:16] where hdr is a 32 bit field
            std::string s(mf.name());
            std::smatch sm;
            std::regex sliceRegex(R"(\[([0-9]+):([0-9]+)\])");
            std::regex_search(s, sm, sliceRegex);
            if (sm.size() == 3) {
                auto *isFieldSliceAnnot = new Util::JsonObject();
                isFieldSliceAnnot->emplace("name", "isFieldSlice");
                isFieldSliceAnnot->emplace("value", "true");
                annotations->append(isFieldSliceAnnot);
            }

            // P4_14-->P4_16 translation names valid matches with a
            // "$valid$" suffix (note the trailing "$").  However, Brig
            // and pdgen use "$valid".
            auto keyName = mf.name();
            auto found = keyName.find(".$valid");
            if (found != std::string::npos) keyName.pop_back();

            // Replace header stack indices hdr[<index>] with hdr$<index>. This
            // is output in the context.json
            std::regex hdrStackRegex(R"(\[([0-9]+)\])");
            keyName = std::regex_replace(keyName, hdrStackRegex, "$$$1");

            // Control plane requires there's no duplicate key in one table.
            if (dupKey.count(keyName) != 0) {
              ::error("Key \"%s\" is duplicate in Table \"%s\". It doesn't meet BFRT's "
              "requirements.\n" "Please using @name annotation for the duplicate key names",
              keyName, pre.name());
              return;
            } else {
              dupKey.insert(keyName);
            }

            // DRV-3112 - Make key fields not mandatory, this allows user to use a
            // driver initialized default value (0).
            addKeyField(keyJson, mf.id(), keyName,
                        false /* mandatory */, *matchType,
                        makeTypeBytes(mf.bitwidth(), boost::none),
                        annotations);
        }
        if (needsPriority) {
            // DRV-3112 - Make key fields not mandatory, this allows user to use a
            // driver initialized default value (0).
            addKeyField(keyJson, BF_RT_DATA_MATCH_PRIORITY, "$MATCH_PRIORITY",
                        false /* mandatory */, "Exact", makeTypeInt("uint32"));
        }
        tableJson->emplace("key", keyJson);

        auto* dataJson = new Util::JsonArray();

        // will be used as an offset for other P4-dependent fields (e.g. direct
        // register fields).
        P4Id maxActionParamId = 0;
        if (tableType == "MatchAction_Direct") {
            tableJson->emplace(
                "action_specs", makeActionSpecs(table, &maxActionParamId));
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
        maxActionParamId++;

        auto* operationsJson = new Util::JsonArray();
        auto* attributesJson = new Util::JsonArray();

        // direct resources
        for (auto directResId : table.direct_resource_ids()) {
            if (auto counter = getDirectCounter(directResId)) {
                addCounterDataFields(dataJson, *counter);
                operationsJson->append("SyncCounters");
            } else if (auto meter = getDirectMeter(directResId)) {
                addMeterDataFields(dataJson, *meter);
                attributesJson->append("MeterByteCountAdjust");
            } else if (auto register_ = getDirectRegister(directResId)) {
                addRegisterDataFields(dataJson, *register_, maxActionParamId);
                operationsJson->append("SyncRegisters");
            } else if (auto lpf = getDirectLpf(directResId)) {
                addLpfDataFields(dataJson);
            } else if (auto lpf = getDirectWred(directResId)) {
                addWredDataFields(dataJson);
            } else {
                ::error("Unknown direct resource id '%1%'", directResId);
                continue;
            }
        }

        attributesJson->append("EntryScope");

        // The compiler backend is in charge of rejecting the program if
        // @dynamic_table_key_masks is used incorrectly (e.g. if the table is
        // ternary).
        auto supportsDynMask = std::count(
            pre.annotations().begin(), pre.annotations().end(),
            "@dynamic_table_key_masks(1)");
        if (supportsDynMask) attributesJson->append("DynamicKeyMask");

        if (table.is_const_table()) attributesJson->append("ConstTable");

        if (table.idle_timeout_behavior() ==
            p4configv1::Table::NOTIFY_CONTROL) {
            auto pollModeOnly = std::count(
                pre.annotations().begin(), pre.annotations().end(),
                "@idletime_precision(1)");

            operationsJson->append("UpdateHitState");
            attributesJson->append("IdleTimeout");

            auto* fEntryTTL = makeCommonDataField(
                BF_RT_DATA_ENTRY_TTL, "$ENTRY_TTL",
                makeTypeInt("uint32", 0 /* default TTL -> ageing disabled */),
                false /* repeated */);
            auto* fEntryHitState = makeCommonDataField(
                BF_RT_DATA_ENTRY_HIT_STATE, "$ENTRY_HIT_STATE",
                makeTypeEnum({"ENTRY_IDLE", "ENTRY_ACTIVE"}),
                false /* repeated */);
            addSingleton(dataJson, fEntryHitState, false /* mandatory */, false /* read-only */);
            if (!pollModeOnly)
              addSingleton(dataJson, fEntryTTL, false /* mandatory */, false /* read-only */);
        }

        tableJson->emplace("data", dataJson);
        tableJson->emplace("supported_operations", operationsJson);
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

        auto actionSelectorInstance = ActionSelector::from(p4info, actionProf);
        if (actionSelectorInstance == boost::none) continue;
        addActionSelectorCommon(tablesJson, *actionSelectorInstance);
        addActionSelectorGetMemberCommon(tablesJson, *actionSelectorInstance);
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
                auto actionSelector =
                    ActionSelector::fromTofinoActionSelector(p4info, externInstance);
                if (actionSelector != boost::none) {
                    addActionSelectorCommon(tablesJson, *actionSelector);
                    addActionSelectorGetMemberCommon(tablesJson, *actionSelector);
                }
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
        } else if (externTypeId == ::barefoot::P4Ids::REGISTER) {
            for (const auto& externInstance : externType.instances()) {
                auto register_ = Register::fromTofino(externInstance);
                if (register_ != boost::none)
                    addRegisterCommon(tablesJson, *register_);
            }
        } else if (externTypeId == ::barefoot::P4Ids::REGISTER_PARAM) {
            for (const auto& externInstance : externType.instances()) {
                auto register_param_ = RegisterParam::fromTofino(externInstance);
                if (register_param_ != boost::none)
                    addRegisterParam(tablesJson, *register_param_);
            }
        } else if (externTypeId == ::barefoot::P4Ids::LPF) {
            for (const auto& externInstance : externType.instances()) {
                auto lpf = Lpf::fromTofino(externInstance);
                if (lpf != boost::none) addLpf(tablesJson, *lpf);
            }
        } else if (externTypeId == ::barefoot::P4Ids::WRED) {
            for (const auto& externInstance : externType.instances()) {
                auto wred = Wred::fromTofino(externInstance);
                if (wred != boost::none) addWred(tablesJson, *wred);
            }
        } else if (externTypeId == ::barefoot::P4Ids::VALUE_SET) {
            for (const auto& externInstance : externType.instances()) {
                auto valueSet = ValueSet::fromTofino(externInstance);
                if (valueSet != boost::none) addValueSet(tablesJson, *valueSet);
            }
        } else if (externTypeId == ::barefoot::P4Ids::SNAPSHOT) {
            for (const auto& externInstance : externType.instances()) {
                auto snapshot = Snapshot::fromTofino(externInstance);
                if (snapshot != boost::none) {
                    addSnapshot(tablesJson, *snapshot);
                    addSnapshotLiveness(tablesJson, *snapshot);
                }
            }
        } else if (externTypeId == ::barefoot::P4Ids::HASH) {
            for (const auto& externInstance : externType.instances()) {
                auto dynHash = DynHash::fromTofino(externInstance);
                if (dynHash != boost::none) {
                    addDynHash(tablesJson, *dynHash);
                }
            }
        } else if (externTypeId == ::barefoot::P4Ids::PARSER_CHOICES) {
            for (const auto& externInstance : externType.instances()) {
                auto parserChoices = ParserChoices::fromTofino(externInstance);
                if (parserChoices != boost::none) {
                    // Disabled unless driver adds BF-RT support for dynamically
                    // changing parser configurations
                    // addParserChoices(tablesJson, *parserChoices);
                }
            }
        }
    }
}

// I chose to do this in a separate function rather than in addTofinoExterns
// because if there is no PortMetadata extern in P4Info, we need to generate a
// default one.
void
BfRtSchemaGenerator::addPortMetadataExtern(Util::JsonArray* tablesJson) const {
    for (const auto& externType : p4info.externs()) {
        auto externTypeId = static_cast<::barefoot::P4Ids::Prefix>(externType.extern_type_id());
        if (externTypeId == ::barefoot::P4Ids::PORT_METADATA) {
            // For multipipe and multiple ingress per pipe scenarios we can have
            // multiple port metadata extern instances in the program, here we
            // add all instances collected in the program
            for (const auto& externInstance : externType.instances()) {
                auto portMetadata = PortMetadata::fromTofino(externInstance);
                if (portMetadata != boost::none) addPortMetadata(tablesJson, *portMetadata);
            }
        }
    }
}

const Util::JsonObject*
BfRtSchemaGenerator::genSchema() const {
    auto* json = new Util::JsonObject();

    json->emplace("schema_version", cstring("1.0.0"));

    auto* tablesJson = new Util::JsonArray();
    json->emplace("tables", tablesJson);

    addMatchTables(tablesJson);
    addActionProfs(tablesJson);
    addCounters(tablesJson);
    addMeters(tablesJson);
    // TODO(antonin): handle "standard" (v1model / PSA) registers

    auto* learnFiltersJson = new Util::JsonArray();
    json->emplace("learn_filters", learnFiltersJson);
    addLearnFilters(learnFiltersJson);

    addTofinoExterns(tablesJson, learnFiltersJson);

    addPortMetadataExtern(tablesJson);

    addDebugCounterTable(tablesJson);

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
