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

	// Note: bitmask defined as follows....
	//
	//   [0:0] sf  #1: ingress basic/advanced
	//   [1:1] sf  #2: unused (was multicast)
	//   [2:2] sf  #3: egress proxy

	// =========================================================================
	// W/O NSH... Table #0: FlowType Classifier / SFC Classifier
	// =========================================================================
/*
#ifdef TRANSPORT_ENABLE
  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE

	action tunnel_transport_sap_hit (
		bit<SSAP_ID_WIDTH>              sap,
		bit<VPN_ID_WIDTH>               vpn
	) {
		hdr_0.nsh_type1.sap     = (16)sap;
		hdr_0.nsh_type1.vpn     = (16)vpn;
	}

	// ---------------------------------

	table tunnel_transport_sap {
		key = {
			hdr_0.nsh_type1.sap    : exact @name("sap");
			tunnel_0.type          : exact @name("tunnel_type");
			tunnel_0.id            : exact @name("tunnel_id");
		}

		actions = {
			NoAction;
			tunnel_transport_sap_hit;
		}

		size = NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH;
	}
  #endif
#endif
*/
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
		}

		const default_action = ing_sfc_sf_sel_miss;
		size = NPB_ING_SFC_SF_SEL_TABLE_DEPTH;
	}
#endif
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
			// Packet already has  a NSH header on it (is already classified) --> just copy it to internal NSH structure
			// -----------------------------------------------------------------

			// metadata
			ig_md.nsh_md.start_of_path = false;
			ig_md.nsh_md.sfc_enable    = false;

			// -----------------------------------------------------------------
#ifdef SFF_PREDECREMENTED_SI_ENABLE
			ing_sfc_sf_sel.apply();
#endif
		} else {
#endif // SFC_NSH_ENABLE
			// -----------------------------------------------------------------
			// Packet doesn't have a NSH header on it (needs classification) --> try to classify / populate internal NSH structure
			// -----------------------------------------------------------------

			// ----- metadata -----
			ig_md.nsh_md.start_of_path = true;  // * see design note below
			ig_md.nsh_md.sfc_enable    = false; // * see design note below

			// ----- header -----
			hdr_0.nsh_type1.setValid();

			// base: word 0
			hdr_0.nsh_type1.next_proto                   = NSH_PROTOCOLS_ETH;
			// (nothing to do, will be done in egress)

			// base: word 1
//			hdr_0.nsh_type1.spi                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
//			hdr_0.nsh_type1.si                           = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE

			// ext: type 1 - word 1-3
			hdr_0.nsh_type1.scope                        = 0;
//			hdr_0.nsh_type1.sap                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
//			hdr_0.nsh_type1.vpn                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
			hdr_0.nsh_type1.sfc_data                     = 0;
#ifdef SFC_TIMESTAMP_ENABLE
//			hdr_0.nsh_type1.timestamp                    = ig_md.timestamp[31:0]; // FOR REAL DESIGN
#else
//			hdr_0.nsh_type1.timestamp                    = 0;                     // FOR SIMS
#endif

			// * design note: we have to ensure that all sfc tables have hits, otherwise
			// we can end up with a partially classified packet -- which would be bad.
			// one "cheap" (resource-wise) way of doing this is to initially set all
			// the control signals valid, and then have any table that misses clear them....

			// -----------------------------------------------------------------

//			if(ig_md.flags.rmac_hit == true) { // note: hit is forced "false" if there is no transport present
			if(hdr_0.ethernet.isValid()) {

				// ---------------------------
				// ----- normally tapped -----
				// ---------------------------

				bool hit;

#ifdef TRANSPORT_ENABLE
				tunnel_transport.apply(ig_md, ig_md.flags.ipv4_checksum_err_0, hdr_0, ig_md.lkp_0, tunnel_0, ig_intr_md_for_dprsr, hit);

  #ifdef SFC_TRANSPORT_NETSAP_TABLE_ENABLE
//				if(hit) {
//					tunnel_transport_sap.apply();
					tunnel_network.apply(ig_md, ig_md.lkp_0, hdr_0, tunnel_0);
//				}
  #endif
#endif // TRANSPORT_ENABLE
			} else {

				// ----------------------------
				// ----- optically tapped -----
				// ----------------------------

				// -----------------------
				// Tunnel - Outer
				// -----------------------

#ifdef SFC_OUTER_TUNNEL_TABLE_ENABLE
				tunnel_outer.apply(ig_md, ig_md.lkp_1, hdr_0, ig_md.lkp_2, hdr_2, tunnel_2);
#endif
			}

			// -----------------------
			// Tunnel - Inner
			// -----------------------

			tunnel_inner.apply(ig_md, ig_md.lkp_1, hdr_0, ig_md.lkp_2, hdr_2, tunnel_2);
#ifdef SFC_NSH_ENABLE
		}
#endif // SFC_NSH_ENABLE
		// always terminate transport headers
		tunnel_0.terminate = true;

	}
}
