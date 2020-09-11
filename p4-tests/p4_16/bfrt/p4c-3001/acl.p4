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
	/* tunnel */                         \
	lkp.tunnel_type : ternary;           \
	lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/

#define INGRESS_IP_ACL_COMMON_KEY        \
	/* l3 */                             \
	lkp.ip_proto : ternary;              \
	lkp.ip_tos : ternary;                \
	/* l4 */                             \
/*	lkp.l4_src_port : ternary; */        \
/*	lkp.l4_dst_port : ternary; */        \
	lkp.tcp_flags : ternary;             \

#define INGRESS_IPV4_ACL_KEY             \
	/* l3 */                             \
	lkp.ip_src_addr[31:0] : ternary;     \
	lkp.ip_dst_addr[31:0] : ternary;     \
	lkp.ip_flags : ternary;              \
  /*lkp.ip_frag : ternary;*/             \
	/* l4 */                             \
	/* tunnel */                         \
	lkp.tunnel_type : ternary;           \
	lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/       \
	INGRESS_IP_ACL_COMMON_KEY

#define INGRESS_IPV6_ACL_KEY             \
	/* l3 */                             \
	lkp.ip_src_addr : ternary;           \
	lkp.ip_dst_addr : ternary;           \
	/* l4 */                             \
	/* tunnel */                         \
	lkp.tunnel_type : ternary;           \
	lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/       \
	INGRESS_IP_ACL_COMMON_KEY

#define INGRESS_IP_ACL_KEY               \
	/* l3 */                             \
	lkp.ip_src_addr : ternary;           \
	lkp.ip_dst_addr : ternary;           \
	lkp.ip_flags : ternary;              \
  /*lkp.ip_frag : ternary;*/             \
	/* l4 */                             \
	/* tunnel */                         \
	lkp.tunnel_type : ternary;           \
	lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/       \
	INGRESS_IP_ACL_COMMON_KEY

#ifdef UDF_ENABLE

#define INGRESS_L7_ACL_KEY               \
	hdr_udf.opaque : ternary;            \
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
	lkp.pcp : ternary;                   \
	/* tunnel */                         \
	lkp.tunnel_type : ternary;           \
	lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/

#define EGRESS_IPV4_ACL_KEY              \
	/* l3 */                             \
	lkp.ip_src_addr[31:0] : ternary;     \
	lkp.ip_dst_addr[31:0] : ternary;     \
	lkp.ip_proto : ternary;              \
	lkp.ip_tos : ternary;                \
	lkp.ip_flags : ternary;              \
	/* l4 */                             \
	lkp.tcp_flags : ternary;             \
/*	lkp.l4_src_port : ternary; */        \
/*	lkp.l4_dst_port : ternary; */        \
	/* tunnel */                         \
	lkp.tunnel_type : ternary;           \
	lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/

#define EGRESS_IPV6_ACL_KEY              \
	/* l3 */                             \
	lkp.ip_src_addr : ternary;           \
	lkp.ip_dst_addr : ternary;           \
	lkp.ip_proto : ternary;              \
	lkp.ip_tos : ternary;                \
	/* l4 */                             \
	lkp.tcp_flags : ternary;             \
/*	lkp.l4_src_port : ternary; */        \
/*	lkp.l4_dst_port : ternary; */        \
	/* tunnel */                         \
	lkp.tunnel_type : ternary;           \
	lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/

#define EGRESS_IP_ACL_KEY                \
	/* l3 */                             \
	lkp.ip_src_addr : ternary;           \
	lkp.ip_dst_addr : ternary;           \
	lkp.ip_proto : ternary;              \
	lkp.ip_tos : ternary;                \
	lkp.ip_flags : ternary;              \
	/* l4 */                             \
/*	lkp.l4_src_port : ternary; */        \
/*	lkp.l4_dst_port : ternary; */        \
	lkp.tcp_flags : ternary;             \
	/* tunnel */                         \
	lkp.tunnel_type : ternary;           \
	lkp.tunnel_id : ternary;             \
	/* misc */                           \
	/*lkp.drop_reason : ternary;*/

//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------

#define INGRESS_ACL_ACTIONS                                                   \
			                                                                  \
action NoAction_() {                                                          \
	stats.count();                                                            \
}                                                                             \
			                                                                  \
