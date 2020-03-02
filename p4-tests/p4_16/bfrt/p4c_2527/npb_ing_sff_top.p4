#include "npb_ing_sff_flow_schd.p4"

control npb_ing_sff_top (
	inout switch_header_transport_t                 hdr,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm,

	in    bit<16>                                   hash
) {

	bit<8> hdr_nsh_type1_si_predec; // local copy used for pre-decrementing prior to forwarding lookup.

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: bitmask defined as follows....
	//
	//   [0:0] sf  #1: ingress basic/advanced
	//   [1:1] sf  #2: unused (was multicast)
	//   [2:2] sf  #3: egress proxy

	// =========================================================================
	// Table #1: ARP
	// =========================================================================

	action drop_pkt (
	) {
		ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
	}

	// =====================================

	action unicast(
		switch_nexthop_t        nexthop_index,

		bool                    end_of_chain
	) {
		ig_md.nexthop       = nexthop_index;

		ig_md.nsh_terminate = end_of_chain;
	}

	// =====================================

	action multicast(
		switch_mgid_t           mgid,

		bool                    end_of_chain
	) {
        ig_md.multicast.id  = mgid;
		ig_md.egress_port_lag_index = 0;

		ig_md.nsh_terminate = end_of_chain;
	}

	// =====================================
	// Table
	// =====================================

	table ing_sff_fib {
		key = {
			hdr.nsh_type1.spi       : exact @name("spi");
//			hdr.nsh_type1.si        : exact @name("si");
			hdr_nsh_type1_si_predec : exact @name("si");
		}

		actions = {
			drop_pkt;
			multicast;
			unicast;
		}

		// Derek: drop packet on miss...
		//
		// RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
		// do not correspond to a valid next hop in a valid SFP, that packet MUST
		// be dropped by the SFF.

		const default_action = drop_pkt;
		size = NPB_ING_SFF_ARP_TABLE_DEPTH;
	}

	// =========================================================================
	// Table - SI  Decrement
	// =========================================================================

	// this table just does a 'pop count' on the bitmask....

	bit<2> nsh_si_dec_amount;

	action new_si(bit<2> dec) {
//		ig_md.nsh_type1.si = ig_md.nsh_type1.si |-| (bit<8>)dec; // saturating subtract
		nsh_si_dec_amount = dec;
	}

	// NOTE: SINCE THE FIRST SF HAS ALREADY RUN, WE ONLY NEED TO ACCOUNT FOR
	// THE REMAINING SFs...

/*
	// this is code we'd like to use, but it doesn't work! -- barefoot bug?
    table ing_sff_dec_si {
        key = { ig_md.nsh_type1.sf_bitmask[2:1] : exact; }
        actions = { new_si; }
        const entries = {
            0  : new_si(0); // 0 bits set
            1  : new_si(1); // 1 bits set
            2  : new_si(1); // 1 bits set
            3  : new_si(2); // 2 bits set
        }
    }
*/

    table ing_sff_dec_si {
        key = { ig_md.nsh_type1.sf_bitmask[2:0] : exact; }
        actions = { new_si; }
        const entries = {
            0  : new_si(0); // 0 bits set
            1  : new_si(0); // 1 bits set -- but don't count bit 0
            2  : new_si(1); // 1 bits set
            3  : new_si(1); // 2 bits set -- but don't count bit 0
            4  : new_si(1); // 1 bits set
            5  : new_si(1); // 2 bits set -- but don't count bit 0
            6  : new_si(2); // 2 bits set
            7  : new_si(2); // 3 bits set -- but don't count bit 0
        }
		const default_action = new_si(0); 
    }

	// =========================================================================
	// Apply
	// =========================================================================

	// Need to do one table lookups here:
	//
	// 1: forwarding lookup, after any sf's have reclassified the packet.

	apply {
		ig_md.flags.dmac_miss = false;

		// +---------------+---------------+-----------------------------+
		// | hdr nsh valid | our nsh valid | signals / actions           |
		// +---------------+---------------+-----------------------------+
		// | n/a           | FALSE         | --> (classification failed) |
		// | FALSE         | TRUE          | --> we  classified          |
		// | TRUE          | TRUE          | --> was classified          |
		// +---------------+---------------+-----------------------------+

//		if(ig_md.nsh_type1.valid == 1) {
		if(1 == 1) {

			// Note: All of this code has to come after, serially, the first service function.
			// This is because the first service function can reclassify / change just about
			// anything with regard to the packet and it's service path.

			// -------------------------------------
			// Perform Flow Scheduling
			// -------------------------------------

// TODO: Modify these functions to include flowclass and vpn....
/*
			if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE)
				compute_non_ip_hash(ig_md.lkp, ig_md.hash);
			else
				compute_ip_hash(ig_md.lkp, ig_md.hash);
*/

			// -----------------

			npb_ing_sff_flow_schd.apply(
				hdr,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm,

				ig_md.hash[15:0]
			);

			// -------------------------------------
			// Pre-Decrement SI
			// -------------------------------------

			// Here we decrement the SI for all SF's we are going to do in the
			// chip.  We have to do all the decrements prior to the forwarding
			// lookup.  However, each SF still needs to do it's own decrement so
			// the the next SF gets the correct value.  Thus we don't want to
			// save this value permanently....

			ing_sff_dec_si.apply(); // do a pop-count on the bitmask

			hdr_nsh_type1_si_predec = hdr.nsh_type1.si |-| (bit<8>)nsh_si_dec_amount; // saturating subtract

			// -------------------------------------
			// Perform Forwarding Lookup
			// -------------------------------------

			ing_sff_fib.apply();

			// -------------------------------------
			// Check SI
			// -------------------------------------

			// RFC 8300: "an SFF that is not the terminal SFF for an SFP will
			// discard any NSH packet with an SI of 0, as there will be no valid
			// next SF information."

//			if((ig_md_nsh_type1_si == 0) && (ig_md.tunnel_0.terminate == false)) { // check for si of 0 (or underflow, since we used a saturating subtract)
//				ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//			}

			// NOTE: MOVED TO EGRESS

		}

	}

}
