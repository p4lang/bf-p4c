#include "tunnel.p4"

#ifdef VALIDATION_ENABLE
  #include "validation.p4"
#endif /* VALIDATION_ENABLE */

control npb_ing_sfc_top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_tunnel_metadata_t                  tunnel_0,
	inout switch_header_outer_t                     hdr_1,
	inout switch_tunnel_metadata_reduced_t          tunnel_1,
	inout switch_header_inner_t                     hdr_2,
	inout switch_tunnel_metadata_reduced_t          tunnel_2,
	inout udf_h                                     hdr_udf,

	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

#ifdef TRANSPORT_ENABLE
	IngressTunnel(
		IPV4_SRC_TUNNEL_TABLE_SIZE, IPV6_SRC_TUNNEL_TABLE_SIZE,
		IPV4_DST_TUNNEL_TABLE_SIZE, IPV6_DST_TUNNEL_TABLE_SIZE
	) tunnel_transport;

  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
	IngressTunnelNetwork(NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH) tunnel_network;
  #endif
#endif

#ifdef SFC_OUTER_TUNNEL_TABLE_ENABLE
	IngressTunnelOuter(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH) tunnel_outer;
#endif
	IngressTunnelInner(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;

	// =========================================================================
	// Notes
	// =========================================================================

	// =========================================================================
	// W/  NSH... Table #0:
	// =========================================================================
#ifdef SFF_PREDECREMENTED_SI_ENABLE
	action ing_sfc_sf_sel_hit(
		bit<8>                     si_predec
	) {
		ig_md.nsh_md.si_predec  = si_predec;
	}

	// ---------------------------------

	action ing_sfc_sf_sel_miss(
	) {
//		ig_md.nsh_md.si_predec  = 0;
		ig_md.nsh_md.si_predec  = hdr_0.nsh_type1.si;
	}

	// ---------------------------------

	table ing_sfc_sf_sel {
		key = {
			hdr_0.nsh_type1.spi : exact @name("spi");
			hdr_0.nsh_type1.si  : exact @name("si");
		}

		actions = {
			ing_sfc_sf_sel_hit;
			ing_sfc_sf_sel_miss;
			NoAction;
		}

		const default_action = ing_sfc_sf_sel_miss;
		size = NPB_ING_SFC_SF_SEL_TABLE_DEPTH;
	}
#endif
	// =========================================================================
	// W/O NSH... Table #0:
	// =========================================================================

	action set_port_properties(
		bit<8>                          si_predec,

		bit<SSAP_ID_WIDTH>              sap,
		bit<VPN_ID_WIDTH>               vpn,
		bit<24>                         spi,
		bit<8>                          si
	) {
		ig_md.nsh_md.si_predec    = si_predec;    //  8 bits

		hdr_0.nsh_type1.sap        = (bit<16>)sap; // 16 bits
		hdr_0.nsh_type1.vpn        = (bit<16>)vpn; // 16 bits
		hdr_0.nsh_type1.spi        = spi;          // 24 bits
		hdr_0.nsh_type1.si         = si;           //  8 bits
	}

	// ---------------------------------

	table port_mapping {
		key = {
			ig_md.port : exact @name("port");
//			ig_md.port_lag_index : exact @name("port_lag_index");
		}

		actions = {
			set_port_properties;
			NoAction;
		}

		const default_action = NoAction;
//		size = port_table_size;
		size = 1024;
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// ---------------------------------------------------------------------
		// Classify
		// ---------------------------------------------------------------------

		// -----------------------------------------------------------------------------------------------------
		// | transport  | trasnport |
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
			ig_md.nsh_md.start_of_path = false;
//			ig_md.nsh_md.sfc_enable    = false;

			// ----- table -----
#ifdef SFF_PREDECREMENTED_SI_ENABLE
			ing_sfc_sf_sel.apply();
#endif
		} else {
#endif // SFC_NSH_ENABLE
			// -----------------------------------------------------------------
			// Packet doesn't have a NSH header on it -- add it (needs classification)
			// -----------------------------------------------------------------

			// ----- metadata -----
			ig_md.nsh_md.start_of_path = true;  // * see design note below
//			ig_md.nsh_md.sfc_enable    = false; // * see design note below

			// ----- header -----

			// note: according to p4 spec, initializing a header also automatically sets it valid.
//			hdr_0.nsh_type1.setValid();
			hdr_0.nsh_type1 = {
				version    = 0x0,
				o          = 0x0,
				reserved   = 0x0,
				ttl        = 0x3f, // 63 is the rfc's recommended default value.
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
				timestamp = ig_md.timestamp[31:0]
#else
				timestamp = 0
#endif
			};

			// ----- table -----
			port_mapping.apply();

			// -----------------------------------------------------------------

			if(hdr_0.ethernet.isValid()) {

				// ---------------------------
				// ----- Normally Tapped -----
				// ---------------------------

				bool hit;

#ifdef TRANSPORT_ENABLE
				tunnel_transport.apply(ig_md, hdr_0, ig_md.lkp_0, tunnel_0, ig_intr_md_for_dprsr, hit);

  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
				// -----------------------
				// Network SAP
				// -----------------------
//				if(hit) {
//					tunnel_transport_sap.apply();
					tunnel_network.apply(ig_md, ig_md.lkp_0, hdr_0, tunnel_0);
//				}
  #endif
#endif // TRANSPORT_ENABLE
			} else {

				// ----------------------------
				// ----- Optically Tapped -----
				// ----------------------------

				// -----------------------
				// Outer SAP
				// -----------------------
#ifdef SFC_OUTER_TUNNEL_TABLE_ENABLE
				tunnel_outer.apply(ig_md, ig_md.lkp_1, hdr_0, ig_md.lkp_2, hdr_2, tunnel_2);
#endif
			}

			// -----------------------
			// Inner SAP
			// -----------------------
			tunnel_inner.apply(ig_md, ig_md.lkp_1, hdr_0, ig_md.lkp_2, hdr_2, tunnel_2);
#ifdef SFC_NSH_ENABLE
		}
#endif // SFC_NSH_ENABLE
		// always terminate transport headers
		tunnel_0.terminate = true;
	}
}
