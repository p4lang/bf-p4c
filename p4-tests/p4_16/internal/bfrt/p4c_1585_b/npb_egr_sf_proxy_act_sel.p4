
control npb_egr_sf_proxy_act_sel (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Table
	//
	// Function: spi and si --> actions
	// =========================================================================

	// Note: action_bitmask defined as follows....
	//
	//   [0:0] unused (was header strip)
	//   [1:1] unused (was header edit)
	//   [2:2] unused (reserved for truncate)
	//   [3:3] meter
	//   [4:4] dedup

	action egr_sf_table_1_hit(
		bit<5>                                      action_bitmask,
		bit<NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH_POW2> meter_id,
		bit<8>                                      meter_overhead,
		bit<3>                                      discard
	) {
		eg_md.action_bitmask          = action_bitmask;
	
		eg_md.meter_id                = meter_id;
		eg_md.meter_overhead          = meter_overhead;

		eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet

	}

	// =====================================

	action egr_sf_table_1_miss(
	) {
		eg_md.action_bitmask          = 0;
	}

	// =====================================

	table egr_sf_table_1 {
		key = {
			hdr.nsh_extr_underlay.spi : exact;
			hdr.nsh_extr_underlay.si  : exact;
		}

		actions = {
			egr_sf_table_1_hit;
			egr_sf_table_1_miss;
		}

		const default_action = egr_sf_table_1_miss;
		size = NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH;
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// table needed: key {spi, si}

		egr_sf_table_1.apply();

	}

}
