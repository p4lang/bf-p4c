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

#if __TARGET_TOFINO__ == 1
  #include "features_t1.p4"
#else
  #ifdef PROFILE_EGRESS_TRANSPORT
    #include "features_t2_egress_transport.p4"
  #else //PROFILE_EGRESS_TRANSPORT
    #ifdef PROFILE_BETA
      #include "features_t2_beta.p4"
    #else // PROFILE_BETA
      #include "features_t2.p4"
    #endif // PROFILE_BETA
  #endif //PROFILE_EGRESS_TRANSPORT
#endif
#include "field_widths.p4"
#include "table_sizes.p4"
#include "headers.p4"
#include "types.p4"
#include "util.p4"

#include "l3.p4"
#include "nexthop.p4"
#include "port.p4"
//#include "validation.p4"
#include "rewrite.p4"
#include "tunnel.p4"
#include "multicast.p4"
#include "meter.p4"
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

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// List pragmas here that are needed to function properly
@pa_auto_init_metadata
@pa_no_overlay("ingress", "hdr.transport.ipv4.src_addr")
@pa_no_overlay("ingress", "hdr.transport.ipv4.dst_addr")

#ifdef PA_MONOGRESS
@pa_parser_group_monogress  //grep for monogress in phv_allocation log to confirm
#endif
#ifdef PA_NO_INIT
@pa_no_init("ingress", "ig_intr_md_for_tm.bypass_egress")  // reset in port.p4
@pa_no_init("egress",  "eg_md.tunnel_1.terminate")         // reset in npb_egr_parser.p4
@pa_no_init("egress",  "eg_md.lkp_1.next_lyr_valid")       // reset in npb_egr_set_lkp.p4
@pa_no_init("egress",  "eg_intr_md_for_dprsr.mirror_type") // reset in this file (below)
@pa_no_init("ingress", "ig_md.tunnel_2.terminate")         // reset in npb_ing_parser.p4
//@pa_no_init("ingress", "ig_md.mirror.src")                 // reset in this file (below) NOT NEEDED
#endif // PA_NO_INIT

// Add pragmas to pragmas.p4 that are needed to fit design
#include "pragmas.p4"


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

	IngressSetLookup() ingress_set_lookup;
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
// 	IngressIpAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
	IngressMirrorMeter() ingress_mirror_meter;
//	IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
	Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
#ifdef SEPARATE_NEXTHOP_AND_OUTER_NEXTHOP_ENABLE
	OuterFib(OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
#endif
	LAG() lag;
  	IngressDtel() dtel;

	// ---------------------------------------------------------------------

	apply {

		ig_intr_md_for_dprsr.drop_ctl = 0;  // no longer present in latest switch.p4
		ig_md.multicast.id = 0;             // no longer present in latest switch.p4
#ifdef PA_NO_INIT
//		ig_md.mirror.src = SWITCH_PKT_SRC_BRIDGED; // for barefoot reset bug NOT NEEDED
#endif

#if defined(PARSER_ERROR_HANDLING_ENABLE)
        //ParserValidation.apply(hdr, ig_md, ig_intr_from_prsr, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif // if defined(PARSER_ERROR_HANDLING_ENABLE)

		ingress_set_lookup.apply(hdr, ig_md);  // set lookup structure fields that parser couldn't

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

		ingress_mirror_meter.apply(ig_md);

#ifdef LAG_HASH_MASKING_ENABLE
		// if lag hash masking enabled, move this before the hash
		nexthop.apply(ig_md);
  #ifdef SEPARATE_NEXTHOP_AND_OUTER_NEXTHOP_ENABLE
		outer_fib.apply(ig_md);
  #endif
#endif
		HashMask.apply(ig_md.lkp_1, ig_md.nsh_md.lag_hash_mask_en);

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
  #ifdef SEPARATE_NEXTHOP_AND_OUTER_NEXTHOP_ENABLE
		outer_fib.apply(ig_md);
  #endif
#endif

//#ifdef LAG_HASH_IN_NSH_HDR_ENABLE
//		hdr.transport.nsh_type1.lag_hash = ig_md.hash[switch_lag_hash_width-1:switch_lag_hash_width/2];
//#endif

		if (ig_md.egress_port_lag_index == SWITCH_FLOOD) {
		} else {
//			lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
			lag.apply(ig_md, ig_md.hash[switch_lag_hash_width-1:switch_lag_hash_width/2], ig_intr_md_for_tm.ucast_egress_port);
		}

		// Only add bridged metadata if we are NOT bypassing egress pipeline.
		if (ig_intr_md_for_tm.bypass_egress == 1w0) {
			add_bridged_md(hdr.bridged_md, ig_md);
		}
#ifdef DTEL_ENABLE
//		ingress_ip_dtel_acl.apply(ig_md, ig_md.unused_nexthop);
		dtel.apply(hdr.outer, ig_md.lkp_1, ig_md, ig_md.hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif
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
	EgressPortMapping2(PORT_TABLE_SIZE) egress_port_mapping2;
	EgressMirrorMeter() egress_mirror_meter;
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

//		eg_intr_md_for_dprsr.drop_ctl = 0;
		eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
#ifdef PA_NO_INIT
		eg_intr_md_for_dprsr.mirror_type = SWITCH_MIRROR_TYPE_INVALID;// for barefoot reset bug
#endif

		egress_set_lookup.apply(hdr, eg_md);  // set lookup structure fields that parser couldn't

		egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

#ifndef EGR_STUBBED_OUT
        
		if (eg_md.flags.bypass_egress == false) {
			multicast_replication.apply (
				hdr.transport,
				eg_intr_md.egress_rid,
				eg_intr_md.egress_port,
				eg_md
			);

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

			egress_mirror_meter.apply(eg_md);

			// ----- nexthop               code: operates on 'outer' ----
			rewrite.apply(hdr.outer, eg_md, eg_md.tunnel_0);
//			npb_egr_sf_proxy_hdr_strip.apply(hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
//			npb_egr_sf_proxy_hdr_edit.apply (hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

			// ---- outer nexthop (tunnel) code: operates on 'transport' ----
			vlan_decap.apply(hdr.transport, eg_md);
			tunnel_encap.apply(hdr.transport, hdr.outer, hdr.inner, hdr.inner_inner, eg_md, eg_md.tunnel_0, eg_md.tunnel_1, eg_md.tunnel_2);
			tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
			vlan_xlate.apply(hdr.transport, eg_md);

#ifdef DTEL_ENABLE
			dtel.apply(hdr.outer, eg_md, eg_intr_md, eg_md.dtel.hash);
			dtel_config.apply(hdr.outer, eg_md, eg_intr_md_for_dprsr);
#endif
		}
		egress_port_mapping2.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

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
