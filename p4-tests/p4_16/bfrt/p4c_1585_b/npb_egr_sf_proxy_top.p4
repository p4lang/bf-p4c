#include "npb_egr_sf_proxy_act_sel.p4"
//#include "npb_egr_sf_proxy_hdr_strip.p4"
//#include "npb_egr_sf_proxy_hdr_edit.p4"
//#include "npb_egr_sf_proxy_truncate.p4"
#include "npb_egr_sf_proxy_meter.p4"

control npb_egr_sf_proxy_top (

	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	apply {

		hdr.nsh_extr_underlay.setInvalid(); // proxy removes the nsh

		// ----------------------------------
		// Action Lookup
		// ----------------------------------

		npb_egr_sf_proxy_act_sel.apply (
			hdr,
			eg_md,
			eg_intr_md,
			eg_intr_md_from_prsr,
			eg_intr_md_for_dprsr,
			eg_intr_md_for_oport
		);

		// ----------------------------------
		// Actions(s)
		// ----------------------------------

/*
		if(action_bitmask[0:0] == 1) {
			npb_egr_sf_proxy_hdr_strip.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

		if(action_bitmask[1:1] == 1) {
			npb_egr_sf_proxy_hdr_edit.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

		if(action_bitmask[2:2] == 1) {
			npb_egr_sf_proxy_truncate.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}
		if(action_bitmask[3:3] == 1) {
#ifdef SF_METER_ENABLE
			npb_egr_sf_proxy_meter.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport,

				meter_id,
				meter_overhead
			);
#endif
		}
*/
    }

}
