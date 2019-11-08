#include "npb_ing_sf_npb_basic_adv_dedup.p4"

control npb_ing_sf_npb_basic_adv_top (
	inout switch_header_t                           hdr,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm,

	in    switch_lookup_fields_t                    lkp
) {

	bit<FLOW_TYPE_WIDTH> flow_type_new;

	bit<8> nsh_sph_si_new;

	bit<8> nsh_srvc_func_bitmask_local_new;
	bit<8> nsh_srvc_func_bitmask_remote_new;

	bit<SRVC_FUNC_CHAIN_WIDTH> service_func_chain_;

	bit<1> action_bitmask_;

	// =========================================================================
	// Table #1:
	//
	// Type: Normal
	// 
	// Function: tenantId and 5-tuple --> flowType and sfc
	// =========================================================================

	action table_1_hit (
		bit<FLOW_TYPE_WIDTH>       flow_type,

		bit<8>                     nsh_sph_si,

		bit<8>                     srvc_func_bitmask_local,
		bit<8>                     srvc_func_bitmask_remote,

		bit<SRVC_FUNC_CHAIN_WIDTH> service_func_chain,

		bit<1>                     action_bitmask,
		bit<3>                     discard
	) {
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

	table table_1_v4_exact {
		key = {
			// l3
            lkp.ip_type                   : exact;
			lkp.ip_proto                  : exact;
			lkp.ipv4_src_addr             : exact;
			lkp.ipv4_dst_addr             : exact;

			// l4
			lkp.l4_src_port               : exact;
			lkp.l4_dst_port               : exact; 

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_BAS_ADV_POLICY_V4_EXACT_MATCH_TABLE_DEPTH;
	}

	// ---------------------------------
	// v4 lpm
	// ---------------------------------

	table table_1_v4_lpm {
		key = {
			// l3
            lkp.ip_type                   : exact;
			lkp.ip_proto                  : exact;
			lkp.ipv4_src_addr             : exact;
			lkp.ipv4_dst_addr             : exact;

			// l4
			lkp.l4_src_port               : exact;
			lkp.l4_dst_port               : exact; 

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_BAS_ADV_POLICY_V4_LPM_TABLE_DEPTH;
	}


	// ---------------------------------
	// v6 exact
	// ---------------------------------

#ifdef IPV6_ENABLE
	table table_1_v6_exact {
		key = {
			// l3
            lkp.ip_type                   : exact;
			lkp.ip_proto                  : exact;
			lkp.ipv6_src_addr             : exact;
			lkp.ipv6_dst_addr             : exact;

			// l4
			lkp.l4_src_port               : exact;
			lkp.l4_dst_port               : exact; 

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_BAS_ADV_POLICY_V6_EXACT_MATCH_TABLE_DEPTH;
	}
#endif

	// ---------------------------------
	// v6 lpm
	// ---------------------------------

#ifdef IPV6_ENABLE
	table table_1_v6_lpm {
		key = {
			// l3
            lkp.ip_type                   : exact;
			lkp.ip_proto                  : exact;
			lkp.ipv6_src_addr             : lpm;
			lkp.ipv6_dst_addr             : lpm;

			// l4
			lkp.l4_src_port               : exact;
			lkp.l4_dst_port               : exact; 

			ig_md.nsh_extr.extr_tenant_id : exact;
		}

		actions = {
			NoAction;
			table_1_hit;
		}

		const default_action = NoAction;
		size = NPB_ING_SF_BAS_ADV_POLICY_V6_LPM_TABLE_DEPTH;
	}
#endif

	// =========================================================================
	// Table #3:
	//
	// Type: Action Selector
	// 
	// Function: tenantId, flowType, and sfc --> nsh header
	// =========================================================================

#ifdef SIMPLE_SFF
#else

#ifdef COMPLEX_SFF_TYPE_ACTION_SELECTOR

	// action selector info
	Hash<bit<16>>(HashAlgorithm_t.CRC16) sel_hash;
	ActionSelector(1024, sel_hash, SelectorMode_t.FAIR) action_selector;

#else

	// action profile info
	ActionProfile(NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART2_DEPTH) action_profile;

#endif

#endif

	// ---------------------------------

	action table_3_hit (
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

	action table_3_miss (
	) {
		// TODO: what should be do on a miss????
	}

	// ---------------------------------

	table table_3 {
		key = {
			service_func_chain_           : exact;
#ifdef SIMPLE_SFF
			ig_md.nsh_extr.extr_tenant_id : exact;
			ig_md.nsh_extr.extr_flow_type : exact;
#else
			ig_md.nsh_extr.extr_tenant_id : selector;
			ig_md.nsh_extr.extr_flow_type : selector;
#endif
		}

		actions = {
			NoAction;
			table_3_hit;
			table_3_miss;
		}

		const default_action = table_3_miss;
		size = NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART1_DEPTH;
#ifdef SIMPLE_SFF
#else

#ifdef COMPLEX_SFF_TYPE_ACTION_SELECTOR
		implementation = action_selector;
#else
		implementation = action_profile;
#endif

#endif
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		ig_md.nsh_extr.si = ig_md.nsh_extr.si - 1; // decrement sp_index

		// -------------------------------------
		// Action Lookup
		// -------------------------------------

		if(lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
			if (!table_1_v4_exact.apply().hit) {
				table_1_v4_lpm.apply();
			}
#ifdef IPV6_ENABLE
		} else if(lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
			if (table_1_v6_exact.apply().hit) {
				table_1_v6_lpm.apply();
			}
#endif
		}

		// -------------------------------------
		// Action(s)
		// -------------------------------------

		if(action_bitmask_[0:0] == 1) {

			// -------------------------------------
			// Action #0
			// -------------------------------------

/*
			npb_ing_sf_npb_basic_adv_dedup.apply (
				hdr,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
*/
		}

		table_3.apply();

	}

}
