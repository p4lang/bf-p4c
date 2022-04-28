#ifndef _P4_ACL_
#define _P4_ACL_

//-----------------------------------------------------------------------------
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------

#define INGRESS_MAC_ACL_KEY              \
	prev_table_hit_ : ternary;           \
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
/*	prev_table_hit_ : ternary; */        \
	/* l3 */                             \
	lkp.ip_proto : ternary;              \
	lkp.ip_tos : ternary;                \
	/* l4 */                             \
/*	lkp.l4_src_port : ternary; */        \
/*	lkp.l4_dst_port : ternary; */        \
	lkp.tcp_flags : ternary;             \

#define INGRESS_IPV4_ACL_KEY             \
/*	prev_table_hit_ : ternary; */        \
	/* l3 */                             \
/*	lkp.ip_src_addr[31:0] : ternary; */  \
/*	lkp.ip_dst_addr[31:0] : ternary; */  \
	lkp.ip_src_addr_v4    : ternary @name("lkp.ip_src_addr[31:0]"); \
	lkp.ip_dst_addr_v4    : ternary @name("lkp.ip_dst_addr[31:0]"); \
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
/*	prev_table_hit_ : ternary; */        \
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
/*	prev_table_hit_ : ternary; */        \
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

#define INGRESS_L7_ACL_KEY               \
/*	prev_table_hit_ : ternary; */        \
	hdr_udf.opaque : ternary;            \
	/*lkp.drop_reason : ternary;*/

//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------

#define EGRESS_MAC_ACL_KEY               \
	prev_table_hit_ : ternary;           \
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
/*	prev_table_hit_ : ternary; */        \
	/* l3 */                             \
/*	lkp.ip_src_addr[31:0] : ternary; */  \
/*	lkp.ip_dst_addr[31:0] : ternary; */  \
	lkp.ip_src_addr_v4    : ternary @name("lkp.ip_src_addr[31:0]"); \
	lkp.ip_dst_addr_v4    : ternary @name("lkp.ip_dst_addr[31:0]"); \
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
/*	prev_table_hit_ : ternary; */        \
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
/*	prev_table_hit_ : ternary; */        \
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
action no_action() {                                                          \
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
	bool dedup_en,                                                            \
	bool sfc_enable,                                                          \
	bit<SF_SRVC_FUNC_CHAIN_WIDTH> sfc,                                        \
	bit<SF_FLOW_CLASS_WIDTH_A> flow_class,                                    \
	bool mirror_enable,                                                       \
	switch_mirror_session_t mirror_session_id,                                \
	switch_cpu_reason_t cpu_reason_code,                                      \
	switch_mirror_meter_id_t mirror_meter_id,                                 \
	switch_qid_t qid,                                                         \
	bool dtel_report_type_enable,                                             \
	switch_dtel_report_type_t dtel_report_type,                               \
                                                                              \
	bit<6> indirect_counter_index                                             \
) {                                                                           \
/*	ig_intr_md_for_dprsr.drop_ctl = drop; */                                  \
	drop_                       = drop;                                       \
                                                                              \
	terminate_                  = terminate;                                  \
	scope_                      = scope;                                      \
	ig_md.nsh_md.truncate_enable= truncate_enable;                            \
	ig_md.nsh_md.truncate_len   = truncate_len;                               \
	ig_md.nsh_md.dedup_en       = dedup_en;                                   \
	ig_md.nsh_md.sfc_enable     = sfc_enable;                                 \
	ig_md.nsh_md.sfc            = sfc;                                        \
	flow_class_                 = flow_class;                                 \
                                                                              \
	mirror_enable_              = mirror_enable;                              \
	mirror_session_id_          = mirror_session_id;                          \
	cpu_reason_                 = cpu_reason_code;                            \
	mirror_meter_id_            = mirror_meter_id;                            \
                                                                              \
	qid_                        = qid;                                        \
                                                                              \
	dtel_report_type_enable_    = dtel_report_type_enable;                    \
	dtel_report_type_           = dtel_report_type;                           \
                                                                              \
	stats.count();                                                            \
	indirect_counter_index_     = indirect_counter_index;                     \
}

//-----------------------------------------------------------------------------
// Common Egress ACL actions.
//-----------------------------------------------------------------------------

#define EGRESS_ACL_ACTIONS                                                    \
                                                                              \
