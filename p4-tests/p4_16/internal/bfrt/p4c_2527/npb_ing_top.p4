#include "npb_ing_sfc_top.p4"
#include "npb_ing_sf_npb_basic_adv_top.p4"
#include "npb_egr_sf_multicast_top.p4"
#include "npb_ing_sff_top.p4"

control npb_ing_top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_header_outer_t                     hdr_1,
	inout switch_header_inner_t                     hdr_2,
	inout udf_h                                     hdr_l7_udf,
	inout switch_tunnel_metadata_t                  tunnel_0,
	inout switch_tunnel_metadata_t                  tunnel_1,
	inout switch_tunnel_metadata_t                  tunnel_2,

	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

                // -------------------------------------
                // SFC
                // -------------------------------------

                npb_ing_sfc_top.apply (
                    hdr_0,
                    hdr_1,
                    hdr_2,
                    hdr_l7_udf,
                    ig_md,
                    ig_intr_md,
                    ig_intr_md_from_prsr,
                    ig_intr_md_for_dprsr,
                    ig_intr_md_for_tm,

                    tunnel_0,
                    tunnel_1,
                    tunnel_2
                );

                // -------------------------------------
                // SF(s)
                // -------------------------------------

                npb_ing_sf_npb_basic_adv_top.apply (
                    hdr_0,
                    hdr_2,
                    ig_md,
                    ig_intr_md,
                    ig_intr_md_from_prsr,
                    ig_intr_md_for_dprsr,
                    ig_intr_md_for_tm
                );

                // -------------------------------------

                npb_ing_sf_multicast_top_part1.apply (
                    hdr_0,
                    ig_md,
                    ig_intr_md,
                    ig_intr_md_from_prsr,
                    ig_intr_md_for_dprsr,
                    ig_intr_md_for_tm
                );

                // -------------------------------------
                // Perform hash for SFF
                // -------------------------------------

                // extreme: this mirrors the hash the switch.p4 does

                // note: TODO - modify these hash functions to include flowclass and vpn (although I
                // question if this is really necessary, since these values are derived from the packet anyway(?) --
                // if not, then we could simply move switch.p4's hash up above from its current location down
                // below and use it's results instead of having to use our own separate hash function).

                if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE)
                    compute_non_ip_hash(ig_md.lkp, ig_md.hash_nsh);
                else
                    compute_ip_hash(ig_md.lkp, ig_md.hash_nsh);

                // -------------------------------------
                // SFF
                // -------------------------------------

                npb_ing_sff_top.apply (
                    hdr_0,
                    ig_md,
                    ig_intr_md,
                    ig_intr_md_from_prsr,
                    ig_intr_md_for_dprsr,
                    ig_intr_md_for_tm,

                    ig_md.hash_nsh[15:0]
                );

	}
}
