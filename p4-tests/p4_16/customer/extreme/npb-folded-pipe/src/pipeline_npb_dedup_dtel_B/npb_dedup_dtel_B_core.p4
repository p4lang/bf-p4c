#ifndef _NPB_DEDUP_DTEL_B_CORE_
#define _NPB_DEDUP_DTEL_B_CORE_

#include <core.p4>
#if __TARGET_TOFINO__ == 2
  #include <t2na.p4>
#else
  #include <tna.p4>
#endif

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control IngressControl_B(
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
	Ipv4Hash() ipv4_hash;
	Ipv6Hash() ipv6_hash;
	NonIpHash() non_ip_hash;
//	IngressIpAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
//	IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
	AddBridgedMd(INSTANCE_DEPLOYMENT_PARAMS) add_bridged_md;
#ifdef DTEL_ENABLE
//	IngressDtel(DTEL_SELECTOR_TABLE_SIZE, DTEL_MAX_MEMBERS_PER_GROUP, DTEL_GROUP_TABLE_SIZE) dtel;
#endif
	Scoper_Hdr2_To_Lkp(INSTANCE_DEPLOYMENT_PARAMS) scoper_hdr2_to_lkp;
	npb_dedup_(INSTANCE_DEPLOYMENT_PARAMS) npb_dedup;

	// ---------------------------------------------------------------------

	apply {

#ifndef ING_STUBBED_OUT
		// -----------------------------------------------------

		ingress_set_lookup.apply(hdr, ig_md);  // set lookup structure fields that parser couldn't

		ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

		// -----------------------------------------------------

		// extract brided metadata here (for stuff we can't do in the parser)

		// set egress port
		ig_intr_md_for_tm.ucast_egress_port = ig_md.ingress_port; // by default, set ingress port equal to egress port -- for testing
		ig_md.ingress_port                  = hdr.bridged_md_folded.base.ingress_port; // set ingress port to original ingress port

		ig_md.qos.qid              = hdr.bridged_md_folded.base.qid; // can't be done in parser, for some reason
//		ig_md.qos.qid = 0x8;
		ig_md.nsh_md.dedup_en      = hdr.bridged_md_folded.base.nsh_md_dedup_en; // can't be done in parser, for some reason

		// -----------------------------------------------------

		// add internal nsh header

//		hdr.transport.nsh_type1_internal.setValid(); // by default, egress parser expects this header -- for testing
//		hdr.transport.nsh_type1_internal.scope = 1; // by default, egress parser expects this header -- for testing
/*
		// Only add bridged metadata if we are NOT bypassing egress pipeline.
		if (ig_intr_md_for_tm.bypass_egress == 1w0) {
			hdr.transport.nsh_type1_internal = {
				version  = 0,
				o        = 0,
				reserved = 0,
				ttl      = ig_md.nsh_md.ttl,
				len      = 0,
				spi      = ig_md.nsh_md.spi,
				si       = ig_md.nsh_md.si,
				vpn      = ig_md.nsh_md.vpn,
				scope    = ig_md.nsh_md.scope,
				sap      = ig_md.nsh_md.sap
			};
		}
*/
		// -----------------------------------------------------

		// set initial scope

#ifndef INGRESS_PARSER_POPULATES_LKP_0
		scoper_hdr0_to_lkp_inst.apply(
			hdr.transport,
			hdr.outer,
			ig_md.lkp_0,
			ig_md.tunnel_0.unsupported_tunnel,

			ig_md.lkp_0
		);
#endif

#ifndef INGRESS_PARSER_POPULATES_LKP_1
  #ifndef INGRESS_MAU_NO_LKP_1
		scoper_hdr1_to_lkp_inst.apply(
			hdr.outer,
			hdr.inner,
			ig_md.lkp_1,
			ig_md.tunnel_1.unsupported_tunnel,

			ig_md.lkp_1
		);
  #endif
#endif

#ifndef INGRESS_PARSER_POPULATES_LKP_2
  #ifndef INGRESS_MAU_NO_LKP_2
		scoper_hdr2_to_lkp_inst.apply(
			hdr.inner,
			hdr.inner_inner,
			ig_md.lkp_2,
			ig_md.tunnel_2.unsupported_tunnel,

			ig_md.lkp_2
		);
  #endif
#endif

		// -----------------------------------------------------

		// set inital scope

		if((ig_md.nsh_md.scope == 2) && ig_md.lkp_1.next_lyr_valid) {
			scoper_hdr2_to_lkp.apply(hdr.inner, hdr.inner_inner, ig_md.lkp_2, ig_md.tunnel_2.unsupported_tunnel, ig_md.lkp_1);
		}

		// -----------------------------------------------------

		// hash

		bit<32> hash_l2;

		if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
			non_ip_hash.apply(ig_md.lkp_1, hash_l2[31:0]);
		} else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
			non_ip_hash.apply(ig_md.lkp_1, hash_l2[31:0]);
		} else {
			non_ip_hash.apply(ig_md.lkp_1, hash_l2[31:0]);
		}

		if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
			non_ip_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
		} else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
			ipv4_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
		} else {
			ipv6_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
		}

		// -----------------------------------------------------

