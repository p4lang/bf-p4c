//#include "npb_ing_sf_npb_basic_adv_acl.p4"
#include "npb_ing_sf_npb_basic_adv_sfp_sel.p4"
#ifdef SF_0_DEDUP_ENABLE
  #include "npb_ing_sf_npb_basic_adv_dedup.p4"
#endif

control npb_ing_sf_npb_basic_adv_top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_header_outer_t                     hdr_1,
	inout switch_header_inner_t                     hdr_2,
    inout udf_h                                     hdr_udf,

	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	IngressAcl(
		INGRESS_IPV4_ACL_TABLE_SIZE,
#if defined(SF_0_ACL_SHARED_IP_ENABLE)
#else
		INGRESS_IPV6_ACL_TABLE_SIZE,
#endif
		INGRESS_MAC_ACL_TABLE_SIZE,
		INGRESS_L7_ACL_TABLE_SIZE
	) acl;

	// temporary internal variables
//	bit<2>  action_bitmask_internal;

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: egress action_bitmask defined as follows....
	//
	//   [0:0] act #1: policy
	//   [1:1] act #2: unused (was dedup)

	// =========================================================================
	// Table #1: Action Select
	// =========================================================================

	bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags = 0;

	action ing_sf_action_sel_hit(
//		bit<2>  action_bitmask,
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
		bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags
#endif
//      bit<3>  discard
	) {
//		action_bitmask_internal = action_bitmask;
#ifdef SF_0_ACL_INT_CTRL_FLAGS_ENABLE
		int_ctrl_flags = int_ctrl_flags;
#endif

//      ig_intr_md_for_dprsr.drop_ctl = discard; // drop packet
	}

	// =====================================

	action ing_sf_action_sel_miss(
	) {
//		action_bitmask_internal = 0;
//		int_ctrl_flags = 0;
	}

	// =====================================

	table ing_sf_action_sel {
		key = {
			hdr_0.nsh_type1.spi        : exact @name("spi");
			hdr_0.nsh_type1.si         : exact @name("si");
		}

		actions = {
			NoAction;
			ing_sf_action_sel_hit;
			ing_sf_action_sel_miss;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH;
	}

	// =========================================================================
	// Table #2: IP Length Range
	// =========================================================================

	bit<SF_L3_LEN_RNG_WIDTH> ip_len = 0;
	bool                     ip_len_is_rng_bitmask = false;

#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
	action ing_sf_ip_len_rng_hit(
		bit<SF_L3_LEN_RNG_WIDTH> rng_bitmask
	) {
		ip_len = rng_bitmask;
		ip_len_is_rng_bitmask = true;
	}

	// =====================================

	action ing_sf_ip_len_rng_miss(
	) {
		ip_len = ig_md.lkp_1.ip_len;
		ip_len_is_rng_bitmask = false;
	}

	// =====================================

	table ing_sf_ip_len_rng {
		key = {
			ig_md.lkp_1.ip_len : range @name("ip_len");
		}

		actions = {
			NoAction;
			ing_sf_ip_len_rng_hit;
			ing_sf_ip_len_rng_miss;
		}

		const default_action = ing_sf_ip_len_rng_miss;
		size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH;
	}
#endif

	// =========================================================================
	// Table #3: L4 Src Port Range
	// =========================================================================

	bit<SF_L4_SRC_RNG_WIDTH> l4_src_port = 0;
	bool                     l4_src_port_is_rng_bitmask = false;

#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
	action ing_sf_l4_src_port_rng_hit(
		bit<SF_L4_SRC_RNG_WIDTH> rng_bitmask
	) {
		l4_src_port = rng_bitmask;
		l4_src_port_is_rng_bitmask = true;
	}

	// =====================================

	action ing_sf_l4_src_port_rng_miss(
	) {
		l4_src_port = ig_md.lkp_1.l4_src_port;
		l4_src_port_is_rng_bitmask = false;
	}

	// =====================================

	table ing_sf_l4_src_port_rng {
		key = {
			ig_md.lkp_1.l4_src_port : range @name("l4_src_port");
		}

		actions = {
			NoAction;
			ing_sf_l4_src_port_rng_hit;
			ing_sf_l4_src_port_rng_miss;
		}

		const default_action = ing_sf_l4_src_port_rng_miss;
		size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH;
	}
#endif

	// =========================================================================
	// Table #4: L4 Dst Port Range
	// =========================================================================

	bit<SF_L4_DST_RNG_WIDTH> l4_dst_port = 0;
	bool                     l4_dst_port_is_rng_bitmask = false;

#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
	action ing_sf_l4_dst_port_rng_hit(
		bit<SF_L4_DST_RNG_WIDTH> rng_bitmask
	) {
		l4_dst_port = rng_bitmask;
		l4_dst_port_is_rng_bitmask = true;
	}

	// =====================================

	action ing_sf_l4_dst_port_rng_miss(
	) {
		l4_dst_port = ig_md.lkp_1.l4_dst_port;
		l4_dst_port_is_rng_bitmask = false;
	}

	// =====================================

	table ing_sf_l4_dst_port_rng {
		key = {
			ig_md.lkp_1.l4_dst_port : range @name("l4_dst_port");
		}

		actions = {
			NoAction;
			ing_sf_l4_dst_port_rng_hit;
			ing_sf_l4_dst_port_rng_miss;
		}

		const default_action = ing_sf_l4_dst_port_rng_miss;
		size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH;
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
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
			ig_md.nsh_md.si_predec = ig_md.nsh_md.si_predec - 1; // decrement sp_index
#else
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si |-| 1; // decrement sp_index
			ig_md.nsh_md.si_predec = ig_md.nsh_md.si_predec - |1|; // decrement sp_index
#endif

			// =====================================
			// Action(s)
			// =====================================

//			if(action_bitmask_internal[0:0] == 1) {

				// -------------------------------------
				// Action #0 - Policy
				// -------------------------------------

#ifdef SF_0_L3_LEN_RNG_TABLE_ENABLE
				ing_sf_ip_len_rng.apply();
#else
				ip_len = ig_md.lkp_1.ip_len;
				ip_len_is_rng_bitmask = false;
#endif
#ifdef SF_0_L4_SRC_RNG_TABLE_ENABLE
				ing_sf_l4_src_port_rng.apply();
#else
				l4_src_port = ig_md.lkp_1.l4_src_port;
				l4_src_port_is_rng_bitmask = false;
#endif
#ifdef SF_0_L4_DST_RNG_TABLE_ENABLE
				ing_sf_l4_dst_port_rng.apply();
#else
				l4_dst_port = ig_md.lkp_1.l4_dst_port;
				l4_dst_port_is_rng_bitmask = false;
#endif

				acl.apply(
					ig_md.lkp_1,
					ig_md,
					ig_intr_md_for_dprsr,
					ig_intr_md_for_tm,
					ip_len,
					ip_len_is_rng_bitmask,
					l4_src_port,
					l4_src_port_is_rng_bitmask,
					l4_dst_port,
					l4_dst_port_is_rng_bitmask,
					hdr_0,
					hdr_1,
					hdr_2,
					hdr_udf,
					int_ctrl_flags
				);
//			}

//			if(action_bitmask_internal[1:1] == 1) {

				// -------------------------------------
				// Action #1 - Deduplication
				// -------------------------------------
#ifdef SF_0_DEDUP_ENABLE
/*
				npb_ing_sf_npb_basic_adv_dedup.apply (
					ig_md.nsh_md.dedup_en,
					ig_md.lkp_1,         // for hash
					(bit<VPN_ID_WIDTH>)hdr_0.nsh_type1.vpn, // for hash
					ig_md.nsh_md.hash_2,
//					ig_md.port,          // for dedup
					hdr_0.nsh_type1.sap, // for dedup
					ig_intr_md_for_dprsr.drop_ctl
				);
*/
#endif
//			}

		}
/*
		npb_ing_sf_npb_basic_adv_sfp_sel.apply(
			hdr_0,
			ig_md,
			ig_intr_md,
			ig_intr_md_from_prsr,
			ig_intr_md_for_dprsr,
			ig_intr_md_for_tm
		);
*/
	}
}
