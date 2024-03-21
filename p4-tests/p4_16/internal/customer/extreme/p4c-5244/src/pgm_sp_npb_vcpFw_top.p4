// Copyright 2020-2021 Extreme Networks, Inc.
// All rights reserved.

#ifndef _PGM_SP_NPB_VCPFW_TOP_
#define _PGM_SP_NPB_VCPFW_TOP_

#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#define BRIDGED_METADATA_WIDTH          36 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs

#define BRIDGED_METADATA_WIDTH_EG        0 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs

#include "p4src_includes.p4"

Pipeline(
    IngressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_VCPFW),
    IngressControl(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_VCPFW),
    IngressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_VCPFW),
    EgressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_VCPFW),
    EgressControl(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_VCPFW),
    EgressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_VCPFW)) pipeline_npb_vcpFw;

Switch(pipeline_npb_vcpFw) main;

#endif // _PGM_SP_NPB_VCPFW_TOP_
