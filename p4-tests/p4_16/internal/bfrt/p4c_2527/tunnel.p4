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
            hdr_0.ethernet.dst_addr : exact;
        }

        actions = {
            NoAction;
            rmac_hit;
            rmac_miss; // extreme added
        }

        const default_action = NoAction;
        size = table_size;
    }
#endif

    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {
#ifdef BRIDGING_ENABLE
		if(hdr_0.nsh_type1.isValid()) {
        	rmac.apply();
		} else {
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
    inout bool ig_md_flags_ipv4_checksum_err,
    inout switch_lookup_fields_t lkp,
    inout switch_tunnel_metadata_t tunnel_0,
    inout switch_header_transport_t hdr_0,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr // extreme added
) (
	switch_uint32_t ipv4_src_vtep_table_size=1024,
    switch_uint32_t ipv6_src_vtep_table_size=1024,
    switch_uint32_t ipv4_dst_vtep_table_size=1024,
    switch_uint32_t ipv6_dst_vtep_table_size=1024
) {

    // -------------------------------------
    // Table: IPv4/v6 Src VTEP
    // -------------------------------------

    // Derek note: These tables are unused in latest switch.p4 code from barefoot

	action src_vtep_hit(
		switch_port_lag_index_t  port_lag_index,
		bit<SAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH> vpn,
		bit<3>            sf_bitmask
	) {
		ig_md.port_lag_index          = port_lag_index;
		hdr_0.nsh_type1.sap           = sap;         // 16 bits
		hdr_0.nsh_type1.vpn           = vpn;         // 16 bits
		ig_md.nsh_type1.sf_bitmask    = sf_bitmask;  //  8 bits
	}

	action src_vtep_miss(
	) {
	}

    // -------------------------------------

    table src_vtep {
        key = {
#ifdef ERSPAN_INGRESS_ENABLE
            hdr_0.ipv4.src_addr : exact @name("src_addr");
#endif
            tunnel_0.type : exact @name("tunnel_type");
        }

        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }

        const default_action = src_vtep_miss;
        size = ipv4_src_vtep_table_size;
    }

    // -------------------------------------

#ifdef SFC_TRANSPORT_TUNNEL_IPV6_TABLE_ENABLE
    table src_vtepv6 {
        key = {
#ifdef ERSPAN_INGRESS_ENABLE
            hdr_0.ipv6.src_addr : exact @name("src_addr");
#endif
            tunnel_0.type : exact @name("tunnel_type");
        }

        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }

        const default_action = src_vtep_miss;
        size = ipv6_src_vtep_table_size;
    }
#endif

    // -------------------------------------
    // Table: IPv4/v6 Dst VTEP
    // -------------------------------------

	action dst_vtep_hit(
//		switch_bd_t bd,

		bit<3>            drop

  #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
		,
		switch_port_lag_index_t  port_lag_index,
		bit<SAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH> vpn,
		bit<3>            sf_bitmask
  #endif
	) {
//		ig_md.bd = bd;

		ig_intr_md_for_dprsr.drop_ctl = drop;

  #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
		ig_md.port_lag_index          = port_lag_index;
		hdr_0.nsh_type1.sap           = sap;         // 16 bits
		hdr_0.nsh_type1.vpn           = vpn;         // 16 bits
		ig_md.nsh_type1.sf_bitmask    = sf_bitmask;  //  8 bits
  #endif
	}

    // -------------------------------------

    table dst_vtep {
        key = {
#ifdef ERSPAN_INGRESS_ENABLE
  #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
            hdr_0.ipv4.src_addr : exact @name("src_addr");
  #endif
            hdr_0.ipv4.dst_addr : ternary @name("dst_addr");
#endif
            tunnel_0.type : exact @name("tunnel_type"); 
        }

        actions = {
            NoAction;
            dst_vtep_hit;
        }

        const default_action = NoAction;
        size = ipv4_dst_vtep_table_size;
    }

    // -------------------------------------

