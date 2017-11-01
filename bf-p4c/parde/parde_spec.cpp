#include "bf-p4c/parde/parde_spec.h"
#include <boost/optional.hpp>
#include <vector>
#include "bf-p4c/ir/bitrange.h"
#include "ir/ir.h"

namespace {

const IR::Member*
createFieldRef(const IR::HeaderOrMetadata* header, cstring field) {
    auto* f = header->type->getField(field);
    BUG_CHECK(f != nullptr,
              "Couldn't find intrinsic metadata field %s in %s", field, header->name);
    return new IR::Member(f->type, new IR::ConcreteHeaderRef(header), field);
}

struct IntrinsicMetadataFieldInfo {
    /// The name of this field.
    cstring name;

    /// The size of this field, in bits.
    size_t bitFieldSize;

    /// The bit which enables this field in the EPB configuration. Note that a
    /// single bit may enable multiple fields. If `boost::none`, this field is
    /// not controlled by the EPB configuration - either it's an ingress field,
    /// or it's an egress field which is always enabled.
    boost::optional<size_t> configBit;
};

using IntrinsicMetadataSpec = std::vector<IntrinsicMetadataFieldInfo>;

const IntrinsicMetadataSpec& getTofinoIngressIntrinsicMetadataSpec() {
    static const IntrinsicMetadataSpec spec = {
        { "resubmit_flag", 1, boost::none },
        { "_pad1", 1, boost::none },
        { "packet_version", 2, boost::none },
        { "_pad2", 3, boost::none },
        { "ingress_port", 9, boost::none },
        { "ingress_mac_tstamp", 48, boost::none },
    };

    return spec;
}

const IntrinsicMetadataSpec& getTofinoEgressIntrinsicMetadataSpec() {
    static const IntrinsicMetadataSpec spec = {
        { "_pad0", 7, boost::none },
        { "egress_port", 9, boost::none },
        { "_pad1", 5, 1 << 0 },
        { "enq_qdepth", 19, 1 << 0 },
        { "_pad2", 6, 1 << 1 },
        { "enq_congest_stat", 2, 1 << 1 },
        { "enq_tstamp", 32, 1 << 2 },
        { "_pad3", 5, 1 << 3 },
        { "deq_qdepth", 19, 1 << 3 },
        { "_pad4", 6, 1 << 4 },
        { "deq_congest_stat", 2, 1 << 4 },
        { "app_pool_congest_stat", 8, 1 << 5 },
        { "deq_timedelta", 32, 1 << 6 },
        { "egress_rid", 16, 1 << 7 },
        { "_pad5", 7, 1 << 8 },
        { "egress_rid_first", 1, 1 << 8 },
        { "_pad6", 3, 1 << 9 },
        { "egress_qid", 5, 1 << 9 },
        { "_pad7", 5, 1 << 10 },
        { "egress_cos", 3, 1 << 10 },
        { "_pad8", 7, 1 << 11 },
        { "deflection_flag", 1, 1 << 11 },
        { "pkt_length", 16, 1 << 12 },
    };

    return spec;
}

/// @return an EPB config with all fields enabled.
EgressParserBufferConfig allFieldsEnabledEPBConfig() {
    return EgressParserBufferConfig{uint16_t(~0)};
}

/// @return the total size in bits of the fields in the given metadata spec. If
/// no EPB config is provided, all EPB-configurable fields are enabled.
size_t computeBitMetadataSize(const IntrinsicMetadataSpec& metadataSpec,
                              EgressParserBufferConfig config = {uint16_t(0)}) {
    size_t bitSize = 0;
    for (auto& field : metadataSpec)
        if (!field.configBit ||
              (config.fieldsEnabled & *field.configBit))
            bitSize += field.bitFieldSize;
    BUG_CHECK(bitSize % 8 == 0, "Intrinsic metadata layout isn't byte aligned?");
    return bitSize;
}

/**
 * Given an intrinsic metadata specific, derive the layout of the fields.
 *
 * @param metadataSpec  The group of intrinsic metadata fields to lay out into a
 *                      FieldPacking.
 * @param header  The header instance that the FieldPacking should reference;
 *                if a parser program is generated from it, this is the header
 *                instance that will be extracted into.
 * @param config  The EPB configuration, which controls whether certain fields
 *                are enabled. If no EPB config is provided, by default all
 *                fields are enabled.
 */
BFN::FieldPacking
createMetadataLayout(const IntrinsicMetadataSpec& metadataSpec,
                     const IR::HeaderOrMetadata* header,
                     EgressParserBufferConfig config = {uint16_t(~0)}) {
    BFN::FieldPacking packing;
    for (auto& field : metadataSpec)
        if (!field.configBit ||
              (config.fieldsEnabled & *field.configBit))
            packing.appendField(createFieldRef(header, field.name),
                                field.bitFieldSize);

    BUG_CHECK(packing.isAlignedTo(8),
              "Intrinsic metadata layout isn't byte aligned?");
    return packing;
}

}  // namespace

