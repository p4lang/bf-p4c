#ifndef _NPB_ING_SF_1_MMULTICAST_
#define _NPB_ING_SF_1_MMULTICAST_

control npb_ing_sf_multicast_top_part1 (
	inout switch_header_transport_t                 hdr_0,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) ( 
	switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH
) {

	// =========================================================================
	// Table #1: Action Select
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;  // direct counter

	action ing_sf_action_sel_hit(
		switch_mgid_t mgid
	) {
		stats.count();

		ig_md.multicast.id = mgid;

		ig_md.egress_port_lag_index = 0;
	}

	// =====================================

	action ing_sf_action_sel_miss(
	) {
		stats.count();

	}

	// =====================================

	table ing_sf_action_sel {
		key = {
			hdr_0.nsh_type1.spi : exact @name("spi");
			hdr_0.nsh_type1.si  : exact @name("si");
		}

		actions = {
			ing_sf_action_sel_hit;
			ing_sf_action_sel_miss;
		}

		size = table_size;
		const default_action = ing_sf_action_sel_miss;
		counters = stats;
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// =====================================
		// Action Lookup
		// =====================================

		if(ing_sf_action_sel.apply().hit) {

			// =====================================
			// Decrement SI
			// =====================================

			// Derek: We have moved this here, rather than at the end of the sf,
			// in violation of RFC8300.  This is because of an issue were a sf
			// can reclassify the packet with a new si, which would then get immediately
			// decremented.  This means firmware would have to add 1 to the si value
			// the really wanted.  So we move it here so that is gets decremented after
			// the lookup that uses it, but before any actions have run....

#ifdef BUG_09719_WORKAROUND
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
#else
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si |-| 1; // decrement sp_index
#endif

		}

	}
}

// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sf_multicast_top_part2 (
	inout switch_header_transport_t hdr_0,
	in switch_rid_t replication_id,
	in switch_port_t port,
	inout switch_egress_metadata_t eg_md
) (
	switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE
) {

	// =========================================================================
	// Table #1: 
	// =========================================================================

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

	}
}

#endif // EGR_SF_MULTICAST_TOP