action no_action() {                                                          \
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
	bool dedup_en,                                                            \
	bool terminate_outer,                                                     \
	bool terminate_inner,                                                     \
	bool mirror_enable,                                                       \
	switch_mirror_session_t mirror_session_id,                                \
	switch_cpu_reason_t cpu_reason_code,                                      \
	switch_mirror_meter_id_t mirror_meter_id,                                 \
	bit<6> indirect_counter_index                                             \
) {                                                                           \
/*	eg_intr_md_for_dprsr.drop_ctl = drop; */                                  \
	drop_                       = drop;                                       \
                                                                              \
	terminate_                  = terminate;                                  \
                                                                              \
	eg_md.nsh_md.strip_tag_e    = strip_tag_e;                                \
	eg_md.nsh_md.strip_tag_vn   = strip_tag_vn;                               \
	eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan;                             \
	eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd;                            \
	eg_md.nsh_md.truncate_enable= truncate_enable;                            \
	eg_md.nsh_md.truncate_len   = truncate_len;                               \
	eg_md.nsh_md.dedup_en       = dedup_en;                                   \
	eg_md.nsh_md.terminate_outer= terminate_outer;                            \
	eg_md.nsh_md.terminate_inner= terminate_inner;                            \
                                                                              \
	mirror_enable_              = mirror_enable;                              \
	mirror_session_id_          = mirror_session_id;                          \
	cpu_reason_                 = cpu_reason_code;                            \
	mirror_meter_id_            = mirror_meter_id;                            \
                                                                              \
	stats.count();                                                            \
	indirect_counter_index_     = indirect_counter_index;                     \
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
	inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_,
	inout switch_qid_t qid_,
	inout bool dtel_report_type_enable_,
	inout switch_dtel_report_type_t dtel_report_type_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

	INGRESS_ACL_ACTIONS

	table acl {
		key = {
			INGRESS_MAC_ACL_KEY

			// extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			ig_md.nsh_md.sap                      : ternary @name("sap");
			ig_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
#ifdef SF_0_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
		}

		actions = {
			no_action;
			hit();
		}

		const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
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
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_,
	inout switch_qid_t qid_,
	inout bool dtel_report_type_enable_,
	inout switch_dtel_report_type_t dtel_report_type_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

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
			ig_md.nsh_md.sap                      : ternary @name("sap");
			ig_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
#ifdef SF_0_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
			ip_len                                 : ternary @name("lkp.ip_len");
#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
			ip_len_rng                             : ternary @name("lkp.ip_len_rng");
#else
  #ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len_rng");
  #endif
#endif
			// -------------------------------------------
			l4_src_port                            : ternary @name("lkp.l4_src_port");
#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port_rng                        : ternary @name("lkp.l4_src_port_rng");
#else
  #ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port_rng");
  #endif
#endif
			// -------------------------------------------
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port_rng                        : ternary @name("lkp.l4_dst_port_rng");
#else
  #ifdef SF_0_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port_rng");
  #endif
#endif
		}

		actions = {
			no_action;
			hit();
		}

		const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
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
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_,
	inout switch_qid_t qid_,
	inout bool dtel_report_type_enable_,
	inout switch_dtel_report_type_t dtel_report_type_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

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
			ig_md.nsh_md.sap                      : ternary @name("sap");
			ig_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
#ifdef SF_0_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
			ip_len                                 : ternary @name("lkp.ip_len");
#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
			ip_len_rng                             : ternary @name("lkp.ip_len_rng");
#else
  #ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len_rng");
  #endif
#endif
			// -------------------------------------------
			l4_src_port                            : ternary @name("lkp.l4_src_port");
#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port_rng                        : ternary @name("lkp.l4_src_port_rng");
#else
  #ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port_rng");
  #endif
#endif
			// -------------------------------------------
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port_rng                        : ternary @name("lkp.l4_dst_port_rng");
#else
  #ifdef SF_0_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port_rng");
  #endif
#endif
		}

		actions = {
			no_action;
			hit();
		}
		const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
		}
	}
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------