#ifdef SFC_TRANSPORT_TUNNEL_IPV6_TABLE_ENABLE
    table dst_vtepv6 {
        key = {
#ifdef ERSPAN_INGRESS_ENABLE
  #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
            hdr_0.ipv6.src_addr : exact @name("src_addr");
  #endif
            hdr_0.ipv6.dst_addr : ternary @name("dst_addr");
#endif
            tunnel_0.type : exact @name("tunnel_type"); 
        }

        actions = {
            NoAction;
            dst_vtep_hit;
        }

        const default_action = NoAction;
        size = ipv6_dst_vtep_table_size;
    }
#endif

    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {
#ifdef TUNNEL_ENABLE
        // outer RMAC lookup for tunnel termination.
//      switch(rmac.apply().action_run) {
//          rmac_hit : {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
  #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
                    src_vtep.apply();
  #endif
                    switch(dst_vtep.apply().action_run) {
                        dst_vtep_hit : {
                        }
                    }
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
#ifdef SFC_TRANSPORT_TUNNEL_IPV6_TABLE_ENABLE
  #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
                    src_vtepv6.apply();
  #endif
                    switch(dst_vtepv6.apply().action_run) {
                        dst_vtep_hit : {
                        }
                    }
#endif
				}
//          }
//      }
#endif /* TUNNEL_ENABLE */
    }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Outer (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelOuterInner(
    inout switch_ingress_metadata_t ig_md,
    inout switch_lookup_fields_t lkp,
	inout switch_header_transport_t                 hdr_0,
	inout switch_header_inner_t                     hdr_2,
	inout switch_tunnel_metadata_t                  tunnel_2
) (
    switch_uint32_t dst_vtep_exm_table_size=32w1024,
    switch_uint32_t dst_vtep_tcam_table_size=32w1024
) {

    // -------------------------------------
    // Table: Dst VTEP
    // -------------------------------------

	bool terminate_ = false;
	bool scope_ = false;

    action dst_vtep_hit(
		bit<SAP_ID_WIDTH>               sap,
        bit<VPN_ID_WIDTH>               vpn,
		bit<3>                          sf_bitmask
    ) {
		hdr_0.nsh_type1.sap                   = sap;
        hdr_0.nsh_type1.vpn                   = vpn;
		ig_md.nsh_type1.sf_bitmask            = sf_bitmask;  //  8 bits
    }

    action dst_vtep_hit_scope(
		bit<SAP_ID_WIDTH>               sap,
        bit<VPN_ID_WIDTH>               vpn,
		bit<3>                          sf_bitmask
    ) {
		hdr_0.nsh_type1.sap                   = sap;
        hdr_0.nsh_type1.vpn                   = vpn;
		ig_md.nsh_type1.sf_bitmask            = sf_bitmask;  //  8 bits

		scope_ = true;
    }

    action dst_vtep_hit_term(
		bit<SAP_ID_WIDTH>               sap,
        bit<VPN_ID_WIDTH>               vpn,
		bit<3>                          sf_bitmask
    ) {
		hdr_0.nsh_type1.sap                   = sap;
        hdr_0.nsh_type1.vpn                   = vpn;
		ig_md.nsh_type1.sf_bitmask            = sf_bitmask;  //  8 bits

		terminate_ = true;
    }

    action dst_vtep_hit_scope_and_term(
		bit<SAP_ID_WIDTH>               sap,
        bit<VPN_ID_WIDTH>               vpn,
		bit<3>                          sf_bitmask
    ) {
		hdr_0.nsh_type1.sap                   = sap;
        hdr_0.nsh_type1.vpn                   = vpn;
		ig_md.nsh_type1.sf_bitmask            = sf_bitmask;  //  8 bits

		scope_ = true;
		terminate_ = true;
    }

    // -------------------------------------

    table dst_vtep_exm {
        key = {
            hdr_0.nsh_type1.sap    : exact @name("sap");
            lkp.tunnel_type        : exact @name("tunnel_type");
            lkp.tunnel_id          : exact @name("tynnel_id");
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            dst_vtep_hit_scope;
            dst_vtep_hit_term;
            dst_vtep_hit_scope_and_term;
        }

        const default_action = NoAction;
        size = dst_vtep_exm_table_size;
    }

    // -------------------------------------

    table dst_vtep_tcam {
        key = {
            hdr_0.nsh_type1.sap    : ternary @name("sap");
            lkp.tunnel_type        : ternary @name("tunnel_type");
            lkp.tunnel_id          : ternary @name("tynnel_id");
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            dst_vtep_hit_scope;
            dst_vtep_hit_term;
            dst_vtep_hit_scope_and_term;
        }

        const default_action = NoAction;
        size = dst_vtep_tcam_table_size;
    }

    // -------------------------------------
    // Table: Scope Increment
    // -------------------------------------

    action new_scope(bit<8> scope_new) {
        hdr_0.nsh_type1.scope = scope_new;
    }
/*
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

		if(!dst_vtep_exm.apply().hit) {
			dst_vtep_tcam.apply();
		}

		if(terminate_ == true) {
            ig_md.tunnel_1.terminate           = true;
            if(hdr_0.nsh_type1.scope == 1) {
                ig_md.tunnel_2.terminate           = true;
			}
		}

		if(scope_ == true) {
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
                    tunnel_2.type,
                    tunnel_2.id,
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

//-----------------------------------------------------------------------------
// Tunnel Decap Transport
//-----------------------------------------------------------------------------

// looks like this control block is doing nothing if ERSPAN ripped out

control TunnelDecapTransportIngress(
    inout switch_header_transport_t hdr_0,
#ifdef BUG_10015_WORKAROUND
    in switch_egress_metadata_t eg_md,
#else
    in switch_ingress_metadata_t eg_md,
#endif
    in switch_tunnel_metadata_t tunnel
) (
    switch_tunnel_mode_t mode
) {

// There is no UDP support in transport
//     // -------------------------------------
//     // Decap L4
//     // -------------------------------------
// 
// 	action decap_l4() {
// 		hdr_0.udp.setInvalid();
// //		hdr_0.tcp.setInvalid();
// 	}

    // -------------------------------------
    // Decap L3
    // -------------------------------------

	// helper functions

#ifdef ERSPAN_INGRESS_ENABLE
    action invalidate_tunneling_headers() {
//#ifdef GRE_ENABLE
		hdr_0.gre.setInvalid();
//#endif
		hdr_0.erspan_type2.setInvalid();
		hdr_0.erspan_type3.setInvalid();
	}

    // -------------------------------------

	action decap_ip() {
		hdr_0.ipv4.setInvalid();
		//hdr_0.ipv4_option.setInvalid();

		invalidate_tunneling_headers();
	}
#endif /* ERSPAN_INGRESS_ENABLE */

    // -------------------------------------
    // Decap L2
    // -------------------------------------


	action decap_l2() {
//      hdr_0.ethernet.setInvalid();
//      hdr_0.vlan_tag[0].setInvalid();
//      hdr_0.nsh_type1.setInvalid();
	}

    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {

		// ----- l2 -----
        if(tunnel.terminate) {
			decap_l2();
		}

#ifdef ERSPAN_INGRESS_ENABLE
		// ----- l3 -----
        if(tunnel.terminate) {
			decap_ip();
		}
#endif /* ERSPAN_INGRESS_ENABLE */

        // No L4 support in transport
		// // ----- l4 -----
        // if(tunnel.terminate) {
		// 	decap_l4();
		// }

    }

}

//-----------------------------------------------------------------------------

control TunnelDecapTransportEgress(
    inout switch_header_transport_t hdr_0,
    in switch_egress_metadata_t eg_md,
    in switch_tunnel_metadata_t tunnel,
    in bool nsh_terminate
) (
    switch_tunnel_mode_t mode
) {
    // -------------------------------------
    // Decap L2
    // -------------------------------------

	action decap_l2() {
        hdr_0.ethernet.setInvalid();
        hdr_0.vlan_tag[0].setInvalid();
	}

	action decap_l2_nsh() {
        hdr_0.nsh_type1.setInvalid();
	}

    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {
		if(tunnel.terminate) { // always true
			decap_l2();
		}

		if(nsh_terminate) { // maybe true
			decap_l2_nsh();
		}
	}
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - Scope Decrement
//-----------------------------------------------------------------------------

control TunnelDecapScopeDecrement (
	in    bool terminate_a,
	in    bool terminate_b,
	inout switch_header_transport_t hdr_0
) {

    action new_scope(bit<8> scope_new) {
        hdr_0.nsh_type1.scope = scope_new;
    }

    table scope_dec {
		key = {
			terminate_a : exact;
			terminate_b : exact;
			hdr_0.nsh_type1.scope : exact;
		}
		actions = {
			new_scope;
		}
		const entries = {
/*
			0 : new_scope(0); // this is an error condition (underflow)!
			1 : new_scope(0);
			2 : new_scope(1);
			3 : new_scope(2);
*/
			// no decrement
			(false, false, 0) : new_scope(0);
			(false, false, 1) : new_scope(1);
			(false, false, 2) : new_scope(2);
			(false, false, 3) : new_scope(3);
			// decrement one
			(false, true,  0) : new_scope(0); // this is an error condition (underflow)!
			(false, true,  1) : new_scope(0);
			(false, true,  2) : new_scope(1);
			(false, true,  3) : new_scope(2);
			// decrement one
			(true,  false, 0) : new_scope(0); // this is an error condition (underflow)!
			(true,  false, 1) : new_scope(0);
			(true,  false, 2) : new_scope(1);
			(true,  false, 3) : new_scope(2);
			// decrement two
			(true,  true,  0) : new_scope(0); // this is an error condition (underflow)!
			(true,  true,  1) : new_scope(0); // this is an error condition (underflow)!
			(true,  true,  2) : new_scope(0);
			(true,  true,  3) : new_scope(1);
		}
	}

	// -------------------------

	apply {
		scope_dec.apply();
	}
}

//-----------------------------------------------------------------------------
// Tunnel Decap Outer
//-----------------------------------------------------------------------------

control TunnelDecapOuter(
    inout switch_header_transport_t hdr_0,
    inout switch_header_outer_t hdr_1,
    in    switch_egress_metadata_t eg_md,
    in    switch_tunnel_metadata_t tunnel
) (
    switch_tunnel_mode_t mode
) {

    // -------------------------------------
	// Decap L4
    // -------------------------------------

	action decap_l4() {
        hdr_1.tcp.setInvalid();
        hdr_1.udp.setInvalid();
	}

    // -------------------------------------
	// Decap L3
    // -------------------------------------

	// helper functions

    action invalidate_tunneling_headers() {
        // Removing tunneling headers by default.
        hdr_1.vxlan.setInvalid();

        // -------------------------------------
        // Extreme Networks - Added
        // -------------------------------------

		hdr_1.vxlan.setInvalid();
		hdr_1.gre.setInvalid();
		hdr_1.nvgre.setInvalid();

#ifdef GTP_ENABLE
        hdr_1.gtp_v1_base.setInvalid(); // extreme added
        hdr_1.gtp_v2_base.setInvalid(); // extreme added
#endif
    }

    // -------------------------------------

	action decap_ip() {
        hdr_1.ipv4.setInvalid();
		//hdr_1.ipv4_option.setInvalid();
#ifdef IPV6_ENABLE
        hdr_1.ipv6.setInvalid();
#endif  /* IPV6_ENABLE */

		invalidate_tunneling_headers();
	}

    // -------------------------------------
	// Decap L2
    // -------------------------------------

	action decap_l2() {
        hdr_1.ethernet.setInvalid();
		hdr_1.e_tag.setInvalid();
		hdr_1.vn_tag.setInvalid();
        hdr_1.vlan_tag[0].setInvalid(); // extreme added
        hdr_1.vlan_tag[1].setInvalid(); // extreme added
	}

    // -------------------------------------
	// Apply
    // -------------------------------------

    apply {
//		hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope - 1;
//		TunnelDecapScopeDecrement.apply(hdr_0);
#ifdef TUNNEL_ENABLE
		// Decap L2
        if(tunnel.terminate)
            decap_l2();

		// Decap L3
		if(tunnel.terminate)
			decap_ip();

		// Decap L4
        if(tunnel.terminate)
            decap_l4();
#endif /* TUNNEL_ENABLE */
    }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Inner
//-----------------------------------------------------------------------------

control TunnelDecapInner(
    inout switch_header_transport_t hdr_0,
    inout switch_header_inner_t hdr_2,
    in    switch_egress_metadata_t eg_md,
    in    switch_tunnel_metadata_t tunnel
) (
    switch_tunnel_mode_t mode
) {

    // -------------------------------------
	// Decap L4
    // -------------------------------------

	action decap_l4() {
        hdr_2.tcp.setInvalid();
        hdr_2.udp.setInvalid();
	}

    // -------------------------------------
	// Decap L3
    // -------------------------------------

	// helper functions

    action invalidate_tunneling_headers() {
        // Removing tunneling headers by default.

        // -------------------------------------
        // Extreme Networks - Added
        // -------------------------------------

#ifdef PARDE_INNER_GRE_ENABLE
		hdr_2.gre.setInvalid();
#endif
    }

    // -------------------------------------

	action decap_ip() {
        hdr_2.ipv4.setInvalid();
#ifdef IPV6_ENABLE
        hdr_2.ipv6.setInvalid();
#endif  /* IPV6_ENABLE */

        invalidate_tunneling_headers();
	}

    // -------------------------------------
	// Decap L2
    // -------------------------------------

	action decap_l2() {
        hdr_2.ethernet.setInvalid();
        hdr_2.vlan_tag[0].setInvalid(); // extreme added
	}

    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {
//		hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope - 1;
//		TunnelDecapScopeDecrement.apply(hdr_0);

		// Decap L2
        if(tunnel.terminate) {
			decap_l2();
		}

		// Decap L3
		if(tunnel.terminate) {
			decap_ip();
		}

		// Decap L4
		if(tunnel.terminate) {
			decap_l4();
		}
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
    switch_uint32_t nexthop_rewrite_table_size=512,
    switch_uint32_t src_addr_rewrite_table_size=1024,
    switch_uint32_t smac_rewrite_table_size=1024
) {

    EgressBd(BD_TABLE_SIZE) egress_bd;
    switch_smac_index_t smac_index;

    // -------------------------------------
	// Table: Nexthop Rewrite (DMAC & BD)
    // -------------------------------------

    // Outer nexthop rewrite
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr_0.ethernet.dst_addr = dmac;
    }

    table nexthop_rewrite {
        key = {
            eg_md.outer_nexthop : exact;
        }

        actions = {
            NoAction;
            rewrite_tunnel;
        }

        const default_action = NoAction;
        size = nexthop_rewrite_table_size;
    }

    // -------------------------------------
	// Table: SIP Rewrite
    // -------------------------------------
#ifdef ERSPAN_EGRESS_ENABLE

    // Tunnel source IP rewrite
    action rewrite_ipv4_src(ipv4_addr_t src_addr) {
        hdr_0.ipv4.src_addr = src_addr;
    }

    table src_addr_rewrite {
        key = { eg_md.bd : exact; }
        actions = {
            rewrite_ipv4_src;
        }

        size = src_addr_rewrite_table_size;
    }

    // -------------------------------------
	// Table: DIP Rewrite
    // -------------------------------------

    // Tunnel destination IP rewrite
    action rewrite_ipv4_dst(ipv4_addr_t dst_addr) {
        hdr_0.ipv4.dst_addr = dst_addr;
    }

    table ipv4_dst_addr_rewrite {
        key = { tunnel.index : exact; }
        actions = { rewrite_ipv4_dst; }
//      const default_action = rewrite_ipv4_dst(0); // extreme modified!
        size = ipv4_dst_addr_rewrite_table_size;
    }
#endif /* ERSPAN_EGRESS_ENABLE */

    // -------------------------------------
	// Table: SMAC Rewrite
    // -------------------------------------

    // Tunnel source MAC rewrite
    action rewrite_smac(mac_addr_t smac) {
        hdr_0.ethernet.src_addr = smac;
    }

    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        const default_action = NoAction;
        size = smac_rewrite_table_size;
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
#ifdef ERSPAN_EGRESS_ENABLE
        if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
            src_addr_rewrite.apply();

        if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            if (hdr_0.ipv4.isValid()) {
                ipv4_dst_addr_rewrite.apply();
            }
        }
#endif /* ERSPAN_EGRESS_ENABLE */

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
    inout switch_egress_metadata_t eg_md,
    inout switch_tunnel_metadata_t tunnel_
) (
    switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
    switch_uint32_t vni_mapping_table_size=1024
) {

    bit<16> payload_len;
    bit<8> ip_proto;

    // -------------------------------------

    action set_vni(switch_tunnel_id_t id) {
        tunnel_.id = id;
    }

    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }

        actions = {
            NoAction;
            set_vni;
        }

        size = vni_mapping_table_size;
    }

	//=============================================================================
	// Copy L3/4 Outer -> Inner
	//=============================================================================

#ifdef ERSPAN_EGRESS_ENABLE
    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields.
        hdr_0.ipv4.setInvalid();  // is this supposed to be transport hdr_0?
    }
