/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#ifndef _P4_ACL_
#define _P4_ACL_

#include "scoper.p4"

//-----------------------------------------------------------------------------
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------

#define INGRESS_MAC_ACL_KEY              \
    /* l2 */                             \
    lkp.mac_src_addr : ternary;          \
    lkp.mac_dst_addr : ternary;          \
    lkp.mac_type : ternary;              \
	lkp.pcp : ternary;                   \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/

#ifdef BUG_10439_WORKAROUND
#define INGRESS_IPV4_ACL_KEY             \
    /* l3 */                             \
    lkp.ip_src_addr_0[31:0] : ternary;     \
    lkp.ip_dst_addr_0[31:0] : ternary;     \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
  /*lkp.ip_frag : ternary;*/             \
    /* l4 */                             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
    lkp.tcp_flags : ternary;             \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#else
#define INGRESS_IPV4_ACL_KEY             \
    /* l3 */                             \
    lkp.ip_src_addr[31:0] : ternary;     \
    lkp.ip_dst_addr[31:0] : ternary;     \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
  /*lkp.ip_frag : ternary;*/             \
    /* l4 */                             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
    lkp.tcp_flags : ternary;             \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#endif

#ifdef BUG_10439_WORKAROUND
#define INGRESS_IPV6_ACL_KEY             \
    /* l3 */                             \
    lkp.ip_src_addr_3 : ternary;           \
    lkp.ip_src_addr_2 : ternary;           \
    lkp.ip_src_addr_1 : ternary;           \
    lkp.ip_src_addr_0 : ternary;           \
    lkp.ip_dst_addr_3 : ternary;           \
    lkp.ip_dst_addr_2 : ternary;           \
    lkp.ip_dst_addr_1 : ternary;           \
    lkp.ip_dst_addr_0 : ternary;           \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
    lkp.tcp_flags : ternary;             \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#else
#define INGRESS_IPV6_ACL_KEY             \
    /* l3 */                             \
    lkp.ip_src_addr : ternary;           \
    lkp.ip_dst_addr : ternary;           \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
    lkp.tcp_flags : ternary;             \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#endif

#ifdef BUG_10439_WORKAROUND
#define INGRESS_IP_ACL_KEY               \
  /*lkp.mac_type : ternary;*/            \
    /* l3 */                             \
    lkp.ip_src_addr_3 : ternary;           \
    lkp.ip_src_addr_2 : ternary;           \
    lkp.ip_src_addr_1 : ternary;           \
    lkp.ip_src_addr_0 : ternary;           \
    lkp.ip_dst_addr_3 : ternary;           \
    lkp.ip_dst_addr_2 : ternary;           \
    lkp.ip_dst_addr_1 : ternary;           \
    lkp.ip_dst_addr_0 : ternary;           \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
    lkp.tcp_flags : ternary;             \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#else
#define INGRESS_IP_ACL_KEY               \
  /*lkp.mac_type : ternary;*/            \
    /* l3 */                             \
    lkp.ip_src_addr : ternary;           \
    lkp.ip_dst_addr : ternary;           \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
    lkp.tcp_flags : ternary;             \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#endif

#ifdef UDF_ENABLE

#define INGRESS_L7_ACL_KEY               \
    ig_md.lkp_l7_udf : ternary;          \
	/*lkp.drop_reason : ternary;*/

#else // UDF_ENABLE

#define INGRESS_L7_ACL_KEY               \
                              
#endif // UDF_ENABLE

//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------

#define EGRESS_MAC_ACL_KEY               \
    /* l2 */                             \
    lkp.mac_src_addr : ternary;          \
    lkp.mac_dst_addr : ternary;          \
    lkp.mac_type : ternary;              \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/

#ifdef BUG_10439_WORKAROUND
#define EGRESS_IPV4_ACL_KEY              \
    /* l3 */                             \
    lkp.ip_src_addr_0[31:0] : ternary;     \
    lkp.ip_dst_addr_0[31:0] : ternary;     \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.tcp_flags : ternary;             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#else
