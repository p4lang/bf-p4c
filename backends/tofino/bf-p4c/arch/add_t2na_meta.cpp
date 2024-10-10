
#include "bf-p4c/arch/add_t2na_meta.h"

namespace BFN {

// Check T2NA metadata structures and headers and add missing fields
void AddT2naMeta::postorder(IR::Type_StructLike* typeStructLike) {
    cstring typeStructLikeName = typeStructLike->name;
    if (typeStructLikeName == "ingress_intrinsic_metadata_for_deparser_t" ||
        typeStructLikeName == "egress_intrinsic_metadata_for_deparser_t") {
        if (typeStructLike->fields.getDeclaration("mirror_io_select"_cs)) {
            LOG3("AddT2naMeta : " << typeStructLikeName << " already complete");
            return;
        }
        LOG3("AddT2naMeta : Adding missing fields to " << typeStructLikeName);
        typeStructLike->fields.push_back(
            new IR::StructField("mirror_io_select", IR::Type::Bits::get(1)));
        typeStructLike->fields.push_back(
            new IR::StructField("mirror_hash", IR::Type::Bits::get(13)));
        typeStructLike->fields.push_back(
            new IR::StructField("mirror_ingress_cos", IR::Type::Bits::get(3)));
        typeStructLike->fields.push_back(
            new IR::StructField("mirror_deflect_on_drop", IR::Type::Bits::get(1)));
        typeStructLike->fields.push_back(
            new IR::StructField("mirror_multicast_ctrl", IR::Type::Bits::get(1)));
        typeStructLike->fields.push_back(
            new IR::StructField("mirror_egress_port", new IR::Type_Name("PortId_t")));
        typeStructLike->fields.push_back(
            new IR::StructField("mirror_qid", new IR::Type_Name("QueueId_t")));
        typeStructLike->fields.push_back(
            new IR::StructField("mirror_coalesce_length", IR::Type::Bits::get(8)));
        typeStructLike->fields.push_back(
            new IR::StructField("adv_flow_ctl", IR::Type::Bits::get(32)));
        typeStructLike->fields.push_back(
            new IR::StructField("mtu_trunc_len", IR::Type::Bits::get(14)));
        typeStructLike->fields.push_back(
            new IR::StructField("mtu_trunc_err_f", IR::Type::Bits::get(1)));
        if (typeStructLikeName == "ingress_intrinsic_metadata_for_deparser_t") {
            typeStructLike->fields.push_back(
                new IR::StructField("pktgen", IR::Type::Bits::get(1)));
            typeStructLike->fields.push_back(
                new IR::StructField("pktgen_address", IR::Type::Bits::get(14)));
            typeStructLike->fields.push_back(
                new IR::StructField("pktgen_length", IR::Type::Bits::get(10)));
        }
    } else if (typeStructLikeName == "egress_intrinsic_metadata_t") {
        const IR::StructField* lastStructField = nullptr;
        for (const auto* structField : typeStructLike->fields) {
            lastStructField = structField;
        };
        if (lastStructField && lastStructField->annotations->getSingle("padding"_cs)) {
            LOG3("AddT2naMeta : " << typeStructLikeName << " already complete");
            return;
        }
        LOG3("AddT2naMeta : Adding missing fields to " << typeStructLikeName);
        typeStructLike->fields.push_back(
            new IR::StructField("_pad_eg_int_md",
                                new IR::Annotations({ new IR::Annotation("padding", { }) }),
                                IR::Type::Bits::get(8)));
    }
}

}  // namespace BFN
