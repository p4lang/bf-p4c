
control npb_ing_sff_flow_schd (
	inout switch_header_transport_t                 hdr,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm,

	in    bit<16>                                   hash
) {

	bit<FLOW_CLASS_WIDTH> flow_class_internal;

	// =========================================================================
	// Notes
	// =========================================================================

	// =========================================================================
	// Table #1:
	// =========================================================================

	action ing_flow_class_hit (
		bit<FLOW_CLASS_WIDTH>      flow_class
	) {
		// ----- change nsh -----

		// change metadata
		flow_class_internal = flow_class;
	}

	// ---------------------------------

	table ing_flow_class {
		key = {
			hdr.nsh_type1.vpn      : ternary @name("vpn");
			ig_md.lkp.mac_type     : ternary @name("mac_type");
			ig_md.lkp.ip_proto     : ternary @name("ip_proto");
			ig_md.lkp.l4_src_port  : ternary @name("l4_src_port");
			ig_md.lkp.l4_dst_port  : ternary @name("l4_dst_port");
		}

		actions = {
			NoAction;
			ing_flow_class_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SFF_FLW_CLS_TABLE_DEPTH;
	}

	// =========================================================================
	// Hash:
	// =========================================================================

	// =========================================================================
	// Table #2: Action Selector
	// =========================================================================

#ifdef  SFF_SCHD_SIMPLE

	// Use just a plain old table...

#else  // SFF_SCHD_SIMPLE

  #ifndef SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR

	// Use an Action Profile with the table...

	ActionProfile(
		NPB_ING_SFF_SCHD_TABLE_PART2_DEPTH
	) schd_selector;

  #else // SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR

	// Use an Action Selector with the table...

/*
    Hash<switch_uint16_t>(
		HashAlgorithm_t.IDENTITY
	) selector_hash;
*/
/*
	Hash<bit<16>>(
		HashAlgorithm_t.CRC16
	) selector_hash;
*/
	Hash<bit<32>>(
		HashAlgorithm_t.CRC32
	) selector_hash;

    ActionSelector(
		NPB_ING_SFF_SCHD_TABLE_PART2_DEPTH,
		selector_hash,
		SelectorMode_t.FAIR
//		SelectorMode_t.RESILIENT
	) schd_selector;

  #endif // SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR

#endif // SFF_SCHD_SIMPLE

	// ---------------------------------

	action ing_schd_hit (
		bit<24>                    spi,
		bit<8>                     si,

		bit<3>                     sf_bitmask
	) {
		// ----- change nsh -----

		// change metadata
		
		// base - word 0

		// base - word 1
		hdr.nsh_type1.spi          = spi;
		hdr.nsh_type1.si           = si;

		// ext type 1 - word 0
		ig_md.nsh_type1.sf_bitmask = sf_bitmask;

		// change metadata
	}

	// ---------------------------------

	table ing_schd {
		key = {
			ig_md.nsh_type1.sfc    : exact @name("sfc");
#ifndef SFF_SCHD_SIMPLE
			hdr.nsh_type1.vpn      : selector;
			flow_class_internal    : selector;
//			hash                   : selector;
#endif // SFF_SCHD_SIMPLE
		}

		actions = {
			NoAction;
			ing_schd_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SFF_SCHD_TABLE_PART1_DEPTH;
#ifndef SFF_SCHD_SIMPLE
		implementation = schd_selector;
#endif // SFF_SCHD_SIMPLE
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
		if(ig_md.nsh_type1.sfc_is_new == true) {
			ing_flow_class.apply();
			ing_schd.apply();
		}
	}

}