control IngressIpv6Acl(
	in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
	inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_,
	inout switch_qid_t qid_,
	inout bool dtel_report_type_enable_,
	inout switch_dtel_report_type_t dtel_report_type_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

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
			ig_md.nsh_md.sap                      : ternary @name("sap");
			ig_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
#ifdef SF_0_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
			ip_len                                 : ternary @name("lkp.ip_len");
#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
			ip_len_rng                             : ternary @name("lkp.ip_len_rng");
#else
  #ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len_rng");
  #endif
#endif
			// -------------------------------------------
			l4_src_port                            : ternary @name("lkp.l4_src_port");
#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port_rng                        : ternary @name("lkp.l4_src_port_rng");
#else
  #ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port_rng");
  #endif
#endif
			// -------------------------------------------
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port_rng                        : ternary @name("lkp.l4_dst_port_rng");
#else
  #ifdef SF_0_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port_rng");
  #endif
#endif
		}

		actions = {
			no_action;
			hit();
		}

		const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
		}
	}
}

//-----------------------------------------------------------------------------
// L7 ACL
//-----------------------------------------------------------------------------

control IngressL7Acl(
	in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
	in    udf_h hdr_udf,
	inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool scope_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<SF_FLOW_CLASS_WIDTH_A> flow_class_,
	inout switch_qid_t qid_,
	inout bool dtel_report_type_enable_,
	inout switch_dtel_report_type_t dtel_report_type_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

	INGRESS_ACL_ACTIONS

	table acl {
		key = {
			INGRESS_L7_ACL_KEY

			// extreme added
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
			ig_md.nsh_md.sap                      : ternary @name("sap");
			ig_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
			flow_class_                            : ternary @name("flow_class");
		}

		actions = {
			no_action;
			hit();
		}

		const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
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
	inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	inout switch_header_transport_t hdr_0,
	in    udf_h hdr_udf,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags
) (
	MODULE_DEPLOYMENT_PARAMS,
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
	IngressIpv6Acl(ipv6_table_size) ipv6_acl;
#endif /* SF_0_ACL_SHARED_IP_ENABLE */
	IngressMacAcl(mac_table_size) mac_acl;
	IngressL7Acl(l7_table_size) l7_acl;

	Scoper_Scope_And_Term_Only(INSTANCE_DEPLOYMENT_PARAMS) scoper_scope_and_term_only;

#ifdef SF_0_INDIRECT_COUNTERS
//	Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
	Counter<bit<32>, bit<15>>(32768, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<16>>(65536, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<17>>(131072, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
#endif

	bool prev_table_hit = false;
	bool drop = false;
	bool terminate = false;
	bool scope = false;
	switch_cpu_reason_t cpu_reason = 0;
	bool mirror_enable = false;
	switch_mirror_session_t mirror_session_id = 0;
	bool dtel_report_type_enable = false;
	switch_mirror_meter_id_t mirror_meter_id = 0;
	bit<SF_FLOW_CLASS_WIDTH_A> flow_class = 0;
	switch_qid_t qid = 0;
	switch_dtel_report_type_t dtel_report_type;
	bit<6> indirect_counter_index = 0;

	// -------------------------------------
	// Table: Scope Increment
	// -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		ig_md.nsh_md.scope = scope_new;
	}

	table scope_inc {
		key = {
			ig_md.nsh_md.scope : exact;
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
	action copy_to_cpu_process_results(in switch_mirror_session_t mirror_session_id_, in switch_cpu_reason_t cpu_reason_) {
/*
		ig_intr_md_for_tm.copy_to_cpu = 1w1;
		ig_md.cpu_reason = cpu_reason_;
*/
		ig_md.cpu_reason = cpu_reason_;
//		ig_intr_md_for_dprsr.mirror_type = SWITCH_MIRROR_TYPE_CPU; // don't need, there is an alias on ingress for this.
		ig_md.mirror.type = SWITCH_MIRROR_TYPE_CPU;
		ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
//		ig_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU_INGRESS;
		ig_md.mirror.session_id = mirror_session_id_;
	}
#endif // CPU_ACL_INGRESS_ENABLE
	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
/*
		drop                         = false;
		terminate                    = false;
		scope                        = false;
		mirror_enable                = false;
		mirror_session_id            = 0;
		dtel_report_type_enable      = false;
		cpu_reason                   = 0;
//		mirror_meter_id              = 0; // TODO: this may be data and therefore not need to be initialized
		flow_class                   = 0;
		indirect_counter_index       = 0;
*/
		ig_md.nsh_md.truncate_enable = false;
		ig_md.nsh_md.dedup_en        = false;
		ig_md.nsh_md.sfc_enable      = false;

#ifdef PA_NO_INIT
		ig_intr_md_for_tm.copy_to_cpu = 0;
#endif

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
			ig_md,
			ig_intr_md_for_dprsr,
			ip_len, ip_len_rng,
			l4_src_port, l4_src_port_rng,
			l4_dst_port, l4_dst_port_rng,
			int_ctrl_flags,
			// ----- results -----
			prev_table_hit,
			drop,
			terminate,
			scope,
			mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
			dtel_report_type_enable, dtel_report_type,
			indirect_counter_index
		);

		// ----- l3/4 -----
#if defined(SF_0_ACL_SHARED_IP_ENABLE)
		if (lkp.ip_type != SWITCH_IP_TYPE_NONE) {
			ip_acl.apply(
				lkp,
				hdr_0,
				ig_md,
				ig_intr_md_for_dprsr,
				ip_len, ip_len_rng,
				l4_src_port, l4_src_port_rng,
				l4_dst_port, l4_dst_port_rng,
				int_ctrl_flags,
				// ----- results -----
				prev_table_hit,
				drop,
				terminate,
				scope,
				mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
				dtel_report_type_enable, dtel_report_type,
				indirect_counter_index
			);
		}
#else
		if (((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) && (lkp.ip_type == SWITCH_IP_TYPE_IPV6)) {
			ipv6_acl.apply(
				lkp,
				hdr_0,
				ig_md,
				ig_intr_md_for_dprsr,
				ip_len, ip_len_rng,
				l4_src_port, l4_src_port_rng,
				l4_dst_port, l4_dst_port_rng,
				int_ctrl_flags,
				// ----- results -----
				prev_table_hit,
				drop,
				terminate,
				scope,
				mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
				dtel_report_type_enable, dtel_report_type,
				indirect_counter_index
			);
		} else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
			ipv4_acl.apply(
				lkp,
				hdr_0,
				ig_md,
				ig_intr_md_for_dprsr,
				ip_len, ip_len_rng,
				l4_src_port, l4_src_port_rng,
				l4_dst_port, l4_dst_port_rng,
				int_ctrl_flags,
				// ----- results -----
				prev_table_hit,
				drop,
				terminate,
				scope,
				mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
				dtel_report_type_enable, dtel_report_type,
				indirect_counter_index
			);
		}
#endif /* SF_0_ACL_SHARED_IP_ENABLE */

		// ----- l7 -----
		if(UDF_ENABLE) {
			if (hdr_udf.isValid()) {
				l7_acl.apply(
					lkp,
					hdr_0,
					hdr_udf,
					ig_md,
					ig_intr_md_for_dprsr,
					ip_len, ip_len_rng,
					l4_src_port, l4_src_port_rng,
					l4_dst_port, l4_dst_port_rng,
					int_ctrl_flags,
					// ----- results -----
					prev_table_hit,
					drop,
					terminate,
					scope,
					mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
					dtel_report_type_enable, dtel_report_type,
					indirect_counter_index
				);
			}
		}
/*
		// ----- l2 -----
		mac_acl.apply(
			lkp,
			hdr_0,
			ig_md,
			ig_intr_md_for_dprsr,
			ip_len, ip_len_rng,
			l4_src_port, l4_src_port_rng,
			l4_dst_port, l4_dst_port_rng,
			int_ctrl_flags,
			// ----- results -----
			prev_table_hit,
			drop,
			terminate,
			scope,
			mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
			dtel_report_type_enable, dtel_report_type,
			indirect_counter_index
		);
*/
		// --------------
		// results
		// --------------

		// ----- drop -----

		if(drop == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0x1;
		}

		// note: terminate + !scope is an illegal condition
/*
		if(lkp.next_lyr_valid == true) {

			// ----- terminate -----

			if(terminate == true) {
				ig_md.tunnel_1.terminate           = true;
				if(ig_md.nsh_md.scope == 2) {
					ig_md.tunnel_2.terminate           = true;
				}
			}

			// ----- scope -----

#ifdef SF_0_ALLOW_SCOPE_CHANGES
			if(scope == true) {
				if(ig_md.nsh_md.scope == 1) {

					// note: need to change scope here so that the lag
					// hash gets the new values....

  #ifdef INGRESS_PARSER_POPULATES_LKP_2
					Scoper.apply(
						ig_md.lkp_2,
//						ig_md.drop_reason_2,

						lkp
					);
  #else
					ScoperInner.apply(
						hdr_2,

						lkp
					);
  #endif

//					ig_md.nsh_md.hash_1 = ig_md.nsh_md.hash_2;
				}

				ig_md.nsh_md.scope = ig_md.nsh_md.scope + 1;
//				scope_inc.apply();
			}
#endif
		}
*/
#ifdef SF_0_ALLOW_SCOPE_CHANGES
/*
		Scoper_ScopeAndTermAndData.apply(
			ig_md.lkp_0,
//			ig_md.lkp_1,
			ig_md.lkp_2,

			lkp,

			terminate,
			scope,
			ig_md.nsh_md.scope,
			ig_md.tunnel_0.terminate,
			ig_md.tunnel_1.terminate,
			ig_md.tunnel_2.terminate
		);
*/
		scoper_scope_and_term_only.apply(
			lkp,

			terminate,
			scope,
			ig_md.nsh_md.scope,
			ig_md.tunnel_0.terminate,
			ig_md.tunnel_1.terminate,
			ig_md.tunnel_2.terminate
		);
#endif

		// ----- truncate -----

		if(ig_md.nsh_md.truncate_enable) {
#if __TARGET_TOFINO__ == 2
			ig_intr_md_for_dprsr.mtu_trunc_len = ig_md.nsh_md.truncate_len + BRIDGED_METADATA_WIDTH;
  #ifdef PA_NO_INIT
		} else {
			ig_intr_md_for_dprsr.mtu_trunc_len = 0x3fff;
  #endif
#endif
		}

		// ----- qid -----
#ifdef SF_0_QID_ENABLE
		ig_intr_md_for_tm.qid = (switch_qid_t) qid;
#endif

		// ----- copy to cpu -----
#ifdef CPU_ACL_INGRESS_ENABLE
/*
		if(copy_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason);
		} else if(redirect_to_cpu == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0b1;
			copy_to_cpu_process_results(cpu_reason);
		}

		if((copy_to_cpu == true) || (redirect_to_cpu == true)) {
			IngressCopp.apply(copp_meter_id, ig_intr_md_for_tm);
		}
*/
		if(mirror_enable == true) {
			copy_to_cpu_process_results(mirror_session_id, cpu_reason);

//			IngressCopp.apply(copp_meter_id, ig_intr_md_for_tm);
			ig_md.mirror.meter_index = mirror_meter_id; // derek added
		}
#endif // CPU_ACL_INGRESS_ENABLE

#ifdef DTEL_ACL
		// ----- dtel -----
		if(dtel_report_type_enable == true) {
			ig_md.dtel.report_type = ig_md.dtel.report_type | dtel_report_type;
		}
#endif

#ifdef SF_0_INDIRECT_COUNTERS
		indirect_counter.count(ig_md.port ++ indirect_counter_index);
#endif
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
	in    switch_header_transport_t hdr,
	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

	EGRESS_ACL_ACTIONS

	table acl {
		key = {
			EGRESS_MAC_ACL_KEY

			// extreme added
#ifdef SF_2_ACL_INT_CTRL_FLAGS_ENABLE
			int_control_flags                      : ternary;
#endif
			// -------------------------------------------
//			eg_md.nsh_md.sap                      : ternary @name("sap");
//			eg_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
			// -------------------------------------------
			eg_md.nsh_md.dsap                      : ternary @name("dsap");
			// -------------------------------------------
#ifdef SF_2_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			lkp.tunnel_outer_type                  : ternary @name("tunnel_outer_type");
			lkp.tunnel_inner_type                  : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");
#endif
		}

		actions = {
			no_action;
			hit();
		}

		const default_action = hit(false, false, false, false, false, 0, false, 0, false, false, false, false, 0, 0, 0, 0);
		//const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
		}
	}
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control EgressIpAcl(
	in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

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
//			eg_md.nsh_md.sap                      : ternary @name("sap");
//			eg_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
			// -------------------------------------------
			eg_md.nsh_md.dsap                      : ternary @name("dsap");
			// -------------------------------------------
#ifdef SF_2_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
			ip_len                                 : ternary @name("lkp.ip_len");
#ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE
			ip_len_rng                             : ternary @name("lkp.ip_len_rng");
#else
  #ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len_rng");
  #endif
#endif
			// -------------------------------------------
			l4_src_port                            : ternary @name("lkp.l4_src_port");
#ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port_rng                        : ternary @name("lkp.l4_src_port_rng");
#else
  #ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port_rng");
  #endif
#endif
			// -------------------------------------------
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
#ifdef SF_2_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port_rng                        : ternary @name("lkp.l4_dst_port_rng");
#else
  #ifdef SF_2_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port_rng");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			lkp.tunnel_outer_type                  : ternary @name("tunnel_outer_type");
			lkp.tunnel_inner_type                  : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");
#endif
		}

		actions = {
			no_action;
			hit();
		}

		const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
		}
	}
}

//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control EgressIpv4Acl(
	in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

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
//			eg_md.nsh_md.sap                      : ternary @name("sap");
//			eg_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
			// -------------------------------------------
			eg_md.nsh_md.dsap                      : ternary @name("dsap");
			// -------------------------------------------
#ifdef SF_2_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
			ip_len                                 : ternary @name("lkp.ip_len");
#ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE
			ip_len_rng                             : ternary @name("lkp.ip_len_rng");
#else
  #ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len_rng");
  #endif
#endif
			// -------------------------------------------
			l4_src_port                            : ternary @name("lkp.l4_src_port");
#ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port_rng                        : ternary @name("lkp.l4_src_port_rng");
#else
  #ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port_rng");
  #endif
#endif
			// -------------------------------------------
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
#ifdef SF_2_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port_rng                        : ternary @name("lkp.l4_dst_port_rng");
#else
  #ifdef SF_2_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port_rng");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			lkp.tunnel_outer_type                  : ternary @name("tunnel_outer_type");
			lkp.tunnel_inner_type                  : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");
#endif
		}

		actions = {
			no_action;
			hit();
		}

		const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
		}
	}
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------

