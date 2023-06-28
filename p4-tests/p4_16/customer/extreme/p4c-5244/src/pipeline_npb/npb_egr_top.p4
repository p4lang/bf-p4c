
#ifndef _NPB_EGR_TOP_
#define _NPB_EGR_TOP_

control Npb_Egr_Top (
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
) (
	MODULE_DEPLOYMENT_PARAMS
) {
	Npb_Egr_Sf_Proxy_Top(INSTANCE_DEPLOYMENT_PARAMS) npb_egr_sf_proxy_top;

	TunnelDecapOuter(INSTANCE_DEPLOYMENT_PARAMS, switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
	TunnelDecapInner(INSTANCE_DEPLOYMENT_PARAMS, switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

	Npb_Egr_Sff_Top(INSTANCE_DEPLOYMENT_PARAMS) npb_egr_sff_top;
#ifdef SF_0_DEDUP_ENABLE
	npb_dedup_(INSTANCE_DEPLOYMENT_PARAMS) npb_dedup;
#endif

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

		npb_dedup.apply (
			eg_md.nsh_md.dedup_en,
			eg_md.lkp_1,         // for hash
			(bit<VPN_ID_WIDTH>)eg_md.nsh_md.vpn, // for hash
			eg_md.hash,
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
/*
		npb_egr_sf_multicast_top_part2.apply (
			hdr_0,
			eg_intr_md.egress_rid,
			eg_intr_md.egress_port,
			eg_md
		);
*/
		// -------------------------------------
		// SF #2 - Policy
		// -------------------------------------

//		if (!eg_md.flags.bypass_egress) {
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
//		}

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

		if(FOLDED_ENABLE) {
//			hdr.transport.nsh_type1_internal = { 
			hdr_0.nsh_type1_internal = { 
				version  = 0,
				o        = 0,
				reserved = 0, 
				ttl      = eg_md.nsh_md.ttl,
				len      = 0,
				spi      = eg_md.nsh_md.spi,
				si       = eg_md.nsh_md.si,
				vpn      = (bit<SSAP_ID_WIDTH>)eg_md.nsh_md.vpn,
				scope    = eg_md.nsh_md.scope,
				sap      = (bit<VPN_ID_WIDTH>)eg_md.nsh_md.sap
			};
		} else {
//			if (!eg_md.flags.bypass_egress) {
				npb_egr_sff_top.apply (
					hdr_0,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
//			}
		}
	}
}

control Npb_Egr_Top_Folded (
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
) (
	MODULE_DEPLOYMENT_PARAMS
) {
	Npb_Egr_Sff_Top(INSTANCE_DEPLOYMENT_PARAMS) npb_egr_sff_top;

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// -------------------------------------
		// SFF - Hdr Decap / Encap
		// -------------------------------------

//		if (!eg_md.flags.bypass_egress) {
			npb_egr_sff_top.apply (
				hdr_0,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
//		}
	}
}

#endif /* _NPB_EGR_TOP_ */