size_t TofinoPardeSpec::byteIngressMetadataPrefixSize() const {
    static const size_t byteMetadataPrefixSize =
      computeBitMetadataSize(getTofinoIngressIntrinsicMetadataSpec()) / 8;
    return byteMetadataPrefixSize;
}

size_t
TofinoPardeSpec::byteEgressMetadataSize(EgressParserBufferConfig config) const {
    const size_t byteMetadataSize =
      computeBitMetadataSize(getTofinoEgressIntrinsicMetadataSpec(), config) / 8;
    return byteMetadataSize;
}

BFN::FieldPacking
TofinoPardeSpec::ingressMetadataLayout(const IR::HeaderOrMetadata* header) const {
    return createMetadataLayout(getTofinoIngressIntrinsicMetadataSpec(), header);
}

EgressParserBufferConfig TofinoPardeSpec::defaultEPBConfig() const {
    return allFieldsEnabledEPBConfig();
}

BFN::FieldPacking
TofinoPardeSpec::egressMetadataLayout(EgressParserBufferConfig config,
                                      const IR::HeaderOrMetadata* header) const {
    return createMetadataLayout(getTofinoEgressIntrinsicMetadataSpec(), header,
                                config);
}

namespace {

const IntrinsicMetadataSpec& getJBayIngressIntrinsicMetadataSpec() {
    // Relative to Tofino, there are no changes to the part of the ingress
    // intrinsic metadata that precedes the static per-port metadata, so we can
    // just reuse the same configuration.
    return getTofinoIngressIntrinsicMetadataSpec();
}

const IntrinsicMetadataSpec& getJBayEgressIntrinsicMetadataSpec() {
    // XXX(seth): The CSR files suggest that JBay provides exactly the same egress
    // intrinsic metadata and EPB configuration bits as Tofino. We should verify
    // that, though.
    return getTofinoEgressIntrinsicMetadataSpec();
}

}  // namespace

size_t JBayPardeSpec::byteIngressMetadataPrefixSize() const {
    static const size_t byteMetadataPrefixSize =
      computeBitMetadataSize(getJBayIngressIntrinsicMetadataSpec()) / 8;
    return byteMetadataPrefixSize;
}

size_t
JBayPardeSpec::byteEgressMetadataSize(EgressParserBufferConfig config) const {
    const size_t byteMetadataSize =
      computeBitMetadataSize(getJBayEgressIntrinsicMetadataSpec(), config) / 8;
    return byteMetadataSize;
}

BFN::FieldPacking
JBayPardeSpec::ingressMetadataLayout(const IR::HeaderOrMetadata* header) const {
    return createMetadataLayout(getJBayIngressIntrinsicMetadataSpec(), header);
}

EgressParserBufferConfig JBayPardeSpec::defaultEPBConfig() const {
    return allFieldsEnabledEPBConfig();
}

BFN::FieldPacking
JBayPardeSpec::egressMetadataLayout(EgressParserBufferConfig config,
                                    const IR::HeaderOrMetadata* header) const {
    return createMetadataLayout(getJBayEgressIntrinsicMetadataSpec(), header,
                                config);
}
