control npb_egr_sff_top_part1 (
	inout switch_header_transport_t                   hdr_0,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: bitmask defined as follows....
	//
	//   [0:0] sf  #1: ingress basic/advanced
	//   [1:1] sf  #2: unused (was multicast)
	//   [2:2] sf  #3: egress proxy 

	// =========================================================================
	// Table
	// =========================================================================

	// RFC 8300, Page 9: Decrementing (the TTL) from an incoming value of 0 shall
	// result in a TTL value of 63.   The handling of an incoming 0 TTL allows
	// for better, although not perfect, interoperation with pre-standard
	// implementations that do not support this TTL field.

    action new_ttl(bit<6> ttl) {
        hdr_0.nsh_type1.ttl = ttl;
    }

    action discard() {
//        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table npb_egr_sff_dec_ttl {
        key = { hdr_0.nsh_type1.ttl : exact; }
        actions = { new_ttl; discard; }
		size = 64;
        const entries = {
            0  : new_ttl(63);
//          1  : discard();
            1  : new_ttl(0);
            2  : new_ttl(1);
            3  : new_ttl(2);
            4  : new_ttl(3);
            5  : new_ttl(4);
            6  : new_ttl(5);
            7  : new_ttl(6);
            8  : new_ttl(7);
            9  : new_ttl(8);
            10 : new_ttl(9);
            11 : new_ttl(10);
            12 : new_ttl(11);
            13 : new_ttl(12);
            14 : new_ttl(13);
            15 : new_ttl(14);
            16 : new_ttl(15);
            17 : new_ttl(16);
            18 : new_ttl(17);
            19 : new_ttl(18);
            20 : new_ttl(19);
            21 : new_ttl(20);
            22 : new_ttl(21);
            23 : new_ttl(22);
            24 : new_ttl(23);
            25 : new_ttl(24);
            26 : new_ttl(25);
            27 : new_ttl(26);
            28 : new_ttl(27);
            29 : new_ttl(28);
            30 : new_ttl(29);
            31 : new_ttl(30);
            32 : new_ttl(31);
            33 : new_ttl(32);
            34 : new_ttl(33);
            35 : new_ttl(34);
            36 : new_ttl(35);
            37 : new_ttl(36);
            38 : new_ttl(37);
            39 : new_ttl(38);
            40 : new_ttl(39);
            41 : new_ttl(40);
            42 : new_ttl(41);
            43 : new_ttl(42);
            44 : new_ttl(43);
            45 : new_ttl(44);
            46 : new_ttl(45);
            47 : new_ttl(46);
            48 : new_ttl(47);
            49 : new_ttl(48);
            50 : new_ttl(49);
            51 : new_ttl(50);
            52 : new_ttl(51);
            53 : new_ttl(52);
            54 : new_ttl(53);
            55 : new_ttl(54);
            56 : new_ttl(55);
            57 : new_ttl(56);
            58 : new_ttl(57);
            59 : new_ttl(58);
            60 : new_ttl(59);
            61 : new_ttl(60);
            62 : new_ttl(61);
            63 : new_ttl(62);
        }
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// =====================================
		// SFF
		// =====================================

		// -------------------------------------
		// Reframer
		// -------------------------------------

		// Three mutually-exclusive reframing scenarios are supported:
		//
		// 1: First  in chain --> encap
		// 2: Middle in chain --> rewrite
		// 3: Last   in chain --> decap
		//
		// Note that the example in the RFC shows either a first/middle or last -- but not
		// combinations of these.  Howver, conceivabably I suppose you could have a last
		// (i.e. decap) followed by a first (i.e. encap).  Regardless, the RFC example
		// doesn't show this, and so we don't support it (currently anyway).
		//
		// To support these three reframing scenarios, I look at three signals:
		//
		// +---------------+---------------+--------------+-------------------------------------+
		// | hdr nsh valid | our nsh valid | terminate    | signals / actions                   |
		// +---------------+---------------+--------------+-------------------------------------+
		// | n/a           | FALSE         | n/a          | --> (classification failed)         |
		// | FALSE         | TRUE          | FALSE        | --> first  / encap                  |
		// | FALSE         | TRUE          | TRUE         | --> first  / encap   & last / decap |
		// | TRUE          | TRUE          | FALSE        | --> middle / rewrite                |
		// | TRUE          | TRUE          | TRUE         | --> last   / decap                  |
		// +---------------+---------------+--------------+-------------------------------------+
		//
		// Note: The above truth table just shows how my logic handles the three scenarios,
		// although you could devise other ways to look at these signals and still get the
		// same results.

		// ----------------------------------------
		// Move NSH Metadata to NSH Header
		// ----------------------------------------

//		if((eg_md.nsh_md.valid == 1) && (hdr_0.nsh_type1.isValid())) {
//		if(hdr_0.nsh_type1.isValid()) {
		if(eg_md.nsh_md.start_of_path == false) {

			// ---------------
			// need to do a rewrite...
			// ---------------

			npb_egr_sff_dec_ttl.apply();

		} else {

			// ---------------
			// need to do a encap...
			// ---------------

//			hdr_0.nsh_type1.setValid();

			// base: word 0
			hdr_0.nsh_type1.version                  = 0x0;
			hdr_0.nsh_type1.o                        = 0x0;
			hdr_0.nsh_type1.reserved                 = 0x0;
			hdr_0.nsh_type1.ttl                      = 0x3f; // 63 is the rfc's recommended default value.
			hdr_0.nsh_type1.len                      = 0x6;  // in 4-byte words (1 + 1 + 4).
			hdr_0.nsh_type1.reserved2                = 0x0;
			hdr_0.nsh_type1.md_type                  = 0x1;  // 0 = reserved, 1 = fixed len, 2 = variable len.
//			hdr_0.nsh_type1.next_proto               = 0x3;  // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.

			// base: word 1
			// (nothing to do)

			// ext: type 1 - word 0-3
			hdr_0.nsh_type1.ver                      = 0x2;  // word 0
//			hdr_0.nsh_type1.reserved3                = 0x0;  // word 0

			hdr_0.nsh_type1.reserved4                = 0x0;  // word 2

#ifndef SFC_TIMESTAMP_ENABLE
			hdr_0.nsh_type1.timestamp                = 0x0;  // word 3 // FOR SIMS
#endif

		}

	}

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sff_top_part2 (
	inout switch_header_transport_t                   hdr_0,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: bitmask defined as follows....
	//
	//   [0:0] sf  #1: ingress basic/advanced
	//   [1:1] sf  #2: unused (was multicast)
	//   [2:2] sf  #3: egress proxy 

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// =============================
		// SFF (continued)
		// =============================

		// -------------------------------------
		// Check TTL & SI
		// -------------------------------------

		// RFC 8300, Page 12: "an SFF that is not the terminal SFF for an SFP
		// will discard any NSH packet with an SI of 0, as there will be no
		// valid next SF information."

//		if((hdr_0.nsh_type1.si == 0) && (eg_md.tunnel_0.terminate == false)) { // check for si of 0 (or underflow, since we used a saturating subtracts)
//			eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//		}

//		if(eg_md.tunnel_0.terminate == false) { // check for si of 0 (or underflow, since we used a saturating subtracts)
		if(eg_md.nsh_md.end_of_path == false) { // check for si of 0 (or underflow, since we used a saturating subtracts)

			// ---------------
			// need to do a rewrite...
			// ---------------

			if((hdr_0.nsh_type1.ttl == 0) || (hdr_0.nsh_type1.si == 0)) {
				eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
			}
		} else {

			// ---------------
			// need to do a decap...
			// ---------------

			hdr_0.nsh_type1.setInvalid(); // it's the end of the line for this nsh chain....
		}

		// -------------------------------------
		// Fowrarding Lookup
		// -------------------------------------

		// Derek: I guess the forwarding lookup would normally
		// be done here.  However, since Tofino requires the outport
		// to set in ingress, it has to be done there instead....

	}

}
