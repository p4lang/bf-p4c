
control npb_ing_sf_npb_basic_adv_sfp_hash (
	inout switch_header_transport_t                 hdr_0,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm,

	in  bit<16>            mac_type,
	in  bit<8>             ip_proto,
	in  bit<16>            l4_src_port,
	in  bit<16>            l4_dst_port,
	out bit<SF_HASH_WIDTH> hash
) {
	// =========================================================================
	// Table #1 (main lkp struct):
	// =========================================================================

	bit<SF_FLOW_CLASS_WIDTH_B> flow_class_internal = 0;

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

	action ing_flow_class_hit (
		bit<SF_FLOW_CLASS_WIDTH_B>      flow_class
	) {
		// ----- change nsh -----

		// change metadata
		flow_class_internal = flow_class;

		stats.count();
	}

	// ---------------------------------

	action no_action (
	) {
		stats.count();
	}

	// ---------------------------------

	table ing_flow_class {
		key = {
			hdr_0.nsh_type1.vpn    : ternary @name("vpn");
			mac_type               : ternary @name("mac_type");
			ip_proto               : ternary @name("ip_proto");
			l4_src_port            : ternary @name("l4_src_port");
			l4_dst_port            : ternary @name("l4_dst_port");
		}

		actions = {
			no_action;
			ing_flow_class_hit;
		}

		const default_action = no_action;
		counters = stats;
		size = NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH;
	}

	// =========================================================================
	// Hash #1 (main lkp struct):
	// =========================================================================

//	Hash<bit<32>>(HashAlgorithm_t.CRC32) hash_func;
//	Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_func;
	Hash<bit<SF_HASH_WIDTH>>(HashAlgorithm_t.CRC16) hash_func;

	action compute_hash(
	) {
		hash = hash_func.get({
			hdr_0.nsh_type1.vpn,
			flow_class_internal
		});
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
		ing_flow_class.apply();
		compute_hash();
	}
}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_sfp_sel (
	inout switch_header_transport_t                 hdr_0,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	// =========================================================================
	// Table #1: Action Selector
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

#ifdef  SFF_SCHD_SIMPLE

	// Use just a plain old table...

#else  // SFF_SCHD_SIMPLE

  #ifndef SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR

	// Use an Action Profile with the table...

	ActionProfile(
		NPB_ING_SF_0_SFP_SCHD_TABLE_PART2_DEPTH
	) schd_selector;

  #else // SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR

	// Use an Action Selector with the table...
    Hash<bit<SF_HASH_WIDTH>>(
		HashAlgorithm_t.IDENTITY
	) selector_hash;
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
/*
	Hash<bit<32>>(
		HashAlgorithm_t.CRC32
	) selector_hash;
*/
	ActionProfile(NPB_ING_SF_0_SFP_SCHD_SELECTOR_TABLE_SIZE) schd_action_profile;
    ActionSelector(
		schd_action_profile,
		selector_hash,
//		SelectorMode_t.FAIR,
		SelectorMode_t.RESILIENT,
		NPB_ING_SF_0_SFP_SCHD_MAX_MEMBERS_PER_GROUP,
		NPB_ING_SF_0_SFP_SCHD_GROUP_TABLE_SIZE
	) schd_selector;

  #endif // SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR

#endif // SFF_SCHD_SIMPLE

	// ---------------------------------

	action ing_schd_hit (
		bit<24>                    spi,
		bit<8>                     si,

		bit<8>                     si_predec
	) {
		hdr_0.nsh_type1.spi    = spi;
		hdr_0.nsh_type1.si     = si;

		// change metadata
		ig_md.nsh_md.si_predec = si_predec;

		stats.count();
	}

	// ---------------------------------

	action no_action (
	) {
		stats.count();
	}

	// ---------------------------------

	table ing_schd {
		key = {
			ig_md.nsh_md.sfc          : exact @name("sfc");
#ifndef SFF_SCHD_SIMPLE
//			hdr_0.nsh_type1.vpn       : selector;
//			flow_class_internal       : selector;
			ig_md.nsh_md.hash_1       : selector;
#endif // SFF_SCHD_SIMPLE
		}

		actions = {
			no_action;
			ing_schd_hit;
		}

		const default_action = no_action;
		counters = stats;
		size = NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE;
#ifndef SFF_SCHD_SIMPLE
		implementation = schd_selector;
#endif // SFF_SCHD_SIMPLE
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
		if(ig_md.nsh_md.sfc_enable == true) {
			ing_schd.apply();
		}
	}

}