#define EGRESS_IPV4_ACL_KEY              \
    /* l3 */                             \
    lkp.ip_src_addr[31:0] : ternary;     \
    lkp.ip_dst_addr[31:0] : ternary;     \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.tcp_flags : ternary;             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#endif

#ifdef BUG_10439_WORKAROUND
#define EGRESS_IPV6_ACL_KEY              \
    /* l3 */                             \
    lkp.ip_src_addr_3 : ternary;           \
    lkp.ip_src_addr_2 : ternary;           \
    lkp.ip_src_addr_1 : ternary;           \
    lkp.ip_src_addr_0 : ternary;           \
    lkp.ip_dst_addr_3 : ternary;           \
    lkp.ip_dst_addr_2 : ternary;           \
    lkp.ip_dst_addr_1 : ternary;           \
    lkp.ip_dst_addr_0 : ternary;           \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.tcp_flags : ternary;             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
	lkp.drop_reason : ternary;           \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#else
#define EGRESS_IPV6_ACL_KEY              \
    /* l3 */                             \
    lkp.ip_src_addr : ternary;           \
    lkp.ip_dst_addr : ternary;           \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.tcp_flags : ternary;             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
	lkp.drop_reason : ternary;           \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#endif

#ifdef BUG_10439_WORKAROUND
#define EGRESS_IP_ACL_KEY                \
  /*lkp.mac_type : ternary;*/            \
    /* l3 */                             \
    lkp.ip_src_addr_3 : ternary;           \
    lkp.ip_src_addr_2 : ternary;           \
    lkp.ip_src_addr_1 : ternary;           \
    lkp.ip_src_addr_0 : ternary;           \
    lkp.ip_dst_addr_3 : ternary;           \
    lkp.ip_dst_addr_2 : ternary;           \
    lkp.ip_dst_addr_1 : ternary;           \
    lkp.ip_dst_addr_0 : ternary;           \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
    lkp.tcp_flags : ternary;             \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#else
#define EGRESS_IP_ACL_KEY                \
  /*lkp.mac_type : ternary;*/            \
    /* l3 */                             \
    lkp.ip_src_addr : ternary;           \
    lkp.ip_dst_addr : ternary;           \
    lkp.ip_proto : ternary;              \
    lkp.ip_tos : ternary;                \
    /* l4 */                             \
    lkp.l4_src_port : ternary;           \
    lkp.l4_dst_port : ternary;           \
    lkp.tcp_flags : ternary;             \
	/* tunnel*/                          \
    lkp.tunnel_type : ternary;           \
    lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/
#endif

//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------

#define INGRESS_ACL_ACTIONS                                                   \
                                                                              \
action NoAction_() {                                                          \
    stats.count();                                                            \
}                                                                             \
                                                                              \
