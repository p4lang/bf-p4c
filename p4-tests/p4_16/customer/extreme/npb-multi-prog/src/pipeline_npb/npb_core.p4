#ifndef _NPB_CORE_
#define _NPB_CORE_

#include <core.p4>
#if __TARGET_TOFINO__ == 2
  #include <t2na.p4>
#else
  #include <tna.p4>
#endif

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control IngressControl(
	inout switch_header_t hdr,
	inout switch_ingress_metadata_t ig_md,
	in ingress_intrinsic_metadata_t ig_intr_md,
	in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
	MODULE_DEPLOYMENT_PARAMS
) {

	// ---------------------------------------------------------------------

	IngressSetLookup(INSTANCE_DEPLOYMENT_PARAMS) ingress_set_lookup;
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
	Ipv4HashSymmetric() ipv4_hash_symmetric;
	Ipv6HashSymmetric() ipv6_hash_symmetric;
	NonIpHashSymmetric() non_ip_hash_symmetric;
// 	IngressIpAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
	IngressMirrorMeter() ingress_mirror_meter;
//	IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
	Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
#ifdef SEPARATE_NEXTHOP_AND_OUTER_NEXTHOP_ENABLE
	OuterFib(OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
#endif
	LAG(LAG_SELECTOR_TABLE_SIZE, LAG_MAX_MEMBERS_PER_GROUP, LAG_GROUP_TABLE_SIZE, LAG_TABLE_SIZE) lag;
//	MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
	AddBridgedMd(INSTANCE_DEPLOYMENT_PARAMS) add_bridged_md;
#ifdef DTEL_ENABLE
	IngressDtel(DTEL_SELECTOR_TABLE_SIZE, DTEL_MAX_MEMBERS_PER_GROUP, DTEL_GROUP_TABLE_SIZE) dtel;
#endif
	IngressHdrCntrsTransport(INSTANCE_DEPLOYMENT_PARAMS) ingress_hdr_cntrs_transport;
	IngressHdrCntrsOuter(INSTANCE_DEPLOYMENT_PARAMS) ingress_hdr_cntrs_outer;
	IngressHdrCntrsInner(INSTANCE_DEPLOYMENT_PARAMS) ingress_hdr_cntrs_inner;
	IngressHdrCntrsMisc(INSTANCE_DEPLOYMENT_PARAMS) ingress_hdr_cntrs_misc;
	Npb_Ing_Top(INSTANCE_DEPLOYMENT_PARAMS) npb_ing_top;

	// ---------------------------------------------------------------------

	apply {

//		ig_intr_md_for_dprsr.drop_ctl = 0;  // no longer present in latest switch.p4
//		ig_md.multicast.id = 0;             // no longer present in latest switch.p4
#ifdef PA_NO_INIT
//		ig_md.mirror.src = SWITCH_PKT_SRC_BRIDGED; // for barefoot reset bug NOT NEEDED
#endif

#if defined(PARSER_ERROR_HANDLING_ENABLE)
        //ParserValidation.apply(hdr, ig_md, ig_intr_from_prsr, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif // if defined(PARSER_ERROR_HANDLING_ENABLE)

		ingress_set_lookup.apply(hdr, ig_md);  // set lookup structure fields that parser couldn't

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

		if(INGRESS_ENABLE == true) {

#ifdef ING_HDR_STACK_COUNTERS
		    ingress_hdr_cntrs_transport.apply(hdr.transport);
		    ingress_hdr_cntrs_outer.apply(hdr.outer);
		    ingress_hdr_cntrs_inner.apply(hdr.inner);
		    ingress_hdr_cntrs_misc.apply(hdr);
#endif  /* ING_HDR_STACK_COUNTERS */

//			unicast.apply(hdr.transport, ig_md);

#ifdef BRIDGING_ENABLE
			// the new parser puts bridging in outer
			dmac.apply(ig_md.lkp_1.mac_dst_addr,    ig_md.lkp_1, ig_md, hdr);
#endif // BRIDGING ENABLE

//			if((hdr.transport.ethernet.isValid() == false) && (ig_md.nsh_md.l2_fwd_en == true)) {
			if((ig_md.flags.transport_valid      == false) && (ig_md.nsh_md.l2_fwd_en == true)) {
				// ----- Bridging Path -----
			} else {
				// ----- NPB Path -----
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

#ifdef RESILIENT_ECMP_HASH_ENABLE
			if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
				compute_non_ip_hash0_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
			} else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
				compute_ipv4_hash0_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
			} else {
				compute_ipv6_hash0_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
			}

			if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
				compute_non_ip_hash1_symmetric.apply(ig_md.lkp_1, ig_md.hash[63:32]);
			} else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
				compute_ipv4_hash1_symmetric.apply(ig_md.lkp_1, ig_md.hash[63:32]);
			} else {
				compute_ipv6_hash1_symmetric.apply(ig_md.lkp_1, ig_md.hash[63:32]);
			}
#else
			if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
				non_ip_hash_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
			} else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
				ipv4_hash_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
			} else {
				ipv6_hash_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
			}
