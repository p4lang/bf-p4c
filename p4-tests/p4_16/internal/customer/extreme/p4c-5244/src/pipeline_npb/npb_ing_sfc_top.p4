
#ifndef _NPB_ING_SFC_TOP_
#define _NPB_ING_SFC_TOP_

control Npb_Ing_Sfc_Top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_tunnel_metadata_t                  tunnel_0,
	inout switch_header_outer_t                     hdr_1,
	inout switch_tunnel_metadata_reduced_t          tunnel_1,
	inout switch_header_inner_t                     hdr_2,
	inout switch_tunnel_metadata_reduced_t          tunnel_2,
	inout switch_header_inner_inner_t               hdr_3,
	inout udf_h                                     hdr_udf,

	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) (
	MODULE_DEPLOYMENT_PARAMS,
	switch_uint32_t port_table_size=288
) {

	bool scope_flag = false;
	bool term_flag = false;

	IngressTunnel(
		INSTANCE_DEPLOYMENT_PARAMS,
		IPV4_SRC_TUNNEL_TABLE_SIZE, IPV6_SRC_TUNNEL_TABLE_SIZE,
		IPV4_DST_TUNNEL_TABLE_SIZE, IPV6_DST_TUNNEL_TABLE_SIZE
	) tunnel_transport;

  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
	IngressTunnelNetwork(INSTANCE_DEPLOYMENT_PARAMS, NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH) tunnel_network;
  #endif

#ifdef SFC_OUTER_TUNNEL_TABLE_ENABLE
	IngressTunnelOuter(INSTANCE_DEPLOYMENT_PARAMS, NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH) tunnel_outer;
#endif
//	IngressTunnelInner(INSTANCE_DEPLOYMENT_PARAMS, NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;
	IngressTunnelOuter(INSTANCE_DEPLOYMENT_PARAMS, NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;

#ifdef INGRESS_MAU_NO_LKP_1
	Scoper_Hdr1_To_Lkp(INSTANCE_DEPLOYMENT_PARAMS) scoper_hdr1_to_lkp;
#else
	Scoper_Lkp_To_Lkp(INSTANCE_DEPLOYMENT_PARAMS) scoper_lkp_to_lkp;
#endif
	Scoper_Scope_And_Term_Only(INSTANCE_DEPLOYMENT_PARAMS) scoper_scope_and_term_only;
	Scoper_Hdr2_To_Lkp(INSTANCE_DEPLOYMENT_PARAMS) scoper_hdr2_to_lkp;

	// =========================================================================
	// W/  NSH... Table #0a:
	// =========================================================================

#ifdef SFF_PREDECREMENTED_SI_ENABLE
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;  // direct counter

	action ing_sfc_sf_sel_hit(
		bit<8>                     si_predec
	) {
		stats.count();

		ig_md.nsh_md.si_predec  = si_predec;
	}

	// ---------------------------------

	action ing_sfc_sf_sel_miss(
	) {
		stats.count();

//		ig_md.nsh_md.si_predec  = 0;
		ig_md.nsh_md.si_predec  = ig_md.nsh_md.si;
	}

	// ---------------------------------

	table ing_sfc_sf_sel {
		key = {
			ig_md.nsh_md.spi : exact @name("spi");
			ig_md.nsh_md.si  : exact @name("si");
		}

		actions = {
			ing_sfc_sf_sel_hit;
			ing_sfc_sf_sel_miss;
		}

		const default_action = ing_sfc_sf_sel_miss;
		size = NPB_ING_SFC_SF_SEL_TABLE_DEPTH;
		counters = stats;
	}
#endif
	// =========================================================================
	// W/  NSH... Table #0b:
	// =========================================================================
#ifdef INGRESS_NSH_HDR_VER_1_SUPPORT
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_nsh_xlate;  // direct counter

	action ing_sfc_sf_sel_nsh_xlate_hit(
		bit<6>                     ttl,
		bit<SPI_WIDTH>             spi,
		bit<8>                     si,
		bit<8>                     si_predec
	) {
		stats_nsh_xlate.count();

		ig_md.nsh_md.ttl     = ttl;
		ig_md.nsh_md.spi     = spi;
		ig_md.nsh_md.si      = si;
		ig_md.nsh_md.si_predec  = si_predec;

		ig_md.nsh_md.ver     = 0x2;
	}

	// ---------------------------------

	action ing_sfc_sf_sel_nsh_xlate_miss(
	) {
		stats_nsh_xlate.count();

		ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
	}

	// ---------------------------------

	table ing_sfc_sf_sel_nsh_xlate {
		key = {
			ig_md.nsh_md.spi : exact @name("tool_address");
		}

		actions = {
			ing_sfc_sf_sel_nsh_xlate_hit;
			ing_sfc_sf_sel_nsh_xlate_miss;
		}

		const default_action = ing_sfc_sf_sel_nsh_xlate_miss;
		size = NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH;
		counters = stats_nsh_xlate;
	}
#endif
	// =========================================================================
	// W/O NSH... Table #0:
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats_port_mapping;  // direct counter

	action set_port_properties(
		bit<8>                          si_predec,

		bit<SSAP_ID_WIDTH>              sap,
		bit<VPN_ID_WIDTH>               vpn,
		bit<SPI_WIDTH>                  spi,
		bit<8>                          si
	) {
		stats_port_mapping.count();

		ig_md.nsh_md.si_predec    = si_predec;    //  8 bits

		ig_md.nsh_md.sap        = (bit<SSAP_ID_WIDTH>)sap; // 16 bits
		ig_md.nsh_md.vpn        = (bit<VPN_ID_WIDTH>)vpn;  // 16 bits
		ig_md.nsh_md.spi        = spi;                     // 24 bits
		ig_md.nsh_md.si         = si;                      //  8 bits
	}

	// ---------------------------------

	action no_action(
	) {
		stats_port_mapping.count();

	}

	// ---------------------------------

	table port_mapping {
		key = {
			ig_md.ingress_port : exact @name("port");
//			ig_md.ingress_port_lag_index : exact @name("port_lag_index");
		}

		actions = {
			no_action;
			set_port_properties;
		}

		const default_action = no_action;
		size = port_table_size;
		counters = stats_port_mapping;
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// ---------------------------------------------------------------------
		// Classify
		// ---------------------------------------------------------------------

		// -----------------------------------------------------------------------------------------------------
		// | transport  | transport |
		// | nsh valid  | eth valid | result
		// +------------+-----------+----------------
		// | 1          | x         | internal  fabric -> sfc no tables...instead grab fields from nsh header
		// | 0          | 1         | normally  tapped -> sfc transport table, sap mapping table, inner table
		// | 0          | 0         | optically tapped -> sfc outer     table,                    inner table
		// -----------------------------------------------------------------------------------------------------
#ifdef SFC_NSH_ENABLE
		if(hdr_0.nsh_type1.isValid()) {

			// -----------------------------------------------------------------
			// Packet does    have a NSH header on it (is already classified)
			// -----------------------------------------------------------------

			// ----- metadata -----
//			ig_md.nsh_md.start_of_path = false;
//			ig_md.nsh_md.sfc_enable    = false;

			// ----- table -----
  #ifdef INGRESS_NSH_HDR_VER_1_SUPPORT
			if(ig_md.nsh_md.ver == 2) {
    #ifdef SFF_PREDECREMENTED_SI_ENABLE
				// get predecremented si
				ing_sfc_sf_sel.apply();
    #endif
			} else {
				// xlate, get predecremented si
				ing_sfc_sf_sel_nsh_xlate.apply();
			}
  #else
    #ifdef SFF_PREDECREMENTED_SI_ENABLE
			// get predecremented si
			ing_sfc_sf_sel.apply();
    #endif
  #endif
			// ---- advance data to match incoming scope value ----
/*
#ifdef INGRESS_MAU_NO_LKP_1
			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, ig_md.lkp_1, ig_md.tunnel_1.unsupported_tunnel, ig_md.lkp_0);
#else
			scoper_lkp_to_lkp.apply(ig_md.lkp_1, ig_md.lkp_0);
#endif
*/
//			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, ig_md.lkp_1, ig_md.tunnel_1.unsupported_tunnel, ig_md.lkp_1);

			// ---- advance data to match incoming scope value ----
/*
			Scoper_Data_Only.apply(
				ig_md.lkp_0,
//				ig_md.lkp_1,
				ig_md.lkp_2,
    
				hdr_1,
				hdr_2,
				hdr_3,

				ig_md.nsh_md.scope,
				ig_md.lkp_1
			);
*/
			if(ig_md.nsh_md.scope == 2) {
				scope_flag = true;
			}
		} else {
#endif // SFC_NSH_ENABLE
			// -----------------------------------------------------------------
			// Packet doesn't have a NSH header on it -- add it (needs classification)
			// -----------------------------------------------------------------

			// ----- metadata -----
//			ig_md.nsh_md.start_of_path = true;  // * see design note below
//			ig_md.nsh_md.sfc_enable    = false; // * see design note below

			ig_md.nsh_md.ttl = 0x00; // 63 is the rfc's recommended default value.

			// ----- header -----
/*
			// note: according to p4 spec, initializing a header also automatically sets it valid.
//			ig_md.nsh_md.setValid();
			ig_md.nsh_md = {
				version    = 0x0,
				o          = 0x0,
				reserved   = 0x0,
				ttl        = 0x00, // 63 is the rfc's recommended default value (0 will get dec'ed to 63).
				len        = 0x6,  // in 4-byte words (1 + 1 + 4).
				reserved2  = 0x0,
				md_type    = 0x1,  // 0 = reserved, 1 = fixed len, 2 = variable len.
				next_proto = NSH_PROTOCOLS_ETH, // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.

				spi        = 0x0,
				si         = 0x0,

				ver        = 0x2,
				reserved3  = 0x0,
				lag_hash   = 0x0,

				vpn        = 0x0,
				sfc_data   = 0x0,

				reserved4  = 0x0,
				scope      = 0x0,
				sap        = 0x0,

#ifdef SFC_TIMESTAMP_ENABLE
				timestamp = ig_md.ingress_timestamp[31:0]
#else
				timestamp = 0
#endif
			};
*/

			// ----- table -----
			port_mapping.apply();

			// -----------------------------------------------------------------

			if((TRANSPORT_INGRESS_ENABLE == true) && (hdr_0.ethernet.isValid())) {
//			if((TRANSPORT_INGRESS_ENABLE == true) && (ig_md.flags.transport_valid == true) {

				// ---------------------------
				// ----- Normally Tapped -----
				// ---------------------------

				tunnel_transport.apply(
					ig_md,
					hdr_0,
					ig_md.lkp_0,
					tunnel_0,
					ig_intr_md_for_dprsr
				);

  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
				// -----------------------
				// Network SAP
				// -----------------------
				tunnel_network.apply(
					ig_md,
					ig_md.lkp_0,
					hdr_0
				);
  #endif
			} else {

				// ----------------------------
				// ----- Optically Tapped -----
				// ----------------------------

				// -----------------------
				// Outer SAP
				// -----------------------
#ifdef SFC_OUTER_TUNNEL_TABLE_ENABLE
				tunnel_outer.apply(
					ig_md,
					ig_md.lkp_1,
					ig_intr_md_for_dprsr,

					scope_flag,
					term_flag
				);
#endif
			}

			// always terminate transport headers
			tunnel_0.terminate = true;
			ig_md.nsh_md.scope = 1;
/*
#ifdef INGRESS_MAU_NO_LKP_1
			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, ig_md.lkp_1, ig_md.tunnel_1.unsupported_tunnel, ig_md.lkp_0);
#else
			scoper_lkp_to_lkp.apply(ig_md.lkp_1, ig_md.lkp_0);
#endif
*/
//			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, ig_md.lkp_1, ig_md.tunnel_1.unsupported_tunnel, ig_md.lkp_1);

			// -----------------------
			// Inner SAP
			// -----------------------
			tunnel_inner.apply(
				ig_md,
				ig_md.lkp_1,
				ig_intr_md_for_dprsr,

				scope_flag,
				term_flag
			);
/*
			Scoper_ScopeAndTermAndData.apply(
				ig_md.lkp_0,
//				ig_md.lkp_1,
				ig_md.lkp_2,

				hdr_1,
				hdr_2,
				hdr_3,

				ig_md.lkp_1,

				term_flag,
				scope_flag,
				ig_md.nsh_md.scope,

				ig_md.tunnel_0.terminate,
				ig_md.tunnel_1.terminate,
				ig_md.tunnel_2.terminate
			);
*/
			scoper_scope_and_term_only.apply(
				ig_md.lkp_1,

				term_flag,
				scope_flag,
				ig_md.nsh_md.scope,

				ig_md.tunnel_0.terminate,
				ig_md.tunnel_1.terminate,
				ig_md.tunnel_2.terminate
			);
#ifdef SFC_NSH_ENABLE
		}
#endif // SFC_NSH_ENABLE

		if(scope_flag && ig_md.lkp_1.next_lyr_valid) {
			scoper_hdr2_to_lkp.apply(hdr_2, hdr_3, ig_md.lkp_2, ig_md.tunnel_2.unsupported_tunnel, ig_md.lkp_1);
		}
	}
}

#endif /* _NPB_ING_SFC_TOP_ */