/* --------------------------------- */                                       \
			                                                                  \
action hit (                                                                  \
/*	bit<3> drop, */                                                           \
	bool drop,                                                                \
			                                                                  \
	bool terminate,                                                           \
	bool scope,                                                               \
	bool truncate_enable,                                                     \
	bit<14> truncate_len,                                                     \
	bool sfc_enable,                                                          \
	bit<SF_SRVC_FUNC_CHAIN_WIDTH> sfc,                                        \
	bit<SF_FLOW_CLASS_WIDTH_A> flow_class,                                    \
	bool copy_to_cpu,                                                         \
	bool redirect_to_cpu,                                                     \
	switch_cpu_reason_t cpu_reason_code,                                      \
	switch_copp_meter_id_t copp_meter_id                                      \
) {                                                                           \
/*	ig_intr_md_for_dprsr.drop_ctl = drop; */                                  \
	drop_                       = drop;                                       \
			                                                                  \
	terminate_                  = terminate;                                  \
	scope_                      = scope;                                      \
	ig_md.nsh_md.truncate_enable= truncate_enable;                            \
	ig_md.nsh_md.truncate_len   = truncate_len;                               \
	ig_md.nsh_md.sfc_enable     = sfc_enable;                                 \
	ig_md.nsh_md.sfc            = sfc;                                        \
	flow_class_                 = flow_class;                                 \
			                                                                  \
	copy_to_cpu_                = copy_to_cpu;                                \
	redirect_to_cpu_            = redirect_to_cpu;                            \
	cpu_reason_                 = cpu_reason_code;                            \
	copp_meter_id_              = copp_meter_id;                              \
			                                                                  \
	stats.count();                                                            \
}

//-----------------------------------------------------------------------------
// Common Egress ACL actions.
//-----------------------------------------------------------------------------

#define EGRESS_ACL_ACTIONS                                                    \
			                                                                  \
action NoAction_() {                                                          \
	stats.count();                                                            \
}                                                                             \
			                                                                  \
/* --------------------------------- */                                       \
			                                                                  \
action hit(                                                                   \
/*	bit<3> drop, */                                                           \
	bool drop,                                                                \
			                                                                  \
	bool terminate,                                                           \
	bool strip_tag_e,                                                         \
	bool strip_tag_vn,                                                        \
	bool strip_tag_vlan,                                                      \
	bit<SF_L2_EDIT_BD_PTR_WIDTH> add_tag_vlan_bd,                             \
	bool truncate_enable,                                                     \
	bit<14> truncate_len,                                                     \
	bool terminate_outer,                                                     \
	bool terminate_inner,                                                     \
	bool copy_to_cpu,                                                         \
	bool redirect_to_cpu,                                                     \
	switch_cpu_reason_t cpu_reason_code,                                      \
	switch_copp_meter_id_t copp_meter_id                                      \
) {                                                                           \
/*	eg_intr_md_for_dprsr.drop_ctl = drop; */                                  \
	drop_                       = drop;                                       \
			                                                                  \
	terminate_                  = terminate;                                  \
			                                                                  \
	eg_md.nsh_md.strip_e_tag    = strip_tag_e;                                \
	eg_md.nsh_md.strip_vn_tag   = strip_tag_vn;                               \
	eg_md.nsh_md.strip_vlan_tag = strip_tag_vlan;                             \
	eg_md.nsh_md.add_vlan_tag_bd= add_tag_vlan_bd;                            \
	eg_md.nsh_md.truncate_enable= truncate_enable;                            \
	eg_md.nsh_md.truncate_len   = truncate_len;                               \
	eg_md.nsh_md.terminate_outer= terminate_outer;                            \
	eg_md.nsh_md.terminate_inner= terminate_inner;                            \
			                                                                  \
	copy_to_cpu_                = copy_to_cpu;                                \
	redirect_to_cpu_            = redirect_to_cpu;                            \
	cpu_reason_                 = cpu_reason_code;                            \
	copp_meter_id_              = copp_meter_id;                              \
			                                                                  \
	stats.count();                                                            \
}                                                                             \

