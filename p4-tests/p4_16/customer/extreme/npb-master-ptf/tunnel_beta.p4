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

#ifndef _TUNNEL_
#define _TUNNEL_

#include "scoper.p4"

//#if defined(IPV6_TUNNEL_ENABLE) && !defined(IPV6_ENABLE)
//#error "IPv6 tunneling cannot be enabled without enabling IPv6"
//#endif

//-----------------------------------------------------------------------------
// Ingress Tunnel RMAC: Transport
//-----------------------------------------------------------------------------

control IngressTunnelRMAC(
	inout switch_header_transport_t hdr_0,
	inout switch_lookup_fields_t lkp_0,
	inout switch_ingress_metadata_t ig_md
) (
	switch_uint32_t table_size = 128
) {

	// -------------------------------------
	// Table: RMAC
	// -------------------------------------

#ifdef BRIDGING_ENABLE
	action rmac_hit(
	) {
		ig_md.flags.rmac_hit = true;
	}

	action rmac_miss(
	) {
		ig_md.flags.rmac_hit = false;
	}

	table rmac {
		key = {
#ifdef INGRESS_PARSER_POPULATES_LKP_0
			lkp_0.mac_dst_addr      : exact;
#else
			hdr_0.ethernet.dst_addr : exact;
#endif
		}

		actions = {
			NoAction;
			rmac_hit;
			rmac_miss; // extreme added
		}

//		const default_action = NoAction;
		const default_action = rmac_miss;
		size = table_size;
	}
#endif

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
#ifdef BRIDGING_ENABLE
		if(hdr_0.ethernet.isValid()) {
//		if(ig_md.nsh_md.l2_fwd_en == true) {
			// network tapped
			rmac.apply();
		} else {
			// optically tapped
			ig_md.flags.rmac_hit = true;
		}
#else // BRIDGING_ENABLE
		ig_md.flags.rmac_hit = true;
#endif // BRIDGING_ENABLE
	}
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Transport (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnel(
	inout switch_ingress_metadata_t ig_md,
	inout switch_header_transport_t hdr_0,
	inout switch_lookup_fields_t lkp_0,
	inout switch_tunnel_metadata_t tunnel_0,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr // extreme added
) (
	switch_uint32_t ipv4_src_vtep_table_size=1024,
	switch_uint32_t ipv6_src_vtep_table_size=1024,
	switch_uint32_t ipv4_dst_vtep_table_size=1024,
	switch_uint32_t ipv6_dst_vtep_table_size=1024
) {
	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_src_vtep;
	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_dst_vtep;
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_src_vtepv6;
	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_dst_vtepv6;
#endif

	// -------------------------------------
	// Table: IPv4 Src VTEP
	// -------------------------------------

	// Derek note: These tables are unused in latest switch.p4 code from barefoot

	action src_vtep_hit(
		switch_port_lag_index_t port_lag_index,
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn
	) {
		stats_src_vtep.count();

		ig_md.port_lag_index    = port_lag_index;
		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
	}

	// -------------------------------------

	action src_vtep_miss(
	) {
		stats_src_vtep.count();
	}

	// -------------------------------------

	table src_vtep {
		key = {
#ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
  #ifdef INGRESS_PARSER_POPULATES_LKP_0
			lkp_0.ip_src_addr[31:0] : ternary @name("src_addr");
  #else
			hdr_0.ipv4.src_addr     : ternary @name("src_addr");
  #endif
#endif
//			tunnel_0.type           : exact @name("tunnel_type");
			lkp_0.tunnel_type       : exact @name("tunnel_type");
		}

		actions = {
			src_vtep_miss;
			src_vtep_hit;
		}

		const default_action = src_vtep_miss;
		counters = stats_src_vtep;
		size = ipv4_src_vtep_table_size;
	}

	// -------------------------------------
	// Table: IPv6 Src VTEP
	// -------------------------------------

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
	action src_vtepv6_hit(
		switch_port_lag_index_t port_lag_index,
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn
	) {
		stats_src_vtepv6.count();

		ig_md.port_lag_index    = port_lag_index;
		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
	}

	// -------------------------------------

	action src_vtepv6_miss(
	) {
		stats_src_vtepv6.count();
	}

	// -------------------------------------

	table src_vtepv6 {
		key = {
#ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
  #ifdef INGRESS_PARSER_POPULATES_LKP_0
			lkp_0.ip_src_addr   : ternary @name("src_addr");
  #else
			hdr_0.ipv6.src_addr : ternary @name("src_addr");
  #endif
#endif
//			tunnel_0.type       : exact @name("tunnel_type");
			lkp_0.tunnel_type   : exact @name("tunnel_type");
		}

		actions = {
			src_vtepv6_miss;
			src_vtepv6_hit;
		}

		const default_action = src_vtepv6_miss;
		counters = stats_src_vtepv6;
		size = ipv6_src_vtep_table_size;
	}
#endif

	// -------------------------------------
	// Table: IPv4 Dst VTEP
	// -------------------------------------

	bool drop_ = false;

	action dst_vtep_hit(
//		switch_bd_t bd,

		bool drop

  #ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
		,
		switch_port_lag_index_t port_lag_index,
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn
  #endif
	) {
		stats_dst_vtep.count();

//		ig_md.bd = bd;

//		ig_intr_md_for_dprsr.drop_ctl = drop;
		drop_ = drop;

  #ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
		ig_md.port_lag_index    = port_lag_index;
		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
  #endif
	}

	// -------------------------------------

//	action dst_vtep_tunid_hit(
//	) {
//		stats_dst_vtep.count();
//	}

	// -------------------------------------

	action NoAction_(
	) {
		stats_dst_vtep.count();
	}

	// -------------------------------------

	table dst_vtep {
		key = {
#ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
  #ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
    #ifdef INGRESS_PARSER_POPULATES_LKP_0
			lkp_0.ip_src_addr[31:0] : ternary @name("src_addr");
    #else
			hdr_0.ipv4.src_addr     : ternary @name("src_addr");
    #endif
  #endif
    #ifdef INGRESS_PARSER_POPULATES_LKP_0
			lkp_0.ip_dst_addr[31:0] : ternary @name("dst_addr");
    #else
			hdr_0.ipv4.dst_addr     : ternary @name("dst_addr");
    #endif
#endif
//			tunnel_0.type           : exact @name("tunnel_type");
			lkp_0.tunnel_type       : exact @name("tunnel_type");
		}

		actions = {
			NoAction_;
			dst_vtep_hit;
//			dst_vtep_tunid_hit;
		}

		const default_action = NoAction_;
		counters = stats_dst_vtep;
		size = ipv4_dst_vtep_table_size;
	}

	// -------------------------------------
	// Table: IPv6 Dst VTEP
	// -------------------------------------

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
	action dst_vtepv6_hit(
//		switch_bd_t bd,

		bool drop

  #ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
		,
		switch_port_lag_index_t port_lag_index,
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn
  #endif
	) {
		stats_dst_vtepv6.count();

//		ig_md.bd = bd;

//		ig_intr_md_for_dprsr.drop_ctl = drop;
		drop_ = drop;

  #ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
		ig_md.port_lag_index    = port_lag_index;
		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
  #endif
	}

	// -------------------------------------

//	action dst_vtepv6_tunid_hit(
//	) {
//		stats_dst_vtepv6.count();
//	}

	// -------------------------------------

	action NoAction_v6(
	) {
		stats_dst_vtepv6.count();
	}

	// -------------------------------------

	table dst_vtepv6 {
		key = {
#ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
  #ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
    #ifdef INGRESS_PARSER_POPULATES_LKP_0
			lkp_0.ip_src_addr   : ternary @name("src_addr");
    #else
			hdr_0.ipv6.src_addr : ternary @name("src_addr");
    #endif
  #endif
    #ifdef INGRESS_PARSER_POPULATES_LKP_0
			lkp_0.ip_dst_addr   : ternary @name("dst_addr");
    #else
			hdr_0.ipv6.dst_addr : ternary @name("dst_addr");
    #endif
#endif
//			tunnel_0.type       : exact @name("tunnel_type");
			lkp_0.tunnel_type   : exact @name("tunnel_type");
		}

		actions = {
			NoAction_v6;
			dst_vtepv6_hit;
//			dst_vtepv6_tunid_hit;
		}

		const default_action = NoAction_v6;
		counters = stats_dst_vtepv6;
		size = ipv6_dst_vtep_table_size;
	}
#endif

	// -------------------------------------
	// Table: VNI to BD
	// -------------------------------------
/*
    // Tunnel id -> BD Translation
    table vni_to_bd_mapping {
        key = {
			lkp_0.tunnel_id : exact;
		}

        actions = {
            NoAction;
            dst_vtep_hit;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }

	// -------------------------------------
	// -------------------------------------

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
    // Tunnel id -> BD Translation
    table vni_to_bd_mappingv6 {
        key = {
			lkp_0.tunnel_id : exact;
		}

        actions = {
            NoAction;
            dst_vtepv6_hit;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }
#endif
*/
	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
#ifdef TUNNEL_ENABLE
		// outer RMAC lookup for tunnel termination.
//		switch(rmac.apply().action_run) {
//			rmac_hit : {
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
				if (hdr_0.ipv4.isValid()) {
//				if (lkp_0.ip_type == SWITCH_IP_TYPE_IPV4) {
      #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
					src_vtep.apply();
      #endif // ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
					switch(dst_vtep.apply().action_run) {
//						dst_vtep_tunid_hit : {
//							// Vxlan
//							vni_to_bd_mapping.apply();
//						}
						dst_vtep_hit : {
						}
					}

    #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
				} else if (hdr_0.ipv6.isValid()) {
//				} else if (lkp_0.ip_type == SWITCH_IP_TYPE_IPV6) {
      #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
					src_vtepv6.apply();
      #endif // ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
					switch(dst_vtepv6.apply().action_run) {
//						dst_vtepv6_tunid_hit : {
//							// Vxlan
//							vni_to_bd_mappingv6.apply();
//						}
						dst_vtepv6_hit : {
						}
					}

    #endif // if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
				}
  #endif // if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
//			}
//		}

		// --------------------

		if(drop_ == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0x1;
//			ig_intr_md_for_dprsr.drop_ctl = (bit<3>)drop_;
		}

#endif /* TUNNEL_ENABLE */
	}
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Network SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelNetwork(
	inout switch_ingress_metadata_t ig_md,
	inout switch_lookup_fields_t    lkp_0,
	inout switch_header_transport_t hdr_0,

	inout switch_tunnel_metadata_t  tunnel_0
) (
	switch_uint32_t sap_table_size=32w1024
) {

	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

	// -------------------------------------
	// Table: SAP
	// -------------------------------------

#ifdef TRANSPORT_ENABLE
  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE

	action NoAction_ (
	) {
		stats.count();
	}

	action sap_hit (
		bit<SSAP_ID_WIDTH>              sap,
		bit<VPN_ID_WIDTH>               vpn
	) {
		stats.count();

		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
	}

	// ---------------------------------

	table sap {
		key = {
			hdr_0.nsh_type1.sap    : exact @name("sap");

			// tunnel
//			tunnel_0.type          : exact @name("tunnel_type");
//			tunnel_0.id            : exact @name("tunnel_id");
			lkp_0.tunnel_type      : exact @name("tunnel_type");
			lkp_0.tunnel_id        : exact @name("tunnel_id");
		}

		actions = {
			NoAction_;
			sap_hit;
		}

		const default_action = NoAction_;
		counters = stats;
		size = sap_table_size;
	}

  #endif
#endif

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
#ifdef TRANSPORT_ENABLE
  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
		sap.apply();
  #endif
#endif
	}
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Outer SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelOuter(
	inout switch_ingress_metadata_t ig_md,
	inout switch_lookup_fields_t    lkp,
	inout switch_header_transport_t hdr_0,

	in    switch_lookup_fields_t    lkp_2,
	in    switch_header_inner_t     hdr_2,
	inout switch_tunnel_metadata_reduced_t tunnel_2
) (
	switch_uint32_t sap_exm_table_size=32w1024,
	switch_uint32_t sap_tcam_table_size=32w1024
) {
//	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

	// -------------------------------------
	// Table: SAP
	// -------------------------------------

	bool terminate_ = false;
	bool scope_     = false;
/*
	action NoAction_exm (
	) {
		stats_exm.count();
	}

	action sap_exm_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate
	) {
		stats_exm.count();

		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
	}

	// -------------------------------------

	table sap_exm {
		key = {
			hdr_0.nsh_type1.sap : exact @name("sap");

			// l3
			lkp.ip_type         : exact @name("ip_type");
			lkp.ip_src_addr     : exact @name("ip_src_addr");
			lkp.ip_dst_addr     : exact @name("ip_dst_addr");

			// tunnel
			lkp.tunnel_type     : exact @name("tunnel_type");
			lkp.tunnel_id       : exact @name("tunnel_id");
		}

		actions = {
			NoAction_exm;
			sap_exm_hit;
		}

		const default_action = NoAction_exm;
		counters = stats_exm;
		size = sap_exm_table_size;
	}
*/
	// -------------------------------------
	// -------------------------------------

	action NoAction_tcam (
	) {
		stats_tcam.count();
	}

	action sap_tcam_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate
	) {
		stats_tcam.count();

		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
	}

	// -------------------------------------

	table sap_tcam {
		key = {
			hdr_0.nsh_type1.sap : ternary @name("sap");

			// l3
			lkp.ip_type         : ternary @name("ip_type");
			lkp.ip_src_addr     : ternary @name("ip_src_addr");
			lkp.ip_dst_addr     : ternary @name("ip_dst_addr");

			// tunnel
			lkp.tunnel_type     : ternary @name("tunnel_type");
			lkp.tunnel_id       : ternary @name("tunnel_id");
		}

		actions = {
			NoAction_tcam;
			sap_tcam_hit;
		}

		const default_action = NoAction_tcam;
		counters = stats_tcam;
		size = sap_tcam_table_size;
	}

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
	// Apply
	// -------------------------------------

	apply {

//		if(!sap_exm.apply().hit) {
			sap_tcam.apply();
//		}

		if(lkp.next_lyr_valid == true) {
			if(terminate_ == true) {
				ig_md.tunnel_1.terminate           = true;
				if(hdr_0.nsh_type1.scope == 1) {
					ig_md.tunnel_2.terminate           = true;
				}
			}

			if(scope_ == true) {
				if(hdr_0.nsh_type1.scope == 0) {
#ifdef INGRESS_PARSER_POPULATES_LKP_2
					Scoper.apply(
						lkp_2,
//						ig_md.drop_reason_2,

						lkp
					);
#else
					ScoperInner.apply(
						hdr_2,
						tunnel_2,
//						ig_md.drop_reason_2,

						lkp
					);
#endif
				}

//				scope_inc.apply();
				hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Inner SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelInner(
	inout switch_ingress_metadata_t ig_md,
	inout switch_lookup_fields_t    lkp,
	inout switch_header_transport_t hdr_0,

	in    switch_lookup_fields_t    lkp_2,
	in    switch_header_inner_t     hdr_2,
	inout switch_tunnel_metadata_reduced_t tunnel_2
) (
	switch_uint32_t sap_exm_table_size=32w1024,
	switch_uint32_t sap_tcam_table_size=32w1024
) {
	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

	// -------------------------------------
	// Table: SAP
	// -------------------------------------

	bool terminate_ = false;
	bool scope_     = false;

	action NoAction_exm (
	) {
		stats_exm.count();
	}

	action sap_exm_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate
	) {
		stats_exm.count();

		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
	}

	// -------------------------------------

	table sap_exm {
		key = {
			hdr_0.nsh_type1.sap : exact @name("sap");

			// tunnel
			lkp.tunnel_type     : exact @name("tunnel_type");
			lkp.tunnel_id       : exact @name("tunnel_id");
		}

		actions = {
			NoAction_exm;
			sap_exm_hit;
		}

		const default_action = NoAction_exm;
		counters = stats_exm;
		size = sap_exm_table_size;
	}

	// -------------------------------------
	// -------------------------------------

	action NoAction_tcam (
	) {
		stats_tcam.count();
	}

	action sap_tcam_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate
	) {
		stats_tcam.count();

		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
	}

	// -------------------------------------

	table sap_tcam {
		key = {
			hdr_0.nsh_type1.sap : ternary @name("sap");

			// tunnel
			lkp.tunnel_type     : ternary @name("tunnel_type");
			lkp.tunnel_id       : ternary @name("tunnel_id");
		}

		actions = {
			NoAction_tcam;
			sap_tcam_hit;
		}

		const default_action = NoAction_tcam;
		counters = stats_tcam;
		size = sap_tcam_table_size;
	}

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
	// Apply
	// -------------------------------------

	apply {

		if(!sap_exm.apply().hit) {
			sap_tcam.apply();
		}

		if(lkp.next_lyr_valid == true) {
			if(terminate_ == true) {
				ig_md.tunnel_1.terminate           = true;
				if(hdr_0.nsh_type1.scope == 1) {
					ig_md.tunnel_2.terminate           = true;
				}
			}

			if(scope_ == true) {
				if(hdr_0.nsh_type1.scope == 0) {
#ifdef INGRESS_PARSER_POPULATES_LKP_2
					Scoper.apply(
						lkp_2,
//						ig_md.drop_reason_2,

						lkp
					);
#else
					ScoperInner.apply(
						hdr_2,
						tunnel_2,
//						ig_md.drop_reason_2,

						lkp
					);
#endif
				}

//				scope_inc.apply();
				hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Tunnel Decap / Encap Transport
//-----------------------------------------------------------------------------

control TunnelDecapTransportIngress(
	inout switch_header_transport_t hdr_0,
	// ----- current header data -----
//	inout switch_header_transport_t hdr_0,
	in    switch_tunnel_metadata_t tunnel_0,
	// ----- next header data -----
	inout switch_header_outer_t hdr_1,
	in    switch_tunnel_metadata_reduced_t tunnel_1,
	// ----- next header data -----
	inout switch_header_inner_t hdr_2,
	in    switch_tunnel_metadata_reduced_t tunnel_2,
	// ----- next header data -----
	in    switch_header_inner_inner_t hdr_3
) (
	switch_tunnel_mode_t mode
) {
	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
		if(tunnel_0.terminate) {
			// ----- l2 -----
//			// (none -- done in egress)
//			hdr_0.ethernet.setInvalid();
//			hdr_0.vlan_tag[0].setInvalid();

			// ----- l3 / l4 / tunnel -----
			// (none -- instead, we do this by simply not deparsing any transport l3 / 4 / tunnels)

			// ----- fix the next layer's l2, if we had an l3 tunnel -----
  #ifndef FIX_L3_TUN_ALL_AT_ONCE
			if(!hdr_1.ethernet.isValid()) {
				// Pkt doesn't have an l2 header...add one.
				// TODO: Do we need to set da/sa?  If so, what to (perhaps copy it from the transport)?
//				hdr_1.ethernet.dst_addr = hdr_0.ethernet.dst_addr;
//				hdr_1.ethernet.src_addr = hdr_0.ethernet.src_addr;
				if(hdr_1.ipv4.isValid()) {
					hdr_1.ethernet.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.ethernet.ether_type = ETHERTYPE_IPV6;
				}
			}
			hdr_1.ethernet.setValid(); // always set valid (it may already be valid)
  #endif

/*
			if(tunnel_1.terminate && tunnel_2.terminate) {

				// get from inner-inner
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_3.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_3.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			} else if(tunnel_1.terminate) {

				// get from inner
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_2.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_2.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			} else {

				// get from outer
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_1.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_1.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			}
*/

		}
	}
}

//-----------------------------------------------------------------------------

control TunnelEncapTransportIngress(
	inout switch_header_transport_t hdr_0,
	// ----- current header data -----
//  inout switch_header_transport_t hdr_0,
	in    switch_tunnel_metadata_t tunnel_0,
	// ----- next header data -----
	inout switch_header_outer_t hdr_1
) (
	switch_tunnel_mode_t mode
) {

	apply {
/*
		if(tunnel_0.encap) {
			// ----- l2 -----
			// add an ethernet header, for egress parser -- only need to set the etype (not the da/sa)....
			hdr_0.ethernet.setValid();
			hdr_0.ethernet.ether_type = ETHERTYPE_NSH;

			// ----- l3 / l4 / tunnel -----
			// (none -- done in egress)
		}
*/
	}

}

//-----------------------------------------------------------------------------
// Tunnel Decap Outer
//-----------------------------------------------------------------------------

control TunnelDecapOuter(
	// ----- current header data -----
	inout switch_header_outer_t hdr_1,
	in    switch_tunnel_metadata_reduced_t tunnel_1,
	// ----- next header data -----
	inout switch_header_inner_t hdr_2,
	in    switch_tunnel_metadata_reduced_t tunnel_2,
	// ----- next header data -----
	in    switch_header_inner_inner_t hdr_3
) (
	switch_tunnel_mode_t mode
) {
	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {

#ifdef TUNNEL_ENABLE
		if(tunnel_1.terminate) {
			// ----- l2 -----

			// only remove l2 when the next layer's is valid
			if(hdr_2.ethernet.isValid() || (tunnel_2.terminate && hdr_3.ethernet.isValid())) {
				hdr_1.ethernet.setInvalid();

#ifdef ETAG_ENABLE
				hdr_1.e_tag.setInvalid();
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
				hdr_1.vn_tag.setInvalid();
#endif // VNTAG_ENABLE

				hdr_1.vlan_tag[0].setInvalid(); // extreme added
				hdr_1.vlan_tag[1].setInvalid(); // extreme added
			}

			// ----- l2.5 -----
#if defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
			hdr_1.mpls[0].setInvalid();
  #if MPLS_DEPTH > 1
			hdr_1.mpls[1].setInvalid();
  #endif
  #if MPLS_DEPTH > 2
			hdr_1.mpls[2].setInvalid();
  #endif
  #if MPLS_DEPTH > 3
			hdr_1.mpls[3].setInvalid();
  #endif
#endif // defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
#ifdef MPLS_L2VPN_ENABLE
			hdr_1.mpls_pw_cw.setInvalid();
#endif // MPLS_L2VPN_ENABLE

			// ----- l3 -----
			hdr_1.ipv4.setInvalid();
  #ifdef IPV6_ENABLE
			hdr_1.ipv6.setInvalid();
  #endif // IPV6_ENABLE

			// ----- l4 -----
			hdr_1.tcp.setInvalid();
			hdr_1.udp.setInvalid();
			hdr_1.sctp.setInvalid(); // extreme added

			// ----- tunnel -----
  #ifdef VXLAN_ENABLE
			hdr_1.vxlan.setInvalid();
  #endif // VXLAN_ENABLE
			hdr_1.gre.setInvalid();
			hdr_1.gre_optional.setInvalid();
  #ifdef NVGRE_ENABLE
			hdr_1.nvgre.setInvalid();
  #endif // NVGRE_ENABLE
  #ifdef GTP_ENABLE
			hdr_1.gtp_v1_base.setInvalid(); // extreme added
			hdr_1.gtp_v1_optional.setInvalid(); // extreme added
  #endif // GTP_ENABLE

			// ----- fix outer ethertype, if we had an l3 tunnel -----

  #ifndef FIX_L3_TUN_ALL_AT_ONCE
			// this is organized from highest priority to lowest priority
			if(tunnel_2.terminate) {

				// get from inner-inner
				if(hdr_1.vlan_tag[1].isValid()) {
					if(hdr_3.ipv4.isValid()) {
						hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV6;
					}
				} else if(hdr_1.vlan_tag[0].isValid()) {
					if(hdr_3.ipv4.isValid()) {
						hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
    #ifdef VNTAG_ENABLE
				} else if(hdr_1.vn_tag.isValid()) {
					if(hdr_3.ipv4.isValid()) {
						hdr_1.vn_tag.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.vn_tag.ether_type = ETHERTYPE_IPV6;
					}
    #endif // VNTAG_ENABLE
    #ifdef ETAG_ENABLE
				} else if(hdr_1.e_tag.isValid()) {
					if(hdr_3.ipv4.isValid()) {
						hdr_1.e_tag.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.e_tag.ether_type = ETHERTYPE_IPV6;
					}
    #endif // ETAG_ENABLE
				} else {
					if(hdr_3.ipv4.isValid()) {
						hdr_1.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			} else {

				// get from inner
				if(hdr_1.vlan_tag[1].isValid()) {
					if(hdr_2.ipv4.isValid()) {
						hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV6;
					}
				} else if(hdr_1.vlan_tag[0].isValid()) {
					if(hdr_2.ipv4.isValid()) {
						hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
    #ifdef VNTAG_ENABLE
				} else if(hdr_1.vn_tag.isValid()) {
					if(hdr_2.ipv4.isValid()) {
						hdr_1.vn_tag.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.vn_tag.ether_type = ETHERTYPE_IPV6;
					}
    #endif // VNTAG_ENABLE
    #ifdef ETAG_ENABLE
				} else if(hdr_1.e_tag.isValid()) {
					if(hdr_2.ipv4.isValid()) {
						hdr_1.e_tag.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.e_tag.ether_type = ETHERTYPE_IPV6;
					}
    #endif // ETAG_ENABLE
				} else {
					if(hdr_2.ipv4.isValid()) {
						hdr_1.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_1.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			}
  #endif
		}
#endif /* TUNNEL_ENABLE */
	}
}

//-----------------------------------------------------------------------------
// Tunnel Decap Inner
//-----------------------------------------------------------------------------

control TunnelDecapInner(
	// ----- previous header data -----
	inout switch_header_outer_t hdr_1,
	in    switch_tunnel_metadata_reduced_t tunnel_1,
	// ----- current header data -----
	inout switch_header_inner_t hdr_2,
	in    switch_tunnel_metadata_reduced_t tunnel_2,
	// ----- next header data -----
	in    switch_header_inner_inner_t hdr_3
) (
	switch_tunnel_mode_t mode
) {
	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
#ifdef TUNNEL_ENABLE
		if(tunnel_2.terminate) {
			// ----- l2 -----

			// only remove l2 when the next layer's is valid
			if(hdr_3.ethernet.isValid()) {
				hdr_2.ethernet.setInvalid();
				hdr_2.vlan_tag[0].setInvalid(); // extreme added
			}

			// ----- l3 -----
			hdr_2.ipv4.setInvalid();
  #ifdef IPV6_ENABLE
			hdr_2.ipv6.setInvalid();
  #endif

			// ----- l4 -----
			hdr_2.tcp.setInvalid();
			hdr_2.udp.setInvalid();
			hdr_2.sctp.setInvalid(); // extreme added

			// ----- tunnel -----
  #ifdef INNER_GRE_ENABLE
			hdr_2.gre.setInvalid();
			hdr_2.gre_optional.setInvalid();
  #endif
  #ifdef INNER_GTP_ENABLE
			hdr_2.gtp_v1_base.setInvalid(); // extreme added
			hdr_2.gtp_v1_optional.setInvalid(); // extreme added
  #endif

			// ----- fix outer ethertype, if we had an l3 tunnel -----

			// this is organized from highest priority to lowest priority
			if(hdr_2.vlan_tag[0].isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_2.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_2.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
				}
			} else {
				if(hdr_3.ipv4.isValid()) {
					hdr_2.ethernet.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_2.ethernet.ether_type = ETHERTYPE_IPV6;
				}
			}
/*
  #if defined(FIX_L3_TUN_LYR_BY_LYR) && !defined(FIX_L3_TUN_ALL_AT_ONCE)
			// this is organized from highest priority to lowest priority
			if(hdr_1.vlan_tag[1].isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV6;
				}
			} else if(hdr_1.vlan_tag[0].isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
				}
    #ifdef VNTAG_ENABLE
			} else if(hdr_1.vn_tag.isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vn_tag.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vn_tag.ether_type = ETHERTYPE_IPV6;
				}
    #endif
    #ifdef ETAG_ENABLE
			} else if(hdr_1.e_tag.isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.e_tag.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.e_tag.ether_type = ETHERTYPE_IPV6;
				}
    #endif
			} else {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.ethernet.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.ethernet.ether_type = ETHERTYPE_IPV6;
				}
			}
	#endif
*/
		}
#endif /* TUNNEL_ENABLE */
	}
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - L2 Ethertype Fix
//-----------------------------------------------------------------------------

control TunnelDecapFixEthertype(
	// ----- current header data -----
	inout switch_header_outer_t hdr_1,
	in    switch_tunnel_metadata_reduced_t tunnel_1,
	// ----- next header data -----
	inout switch_header_inner_t hdr_2,
	in    switch_tunnel_metadata_reduced_t tunnel_2,
	// ----- next header data -----
	in    switch_header_inner_inner_t hdr_3
) (
) {
	// -------------------------------------
	// Table
	// -------------------------------------

	action fix_l2_decap_hdr_1() {
		hdr_1.ethernet.setInvalid();

#ifdef ETAG_ENABLE
		hdr_1.e_tag.setInvalid();
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
		hdr_1.vn_tag.setInvalid();
#endif // VNTAG_ENABLE

		hdr_1.vlan_tag[0].setInvalid(); // extreme added
		hdr_1.vlan_tag[1].setInvalid(); // extreme added
	}

	action fix_l2_decap_hdr_2() {
		hdr_2.ethernet.setInvalid();
		hdr_2.vlan_tag[0].setInvalid(); // extreme added
	}

  #ifdef FIX_L3_TUN_ALL_AT_ONCE

	action fix_l2_etype_vlan_tag1_v4(bit<16> ether_type) {
		hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV4;
	}

	action fix_l2_etype_vlan_tag0_v4(bit<16> ether_type) {
		hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
	}

	action fix_l2_etype_vn_tag_v4(bit<16> ether_type) {
		hdr_1.vn_tag.ether_type = ETHERTYPE_IPV4;
	}

	action fix_l2_etype_e_tag_v4(bit<16> ether_type) {
		hdr_1.e_tag.ether_type = ETHERTYPE_IPV4;
	}

	action fix_l2_etype_eth_v4(bit<16> ether_type) {
		hdr_1.ethernet.ether_type = ETHERTYPE_IPV4;

		hdr_1.ethernet.setValid(); // always set valid (it may already be valid)
	}

	// -----------------------------------

	action fix_l2_etype_vlan_tag1_v6(bit<16> ether_type) {
		hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV6;
	}

	action fix_l2_etype_vlan_tag0_v6(bit<16> ether_type) {
		hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
	}

	action fix_l2_etype_vn_tag_v6(bit<16> ether_type) {
		hdr_1.vn_tag.ether_type = ETHERTYPE_IPV6;
	}

	action fix_l2_etype_e_tag_v6(bit<16> ether_type) {
		hdr_1.e_tag.ether_type = ETHERTYPE_IPV6;
	}

	action fix_l2_etype_eth_v6(bit<16> ether_type) {
		hdr_1.ethernet.ether_type = ETHERTYPE_IPV6;

		hdr_1.ethernet.setValid(); // always set valid (it may already be valid)
	}

	// -----------------------------------

	table fix_l2_etype {
		key = {
			tunnel_1.terminate          : ternary;
			tunnel_2.terminate          : ternary;

			hdr_1.ethernet.isValid()    : ternary;
			hdr_1.e_tag.isValid()       : ternary;
			hdr_1.vn_tag.isValid()      : ternary;
			hdr_1.vlan_tag[0].isValid() : ternary;
			hdr_1.vlan_tag[1].isValid() : ternary;
			hdr_1.ipv4.isValid()        : ternary;

			hdr_2.ethernet.isValid()    : ternary;
			hdr_2.ipv4.isValid()        : ternary;

			hdr_3.ethernet.isValid()    : ternary;
			hdr_3.ipv4.isValid()        : ternary;
		}
		actions = {
			NoAction;

			fix_l2_etype_eth_v4;
			fix_l2_etype_e_tag_v4;
			fix_l2_etype_vn_tag_v4;
			fix_l2_etype_vlan_tag0_v4;
			fix_l2_etype_vlan_tag1_v4;

			fix_l2_etype_eth_v6;
			fix_l2_etype_e_tag_v6;
			fix_l2_etype_vn_tag_v6;
			fix_l2_etype_vlan_tag0_v6;
			fix_l2_etype_vlan_tag1_v6;

			fix_l2_decap_hdr_1;
			fix_l2_decap_hdr_2;
		}
		const entries = {
			// a priority encoder

			// -----------   -----------------------------------------   -------------   -------------
			// Terminates    Hdr 1                                       Hdr 2           Hdr 3
			// -----------   -----------------------------------------   -------------   -------------
			// 0 terminates (fix hdr1's l2 etype, based on hdr1's ip type)
			(false, false,   false, _,     _,     _,     _,     true,    _,     _,       _,     _    ) : fix_l2_etype_eth_v4(ETHERTYPE_IPV4);      // do   check for eth true
			(false, false,   false, _,     _,     _,     _,     false,   _,     _,       _,     _    ) : fix_l2_etype_eth_v6(ETHERTYPE_IPV6);      // do   check for eth true

			// 0 terminates (rm  hdr1's l2, since hdr2 has one)
			(false, false,   true,  _,     _,     _,     _,     _,       _,     _,       _,     _    ) : NoAction        ();                       // do   check for eth true

			// 1 terminate  (fix hdr1's l2 etype, based on hdr2's ip type)
			(true,  false,   _,     _,     _,     _,     true,  _,       false, true,    _,     _    ) : fix_l2_etype_vlan_tag1_v4(ETHERTYPE_IPV4);
			(true,  false,   _,     _,     _,     _,     true,  _,       false, false,   _,     _    ) : fix_l2_etype_vlan_tag1_v6(ETHERTYPE_IPV6);
			(true,  false,   _,     _,     _,     true,  false, _,       false, true,    _,     _    ) : fix_l2_etype_vlan_tag0_v4(ETHERTYPE_IPV4);
			(true,  false,   _,     _,     _,     true,  false, _,       false, false,   _,     _    ) : fix_l2_etype_vlan_tag0_v6(ETHERTYPE_IPV6);
			(true,  false,   _,     _,     true,  false, false, _,       false, true,    _,     _    ) : fix_l2_etype_vn_tag_v4(ETHERTYPE_IPV4);
			(true,  false,   _,     _,     true,  false, false, _,       false, false,   _,     _    ) : fix_l2_etype_vn_tag_v6(ETHERTYPE_IPV6);
			(true,  false,   _,     true,  false, false, false, _,       false, true,    _,     _    ) : fix_l2_etype_e_tag_v4(ETHERTYPE_IPV4);
			(true,  false,   _,     true,  false, false, false, _,       false, false,   _,     _    ) : fix_l2_etype_e_tag_v6(ETHERTYPE_IPV6);
			(true,  false,   _,     false, false, false, false, _,       false, true,    _,     _    ) : fix_l2_etype_eth_v4(ETHERTYPE_IPV4);      // don't check for eth true...it might not be
			(true,  false,   _,     false, false, false, false, _,       false, false,   _,     _    ) : fix_l2_etype_eth_v6(ETHERTYPE_IPV6);      // don't check for eth true...it might not be

			// 1 terminate  (rm  hdr1's l2, since hdr2 has one)
			(true,  false,   _,     _,     _,     _,     _,     _,       true,  _,       _,     _    ) : fix_l2_decap_hdr_1();                     // don't check for eth true...it might not be

			// 2 terminates (fix hdr1's l2 etype, based on hdr3's ip type)
			(true,  true,    _,     _,     _,     _,     true,  _,       _,     _,       false, true ) : fix_l2_etype_vlan_tag1_v4(ETHERTYPE_IPV4);
			(true,  true,    _,     _,     _,     _,     true,  _,       _,     _,       false, false) : fix_l2_etype_vlan_tag1_v6(ETHERTYPE_IPV6);
			(true,  true,    _,     _,     _,     true,  false, _,       _,     _,       false, true ) : fix_l2_etype_vlan_tag0_v4(ETHERTYPE_IPV4);
			(true,  true,    _,     _,     _,     true,  false, _,       _,     _,       false, false) : fix_l2_etype_vlan_tag0_v6(ETHERTYPE_IPV6);
			(true,  true,    _,     _,     true,  false, false, _,       _,     _,       false, true ) : fix_l2_etype_vn_tag_v4(ETHERTYPE_IPV4);
			(true,  true,    _,     _,     true,  false, false, _,       _,     _,       false, false) : fix_l2_etype_vn_tag_v6(ETHERTYPE_IPV6);
			(true,  true,    _,     true,  false, false, false, _,       _,     _,       false, true ) : fix_l2_etype_e_tag_v4(ETHERTYPE_IPV4);
			(true,  true,    _,     true,  false, false, false, _,       _,     _,       false, false) : fix_l2_etype_e_tag_v6(ETHERTYPE_IPV6);
			(true,  true,    _,     false, false, false, false, _,       _,     _,       false, true ) : fix_l2_etype_eth_v4(ETHERTYPE_IPV4);      // don't check for eth true...it might not be
			(true,  true,    _,     false, false, false, false, _,       _,     _,       false, false) : fix_l2_etype_eth_v6(ETHERTYPE_IPV6);      // don't check for eth true...it might not be

			// 2 terminates (rm  hdr1's l2, since hdr3 has one)
			(true,  true,    _,     _,     _,     _,     _,     _,       _,     _,       true,  _    ) : fix_l2_decap_hdr1();                      // don't check for eth true...it might not be
		}
		const default_action = NoAction;
	}
  #endif

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply{
  #ifdef FIX_L3_TUN_ALL_AT_ONCE
		fix_l2_etype.apply();
  #endif
	}
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - Scope Decrement
//-----------------------------------------------------------------------------

control TunnelDecapScopeDecrement (
	inout bool terminate_a,
	inout bool terminate_b,
	inout switch_header_transport_t hdr_0
) {

	action new_scope(bit<8> scope_new) {
		hdr_0.nsh_type1.scope = scope_new;
//		terminate_a = false;
//		terminate_b = false;
	}

	table scope_dec {
		key = {
			hdr_0.nsh_type1.scope : exact;
			terminate_a : exact;
			terminate_b : exact;
		}
		actions = {
			NoAction;
			new_scope;
		}
		const entries = {
			// no decrement
			(0, false, false) : new_scope(0);
			(1, false, false) : new_scope(1);
			(2, false, false) : new_scope(2);
			(3, false, false) : new_scope(3);
			// decrement by one
			(0, true,  false) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
			(1, true,  false) : new_scope(0);
			(2, true,  false) : new_scope(1);
			(3, true,  false) : new_scope(2);
			// decrement by one (these should never occur)
			(0, false, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
			(1, false, true ) : new_scope(0);
			(2, false, true ) : new_scope(1);
			(3, false, true ) : new_scope(2);
			// decrement by two
			(0, true,  true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
			(1, true,  true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
			(2, true,  true ) : new_scope(0);
			(3, true,  true ) : new_scope(1);
		}
		const default_action = NoAction;
	}

	// -------------------------

	apply {
		scope_dec.apply();
	}
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

control TunnelRewrite(
	inout switch_header_transport_t hdr_0,
	inout switch_egress_metadata_t eg_md,
	in    switch_tunnel_metadata_t tunnel
) (
	switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024,
	switch_uint32_t ipv6_dst_addr_rewrite_table_size=1024,
	switch_uint32_t nexthop_rewrite_table_size=512,
	switch_uint32_t src_addr_rewrite_table_size=1024,
	switch_uint32_t smac_rewrite_table_size=1024
) {

	EgressBd(BD_TABLE_SIZE) egress_bd;
	switch_smac_index_t smac_index;

	// -------------------------------------
	// Table: Nexthop Rewrite (DMAC & BD)
	// -------------------------------------

//	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_nexthop;  // direct counter

	// Outer nexthop rewrite
	action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
//		stats_nexthop.count();

		eg_md.bd = bd;
		hdr_0.ethernet.dst_addr = dmac;
	}

	action no_action_nexthop() {
//		stats_nexthop.count();

	}

	table nexthop_rewrite {
		key = {
			eg_md.outer_nexthop : exact;
		}

		actions = {
			no_action_nexthop;
			rewrite_tunnel;
		}

		const default_action = no_action_nexthop;
		size = nexthop_rewrite_table_size;
//		counters = stats_nexthop;
	}

	// -------------------------------------
	// Table: SIP Rewrite
	// -------------------------------------

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_src_addr;  // direct counter

	// Tunnel source IP rewrite
	action rewrite_ipv4_src(ipv4_addr_t src_addr) {
		stats_src_addr.count();

#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
		hdr_0.ipv4.src_addr = src_addr;
#endif
	}

	action rewrite_ipv6_src(ipv6_addr_t src_addr) {
		stats_src_addr.count();

#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V6)
		hdr_0.ipv6.src_addr = src_addr;
#endif
	}

	table src_addr_rewrite {
		key = { eg_md.bd : exact; }
		actions = {
			rewrite_ipv4_src;
			rewrite_ipv6_src;
		}

		size = src_addr_rewrite_table_size;
		counters = stats_src_addr;
	}

	// -------------------------------------
	// Table: DIP Rewrite
	// -------------------------------------

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_ipv4_dst_addr;  // direct counter
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_ipv6_dst_addr;  // direct counter

	// Tunnel destination IP rewrite
#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V4
	action rewrite_ipv4_dst(ipv4_addr_t dst_addr) {
		stats_ipv4_dst_addr.count();

		hdr_0.ipv4.dst_addr = dst_addr;
	}
#endif

#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
	action rewrite_ipv6_dst(ipv6_addr_t dst_addr) {
		stats_ipv6_dst_addr.count();

		hdr_0.ipv6.dst_addr = dst_addr;
	}
#endif

#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
	table ipv4_dst_addr_rewrite {
		key = { tunnel.index : exact; }
		actions = { rewrite_ipv4_dst; }
//		const default_action = rewrite_ipv4_dst(0); // extreme modified!
		size = ipv4_dst_addr_rewrite_table_size;
		counters = stats_ipv4_dst_addr;
	}
#endif

#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
	table ipv6_dst_addr_rewrite {
		key = { tunnel.index : exact; }
		actions = { rewrite_ipv6_dst; }
//		const default_action = rewrite_ipv6_dst(0); // extreme modified!
		size = ipv6_dst_addr_rewrite_table_size;
		counters = stats_ipv6_dst_addr;
	}
#endif

	// -------------------------------------
	// Table: SMAC Rewrite
	// -------------------------------------

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_smac_rewrite;  // direct counter

	// Tunnel source MAC rewrite
	action rewrite_smac(mac_addr_t smac) {
		stats_smac_rewrite.count();

		hdr_0.ethernet.src_addr = smac;
	}

	action no_action_smac() {
		stats_smac_rewrite.count();

	}

	table smac_rewrite {
		key = { smac_index : exact; }
		actions = {
			no_action_smac;
			rewrite_smac;
		}

		const default_action = no_action_smac;
		size = smac_rewrite_table_size;
		counters = stats_smac_rewrite;
	}

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
#ifdef TUNNEL_ENABLE
		if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
			nexthop_rewrite.apply();

		if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
			egress_bd.apply(hdr_0, eg_md.bd, eg_md.pkt_src,
				smac_index);

#if defined(ERSPAN_TRANSPORT_EGRESS_ENABLE) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V6)
		if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
			src_addr_rewrite.apply();

		if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
  #if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
			if (hdr_0.ipv4.isValid()) {
				ipv4_dst_addr_rewrite.apply();
			 }
  #endif
  #if (defined(ERSPAN_TRANSPORT_EGRESS_ENABLE) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V4)) && (defined(GRE_TRANSPORT_EGRESS_ENABLE_V6))
			else
  #endif
  #if defined(GRE_TRANSPORT_EGRESS_ENABLE_V6)
			if (hdr_0.ipv6.isValid()) {
				ipv6_dst_addr_rewrite.apply();
			}
  #endif
		}
#endif /* ERSPAN_TRANSPORT_EGRESS_ENABLE */

		smac_rewrite.apply();
#endif /* TUNNEL_ENABLE */
	}
}

//-----------------------------------------------------------------------------
// Tunnel encapsulation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param mode :  Specify the model for tunnel encapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying into the outer header on encapsulation. This results in 'normal'
// behaviour for ECN field (See RFC 6040 secion 4.1). In the PIPE model, outer header ttl and dscp
// fields are independent of that in the inner header and are set to user-defined values on
// encapsulation.
// @param vni_mapping_table_size : Number of VNIs.
//
//-----------------------------------------------------------------------------

control TunnelEncap(
	inout switch_header_transport_t hdr_0,
	inout switch_header_outer_t hdr_1,
	inout switch_header_inner_t hdr_2,
	inout switch_header_inner_inner_t hdr_3,
	inout switch_egress_metadata_t eg_md,
	inout switch_tunnel_metadata_t tunnel_0,
	inout switch_tunnel_metadata_reduced_t tunnel_1,
	inout switch_tunnel_metadata_reduced_t tunnel_2
) (
	switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
	switch_uint32_t vni_mapping_table_size=1024
) {

	bit<16> payload_len;
	bit<16> gre_proto;

	//=============================================================================
	// Table #0: VRF to VNI Mapping
	//=============================================================================
/*
	action set_vni(switch_tunnel_id_t id) {
		tunnel_0.id = id;
	}

	table vrf_to_vni_mapping {
		key = { eg_md.vrf : exact; }

		actions = {
			NoAction;
			set_vni;
		}

		size = vni_mapping_table_size;
	}
*/
	//=============================================================================
	// Table #1: Copy L3/4 Outer -> Inner
	//=============================================================================

	action rewrite_inner_ipv4_lkp1() {
		payload_len = hdr_1.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	// --------------------------------
#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V6)
	action rewrite_inner_ipv6_lkp1() {
		payload_len = hdr_1.ipv6.payload_len + 16w40;
		gre_proto = GRE_PROTOCOLS_IPV6;
	}

#endif  /* GRE_TRANSPORT_EGRESS_ENABLE_V6 */
	// --------------------------------

	table encap_outer {
		key = {
			hdr_1.ipv4.isValid() : exact;
#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
			hdr_1.ipv6.isValid() : exact;
#endif  /* GRE_TRANSPORT_EGRESS_ENABLE_V6 */
			hdr_1.udp.isValid() : exact;
			// hdr_1.tcp.isValid() : exact;
		}

		actions = {
			rewrite_inner_ipv4_lkp1;
//			rewrite_inner_ipv4_unknown;
#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
			rewrite_inner_ipv6_lkp1;
//			rewrite_inner_ipv6_unknown;
#endif  /* GRE_TRANSPORT_EGRESS_ENABLE_V6 */
		}

		const entries = {
#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
			(true,  false, false) : rewrite_inner_ipv4_lkp1();
			(false, true,  false) : rewrite_inner_ipv6_lkp1();
			(true,  false, true ) : rewrite_inner_ipv4_lkp1();
			(false, true,  true ) : rewrite_inner_ipv6_lkp1();
#else
			(true,         false) : rewrite_inner_ipv4_lkp1();
			(true,         true ) : rewrite_inner_ipv4_lkp1();
#endif  /* GRE_TRANSPORT_EGRESS_ENABLE_V6 */
		}
	}

	//=============================================================================
	// Table #2: Copy L2 Outer -> Inner (Writes Tunnel header, rewrites some of Outer)
	//=============================================================================

	//-----------------------------------------------------------------------------
	// Helper actions to add various headers.
	//-----------------------------------------------------------------------------

	// there is no UDP supported in the transport
	// action add_udp_header(bit<16> src_port, bit<16> dst_port) {
	//     hdr_0.udp.setValid();
	//     hdr_0.udp.src_port = src_port;
	//     hdr_0.udp.dst_port = dst_port;
	//     hdr_0.udp.checksum = 0;
	//     // hdr_0.udp.length = 0;
	// }

	// -------------------------------------
	// Extreme Networks - Modified
	// -------------------------------------

	action add_gre_header(bit<16> proto, bit<1> K, bit<1> S) {
#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
		hdr_0.gre.setValid();
		hdr_0.gre.proto = proto;
		hdr_0.gre.C = 0;
		hdr_0.gre.R = 0;
		hdr_0.gre.K = K;
		hdr_0.gre.S = S;
		hdr_0.gre.s = 0;
		hdr_0.gre.recurse = 0;
		hdr_0.gre.flags = 0;
		hdr_0.gre.version = 0;
#endif
	}

	// -------------------------------------
	// Extreme Networks - Added
	// -------------------------------------

	action add_gre_header_seq() {
#ifdef ERSPAN_TRANSPORT_EGRESS_ENABLE
		hdr_0.gre_sequence.setValid();
		hdr_0.gre_sequence.seq_num = 0;
#endif
	}

	action add_l2_header(bit<16> ethertype) {
		hdr_0.ethernet.setValid();
		hdr_0.ethernet.ether_type = ethertype;
	}

	// -------------------------------------

	action add_erspan_header_type2(switch_mirror_session_t session_id) {
#ifdef ERSPAN_TRANSPORT_EGRESS_ENABLE
		hdr_0.erspan_type2.setValid();
		hdr_0.erspan_type2.version = 4w0x1;
		hdr_0.erspan_type2.vlan = 0;
		hdr_0.erspan_type2.cos_en_t = 0;
		hdr_0.erspan_type2.session_id = (bit<10>) 0;
//		hdr_0.erspan_type2.reserved = 0;
//		hdr_0.erspan_type2.index = 0;
#endif
	}

	// action add_erspan_header(bit<32> timestamp, switch_mirror_session_t session_id) {
	// 	hdr_0.erspan_type3.setValid();
	// 	hdr_0.erspan_type3.timestamp = timestamp;
	// 	hdr_0.erspan_type3.session_id = (bit<10>) session_id;
	// 	hdr_0.erspan_type3.version = 4w0x2;
	// 	hdr_0.erspan_type3.sgt = 0;
	// 	hdr_0.erspan_type3.vlan = 0;
	// }

	// -------------------------------------

	action add_ipv4_header(bit<8> proto, bit<3> flags) {
#if defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_EGRESS_ENABLE)
		hdr_0.ipv4.setValid();
		hdr_0.ipv4.version = 4w4;
		hdr_0.ipv4.ihl = 4w5;
		// hdr_0.ipv4.total_len = 0;
		hdr_0.ipv4.identification = 0;
		hdr_0.ipv4.flags = flags; // derek: was 0 originally, but request came in to set 'don't frag' bit
		hdr_0.ipv4.frag_offset = 0;
		hdr_0.ipv4.protocol = proto;
		// hdr_0.ipv4.src_addr = 0;
		// hdr_0.ipv4.dst_addr = 0;

		if (mode == switch_tunnel_mode_t.UNIFORM) {
			// NoAction.
		} else if (mode == switch_tunnel_mode_t.PIPE) {
			hdr_0.ipv4.ttl = 8w64;
			hdr_0.ipv4.tos = 0;
		}
#endif
	}

	action add_ipv6_header(bit<8> proto) {
#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
		hdr_0.ipv6.setValid();
		hdr_0.ipv6.version = 4w6;
		hdr_0.ipv6.flow_label = 0;
		// hdr_0.ipv6.payload_len = 0;
		hdr_0.ipv6.next_hdr = proto;
		// hdr_0.ipv6.src_addr = 0;
		// hdr_0.ipv6.dst_addr = 0;

		if (mode == switch_tunnel_mode_t.UNIFORM) {
			// NoAction.
		} else if (mode == switch_tunnel_mode_t.PIPE) {
			hdr_0.ipv6.hop_limit = 8w64;
			hdr_0.ipv6.tos = 0; // derek was "traffic_class"
		}
#endif
	}

	//-----------------------------------------------------------------------------
	// Actual actions.
	//-----------------------------------------------------------------------------

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;  // direct counter

	// =====================================
	// ----- Rewrite, IPv4 Stuff -----
	// =====================================

	action rewrite_ipv4_gre() {
		stats.count();

#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V4
		// ----- l2 -----
		add_l2_header(ETHERTYPE_IPV4);

		// ----- l3 -----
		add_ipv4_header(IP_PROTOCOLS_GRE, 2);
		// Total length = packet length + 24
		//   IPv4 (20) + GRE (4)
		hdr_0.ipv4.total_len = payload_len + 16w24;

		// ----- tunnel -----
		add_gre_header(gre_proto, 0, 0);

		hdr_1.ethernet.setInvalid();
		hdr_1.e_tag.setInvalid();
		hdr_1.vn_tag.setInvalid();
		hdr_1.vlan_tag[0].setInvalid();
		hdr_1.vlan_tag[1].setInvalid();
#if defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
		hdr_1.mpls[0].setInvalid();
  #if MPLS_DEPTH > 1
		hdr_1.mpls[1].setInvalid();
  #endif
  #if MPLS_DEPTH > 2
		hdr_1.mpls[2].setInvalid();
  #endif
  #if MPLS_DEPTH > 3
		hdr_1.mpls[3].setInvalid();
  #endif
#endif // defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
#ifdef MPLS_L2VPN_ENABLE
		hdr_1.mpls_pw_cw.setInvaid();
#endif // MPLS_L2VPN_ENABLE
#endif
	}

	action rewrite_ipv4_erspan(switch_mirror_session_t session_id) {
		stats.count();

#ifdef ERSPAN_TRANSPORT_EGRESS_ENABLE
		// ----- l2 -----
		add_l2_header(ETHERTYPE_IPV4);

		// ----- l3 -----
		add_ipv4_header(IP_PROTOCOLS_GRE, 2);
		// Total length = packet length + 36
		//   IPv4 (20) + GRE (4) + ERSPAN (12)
		hdr_0.ipv4.total_len = payload_len + 16w50; // 20 V4 + 8 GRE + 8 ERSPAN + 14 ETHERNET

		// ----- tunnel -----
		add_gre_header(GRE_PROTOCOLS_ERSPAN_TYPE_2, 0, 1);
		add_gre_header_seq();
		add_erspan_header_type2(session_id);
#endif /* ERSPAN_TRANSPORT_EGRESS_ENABLE */
	}

	// =====================================
	// ----- Rewrite, IPv6 Stuff -----
	// =====================================

	action rewrite_ipv6_gre() {
		stats.count();

#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
		// ----- l2 -----
		add_l2_header(ETHERTYPE_IPV6);

		// ----- l3 -----
//		hdr_0.inner_ethernet = hdr_0.ethernet;
		add_ipv6_header(IP_PROTOCOLS_GRE);
		// Payload length = packet length + 8
		//   GRE (4)
		hdr_0.ipv6.payload_len = payload_len + 16w4;

		// ----- tunnel -----
		add_gre_header(gre_proto, 0, 0);

		hdr_1.ethernet.setInvalid();
		hdr_1.e_tag.setInvalid();
		hdr_1.vn_tag.setInvalid();
		hdr_1.vlan_tag[0].setInvalid();
		hdr_1.vlan_tag[1].setInvalid();
#if defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
		hdr_1.mpls[0].setInvalid();
  #if MPLS_DEPTH > 1
		hdr_1.mpls[1].setInvalid();
  #endif
  #if MPLS_DEPTH > 2
		hdr_1.mpls[2].setInvalid();
  #endif
  #if MPLS_DEPTH > 3
		hdr_1.mpls[3].setInvalid();
  #endif
#endif // defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
#ifdef MPLS_L2VPN_ENABLE
		hdr_1.mpls_pw_cw.setInvaid();
#endif // MPLS_L2VPN_ENABLE
#endif
	}
/*
	action rewrite_ipv6_erspan(switch_mirror_session_t session_id) {
		stats.count();

		// ----- l2 -----
		add_l2_header(ETHERTYPE_IPV6);
		// ----- l3 -----
//		hdr_0.inner_ethernet = hdr_0.ethernet;
		add_ipv6_header(IP_PROTOCOLS_GRE);
		// Payload length = packet length + 8
		//   GRE (4)
		hdr_0.ipv6.payload_len = payload_len + 16w30; // 8 GRE + 8 ERSPAN + 14 ETHERNET

		// ----- tunnel -----
		add_gre_header(GRE_PROTOCOLS_ERSPAN_TYPE_2, 0, 1);
		add_gre_header_seq();
		add_erspan_header_type2(session_id);
	}
*/
	// -------------------------------------
	// Extreme Networks - Added
	// -------------------------------------

	action rewrite_mac_in_mac() {
		stats.count();

		add_l2_header(ETHERTYPE_NSH);
	}

	// -------------------------------------

	action no_action() {
		stats.count();

	}

	// -------------------------------------

	table tunnel {
		key = {
			tunnel_0.type : exact @name("tunnel_.type"); // name change for backwards compatibility
		}

		actions = {
			no_action;

			rewrite_mac_in_mac;           // extreme added
			rewrite_ipv4_gre;             // extreme added
			rewrite_ipv6_gre;             // extreme added
			rewrite_ipv4_erspan;          // extreme added
//			rewrite_ipv6_erspan;          // extreme added
		}

		const default_action = no_action;
		counters = stats;
	}

	//=============================================================================
	// Apply
	//=============================================================================

	apply {
#ifdef TUNNEL_ENABLE
		if (tunnel_0.type != SWITCH_TUNNEL_TYPE_NONE && tunnel_0.id == 0) {
//			vrf_to_vni_mapping.apply(); // Derek: since tunnel.id is only used by vxlan, getting rid of this table (for now, anyway).
		}

		if (tunnel_0.type != SWITCH_TUNNEL_TYPE_NONE) {
			// Copy L3/L4 header into inner headers.
			encap_outer.apply();

			// Add outer L3/L4/Tunnel headers.
			tunnel.apply();
		}
#endif /* TUNNEL_ENABLE */
	}
}

#endif
