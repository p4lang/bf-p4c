#ifndef EXTENSIONS_BF_P4C_CONTROL_PLANE_P4RUNTIME_FORCE_STD_H_
#define EXTENSIONS_BF_P4C_CONTROL_PLANE_P4RUNTIME_FORCE_STD_H_

#include <functional>
#include <unordered_map>
#include <unordered_set>

#include "barefoot/p4info.pb.h"
#include "control-plane/p4RuntimeSerializer.h"
#include "lib/exceptions.h"
#include "lib/log.h"
#include "lib/null.h"
#include "p4/config/v1/p4info.pb.h"

namespace p4configv1 = ::p4::config::v1;

namespace BFN {

class P4RuntimeStdConverter {
 public:
    explicit P4RuntimeStdConverter(const p4configv1::P4Info* p4infoIn)
        : p4infoIn(p4infoIn) { }

    const p4configv1::P4Info* convert() {
        p4configv1::P4Info* p4info = new p4configv1::P4Info;
        p4info->CopyFrom(*p4infoIn);

        using ConverterFn =
            std::function<void(p4configv1::P4Info*, const p4configv1::ExternInstance&)>;
        using C = P4RuntimeStdConverter;
        using std::placeholders::_1;
        using std::placeholders::_2;

        const std::unordered_map<P4Id, ConverterFn> converters = {
          {::barefoot::P4Ids::ACTION_PROFILE, std::bind(&C::convertActionProfile, this, _1, _2)},
          {::barefoot::P4Ids::ACTION_SELECTOR, std::bind(&C::convertActionSelector, this, _1, _2)},
          {::barefoot::P4Ids::COUNTER, std::bind(&C::convertCounter, this, _1, _2)},
          {::barefoot::P4Ids::DIRECT_COUNTER, std::bind(&C::convertDirectCounter, this, _1, _2)},
          {::barefoot::P4Ids::METER, std::bind(&C::convertMeter, this, _1, _2)},
          {::barefoot::P4Ids::DIRECT_METER, std::bind(&C::convertDirectMeter, this, _1, _2)},
          {::barefoot::P4Ids::DIGEST, std::bind(&C::convertDigest, this, _1, _2)},
        };

        static const std::unordered_set<P4Id> suppressWarnings = {
          ::barefoot::P4Ids::REGISTER_PARAM,
          ::barefoot::P4Ids::PORT_METADATA,
          ::barefoot::P4Ids::SNAPSHOT,
          ::barefoot::P4Ids::SNAPSHOT_LIVENESS,
        };

        for (const auto& externType : p4info->externs()) {
            auto externTypeId = static_cast<::barefoot::P4Ids::Prefix>(externType.extern_type_id());
            auto converterIt = converters.find(externTypeId);
            if (converterIt == converters.end()) {
                if (suppressWarnings.count(externTypeId) == 0) {
                    ::warning("No known conversion to standard P4Info for '%1%' extern type",
                              externType.extern_type_name());
                }
                continue;
            }
            for (const auto& externInstance : externType.instances())
                converterIt->second(p4info, externInstance);
        }

        // remove all the Tofino-specific externs now that we have converted
        // them to standard P4Info objects (when it was possible)
        p4info->clear_externs();

        // update implementation_id and direct_resource_ids fields in Table
        // messages because the ids have changed
        updateTables(p4info);

        return p4info;
    }

 private:
    using P4Id = uint32_t;

    template <typename T>
    static constexpr P4Id makeStdId(T base,  p4configv1::P4Ids::Prefix prefix) {
        return static_cast<P4Id>((base & 0xffffff) | (prefix << 24));
    }

    template <typename U>
    static void unpackExternInstance(const p4configv1::ExternInstance& externInstance,
                                     U* unpackedMessage) {
        auto success = externInstance.info().UnpackTo(unpackedMessage);
        // this is a BUG_CHECK because the p4Info message being converted was
        // itself produced by this compiler just a moment ago...
        BUG_CHECK(success, "Could not unpack extern instance '%1%'",
                  externInstance.preamble().name());
    }

