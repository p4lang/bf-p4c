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
#include "field_widths.p4"
#include "table_sizes.p4"
#include "headers.p4"
#include "types.p4"
#include "util.p4"

#include "l3.p4"
#include "nexthop.p4"
#include "port.p4"
#include "validation.p4"
#include "rewrite.p4"
#include "tunnel.p4"
#include "multicast.p4"
#include "copp.p4"
#include "dtel.p4"

#include "npb_ing_parser.p4"
#include "npb_ing_set_lkp.p4"
#include "npb_ing_top.p4"
#include "npb_ing_deparser.p4"
#include "npb_egr_parser.p4"
#include "npb_egr_set_lkp.p4"
#include "npb_egr_top.p4"
#include "npb_egr_deparser.p4"

#ifdef ING_HDR_STACK_COUNTERS
  #include "npb_ing_hdr_stack_counters.p4"
#endif

//@pa_auto_init_metadata

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
#ifdef BRIDGING_ENABLE
	DMAC(MAC_TABLE_SIZE) dmac;
#endif
//	IngressBd(BD_TABLE_SIZE) bd_stats;
//	IngressUnicast(RMAC_TABLE_SIZE) unicast;
	Ipv4Hash() ipv4_hash;
	Ipv6Hash() ipv6_hash;
	NonIpHash() non_ip_hash;
  	IngressIpAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
	Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
	OuterFib(OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
	LAG() lag;
  	IngressDtel() dtel;

	// ---------------------------------------------------------------------

	apply {

		ig_intr_md_for_dprsr.drop_ctl = 0;  // no longer present in latest switch.p4
		ig_md.multicast.id = 0;             // no longer present in latest switch.p4

#ifdef PARSER_ERROR_HANDLING_ENABLE
        ParserValidation.apply(hdr, ig_md, ig_intr_from_prsr, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif // PARSER_ERROR_HANDLING_ENABLE
        
		IngressSetLookup.apply(hdr, ig_md);  // set lookup structure fields that parser couldn't        
        
#ifdef ING_HDR_STACK_COUNTERS
		IngressHdrStackCounters.apply(hdr);
#endif  /* ING_HDR_STACK_COUNTERS */

		// -----------------------------------------------------

#ifndef ING_STUBBED_OUT

#ifdef VALIDATION_ENABLE
#ifdef TRANSPORT_ENABLE
		if(hdr.transport.ethernet.isValid()) {
			pkt_validation_0.apply(hdr.transport, ig_md.flags.ipv4_checksum_err_0, ig_md.tunnel_0, ig_md.lkp_1, ig_md.drop_reason_0);
		}
#endif
		if(ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) {
			pkt_validation_1.apply(hdr.outer, ig_md.flags.ipv4_checksum_err_1, ig_md.tunnel_1, ig_md.lkp_1, ig_md.drop_reason_1);
		} 
		if(ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) {
			pkt_validation_2.apply(hdr.inner, ig_md.flags.ipv4_checksum_err_2, ig_md.tunnel_2, ig_md.lkp_1, ig_md.drop_reason_2);
		} 
#endif /* VALIDATION_ENABLE */

		ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

//		unicast.apply(hdr.transport, ig_md);

#ifdef BRIDGING_ENABLE
		if((ig_md.flags.rmac_hit == false) && (ig_md.nsh_md.l2_fwd_en == true)) {
			// ----- Bridging Path -----
            
	// the new parser puts bridging in outer
    #ifdef INGRESS_PARSER_POPULATES_LKP_1
			dmac.apply(ig_md.lkp_1.mac_dst_addr, ig_md);
    #else
			dmac.apply(hdr.outer.ethernet.dst_addr, ig_md);
    #endif

		} else {
			// ----- NPB Path -----
#endif // BRIDGING ENABLE
			npb_ing_top.apply (
				hdr.transport,
				ig_md.tunnel_0,
				hdr.outer,
				ig_md.tunnel_1,
				hdr.inner,
				ig_md.tunnel_2,
				hdr.inner_inner,
				hdr.udf,

				ig_md,
				ig_intr_md,
				ig_intr_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
#ifdef BRIDGING_ENABLE
		}
#endif // BRIDGING ENABLE

#ifdef LAG_HASH_MASKING_ENABLE
		// if lag hash masking enabled, move this before the hash
		nexthop.apply(ig_md);
		outer_fib.apply(ig_md);
#endif

		HashMask.apply(ig_md.lkp_1, ig_md.egress_port_lag_hash_sel);

		if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
			non_ip_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
		} else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
			ipv4_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
		} else {
			ipv6_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
		}

#ifndef LAG_HASH_MASKING_ENABLE
		// this code should be removed if lag hash masking ever fits
		nexthop.apply(ig_md);
		outer_fib.apply(ig_md);
#endif

#ifdef LAG_HASH_IN_NSH_HDR_ENABLE
		hdr.transport.nsh_type1.lag_hash = ig_md.hash[switch_lag_hash_width-1:switch_lag_hash_width/2];
#endif

		if (ig_md.egress_port_lag_index == SWITCH_FLOOD) {
		} else {
//			lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
			lag.apply(ig_md, ig_md.hash[switch_lag_hash_width-1:switch_lag_hash_width/2], ig_intr_md_for_tm.ucast_egress_port);
		}

		IngressCopp.apply(ig_md.copp_enable, ig_md.copp_meter_id, ig_md, ig_intr_md_for_tm);

		// Only add bridged metadata if we are NOT bypassing egress pipeline.
		if (ig_intr_md_for_tm.bypass_egress == 1w0) {
			add_bridged_md(hdr.bridged_md, ig_md);
		}

//		ingress_ip_dtel_acl.apply(ig_md, ig_md.unused_nexthop);
//		dtel.apply(hdr, ig_md.lkp_1, ig_md, ig_md.hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);

		set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);

#else   /* ING_STUBBED_OUT */

		// Only add bridged metadata if we are NOT bypassing egress pipeline.
		if (ig_intr_md_for_tm.bypass_egress == 1w0) {
			add_bridged_md(hdr.bridged_md, ig_md);
		}

		set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);

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

	EgressSetLookup() egress_set_lookup;    
	EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
	VlanDecap() vlan_decap;
	Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
	TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
	TunnelRewrite() tunnel_rewrite;
	VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
