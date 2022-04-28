#ifndef _PGM_FP_NPB_DEDUP_DTEL_VCPFW_TOP_
#define _PGM_FP_NPB_DEDUP_DTEL_VCPFW_TOP_

#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#define BRIDGED_METADATA_WIDTH          36 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs

#include "p4src_includes.p4"

Pipeline(
    IngressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_A_VCPFW),
    IngressControl_A(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_A_VCPFW),
    IngressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_A_VCPFW),
    EgressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_A_VCPFW),
    EgressControl_A(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_A_VCPFW),
    EgressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_A_VCPFW))
pipeline_npb_dedup_dtel_A_vcpFw;

Pipeline(
    IngressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_B_VCPFW),
    IngressControl_B(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_B_VCPFW),
    IngressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_B_VCPFW),
    EgressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_B_VCPFW),
    EgressControl_B(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_B_VCPFW),
    EgressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_DEDUP_DTEL_B_VCPFW))
pipeline_npb_dedup_dtel_B_vcpFw;

Switch(pipeline_npb_dedup_dtel_A_vcpFw, pipeline_npb_dedup_dtel_B_vcpFw) main;

#endif // _PGM_FP_NPB_DEDUP_DTEL_VCPFW_TOP_
