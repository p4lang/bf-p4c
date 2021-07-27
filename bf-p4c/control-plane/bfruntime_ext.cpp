#include "bfruntime_ext.h"

namespace BFN {

namespace BFRT {

struct BFRuntimeSchemaGenerator::ActionSelector {
    std::string name;
    std::string get_mem_name;
    P4Id id;
    P4Id get_mem_id;
    P4Id action_profile_id;
    int64_t max_group_size;
    int64_t num_groups;  // aka size of selector
    std::vector<P4Id> tableIds;
    Util::JsonArray* annotations;

    static boost::optional<ActionSelector>
    from(const p4configv1::P4Info& p4info, const p4configv1::ActionProfile& actionProfile) {
        const auto& pre = actionProfile.preamble();
        if (!actionProfile.with_selector())
            return boost::none;
        auto selectorId = makeBFRuntimeId(pre.id(), ::barefoot::P4Ids::ACTION_SELECTOR);
        auto selectorGetMemId = makeBFRuntimeId(pre.id(),
                ::barefoot::P4Ids::ACTION_SELECTOR_GET_MEMBER);
        auto tableIds = collectTableIds(
            p4info, actionProfile.table_ids().begin(), actionProfile.table_ids().end());
        return ActionSelector{pre.name(), pre.name() + "_get_member",
            selectorId, selectorGetMemId, actionProfile.preamble().id(),
            actionProfile.max_group_size(), actionProfile.size(), tableIds,
            transformAnnotations(pre)};
    }

    static boost::optional<ActionSelector>
    fromTNA(const p4configv1::P4Info& p4info, const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::ActionSelector actionSelector;
        if (!externInstance.info().UnpackTo(&actionSelector)) {
            ::error("Extern instance %1% does not pack an ActionSelector object", pre.name());
            return boost::none;
        }
        auto selectorId = makeBFRuntimeId(pre.id(), ::barefoot::P4Ids::ACTION_SELECTOR);
        auto selectorGetMemId = makeBFRuntimeId(pre.id(),
                ::barefoot::P4Ids::ACTION_SELECTOR_GET_MEMBER);
        auto tableIds = collectTableIds(
            p4info, actionSelector.table_ids().begin(), actionSelector.table_ids().end());
        return ActionSelector{pre.name(), pre.name() + "_get_member",
            selectorId, selectorGetMemId, actionSelector.action_profile_id(),
            actionSelector.max_group_size(), actionSelector.num_groups(),
            tableIds, transformAnnotations(pre)};
    };
};

/// This struct is meant to be used as a common representation of ValueSet
/// objects for both PSA & TNA programs. However, at the moment we only support
/// TNA ValueSet objects.
struct BFRuntimeSchemaGenerator::ValueSet {
    std::string name;
    P4Id id;
    p4configv1::P4DataTypeSpec typeSpec;
    const int64_t size;
    Util::JsonArray* annotations;

