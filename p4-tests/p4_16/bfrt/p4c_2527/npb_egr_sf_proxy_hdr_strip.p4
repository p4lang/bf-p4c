
control npb_egr_sf_proxy_hdr_strip (
	inout switch_header_transport_t                   hdr_0,
	inout switch_header_outer_t                       hdr_1,
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
	    if(eg_md.nsh_type1.strip_e_tag) {
	        hdr_1.e_tag.setInvalid();
	    }

	    if(eg_md.nsh_type1.strip_vn_tag) {
	        hdr_1.vn_tag.setInvalid();
	    }
    
	    if(eg_md.nsh_type1.strip_vlan_tag) {
	        hdr_1.vlan_tag[0].setInvalid();
	        hdr_1.vlan_tag[1].setInvalid();
	    }

	}

}
