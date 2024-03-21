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

#include <core.p4>
#if __TARGET_TOFINO__ == 2
  #include <t2na.p4>
#else
  #include <tna.p4>
#endif

#include "features.p4"
#include "headers.p4"
#include "types.p4"
#include "table_sizes.p4"
#include "util.p4"
#include "l3.p4"
#include "nexthop.p4"

#include "npb_ing_parser.p4"
#include "npb_ing_deparser.p4"
#include "npb_egr_parser.p4"
#include "npb_egr_deparser.p4"

#include "port.p4"

#ifdef VALIDATION_ENABLE
  #include "validation.p4"
#endif /* VALIDATION_ENABLE */

#include "rewrite.p4"
#include "tunnel.p4"

#include "npb_ing_top.p4"
#include "npb_egr_top.p4"

#ifdef ING_HDR_STACK_COUNTERS
  #include "npb_ing_hdr_stack_counters.p4"
#endif

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchIngress(
    inout switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

    // ---------------------------------------------------------------------

    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE, PORT_TABLE_SIZE, VLAN_TABLE_SIZE) ingress_port_mapping;

#ifdef VALIDATION_ENABLE
    PktValidation() pkt_validation_0;
    OuterPktValidation() pkt_validation_1;
    InnerPktValidation() pkt_validation_2;
#endif /* VALIDATION_ENABLE */

    DMAC(MAC_TABLE_SIZE) dmac;
//  IngressBd(BD_TABLE_SIZE) bd_stats;
//  IngressUnicast(RMAC_TABLE_SIZE) unicast;
	IngressTunnelRMAC(RMAC_TABLE_SIZE) rmac;

    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterFib(OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
    LAG() lag;
    TunnelDecapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_decap_transport_ingress;

    // ---------------------------------------------------------------------

    apply {

		// would like to do this stuff in the parser, but can't because tos
		// field isn't byte aligned...
		if(hdr.outer.ipv6.isValid()) {
			ig_md.lkp.ip_tos = hdr.outer.ipv6.tos;
		}        
		if(hdr.inner.ipv6.isValid()) {
			ig_md.lkp_2.ip_tos = hdr.inner.ipv6.tos;
		}

		// would like to do this stuff in the parser, but get the following error:
        //   "error: Field is extracted in the parser into multiple containers, but
        //    the container slices after the first aren't byte aligned"
/*
		if(hdr.outer.ipv4.isValid()) {
			ig_md.lkp.ip_tos = hdr.outer.ipv4.tos;
		}        
		if(hdr.inner.ipv4.isValid()) {
			ig_md.lkp_2.ip_tos = hdr.inner.ipv4.tos;
		}
*/

        
#ifdef ING_HDR_STACK_COUNTERS
        IngressHdrStackCounters.apply(hdr);
#endif  /* ING_HDR_STACK_COUNTERS */

        // -----------------------------------------------------

        ig_intr_md_for_dprsr.drop_ctl = 0;
        ig_md.multicast.id = 0;

#ifndef ING_STUBBED_OUT

#ifdef VALIDATION_ENABLE
#ifdef TRANSPORT_ENABLE
		if(hdr.transport.ethernet.isValid()) {
            pkt_validation_0.apply(hdr.transport, ig_md.flags.ipv4_checksum_err_0, ig_md.tunnel_0, ig_md.lkp, ig_md.drop_reason_0);
		}
#endif
		if(ig_md.tunnel_0.type != SWITCH_TUNNEL_TYPE_NONE) {
			pkt_validation_1.apply(hdr.outer, ig_md.flags.ipv4_checksum_err_1, ig_md.tunnel_1, ig_md.lkp, ig_md.drop_reason_1);
		} 
		if(ig_md.tunnel_1.type != SWITCH_TUNNEL_TYPE_NONE) {
			pkt_validation_2.apply(hdr.inner, ig_md.flags.ipv4_checksum_err_2, ig_md.tunnel_2, ig_md.lkp, ig_md.drop_reason_2);
		} 
#endif /* VALIDATION_ENABLE */

        ingress_port_mapping.apply(hdr.transport, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

//      unicast.apply(hdr.transport, ig_md);
        rmac.apply(hdr.transport, ig_md);

		// -------------------------------------------------------------------------------------------------------------------------------------
		// | transport  | transport | trasnport |
		// | eth valid  | our mac   | nsh valid | result
		// +------------+-----------+-----------+----------------
		// | 0          | x         | x         | sfc, sf(s), sff (optically tapped,     to us) -> sfc outer validate table
		// | 1          | 0         | 0         | l2 bridge       (normally  tapped, not to us)
		// | 1          | 0         | 1         | l2 bridge       (internal  fabric, not to us)
		// | 1          | 1         | 0         | sfc, sf(s), sff (normally  tapped,     to us) -> sfc transport decap/validate table + sap mapping table
		// | 1          | 1         | 1         | ---, sf(s), sff (internal  fabric,     to us) -> sfc no tables...instead grab fields from nsh header
		// -------------------------------------------------------------------------------------------------------------------------------------

		if((hdr.transport.ethernet.isValid() == false) || ((hdr.transport.ethernet.isValid() == true) && (ig_md.flags.rmac_hit == true))) {

            npb_ing_top.apply (
                hdr.transport,
                hdr.outer,
                hdr.inner,
                hdr.l7_udf,
                ig_md.tunnel_0,
                ig_md.tunnel_1,
                ig_md.tunnel_2,

				ig_md,
                ig_intr_md,
                ig_intr_from_prsr,
                ig_intr_md_for_dprsr,
                ig_intr_md_for_tm
            );

        } else {
#ifdef BRIDGING_ENABLE
  #ifdef BRIDGING_L2_FWD_EN_SIGNAL_ENABLE
			if(ig_md.nsh_type1.l2_fwd_en) {
	            dmac.apply(hdr.transport.ethernet.dst_addr, ig_md);
			}
  #else
            dmac.apply(hdr.transport.ethernet.dst_addr, ig_md);
  #endif
#endif // BRIDGING ENABLE
        }

        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE)
            compute_non_ip_hash(ig_md.lkp, ig_md.hash);
        else
            compute_ip_hash(ig_md.lkp, ig_md.hash);

        nexthop.apply(ig_md.lkp, ig_md, ig_md.hash[15:0]);
        outer_fib.apply(ig_md, ig_md.hash[31:16]);

        lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);

        add_bridged_md(hdr.bridged_md, ig_md);

        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);

