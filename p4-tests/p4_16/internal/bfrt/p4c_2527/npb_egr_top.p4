#ifdef VALIDATION_ENABLE
  #include "validation.p4"
#endif /* VALIDATION_ENABLE */

#include "npb_egr_sff_top.p4"
#include "npb_egr_sf_multicast_top.p4"
#include "npb_egr_sf_proxy_top.p4"

#include "scoper.p4"

control npb_egr_top (
    inout switch_header_transport_t                   hdr_0,
    inout switch_header_outer_t                       hdr_1,
    inout switch_header_inner_t                       hdr_2,
    inout switch_tunnel_metadata_t                    tunnel_1,
    inout switch_tunnel_metadata_t                    tunnel_2,
    inout switch_egress_metadata_t                    eg_md,

    in    egress_intrinsic_metadata_t                 eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
//	ScoperOuterEgress() scoper0;
	ScoperInnerEgress() scoper1;

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
        // SFF Part 1 --> *** before reframing ***
        // -------------------------------------

        npb_egr_sff_top_part1.apply (
            hdr_0,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        // -------------------------------------
        // Scoper
        // -------------------------------------

		if(hdr_0.nsh_type1.scope == 0) {
/*
			scoper0.apply(
				hdr_1.ethernet,
				hdr_1.e_tag,
				hdr_1.vn_tag,
				hdr_1.vlan_tag[0],
				hdr_1.vlan_tag[1],
				hdr_1.ipv4,
#ifdef IPV6_ENABLE
				hdr_1.ipv6,
#endif // IPV6_ENABLE
				hdr_1.tcp,
				hdr_1.udp,
				hdr_1.sctp,
				tunnel_1.type,
				tunnel_1.id,
				eg_md.drop_reason_1,

				eg_md.lkp
			);
*/
#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE;
			eg_md.lkp_tunnel_inner_type = eg_md.tunnel_2.type;
#endif
		} else {
			scoper1.apply(
				hdr_2.ethernet,
				hdr_2.vlan_tag[0],
				hdr_2.ipv4,
#ifdef IPV6_ENABLE
				hdr_2.ipv6,
#endif  /* IPV6_ENABLE */
				hdr_2.tcp,
				hdr_2.udp,
				hdr_2.sctp,
				tunnel_2.type,
				tunnel_2.id,
				eg_md.drop_reason_2,

				eg_md.lkp
			);

#ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
			eg_md.lkp_tunnel_outer_type = eg_md.tunnel_1.type;
			eg_md.lkp_tunnel_inner_type = SWITCH_TUNNEL_TYPE_NONE;
#endif
		}

        // -------------------------------------
        // SF(s): Part 1 --> *** before reframing ***
        // -------------------------------------

        npb_egr_sf_multicast_top_part2.apply (
			hdr_0,
			eg_intr_md.egress_rid,
			eg_intr_md.egress_port,
			eg_md
        );

        // -------------------------------------

        npb_egr_sf_proxy_top.apply (
            hdr_0,
            hdr_1,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        // -------------------------------------
		// Reframing
        // -------------------------------------

        tunnel_decap_outer.apply(hdr_0, hdr_1, eg_md, tunnel_1);
        tunnel_decap_inner.apply(hdr_0, hdr_2, eg_md, tunnel_2);
		TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0);

        // -------------------------------------
        // SF(s): Part 2 --> *** after reframing ***
        // -------------------------------------
/*
        npb_egr_sf_proxy_top_part2.apply (
            hdr_0,
            hdr_1,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
*/
        // -------------------------------------
        // SFF: Part 2 --> *** after reframing ***
        // -------------------------------------

        npb_egr_sff_top_part2.apply (
            hdr_0,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

	}
}
