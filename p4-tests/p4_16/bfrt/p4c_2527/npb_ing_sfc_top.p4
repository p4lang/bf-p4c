#include "tunnel.p4"

#ifdef VALIDATION_ENABLE
  #include "validation.p4"
#endif /* VALIDATION_ENABLE */

control npb_ing_sfc_top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_header_outer_t                     hdr_1,
	inout switch_header_inner_t                     hdr_2,
	inout udf_h                                     hdr_l7_udf,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm,

	inout switch_tunnel_metadata_t                  tunnel_0,
	inout switch_tunnel_metadata_t                  tunnel_1,
	inout switch_tunnel_metadata_t                  tunnel_2
) {

#ifdef TRANSPORT_ENABLE
	IngressTunnel(
		IPV4_SRC_TUNNEL_TABLE_SIZE, IPV6_SRC_TUNNEL_TABLE_SIZE,
		IPV4_DST_TUNNEL_TABLE_SIZE, IPV6_DST_TUNNEL_TABLE_SIZE
	) tunnel_transport;
#endif

#ifdef SFC_OUTER_TUNNEL_TABLE_ENABLE
	IngressTunnelOuterInner(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH) tunnel_outer;
#endif
	IngressTunnelOuterInner(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;

//	ScoperIngress() scoper0;
	ScoperIngress() scoper1;
//	ScoperIngress() scoper2;

#ifdef UDF_ENABLE
//	Scoper_l7() scoper_l7;
#endif

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

#ifdef TRANSPORT_ENABLE
	action ing_sfc_net_sap_miss (
	) {
	}

	// ---------------------------------

	action ing_sfc_net_sap_permit (
		bit<SAP_ID_WIDTH>               sap,
		bit<VPN_ID_WIDTH>               vpn,
		bit<3>                          sf_bitmask
	) {
		hdr_0.nsh_type1.sap        = sap;
		hdr_0.nsh_type1.vpn        = vpn;
		ig_md.nsh_type1.sf_bitmask = sf_bitmask;  //  8 bits
	}

	// ---------------------------------

	table ing_sfc_net_sap {
		key = {
			hdr_0.nsh_type1.sap    : exact @name("sap");
			tunnel_0.type          : exact @name("tunneL_type");
			tunnel_0.id            : exact @name("tunnel_id");
		}

		actions = {
			NoAction;
			ing_sfc_net_sap_permit;
			ing_sfc_net_sap_miss;
		}

		const default_action = ing_sfc_net_sap_miss();
		size = NPB_ING_SFC_NET_SAP_TABLE_DEPTH;
	}
#endif

	// =========================================================================
	// W/  NSH... Table #0:
	// =========================================================================

	action ing_sfc_sf_sel_hit(
		bit<3>                     sf_bitmask

	) {
		// ----- change nsh -----

		// change metadata
		
		// base - word 0

		// base - word 1

		// ext type 1 - word 0-3

		// change metadata

		ig_md.nsh_type1.sf_bitmask             = sf_bitmask;

	}

	// ---------------------------------

	action ing_sfc_sf_sel_miss(
	) {
		ig_md.nsh_type1.sf_bitmask             = 0;
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

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

#ifdef VALIDATION_ENABLE
		// check for parser errors
		ParserValidation.apply(hdr_l7_udf, ig_md, ig_intr_md_from_prsr, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
#endif /* VALIDATION_ENABLE */

		// -----------------------------------------------------------------
		// Set Initial Scope (L7)
		// -----------------------------------------------------------------

        // populate l7_udf in lkp struct for the following cases:
        //   scope==inner
        //   scope==outer and no inner stack present
        // todo: do we need to qualify this w/ hdr_l7_udf.isValid()? (the thinking is it will just work w/o doing so)

#ifdef UDF_ENABLE
//      if(hdr_0.nsh_type1.scope==1 || (hdr_0.nsh_type1.scope==0 && !hdr_2.ethernet.isValid())) {
//              scoper_l7.apply(hdr_l7_udf, ig_md.lkp);
//      }
#endif  /* UDF_ENABLE */

		// ---------------------------------------------------------------------
		// Classify
		// ---------------------------------------------------------------------

		if(hdr_0.nsh_type1.isValid()) {

			// -----------------------------------------------------------------
			// Packet already has  a NSH header on it (is already classified) --> just copy it to internal NSH structure
			// -----------------------------------------------------------------

			// metadata
			ig_md.nsh_type1.hdr_is_new                   = false;
			ig_md.nsh_type1.sfc_is_new                   = false;

			// -----------------------------------------------------------------
			// Set Initial Scope
			// -----------------------------------------------------------------

			if(hdr_0.nsh_type1.scope == 0) {
/*
				scoper0.apply(
					hdr_1.ethernet,
					hdr_1.e_tag,
					hdr_1.vn_tag,
					hdr_1.vlan_tag[0],
					hdr_1.vlan_tag[1],
					hdr_1.ipv4,
#ifdef IPV6_ENABLE
					hdr_1.ipv6,
#endif // IPV6_ENABLE
					hdr_1.tcp,
					hdr_1.udp,
					hdr_1.sctp,
					tunnel_1.type,
					tunnel_1.id,
					ig_md.drop_reason_1,

					ig_md.lkp
				);
*/
			} else {
/*
				scoper1.apply(
					hdr_2.ethernet,
					hdr_2.vlan_tag[0],
					hdr_2.ipv4,
#ifdef IPV6_ENABLE
					hdr_2.ipv6,
#endif // IPV6_ENABLE
					hdr_2.tcp,
					hdr_2.udp,
					hdr_2.sctp,
					tunnel_2.type,
					tunnel_2.id,
					ig_md.drop_reason_2,

					ig_md.lkp
				);
*/
				scoper1.apply(
					ig_md.lkp_2,
					ig_md.drop_reason_2,

					ig_md.lkp
				);
			}

			// -----------------------------------------------------------------

			ing_sfc_sf_sel.apply();

		} else {

			// -----------------------------------------------------------------
			// Packet doesn't have a NSH header on it (needs classification) --> try to classify / populate internal NSH structure
			// -----------------------------------------------------------------

			// metadata
			ig_md.nsh_type1.hdr_is_new                   = true;  // * see design note below
			ig_md.nsh_type1.sfc_is_new                   = false; // * see design note below

			// header
			hdr_0.nsh_type1.setValid();

			// base: word 0
			// (nothing to do)

			// base: word 1
//			hdr_0.nsh_type1.spi                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
//			hdr_0.nsh_type1.si                           = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE

			// ext: type 1 - word 1-3
			hdr_0.nsh_type1.scope                        = 0;
//			hdr_0.nsh_type1.sap                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
//			hdr_0.nsh_type1.vpn                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
#ifdef SFC_TIMESTAMP_ENABLE
			hdr_0.nsh_type1.timestamp                    = ig_md.timestamp[31:0]; // FOR REAL DESIGN
#else
			hdr_0.nsh_type1.timestamp                    = 0;                     // FOR SIMS
#endif

			// * design note: we have to ensure that all sfc tables have hits, otherwise
			// we can end up with a partially classified packet -- which would be bad.
			// one "cheap" (resource-wise) way of doing this is to initially set all
			// the control signals valid, and then have any table that misses clear them....

			// -----------------------------------------------------------------
			// Set Initial Scope
			// -----------------------------------------------------------------
/*
			scoper2.apply(
				hdr_1.ethernet,
				hdr_1.e_tag,
				hdr_1.vn_tag,
				hdr_1.vlan_tag[0],
				hdr_1.vlan_tag[1],
				hdr_1.ipv4,
#ifdef IPV6_ENABLE
				hdr_1.ipv6,
#endif // IPV6_ENABLE
				hdr_1.tcp,
				hdr_1.udp,
				hdr_1.sctp,
				tunnel_1.type,
				tunnel_1.id,
				ig_md.drop_reason_1,

				ig_md.lkp
			);
*/
			// -----------------------------------------------------------------

			if(hdr_0.ethernet.isValid()) {
				// ---------------------------
				// ----- normally tapped -----
				// ---------------------------
#ifdef TRANSPORT_ENABLE
				// decaps transport, validates and copies ***outer*** to lkp struct.
				tunnel_transport.apply(ig_md, ig_md.flags.ipv4_checksum_err_0, ig_md.lkp, tunnel_0, hdr_0, ig_intr_md_for_dprsr);

				// table
				ing_sfc_net_sap.apply();
#endif // TRANSPORT_ENABLE
			} else {
				// ----------------------------
				// ----- optically tapped -----
				// ----------------------------

				// -----------------------
				// Tunnel - Outer
				// -----------------------

				// if hit, validates and copies ***inner*** to lkp struct.
#ifdef SFC_OUTER_TUNNEL_TABLE_ENABLE
				tunnel_outer.apply(ig_md, ig_md.lkp, hdr_0, hdr_2, tunnel_2);
#endif
			}

			// -----------------------
			// Tunnel - Inner
			// -----------------------

			// if hit, validates and copies ***inner*** to lkp struct.
			tunnel_inner.apply(ig_md, ig_md.lkp, hdr_0, hdr_2, tunnel_2);

			// -----------------------
			// Finishing Touches
			// -----------------------

			// add a dummy ethernet header -- only need to set the etype (not the da/sa)....
			hdr_0.ethernet.setValid();
			hdr_0.ethernet.ether_type = ETHERTYPE_NSH;
		}

		// always terminate transport headers
		tunnel_0.terminate = true;

	}
}
