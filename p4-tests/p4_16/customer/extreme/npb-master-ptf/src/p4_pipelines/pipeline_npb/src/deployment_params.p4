// This file is auto-generated via /npb-dp/p4_pipelines/cls/pipeline.py
#ifndef _DEPLOYMENT_PARAMS_PIPELINE_NPB_
#define _DEPLOYMENT_PARAMS_PIPELINE_NPB_

// Use this #define within your modules to declare
// the list of deployment parameters being passed in
// from above.
#define MODULE_DEPLOYMENT_PARAMS \
bool OUTER_VXLAN_ENABLE = true, \
bool UDF_ENABLE = false, \
bool OUTER_VNTAG_ENABLE = true, \
bool OUTER_NVGRE_ENABLE = true, \
bool FOLDED_ENABLE = false, \
bool OUTER_ETAG_ENABLE = true, \
bool OUTER_GENEVE_ENABLE = false

// Use this #define within your modules to declare
// the list of deployment parameters being passed down
// to sub-module instances.
#define INSTANCE_DEPLOYMENT_PARAMS \
OUTER_VXLAN_ENABLE, \
UDF_ENABLE, \
OUTER_VNTAG_ENABLE, \
OUTER_NVGRE_ENABLE, \
FOLDED_ENABLE, \
OUTER_ETAG_ENABLE, \
OUTER_GENEVE_ENABLE 

// Deployment Profile: vcpFw
// --------------------------------------------------

const bool OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool UDF_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool FOLDED_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW = false;

// Use this #define to pass the list of deployment
// parameters into your top-level module instantiations.
#define INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_VCPFW \
OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW, \
UDF_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW, \
FOLDED_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW 

// Deployment Profile: chtr
// --------------------------------------------------

const bool OUTER_VXLAN_ENABLE_PIPELINE_NPB_CHTR = false;
const bool UDF_ENABLE_PIPELINE_NPB_CHTR = false;
const bool OUTER_VNTAG_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_NVGRE_ENABLE_PIPELINE_NPB_CHTR = true;
const bool FOLDED_ENABLE_PIPELINE_NPB_CHTR = false;
const bool OUTER_ETAG_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_GENEVE_ENABLE_PIPELINE_NPB_CHTR = true;

// Use this #define to pass the list of deployment
// parameters into your top-level module instantiations.
#define INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_CHTR \
OUTER_VXLAN_ENABLE_PIPELINE_NPB_CHTR, \
UDF_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_VNTAG_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_NVGRE_ENABLE_PIPELINE_NPB_CHTR, \
FOLDED_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_ETAG_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_GENEVE_ENABLE_PIPELINE_NPB_CHTR 

#endif // _DEPLOYMENT_PARAMS_PIPELINE_NPB_