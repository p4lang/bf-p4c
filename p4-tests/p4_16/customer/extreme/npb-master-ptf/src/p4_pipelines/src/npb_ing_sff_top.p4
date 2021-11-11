
#ifndef _NPB_ING_SFF_TOP_
#define _NPB_ING_SFF_TOP_

control npb_ing_sff_top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	// =========================================================================
	// Table #1: FIB
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

	// =====================================

	action drop_pkt (
	) {
		stats.count();

		ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//		ig_md.nsh_md.end_of_path = false;
	}

	// =====================================

	// sets: port_lag_index
	action unicast(
		switch_port_lag_index_t port_lag_index,

//		bool end_of_chain,
		bit<6> lag_hash_mask_en
	) {
		stats.count();

		ig_md.egress_port_lag_index = port_lag_index;

		ig_md.nsh_md.end_of_path = true; // since we're bypassing nexthop and so can't put a tunnel on, we don't want an nsh header either.
		ig_md.nsh_md.lag_hash_mask_en = lag_hash_mask_en;
	}

	// =====================================

	// sets: mgid (well, actually mgid set by sf#1, but it could be set here instead!)
	action multicast(
//		switch_mgid_t mgid,

//		bool end_of_chain,
		bit<6> lag_hash_mask_en
	) {
		stats.count();

//		ig_md.multicast.id = mgid;

		ig_md.nsh_md.end_of_path = true; // since we're bypassing nexthop and so can't put a tunnel on, we don't want an nsh header either.
		ig_md.nsh_md.lag_hash_mask_en = lag_hash_mask_en;
	}

	// =====================================

	// sets: nexthop
	action redirect(
		switch_nexthop_t nexthop_index,

		bool end_of_chain,
		bit<6> lag_hash_mask_en
	) {
		stats.count();

		ig_md.nexthop = nexthop_index;

		ig_md.nsh_md.end_of_path = end_of_chain;
		ig_md.nsh_md.lag_hash_mask_en = lag_hash_mask_en;
	}

	// =====================================

	table ing_sff_fib {
		key = {
			ig_md.nsh_md.spi        : exact @name("spi");
#ifdef SFF_PREDECREMENTED_SI_ENABLE
			ig_md.nsh_md.si_predec  : exact @name("si");
#else
			ig_md.nsh_md.si         : exact @name("si");
#endif
		}

		actions = {
			drop_pkt;
			unicast;
			multicast;
			redirect;
		}

		// Derek: drop packet on miss...
		//
		// RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
		// do not correspond to a valid next hop in a valid SFP, that packet MUST
		// be dropped by the SFF.

		const default_action = drop_pkt;
		counters = stats;
		size = NPB_ING_SFF_ARP_TABLE_DEPTH;
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
		// -------------------------------------
		// Forwarding Lookup
		// -------------------------------------

		ing_sff_fib.apply();

	}
}

#endif /* _NPB_ING_SFF_TOP_ */
