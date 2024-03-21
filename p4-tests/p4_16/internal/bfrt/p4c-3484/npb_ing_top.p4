#include "npb_ing_sfc_top.p4"
#include "npb_ing_sf_npb_basic_adv_top.p4"
//#include "npb_ing_sf_npb_basic_adv_sfp_sel.p4"
#include "npb_ing_sf_multicast_top.p4"
#include "npb_ing_sff_top.p4"

#include "scoper.p4"

control npb_ing_top (
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
) {

#ifdef UDF_ENABLE
//  Scoper_l7() scoper_l7;
#endif

#ifndef SFF_SCHD_SIMPLE
	npb_ing_sf_npb_basic_adv_sfp_hash() npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1;
  #ifdef SF_0_ALLOW_SCOPE_CHANGES
//	npb_ing_sf_npb_basic_adv_sfp_hash() npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2;
  #endif
#endif

	TunnelDecapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_decap_transport_ingress;
	TunnelDecapOuter(switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
	TunnelDecapInner(switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

//	TunnelEncapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_encap_transport_ingress;

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// Derek: Don't know what we want to do with this signal for the 
		// npb path.  For now, just setting it to 0 here (it's set in port.p4,
		// but probably not using the fields we want to be used for the npb)
		
		ig_intr_md_for_tm.level2_exclusion_id = 0;

		// -----------------------------------------------------------------
		// Set Initial Scope
		// -----------------------------------------------------------------

		if(hdr_0.nsh_type1.scope == 0) {
#ifdef INGRESS_PARSER_POPULATES_LKP_1
			// do nothing
#else
			ScoperOuter.apply(
				hdr_1,
				tunnel_1,
//				ig_md.drop_reason_1,

				ig_md.lkp_1
			);
#endif
		} else {
#ifdef INGRESS_PARSER_POPULATES_LKP_2
			Scoper.apply(
				ig_md.lkp_2,
//				ig_md.drop_reason_2,

				ig_md.lkp_1
			);
#else
			ScoperInner.apply(
				hdr_2,
				tunnel_2,
//				ig_md.drop_reason_2,

				ig_md.lkp_1
			);
#endif
		}

		// -----------------------------------------------------------------
		// Set Initial Scope (L7)
		// -----------------------------------------------------------------

#ifdef VALIDATION_ENABLE
		// check for parser errors
		ParserValidation.apply(hdr_udf, ig_md, ig_intr_md_from_prsr, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif /* VALIDATION_ENABLE */

		// -----------------------------------------------------------------

		// populate udf in lkp struct for the following cases:
		//   scope==inner
		//   scope==outer and no inner stack present
		// todo: do we need to qualify this w/ hdr_udf.isValid()? (the thinking is it will just work w/o doing so)

#ifdef UDF_ENABLE
//      if(hdr_0.nsh_type1.scope==1 || (hdr_0.nsh_type1.scope==0 && !hdr_2.ethernet.isValid())) {
//              scoper_l7.apply(hdr_udf, ig_md.lkp);
//      }
#endif  /* UDF_ENABLE */

		// -------------------------------------
		// SFC
		// -------------------------------------

		npb_ing_sfc_top.apply (
			hdr_0,
			tunnel_0,
			hdr_1,
			tunnel_1,
			hdr_2,
			tunnel_2,
			hdr_udf,

			ig_md,
			ig_intr_md,
			ig_intr_md_from_prsr,
			ig_intr_md_for_dprsr,
			ig_intr_md_for_tm
		);

		// -------------------------------------
		// Pre-Generate Flow Schd Hashes
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

		// -------------------------------------

#ifdef SF_0_DEDUP_ENABLE
/*
                npb_ing_sf_npb_basic_adv_dedup_hash.apply (
                    ig_md.lkp_1,         // for hash
                    (bit<VPN_ID_WIDTH>)hdr_0.nsh_type1.vpn, // for hash
					ig_md.nsh_md.hash_2
                );
*/
#endif

		// -------------------------------------
/*
  #ifdef SF_0_ALLOW_SCOPE_CHANGES

    #ifdef INGRESS_PARSER_POPULATES_LKP_2
    #else
		ScoperInner.apply(
			hdr_2,
			tunnel_2,
//			ig_md.drop_reason_2,

			ig_md.lkp_2
		);
    #endif

		npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.apply(
			hdr_0,
			ig_md,
			ig_intr_md,
			ig_intr_md_from_prsr,
			ig_intr_md_for_dprsr,
			ig_intr_md_for_tm,

			ig_md.lkp_2.mac_type,
			ig_md.lkp_2.ip_proto,
			ig_md.lkp_2.l4_src_port,
			ig_md.lkp_2.l4_dst_port,
			ig_md.nsh_md.hash_2
		);
  #endif // SF_0_ALLOW_SCOPE_CHANGES
*/
#endif // SFF_SCHD_SIMPLE

		// -------------------------------------
		// SF #0 - Policy
		// -------------------------------------

		if (!INGRESS_BYPASS(SF_ACL)) {
			npb_ing_sf_npb_basic_adv_top.apply (
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
		// SFF Reframing
		// -------------------------------------

		// Decaps ------------------------------

		tunnel_decap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

#ifdef INGRESS_TERMINATE_OUTER_ENABLE
  #ifdef INGRESS_TERMINATE_INNER_ENABLE
		tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
		tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		TunnelDecapFixEthertype.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
		TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0);
  #else
		tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
//		tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		TunnelDecapFixEthertype.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
		TunnelDecapScopeDecrement.apply(tunnel_1.terminate, false,              hdr_0);
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
	}
}