    static boost::optional<ValueSet> fromTNA(const p4configv1::ExternInstance& externInstance) {
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

// It is tempting to unify the code for Lpf & Wred (using CRTP?) but the
// resulting code doesn't look too good and is not really less verbose. In
// particular aggregate initialization is not possible when a class has a base.
struct BFRuntimeSchemaGenerator::Lpf {
    std::string name;
    P4Id id;
    int64_t size;
    Util::JsonArray* annotations;

    static boost::optional<Lpf> fromTNA(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Lpf lpf;
        if (!externInstance.info().UnpackTo(&lpf)) {
            ::error("Extern instance %1% does not pack a Lpf object", pre.name());
            return boost::none;
        }
        return Lpf{pre.name(), pre.id(), lpf.size(), transformAnnotations(pre)};
    }

    static boost::optional<Lpf> fromTNADirect(
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

struct BFRuntimeSchemaGenerator::RegisterParam {
    std::string name;
    std::string dataFieldName;
    P4Id id;
    P4Id tableId;
    int64_t initial_value;
    p4configv1::P4DataTypeSpec typeSpec;
    Util::JsonArray* annotations;

    static boost::optional<RegisterParam>
    fromTNA(const p4configv1::ExternInstance& externInstance) {
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

struct BFRuntimeSchemaGenerator::PortMetadata {
    P4Id id;
    std::string name;
    std::string key_name;
    p4configv1::P4DataTypeSpec typeSpec;
    Util::JsonArray* annotations;

    static boost::optional<PortMetadata> fromTNA(
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

struct BFRuntimeSchemaGenerator::DynHash {
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

    static boost::optional<DynHash> fromTNA(
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
        auto cfgId = makeBFRuntimeId(pre.id(), ::barefoot::P4Ids::HASH_CONFIGURE);
        auto cmpId = makeBFRuntimeId(pre.id(), ::barefoot::P4Ids::HASH_COMPUTE);
        auto algId = makeBFRuntimeId(pre.id(), ::barefoot::P4Ids::HASH_ALGORITHM);
        return DynHash{pre.name(), cfgId, cmpId, algId, dynHash.type_spec(),
                       hfInfo, dynHash.hash_width(), transformAnnotations(pre)};
    }
};

struct BFRuntimeSchemaGenerator::Snapshot {
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

    static boost::optional<Snapshot> fromTNA(
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

struct BFRuntimeSchemaGenerator::ParserChoices {
    std::string name;
    P4Id id;
    std::vector<cstring> choices;

    static boost::optional<ParserChoices> fromTNA(
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

struct BFRuntimeSchemaGenerator::Wred {
    std::string name;
    P4Id id;
    int64_t size;
    Util::JsonArray* annotations;

    static boost::optional<Wred> fromTNA(
        const p4configv1::ExternInstance& externInstance) {
        const auto& pre = externInstance.preamble();
        ::barefoot::Wred wred;
        if (!externInstance.info().UnpackTo(&wred)) {
            ::error("Extern instance %1% does not pack a Wred object", pre.name());
            return boost::none;
        }
        return Wred{pre.name(), pre.id(), wred.size(), transformAnnotations(pre)};
    }

    static boost::optional<Wred> fromTNADirect(
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

boost::optional<BFRuntimeSchemaGenerator::Lpf>
BFRuntimeSchemaGenerator::getDirectLpf(P4Id lpfId) const {
    if (isOfType(lpfId, ::barefoot::P4Ids::DIRECT_LPF)) {
        auto* externInstance = findExternInstance(p4info, lpfId);
        if (externInstance == nullptr) return boost::none;
        return Lpf::fromTNADirect(*externInstance);
    }
    return boost::none;
}

boost::optional<BFRuntimeSchemaGenerator::Wred>
BFRuntimeSchemaGenerator::getDirectWred(P4Id wredId) const {
    if (isOfType(wredId, ::barefoot::P4Ids::DIRECT_WRED)) {
        auto* externInstance = findExternInstance(p4info, wredId);
        if (externInstance == nullptr) return boost::none;
        return Wred::fromTNADirect(*externInstance);
    }
    return boost::none;
}

boost::optional<BFRuntimeSchemaGenerator::Counter>
BFRuntimeSchemaGenerator::getDirectCounter(P4Id counterId) const {
    if (isOfType(counterId, p4configv1::P4Ids::DIRECT_COUNTER)) {
        auto* counter = Standard::findDirectCounter(p4info, counterId);
        if (counter == nullptr) return boost::none;
        return Counter::fromDirect(*counter);
    } else if (isOfType(counterId, ::barefoot::P4Ids::DIRECT_COUNTER)) {
        auto* externInstance = findExternInstance(p4info, counterId);
        if (externInstance == nullptr) return boost::none;
        return fromTNADirectCounter(*externInstance);
    }
    return boost::none;
}

boost::optional<BFRuntimeSchemaGenerator::Meter>
BFRuntimeSchemaGenerator::getDirectMeter(P4Id meterId) const {
    if (isOfType(meterId, p4configv1::P4Ids::DIRECT_METER)) {
        auto* meter = Standard::findDirectMeter(p4info, meterId);
        if (meter == nullptr) return boost::none;
        return Meter::fromDirect(*meter);
    } else if (isOfType(meterId, ::barefoot::P4Ids::DIRECT_METER)) {
        auto* externInstance = findExternInstance(p4info, meterId);
        if (externInstance == nullptr) return boost::none;
        return fromTNADirectMeter(*externInstance);
    }
    return boost::none;
}

boost::optional<BFRuntimeSchemaGenerator::Register>
BFRuntimeSchemaGenerator::getDirectRegister(P4Id registerId) const {
    if (!isOfType(registerId, ::barefoot::P4Ids::DIRECT_REGISTER)) return boost::none;
    auto* externInstance = findExternInstance(p4info, registerId);
    if (externInstance == nullptr) return boost::none;
    return fromTNADirectRegister(*externInstance);
}

void
BFRuntimeSchemaGenerator::addActionSelectorGetMemberCommon(Util::JsonArray* tablesJson,
                                        const ActionSelector& actionSelector) const {
        auto* tableJson = initTableJson(actionSelector.get_mem_name,
                actionSelector.get_mem_id, "SelectorGetMember", 1 /* size */,
                actionSelector.annotations);

        auto* keyJson = new Util::JsonArray();
        addKeyField(keyJson, BF_RT_DATA_SELECTOR_GROUP_ID, "$SELECTOR_GROUP_ID",
                            true /* mandatory */, "Exact", makeTypeInt("uint64"));
        addKeyField(keyJson, BF_RT_DATA_HASH_VALUE, "hash_value",
                            true /* mandatory */, "Exact", makeTypeInt("uint64"));
        tableJson->emplace("key", keyJson);

        auto* dataJson = new Util::JsonArray();
        {
            auto* f = makeCommonDataField(BF_RT_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
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
BFRuntimeSchemaGenerator::addActionSelectorCommon(Util::JsonArray* tablesJson,
                const ActionSelector& actionSelector) const {
    // TODO(antonin): formalize ID allocation for selector tables
    // repeat same annotations as for action table
    // the maximum number of groups is the table size for the selector table
    auto* tableJson = initTableJson(
        actionSelector.name, actionSelector.id, "Selector",
        actionSelector.num_groups, actionSelector.annotations);

    auto* keyJson = new Util::JsonArray();
    addKeyField(keyJson, TD_DATA_SELECTOR_GROUP_ID, "$SELECTOR_GROUP_ID",
            true /* mandatory */, "Exact", makeTypeInt("uint32"));
    tableJson->emplace("key", keyJson);

    auto* dataJson = new Util::JsonArray();
    {
        auto* f = makeCommonDataField(
                TD_DATA_ACTION_MEMBER_ID, "$ACTION_MEMBER_ID",
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
    addToDependsOn(tableJson, actionSelector.action_profile_id);

    tablesJson->append(tableJson);
}

bool
BFRuntimeSchemaGenerator::addActionProfIds(const p4configv1::Table& table,
        Util::JsonObject* tableJson) const {
    auto implementationId = table.implementation_id();
    auto actProfId = static_cast<P4Id>(0);
    auto actSelectorId = static_cast<P4Id>(0);
    if (implementationId > 0) {
        auto hasSelector = actProfHasSelector(implementationId);
        if (hasSelector == boost::none) {
            ::error("Invalid implementation id in p4info: %1%", implementationId);
            return false;
        }
        cstring tableType = "";
        if (*hasSelector) {
            actSelectorId = makeActSelectorId(implementationId);
            tableType = "MatchAction_Indirect_Selector";
            // actProfId will be set while visiting action profile externs
        } else {
            actProfId = makeActProfId(implementationId);
            tableType = "MatchAction_Indirect";
        }
        tableJson->erase("table_type");
        tableJson->emplace("table_type", tableType);
    }

    if (actProfId > 0) addToDependsOn(tableJson, actProfId);
    if (actSelectorId > 0) addToDependsOn(tableJson, actSelectorId);
    return true;
}

void
BFRuntimeSchemaGenerator::addActionProfs(Util::JsonArray* tablesJson) const {
    for (const auto& actionProf : p4info.action_profiles()) {
        auto actionProfInstance = ActionProf::from(p4info, actionProf);
        if (actionProfInstance == boost::none) continue;
        addActionProfCommon(tablesJson, *actionProfInstance);

        auto actionSelectorInstance = ActionSelector::from(p4info, actionProf);
        if (actionSelectorInstance == boost::none) continue;
        addActionSelectorCommon(tablesJson, *actionSelectorInstance);
    }
}

void
BFRuntimeSchemaGenerator::addValueSet(Util::JsonArray* tablesJson,
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

void BFRuntimeSchemaGenerator::addDirectResources(const p4configv1::Table& table,
        Util::JsonArray* dataJson, Util::JsonArray* operationsJson,
        Util::JsonArray* attributesJson, P4Id maxActionParamId) const {
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
}

boost::optional<bool>
BFRuntimeSchemaGenerator::actProfHasSelector(P4Id actProfId) const {
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

const Util::JsonObject*
BFRuntimeSchemaGenerator::genSchema() const {
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

    addTNAExterns(tablesJson, learnFiltersJson);
    addPortMetadataExtern(tablesJson);
    addDebugCounterTable(tablesJson);

    return json;
}

void
BFRuntimeSchemaGenerator::addTNAExterns(Util::JsonArray* tablesJson,
                                      Util::JsonArray* learnFiltersJson) const {
    for (const auto& externType : p4info.externs()) {
        auto externTypeId = static_cast<::barefoot::P4Ids::Prefix>(externType.extern_type_id());
        if (externTypeId == ::barefoot::P4Ids::ACTION_PROFILE) {
            for (const auto& externInstance : externType.instances()) {
                auto actionProf = fromTNAActionProfile(p4info, externInstance);
                if (actionProf != boost::none) addActionProfCommon(tablesJson, *actionProf);
            }
        } else if (externTypeId == ::barefoot::P4Ids::ACTION_SELECTOR) {
            for (const auto& externInstance : externType.instances()) {
                auto actionSelector =
                    ActionSelector::fromTNA(p4info, externInstance);
                if (actionSelector != boost::none) {
                    addActionSelectorCommon(tablesJson, *actionSelector);
                    addActionSelectorGetMemberCommon(tablesJson, *actionSelector);
                }
            }
        } else if (externTypeId == ::barefoot::P4Ids::COUNTER) {
            for (const auto& externInstance : externType.instances()) {
                auto counter = fromTNACounter(externInstance);
                if (counter != boost::none) addCounterCommon(tablesJson, *counter);
            }
        } else if (externTypeId == ::barefoot::P4Ids::METER) {
            for (const auto& externInstance : externType.instances()) {
                auto meter = fromTNAMeter(externInstance);
                if (meter != boost::none) addMeterCommon(tablesJson, *meter);
            }
        } else if (externTypeId == ::barefoot::P4Ids::DIGEST) {
            for (const auto& externInstance : externType.instances()) {
                auto digest = fromTNADigest(externInstance);
                if (digest != boost::none) addLearnFilterCommon(learnFiltersJson, *digest);
            }
        } else if (externTypeId == ::barefoot::P4Ids::REGISTER) {
            for (const auto& externInstance : externType.instances()) {
                auto register_ = fromTNARegister(externInstance);
                if (register_ != boost::none)
                    addRegisterCommon(tablesJson, *register_);
            }
        } else if (externTypeId == ::barefoot::P4Ids::REGISTER_PARAM) {
            for (const auto& externInstance : externType.instances()) {
                auto register_param_ = RegisterParam::fromTNA(externInstance);
                if (register_param_ != boost::none)
                    addRegisterParam(tablesJson, *register_param_);
            }
        } else if (externTypeId == ::barefoot::P4Ids::LPF) {
            for (const auto& externInstance : externType.instances()) {
                auto lpf = Lpf::fromTNA(externInstance);
                if (lpf != boost::none) addLpf(tablesJson, *lpf);
            }
        } else if (externTypeId == ::barefoot::P4Ids::WRED) {
            for (const auto& externInstance : externType.instances()) {
                auto wred = Wred::fromTNA(externInstance);
                if (wred != boost::none) addWred(tablesJson, *wred);
            }
        } else if (externTypeId == ::barefoot::P4Ids::VALUE_SET) {
            for (const auto& externInstance : externType.instances()) {
                auto valueSet = ValueSet::fromTNA(externInstance);
                if (valueSet != boost::none) addValueSet(tablesJson, *valueSet);
            }
        } else if (externTypeId == ::barefoot::P4Ids::SNAPSHOT) {
            for (const auto& externInstance : externType.instances()) {
                auto snapshot = Snapshot::fromTNA(externInstance);
                if (snapshot != boost::none) {
                    addSnapshot(tablesJson, *snapshot);
                    addSnapshotLiveness(tablesJson, *snapshot);
                }
            }
        } else if (externTypeId == ::barefoot::P4Ids::HASH) {
            for (const auto& externInstance : externType.instances()) {
                auto dynHash = DynHash::fromTNA(externInstance);
                if (dynHash != boost::none) {
                    addDynHash(tablesJson, *dynHash);
                }
            }
        } else if (externTypeId == ::barefoot::P4Ids::PARSER_CHOICES) {
            for (const auto& externInstance : externType.instances()) {
                auto parserChoices = ParserChoices::fromTNA(externInstance);
                if (parserChoices != boost::none) {
                    // Disabled unless driver adds BF-RT support for dynamically
                    // changing parser configurations
                    // addParserChoices(tablesJson, *parserChoices);
                }
            }
        }
    }
}

// I chose to do this in a separate function rather than in addTNAExterns
// because if there is no PortMetadata extern in P4Info, we need to generate a
// default one.
void
BFRuntimeSchemaGenerator::addPortMetadataExtern(Util::JsonArray* tablesJson) const {
    for (const auto& externType : p4info.externs()) {
        auto externTypeId = static_cast<::barefoot::P4Ids::Prefix>(externType.extern_type_id());
        if (externTypeId == ::barefoot::P4Ids::PORT_METADATA) {
            // For multipipe and multiple ingress per pipe scenarios we can have
            // multiple port metadata extern instances in the program, here we
            // add all instances collected in the program
            for (const auto& externInstance : externType.instances()) {
                auto portMetadata = PortMetadata::fromTNA(externInstance);
                if (portMetadata != boost::none) addPortMetadata(tablesJson, *portMetadata);
            }
        }
    }
}

void
BFRuntimeSchemaGenerator::addRegisterParamDataFields(Util::JsonArray* dataJson,
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
BFRuntimeSchemaGenerator::addRegisterParam(Util::JsonArray* tablesJson,
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
BFRuntimeSchemaGenerator::addPortMetadata(Util::JsonArray* tablesJson,
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
BFRuntimeSchemaGenerator::addDynHash(Util::JsonArray* tablesJson,
                                     const DynHash& dynHash) const {
    addDynHashAlgorithm(tablesJson, dynHash);
    addDynHashConfig(tablesJson, dynHash);
    addDynHashCompute(tablesJson, dynHash);
}

void
BFRuntimeSchemaGenerator::addDynHashConfig(Util::JsonArray* tablesJson,
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
BFRuntimeSchemaGenerator::addDynHashAlgorithm(Util::JsonArray* tablesJson,
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
    addToDependsOn(tableJson, dynHash.cfgId);

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

    tableJson->emplace("action_specs", actionSpecsJson);
    tableJson->emplace("supported_operations", new Util::JsonArray());
    tableJson->emplace("attributes", new Util::JsonArray());

    tablesJson->append(tableJson);
}

void
BFRuntimeSchemaGenerator::addDynHashCompute(Util::JsonArray* tablesJson,
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
BFRuntimeSchemaGenerator::addLpfDataFields(Util::JsonArray* dataJson) {
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
BFRuntimeSchemaGenerator::addLpf(Util::JsonArray* tablesJson, const Lpf& lpf) const {
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
BFRuntimeSchemaGenerator::addWredDataFields(Util::JsonArray* dataJson) {
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
BFRuntimeSchemaGenerator::addWred(Util::JsonArray* tablesJson, const Wred& wred) const {
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

void
BFRuntimeSchemaGenerator::addSnapshot(Util::JsonArray* tablesJson,
                                        const Snapshot& snapshot) const {
    auto size = Device::numStages();

    // Snapshot Config Table
    {
        auto tblName = snapshot.getCfgTblName();
        Util::JsonObject *tableJson = findJsonTable(tablesJson, tblName);
        if (!tableJson) {
            auto* tableJson = initTableJson(tblName,
                    makeBFRuntimeId(snapshot.id, ::barefoot::P4Ids::SNAPSHOT),
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
        auto tableId = makeBFRuntimeId(snapshot.id, ::barefoot::P4Ids::SNAPSHOT_TRIGGER);
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
            makeBFRuntimeId(snapshot.id, ::barefoot::P4Ids::SNAPSHOT_DATA),
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
BFRuntimeSchemaGenerator::addSnapshotLiveness(Util::JsonArray* tablesJson,
    const Snapshot& snapshot) const {
  auto tblName = snapshot.getLivTblName();
  Util::JsonObject *tableJson = findJsonTable(tablesJson, tblName);
  if (!tableJson) {
    auto tableId = makeBFRuntimeId(snapshot.id, ::barefoot::P4Ids::SNAPSHOT_LIVENESS);
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
BFRuntimeSchemaGenerator::addParserChoices(Util::JsonArray* tablesJson,
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
BFRuntimeSchemaGenerator::addDebugCounterTable(Util::JsonArray* tablesJson) const {
    P4Id id = makeBFRuntimeId(0, barefoot::P4Ids::DEBUG_COUNTER);
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


}  // namespace BFRT

}  // namespace BFN
