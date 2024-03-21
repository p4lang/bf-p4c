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
	switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH
) {

	// temporary internal variables
//  bit<1> action_bitmask_internal;

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: egress action_bitmask defined as follows....
	//
	//   [0:0] act #1: multicast

	// =========================================================================
	// Table #1: Action Select
	// =========================================================================

	action ing_sf_action_sel_hit(
//		bit<1> action_bitmask,
		switch_mgid_t mgid
	) {
//		action_bitmask_internal = action_bitmask;

		ig_md.multicast.id = mgid;

		ig_md.egress_port_lag_index = 0;
	}

	// =====================================

	action ing_sf_action_sel_miss(
	) {
//		action_bitmask_internal = 0;
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
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// =====================================
		// Action Lookup
		// =====================================

		if(ing_sf_action_sel.apply().hit) {

//			ig_md.nsh_md.sf1_active = true;

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

			// =====================================
			// Action(s)
			// =====================================

//			if(action_bitmask_internal[0:0] == 1) {

				// There used to be a table here that took sfc and gave mgid.  It has been removed in the latest iteration.

//			}

		} else {
//			ig_md.nsh_md.sf1_active = false;
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
	// Notes
	// =========================================================================

	// =========================================================================
	// Table #1: 
	// =========================================================================
/*
#ifdef MULTICAST_ENABLE
	action rid_hit_nsh(
		switch_bd_t bd,

		bit<24>               spi,
		bit<8>                si,

		switch_nexthop_t nexthop_index,
		switch_tunnel_index_t tunnel_index,
		switch_outer_nexthop_t outer_nexthop_index
	) {
		eg_md.bd = bd;

		hdr_0.nsh_type1.spi     = spi;
		hdr_0.nsh_type1.si      = si;

		eg_md.nexthop = nexthop_index;
		eg_md.tunnel_0.index = tunnel_index;
		eg_md.outer_nexthop = outer_nexthop_index;
	}

	action rid_hit(
		switch_bd_t bd
	) {
		eg_md.bd = bd;
	}

	action rid_miss() {
	}

	table rid {
		key = {
			replication_id : exact;
		}
		actions = {
			rid_miss;
			rid_hit;
			rid_hit_nsh;
		}

		size = table_size;
		const default_action = rid_miss;
	}
#endif
*/
	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// =====================================
		// Action Lookup
		// =====================================
/*
		if(eg_md.nsh_md.sf1_active == true) {

			// =====================================
			// Decrement SI
			// =====================================

			// Derek: We have moved this here, rather than at the end of the sf,
			// in violation of RFC8300.  This is because of an issue were a sf
			// can reclassify the packet with a new si, which would then get immediately
			// decremented.  This means firmware would have to add 1 to the si value
			// the really wanted.  So we move it here so that is gets decremented after
			// the lookup that uses it, but before any actions have run....

			// NOTE: THIS IS DONE IN EGRESS INSTEAD OF INGRESS, BECAUSE WE DON"T FIT OTHERWISE!

#ifdef BUG_09719_WORKAROUND
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
#else
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si |-| 1; // decrement sp_index
#endif
			// =====================================
			// Action(s)
			// =====================================

		}
*/
		// =====================================
		// Replication ID Lookup
		// =====================================
/*
#ifdef MULTICAST_ENABLE
		if(replication_id != 0) {
			rid.apply();
		}
#endif
*/
	}
}

#endif // EGR_SF_MULTICAST_TOP