#endif /* ERSPAN_EGRESS_ENABLE */


    action rewrite_inner_ipv4_udp() {
        payload_len = hdr_1.ipv4.total_len;
#ifdef ERSPAN_EGRESS_ENABLE
        copy_ipv4_header();
#endif /* ERSPAN_EGRESS_ENABLE */

        ip_proto = IP_PROTOCOLS_IPV4;
    }

    action rewrite_inner_ipv4_unknown() {
        payload_len = hdr_1.ipv4.total_len;
#ifdef ERSPAN_EGRESS_ENABLE
        copy_ipv4_header();
#endif /* ERSPAN_EGRESS_ENABLE */
        ip_proto = IP_PROTOCOLS_IPV4;
    }

#ifdef IPV6_ENABLE
    action rewrite_inner_ipv6_udp() {
        payload_len = hdr_1.ipv6.payload_len + 16w40;
        ip_proto = IP_PROTOCOLS_IPV6;
    }

    action rewrite_inner_ipv6_unknown() {
        payload_len = hdr_1.ipv6.payload_len + 16w40;
        ip_proto = IP_PROTOCOLS_IPV6;
    }
#endif  /* IPV6_ENABLE */

    table encap_outer {
        key = {
            hdr_1.ipv4.isValid() : exact;
#ifdef IPV6_ENABLE
            hdr_1.ipv6.isValid() : exact;
#endif  /* IPV6_ENABLE */
            hdr_1.udp.isValid() : exact;
            // hdr_1.tcp.isValid() : exact;
        }

        actions = {
            rewrite_inner_ipv4_udp;
            rewrite_inner_ipv4_unknown;
#ifdef IPV6_ENABLE
            rewrite_inner_ipv6_udp;
            rewrite_inner_ipv6_unknown;
#endif  /* IPV6_ENABLE */
        }

        const entries = {
#ifdef IPV6_ENABLE
            (true, false, false) : rewrite_inner_ipv4_unknown();
            (false, true, false) : rewrite_inner_ipv6_unknown();
            (true, false, true) : rewrite_inner_ipv4_udp();
            (false, true, true) : rewrite_inner_ipv6_udp();
#else
            (true,  false) : rewrite_inner_ipv4_unknown();
            (true,  true) : rewrite_inner_ipv4_udp();
#endif  /* IPV6_ENABLE */

        }
    }

	//=============================================================================
	// Copy L2 Outer -> Inner
    // Writes Tunnel header, rewrites some of Outer
	//=============================================================================

    //-----------------------------------------------------------------------------
    // Helper actions to add various headers.
    //-----------------------------------------------------------------------------

    // there is no UDP supported inthe transport
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

