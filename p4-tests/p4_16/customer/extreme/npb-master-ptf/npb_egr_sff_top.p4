control npb_egr_sff_top (
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

		// =============================
		// SFF (continued)
		// =============================

		// -------------------------------------
		// Check TTL & SI
		// -------------------------------------

		// RFC 8300, Page 12: "an SFF that is not the terminal SFF for an SFP
		// will discard any NSH packet with an SI of 0, as there will be no
		// valid next SF information."

		if(eg_md.nsh_md.start_of_path == true) {

			// ---------------
			// add new header
			// ---------------

			// (done in ingress)

			// ---------------

			if(eg_md.nsh_md.end_of_path == true) {

				// ---------------
				// process start + end of chain
				// ---------------

				hdr_0.nsh_type1.setInvalid(); // it's the end of the line for this nsh chain....

			} else {

				// ---------------
				// process start of chain
				// ---------------

				if((hdr_0.nsh_type1.ttl == 0) || (hdr_0.nsh_type1.si == 0)) {
					eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
				}

			}


		} else {

			// ---------------
			// update existing header
			// ---------------

			npb_egr_sff_dec_ttl.apply();

			// ---------------

			if(eg_md.nsh_md.end_of_path == true) {

				// ---------------
				// process end of chain
				// ---------------

				hdr_0.nsh_type1.setInvalid(); // it's the end of the line for this nsh chain....

			} else {

				// ---------------
				// process middle of chain
				// ---------------

				if((hdr_0.nsh_type1.ttl == 0) || (hdr_0.nsh_type1.si == 0)) {
					eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
				}

			}

		}

		// -------------------------------------
		// Fowrarding Lookup
		// -------------------------------------

		// Derek: The forwarding lookup would normally
		// be done here.  However, since Tofino requires the outport
		// to set in ingress, it has to be done there instead....

	}

}
