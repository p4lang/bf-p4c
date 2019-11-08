
control npb_egr_sf_proxy_act_sel (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,

	out   bit<4>                                      action_bitmask_,
	out   bit<NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH_POW2> meter_id_,
	out   bit<8>                                      meter_overhead_
) {

	// =========================================================================
	// Table
	//
	// Function: spi and si --> actions
	// =========================================================================

	action hit(
		bit<4>                                      action_bitmask,
		bit<NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH_POW2> meter_id,
		bit<8>                                      meter_overhead,
		bit<3>                                      discard
	) {
		action_bitmask_               = action_bitmask;
	
		meter_id_                     = meter_id;
		meter_overhead_               = meter_overhead;

		eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet

	}

	// =====================================

	action miss(
	) {
		action_bitmask_               = 0;
	}

	// =====================================

	table myTable {
		key = {
			hdr.nsh_extr_underlay.spi : exact;
			hdr.nsh_extr_underlay.si  : exact;
		}

		actions = {
			hit;
			miss;
		}

		const default_action = miss;
		size = NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH;
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// table needed: key {spi, si}

		myTable.apply();

	}

}
