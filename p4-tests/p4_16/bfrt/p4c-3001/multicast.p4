#ifndef MULTICAST
#define MULTICAST

// =============================================================================
// =============================================================================
// =============================================================================

control MulticastReplication (
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

#ifdef MULTICAST_ENABLE
	action rid_hit_unique_copies(
		switch_bd_t bd,

		bit<24>               spi,
		bit<8>                si,

		switch_nexthop_t nexthop_index,
		switch_tunnel_index_t tunnel_index,
		switch_outer_nexthop_t outer_nexthop_index

#ifdef COLLAPSE_SPI_SI_TABLES
		,
		bit<DSAP_ID_WIDTH> dsap
#endif
	) {
		eg_md.bd = bd;

		hdr_0.nsh_type1.spi     = spi;
		hdr_0.nsh_type1.si      = si;

		eg_md.nexthop = nexthop_index;
		eg_md.tunnel_0.index = tunnel_index;
		eg_md.outer_nexthop = outer_nexthop_index;

#ifdef COLLAPSE_SPI_SI_TABLES
		eg_md.nsh_md.dsap             = dsap;
#endif
	}

	action rid_hit_identical_copies(
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
			rid_hit_identical_copies;
			rid_hit_unique_copies;
		}

		size = table_size;
		const default_action = rid_miss;
	}
#endif

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// =====================================
		// Replication ID Lookup
		// =====================================

#ifdef MULTICAST_ENABLE
		if(replication_id != 0) {
			rid.apply();
		}
#endif
	}
}

#endif // MULTICAST