#ifdef ERSPAN_EGRESS_ENABLE
    action add_gre_header(bit<16> proto, bit<1> K, bit<1> S) {
#ifdef GRE_ENABLE
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
#ifdef GRE_ENABLE
		hdr_0.gre_sequence.setValid();
		hdr_0.gre_sequence.seq_num = 0;
#endif
	}
#endif /* ERSPAN_EGRESS_ENABLE */

	action add_l2_header() { 
        hdr_0.ethernet.setValid();
	}

    // -------------------------------------

#ifdef ERSPAN_EGRESS_ENABLE
    action add_erspan_header_type2(bit<10> session_id) {
        hdr_0.erspan_type2.setValid();
        hdr_0.erspan_type2.version = 4w0x1;
        hdr_0.erspan_type2.vlan = 0;
        hdr_0.erspan_type2.cos_en_t = 0;
        hdr_0.erspan_type2.session_id = (bit<10>) 0;
//        hdr_0.erspan_type2.reserved = 0;
//        hdr_0.erspan_type2.index = 0;
    }

    action add_erspan_header(bit<32> timestamp, bit<10> session_id) {
        hdr_0.erspan_type3.setValid();
        hdr_0.erspan_type3.timestamp = timestamp;
        hdr_0.erspan_type3.session_id = (bit<10>) session_id;
        hdr_0.erspan_type3.version = 4w0x2;
        hdr_0.erspan_type3.sgt = 0;
        hdr_0.erspan_type3.vlan = 0;
    }
