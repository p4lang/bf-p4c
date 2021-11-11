
#ifndef _NPB_ING_TOP_
#define _NPB_ING_TOP_

#include "npb_ing_sfc_top.p4"
#include "npb_ing_sf_npb_basic_adv_top.p4"
//#include "npb_ing_sf_npb_basic_adv_sfp_sel.p4"
#include "npb_ing_sf_multicast_top.p4"
#include "npb_ing_sff_top.p4"

#include "scoper.p4"

control Npb_Ing_Top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_tunnel_metadata_t                  tunnel_0,
	inout switch_header_outer_t                     hdr_1,
	inout switch_tunnel_metadata_reduced_t          tunnel_1,
	inout switch_header_inner_t                     hdr_2,
	inout switch_tunnel_metadata_reduced_t          tunnel_2,
	inout switch_header_inner_inner_t               hdr_3,
	inout udf_h                                     hdr_udf,

	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) (
	MODULE_DEPLOYMENT_PARAMS
) {

	Scoper_Hdr0_To_Lkp(INSTANCE_DEPLOYMENT_PARAMS) scoper_hdr0_to_lkp;
	Scoper_Hdr1_To_Lkp(INSTANCE_DEPLOYMENT_PARAMS) scoper_hdr1_to_lkp;
	Scoper_Hdr2_To_Lkp(INSTANCE_DEPLOYMENT_PARAMS) scoper_hdr2_to_lkp;

	Npb_Ing_Sfc_Top(INSTANCE_DEPLOYMENT_PARAMS) npb_ing_sfc_top;

	Npb_Ing_Sf_Npb_Basic_Adv_Top(INSTANCE_DEPLOYMENT_PARAMS) npb_ing_sf_npb_basic_adv_top;

#ifndef SFF_SCHD_SIMPLE
	Npb_Ing_Sf_Npb_Basic_Adv_Sfp_Hash() npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1;
#endif
	Npb_Ing_Sf_Npb_Basic_Adv_Sfp_Sel(INSTANCE_DEPLOYMENT_PARAMS) npb_ing_sf_npb_basic_adv_sfp_sel;

	TunnelDecapTransportIngress(INSTANCE_DEPLOYMENT_PARAMS, switch_tunnel_mode_t.PIPE) tunnel_decap_transport_ingress;
	TunnelDecapOuter(INSTANCE_DEPLOYMENT_PARAMS, switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
	TunnelDecapInner(INSTANCE_DEPLOYMENT_PARAMS, switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// Derek: Don't know what we want to do with this signal for the 
		// npb path.  For now, just setting it to 0 here (it's set in port.p4,
		// but probably not using the fields we want to be used for the npb)
		
//		ig_intr_md_for_tm.level2_exclusion_id = 0;

		// -----------------------------------------------------------------
		// Set Initial Lkp Structures
		// -----------------------------------------------------------------

#ifndef INGRESS_PARSER_POPULATES_LKP_0
		scoper_hdr0_to_lkp.apply(
			hdr_0,
			hdr_1,
			ig_md.lkp_0,
			ig_md.tunnel_0.unsupported_tunnel,

			ig_md.lkp_0
		);
#endif

#ifndef INGRESS_PARSER_POPULATES_LKP_1
  #ifndef INGRESS_MAU_NO_LKP_1
		scoper_hdr1_to_lkp.apply(
			hdr_1,
			hdr_2,
			ig_md.lkp_1,
			ig_md.tunnel_1.unsupported_tunnel,

			ig_md.lkp_1
		);
  #endif
#endif

#ifndef INGRESS_PARSER_POPULATES_LKP_2
  #ifndef INGRESS_MAU_NO_LKP_2
		scoper_hdr2_to_lkp.apply(
			hdr_2,
			hdr_3,
			ig_md.lkp_2,
			ig_md.tunnel_2.unsupported_tunnel,

			ig_md.lkp_2
		);
  #endif
#endif

		// -----------------------------------------------------------------
		// Set Initial Scope (L7)
		// -----------------------------------------------------------------

#ifdef VALIDATION_ENABLE
		// check for parser errors
		ParserValidation.apply(hdr_udf, ig_md, ig_intr_md_from_prsr, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif /* VALIDATION_ENABLE */

		// -------------------------------------
		// SFC
		// -------------------------------------

//		if (!INGRESS_BYPASS(SFC)) {
			npb_ing_sfc_top.apply (
				hdr_0,
				tunnel_0,
				hdr_1,
				tunnel_1,
				hdr_2,
				tunnel_2,
				hdr_3,
				hdr_udf,

				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
//		}

		// -------------------------------------
		// SF #0 - SFP Hashes
		// -------------------------------------

#ifndef SFF_SCHD_SIMPLE
		npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.apply(
			hdr_0,
			ig_md,
			ig_intr_md,
			ig_intr_md_from_prsr,
			ig_intr_md_for_dprsr,
			ig_intr_md_for_tm,

			ig_md.lkp_1.mac_type,
			ig_md.lkp_1.ip_proto,
			ig_md.lkp_1.l4_src_port,
			ig_md.lkp_1.l4_dst_port,
			ig_md.nsh_md.hash_1
		);
#endif // SFF_SCHD_SIMPLE

		// -------------------------------------
		//
		// -------------------------------------

#ifdef SF_0_DEDUP_ENABLE
/*
		npb_ing_sf_npb_basic_adv_dedup_hash.apply (
			ig_md.lkp_1,         // for hash
			(bit<VPN_ID_WIDTH>)ig_md.nsh_md.vpn, // for hash
			ig_md.nsh_md.hash_2
		);
*/
#endif

		// -------------------------------------
		// SF #0 - Policy
		// -------------------------------------

		if (!INGRESS_BYPASS(SF_ACL)) {
			npb_ing_sf_npb_basic_adv_top.apply (
				ig_md.lkp_1,
				hdr_0,
				hdr_1,
				hdr_2,
				hdr_udf,

				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);

			// -------------------------------------
			// SF #0 - SFP Select
			// -------------------------------------

			npb_ing_sf_npb_basic_adv_sfp_sel.apply(
				hdr_0,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
		}

		// -------------------------------------
		// SFF - Reframing
		// -------------------------------------

		// Decaps ------------------------------

		tunnel_decap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

#ifdef INGRESS_TERMINATE_OUTER_ENABLE
  #ifdef INGRESS_TERMINATE_INNER_ENABLE
		tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
		tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		ig_md.nsh_md.scope = ig_md.nsh_md.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
		TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0, ig_md.nsh_md.scope);
  #else
		tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
//		tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		ig_md.nsh_md.scope = ig_md.nsh_md.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
		TunnelDecapScopeDecrement.apply(tunnel_1.terminate, false,              hdr_0, ig_md.nsh_md.scope);
  #endif
#endif

		// Encaps ------------------------------

//		tunnel_0.encap = true;
//		tunnel_encap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1);

		// -------------------------------------
		// SFF
		// -------------------------------------

		if (!INGRESS_BYPASS(SFF)) {
			npb_ing_sff_top.apply (
				hdr_0,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
		}

		// -------------------------------------
		// SF #1 - Multicast
		// -------------------------------------

		if (!INGRESS_BYPASS(SF_MCAST)) {
			npb_ing_sf_multicast_top_part1.apply (
				hdr_0,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
		}

		// -------------------------------------
		// Add NSH header
		// -------------------------------------

		// Only add bridged metadata if we are NOT bypassing egress pipeline.
		if (ig_intr_md_for_tm.bypass_egress == 1w0) {
			hdr_0.nsh_type1_internal = {
				version  = 0,
				o        = 0,
				reserved = 0,
				ttl      = ig_md.nsh_md.ttl,
				len      = 0,
				spi      = ig_md.nsh_md.spi,
				si       = ig_md.nsh_md.si,
				vpn      = (bit<SSAP_ID_WIDTH>)ig_md.nsh_md.vpn,
				scope    = ig_md.nsh_md.scope,
				sap      = (bit<VPN_ID_WIDTH>)ig_md.nsh_md.sap
			};
		}
	}
}

#endif /* _NPB_ING_TOP_ */