#ifdef BRIDGING_ENABLE
		if((ig_md.flags.transport_valid == false) && (ig_md.nsh_md.l2_fwd_en == true)) {
			// do nothing (bridging the packet)
		} else {
#endif // BRIDGING_ENABLE

			// dedup
			npb_dedup.apply(
//				true,
				ig_md.nsh_md.dedup_en,
				ig_md.lkp_1, // aka hash_l34
				hash_l2,
				ig_md.hash,
				ig_md.nsh_md.sap,
				ig_md.nsh_md.vpn,
				ig_md.ingress_port,
				ig_intr_md_for_dprsr.drop_ctl
			);
#ifdef BRIDGING_ENABLE
		}
#endif

		// -----------------------------------------------------

		// Only add bridged metadata if we are NOT bypassing egress pipeline.
		if (ig_intr_md_for_tm.bypass_egress == 1w0) {
			add_bridged_md.apply(hdr.bridged_md, ig_md);
		}
#ifdef DTEL_ENABLE
//		ingress_ip_dtel_acl.apply(ig_md, ig_md.unused_nexthop);
//		dtel.apply(hdr.transport, ig_md.lkp_1, ig_md, ig_md.hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif
		set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);

		ig_intr_md_for_tm.ucast_egress_port = ig_intr_md_for_tm.ucast_egress_port & 0x0ff; // for folded pipe (clr the high bit) - FOR FOLD IN PIPES 2 and 3
//		ig_intr_md_for_tm.ucast_egress_port = ig_intr_md_for_tm.ucast_egress_port | 0x100; // for folded pipe (set the high bit) - FOR FOLD IN PIPES 0 and 1

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

control EgressControl_B(
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
	AddBridgedMdFolded(INSTANCE_DEPLOYMENT_PARAMS) add_bridged_md_folded;
#ifdef DTEL_ENABLE
//	EgressDtel() dtel;
//	DtelConfig(INSTANCE_DEPLOYMENT_PARAMS) dtel_config;
#endif
	EgressCpuRewrite(PORT_TABLE_SIZE) cpu_rewrite;
	Npb_Egr_Top(INSTANCE_DEPLOYMENT_PARAMS) npb_egr_top;

	// -------------------------------------------------------------------------

	apply {

//		eg_intr_md_for_dprsr.drop_ctl = 0;
#ifdef INT_V2
		eg_md.egress_timestamp = eg_intr_md_from_prsr.global_tstamp;
#else
		eg_md.egress_timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
#endif
#ifdef PA_NO_INIT
		eg_intr_md_for_dprsr.mirror_type = SWITCH_MIRROR_TYPE_INVALID;// for barefoot reset bug
#endif

		egress_set_lookup.apply(hdr.outer, hdr.inner, eg_md, eg_intr_md);  // set lookup structure fields that parser couldn't

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
//			npb_egr_sf_proxy_hdr_strip.apply(hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
//			npb_egr_sf_proxy_hdr_edit.apply (hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

			// ---- outer nexthop (tunnel) code: operates on 'transport' ----
//			vlan_decap.apply(hdr.transport, eg_md);
/*
			tunnel_encap.apply(hdr.transport, hdr.outer, hdr.inner, hdr.inner_inner, eg_md, eg_intr_md, eg_md.tunnel_0, eg_md.tunnel_1, eg_md.tunnel_2);
			tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
			vlan_xlate.apply(hdr.transport, eg_md);
*/
/*
			// fix ip total length field if packet is being truncated (todo: adjust by 16w20 in case of vlan tag present)
			if(hdr.transport.ipv4.total_len > (bit<16>)eg_md.nsh_md.truncate_len - 16w14) {
				hdr.transport.ipv4.total_len = (bit<16>)eg_md.nsh_md.truncate_len - 16w14;
			}
*/

#ifdef DTEL_ENABLE
//			dtel.apply(hdr.transport, eg_md, eg_intr_md, eg_md.dtel.hash);
//			dtel_config.apply(hdr.transport, eg_md, eg_intr_md_for_dprsr);
#endif

			// ----------------------------------

			if(FOLDED_ENABLE) {
				add_bridged_md_folded.apply(hdr.bridged_md_folded, eg_md);
			}
		}

		// ----------------------------------

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

#endif // _NPB_DEDUP_DTEL_B_CORE_
