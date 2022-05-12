#include "bf-p4c/parde/add_parde_metadata.h"
#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/device.h"
#include "bf-p4c/common/ir_utils.h"
#include "lib/exceptions.h"

bool AddParserMetadata::preorder(IR::BFN::Parser *parser) {
    switch (parser->gress) {
        case INGRESS: addIngressMetadata(parser); break;
        case EGRESS:  addEgressMetadata(parser);  break;
        default: break;  // Nothing for Ghost
    }

    return true;
}

void AddParserMetadata::addTofinoIngressParserEntryPoint(IR::BFN::Parser* parser) {
    // This state initializes some special metadata and serves as an entry
    // point.
    auto *igParserMeta =
            getMetadataType(pipe, "ingress_intrinsic_metadata_from_parser");
    auto *alwaysDeparseBit =
            new IR::TempVar(IR::Type::Bits::get(1), true, "ingress$always_deparse");
    auto *bridgedMetadataIndicator =
            new IR::TempVar(IR::Type::Bits::get(8), false, BFN::BRIDGED_MD_INDICATOR);
    auto *globalTimestamp = gen_fieldref(igParserMeta, "global_tstamp");
    auto *globalVersion = gen_fieldref(igParserMeta, "global_ver");

    auto prim = new IR::Vector<IR::BFN::ParserPrimitive>();
    if (isV1) {
        prim->push_back(new IR::BFN::Extract(alwaysDeparseBit,
                new IR::BFN::ConstantRVal(1)));
        prim->push_back(new IR::BFN::Extract(bridgedMetadataIndicator,
                new IR::BFN::ConstantRVal(0)));
    }
    if (Device::currentDevice() == Device::TOFINO) {
        prim->push_back(new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(StartLen(432, 48))));
        prim->push_back(new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(StartLen(480, 32))));
    } else {
        prim->push_back(new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(StartLen(400, 48))));
        prim->push_back(new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(StartLen(448, 32))));
    }

    parser->start =
      new IR::BFN::ParserState(createThreadName(parser->gress, "$entry_point"), parser->gress,
        *prim, { },
        { new IR::BFN::Transition(match_t(), 0, parser->start) });
}

void AddParserMetadata::addIngressMetadata(IR::BFN::Parser *parser) {
    if (Device::currentDevice() == Device::TOFINO ||
        Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
        || Device::currentDevice() == Device::CLOUDBREAK
#endif
    ) {
        addTofinoIngressParserEntryPoint(parser);
#if HAVE_FLATROCK
    } else if (Device::currentDevice() == Device::FLATROCK) {
        ::warning("Parser metadata not implemented for %1%", Device::name());
#endif
    }
}

void AddParserMetadata::addTofinoEgressParserEntryPoint(IR::BFN::Parser* parser) {
    auto* egParserMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_from_parser");

    auto* alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "egress$always_deparse");
    auto* globalTimestamp = gen_fieldref(egParserMeta, "global_tstamp");
    auto* globalVersion = gen_fieldref(egParserMeta, "global_ver");

    auto prim = new IR::Vector<IR::BFN::ParserPrimitive>();
    if (isV1)
        prim->push_back(new IR::BFN::Extract(alwaysDeparseBit, new IR::BFN::ConstantRVal(1)));

    if (Device::currentDevice() == Device::TOFINO) {
        prim->push_back(new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(StartLen(432, 48))));
        prim->push_back(new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(StartLen(480, 32))));
    } else {
        prim->push_back(new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(StartLen(400, 48))));
        prim->push_back(new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(StartLen(448, 32))));
    }

    parser->start =
      new IR::BFN::ParserState(createThreadName(parser->gress, "$entry_point"), parser->gress,
        *prim, { },
        { new IR::BFN::Transition(match_t(), 0, parser->start) });
}

void AddParserMetadata::addEgressMetadata(IR::BFN::Parser *parser) {
    if (Device::currentDevice() == Device::TOFINO ||
        Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
        || Device::currentDevice() == Device::CLOUDBREAK
#endif
    ) {
        addTofinoEgressParserEntryPoint(parser);
#if HAVE_FLATROCK
    } else if (Device::currentDevice() == Device::FLATROCK) {
        ::warning("Parser metadata not implemented for %1%", Device::name());
#endif
    }
}

bool AddDeparserMetadata::preorder(IR::BFN::Deparser *d) {
    switch (d->gress) {
        case INGRESS: addIngressMetadata(d); break;
        case EGRESS:  addEgressMetadata(d);  break;
        default: break;  // Nothing for Ghost
    }
    return false;
}

void addDeparserParamRename(IR::BFN::Deparser* deparser,
                      const IR::HeaderOrMetadata* meta,
                      cstring field, cstring paramName) {
    auto* param =
      new IR::BFN::DeparserParameter(paramName, gen_fieldref(meta, field));

    deparser->params.push_back(param);
}

void AddDeparserMetadata::addIngressMetadata(IR::BFN::Deparser *d) {
    for (auto f : Device::archSpec().getIngressInstrinicMetadataForTM()) {
        auto* tmMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_tm");
        if (!tmMeta) {
            ::warning("ig_intr_md_for_tm not defined in ingress control block");
            continue; }
        addDeparserParamRename(d, tmMeta, f.name, f.asm_name);
    }

    for (auto f : Device::archSpec().getIngressInstrinicMetadataForDeparser()) {
        auto* dpMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_deparser");
        if (!dpMeta) {
            ::warning("ig_intr_md_for_dprsr not defined in ingress control block");
            continue; }
        addDeparserParamRename(d, dpMeta, f.name, f.asm_name);
    }
}

void AddDeparserMetadata::addEgressMetadata(IR::BFN::Deparser *d) {
    for (auto f : Device::archSpec().getEgressIntrinsicMetadataForOutputPort()) {
        auto* outputMeta = getMetadataType(pipe, "egress_intrinsic_metadata_for_output_port");
        if (!outputMeta) {
            ::warning("eg_intr_md_for_oport not defined in egress control block");
            continue; }
        addDeparserParamRename(d, outputMeta, f.name, f.asm_name);
    }

    for (auto f : Device::archSpec().getEgressIntrinsicMetadataForDeparser()) {
        auto* dpMeta = getMetadataType(pipe, "egress_intrinsic_metadata_for_deparser");
        if (!dpMeta) {
            ::warning("eg_intr_md_for_dprsr not defined in egress control block");
            continue; }
        addDeparserParamRename(d, dpMeta, f.name, f.asm_name);
    }
    /* egress_port is how the egress deparser knows where to push
     * the reassembled header and is absolutely necessary
     */
    for (auto f : Device::archSpec().getEgressIntrinsicMetadata()) {
        auto* egMeta = getMetadataType(pipe, "egress_intrinsic_metadata");
        if (!egMeta) {
            ::warning("eg_intr_md not defined in egress control block");
            continue; }
        addDeparserParamRename(d, egMeta, f.name, f.asm_name);
    }
}
