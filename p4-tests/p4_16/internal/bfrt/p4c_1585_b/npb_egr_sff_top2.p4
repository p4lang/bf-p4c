#include "npb_egr_sf_proxy_top2.p4"

control npb_egr_sff_top2 (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// -----------------------------------------------------------------------------
		// Do some work
		// -----------------------------------------------------------------------------

		if(eg_md.nsh_extr.valid == 1) {

			// -------------------------------------
			// SF(s)
			// -------------------------------------

			if(eg_md.nsh_extr.extr_srvc_func_bitmask_local[2:2] == 1) {

				// -------------------------------------
				// SF #0
				// -------------------------------------

				npb_egr_sf_proxy_top2.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

				// DON"T NEED TO DO THIS.  THE PROXY DELETES THE NSH HEADER SO THERES NO POINT IN CHECKING.
				// check sp index
//				if(eg_md.nsh_extr_underlay.si == 0) {
//					eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//				}

			}

		}

	}

}