#ifndef BUG_10015_WORKAROUND
		tunnel_decap_transport_ingress.apply(hdr.transport, ig_md, ig_md.tunnel_0);
#endif

#else   /* ING_STUBBED_OUT */

        add_bridged_md(hdr.bridged_md, ig_md);

        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);

#ifndef BUG_10015_WORKAROUND
		tunnel_decap_transport_ingress.apply(hdr.transport, ig_md, ig_md.tunnel_0);
#endif

#endif  /* ING_STUBBED_OUT */
    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchEgress(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

    // -------------------------------------------------------------------------

    EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
#ifdef BUG_10015_WORKAROUND
    TunnelDecapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_decap_transport_ingress;
#endif
    TunnelDecapTransportEgress(switch_tunnel_mode_t.PIPE) tunnel_decap_transport_egress;
//  VlanDecap() vlan_decap;
    Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
    TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
    TunnelRewrite() tunnel_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
//	NSHTypeFixer() nsh_type_fixer;

    // -------------------------------------------------------------------------

    apply {

        eg_intr_md_for_dprsr.drop_ctl = 0;
//      eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
        egress_port_mapping.apply(hdr.transport, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

#ifndef EGR_STUBBED_OUT

		if((hdr.transport.nsh_type1.isValid() == true)) {

	        npb_egr_top.apply (
	            hdr.transport,
	            hdr.outer,
	            hdr.inner,
                eg_md.tunnel_1,
                eg_md.tunnel_2,

	            eg_md,
	            eg_intr_md,
	            eg_intr_md_from_prsr,
	            eg_intr_md_for_dprsr,
	            eg_intr_md_for_oport
	        );

		}

//      vlan_decap.apply(hdr.transport, eg_md);
#ifdef BUG_10015_WORKAROUND
        tunnel_decap_transport_ingress.apply(hdr.transport, eg_md, eg_md.tunnel_0);
#endif
        tunnel_decap_transport_egress.apply(hdr.transport, eg_md, eg_md.tunnel_0, eg_md.nsh_terminate);
        rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
        tunnel_encap.apply(hdr.transport, hdr.outer, eg_md, eg_md.tunnel_0);
        tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);

        vlan_xlate.apply(hdr.transport, eg_md);
//		nsh_type_fixer.apply(hdr.transport);

#endif  /* EGR_STUBBED_OUT */
    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

Pipeline(
        NpbIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        NpbEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
