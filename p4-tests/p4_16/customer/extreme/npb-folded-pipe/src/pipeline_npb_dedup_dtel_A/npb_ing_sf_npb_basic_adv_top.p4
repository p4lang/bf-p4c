#ifndef _NPB_ING_SF_NPB_BASIC_ADV_TOP_
#define _NPB_ING_SF_NPB_BASIC_ADV_TOP_

control Npb_Ing_Sf_Npb_Basic_Adv_Top (
	inout switch_lookup_fields_t                    lkp,
	inout switch_header_transport_t                 hdr_0,
	inout switch_header_outer_t                     hdr_1,
	inout switch_header_inner_t                     hdr_2,
	inout udf_h                                     hdr_udf,

	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) (
	MODULE_DEPLOYMENT_PARAMS
) {

	IngressAcl(
		INSTANCE_DEPLOYMENT_PARAMS,
#if defined(SF_0_ACL_SHARED_IP_ENABLE)
		INGRESS_IPV4_ACL_TABLE_SIZE,
#else
		INGRESS_IPV4_ACL_TABLE_SIZE,
		INGRESS_IPV6_ACL_TABLE_SIZE,
#endif
		INGRESS_MAC_ACL_TABLE_SIZE,
		INGRESS_L7_ACL_TABLE_SIZE
	) acl;

#ifdef SF_0_DEDUP_ENABLE
	npb_dedup_(INSTANCE_DEPLOYMENT_PARAMS) npb_dedup;
#endif

	// =========================================================================
	// Table #1: SFF Action Select
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;  // direct counter

	bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags = 0;

	action ing_sf_action_sel_hit(
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
		bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags
#endif
	) {
		stats.count();

#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
		int_ctrl_flags = int_ctrl_flags;
#endif
	}

	// =====================================

	action ing_sf_action_sel_miss(
	) {
		stats.count();

	}

	// =====================================

	table ing_sf_action_sel {
		key = {
			ig_md.nsh_md.spi           : exact @name("spi");
			ig_md.nsh_md.si            : exact @name("si");
		}

		actions = {
			ing_sf_action_sel_hit;
			ing_sf_action_sel_miss;
		}

		const default_action = ing_sf_action_sel_miss;
		size = NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH;
		counters = stats;
	}

	// =========================================================================
	// Table #2: SF IP Length Range
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_ip_len;  // direct counter

	bit<SF_L3_LEN_RNG_WIDTH> ip_len_rng = 0;

#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
	action ing_sf_ip_len_rng_hit(
		bit<SF_L3_LEN_RNG_WIDTH> rng_bitmask
	) {
		stats_ip_len.count();

		ip_len_rng = rng_bitmask;
	}

	// =====================================

	action ing_sf_ip_len_rng_miss(
	) {
		stats_ip_len.count();
	}

	// =====================================

	table ing_sf_ip_len_rng {
		key = {
			lkp.ip_len : range @name("ip_len");
		}

		actions = {
//			NoAction;
			ing_sf_ip_len_rng_hit;
			ing_sf_ip_len_rng_miss;
		}

		const default_action = ing_sf_ip_len_rng_miss;
		size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH;
		counters = stats_ip_len;
	}
#endif

	// =========================================================================
	// Table #3: SF L4 Src Port Range
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_l4_src_port;  // direct counter

	bit<SF_L4_SRC_RNG_WIDTH> l4_src_port_rng = 0;

#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
	action ing_sf_l4_src_port_rng_hit(
		bit<SF_L4_SRC_RNG_WIDTH> rng_bitmask
	) {
		stats_l4_src_port.count();

		l4_src_port_rng = rng_bitmask;
	}

	// =====================================

	action ing_sf_l4_src_port_rng_miss(
	) {
		stats_l4_src_port.count();
	}

	// =====================================

	table ing_sf_l4_src_port_rng {
		key = {
			lkp.l4_src_port : range @name("l4_src_port");
		}

		actions = {
//			NoAction;
			ing_sf_l4_src_port_rng_hit;
			ing_sf_l4_src_port_rng_miss;
		}

		const default_action = ing_sf_l4_src_port_rng_miss;
		size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH;
		counters = stats_l4_src_port;
	}
#endif

	// =========================================================================
	// Table #4: SF L4 Dst Port Range
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_l4_dst_port;  // direct counter

	bit<SF_L4_DST_RNG_WIDTH> l4_dst_port_rng = 0;

#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
	action ing_sf_l4_dst_port_rng_hit(
		bit<SF_L4_DST_RNG_WIDTH> rng_bitmask
	) {
		stats_l4_dst_port.count();

		l4_dst_port_rng = rng_bitmask;
	}

	// =====================================

	action ing_sf_l4_dst_port_rng_miss(
	) {
		stats_l4_dst_port.count();
	}

	// =====================================

	table ing_sf_l4_dst_port_rng {
		key = {
			lkp.l4_dst_port : range @name("l4_dst_port");
		}

		actions = {
//			NoAction;
			ing_sf_l4_dst_port_rng_hit;
			ing_sf_l4_dst_port_rng_miss;
		}

		const default_action = ing_sf_l4_dst_port_rng_miss;
		size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH;
		counters = stats_l4_dst_port;
	}
#endif

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
			ig_md.nsh_md.si = ig_md.nsh_md.si - 1; // decrement sp_index
			ig_md.nsh_md.si_predec = ig_md.nsh_md.si_predec - 1; // decrement sp_index
#else
			ig_md.nsh_md.si = ig_md.nsh_md.si |-| 1; // decrement sp_index
			ig_md.nsh_md.si_predec = ig_md.nsh_md.si_predec - |1|; // decrement sp_index
#endif

			// =====================================
			// Action(s)
			// =====================================

			// -------------------------------------
			// Action #0 - Policy
			// -------------------------------------

#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
			ing_sf_ip_len_rng.apply();
#endif
#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
			ing_sf_l4_src_port_rng.apply();
#endif
#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
			ing_sf_l4_dst_port_rng.apply();
#endif

			acl.apply(
				lkp,
				ig_md,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm,
				lkp.ip_len,
				ip_len_rng,
				lkp.l4_src_port,
				l4_src_port_rng,
				lkp.l4_dst_port,
				l4_dst_port_rng,
				hdr_0,
				hdr_udf,
				int_ctrl_flags
			);

			// -------------------------------------
			// Action #1 - Deduplication
			// -------------------------------------
#ifdef SF_0_DEDUP_ENABLE
/*
			npb_dedup.apply (
				ig_md.nsh_md.dedup_en,
				lkp,                 // for hash
				(bit<VPN_ID_WIDTH>)ig_md.nsh_md.vpn, // for hash
				ig_md.nsh_md.hash_2,
//				ig_md.ingress_port,          // for dedup
				ig_md.nsh_md.sap,    // for dedup
				ig_intr_md_for_dprsr.drop_ctl
			);
*/
#endif

		}
	}
}

#endif
