#ifndef _NPB_EGR_SF_PROXY_TRUNCATE_
#define _NPB_EGR_SF_PROXY_TRUNCATE_

control npb_egr_sf_proxy_truncate (
	inout switch_header_transport_t                   hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// -----------------------------------------------------------------
	// Table
	// -----------------------------------------------------------------

	// -----------------------------------------------------------------
	// Apply
	// -----------------------------------------------------------------

	apply {
	   if(eg_md.nsh_md.truncate_enable) {
#if __TARGET_TOFINO__ == 2
        eg_intr_md_for_dprsr.mtu_trunc_len = eg_md.nsh_md.truncate_len;
#endif
        }

	}

}

#endif