#endif

#ifndef LAG_HASH_MASKING_ENABLE
			// this code should be removed if lag hash masking ever fits
			nexthop.apply(ig_md);
  #ifdef SEPARATE_NEXTHOP_AND_OUTER_NEXTHOP_ENABLE
			outer_fib.apply(ig_md);
  #endif
#endif

//#ifdef LAG_HASH_IN_NSH_HDR_ENABLE
//			hdr.transport.nsh_type1.lag_hash = ig_md.hash[switch_hash_width-1:switch_hash_width/2];
//#endif

//			if (ig_md.egress_port_lag_index == SWITCH_FLOOD) {
//				flood.apply(ig_md);
//			} else {
//				lag.apply(ig_md.lkp_1, ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
				lag.apply(ig_md.lkp_1, ig_md, ig_md.hash, ig_intr_md_for_tm.ucast_egress_port);
//			}

		} else { // INGRESS ENABLE
			// NECESSARY STUFF JUST TO GET A VALID PACKET TO EGRESS

			// set egress port
			ig_intr_md_for_tm.ucast_egress_port = ig_md.port; // by default, set ingress port equal to egress port -- for testing
//			ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet

			// add internal nsh header
			ig_md.nsh_md.ttl = 0;
			ig_md.nsh_md.scope = 1;
			ig_md.nsh_md.end_of_path = true;

			hdr.transport.nsh_type1_internal.setValid(); // by default, egress parser expects this header -- for testing
			hdr.transport.nsh_type1_internal.ttl = ig_md.nsh_md.ttl; // by default, egress parser expects this header -- for testing
			hdr.transport.nsh_type1_internal.scope = ig_md.nsh_md.scope; // by default, egress parser expects this header -- for testing
		} // INGRESS ENABLE

		// -----------------------------------------------------

		// Only add bridged metadata if we are NOT bypassing egress pipeline.
		if (ig_intr_md_for_tm.bypass_egress == 1w0) {
			add_bridged_md.apply(hdr.bridged_md, ig_md);
		}
#ifdef DTEL_ENABLE
//		ingress_ip_dtel_acl.apply(ig_md, ig_md.unused_nexthop);
		dtel.apply(hdr.transport, ig_md.lkp_1, ig_md, ig_md.hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif
		set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);

#else   /* ING_STUBBED_OUT */

		// Only add bridged metadata if we are NOT bypassing egress pipeline.
		if (ig_intr_md_for_tm.bypass_egress == 1w0) {
			add_bridged_md.apply(hdr.bridged_md, ig_md);
		}

		set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);

