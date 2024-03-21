
control npb_ing_sfc_top (
	inout switch_header_t                           hdr,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	bit<SRVC_FUNC_CHAIN_WIDTH> service_func_chain_;

	// =========================================================================
	// Table #1
	// =========================================================================

	action ing_sfc_table_1_hit (
		bit<FLOW_TYPE_WIDTH>       flow_type
	) {
		// ext type 1 - word 0
		ig_md.nsh_extr.extr_flow_type               = flow_type;
	}

	// ---------------------------------

	table ing_sfc_table_1 {
		key = {
			// l3
			ig_md.lkp_nsh.ip_type                   : exact;
			ig_md.lkp_nsh.ip_proto                  : exact;

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			ing_sfc_table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH;
	}

#ifdef SFC_SIMPLE

	// =========================================================================
	// Table #2
	// =========================================================================

    // Note: local and remote bitmasks defined as follows....
    //
    //   [0:0] sf #1: ingress basic/advanced
    //   [1:1] sf #2: unused (was multicast)
    //   [2:2] sf #3: egress proxy 

	action ing_sfc_table_2_hit (
		bit<24>                    nsh_sph_spi,
		bit<8>                     nsh_sph_si,

		bit<8>                     srvc_func_bitmask_local,
		bit<8>                     srvc_func_bitmask_remote,

		bit<SRVC_FUNC_CHAIN_WIDTH> service_func_chain
	) {
		ig_md.nsh_extr.valid            = 1;
		
		// base - word 0

		// base - word 1
		ig_md.nsh_extr.spi                           = nsh_sph_spi;
		ig_md.nsh_extr.si                            = nsh_sph_si;

		// ext type 1 - word 0
		ig_md.nsh_extr.extr_srvc_func_bitmask_local  = srvc_func_bitmask_local;
		ig_md.nsh_extr.extr_srvc_func_bitmask_remote = srvc_func_bitmask_remote;
//		ig_md.nsh_extr.extr_tenant_id                = ig_md.tunnel.id;
		ig_md.nsh_extr.extr_tenant_id                = (bit<TENANT_ID_WIDTH>)ig_md.bd;

		// change metadata
		service_func_chain_                          = service_func_chain;
	}

	// ---------------------------------

	table ing_sfc_table_2 {
		key = {
			ig_md.nsh_extr.extr_tenant_id : exact;
			ig_md.nsh_extr.extr_flow_type : exact;
		}

		actions = {
			NoAction;
			ing_sfc_table_2_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SFC_NSH_TABLE_DEPTH;
	}

#else // SFC_SIMPLE

	// =========================================================================
	// Table #2
	// =========================================================================

	action ing_sfc_table_2_hit (
		bit<8>                     nsh_sph_si,

		bit<8>                     srvc_func_bitmask_local,
		bit<8>                     srvc_func_bitmask_remote,

		bit<SRVC_FUNC_CHAIN_WIDTH> service_func_chain
	) {
		// base - word 0

		// base - word 1
		ig_md.nsh_extr.si                            = nsh_sph_si;

		// ext type 1 - word 0
		ig_md.nsh_extr.extr_srvc_func_bitmask_local  = srvc_func_bitmask_local;
		ig_md.nsh_extr.extr_srvc_func_bitmask_remote = srvc_func_bitmask_remote;
//		ig_md.nsh_extr.extr_tenant_id                = ig_md.tunnel.id;
		ig_md.nsh_extr.extr_tenant_id                = (bit<TENANT_ID_WIDTH>)ig_md.bd;

		// change metadata
		service_func_chain_                          = service_func_chain;
	}

	// ---------------------------------

	table ing_sfc_table_2 {
		key = {
			ig_md.nsh_extr.extr_tenant_id : exact;
			ig_md.nsh_extr.extr_flow_type : exact;
		}

		actions = {
			NoAction;
			ing_sfc_table_2_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SFC_NSH_TABLE_DEPTH;
	}

	// =========================================================================
	// Table #3
	// =========================================================================

#ifdef SFC_COMPLEX_TYPE_ACTION_SELECTOR

	// action selector info
	Hash<bit<16>>(HashAlgorithm_t.CRC16) sel_hash;
//	ActionSelector(1024, sel_hash, SelectorMode_t.FAIR) action_selector;
	ActionSelector(1024, sel_hash, SelectorMode_t.RESILIENT) action_selector;

#else // SFC_COMPLEX_TYPE_ACTION_SELECTOR

	// action profile info
	ActionProfile(NPB_ING_SFC_SCHD_TABLE_PART2_DEPTH) action_profile;

#endif // SFC_COMPLEX_TYPE_ACTION_SELECTOR

	// ---------------------------------

	action ing_sfc_table_3_hit (
		bit<24>                    nsh_sph_spi
	) {
		ig_md.nsh_extr.valid            = 1;
		
		// base - word 1
		ig_md.nsh_extr.spi              = nsh_sph_spi;
	}

	// ---------------------------------

	table ing_sfc_table_3 {
		key = {
			service_func_chain_           : exact;
			ig_md.nsh_extr.extr_tenant_id : selector;
			ig_md.nsh_extr.extr_flow_type : selector;
		}

		actions = {
			NoAction;
			ing_sfc_table_3_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SFC_SCHD_TABLE_PART1_DEPTH;
#ifdef SFC_COMPLEX_TYPE_ACTION_SELECTOR
		implementation = action_selector;
#else // SFC_COMPLEX_TYPE_ACTION_SELECTOR
		implementation = action_profile;
#endif // SFC_COMPLEX_TYPE_ACTION_SELECTOR
	}

#endif // SFC_SIMPLE

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		if(hdr.nsh_extr_underlay.isValid()) {

			// ***** Packet has an NSH header on it *****

			ig_md.nsh_extr.valid                        = 1;

			// base: word 0

			// base: word 1
			ig_md.nsh_extr.spi                          = hdr.nsh_extr_underlay.spi;
			ig_md.nsh_extr.si                           = hdr.nsh_extr_underlay.si;
    
			// ext: type 2 - word 0

			// ext: type 2 - word 1+
			ig_md.nsh_extr.extr_srvc_func_bitmask_local = hdr.nsh_extr_underlay.extr_srvc_func_bitmask; //  1 byte
			ig_md.nsh_extr.extr_tenant_id               = hdr.nsh_extr_underlay.extr_tenant_id;         //  3 bytes
			ig_md.nsh_extr.extr_flow_type               = hdr.nsh_extr_underlay.extr_flow_type;         //  1 byte?

		} else {

			// ***** Packet does NOT have an NSH header on it *****

			if(ing_sfc_table_1.apply().hit) {
#ifdef SFC_SIMPLE
				ing_sfc_table_2.apply();
#else // SFC_SIMPLE
				if(ing_sfc_table_2.apply().hit) {
					ing_sfc_table_3.apply();
				}
#endif // SFC_SIMPLE
			}

		}

	}

}