    template <typename T>
    void setPreamble(const p4configv1::ExternInstance& externInstance,
                     p4configv1::P4Ids::Prefix stdPrefix,
                     T* stdMessage) {
        const auto& preIn = externInstance.preamble();
        auto* preOut = stdMessage->mutable_preamble();
        preOut->CopyFrom(preIn);
        P4Id idBase = preIn.id() & 0xffffff;
        P4Id id;
        // Convert the Tofino P4Info id to the Standard P4Info id. Most of the
        // time, this just means doing the correct prefix substitution. The only
        // exception at the moment is for action profiles / selectors. The
        // Tofino P4Info uses 2 different id prefixes for profiles & selectors
        // (because they are 2 different extern types in tofino.p4), but
        // Standard P4Info uses a single id prefix. This can create collisions
        // between an action profile and an action selector which have the same
        // "base" id (i.e. id stripped of the prefix). To handle such a
        // collision, we maintain a set of allocated ids.
        do {
          id = makeStdId(idBase++, stdPrefix);
        } while (allocatedIds.count(id) > 0);
        allocatedIds.insert(id);
        preOut->set_id(id);
        auto r = oldToNewIds.emplace(preIn.id(), preOut->id());
        BUG_CHECK(r.second, "Id %1% was already in id map when converting P4Info to standard",
                  preIn.id());
    }

    void convertActionProfile(p4configv1::P4Info* p4info,
                              const p4configv1::ExternInstance& externInstance) {
        ::barefoot::ActionProfile actionProfile;
        unpackExternInstance(externInstance, &actionProfile);
        auto* actionProfileStd = p4info->add_action_profiles();
        setPreamble(externInstance, p4configv1::P4Ids::ACTION_PROFILE, actionProfileStd);
        actionProfileStd->mutable_table_ids()->CopyFrom(actionProfile.table_ids());
        actionProfileStd->set_size(actionProfile.size());
        actionProfileStd->set_with_selector(false);
    }

    void convertActionSelector(p4configv1::P4Info* p4info,
                               const p4configv1::ExternInstance& externInstance) {
        ::barefoot::ActionSelector actionSelector;
        unpackExternInstance(externInstance, &actionSelector);
        auto* actionSelectorStd = p4info->add_action_profiles();
        setPreamble(externInstance, p4configv1::P4Ids::ACTION_PROFILE, actionSelectorStd);
        actionSelectorStd->mutable_table_ids()->CopyFrom(actionSelector.table_ids());
        actionSelectorStd->set_size(actionSelector.size());
        actionSelectorStd->set_with_selector(true);
    }

    static void setCounterSpec(const ::barefoot::CounterSpec& specIn,
                               p4configv1::CounterSpec* specOut) {
        // works because the numerical values of the enum members are the same
        specOut->set_unit(static_cast<p4configv1::CounterSpec::Unit>(specIn.unit()));
    }

    void convertCounter(p4configv1::P4Info* p4info,
                        const p4configv1::ExternInstance& externInstance) {
        ::barefoot::Counter counter;
        unpackExternInstance(externInstance, &counter);
        auto* counterStd = p4info->add_counters();
        setPreamble(externInstance, p4configv1::P4Ids::COUNTER, counterStd);
        counterStd->set_size(counter.size());
        setCounterSpec(counter.spec(), counterStd->mutable_spec());
    }

    void convertDirectCounter(p4configv1::P4Info* p4info,
                              const p4configv1::ExternInstance& externInstance) {
        ::barefoot::DirectCounter directCounter;
        unpackExternInstance(externInstance, &directCounter);
        auto* directCounterStd = p4info->add_direct_counters();
        setPreamble(externInstance, p4configv1::P4Ids::DIRECT_COUNTER, directCounterStd);
        directCounterStd->set_direct_table_id(directCounter.direct_table_id());
        setCounterSpec(directCounter.spec(), directCounterStd->mutable_spec());
    }