#endif  /* ING_STUBBED_OUT */
	}
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control EgressControl(
	inout switch_header_t hdr,
	inout switch_egress_metadata_t eg_md,
	in egress_intrinsic_metadata_t eg_intr_md,
	in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) (
	MODULE_DEPLOYMENT_PARAMS
) {

	// -------------------------------------------------------------------------

	EgressSetLookup(INSTANCE_DEPLOYMENT_PARAMS) egress_set_lookup;
	EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
	EgressMirrorMeter() egress_mirror_meter;

	VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
	VlanDecap() vlan_decap;
//	TunnelDecap() tunnel_decap;
	TunnelNexthop(INSTANCE_DEPLOYMENT_PARAMS, NEXTHOP_TABLE_SIZE) rewrite;
	TunnelEncap(INSTANCE_DEPLOYMENT_PARAMS, switch_tunnel_mode_t.PIPE) tunnel_encap;
	TunnelRewrite(INSTANCE_DEPLOYMENT_PARAMS) tunnel_rewrite;
//	NSHTypeFixer() nsh_type_fixer;
//	MulticastReplication(RID_TABLE_SIZE) multicast_replication;
	MulticastReplication(NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE) multicast_replication;
#ifdef DTEL_ENABLE
	EgressDtel() dtel;
	DtelConfig(INSTANCE_DEPLOYMENT_PARAMS) dtel_config;
#endif
	EgressCpuRewrite(PORT_TABLE_SIZE) cpu_rewrite;
	Npb_Egr_Top(INSTANCE_DEPLOYMENT_PARAMS) npb_egr_top;

	// -------------------------------------------------------------------------

	apply {

//		eg_intr_md_for_dprsr.drop_ctl = 0;
#ifdef INT_V2
		eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp;
#else
		eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
#endif
#ifdef PA_NO_INIT
		eg_intr_md_for_dprsr.mirror_type = SWITCH_MIRROR_TYPE_INVALID;// for barefoot reset bug
#endif

		egress_set_lookup.apply(hdr.outer, hdr.inner, eg_md, eg_intr_md);  // set lookup structure fields that parser couldn't

		egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

#ifndef EGR_STUBBED_OUT
		if(EGRESS_ENABLE == true) {
			if(eg_md.flags.bypass_egress == false) {
				multicast_replication.apply (
					hdr.transport,
					eg_intr_md.egress_rid,
					eg_intr_md.egress_port,
					eg_md
				);

#ifdef BRIDGING_ENABLE
				if((eg_md.flags.transport_valid == false) && (eg_md.nsh_md.l2_fwd_en == true)) {
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
//				npb_egr_sf_proxy_hdr_strip.apply(hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
//				npb_egr_sf_proxy_hdr_edit.apply (hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

				// ---- outer nexthop (tunnel) code: operates on 'transport' ----
//				vlan_decap.apply(hdr.transport, eg_md);
				tunnel_encap.apply(hdr.transport, hdr.outer, hdr.inner, hdr.inner_inner, eg_md, eg_intr_md, eg_md.tunnel_0, eg_md.tunnel_1, eg_md.tunnel_2);
				tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
				vlan_xlate.apply(hdr.transport, eg_md);
/*
				// fix ip total length field if packet is being truncated (todo: adjust by 16w20 in case of vlan tag present)
				if(hdr.transport.ipv4.total_len > (bit<16>)eg_md.nsh_md.truncate_len - 16w14) {
					hdr.transport.ipv4.total_len = (bit<16>)eg_md.nsh_md.truncate_len - 16w14;
				}
*/

#ifdef DTEL_ENABLE
				dtel.apply(hdr.transport, eg_md, eg_intr_md, eg_md.dtel.hash);
				dtel_config.apply(hdr.transport, eg_md, eg_intr_md_for_dprsr);
#endif
			}
		} // EGRESS ENABLE
		cpu_rewrite.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
		set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

#endif  /* EGR_STUBBED_OUT */
	}
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// MOVED TO P4-PROGRAMS
// 
// Pipeline(
//         NpbIngressParser(),
//         SwitchIngress(INSTANCE_DEPLOYMENT_PARAMS_VCPFW),
//         SwitchIngressDeparser(),
//         NpbEgressParser(),
//         SwitchEgress(INSTANCE_DEPLOYMENT_PARAMS_VCPFW),
//         SwitchEgressDeparser()) pipe;
// 
// Switch(pipe) main;

#endif // _NPB_CORE_