action deny(                                                                  \
) {                                                                           \
    ig_md.flags.acl_deny = true;                                              \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
action permit(                                                                \
) {                                                                           \
    ig_md.flags.acl_deny = false;                                             \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
/* ------------- */                                                           \
/* Extreme Added */                                                           \
/* ------------- */                                                           \
                                                                              \
action drop (                                                                 \
    switch_drop_reason_t drop_reason                                          \
) {                                                                           \
    ig_md.flags.acl_deny = true;                                              \
                                                                              \
    ig_intr_md_for_dprsr.drop_ctl = 0x1;                                      \
                                                                              \
    ig_md.drop_reason_general = drop_reason;                                  \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
/* --------------------------------- */                                       \
                                                                              \
action redirect (                                                             \
    bit<FLOW_CLASS_WIDTH>           flow_class,                               \
	bool                            terminate,                                \
	bool                            scope                                     \
) {                                                                           \
    ig_md.flags.acl_deny = false;                                             \
                                                                              \
    /* ----- extreme ----- */                                                 \
                                                                              \
    ig_md.nsh_type1.flow_class                 = flow_class;                  \
                                                                              \
    terminate_                                 = terminate;                   \
    scope_                                     = scope;                       \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
/* --------------------------------- */                                       \

#define INGRESS_ACL_ACTIONS_2                                                 \
                                                                              \
action redirect_sfc (                                                         \
    bit<FLOW_CLASS_WIDTH>           flow_class,                               \
	bool                            terminate,                                \
	bool                            scope,                                    \
    bit<SRVC_FUNC_CHAIN_WIDTH>      sfc                                       \
) {                                                                           \
    ig_md.flags.acl_deny = false;                                             \
                                                                              \
    /* ----- extreme ----- */                                                 \
                                                                              \
    ig_md.nsh_type1.flow_class                 = flow_class;                  \
                                                                              \
    terminate_                                 = terminate;                   \
    scope_                                     = scope;                       \
                                                                              \
    ig_md.nsh_type1.sfc_is_new             = true;                            \
    ig_md.nsh_type1.sfc                    = sfc;                             \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
/* --------------------------------- */                                       \

#define INGRESS_ACL_ACTIONS_3_TOFINO_1                                        \
                                                                              \
action redirect_trunc (                                                       \
    bit<FLOW_CLASS_WIDTH>           flow_class,                               \
	bool                            terminate,                                \
	bool                            scope,                                    \
    bit<14>                         truncate_len                              \
) {                                                                           \
    ig_md.flags.acl_deny = false;                                             \
                                                                              \
    /* ----- extreme ----- */                                                 \
                                                                              \
    ig_md.nsh_type1.flow_class                 = flow_class;                  \
                                                                              \
    terminate_                                 = terminate;                   \
    scope_                                     = scope;                       \
                                                                              \
    /*ig_intr_md_for_dprsr.mtu_trunc_len = truncate_len;*/                    \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
/* --------------------------------- */                                       \
                                                                              \
action redirect_sfc_and_trunc (                                               \
    bit<FLOW_CLASS_WIDTH>           flow_class,                               \
	bool                            terminate,                                \
	bool                            scope,                                    \
    bit<SRVC_FUNC_CHAIN_WIDTH>      sfc,                                      \
    bit<14>                         truncate_len                              \
) {                                                                           \
    ig_md.flags.acl_deny = false;                                             \
                                                                              \
    /* ----- extreme ----- */                                                 \
                                                                              \
    ig_md.nsh_type1.flow_class                 = flow_class;                  \
                                                                              \
    terminate_                                 = terminate;                   \
    scope_                                     = scope;                       \
                                                                              \
    ig_md.nsh_type1.sfc_is_new             = true;                            \
    ig_md.nsh_type1.sfc                    = sfc;                             \
                                                                              \
    /*ig_intr_md_for_dprsr.mtu_trunc_len = truncate_len;*/                    \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
/* --------------------------------- */                                       \


#define INGRESS_ACL_ACTIONS_3_TOFINO_2                                        \
                                                                              \
action redirect_trunc (                                                       \
    bit<FLOW_CLASS_WIDTH>           flow_class,                               \
	bool                            terminate,                                \
	bool                            scope,                                    \
    bit<14>                         truncate_len                              \
) {                                                                           \
    ig_md.flags.acl_deny = false;                                             \
                                                                              \
    /* ----- extreme ----- */                                                 \
                                                                              \
    ig_md.nsh_type1.flow_class                 = flow_class;                  \
                                                                              \
    terminate_                                 = terminate;                   \
    scope_                                     = scope;                       \
                                                                              \
    ig_intr_md_for_dprsr.mtu_trunc_len = truncate_len;                        \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
/* --------------------------------- */                                       \
                                                                              \
action redirect_sfc_and_trunc (                                               \
    bit<FLOW_CLASS_WIDTH>           flow_class,                               \
	bool                            terminate,                                \
	bool                            scope,                                    \
    bit<SRVC_FUNC_CHAIN_WIDTH>      sfc,                                      \
    bit<14>                         truncate_len                              \
) {                                                                           \
    ig_md.flags.acl_deny = false;                                             \
                                                                              \
    /* ----- extreme ----- */                                                 \
                                                                              \
    ig_md.nsh_type1.flow_class                 = flow_class;                  \
                                                                              \
    terminate_                                 = terminate;                   \
    scope_                                     = scope;                       \
                                                                              \
    ig_md.nsh_type1.sfc_is_new             = true;                            \
    ig_md.nsh_type1.sfc                    = sfc;                             \
                                                                              \
    ig_intr_md_for_dprsr.mtu_trunc_len = truncate_len;                        \
                                                                              \
	stats.count();                                                            \
}

// ---------------------------------

/*
action redirect_decap (
    bit<FLOW_CLASS_WIDTH>           flow_class
) {
    ig_md.flags.acl_deny = false;

    // ----- extreme -----

    ig_md.nsh_type1.flow_class                 = flow_class;

    terminate = true;
    scope     = true;

	stats.count();                                                            \
}
*/

// ---------------------------------

/*
action redirect_sfc_and_decap (
    bit<FLOW_CLASS_WIDTH>           flow_class,
    bit<SRVC_FUNC_CHAIN_WIDTH>      sfc,
) {
    ig_md.flags.acl_deny = false;

    // ----- extreme -----

    ig_md.nsh_type1.flow_class                 = flow_class;

    ig_md.nsh_type1.sfc_is_new             = 1;
    ig_md.nsh_type1.sfc                    = sfc;

	terminate = true;
    scope     = true;

	stats.count();                                                            \
}

// ---------------------------------

action redirect_decap_and_trunc (
    bit<FLOW_CLASS_WIDTH>           flow_class,
    bit<14>                         truncate_len
) {
    ig_md.flags.acl_deny = false;

    // ----- extreme -----

    ig_md.nsh_type1.flow_class                 = flow_class;

	terminate = true;
    scope     = true;

#if __TARGET_TOFINO__ == 2
    ig_intr_md_for_dprsr.mtu_trunc_len = truncate_len;
#endif

	stats.count();                                                            \
}

// ---------------------------------

action redirect_sfc_and_decap_and_trunc (
    bit<FLOW_CLASS_WIDTH>           flow_class,
    bit<SRVC_FUNC_CHAIN_WIDTH>      sfc,
    bit<14>                         truncate_len
) {
    ig_md.flags.acl_deny = false;

    // ----- extreme -----

    ig_md.nsh_type1.flow_class                 = flow_class;

    ig_md.nsh_type1.sfc_is_new             = 1;
    ig_md.nsh_type1.sfc                    = sfc;

    terminate = true;
    scope     = true;

#if __TARGET_TOFINO__ == 2
    ig_intr_md_for_dprsr.mtu_trunc_len = truncate_len;
#endif

	stats.count();                                                            \
}
*/

//-----------------------------------------------------------------------------
// Common Egress ACL actions.
//-----------------------------------------------------------------------------

#define EGRESS_ACL_ACTIONS                                                    \
                                                                              \
action NoAction_() {                                                          \
    stats.count();                                                            \
}                                                                             \
                                                                              \
action deny(                                                                  \
) {                                                                           \
    eg_md.flags.acl_deny = true;                                              \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
action permit(                                                                \
) {                                                                           \
    eg_md.flags.acl_deny = false;                                             \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
/* ------------- */                                                           \
/* Extreme Added */                                                           \
/* ------------- */                                                           \
                                                                              \
action drop(                                                                  \
) {                                                                           \
    eg_md.flags.acl_deny = true;                                              \
                                                                              \
    eg_intr_md_for_dprsr.drop_ctl = 0x1;                                      \
                                                                              \
	stats.count();                                                            \
}                                                                             \
                                                                              \
action redirect(                                                              \
	bool terminate,                                                           \
    bool strip_tag_e,                                                         \
    bool strip_tag_vn,                                                        \
    bool strip_tag_vlan,                                                      \
    bool truncate,                                                            \
    bit<14> truncate_len                                                      \
) {                                                                           \
    eg_md.flags.acl_deny = false;                                             \
                                                                              \
	terminate_                     = terminate;                               \
                                                                              \
	eg_md.nsh_type1.strip_e_tag    = strip_tag_e;                             \
	eg_md.nsh_type1.strip_vn_tag   = strip_tag_vn;                            \
	eg_md.nsh_type1.strip_vlan_tag = strip_tag_vlan;                          \
	eg_md.nsh_type1.truncate       = truncate;                                \
	eg_md.nsh_type1.truncate_len   = truncate_len;                            \
                                                                              \
	stats.count();                                                            \
}                                                                             \

// ============================================================================
// ============================================================================
// Ingress ACL ================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// L7 ACL
//-----------------------------------------------------------------------------

control IngressL7Acl(
    in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool scope_,
	inout bool hit,
	in    bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    INGRESS_ACL_ACTIONS
    INGRESS_ACL_ACTIONS_2
#if __TARGET_TOFINO__ == 2 
    INGRESS_ACL_ACTIONS_3_TOFINO_2
#else
    INGRESS_ACL_ACTIONS_3_TOFINO_1
#endif

    table acl {
        key = {
            INGRESS_L7_ACL_KEY

            // extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                    : ternary;
#endif
            hdr.nsh_type1.sap                    : ternary @name("sap");
            ig_md.nsh_type1.flow_class           : ternary;
#ifdef SF_0_LEN_RNG_TABLE_ENABLE
//          length_bitmask                       : ternary;
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

			// extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }

        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control IngressIpAcl(
    in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool scope_,
	inout bool hit,
	in    bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    INGRESS_ACL_ACTIONS
    INGRESS_ACL_ACTIONS_2
#if __TARGET_TOFINO__ == 2 
    INGRESS_ACL_ACTIONS_3_TOFINO_2
#else
    INGRESS_ACL_ACTIONS_3_TOFINO_1
#endif

    table acl {
        key = {
            INGRESS_IP_ACL_KEY

            // extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                  : ternary;
#endif
            hdr.nsh_type1.sap                  : ternary @name("sap");
//          hdr.nsh_type1.flow_class           : ternary @name("flow_class");
#ifdef SF_0_LEN_RNG_TABLE_ENABLE
            length_bitmask                     : ternary;
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

			// extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }

        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}

//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control IngressIpv4Acl(
    in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool scope_,
	inout bool hit,
	in    bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    INGRESS_ACL_ACTIONS
    INGRESS_ACL_ACTIONS_2
#if __TARGET_TOFINO__ == 2 
    INGRESS_ACL_ACTIONS_3_TOFINO_2
#else
    INGRESS_ACL_ACTIONS_3_TOFINO_1
#endif

    table acl {
        key = {
            INGRESS_IPV4_ACL_KEY

			// extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                  : ternary;
#endif
            hdr.nsh_type1.sap                  : ternary @name("sap");
//          hdr.nsh_type1.flow_class           : ternary @name("flow_class");
#ifdef SF_0_LEN_RNG_TABLE_ENABLE
            length_bitmask                     : ternary;
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

			// extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }
        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------

#ifdef IPV6_ENABLE

control IngressIpv6Acl(
    in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool scope_,
	inout bool hit,
	in    bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    INGRESS_ACL_ACTIONS
    INGRESS_ACL_ACTIONS_2
#if __TARGET_TOFINO__ == 2 
    INGRESS_ACL_ACTIONS_3_TOFINO_2
#else
    INGRESS_ACL_ACTIONS_3_TOFINO_1
#endif

    table acl {
        key = {
            INGRESS_IPV6_ACL_KEY

            // extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                  : ternary;
#endif
            hdr.nsh_type1.sap                  : ternary @name("sap");
//          hdr.nsh_type1.flow_class           : ternary @name("flow_class");
#ifdef SF_0_LEN_RNG_TABLE_ENABLE
            length_bitmask                     : ternary;
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

			// extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }

        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}

#endif

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control IngressMacAcl(
    in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool scope_,
	inout bool hit,
	in    bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    INGRESS_ACL_ACTIONS
    INGRESS_ACL_ACTIONS_2
#if __TARGET_TOFINO__ == 2 
    INGRESS_ACL_ACTIONS_3_TOFINO_2
#else
    INGRESS_ACL_ACTIONS_3_TOFINO_1
#endif

    table acl {
        key = {
            INGRESS_MAC_ACL_KEY

            // extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                  : ternary;
#endif
            hdr.nsh_type1.sap                  : ternary @name("sap");
//          hdr.nsh_type1.flow_class           : ternary @name("flow_class");
#ifdef SF_0_LEN_RNG_TABLE_ENABLE
//          length_bitmask                     : ternary;
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

			// extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }

        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}

// ----------------------------------------------------------------------------
// Ingress Access Control List (ACL)
//
// @param lkp : Lookup fields used for lookups.
// @param ig_md : Ingress metadata.
// @param mac_acl_enable : Add a ACL slice for L2 traffic. If mac_acl_enable is false, IPv4 ACL is
// applied to IPv4 and non-IP traffic.
// @param mac_packet_class_enable : Controls whether MAC ACL applies to all traffic entering the
// interface, including IP traffic, or to non-IP traffic only.
// ----------------------------------------------------------------------------

control IngressAcl(
    inout switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	in    bit<16> length_bitmask,
    inout switch_header_transport_t hdr_0,
    inout switch_header_inner_t hdr_2,
	in    bit<16> int_ctrl_flags
) (
#if defined(SF_0_ACL_SHARED_IP_ENABLE)
    switch_uint32_t ip_table_size=512,
#else
    switch_uint32_t ipv4_table_size=512,
    switch_uint32_t ipv6_table_size=512,
#endif /* SF_0_ACL_SHARED_IP_ENABLE */
    switch_uint32_t mac_table_size=512,
    switch_uint32_t l7_table_size=512
) {

	// ---------------------------------------------------

#if defined(SF_0_ACL_SHARED_IP_ENABLE)
    IngressIpAcl(ip_table_size) ip_acl;
#else
    IngressIpv4Acl(ipv4_table_size) ipv4_acl;
#ifdef IPV6_ENABLE
    IngressIpv6Acl(ipv6_table_size) ipv6_acl;
#endif // IPV6_ENABLE
#endif /* SF_0_ACL_SHARED_IP_ENABLE */
    IngressMacAcl(mac_table_size) mac_acl;
#ifdef UDF_ENABLE
    IngressL7Acl(l7_table_size) l7_acl;
#endif

    switch_nexthop_t nexthop;
	bool terminate;
    bool scope;
	bool hit;

    // -------------------------------------
    // Table: Scope Increment
    // -------------------------------------
/*
    action new_scope(bit<8> scope_new) {
        hdr_0.nsh_type1.scope = scope_new;
    }

    table scope_inc {
        key = {
            hdr_0.nsh_type1.scope : exact;
        }
        actions = {
            new_scope;
        }
        const entries = {
            0  : new_scope(1);
            1  : new_scope(2);
            2  : new_scope(3);
        }
    }
*/
	// ---------------------------------------------------

    apply {
        ig_md.flags.acl_deny = false;
        nexthop = 0;
        terminate = false;
        scope = false;
		hit = false;

		// ----- l7 -----
#ifdef UDF_ENABLE
        l7_acl.apply(lkp, hdr_0, ig_md, ig_intr_md_for_dprsr, nexthop, length_bitmask, terminate, scope, hit, int_ctrl_flags);
#endif // UDF_ENABLE

		// ----- l3/4 -----
		if(hit == false) {
#if defined(SF_0_ACL_SHARED_IP_ENABLE)
	        if (lkp.ip_type != SWITCH_IP_TYPE_NONE) {
	            ip_acl.apply(lkp, hdr_0, ig_md, ig_intr_md_for_dprsr, nexthop, length_bitmask, terminate, scope, hit, int_ctrl_flags);
	        }
#else
	        if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
  #ifdef IPV6_ENABLE
	            ipv6_acl.apply(lkp, hdr_0, ig_md, ig_intr_md_for_dprsr, nexthop, length_bitmask, terminate, scope, hit, int_ctrl_flags);
  #endif // IPV6_ENABLE
	        } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
	            ipv4_acl.apply(lkp, hdr_0, ig_md, ig_intr_md_for_dprsr, nexthop, length_bitmask, terminate, scope, hit, int_ctrl_flags);
	        }
#endif /* SF_0_ACL_SHARED_IP_ENABLE */
		}

		// ----- l2 -----
		if(hit == false) {
	        mac_acl.apply(lkp, hdr_0, ig_md, ig_intr_md_for_dprsr, nexthop, length_bitmask, terminate, scope, hit, int_ctrl_flags);
		}

		// --------------

		// note: terminate + !scope is an illegal condition
		if(terminate == true) {
		    ig_md.tunnel_1.terminate           = true;
			if(hdr_0.nsh_type1.scope == 1) {
			    ig_md.tunnel_2.terminate           = true;
			}
		}

		if(scope == true) {
			if(hdr_0.nsh_type1.scope == 0) {
/*
		        ScoperInner.apply(
		            hdr_2.ethernet,
		            hdr_2.vlan_tag[0],
		            hdr_2.ipv4,
#ifdef IPV6_ENABLE
		            hdr_2.ipv6,
#endif // IPV6_ENABLE
		            hdr_2.tcp,
		            hdr_2.udp,
		            hdr_2.sctp,
		            ig_md.tunnel_2.type,
		            ig_md.tunnel_2.id,
					ig_md.drop_reason_2,

		            ig_md.lkp
		        );
*/
		        ScoperIngress.apply(
		            ig_md.lkp_2,
					ig_md.drop_reason_2,

		            ig_md.lkp
				);
			}

			hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
//			scope_inc.apply();
		}
    }
}

// ============================================================================
// ============================================================================
// Egress ACL =================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control EgressMacAcl(
    in    switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool hit
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    EGRESS_ACL_ACTIONS

    table acl {
        key = {
//          hdr.ethernet.src_addr : ternary;
//          hdr.ethernet.dst_addr : ternary;
//          hdr.ethernet.ether_type : ternary;
#ifdef SF_2_ACL_MAC_KEY_ENABLE
			EGRESS_MAC_ACL_KEY
#endif

			// extreme added
			eg_md.nsh_type1.dsap    : ternary @name("dsap");
#ifdef SF_2_LEN_RNG_TABLE_ENABLE
//			length_bitmask          : ternary;
#endif

#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_tunnel_outer_type : ternary @name("tunnel_outer_type");
			eg_md.lkp_tunnel_inner_type : ternary @name("tunnel_inner_type");
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();

            drop();
            redirect();
        }

        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control EgressIpAcl(
    in    switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool hit
)(
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    EGRESS_ACL_ACTIONS

    table acl {
        key = {
            EGRESS_IP_ACL_KEY

			// extreme added
			eg_md.nsh_type1.dsap    : ternary @name("dsap");
#ifdef SF_2_LEN_RNG_TABLE_ENABLE
			length_bitmask          : ternary;
#endif

#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_tunnel_outer_type : ternary @name("tunnel_outer_type");
			eg_md.lkp_tunnel_inner_type : ternary @name("tunnel_inner_type");
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();

            drop();
            redirect();
        }

        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}
//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control EgressIpv4Acl(
    in    switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool hit
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    EGRESS_ACL_ACTIONS

    table acl {
        key = {
            EGRESS_IPV4_ACL_KEY
//          hdr.ethernet.ether_type : ternary;

			// extreme added
			eg_md.nsh_type1.dsap    : ternary @name("dsap");
#ifdef SF_2_LEN_RNG_TABLE_ENABLE
			length_bitmask          : ternary;
#endif

#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_tunnel_outer_type : ternary @name("tunnel_outer_type");
			eg_md.lkp_tunnel_inner_type : ternary @name("tunnel_inner_type");
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();
            drop();
            redirect();
        }

        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------

#ifdef IPV6_ENABLE

control EgressIpv6Acl(
    in    switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in    bit<16> length_bitmask,
	inout bool terminate_,
	inout bool hit
)(
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    EGRESS_ACL_ACTIONS

    table acl {
        key = {
            EGRESS_IPV6_ACL_KEY

			// extreme added
			eg_md.nsh_type1.dsap    : ternary @name("dsap");
#ifdef SF_2_LEN_RNG_TABLE_ENABLE
			length_bitmask          : ternary;
#endif

#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_tunnel_outer_type : ternary @name("tunnel_outer_type");
			eg_md.lkp_tunnel_inner_type : ternary @name("tunnel_inner_type");
#endif
        }

        actions = {
            NoAction_;
//          deny();
            permit();

            drop();
            redirect();
        }

        const default_action = NoAction_;
		counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
			hit = true;
		}
    }
}

#endif

//-----------------------------------------------------------------------------

control EgressAcl(
    in      switch_lookup_fields_t lkp,
    inout   switch_egress_metadata_t eg_md,
    inout   egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in      bit<16> length_bitmask,
    inout switch_header_transport_t hdr_0
) (
#if defined(SF_2_ACL_SHARED_IP_ENABLE)
    switch_uint32_t ip_table_size=512,
#else
    switch_uint32_t ipv4_table_size=512,
    switch_uint32_t ipv6_table_size=512,
#endif
    switch_uint32_t mac_table_size=512
) {

	// ---------------------------------------------------

#if defined(SF_2_ACL_SHARED_IP_ENABLE)
    EgressIpAcl(ip_table_size) egress_ip_acl;
#else
    EgressIpv4Acl(ipv4_table_size) egress_ipv4_acl;
#ifdef IPV6_ENABLE
    EgressIpv6Acl(ipv6_table_size) egress_ipv6_acl;
#endif // IPV6_ENABLE
#endif
#ifdef SF_2_ACL_MAC_KEY_ENABLE
    EgressMacAcl(mac_table_size) egress_mac_acl;
#endif

	bool terminate;
	bool hit;

	// ---------------------------------------------------

    apply {
        eg_md.flags.acl_deny = false;
        terminate = false;
		hit = false;

		// ----- l3/4 -----
#if defined(SF_2_ACL_SHARED_IP_ENABLE)
        if (lkp.ip_type != SWITCH_IP_TYPE_NONE) {
            egress_ip_acl.apply(lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask, terminate, hit);
        }
#else
        if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
  #ifdef IPV6_ENABLE
            egress_ipv6_acl.apply(lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask, terminate, hit);
  #endif // IPV6_ENABLE
        } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            egress_ipv4_acl.apply(lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask, terminate, hit);
        }
#endif

		// ----- l2 -----
		if(hit == false) {
#ifdef SF_2_ACL_MAC_KEY_ENABLE
	        egress_mac_acl.apply(lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask, terminate, hit);
#endif
		}

		// --------------

		// note: terminate + !scope is an illegal condition
		if(terminate == true) {
		    eg_md.tunnel_1.terminate           = true;
			if(hdr_0.nsh_type1.scope == 1) {
			    eg_md.tunnel_2.terminate           = true;
			}
		}

		// note: don't need to adjust scope here, as nobody else looks at the data after this.
    }
}

#endif /* _P4_ACL_ */
