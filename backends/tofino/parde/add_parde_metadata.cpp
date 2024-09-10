#include "backends/tofino/parde/add_parde_metadata.h"
#include "backends/tofino/arch/bridge_metadata.h"
#include "backends/tofino/device.h"
#include "backends/tofino/common/ir_utils.h"
#include "backends/tofino/common/pragma/all_pragmas.h"
#include "backends/tofino/common/pragma/collect_global_pragma.h"
#include "backends/tofino/common/pragma/pragma.h"
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

    auto prim = new IR::Vector<IR::BFN::ParserPrimitive>();
    if (isV1) {
        prim->push_back(new IR::BFN::Extract(alwaysDeparseBit,
                new IR::BFN::ConstantRVal(1)));
        prim->push_back(new IR::BFN::Extract(bridgedMetadataIndicator,
                new IR::BFN::ConstantRVal(0)));
    }

    if (igParserMeta) {
        auto *globalTimestamp = gen_fieldref(igParserMeta, "global_tstamp");
        auto *globalVersion = gen_fieldref(igParserMeta, "global_ver");
        prim->push_back(
            new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(
                    StartLen(Device::metaGlobalTimestampStart(),
                             Device::metaGlobalTimestampLen()))));
        prim->push_back(
            new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(
                    StartLen(Device::metaGlobalVersionStart(),
                             Device::metaGlobalVersionLen()))));
    } else {
        ::warning("ingress_intrinsic_metadata_from_parser not defined in parser %1%",
                  parser->name);
    }

    // Initialize mirror_type.$valid to 1 to workaround ingress drop issue in tofino2.
    // TOF3-DOC: Also tofino3.
    if (Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
        || Device::currentDevice() == Device::CLOUDBREAK
#endif
        ) {
        // can be disabled with a pragma
        if (!pipe->has_pragma(PragmaDisableI2EReservedDropImplementation::name)) {
            auto *igDeparserMeta =
                    getMetadataType(pipe, "ingress_intrinsic_metadata_for_deparser");
            if (igDeparserMeta) {
                auto *mirrorType =
                        gen_fieldref(igDeparserMeta, "mirror_type");
                auto povBit =
                        new IR::BFN::FieldLVal(new IR::TempVar(
                            IR::Type::Bits::get(1), true, mirrorType->toString() + ".$valid"));
                prim->push_back(new IR::BFN::Extract(povBit,
                        new IR::BFN::ConstantRVal(1)));
            } else {
                ::warning("ingress_intrinsic_metadata_for_deparser not defined in parser %1%",
                          parser->name);
            }
        }
    }

    parser->start =
      new IR::BFN::ParserState(createThreadName(parser->gress, "$entry_point"), parser->gress,
        *prim, { },
        { new IR::BFN::Transition(match_t(), 0, parser->start) });
}

#if HAVE_FLATROCK
void AddParserMetadata::addFlatrockIngressParserEntryPoint(IR::BFN::Parser* parser) {
    // Initialize ingress_intrinsic_metadata_for_tm.$zero to 0
    auto* igTmMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_tm");
    CHECK_NULL(igTmMeta);
    auto zeroVar = new IR::BFN::FieldLVal(
        new IR::TempVar(IR::Type::Bits::get(8), true, igTmMeta->name + ".$zero"));
    auto prim = new IR::Vector<IR::BFN::ParserPrimitive>(
        { new IR::BFN::Extract(zeroVar, new IR::BFN::ConstantRVal(0)) });

    parser->start = new IR::BFN::ParserState(createThreadName(parser->gress, "$entry_point"),
        parser->gress, *prim, { }, { new IR::BFN::Transition(match_t(), 0, parser->start) });
}
#endif  // HAVE_FLATROCK

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
        addFlatrockIngressParserEntryPoint(parser);
#endif
    }
}

void AddParserMetadata::addTofinoEgressParserEntryPoint(IR::BFN::Parser* parser) {
    auto* egParserMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_from_parser");

    auto* alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "egress$always_deparse");

    auto prim = new IR::Vector<IR::BFN::ParserPrimitive>();
    if (isV1)
        prim->push_back(new IR::BFN::Extract(alwaysDeparseBit, new IR::BFN::ConstantRVal(1)));

    if (egParserMeta) {
        auto* globalTimestamp = gen_fieldref(egParserMeta, "global_tstamp");
        auto* globalVersion = gen_fieldref(egParserMeta, "global_ver");
        prim->push_back(
            new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(
                    StartLen(Device::metaGlobalTimestampStart(),
                             Device::metaGlobalTimestampLen()))));
        prim->push_back(
            new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(
                    StartLen(Device::metaGlobalVersionStart(),
                             Device::metaGlobalVersionLen()))));
    } else {
        ::warning("egress_intrinsic_metadata_from_parser not defined in parser %1%",
                  parser->name);
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

#if HAVE_FLATROCK
    // Create a zero-field to ensure that there's a zero container available to the metadata packer
    if (Device::currentDevice() == Device::FLATROCK) {
        auto* tmMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_tm");
        if (!tmMeta) {
            ::warning("ig_intr_md_for_tm not defined in ingress control block");
        } else {
            auto* zeroVar = new IR::TempVar(IR::Type::Bits::get(8), true, tmMeta->name + ".$zero");
            auto* param = new IR::BFN::DeparserParameter("zero", zeroVar);
            d->params.push_back(param);
        }
    }
#endif  /* HAVE_FLATROCK */
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
