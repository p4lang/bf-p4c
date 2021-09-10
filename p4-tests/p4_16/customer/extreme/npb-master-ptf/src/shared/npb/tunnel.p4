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
/*
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
*/
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
//		switch_port_lag_index_t port_lag_index,
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn
	) {
		stats_src_vtep.count();

//		ig_md.port_lag_index    = port_lag_index;
		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
	}

	// -------------------------------------

	action src_vtep_miss(
	) {
		stats_src_vtep.count();
	}

	// -------------------------------------

	table src_vtep {
		key = {
			// l3
			lkp_0.ip_src_addr_v4    : ternary @name("src_addr");

			// tunnel
//			tunnel_0.type           : ternary @name("tunnel_type");
			lkp_0.tunnel_type       : ternary @name("tunnel_type");
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
//		switch_port_lag_index_t port_lag_index,
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn
	) {
		stats_src_vtepv6.count();

//		ig_md.port_lag_index    = port_lag_index;
		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
	}

	// -------------------------------------

	action src_vtepv6_miss(
	) {
		stats_src_vtepv6.count();
	}

	// -------------------------------------

	table src_vtepv6 {
		key = {
			// l3
			lkp_0.ip_src_addr   : ternary @name("src_addr");

			// tunnel
//			tunnel_0.type       : ternary @name("tunnel_type");
			lkp_0.tunnel_type   : ternary @name("tunnel_type");
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
//		switch_port_lag_index_t port_lag_index,
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn
  #endif
//		,
//		bit<24>                    spi,
//		bit<8>                     si,
//		bit<8>                     si_predec
		,
		bool mirror_enable,
        switch_mirror_session_t mirror_session_id,
        switch_mirror_meter_id_t mirror_meter_index, // derek added
		switch_cpu_reason_t cpu_reason_code // derek added
	) {
		stats_dst_vtep.count();

//		ig_md.bd = bd;

//		ig_intr_md_for_dprsr.drop_ctl = drop;
		drop_ = drop;

  #ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
//		ig_md.port_lag_index    = port_lag_index;
		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
  #endif
//		ig_md.nsh_md.spi     = spi;
//		ig_md.nsh_md.si      = si;
//		ig_md.nsh_md.si_predec  = si_predec;

		if(mirror_enable) {
			ig_md.mirror.type = SWITCH_MIRROR_TYPE_PORT;
			ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
			ig_md.mirror.session_id = mirror_session_id;
#ifdef MIRROR_METER_ENABLE
			ig_md.mirror.meter_index = mirror_meter_index; // derek added
#endif
			ig_md.cpu_reason = cpu_reason_code; // derek added
		}
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
#ifndef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
			ig_md.nsh_md.sap        : ternary @name("sap");
#endif
			// l3
#ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
//			lkp_0.ip_src_addr       : ternary @name("src_addr");
			lkp_0.ip_src_addr_v4    : ternary @name("src_addr");
  #else
			lkp_0.ip_src_addr_v4    : ternary @name("src_addr");
  #endif
#endif
			lkp_0.ip_type           : ternary @name("type");
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
//			lkp_0.ip_dst_addr       : ternary @name("dst_addr");
			lkp_0.ip_dst_addr_v4    : ternary @name("dst_addr");
  #else
			lkp_0.ip_dst_addr_v4    : ternary @name("dst_addr");
  #endif
			lkp_0.ip_proto          : ternary @name("proto");

			// l4
//#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			lkp_0.l4_src_port       : ternary @name("src_port");
			lkp_0.l4_dst_port       : ternary @name("dst_port");
//#endif
			// tunnel
			lkp_0.tunnel_type       : ternary @name("tunnel_type");
#ifndef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
			lkp_0.tunnel_id         : ternary @name("tunnel_id");
#endif
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
//		switch_port_lag_index_t port_lag_index,
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn
//		,
//		bit<24>                    spi,
//		bit<8>                     si,
//		bit<8>                     si_predec
		,
		bool mirror_enable,
        switch_mirror_session_t mirror_session_id,
        switch_mirror_meter_id_t mirror_meter_index, // derek added
		switch_cpu_reason_t cpu_reason_code // derek added
  #endif
	) {
		stats_dst_vtepv6.count();

//		ig_md.bd = bd;

//		ig_intr_md_for_dprsr.drop_ctl = drop;
		drop_ = drop;

  #ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
//		ig_md.port_lag_index    = port_lag_index;
		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
  #endif
//		ig_md.nsh_md.spi     = spi;
//		ig_md.nsh_md.si      = si;
//		ig_md.nsh_md.si_predec  = si_predec;

		if(mirror_enable) {
			ig_md.mirror.type = SWITCH_MIRROR_TYPE_PORT;
			ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
			ig_md.mirror.session_id = mirror_session_id;
#ifdef MIRROR_METER_ENABLE
			ig_md.mirror.meter_index = mirror_meter_index; // derek added
#endif
			ig_md.cpu_reason = cpu_reason_code; // derek added
		}
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
#ifndef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
			ig_md.nsh_md.sap        : ternary @name("sap");
#endif
			// l3
#ifdef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
			lkp_0.ip_src_addr       : ternary @name("src_addr");
#endif
			lkp_0.ip_type           : ternary @name("ip_type");
			lkp_0.ip_dst_addr       : ternary @name("dst_addr");
			lkp_0.ip_proto          : ternary @name("proto");

			// l4
//#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			lkp_0.l4_src_port       : ternary @name("src_port");
			lkp_0.l4_dst_port       : ternary @name("dst_port");
//#endif
			// tunnel
			lkp_0.tunnel_type       : ternary @name("tunnel_type");
#ifndef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
			lkp_0.tunnel_id         : ternary @name("tunnel_id");
#endif
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
#endif // if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)

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
/*
		// outer RMAC lookup for tunnel termination.
//		switch(rmac.apply().action_run) {
//			rmac_hit : {
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4)
    #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
				if (hdr_0.ipv4.isValid()) {
//				if (lkp_0.ip_type == SWITCH_IP_TYPE_IPV4) {
    #endif
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

				}
    #endif // if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
  #endif // if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4)
//			}
//		}
*/

		switch(dst_vtep.apply().action_run) {
//			dst_vtep_tunid_hit : {
//				// Vxlan
//				vni_to_bd_mapping.apply();
//			}
			dst_vtep_hit : {
			}
		}

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
	inout switch_header_transport_t hdr_0
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

		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
	}

	// ---------------------------------

	table sap {
		key = {
			ig_md.nsh_md.sap    : exact @name("sap");

			// tunnel
//			ig_md.tunnel_0.type    : exact @name("tunnel_type");
//			ig_md.tunnel_0.id      : exact @name("tunnel_id");
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
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, // extreme added

	inout bool scope_,
	inout bool terminate_
) (
	switch_uint32_t sap_exm_table_size=32w1024,
	switch_uint32_t sap_tcam_table_size=32w1024
) {
//	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

	// -------------------------------------
	// Table: SAP
	// -------------------------------------

//	bool terminate_ = false;
//	bool scope_     = false;
	bool drop_      = false;
/*
	action NoAction_exm (
	) {
		stats_exm.count();
	}

	action sap_exm_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate,
		bool               drop
//		,
//		bit<24>                    spi,
//		bit<8>                     si,
//		bit<8>                     si_predec
	) {
		stats_exm.count();

		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
		drop_                   = drop;
//		ig_md.nsh_md.spi     = spi;
//		ig_md.nsh_md.si      = si;
//		ig_md.nsh_md.si_predec  = si_predec;
	}

	// -------------------------------------

	table sap_exm {
		key = {
			ig_md.nsh_md.sap : exact @name("sap");

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
		bool               terminate,
		bool               drop
//		,
//		bit<24>                    spi,
//		bit<8>                     si,
//		bit<8>                     si_predec
	) {
		stats_tcam.count();

		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
		drop_                   = drop;
//		ig_md.nsh_md.spi     = spi;
//		ig_md.nsh_md.si      = si;
//		ig_md.nsh_md.si_predec  = si_predec;
	}

	// -------------------------------------

	table sap_tcam {
		key = {
			ig_md.nsh_md.sap : ternary @name("sap");

			// l3
			lkp.ip_type         : ternary @name("ip_type");
			lkp.ip_src_addr     : ternary @name("ip_src_addr");
			lkp.ip_dst_addr     : ternary @name("ip_dst_addr");
			lkp.ip_proto        : ternary @name("ip_proto");

			// l4
			lkp.l4_src_port     : ternary @name("l4_src_port");
			lkp.l4_dst_port     : ternary @name("l4_dst_port");

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
	// Apply
	// -------------------------------------

	apply {
//		if(!sap_exm.apply().hit) {
			sap_tcam.apply();
//		}
/*
		if(lkp.next_lyr_valid == true) {
			if(terminate_ == true) {
				ig_md.tunnel_1.terminate           = true;
				if(ig_md.nsh_md.scope == 2) {
					ig_md.tunnel_2.terminate           = true;
				}
			}

			if(scope_ == true) {
				if(ig_md.nsh_md.scope == 1) {
#ifdef INGRESS_PARSER_POPULATES_LKP_2
					Scoper.apply(
						lkp_2,
//						ig_md.drop_reason_2,

						lkp
					);
#else
					ScoperInner.apply(
						hdr_2,

						lkp
					);
#endif
				}

//				scope_inc.apply();
				ig_md.nsh_md.scope = ig_md.nsh_md.scope + 1;
			}
		}
*/
/*
		Scoper_ScopeAndTermAndData.apply(
			ig_md.lkp_0,
//			ig_md.lkp_1,
			ig_md.lkp_2,

			lkp,

			terminate_,
			scope_,
			ig_md.nsh_md.scope,
			ig_md.tunnel_0.terminate,
			ig_md.tunnel_1.terminate,
			ig_md.tunnel_2.terminate
		);
*/
		// --------------------

		if(drop_ == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0x1;
//			ig_intr_md_for_dprsr.drop_ctl = (bit<3>)drop_;
		}
	}
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Inner SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelInner(
	inout switch_ingress_metadata_t ig_md,
	inout switch_lookup_fields_t    lkp,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr // extreme added
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
	bool drop_      = false;

	action NoAction_exm (
	) {
		stats_exm.count();
	}

	action sap_exm_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate,
		bool               drop
//		,
//		bit<24>                    spi,
//		bit<8>                     si,
//		bit<8>                     si_predec
	) {
		stats_exm.count();

		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
		drop_                   = drop;
//		ig_md.nsh_md.spi     = spi;
//		ig_md.nsh_md.si      = si;
//		ig_md.nsh_md.si_predec  = si_predec;
	}

	// -------------------------------------

	table sap_exm {
		key = {
			ig_md.nsh_md.sap : exact @name("sap");

			// l3
			lkp.ip_type         : ternary @name("ip_type");
			lkp.ip_src_addr     : ternary @name("ip_src_addr");
			lkp.ip_dst_addr     : ternary @name("ip_dst_addr");
			lkp.ip_proto        : ternary @name("ip_proto");

			// l4
			lkp.l4_src_port     : ternary @name("l4_src_port");
			lkp.l4_dst_port     : ternary @name("l4_dst_port");

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
		bool               terminate,
		bool               drop
//		,
//		bit<24>                    spi,
//		bit<8>                     si,
//		bit<8>                     si_predec
	) {
		stats_tcam.count();

		ig_md.nsh_md.sap     = (bit<16>)sap;
		ig_md.nsh_md.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
		drop_                   = drop;
//		ig_md.nsh_md.spi     = spi;
//		ig_md.nsh_md.si      = si;
//		ig_md.nsh_md.si_predec  = si_predec;
	}

	// -------------------------------------

	table sap_tcam {
		key = {
			ig_md.nsh_md.sap : ternary @name("sap");

			// l3
			lkp.ip_type         : ternary @name("ip_type");
			lkp.ip_src_addr     : ternary @name("ip_src_addr");
			lkp.ip_dst_addr     : ternary @name("ip_dst_addr");
			lkp.ip_proto        : ternary @name("ip_proto");

			// l4
			lkp.l4_src_port     : ternary @name("l4_src_port");
			lkp.l4_dst_port     : ternary @name("l4_dst_port");

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
	// Apply
	// -------------------------------------

	apply {
		if(!sap_exm.apply().hit) {
			sap_tcam.apply();
		}
/*
		if(lkp.next_lyr_valid == true) {
			if(terminate_ == true) {
				ig_md.tunnel_1.terminate           = true;
				if(ig_md.nsh_md.scope == 2) {
					ig_md.tunnel_2.terminate           = true;
				}
			}

			if(scope_ == true) {
				if(ig_md.nsh_md.scope == 1) {
#ifdef INGRESS_PARSER_POPULATES_LKP_2
					Scoper.apply(
						lkp_2,
//						ig_md.drop_reason_2,

						lkp
					);
#else
					ScoperInner.apply(
						hdr_2,

						lkp
					);
#endif
				}

//				scope_inc.apply();
				ig_md.nsh_md.scope = ig_md.nsh_md.scope + 1;
			}
		}
*/
/*
		Scoper_ScopeAndTermAndData.apply(
			ig_md.lkp_0,
//			ig_md.lkp_1,
			ig_md.lkp_2,

			lkp,

			terminate_,
			scope_,
			ig_md.nsh_md.scope,
			ig_md.tunnel_0.terminate,
			ig_md.tunnel_1.terminate,
			ig_md.tunnel_2.terminate
		);
*/
		// --------------------

		if(drop_ == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0x1;
//			ig_intr_md_for_dprsr.drop_ctl = (bit<3>)drop_;
		}
	}
}

//-----------------------------------------------------------------------------
// Tunnel Decap Transport
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
	// Table
	// -------------------------------------

	action decap_l234() {
		// don't need to do anything, since we don't deparse these headers
	}

	action decap_l234_update_eth     (bit<16> new_eth) { hdr_1.ethernet.ether_type    = new_eth; hdr_1.ethernet.setValid(); decap_l234(); }

	table decap {
		key = {
			tunnel_0.terminate       : exact;
			hdr_1.ethernet.isValid() : exact;
			hdr_1.ipv4.isValid()     : exact;
		}

		actions = {
			NoAction;
			decap_l234_update_eth;
		}

		const entries = {
			// hdr hdr_1
			// --- ------------
			(false, false, false) : NoAction();
			(false, false, true ) : NoAction();
			(false, true,  false) : NoAction();
			(false, true,  true ) : NoAction();
			(true,  false, false) : decap_l234_update_eth(ETHERTYPE_IPV6);
			(true,  false, true ) : decap_l234_update_eth(ETHERTYPE_IPV4);
			(true,  true,  false) : NoAction(); // next layer already has an ethernet header
			(true,  true,  true ) : NoAction(); // next layer already has an ethernet header
		}
	}

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
		decap.apply();
/*
        if(tunnel_0.terminate) {
  #ifndef FIX_L3_TUN_ALL_AT_ONCE
            if(!hdr_1.ethernet.isValid()) {
                if(hdr_1.ipv4.isValid()) {
					decap_l234_update_eth(ETHERTYPE_IPV4);
                } else {
					decap_l234_update_eth(ETHERTYPE_IPV6);
                }
            }
  #endif
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
	// Table
	// -------------------------------------

	action decap_l2() {
		// ----- l2 -----
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

	action decap_l34() {
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
	}

	action decap_l_34_update_vlan1(bit<16> new_eth) { hdr_1.vlan_tag[1].ether_type = new_eth;             decap_l34(); }
	action decap_l_34_update_vlan0(bit<16> new_eth) { hdr_1.vlan_tag[0].ether_type = new_eth;             decap_l34(); }
#ifdef ETAG_ENABLE
	action decap_l_34_update_e    (bit<16> new_eth) { hdr_1.e_tag.ether_type       = new_eth;             decap_l34(); }
#endif
#ifdef VNTAG_ENABLE
	action decap_l_34_update_vn   (bit<16> new_eth) { hdr_1.vn_tag.ether_type      = new_eth;             decap_l34(); }
#endif
	action decap_l_34_update_eth  (bit<16> new_eth) { hdr_1.ethernet.ether_type    = new_eth;             decap_l34(); }

	action decap_l234_update_vlan1(bit<16> new_eth) { hdr_1.vlan_tag[1].ether_type = new_eth; decap_l2(); decap_l34(); }
	action decap_l234_update_vlan0(bit<16> new_eth) { hdr_1.vlan_tag[0].ether_type = new_eth; decap_l2(); decap_l34(); }
#ifdef ETAG_ENABLE
	action decap_l234_update_e    (bit<16> new_eth) { hdr_1.e_tag.ether_type       = new_eth; decap_l2(); decap_l34(); }
#endif
#ifdef VNTAG_ENABLE
	action decap_l234_update_vn   (bit<16> new_eth) { hdr_1.vn_tag.ether_type      = new_eth; decap_l2(); decap_l34(); }
#endif
	action decap_l234_update_eth  (bit<16> new_eth) { hdr_1.ethernet.ether_type    = new_eth; decap_l2(); decap_l34(); }

	table decap {
		key = {
			tunnel_1.terminate          : exact;
			hdr_1.e_tag.isValid()       : ternary;
			hdr_1.vn_tag.isValid()      : ternary;
			hdr_1.vlan_tag[0].isValid() : exact;
			hdr_1.vlan_tag[1].isValid() : exact;

			tunnel_2.terminate          : exact;
			hdr_2.ethernet.isValid()    : ternary;
			hdr_2.ipv4.isValid()        : ternary;

			hdr_3.ethernet.isValid()    : ternary;
			hdr_3.ipv4.isValid()        : ternary;
		}

		actions = {
			decap_l_34_update_vlan1;
			decap_l_34_update_vlan0;
#ifdef ETAG_ENABLE
			decap_l_34_update_e;
#endif
#ifdef VNTAG_ENABLE
			decap_l_34_update_vn;
#endif
			decap_l_34_update_eth;

			decap_l234_update_vlan1;
			decap_l234_update_vlan0;
#ifdef ETAG_ENABLE
			decap_l234_update_e;
#endif
#ifdef VNTAG_ENABLE
			decap_l234_update_vn;
#endif
			decap_l234_update_eth;
		}

		// My original equation for when to remove the outer l2 header:
		//
		// only remove l2 when the next layer's is valid
		// if(hdr_2.ethernet.isValid() || (tunnel_2.terminate && hdr_3.ethernet.isValid())) {
		// }

			// hdr_1                            hdr__2               hdr_3
			// -------------------------------- -------------------- ------------
		const entries = {
			(true,  _,     _,     true,  false, false, false, true,  _,     _    ) : decap_l_34_update_vlan0(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  false, false, false, false, _,     _    ) : decap_l_34_update_vlan0(ETHERTYPE_IPV6);
			(true,  _,     _,     true,  true,  false, false, true,  _,     _    ) : decap_l_34_update_vlan1(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  true,  false, false, false, _,     _    ) : decap_l_34_update_vlan1(ETHERTYPE_IPV6);
#ifdef ETAG_ENABLE
			(true,  true,  false, false, false, false, false, true,  _,     _    ) : decap_l_34_update_e    (ETHERTYPE_IPV4);
			(true,  true,  false, false, false, false, false, false, _,     _    ) : decap_l_34_update_e    (ETHERTYPE_IPV6);
#endif
#ifdef VNTAG_ENABLE
			(true,  false, true,  false, false, false, false, true,  _,     _    ) : decap_l_34_update_vn   (ETHERTYPE_IPV4);
			(true,  false, true,  false, false, false, false, false, _,     _    ) : decap_l_34_update_vn   (ETHERTYPE_IPV6);
#endif
			(true,  false, false, false, false, false, false, true,  _,     _    ) : decap_l_34_update_eth  (ETHERTYPE_IPV4);
			(true,  false, false, false, false, false, false, false, _,     _    ) : decap_l_34_update_eth  (ETHERTYPE_IPV6);

			(true,  _,     _,     true,  false, false, true,  true,  _,     _    ) : decap_l234_update_vlan0(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  false, false, true,  false, _,     _    ) : decap_l234_update_vlan0(ETHERTYPE_IPV6);
			(true,  _,     _,     true,  true,  false, true,  true,  _,     _    ) : decap_l234_update_vlan1(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  true,  false, true,  false, _,     _    ) : decap_l234_update_vlan1(ETHERTYPE_IPV6);
#ifdef ETAG_ENABLE
			(true,  true,  false, false, false, false, true,  true,  _,     _    ) : decap_l234_update_e    (ETHERTYPE_IPV4);
			(true,  true,  false, false, false, false, true,  false, _,     _    ) : decap_l234_update_e    (ETHERTYPE_IPV6);
#endif
#ifdef VNTAG_ENABLE
			(true,  false, true,  false, false, false, true,  true,  _,     _    ) : decap_l234_update_vn   (ETHERTYPE_IPV4);
			(true,  false, true,  false, false, false, true,  false, _,     _    ) : decap_l234_update_vn   (ETHERTYPE_IPV6);
#endif
			(true,  false, false, false, false, false, true,  true,  _,     _    ) : decap_l234_update_eth  (ETHERTYPE_IPV4);
			(true,  false, false, false, false, false, true,  false, _,     _    ) : decap_l234_update_eth  (ETHERTYPE_IPV6);

			(true,  _,     _,     true,  false, true,  true,  true,  _,     _    ) : decap_l234_update_vlan0(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  false, true,  true,  false, _,     _    ) : decap_l234_update_vlan0(ETHERTYPE_IPV6);
			(true,  _,     _,     true,  true,  true,  true,  true,  _,     _    ) : decap_l234_update_vlan1(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  true,  true,  true,  false, _,     _    ) : decap_l234_update_vlan1(ETHERTYPE_IPV6);
#ifdef ETAG_ENABLE
			(true,  true,  false, false, false, true,  true,  true,  _,     _    ) : decap_l234_update_e    (ETHERTYPE_IPV4);
			(true,  true,  false, false, false, true,  true,  false, _,     _    ) : decap_l234_update_e    (ETHERTYPE_IPV6);
#endif
#ifdef VNTAG_ENABLE
			(true,  false, true,  false, false, true,  true,  true,  _,     _    ) : decap_l234_update_vn   (ETHERTYPE_IPV4);
			(true,  false, true,  false, false, true,  true,  false, _,     _    ) : decap_l234_update_vn   (ETHERTYPE_IPV6);
#endif
			(true,  false, false, false, false, true,  true,  true,  _,     _    ) : decap_l234_update_eth  (ETHERTYPE_IPV4);
			(true,  false, false, false, false, true,  true,  false, _,     _    ) : decap_l234_update_eth  (ETHERTYPE_IPV6);

			(true,  _,     _,     true,  false, true,  _,     _,     false, true ) : decap_l_34_update_vlan0(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  false, true,  _,     _,     false, false) : decap_l_34_update_vlan0(ETHERTYPE_IPV6);
			(true,  _,     _,     true,  true,  true,  _,     _,     false, true ) : decap_l_34_update_vlan1(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  true,  true,  _,     _,     false, false) : decap_l_34_update_vlan1(ETHERTYPE_IPV6);
#ifdef ETAG_ENABLE
			(true,  true,  false, false, false, true,  _,     _,     false, true ) : decap_l_34_update_e    (ETHERTYPE_IPV4);
			(true,  true,  false, false, false, true,  _,     _,     false, false) : decap_l_34_update_e    (ETHERTYPE_IPV6);
#endif
#ifdef VNTAG_ENABLE
			(true,  false, true,  false, false, true,  _,     _,     false, true ) : decap_l_34_update_vn   (ETHERTYPE_IPV4);
			(true,  false, true,  false, false, true,  _,     _,     false, false) : decap_l_34_update_vn   (ETHERTYPE_IPV6);
#endif
			(true,  false, false, false, false, true,  _,     _,     false, true ) : decap_l_34_update_eth  (ETHERTYPE_IPV4);
			(true,  false, false, false, false, true,  _,     _,     false, false) : decap_l_34_update_eth  (ETHERTYPE_IPV6);

			(true,  _,     _,     true,  false, true,  _,     _,     true,  true ) : decap_l234_update_vlan0(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  false, true,  _,     _,     true,  false) : decap_l234_update_vlan0(ETHERTYPE_IPV6);
			(true,  _,     _,     true,  true,  true,  _,     _,     true,  true ) : decap_l234_update_vlan1(ETHERTYPE_IPV4);
			(true,  _,     _,     true,  true,  true,  _,     _,     true,  false) : decap_l234_update_vlan1(ETHERTYPE_IPV6);
#ifdef ETAG_ENABLE
			(true,  true,  false, false, false, true,  _,     _,     true,  true ) : decap_l234_update_e    (ETHERTYPE_IPV4);
			(true,  true,  false, false, false, true,  _,     _,     true,  false) : decap_l234_update_e    (ETHERTYPE_IPV6);
#endif
#ifdef VNTAG_ENABLE
			(true,  false, true,  false, false, true,  _,     _,     true,  true ) : decap_l234_update_vn   (ETHERTYPE_IPV4);
			(true,  false, true,  false, false, true,  _,     _,     true,  false) : decap_l234_update_vn   (ETHERTYPE_IPV6);
#endif
			(true,  false, false, false, false, true,  _,     _,     true,  true ) : decap_l234_update_eth  (ETHERTYPE_IPV4);
			(true,  false, false, false, false, true,  _,     _,     true,  false) : decap_l234_update_eth  (ETHERTYPE_IPV6);
		}
	}

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
#ifdef TUNNEL_ENABLE
		decap.apply();
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
	// Table
	// -------------------------------------

	action decap_l2() {
		// ----- l2 -----
		hdr_2.ethernet.setInvalid();
		hdr_2.vlan_tag[0].setInvalid(); // extreme added
	}

	action decap_l34() {
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
	}

	action decap_l_34_update_vlan0(bit<16> new_eth) { hdr_2.vlan_tag[0].ether_type = new_eth;             decap_l34(); }
	action decap_l_34_update_eth  (bit<16> new_eth) { hdr_2.ethernet.ether_type    = new_eth;             decap_l34(); }
	action decap_l234_update_vlan0(bit<16> new_eth) { hdr_2.vlan_tag[0].ether_type = new_eth; decap_l2(); decap_l34(); }
	action decap_l234_update_eth  (bit<16> new_eth) { hdr_2.ethernet.ether_type    = new_eth; decap_l2(); decap_l34(); }

	table decap {
		key = {
			tunnel_2.terminate          : exact;
			hdr_2.vlan_tag[0].isValid() : exact;

			hdr_3.ethernet.isValid()    : exact;
			hdr_3.ipv4.isValid()        : exact;
		}

		actions = {
			decap_l_34_update_vlan0;
			decap_l_34_update_eth;

			decap_l234_update_vlan0;
			decap_l234_update_eth;
		}

		const entries = {
			// hdr_2       hdr_3
			// ----------- ------------
			(true,  true,  false, true ) : decap_l_34_update_vlan0(ETHERTYPE_IPV4);
			(true,  true,  false, false) : decap_l_34_update_vlan0(ETHERTYPE_IPV6);
			(true,  false, false, true ) : decap_l_34_update_eth  (ETHERTYPE_IPV4);
			(true,  false, false, false) : decap_l_34_update_eth  (ETHERTYPE_IPV6);

			(true,  true,  true,  true ) : decap_l234_update_vlan0(ETHERTYPE_IPV4);
			(true,  true,  true,  false) : decap_l234_update_vlan0(ETHERTYPE_IPV6);
			(true,  false, true,  true ) : decap_l234_update_eth  (ETHERTYPE_IPV4);
			(true,  false, true,  false) : decap_l234_update_eth  (ETHERTYPE_IPV6);
		}
	}

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
#ifdef TUNNEL_ENABLE
		decap.apply();
#endif /* TUNNEL_ENABLE */
	}
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - L2 Ethertype Fix
//-----------------------------------------------------------------------------
/*
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
*/
//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - Scope Decrement
//-----------------------------------------------------------------------------

control TunnelDecapScopeDecrement (
	inout bool terminate_a,
	inout bool terminate_b,
	inout switch_header_transport_t hdr_0,
	inout bit<8> scope
) {

	action new_scope(bit<8> scope_new) {
		scope = scope_new;
//		terminate_a = false;
//		terminate_b = false;
	}

	table scope_dec {
		key = {
			scope : exact;
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
			(0, true,  false) : new_scope(0); // this is an error condition (underflow) -- cap at 0
			(1, true,  false) : new_scope(0);
			(2, true,  false) : new_scope(1);
			(3, true,  false) : new_scope(2);
			// decrement by one (these should never occur)
			(0, false, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0
			(1, false, true ) : new_scope(0);
			(2, false, true ) : new_scope(1);
			(3, false, true ) : new_scope(2);
			// decrement by two
			(0, true,  true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0
			(1, true,  true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0
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
// IP Tunnel Encapsulation - Step 1
//
// Tunnel Nexthop
//-----------------------------------------------------------------------------

control TunnelNexthop(inout switch_header_outer_t hdr,
				inout switch_egress_metadata_t eg_md,
				inout switch_tunnel_metadata_t tunnel
) (
				switch_uint32_t nexthop_table_size
) {

	// ---------------------------------------------
	// Table: Nexthop Rewrite
	// ---------------------------------------------

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;  // direct counter

	action rewrite_l2_with_tunnel(    // ---- + -- + tun type + -------
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

		switch_tunnel_type_t type
	) {
		stats.count();

//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later

#ifdef TUNNEL_ENABLE
		tunnel.type = type;
#endif
	}

	// ---------------------------------------------

	action rewrite_l3(                // dmac + bd + -------- + -------
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,
		switch_bd_t bd
	) {
		stats.count();

//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = bd; // derek: add in later
	}

	// ---------------------------------------------

	action rewrite_l3_with_tunnel_id( // dmac + bd + tun type + tun id
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

		switch_tunnel_type_t type,
		switch_tunnel_id_t id
	) {
		stats.count();

#ifdef TUNNEL_ENABLE
//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = SWITCH_BD_DEFAULT_VRF; // derek: add in later

		tunnel.type = type;
		tunnel.id = id;
#endif
	}

	// ---------------------------------------------

	action rewrite_l3_with_tunnel_bd( // dmac + bd + tun type + -------
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,
		switch_bd_t bd,

		switch_tunnel_type_t type
	) {
		stats.count();

#ifdef TUNNEL_ENABLE
//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = bd; // derek: add in later

		tunnel.type = type;
#endif
	}

	// ---------------------------------------------

	action rewrite_l3_with_tunnel( // dmac + bd(vrf) + tun type + -------
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

		switch_tunnel_type_t type
	) {
		stats.count();

#ifdef TUNNEL_ENABLE
//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = (switch_bd_t) eg_md.vrf;

		tunnel.type = type;
#endif
	}

	// ---------------------------------------------

	action no_action(
	) {
		stats.count();
	}

	// ---------------------------------------------

	table nexthop_rewrite {
		key = { eg_md.nexthop : exact; }
		actions = {
#if defined(TUNNEL_ENABLE) || defined(MULTICAST_ENABLE)
//			NoAction;
			no_action;
#endif
#ifdef TUNNEL_ENABLE
			rewrite_l2_with_tunnel;
			rewrite_l3;
			rewrite_l3_with_tunnel;
			rewrite_l3_with_tunnel_bd;
			rewrite_l3_with_tunnel_id;
#else
			rewrite_l3;
#endif
		}

#if defined(TUNNEL_ENABLE) || defined(MULTICAST_ENABLE)
//		const default_action = NoAction;
		const default_action = no_action;
#else
		const default_action = rewrite_l3(0, 0);
#endif
		size = nexthop_table_size;
		counters = stats;
	}

	// ---------------------------------------------
	// Apply
	// ---------------------------------------------

	apply {
		if (!EGRESS_BYPASS(REWRITE)) {
			nexthop_rewrite.apply();
		}
	}
}

//-----------------------------------------------------------------------------
// IP/MPLS Tunnel encapsulation - Step 2
//         -- Copy Outer Headers to inner
//         -- Tunnel Header (VXLAN, GRE etc)Rewrite
//         -- MPLS Label Push
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

	action rewrite_inner_ipv4_hdr1() {
		payload_len = hdr_1.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	action rewrite_inner_ipv4_hdr2() {
		payload_len = hdr_2.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	action rewrite_inner_ipv4_hdr3() {
		payload_len = hdr_3.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	// --------------------------------
#ifdef IPV6_ENABLE
	action rewrite_inner_ipv6_hdr1() {
//		payload_len = hdr_1.ipv6.payload_len + 16w40;
		payload_len = hdr_1.ipv6.payload_len;
		gre_proto = GRE_PROTOCOLS_IPV6;
	}

	action rewrite_inner_ipv6_hdr2() {
//		payload_len = hdr_2.ipv6.payload_len + 16w40;
		payload_len = hdr_2.ipv6.payload_len;
		gre_proto = GRE_PROTOCOLS_IPV6;
	}

	action rewrite_inner_ipv6_hdr3() {
//		payload_len = hdr_3.ipv6.payload_len + 16w40;
		payload_len = hdr_3.ipv6.payload_len;
		gre_proto = GRE_PROTOCOLS_IPV6;
	}
#endif
	// --------------------------------

	// Look for the first valid l3.

	table encap_outer {
		key = {
			hdr_1.ipv4.isValid() : exact;
			hdr_1.ipv6.isValid() : exact;
			hdr_2.ipv4.isValid() : exact;
			hdr_2.ipv6.isValid() : exact;
			hdr_3.ipv4.isValid() : exact;
			hdr_3.ipv6.isValid() : exact;
		}

		actions = {
			rewrite_inner_ipv4_hdr1;
			rewrite_inner_ipv4_hdr2;
			rewrite_inner_ipv4_hdr3;
#ifdef IPV6_ENABLE
			rewrite_inner_ipv6_hdr1;
			rewrite_inner_ipv6_hdr2;
			rewrite_inner_ipv6_hdr3;
#endif
		}

		const entries = {
			// hdr_1       hdr_2         hdr_3
			// ----------- ------------- ------------
/*
			(true,  false, _,     _,     _,     _    ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(false, false, true,  false, _,     _    ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, false, false, true,  false) : rewrite_inner_ipv4_hdr3(); // inner-inner v4 (note:                 are don't care)
#ifdef IPV6_ENABLE
			(false, true,  _,     _,     _,     _    ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, false, false, true,  _,     _    ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, false, false, true ) : rewrite_inner_ipv6_hdr3(); // inner-inner v6 (note:                 are don't care)
#endif
*/
			(true,  false, false, false, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)

			(false, false, true,  false, false, false) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, true,  false) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, false, true ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, true,  true ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)

			(false, false, false, false, true,  false) : rewrite_inner_ipv4_hdr3(); // inner-inner v4 (note:                 are don't care)
#ifdef IPV6_ENABLE
			(false, true,  false, false, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)

			(false, false, false, true,  false, false) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  true,  false) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  false, true ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  true,  true ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)

			(false, false, false, false, false, true ) : rewrite_inner_ipv6_hdr3(); // inner-inner v6 (note:                 are don't care)
#endif
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
	// Table #3: Terminate L2 (for GRE)
	//=============================================================================

	action decap_l2_outer() {
		// ----- l2 -----
		hdr_1.ethernet.setInvalid();
#ifdef ETAG_ENABLE
		hdr_1.e_tag.setInvalid();
#endif
#ifdef VNTAG_ENABLE
		hdr_1.vn_tag.setInvalid();
#endif
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
		hdr_1.mpls_pw_cw.setInvalid();
#endif // MPLS_L2VPN_ENABLE
	}

	action decap_l2_inner() {
		// ----- l2 -----
		hdr_2.ethernet.setInvalid();
		hdr_2.vlan_tag[0].setInvalid();
	}

	action decap_l2_inner_inner() {
		// ----- l2 -----
	}

	// Remove the first valid l2.  This could be in any layer(s) prior to the first
	// valid l3, because we could have decapped l3 tunnel(s) and had to leave the
	// l2 from a previous layer.

	table decap_l2 {
		key = {
			hdr_1.ethernet.isValid() : exact;
			hdr_2.ethernet.isValid() : exact;
		}

		actions = {
			NoAction;
			decap_l2_outer;
			decap_l2_inner;
			decap_l2_inner_inner;
		}

		const entries = {
			(true,  false) : decap_l2_outer; // note: inner is don't care
			(true,  true ) : decap_l2_outer; // note: inner is don't care
			(false, true ) : decap_l2_inner;
			(false, false) : decap_l2_inner_inner;
		}
		const default_action = NoAction;
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
			encap_outer.apply(); // derek: this no longer copies anything -- it just gets some lengths needed for the next table actions

			if(gre_proto == GRE_PROTOCOLS_IPV6) {
				payload_len = payload_len + 16w40; // for ipv6, need to add hdr size to payload len
			}

			// Add outer L3/L4/Tunnel headers.
//			tunnel.apply();

			switch(tunnel.apply().action_run) {
				rewrite_ipv4_gre: {
//					decap_l2.apply();

					if(hdr_1.ethernet.isValid() == true) {
						decap_l2_outer();
					} else {
						if(hdr_2.ethernet.isValid() == true) {
							decap_l2_inner();
						} else {
							decap_l2_inner_inner();
						}
					}
				}
				rewrite_ipv6_gre: {
#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
//					decap_l2.apply();

					if(hdr_1.ethernet.isValid() == true) {
						decap_l2_outer();
					} else {
						if(hdr_2.ethernet.isValid() == true) {
							decap_l2_inner();
						} else {
							decap_l2_inner_inner();
						}
					}
#endif
				}
				default: {
				}
			}
		}
#endif /* TUNNEL_ENABLE */
	}
}

//-----------------------------------------------------------------------------
// IP Tunnel Encapsulation - Step 3
//         -- Outer SIP Rewrite
//         -- Outer DIP Rewrite
//         -- TTL QoS Rewrite
//         -- MPLS Rewrite 
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

	// DEREK: As best as I can tell, most of this table has moved to nexthop.p4 in the latest switch.p4 code....

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_nexthop;  // direct counter

	// Outer nexthop rewrite
	action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
		stats_nexthop.count();

		eg_md.bd = bd;
		hdr_0.ethernet.dst_addr = dmac;
	}

	action no_action_nexthop() {
		stats_nexthop.count();

	}

	table nexthop_rewrite {
		key = {
			eg_md.tunnel_nexthop : exact @name("eg_md.outer_nexthop");
		}

		actions = {
			no_action_nexthop;
			rewrite_tunnel;
		}

		const default_action = no_action_nexthop;
		size = nexthop_rewrite_table_size;
		counters = stats_nexthop;
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
		key = { tunnel.dip_index : exact @name("tunnel.index"); }
		actions = { rewrite_ipv4_dst; }
//		const default_action = rewrite_ipv4_dst(0); // extreme modified!
		size = ipv4_dst_addr_rewrite_table_size;
		counters = stats_ipv4_dst_addr;
	}
#endif

#ifdef GRE_TRANSPORT_EGRESS_ENABLE_V6
	table ipv6_dst_addr_rewrite {
		key = { tunnel.dip_index : exact @name("tunnel.index"); }
		actions = { rewrite_ipv6_dst; }
//		const default_action = rewrite_ipv6_dst(0); // extreme modified!
		size = ipv6_dst_addr_rewrite_table_size;
		counters = stats_ipv6_dst_addr;
	}
#endif

	// -------------------------------------
	// Table: SMAC Rewrite
	// -------------------------------------

	// DEREK: As best as I can tell, this table has been absorbed into the EgressBd table in l2.p4 in the lastest swtich.p4 code....

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
		if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
			// DEREK: As best as I can tell, this table is now instantiated in the top level in the latest switch.p4 code....
			nexthop_rewrite.apply();

			// DEREK: As best as I can tell, this table is now instantiated in the top level in the latest switch.p4 code....
			egress_bd.apply(hdr_0, eg_md.bd, eg_md.pkt_src, smac_index);

#if defined(ERSPAN_TRANSPORT_EGRESS_ENABLE) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V4) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V6)
			src_addr_rewrite.apply();

			// DEREK: As best as I can tell, these two tables have been combined into a single table in the lastest swtich.p4 code....
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

		// DEREK: As best as I can tell, this table has been absorbed into the EgressBd table in l2.p4 in the lastest swtich.p4 code....
		smac_rewrite.apply();
#endif /* TUNNEL_ENABLE */
	}
}

#endif
