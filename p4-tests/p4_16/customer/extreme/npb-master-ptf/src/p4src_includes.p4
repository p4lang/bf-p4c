// Copyright 2022 Extreme Networks, Inc.
// All rights reserved.

// This file is auto-generated via /npb-dp/p4_programs/cls/package.py
#ifndef _P4SRC_INCLUDES_PGM_SP_NPB_VCPFW_
#define _P4SRC_INCLUDES_PGM_SP_NPB_VCPFW_

#include "./pipeline_npb/deployment_params.p4"
#include "./pipeline_npb/features.p4"
#include "./pipeline_npb/field_widths.p4"
#include "./pipeline_npb/pragmas.p4"
#include "./pipeline_npb/headers.p4"
#include "./pipeline_npb/types.p4"
#include "./pipeline_npb/util.p4"
#include "./pipeline_npb/hash.p4"
#include "./pipeline_npb/scoper_lkp_to_lkp.p4"
#include "./pipeline_npb/scoper_hdr0_to_lkp.p4"
#include "./pipeline_npb/scoper_hdr1_to_lkp.p4"
#include "./pipeline_npb/scoper_hdr2_to_lkp.p4"
#include "./pipeline_npb/scoper.p4"
#include "./pipeline_npb/copp.p4"
#include "./pipeline_npb/acl.p4"
#include "./pipeline_npb/l2.p4"
#include "./pipeline_npb/l3.p4"
#include "./pipeline_npb/nexthop.p4"
#include "./pipeline_npb/port.p4"
#include "./pipeline_npb/payload_len.p4"
#include "./pipeline_npb/tunnel.p4"
#include "./pipeline_npb/multicast.p4"
#include "./pipeline_npb/meter.p4"
#include "./pipeline_npb/dtel.p4"
#include "./pipeline_npb/npb_ing_parser.p4"
#include "./pipeline_npb/npb_ing_set_lkp.p4"
#include "./pipeline_npb/npb_ing_hdr_cntrs_transport.p4"
#include "./pipeline_npb/npb_ing_hdr_cntrs_outer.p4"
#include "./pipeline_npb/npb_ing_hdr_cntrs_inner.p4"
#include "./pipeline_npb/npb_ing_hdr_cntrs_misc.p4"
#include "./pipeline_npb/npb_ing_sfc_top.p4"
#include "./pipeline_npb/npb_ing_sf_npb_basic_adv_sfp_sel.p4"
#include "./pipeline_npb/npb_ing_sf_npb_basic_adv_dedup.p4"
#include "./pipeline_npb/npb_ing_sf_npb_basic_adv_top.p4"
#include "./pipeline_npb/npb_ing_sf_multicast_top.p4"
#include "./pipeline_npb/npb_ing_sff_top.p4"
#include "./pipeline_npb/npb_ing_top.p4"
#include "./pipeline_npb/npb_ing_deparser.p4"
#include "./pipeline_npb/npb_egr_parser.p4"
#include "./pipeline_npb/npb_egr_set_lkp.p4"
#include "./pipeline_npb/npb_egr_sff_top.p4"
#include "./pipeline_npb/npb_egr_sf_proxy_hdr_strip.p4"
#include "./pipeline_npb/npb_egr_sf_proxy_hdr_edit.p4"
#include "./pipeline_npb/npb_egr_sf_proxy_truncate.p4"
#include "./pipeline_npb/npb_egr_sf_proxy_top.p4"
#include "./pipeline_npb/npb_egr_top.p4"
#include "./pipeline_npb/npb_egr_deparser.p4"
#include "./pipeline_npb/npb_core.p4"

#endif // _P4SRC_INCLUDES_PGM_SP_NPB_VCPFW_
