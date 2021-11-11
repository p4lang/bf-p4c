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
	// Table #1: 
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;  // direct counter

#ifdef MULTICAST_ENABLE
	action rid_hit_unique_copies(
		switch_bd_t            bd,

		bit<SPI_WIDTH>         spi,
		bit<8>                 si,

		switch_nexthop_t       nexthop_index,
		switch_tunnel_ip_index_t tunnel_index,
		switch_tunnel_nexthop_t outer_nexthop_index
	) {
		stats.count();

		eg_md.bd             = bd;

		eg_md.nsh_md.spi     = spi;
		eg_md.nsh_md.si      = si;

		eg_md.nexthop        = nexthop_index;
		eg_md.tunnel_0.dip_index = tunnel_index;
		eg_md.tunnel_nexthop = outer_nexthop_index;
	}

	action rid_hit_identical_copies(
		switch_bd_t            bd
	) {
		stats.count();

		eg_md.bd             = bd;
	}

	action rid_miss() {
		stats.count();

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
		counters = stats;
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