//	NSHTypeFixer() nsh_type_fixer;
//	MulticastReplication(RID_TABLE_SIZE) multicast_replication;
	MulticastReplication(NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE) multicast_replication;
  	EgressDtel() dtel;
  	DtelConfig() dtel_config;

	// -------------------------------------------------------------------------

	apply {

		eg_intr_md_for_dprsr.drop_ctl = 0;
//		eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];

		egress_set_lookup.apply(hdr, eg_md);  // set lookup structure fields that parser couldn't                

		egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

		multicast_replication.apply (
			hdr.transport,
			eg_intr_md.egress_rid,
			eg_intr_md.egress_port,
			eg_md
		);

#ifndef EGR_STUBBED_OUT

#ifdef BRIDGING_ENABLE
		if((eg_md.flags.rmac_hit == false) && (eg_md.nsh_md.l2_fwd_en == true)) {
			// do nothing (bridging the packet)
		} else {
#endif // BRIDGING_ENABLE
			npb_egr_top.apply (
				hdr.transport,
				eg_md.tunnel_0,
				hdr.outer,
				eg_md.tunnel_1,
				hdr.inner,
				eg_md.tunnel_2,
				hdr.inner_inner,

				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
#ifdef BRIDGING_ENABLE
		}
#endif // BRIDGING_ENABLE

		// nexthop -- operates on 'outer'
		rewrite.apply(hdr.outer, eg_md, eg_md.tunnel_0);

		// outer nexthop (tunnel) -- operates on 'transport'
		vlan_decap.apply(hdr.transport, eg_md);
		tunnel_encap.apply(hdr.transport, hdr.outer, eg_md, eg_md.tunnel_0);
		tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
		vlan_xlate.apply(hdr.transport, eg_md);

		EgressCopp.apply(eg_md.copp_enable, eg_md.copp_meter_id, eg_md, eg_intr_md_for_dprsr);

//		dtel.apply(hdr, eg_md, eg_intr_md, eg_md.dtel.hash);
//		dtel_config.apply(hdr, eg_md, eg_intr_md_for_dprsr);

		set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

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