    static void setMeterSpec(const ::barefoot::MeterSpec& specIn,
                             p4configv1::MeterSpec* specOut) {
      // works because the numerical values of the enum members are the same
      specOut->set_unit(static_cast<p4configv1::MeterSpec::Unit>(specIn.unit()));
    }

    void convertMeter(p4configv1::P4Info* p4info,
                      const p4configv1::ExternInstance& externInstance) {
        ::barefoot::Meter meter;
        unpackExternInstance(externInstance, &meter);
        auto* meterStd = p4info->add_meters();
        setPreamble(externInstance, p4configv1::P4Ids::METER, meterStd);
        meterStd->set_size(meter.size());
        setMeterSpec(meter.spec(), meterStd->mutable_spec());
    }

    void convertDirectMeter(p4configv1::P4Info* p4info,
                            const p4configv1::ExternInstance& externInstance) {
        ::barefoot::DirectMeter directMeter;
        unpackExternInstance(externInstance, &directMeter);
        auto* directMeterStd = p4info->add_direct_meters();
        setPreamble(externInstance, p4configv1::P4Ids::DIRECT_METER, directMeterStd);
        directMeterStd->set_direct_table_id(directMeter.direct_table_id());
        setMeterSpec(directMeter.spec(), directMeterStd->mutable_spec());
    }

    void convertDigest(p4configv1::P4Info* p4info,
                       const p4configv1::ExternInstance& externInstance) {
        ::barefoot::Digest digest;
        unpackExternInstance(externInstance, &digest);
        auto* digestStd = p4info->add_digests();
        setPreamble(externInstance, p4configv1::P4Ids::DIGEST, digestStd);
        digestStd->mutable_type_spec()->CopyFrom(digest.type_spec());
    }

    void updateTables(p4configv1::P4Info* p4info) {
        for (auto& table : *p4info->mutable_tables()) {
            auto& tableName = table.preamble().name();
            auto implementationId = table.implementation_id();
            if (implementationId) {
                auto idIt = oldToNewIds.find(implementationId);
                if (idIt != oldToNewIds.end()) {
                    table.set_implementation_id(idIt->second);
                } else {
                    ::error("Unknown implementation id %1% for table '%2%' "
                            "(maybe the implementation extern type is not supported)",
                            implementationId, tableName);
                    table.clear_implementation_id();
                }
            }
            int idx = 0;
            for (auto directResourceId : table.direct_resource_ids()) {
                auto idIt = oldToNewIds.find(directResourceId);
                if (idIt != oldToNewIds.end()) {
                    table.set_direct_resource_ids(idx++, idIt->second);
                } else {
                    ::warning("Unknown direct resource id %1% for table '%2%' "
                              "(maybe the extern type is not supported), "
                              "so dropping the direct resource for the table",
                              directResourceId, tableName);
                }
            }
            table.mutable_direct_resource_ids()->Truncate(idx);
        }
    }

    const p4configv1::P4Info* p4infoIn;
    std::unordered_set<P4Id> allocatedIds{};
    std::unordered_map<P4Id, P4Id> oldToNewIds{};
};

P4::P4RuntimeAPI convertToStdP4Runtime(const P4::P4RuntimeAPI& p4RuntimeIn) {
    P4::P4RuntimeAPI p4RuntimeOut;
    CHECK_NULL(p4RuntimeIn.p4Info);
    P4RuntimeStdConverter converter(p4RuntimeIn.p4Info);

    p4RuntimeOut.p4Info = converter.convert();
    p4RuntimeOut.entries = p4RuntimeIn.entries;

    // Note that the output P4Info may include some additional data in
    // P4TypeInfo which is not required any more, however, this is unlikely to
    // be an issue.
    return p4RuntimeOut;
}

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_CONTROL_PLANE_P4RUNTIME_FORCE_STD_H_ */