#endif /* ERSPAN_EGRESS_ENABLE */

    // -------------------------------------

#ifdef ERSPAN_EGRESS_ENABLE
    action add_ipv4_header(bit<8> proto) {
        hdr_0.ipv4.setValid();
        hdr_0.ipv4.version = 4w4;
        hdr_0.ipv4.ihl = 4w5;
        // hdr_0.ipv4.total_len = 0;
        hdr_0.ipv4.identification = 0;
        hdr_0.ipv4.flags = 0;
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
    }
#endif /* ERSPAN_EGRESS_ENABLE */

    //-----------------------------------------------------------------------------
    // Actual actions.
    //-----------------------------------------------------------------------------

    // =====================================
    // ----- Rewrite, IPv4 Stuff -----
    // =====================================

	action rewrite_ipv4_erspan() {
#ifdef ERSPAN_EGRESS_ENABLE
		add_l2_header();
        // ----- l3 -----
        add_ipv4_header(IP_PROTOCOLS_GRE);
        // Total length = packet length + 36
        //   IPv4 (20) + GRE (4) + ERSPAN (12)
        hdr_0.ipv4.total_len = payload_len + 16w50; // 20 V4 + 8 GRE + 8 ERSPAN + 14 ETHERNET

        // ----- tunnel -----
        add_gre_header(GRE_PROTOCOLS_ERSPAN_TYPE_2, 0, 1);
		add_gre_header_seq();
		add_erspan_header_type2();

        // ----- l2 -----
        hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
#endif /* ERSPAN_EGRESS_ENABLE */
	}

    // =====================================
    // ----- Rewrite, IPv6 Stuff -----
    // =====================================

    // -------------------------------------
    // Extreme Networks - Added
    // -------------------------------------

    action rewrite_mac_in_mac() {
		add_l2_header();
        hdr_0.ethernet.ether_type = ETHERTYPE_NSH;
    }

    // -------------------------------------

    table tunnel {
        key = {
            tunnel_.type : exact;
        }

        actions = {
            NoAction;

            rewrite_mac_in_mac;   // extreme added
            rewrite_ipv4_erspan;  // extreme added
        }

        const default_action = NoAction;

	    // ---------------------------------
	    // Extreme Networks - Added
	    // ---------------------------------
		/*
		// Note that this table should just be programmed with the
		// following constants, but the language doesn't seem to allow it....
		const entries = {
			(SWITCH_TUNNEL_TYPE_NSH)      = rewrite_mac_in_mac();  // extreme added
			(SWITCH_TUNNEL_TYPE_GRE)      = rewrite_ipv4_gre();    // extreme added
			(SWITCH_TUNNEL_TYPE_ERSPAN)   = rewrite_ipv4_erspan(); // extreme added
		}
		*/
	    // ---------------------------------
    }

	//=============================================================================
	// Apply
	//=============================================================================

    apply {
#ifdef TUNNEL_ENABLE
        if (tunnel_.type != SWITCH_TUNNEL_TYPE_NONE && tunnel_.id == 0)
            bd_to_vni_mapping.apply();

        if (tunnel_.type != SWITCH_TUNNEL_TYPE_NONE) {
            // Copy L3/L4 header into inner headers.
            encap_outer.apply();

            // Add outer L3/L4/Tunnel headers.
            tunnel.apply();
        }
#endif /* TUNNEL_ENABLE */
    }
}

#endif