control EgressIpv6Acl(
	in    switch_lookup_fields_t lkp,
	in    switch_header_transport_t hdr,
	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_control_flags,
	// ----- results -----
	inout bool prev_table_hit_,
	inout bool drop_,
	inout bool terminate_,
	inout bool mirror_enable_,
	inout switch_mirror_session_t mirror_session_id_,
	inout switch_cpu_reason_t cpu_reason_,
	inout switch_mirror_meter_id_t mirror_meter_id_,
	inout bit<6> indirect_counter_index_
) (
	switch_uint32_t table_size=512
) {
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

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
//			eg_md.nsh_md.sap                      : ternary @name("sap");
//			eg_md.nsh_md.vpn                      : ternary @name("vpn");
			// -------------------------------------------
			// -------------------------------------------
			eg_md.nsh_md.dsap                      : ternary @name("dsap");
			// -------------------------------------------
#ifdef SF_2_L2_VLAN_ID_ENABLE
			lkp.vid                                : ternary;
#endif
			// -------------------------------------------
			ip_len                                 : ternary @name("lkp.ip_len");
#ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE
			ip_len_rng                             : ternary @name("lkp.ip_len_rng");
#else
  #ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE_IN_ACL
			lkp.ip_len                             : range   @name("lkp.ip_len_rng");
  #endif
#endif
			// -------------------------------------------
			l4_src_port                            : ternary @name("lkp.l4_src_port");
#ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE
			l4_src_port_rng                        : ternary @name("lkp.l4_src_port_rng");
#else
  #ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_src_port                        : range   @name("lkp.l4_src_port_rng");
  #endif
#endif
			// -------------------------------------------
			l4_dst_port                            : ternary @name("lkp.l4_dst_port");
#ifdef SF_2_L4_DST_RNG_TABLE_ENABLE
			l4_dst_port_rng                        : ternary @name("lkp.l4_dst_port_rng");
#else
  #ifdef SF_2_L4_DST_RNG_TABLE_ENABLE_IN_ACL
			lkp.l4_dst_port                        : range   @name("lkp.l4_dst_port_rng");
  #endif
#endif
			// -------------------------------------------
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			lkp.tunnel_outer_type                  : ternary @name("tunnel_outer_type");
			lkp.tunnel_inner_type                  : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_inner_type");
#endif
		}

		actions = {
			no_action;
			hit();
		}

		const default_action = no_action;
		counters = stats;
		size = table_size;
	}

	apply {
		if(acl.apply().hit) {
			prev_table_hit_ = true;
		}
	}
}

