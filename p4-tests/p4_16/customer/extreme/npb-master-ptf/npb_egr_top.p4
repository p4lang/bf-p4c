#ifdef VALIDATION_ENABLE
  #include "validation.p4"
#endif /* VALIDATION_ENABLE */

#include "npb_egr_sff_top.p4"
#include "npb_ing_sf_multicast_top.p4"
#include "npb_egr_sf_proxy_top.p4"
#include "npb_ing_sf_npb_basic_adv_dedup.p4"

#include "scoper.p4"

control npb_egr_top (
	inout switch_header_transport_t                   hdr_0,
	inout switch_tunnel_metadata_t                    tunnel_0,
	inout switch_header_outer_t                       hdr_1,
	inout switch_tunnel_metadata_reduced_t            tunnel_1,
	inout switch_header_inner_t                       hdr_2,
	inout switch_tunnel_metadata_reduced_t            tunnel_2,
	inout switch_header_inner_inner_t                 hdr_3,

	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
#ifdef VALIDATION_ENABLE
	OuterPktValidation() pkt_validation_outer;
	InnerPktValidation() pkt_validation_inner;
#endif /* VALIDATION_ENABLE */

	TunnelDecapOuter(switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
	TunnelDecapInner(switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// -------------------------------------
		// Ingress Dedup (continued from ingress side)
		// -------------------------------------

#ifdef SF_0_DEDUP_ENABLE
/*
        npb_ing_sf_npb_basic_adv_dedup_hash.apply (
            eg_md.lkp_1,         // for hash
            (bit<VPN_ID_WIDTH>)eg_md.nsh_md.vpn, // for hash
            eg_md.nsh_md.hash_2
        );

		npb_ing_sf_npb_basic_adv_dedup.apply (
			eg_md.nsh_md.dedup_en,
			eg_md.lkp_1,         // for hash
			(bit<VPN_ID_WIDTH>)eg_md.nsh_md.vpn, // for hash
			eg_md.nsh_md.hash_2,
//			eg_md.ingress_port,  // for dedup
			eg_md.nsh_md.sap, // for dedup
			eg_intr_md_for_dprsr.drop_ctl
		);
*/

		npb_egr_sf_proxy_dedup.apply (
			eg_md.nsh_md.dedup_en,
			eg_md.lkp_1,         // for hash
			(bit<VPN_ID_WIDTH>)eg_md.nsh_md.vpn, // for hash
//			eg_md.ingress_port,  // for dedup
			eg_md.nsh_md.sap, // for dedup
			eg_intr_md_for_dprsr.drop_ctl
		);
#endif

		// -------------------------------------
		// Set Initial Scope
		// -------------------------------------

		if(eg_md.nsh_md.scope == 1) {
#ifdef EGRESS_PARSER_POPULATES_LKP_WITH_OUTER
			// do nothing
#else
			ScoperOuter.apply(
				hdr_1,
				tunnel_1,

				eg_md.lkp_1
			);
#endif
		} else {
#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED
			// do nothing
#else
			ScoperInner.apply(
				hdr_2,
				tunnel_2,

				eg_md.lkp_1
			);
#endif
		}

		// -------------------------------------
		// SF #1 - Multicast
		// -------------------------------------

		npb_egr_sf_multicast_top_part2.apply (
			hdr_0,
			eg_intr_md.egress_rid,
			eg_intr_md.egress_port,
			eg_md
		);

		// -------------------------------------
		// SF #2 - Policy
		// -------------------------------------

		if (!EGRESS_BYPASS(SF_ACL)) {
			npb_egr_sf_proxy_top.apply (
				eg_md.lkp_1,
				hdr_0,
				hdr_1,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

		// -------------------------------------
		// SFF - Pkt Decap(s)
		// -------------------------------------

		// Decaps ------------------------------

		tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
		tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		eg_md.nsh_md.scope = eg_md.nsh_md.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
		TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0, eg_md.nsh_md.scope);

		// -------------------------------------
		// SFF - Hdr Decap / Encap
		// -------------------------------------

		if (!EGRESS_BYPASS(SFF)) {
			npb_egr_sff_top.apply (
				hdr_0,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

	}
}
