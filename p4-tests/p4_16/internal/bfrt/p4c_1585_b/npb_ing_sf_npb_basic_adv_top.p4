//#include "npb_ing_sf_npb_basic_adv_dedup.p4"

control npb_ing_sf_npb_basic_adv_top (
	inout switch_header_t                           hdr,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	// candidate values (used if all tables have hits)
	bit<FLOW_TYPE_WIDTH> flow_type_new;
	bit<8>               nsh_sph_si_new;
	bit<8>               nsh_srvc_func_bitmask_local_new;
	bit<8>               nsh_srvc_func_bitmask_remote_new;

	// local values
	bit<1>                     had_hit;
	bit<SRVC_FUNC_CHAIN_WIDTH> service_func_chain_;
	bit<1>                     action_bitmask_;

	// =========================================================================
	// Table #1
	// =========================================================================

    // Note: local and remote bitmasks defined as follows....
    //
    //   [0:0] sf #1: ingress basic/advanced
    //   [1:1] sf #2: unused (was multicast)
    //   [2:2] sf #3: egress proxy 

	// Note: action_bitmask defined as follows....
	//
	//   [0:0] unused (was dedup)

	action npb_ing_sf_table_1_hit (
		bit<FLOW_TYPE_WIDTH>       flow_type,

		bit<8>                     nsh_sph_si,

		bit<8>                     srvc_func_bitmask_local,
		bit<8>                     srvc_func_bitmask_remote,

		bit<SRVC_FUNC_CHAIN_WIDTH> service_func_chain,

		bit<1>                     action_bitmask,
		bit<3>                     discard
	) {
		had_hit                          = 1;

		// change nsh

		// change metadata
		flow_type_new                    = flow_type;

		// base - word 1
		nsh_sph_si_new                   = nsh_sph_si;

		// ext type 1 - word 0
		nsh_srvc_func_bitmask_local_new  = srvc_func_bitmask_local;
		nsh_srvc_func_bitmask_remote_new = srvc_func_bitmask_remote;

		// change metadata
		service_func_chain_              = service_func_chain;

		action_bitmask_                  = action_bitmask;
		ig_intr_md_for_dprsr.drop_ctl    = discard; // drop packet
	}

	// ---------------------------------
	// v4 exact
	// ---------------------------------

	table npb_ing_sf_table_1_v4_exact {
		key = {
			// l3
            ig_md.lkp_nsh.ip_type                   : exact;
			ig_md.lkp_nsh.ip_proto                  : exact;
			ig_md.lkp_nsh.ipv4_src_addr             : exact;
			ig_md.lkp_nsh.ipv4_dst_addr             : exact;

			// l4
			ig_md.lkp_nsh.l4_src_port               : exact;
			ig_md.lkp_nsh.l4_dst_port               : exact; 

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			npb_ing_sf_table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_BAS_ADV_POLICY_V4_EXACT_MATCH_TABLE_DEPTH;
	}

	// ---------------------------------
	// v4 lpm
	// ---------------------------------

	table npb_ing_sf_table_1_v4_lpm {
		key = {
			// l3
            ig_md.lkp_nsh.ip_type                   : exact;
			ig_md.lkp_nsh.ip_proto                  : exact;
			ig_md.lkp_nsh.ipv4_src_addr             : ternary;
			ig_md.lkp_nsh.ipv4_dst_addr             : ternary;

			// l4
			ig_md.lkp_nsh.l4_src_port               : exact;
			ig_md.lkp_nsh.l4_dst_port               : exact; 

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			npb_ing_sf_table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_BAS_ADV_POLICY_V4_LPM_TABLE_DEPTH;
	}


	// ---------------------------------
	// v6 exact
	// ---------------------------------

#ifdef IPV6_ENABLE
	table npb_ing_sf_table_1_v6_exact {
		key = {
			// l3
            ig_md.lkp_nsh.ip_type                   : exact;
			ig_md.lkp_nsh.ip_proto                  : exact;
			ig_md.lkp_nsh.ipv6_src_addr             : exact;
			ig_md.lkp_nsh.ipv6_dst_addr             : exact;

			// l4
			ig_md.lkp_nsh.l4_src_port               : exact;
			ig_md.lkp_nsh.l4_dst_port               : exact; 

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			npb_ing_sf_table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_BAS_ADV_POLICY_V6_EXACT_MATCH_TABLE_DEPTH;
	}
#endif

	// ---------------------------------
	// v6 lpm
	// ---------------------------------

#ifdef IPV6_ENABLE
	table npb_ing_sf_table_1_v6_lpm {
		key = {
			// l3
            ig_md.lkp_nsh.ip_type                   : exact;
			ig_md.lkp_nsh.ip_proto                  : exact;
			ig_md.lkp_nsh.ipv6_src_addr             : lpm;
			ig_md.lkp_nsh.ipv6_dst_addr             : ternary;

			// l4
			ig_md.lkp_nsh.l4_src_port               : exact;
			ig_md.lkp_nsh.l4_dst_port               : exact; 

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			npb_ing_sf_table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_BAS_ADV_POLICY_V6_LPM_TABLE_DEPTH;
	}
#endif

#ifdef SFF_SIMPLE

	// =========================================================================
	// Table #3
	// =========================================================================

	action npb_ing_sf_table_3_hit (
		bit<24>                    nsh_sph_path_identifier
	) {
		// change nsh
		
		// change metadata
		ig_md.nsh_extr.extr_flow_type                = flow_type_new;

		// base - word 1
		ig_md.nsh_extr.spi                           = nsh_sph_path_identifier;
		ig_md.nsh_extr.si                            = nsh_sph_si_new;

		// ext type 1 - word 0
		ig_md.nsh_extr.extr_srvc_func_bitmask_local  = nsh_srvc_func_bitmask_local_new;
		ig_md.nsh_extr.extr_srvc_func_bitmask_remote = nsh_srvc_func_bitmask_remote_new;
	}

	// ---------------------------------

	action npb_ing_sf_table_3_miss (
	) {
		// do nothing on a miss, I think?
	}

	// ---------------------------------

	table npb_ing_sf_table_3 {
		key = {
			service_func_chain_           : exact;
			ig_md.nsh_extr.extr_tenant_id : exact;
			ig_md.nsh_extr.extr_flow_type : exact;
		}

		actions = {
			NoAction;
			npb_ing_sf_table_3_hit;
			npb_ing_sf_table_3_miss;
		}

		const default_action = npb_ing_sf_table_3_miss;
		size = NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART1_DEPTH;
	}

#else // SFF_SIMPLE

	// =========================================================================
	// Table #3
	// =========================================================================

#ifdef SFF_COMPLEX_TYPE_ACTION_SELECTOR

	// action selector info
	Hash<bit<16>>(HashAlgorithm_t.CRC16) sel_hash;
//	ActionSelector(1024, sel_hash, SelectorMode_t.FAIR) action_selector;
	ActionSelector(1024, sel_hash, SelectorMode_t.RESILIENT) action_selector;

#else // SFF_COMPLEX_TYPE_ACTION_SELECTOR

	// action profile info
	ActionProfile(NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART2_DEPTH) action_profile;

#endif // SFF_COMPLEX_TYPE_ACTION_SELECTOR

	// ---------------------------------

	action npb_ing_sf_table_3_hit (
		bit<24>                    nsh_sph_path_identifier
	) {
		// change nsh
		
		// change metadata
		ig_md.nsh_extr.extr_flow_type                = flow_type_new;

		// base - word 1
		ig_md.nsh_extr.spi                           = nsh_sph_path_identifier;
		ig_md.nsh_extr.si                            = nsh_sph_si_new;

		// ext type 1 - word 0
		ig_md.nsh_extr.extr_srvc_func_bitmask_local  = nsh_srvc_func_bitmask_local_new;
		ig_md.nsh_extr.extr_srvc_func_bitmask_remote = nsh_srvc_func_bitmask_remote_new;
	}

	// ---------------------------------

	table npb_ing_sf_table_3 {
		key = {
			service_func_chain_           : exact;
			ig_md.nsh_extr.extr_tenant_id : selector;
			ig_md.nsh_extr.extr_flow_type : selector;
		}

		actions = {
			NoAction;
			npb_ing_sf_table_3_hit;
			npb_ing_sf_table_3_miss;
		}

		const default_action = npb_ing_sf_table_3_miss;
		size = NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART1_DEPTH;
#ifdef SFF_COMPLEX_TYPE_ACTION_SELECTOR
		implementation = action_selector;
#else // SFF_COMPLEX_TYPE_ACTION_SELECTOR
		implementation = action_profile;
#endif // SFF_COMPLEX_TYPE_ACTION_SELECTOR
	}

#endif // SFF_SIMPLE

	// =========================================================================
	// SF Actions (helper function)
	// =========================================================================

	action sf_actions() {

			// -------------------------------------
			// Action(s)
			// -------------------------------------

			if(action_bitmask_[0:0] == 1) {

				// -------------------------------------
				// Action #0
				// -------------------------------------

/*
#ifdef SF_DEDUP_ENABLE
				npb_ing_sf_npb_basic_adv_dedup.apply (
					hdr,
					ig_md,
					ig_intr_md,
					ig_intr_md_from_prsr,
					ig_intr_md_for_dprsr,
					ig_intr_md_for_tm,

					ig_md.lkp_nsh
				);
#endif
*/
			}
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		ig_md.nsh_extr.si = ig_md.nsh_extr.si - 1; // decrement sp_index

		// -------------------------------------
		// Action Lookup
		// -------------------------------------

		if(ig_md.lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV4) {
			// v4, exact
			if (npb_ing_sf_table_1_v4_exact.apply().hit) {
				// -------------------------------------
				// Action(s)
				// -------------------------------------
				sf_actions();

				// -------------------------------------
				// Flow Scheduler
				// -------------------------------------
				npb_ing_sf_table_3.apply();
			} else {
				// v4, lpm (fallback if exact missed)
				if(npb_ing_sf_table_1_v4_lpm.apply().hit) {
					// -------------------------------------
					// Action(s)
					// -------------------------------------
					sf_actions();

					// -------------------------------------
					// Flow Scheduler
					// -------------------------------------
					npb_ing_sf_table_3.apply();
				}
			}
#ifdef IPV6_ENABLE
		} else if(ig_md.lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV6) {
			// v6, exact
			if (npb_ing_sf_table_1_v6_exact.apply().hit) {
				// -------------------------------------
				// Action(s)
				// -------------------------------------
				sf_actions();

				// -------------------------------------
				// Flow Scheduler
				// -------------------------------------
				npb_ing_sf_table_3.apply();
			} else {
				// v6, lpm (fallback if exact missed)
				if(npb_ing_sf_table_1_v6_lpm.apply().hit) {
					// -------------------------------------
					// Action(s)
					// -------------------------------------
					sf_actions();

					// -------------------------------------
					// Flow Scheduler
					// -------------------------------------
					npb_ing_sf_table_3.apply();
				}
			}
#endif
		}

			// -------------------------------------
			// Flow Scheduler
			// -------------------------------------

//			npb_ing_sf_table_3.apply();

	}

}
