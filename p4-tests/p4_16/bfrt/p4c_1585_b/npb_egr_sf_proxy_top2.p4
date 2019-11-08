#include "npb_ing_sf_npb_basic_adv_dedup.p4"

control npb_egr_sf_proxy_top2 (

	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	apply {

		// ----------------------------------
		// Action Lookup
		// ----------------------------------

		// ----------------------------------
		// Actions(s)
		// ----------------------------------

        if(eg_md.action_bitmask[3:3] == 1) {
#ifdef SF_METER_ENABLE
            npb_egr_sf_proxy_meter.apply (
                hdr,
                eg_md,
                eg_intr_md,
                eg_intr_md_from_prsr,
                eg_intr_md_for_dprsr,
                eg_intr_md_for_oport
            );
#endif
		}
		if(eg_md.action_bitmask[4:4] == 1) {
#ifdef SF_DEDUP_ENABLE
			npb_ing_sf_npb_basic_adv_dedup.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
#endif
		}

	}

}