// ============================================================================
// ============================================================================
// Ingress ACL ================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control IngressMacAcl(
	in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
	in    switch_header_outer_t hdr_1,
	inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout switch_nexthop_t nexthop_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	INGRESS_ACL_ACTIONS

	table acl {
		key = {
			INGRESS_MAC_ACL_KEY

			// extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			hdr.nsh_type1.sap                      : ternary @name("sap");
			// -------------------------------------------
#ifdef SF_0_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
//			hdr_1.e_tag.isValid()                  : ternary @name("hdr.e_tag.$valid");
//			hdr_1.vn_tag.isValid()                 : ternary @name("hdr.vn_tag.$valid");
		}

		actions = {
			NoAction_;
			hit();
		}

		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		acl.apply();
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
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout switch_nexthop_t nexthop_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	INGRESS_ACL_ACTIONS

	table acl {
		key = {
			INGRESS_IP_ACL_KEY
			lkp.mac_type : ternary;

			// extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			hdr.nsh_type1.sap                      : ternary @name("sap");
			// -------------------------------------------
#ifdef SF_0_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
			ip_len                                 : ternary @name("lkp.ip_len");
			ip_len_is_rng_bitmask                  : ternary @name("lkp.ip_len_is_rng_bitmask");
#else
  #ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len");
  #else
			lkp.ip_len                             : ternary @name("lkp.ip_len");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port                            : ternary @name("lkp.l4_src_port");
			l4_src_port_is_rng_bitmask             : ternary @name("lkp.l4_src_port_is_rng_bitmask");
#else
  #ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port");
  #else
			lkp.l4_src_port                        : ternary @name("lkp.l4_src_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
			l4_dst_port_is_rng_bitmask             : ternary @name("lkp.l4_dst_port_is_rng_bitmask");
#else
  #ifdef SF_0_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port");
  #else
			lkp.l4_dst_port                        : ternary @name("lkp.l4_dst_port");
  #endif
#endif
		}

		actions = {
			NoAction_;
			hit();
		}

		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		acl.apply();
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
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout switch_nexthop_t nexthop_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	INGRESS_ACL_ACTIONS

	table acl {
		key = {
			INGRESS_IPV4_ACL_KEY
#ifdef ETYPE_IN_IP_ACL_KEY_ENABLE
			lkp.mac_type : ternary;
#endif

			// extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			hdr.nsh_type1.sap                      : ternary @name("sap");
			// -------------------------------------------
#ifdef SF_0_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
			ip_len                                 : ternary @name("lkp.ip_len");
			ip_len_is_rng_bitmask                  : ternary @name("lkp.ip_len_is_rng_bitmask");
#else
  #ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len");
  #else
			lkp.ip_len                             : ternary @name("lkp.ip_len");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port                            : ternary @name("lkp.l4_src_port");
			l4_src_port_is_rng_bitmask             : ternary @name("lkp.l4_src_port_is_rng_bitmask");
#else
  #ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port");
  #else
			lkp.l4_src_port                        : ternary @name("lkp.l4_src_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
			l4_dst_port_is_rng_bitmask             : ternary @name("lkp.l4_dst_port_is_rng_bitmask");
#else
  #ifdef SF_0_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port");
  #else
			lkp.l4_dst_port                        : ternary @name("lkp.l4_dst_port");
  #endif
#endif
		}

		actions = {
			NoAction_;
			hit();
		}
		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		acl.apply();
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
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout switch_nexthop_t nexthop_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	INGRESS_ACL_ACTIONS

	table acl {
		key = {
			INGRESS_IPV6_ACL_KEY
#ifdef ETYPE_IN_IP_ACL_KEY_ENABLE
			lkp.mac_type : ternary;
#endif

			// extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			hdr.nsh_type1.sap                      : ternary @name("sap");
			// -------------------------------------------
#ifdef SF_0_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
			ip_len                                 : ternary @name("lkp.ip_len");
			ip_len_is_rng_bitmask                  : ternary @name("lkp.ip_len_is_rng_bitmask");
#else
  #ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len");
  #else
			lkp.ip_len                             : ternary @name("lkp.ip_len");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port                            : ternary @name("lkp.l4_src_port");
			l4_src_port_is_rng_bitmask             : ternary @name("lkp.l4_src_port_is_rng_bitmask");
#else
  #ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port");
  #else
			lkp.l4_src_port                        : ternary @name("lkp.l4_src_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
			l4_dst_port_is_rng_bitmask             : ternary @name("lkp.l4_dst_port_is_rng_bitmask");
#else
  #ifdef SF_0_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port");
  #else
			lkp.l4_dst_port                        : ternary @name("lkp.l4_dst_port");
  #endif
#endif
		}

		actions = {
			NoAction_;
			hit();
		}

		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		acl.apply();
	}
}

#endif

//-----------------------------------------------------------------------------
// L7 ACL
//-----------------------------------------------------------------------------

control IngressL7Acl(
	in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
	in    udf_h hdr_udf,
	inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout switch_nexthop_t nexthop_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	INGRESS_ACL_ACTIONS

	table acl {
		key = {
			INGRESS_L7_ACL_KEY

			// extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			hdr.nsh_type1.sap                      : ternary @name("sap");
			// -------------------------------------------
			flow_class_                            : ternary @name("flow_class");
		}

		actions = {
			NoAction_;
			hit();
		}

		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		acl.apply();
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
	inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	inout switch_header_transport_t hdr_0,
	in    switch_header_outer_t     hdr_1,
	in    switch_header_inner_t     hdr_2,
	in    udf_h hdr_udf,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags
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
	bool drop;
	bool terminate;
	bool scope;
	switch_cpu_reason_t cpu_reason;
	bool copy_to_cpu;
	bool redirect_to_cpu;
	switch_copp_meter_id_t copp_meter_id;
	bit<SF_FLOW_CLASS_WIDTH_A> flow_class;

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

	// -------------------------------------
	// Table: COPP
	// -------------------------------------
#ifdef CPU_ACL_INGRESS_ENABLE
	action copy_to_cpu_process_results(in switch_cpu_reason_t cpu_reason_, in switch_copp_meter_id_t copp_meter_id_) {
		ig_intr_md_for_tm.copy_to_cpu = 1w1;
		ig_md.cpu_reason = cpu_reason_;
	}
#endif // CPU_ACL_INGRESS_ENABLE
	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
		nexthop = 0;
		drop = false;
		terminate = false;
		scope = false;
		copy_to_cpu = false;
		redirect_to_cpu = false;
		cpu_reason = 0;
//		copp_meter_id = 0; // TODO: this may be data and therefore not need to be initialized
		flow_class = 0;

		ig_md.nsh_md.truncate_enable = false;
		ig_md.nsh_md.sfc_enable = false;

		// --------------
		// tables
		// --------------

		// Derek: The way this works is that the "hit" action of each table MUST write ALL of the outputs.  This is so that we don't
		// end up with partial results from one table and partial results from another in the final result.  So it is very import
		// that all "hit" actions write ALL of the outputs.

		// ----- l2 -----
		mac_acl.apply(
			lkp,
			hdr_0,
			hdr_1,
			ig_md,
			ig_intr_md_for_dprsr,
			ip_len, ip_len_is_rng_bitmask,
			l4_src_port, l4_src_port_is_rng_bitmask,
			l4_dst_port, l4_dst_port_is_rng_bitmask,
			int_ctrl_flags,
			// ----- results -----
			nexthop,
			drop,
			terminate,
			scope,
			copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
		);

		// ----- l3/4 -----
#if defined(SF_0_ACL_SHARED_IP_ENABLE)
		if (lkp.ip_type != SWITCH_IP_TYPE_NONE) {
			ip_acl.apply(
				lkp,
				hdr_0,
				ig_md,
				ig_intr_md_for_dprsr,
				ip_len, ip_len_is_rng_bitmask,
				l4_src_port, l4_src_port_is_rng_bitmask,
				l4_dst_port, l4_dst_port_is_rng_bitmask,
				int_ctrl_flags,
				// ----- results -----
				nexthop,
				drop,
				terminate,
				scope,
				copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
			);
		}
#else
		if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
  #ifdef IPV6_ENABLE
			ipv6_acl.apply(
				lkp,
				hdr_0,
				ig_md,
				ig_intr_md_for_dprsr,
				ip_len, ip_len_is_rng_bitmask,
				l4_src_port, l4_src_port_is_rng_bitmask,
				l4_dst_port, l4_dst_port_is_rng_bitmask,
				int_ctrl_flags,
				// ----- results -----
				nexthop,
				drop,
				terminate,
				scope,
				copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
			);
  #endif // IPV6_ENABLE
		} else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
			ipv4_acl.apply(
				lkp,
				hdr_0,
				ig_md,
				ig_intr_md_for_dprsr,
				ip_len, ip_len_is_rng_bitmask,
				l4_src_port, l4_src_port_is_rng_bitmask,
				l4_dst_port, l4_dst_port_is_rng_bitmask,
				int_ctrl_flags,
				// ----- results -----
				nexthop,
				drop,
				terminate,
				scope,
				copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
			);
		}
#endif /* SF_0_ACL_SHARED_IP_ENABLE */

		// ----- l7 -----
#ifdef UDF_ENABLE
		if (hdr_udf.isValid()) {
			l7_acl.apply(
				lkp,
				hdr_0,
				hdr_udf,
				ig_md,
				ig_intr_md_for_dprsr,
				ip_len, ip_len_is_rng_bitmask,
				l4_src_port, l4_src_port_is_rng_bitmask,
				l4_dst_port, l4_dst_port_is_rng_bitmask,
				int_ctrl_flags,
				// ----- results -----
				nexthop,
				drop,
				terminate,
				scope,
				copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class
			);
		}
#endif // UDF_ENABLE

		// --------------
		// results
		// --------------

		// ----- drop -----

		if(drop == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0x1;
		}

		// note: terminate + !scope is an illegal condition

		// ----- terminate -----

		if(terminate == true) {
			ig_md.tunnel_1.terminate           = true;
			if(hdr_0.nsh_type1.scope == 1) {
				ig_md.tunnel_2.terminate           = true;
			}
		}

		// ----- scope -----

#ifdef SF_0_ALLOW_SCOPE_CHANGES
		if(scope == true) {
			if(hdr_0.nsh_type1.scope == 0) {

				// note: don't need to do a full scope change here,
				// as nobody else looks at all the data after this
				// (only the hash of the data is looked at).
/*
//  #ifdef INGRESS_PARSER_POPULATES_LKP_2
				Scoper.apply(
					ig_md.lkp_2,
					ig_md.drop_reason_2,

					ig_md.lkp
				);
//  #else
//				ScoperInner.apply(
//					hdr_2,
//					ig_md.tunnel_2,
//					ig_md.drop_reason_2,
//
//					ig_md.lkp
//				);
//  #endif
*/
//				ig_md.nsh_md.hash_1 = ig_md.nsh_md.hash_2;
			}

			hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
//			scope_inc.apply();
		}
#endif

		// ----- truncate -----

		if(ig_md.nsh_md.truncate_enable) {
#if __TARGET_TOFINO__ == 2
			ig_intr_md_for_dprsr.mtu_trunc_len = ig_md.nsh_md.truncate_len;
#endif
		}

		// ----- copy to cpu -----
#ifdef CPU_ACL_INGRESS_ENABLE
		if(copy_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason, copp_meter_id);
		} else if(redirect_to_cpu == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0b1;
			copy_to_cpu_process_results(cpu_reason, copp_meter_id);
		}

		ig_md.copp_enable = copy_to_cpu;
		ig_md.copp_meter_id = copp_meter_id;
#endif // CPU_ACL_INGRESS_ENABLE
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
	in    switch_header_outer_t hdr_1,
	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool drop_,
	inout bool terminate_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	EGRESS_ACL_ACTIONS

	table acl {
		key = {
			EGRESS_MAC_ACL_KEY

			// extreme added
#ifdef SF_2_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			eg_md.nsh_md.dsap                      : ternary @name("dsap");
			// -------------------------------------------
#ifdef SF_2_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_1.tunnel_outer_type          : ternary @name("tunnel_outer_type");
			eg_md.lkp_1.tunnel_inner_type          : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");
#endif
			// -------------------------------------------
//			hdr_1.e_tag.isValid()                  : ternary @name("hdr.e_tag.$valid");
//			hdr_1.vn_tag.isValid()                 : ternary @name("hdr.vn_tag.$valid");
		}

		actions = {
			NoAction_;
			hit();
		}

		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		if (!EGRESS_BYPASS(ACL)) {
			acl.apply();
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
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool drop_,
	inout bool terminate_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_
)(
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	EGRESS_ACL_ACTIONS

	table acl {
		key = {
			EGRESS_IP_ACL_KEY
			lkp.mac_type : ternary;

			// extreme added
#ifdef SF_2_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			eg_md.nsh_md.dsap                      : ternary @name("dsap");
			// -------------------------------------------
#ifdef SF_2_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
#ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE
			ip_len                                 : ternary @name("lkp.ip_len");
			ip_len_is_rng_bitmask                  : ternary @name("lkp.ip_len_is_rng_bitmask");
#else
  #ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len");
  #else
			lkp.ip_len                             : ternary @name("lkp.ip_len");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port                            : ternary @name("lkp.l4_src_port");
			l4_src_port_is_rng_bitmask             : ternary @name("lkp.l4_src_port_is_rng_bitmask");
#else
  #ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port");
  #else
			lkp.l4_src_port                        : ternary @name("lkp.l4_src_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
			l4_dst_port_is_rng_bitmask             : ternary @name("lkp.l4_dst_port_is_rng_bitmask");
#else
  #ifdef SF_2_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port");
  #else
			lkp.l4_dst_port                        : ternary @name("lkp.l4_dst_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_1.tunnel_outer_type          : ternary @name("tunnel_outer_type");
			eg_md.lkp_1.tunnel_inner_type          : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");
#endif
		}

		actions = {
			NoAction_;
			hit();
		}

		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		if (!EGRESS_BYPASS(ACL)) {
			acl.apply();
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
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool drop_,
	inout bool terminate_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	EGRESS_ACL_ACTIONS

	table acl {
		key = {
			EGRESS_IPV4_ACL_KEY
#ifdef ETYPE_IN_IP_ACL_KEY_ENABLE
			lkp.mac_type : ternary;
#endif

			// extreme added
#ifdef SF_2_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			eg_md.nsh_md.dsap                      : ternary @name("dsap");
			// -------------------------------------------
#ifdef SF_2_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
#ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE
			ip_len                                 : ternary @name("lkp.ip_len");
			ip_len_is_rng_bitmask                  : ternary @name("lkp.ip_len_is_rng_bitmask");
#else
  #ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len");
  #else
			lkp.ip_len                             : ternary @name("lkp.ip_len");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port                            : ternary @name("lkp.l4_src_port");
			l4_src_port_is_rng_bitmask             : ternary @name("lkp.l4_src_port_is_rng_bitmask");
#else
  #ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port");
  #else
			lkp.l4_src_port                        : ternary @name("lkp.l4_src_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
			l4_dst_port_is_rng_bitmask             : ternary @name("lkp.l4_dst_port_is_rng_bitmask");
#else
  #ifdef SF_2_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port");
  #else
			lkp.l4_dst_port                        : ternary @name("lkp.l4_dst_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_1.tunnel_outer_type          : ternary @name("tunnel_outer_type");
			eg_md.lkp_1.tunnel_inner_type          : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");
#endif
		}

		actions = {
			NoAction_;
			hit();
		}

		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		if (!EGRESS_BYPASS(ACL)) {
			acl.apply();
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
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool drop_,
	inout bool terminate_,
	inout bool copy_to_cpu_,
	inout bool redirect_to_cpu_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_copp_meter_id_t copp_meter_id_
)(
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	EGRESS_ACL_ACTIONS

	table acl {
		key = {
			EGRESS_IPV6_ACL_KEY
#ifdef ETYPE_IN_IP_ACL_KEY_ENABLE
			lkp.mac_type : ternary;
#endif

			// extreme added
#ifdef SF_2_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			eg_md.nsh_md.dsap                      : ternary @name("dsap");
			// -------------------------------------------
#ifdef SF_2_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
#ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE
			ip_len                                 : ternary @name("lkp.ip_len");
			ip_len_is_rng_bitmask                  : ternary @name("lkp.ip_len_is_rng_bitmask");
#else
  #ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len");
  #else
			lkp.ip_len                             : ternary @name("lkp.ip_len");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port                            : ternary @name("lkp.l4_src_port");
			l4_src_port_is_rng_bitmask             : ternary @name("lkp.l4_src_port_is_rng_bitmask");
#else
  #ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port");
  #else
			lkp.l4_src_port                        : ternary @name("lkp.l4_src_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
			l4_dst_port_is_rng_bitmask             : ternary @name("lkp.l4_dst_port_is_rng_bitmask");
#else
  #ifdef SF_2_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port");
  #else
			lkp.l4_dst_port                        : ternary @name("lkp.l4_dst_port");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_1.tunnel_outer_type          : ternary @name("tunnel_outer_type");
			eg_md.lkp_1.tunnel_inner_type          : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_inner_type");
#endif
		}

		actions = {
			NoAction_;
			hit();
		}

		const default_action = NoAction_;
		counters = stats;
		size = table_size;
	}

	apply {
		if (!EGRESS_BYPASS(ACL)) {
			acl.apply();
		}
	}
}

#endif

//-----------------------------------------------------------------------------

control EgressAcl(
	in    switch_lookup_fields_t lkp,
	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len,
	in    bool                     ip_len_is_rng_bitmask,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port,
	in    bool                     l4_src_port_is_rng_bitmask,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port,
	in    bool                     l4_dst_port_is_rng_bitmask,
	inout switch_header_transport_t hdr_0,
	in    switch_header_outer_t     hdr_1,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags
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
	EgressMacAcl(mac_table_size) egress_mac_acl;

	bool drop;
	bool terminate;
	bool copy_to_cpu;
	bool redirect_to_cpu;
	switch_cpu_reason_t cpu_reason;
	switch_copp_meter_id_t copp_meter_id;

	// -------------------------------------
	// Table: Terminate
	// -------------------------------------

/*
	action terminate_table_none() {
//		eg_md.nsh_md.terminate_popcount = 0;
	}

	action terminate_table_outer() {
		eg_md.tunnel_1.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 1;
	}

//	action terminate_table_inner() {
//		eg_md.tunnel_2.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 1;
//	}

	action terminate_table_both() {
		eg_md.tunnel_1.terminate = true;
		eg_md.tunnel_2.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 2;
	}

	table terminate_table {
		key = {
			hdr_0.nsh_type1.scope        : exact;

			eg_md.nsh_md.terminate_outer : exact; // prev
			terminate                    : exact; // curr
			eg_md.nsh_md.terminate_inner : exact; // next
		}
		actions = {
			terminate_table_none;
			terminate_table_outer;
//			terminate_table_inner;
			terminate_table_both;
		}
		const entries = {
			//  prev,  curr,  next
			// --------------------
			// scope is "outer" -- ignore terminate prev bit (there is nothing before present scope)
			(0, false, false, false) : terminate_table_none();
			(0, true,  false, false) : terminate_table_none();
			(0, false, true,  false) : terminate_table_outer();
			(0, true,  true,  false) : terminate_table_outer();
			(0, false, false, true ) : terminate_table_both();  // can't term just inner, must term both outer and inner
			(0, true,  false, true ) : terminate_table_both();  // can't term just inner, must term both outer and inner
			(0, false, true,  true ) : terminate_table_both();
			(0, true,  true,  true ) : terminate_table_both();

			// scope is "inner" -- ignore terminate next bit (there is nothing after present scope)
			(1, false, false, false) : terminate_table_none();
			(1, true,  false, false) : terminate_table_outer();
			(1, false, true,  false) : terminate_table_both();   // can't term just inner, must term both outer and inner
			(1, true,  true,  false) : terminate_table_both();
			(1, false, false, true ) : terminate_table_none();
			(1, true,  false, true ) : terminate_table_outer();
			(1, false, true,  true ) : terminate_table_both();   // can't term just inner, must term both outer and inner
			(1, true,  true,  true ) : terminate_table_both();
		}
	}
*/

	// -------------------------------------
	// Table: COPP
	// -------------------------------------
#ifdef CPU_ACL_EGRESS_ENABLE
	action copy_to_cpu_process_results(in switch_cpu_reason_t cpu_reason_, in switch_copp_meter_id_t copp_meter_id_) {
		eg_md.cpu_reason = cpu_reason_;
		eg_intr_md_for_dprsr.mirror_type = SWITCH_MIRROR_TYPE_CPU;
		eg_md.mirror.type = SWITCH_MIRROR_TYPE_CPU;
		eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU;
		eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
	}
#endif // CPU_ACL_EGRESS_ENABLE
	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
		drop = false;
		terminate = false;
		copy_to_cpu = false;
		redirect_to_cpu = false;
		cpu_reason = 0;
//		copp_meter_id = 0; // TODO: this may be data and therefore not need to be initialized

		eg_md.nsh_md.strip_e_tag = false;
		eg_md.nsh_md.strip_vn_tag = false;
		eg_md.nsh_md.strip_vlan_tag = false;
		eg_md.nsh_md.add_vlan_tag_bd = 0;
		eg_md.nsh_md.truncate_enable = false;
		eg_md.nsh_md.terminate_outer = false;
		eg_md.nsh_md.terminate_inner = false;

		// --------------
		// tables
		// --------------

		// Derek: The way this works is that the "hit" action of each table MUST write ALL of the outputs.  This is so that we don't
		// end up with partial results from one table and partial results from another in the final result.  So it is very import
		// that all "hit" actions write ALL of the outputs.

		// ----- l2 -----
		egress_mac_acl.apply(
			lkp,
			hdr_1,
			eg_md,
			eg_intr_md_for_dprsr,
			ip_len, ip_len_is_rng_bitmask,
			l4_src_port, l4_src_port_is_rng_bitmask,
			l4_dst_port, l4_dst_port_is_rng_bitmask,
			int_ctrl_flags,
			// ----- results -----
			drop,
			terminate,
			copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id
		);

		// ----- l3/4 -----
#if defined(SF_2_ACL_SHARED_IP_ENABLE)
		if (lkp.ip_type != SWITCH_IP_TYPE_NONE) {
			egress_ip_acl.apply(
				lkp,
				eg_md,
				eg_intr_md_for_dprsr,
				ip_len, ip_len_is_rng_bitmask,
				l4_src_port, l4_src_port_is_rng_bitmask,
				l4_dst_port, l4_dst_port_is_rng_bitmask,
				int_ctrl_flags,
				// ----- results -----
				drop,
				terminate,
				copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id
			);
		}
#else
		if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
  #ifdef IPV6_ENABLE
			egress_ipv6_acl.apply(
				lkp,
				eg_md,
				eg_intr_md_for_dprsr,
				ip_len, ip_len_is_rng_bitmask,
				l4_src_port, l4_src_port_is_rng_bitmask,
				l4_dst_port, l4_dst_port_is_rng_bitmask,
				int_ctrl_flags,
				// ----- results -----
				drop,
				terminate,
				copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id
			);
  #endif // IPV6_ENABLE
		} else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
			egress_ipv4_acl.apply(
				lkp,
				eg_md,
				eg_intr_md_for_dprsr,
				ip_len, ip_len_is_rng_bitmask,
				l4_src_port, l4_src_port_is_rng_bitmask,
				l4_dst_port, l4_dst_port_is_rng_bitmask,
				int_ctrl_flags,
				// ----- results -----
				drop,
				terminate,
				copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id
			);
		}
#endif

		// --------------
		// results
		// --------------

		// ----- drop -----

		if(drop == true) {
			eg_intr_md_for_dprsr.drop_ctl = 0x1;
		}

		// note: terminate + !scope is an illegal condition

		// ----- terminate -----

		// outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
		if(terminate || eg_md.nsh_md.terminate_inner) {
			eg_md.tunnel_1.terminate           = true;
			if(hdr_0.nsh_type1.scope == 1) {
				eg_md.tunnel_2.terminate           = true;
			}
		}

		// ----- scope -----

		// note: don't need to adjust scope here, as nobody else looks at the data after this.

		// ----- copy to cpu -----
#ifdef CPU_ACL_EGRESS_ENABLE
		if(copy_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason, copp_meter_id);
		} else if(redirect_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason, copp_meter_id);
			eg_intr_md_for_dprsr.drop_ctl = 0x1;
		}

		eg_md.copp_enable = copy_to_cpu;
		eg_md.copp_meter_id = copp_meter_id;
#endif // CPU_ACL_EGRESS_ENABLE
	}
}

#endif /* _P4_ACL_ */