//-----------------------------------------------------------------------------

control EgressAcl(
	inout switch_lookup_fields_t lkp,
	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	in    bit<16>                  ip_len,
	in    bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng,
	in    bit<16>                  l4_src_port,
	in    bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng,
	in    bit<16>                  l4_dst_port,
	in    bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng,
	inout switch_header_transport_t hdr_0,
	in    bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags
) (
	MODULE_DEPLOYMENT_PARAMS,
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
	EgressIpv6Acl(ipv6_table_size) egress_ipv6_acl;
#endif
	EgressMacAcl(mac_table_size) egress_mac_acl;

	Scoper_Scope_And_Term_Only_no_scope_flag(INSTANCE_DEPLOYMENT_PARAMS) scoper_scope_and_term_only;

#ifdef SF_2_INDIRECT_COUNTERS
//	Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
	Counter<bit<32>, bit<15>>(32768, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<16>>(65536, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<17>>(131072, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
#endif

	bool prev_table_hit = false;
	bool drop = false;
	bool terminate = false;
	bool mirror_enable = false;
	switch_mirror_session_t mirror_session_id = 0;
	switch_cpu_reason_t cpu_reason = 0;
	switch_mirror_meter_id_t mirror_meter_id = 0;
	bit<6> indirect_counter_index = 0;

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
			eg_md.nsh_md.scope           : exact;

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
	action copy_to_cpu_process_results(in switch_mirror_session_t mirror_session_id_, in switch_cpu_reason_t cpu_reason_) {
		eg_md.cpu_reason = cpu_reason_;
		eg_intr_md_for_dprsr.mirror_type = SWITCH_MIRROR_TYPE_CPU;
		eg_md.mirror.type = SWITCH_MIRROR_TYPE_CPU;
		eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
//		eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU_EGRESS;
		eg_md.mirror.session_id = mirror_session_id_;
	}
#endif // CPU_ACL_EGRESS_ENABLE
	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
/*
		drop                         = false;
		terminate                    = false;
		mirror_enable                = false;
		mirror_session_id            = 0;
		cpu_reason                   = 0;
//		mirror_meter_id              = 0; // TODO: this may be data and therefore not need to be initialized
		indirect_counter_index       = 0;
*/
		eg_md.nsh_md.strip_tag_e     = false;
		eg_md.nsh_md.strip_tag_vn    = false;
		eg_md.nsh_md.strip_tag_vlan  = false;
		eg_md.nsh_md.add_tag_vlan_bd = 0;
		eg_md.nsh_md.truncate_enable = false;
		eg_md.nsh_md.dedup_en        = false;
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
			hdr_0,
			eg_md,
			eg_intr_md_for_dprsr,
			ip_len, ip_len_rng,
			l4_src_port, l4_src_port_rng,
			l4_dst_port, l4_dst_port_rng,
			int_ctrl_flags,
			// ----- results -----
			prev_table_hit,
			drop,
			terminate,
			mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
			indirect_counter_index
		);

		// ----- l3/4 -----
#if defined(SF_2_ACL_SHARED_IP_ENABLE)
		if (lkp.ip_type != SWITCH_IP_TYPE_NONE) {
			egress_ip_acl.apply(
				lkp,
				hdr_0,
				eg_md,
				eg_intr_md_for_dprsr,
				ip_len, ip_len_rng,
				l4_src_port, l4_src_port_rng,
				l4_dst_port, l4_dst_port_rng,
				int_ctrl_flags,
				// ----- results -----
				prev_table_hit,
				drop,
				terminate,
				mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
				indirect_counter_index
			);
		}
#else
		if (((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) && (lkp.ip_type == SWITCH_IP_TYPE_IPV6)) {
			egress_ipv6_acl.apply(
				lkp,
				hdr_0,
				eg_md,
				eg_intr_md_for_dprsr,
				ip_len, ip_len_rng,
				l4_src_port, l4_src_port_rng,
				l4_dst_port, l4_dst_port_rng,
				int_ctrl_flags,
				// ----- results -----
				prev_table_hit,
				drop,
				terminate,
				mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
				indirect_counter_index
			);
		} else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
			egress_ipv4_acl.apply(
				lkp,
				hdr_0,
				eg_md,
				eg_intr_md_for_dprsr,
				ip_len, ip_len_rng,
				l4_src_port, l4_src_port_rng,
				l4_dst_port, l4_dst_port_rng,
				int_ctrl_flags,
				// ----- results -----
				prev_table_hit,
				drop,
				terminate,
				mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
				indirect_counter_index
			);
		}
#endif
/*
		// ----- l2 -----
		egress_mac_acl.apply(
			lkp,
			hdr_0,
			eg_md,
			eg_intr_md_for_dprsr,
			ip_len, ip_len_rng,
			l4_src_port, l4_src_port_rng,
			l4_dst_port, l4_dst_port_rng,
			int_ctrl_flags,
			// ----- results -----
			prev_table_hit,
			drop,
			terminate,
			mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
			indirect_counter_index
		);
*/
		// --------------
		// results
		// --------------

		// ----- drop -----

		if(drop == true) {
			eg_intr_md_for_dprsr.drop_ctl = 0x1;
		}

		// note: terminate + !scope is an illegal condition

		// ----- terminate -----
/*
		if(terminate || eg_md.nsh_md.terminate_inner) {
			eg_md.tunnel_1.terminate           = true;
			if(eg_md.nsh_md.scope == 2) {
				eg_md.tunnel_2.terminate           = true;
			}
		}
*/

#ifdef PA_NO_INIT

		if(((eg_md.nsh_md.terminate_inner == true) && (eg_md.nsh_md.scope == 2)) || ((lkp.next_lyr_valid == true) && (terminate == true))) {
			eg_md.tunnel_1.terminate           = true;
		} else {
			eg_md.tunnel_1.terminate           = false;
		}

		if(lkp.next_lyr_valid == true) {
			// ----- terminate -----

			if(terminate == true) { 
//				eg_md.tunnel_1.terminate           = true;
				if(eg_md.nsh_md.scope == 2) {
					eg_md.tunnel_2.terminate           = true;
				}

			}

			// ----- scope -----

			// since we don't have an explicit 'scope' signal in egress acl, use 'terminate':
			if(terminate == true) { 

				// note: don't need to advance the data here, as nobody else looks at it after this.

				eg_md.nsh_md.scope = eg_md.nsh_md.scope + 1;
//				scope_inc.apply();
			}
		}

#else
/*
		if((eg_md.nsh_md.terminate_inner == true)) {
			// outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
			if(eg_md.nsh_md.scope == 2) {
				eg_md.tunnel_1.terminate           = true;
			}
		}
*/
/*
		if(lkp.next_lyr_valid == true) {

			// ----- terminate -----

			if(terminate == true) { 
				eg_md.tunnel_1.terminate           = true;
				if(eg_md.nsh_md.scope == 2) {
					eg_md.tunnel_2.terminate           = true;
				}

			}

			// ----- scope -----

			// since we don't have an explicit 'scope' signal in egress acl, use 'terminate':
			if(terminate == true) { 

				// note: don't need to advance the data here, as nobody else looks at it after this.

				eg_md.nsh_md.scope = eg_md.nsh_md.scope + 1;
//				scope_inc.apply();
			}
		}
*/
		scoper_scope_and_term_only.apply(
			lkp,

			terminate, // curr and prev
			eg_md.nsh_md.terminate_inner, // prev only
			eg_md.nsh_md.scope,
			eg_md.tunnel_0.terminate,
			eg_md.tunnel_1.terminate,
			eg_md.tunnel_2.terminate
		);
#endif

		// ----- truncate -----

		if(eg_md.nsh_md.truncate_enable) {
#if __TARGET_TOFINO__ == 2
			eg_intr_md_for_dprsr.mtu_trunc_len = eg_md.nsh_md.truncate_len;
  #ifdef PA_NO_INIT
		} else {
			eg_intr_md_for_dprsr.mtu_trunc_len = 0x3fff;
  #endif
#endif
		}

		// ----- copy to cpu -----
#ifdef CPU_ACL_EGRESS_ENABLE
/*
		if(copy_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason);
		} else if(redirect_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason);
			eg_intr_md_for_dprsr.drop_ctl = 0x1;
		}

		if((copy_to_cpu == true) || (redirect_to_cpu == true)) {
			EgressCopp.apply(copp_meter_id, eg_intr_md_for_dprsr);
		}
*/
		if(mirror_enable == true) {
			copy_to_cpu_process_results(mirror_session_id, cpu_reason);

//			EgressCopp.apply(copp_meter_id, eg_intr_md_for_dprsr);
			eg_md.mirror.meter_index = mirror_meter_id; // derek added
		}

#endif // CPU_ACL_EGRESS_ENABLE

#ifdef SF_2_INDIRECT_COUNTERS
		indirect_counter.count(eg_md.port ++ indirect_counter_index);
#endif
	}
}

#endif /* _P4_ACL_ */
